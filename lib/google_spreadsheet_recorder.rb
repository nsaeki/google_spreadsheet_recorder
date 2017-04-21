# coding: utf-8
require 'yaml'
require 'oauth2'
require 'nokogiri'

class GoogleSpreadsheetRecorder
  SCOPE = 'https://spreadsheets.google.com/feeds'
  REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob'

  attr_accessor :spreadsheet_key

  def initialize(client_id, client_secret, token_file, spreadsheet_key)
    @token = load_or_refresh_token(client_id, client_secret, token_file)
    @spreadsheet_key = spreadsheet_key
  end

  def worksheets(spreadsheet_key = nil)
    key = spreadsheet_key || @spreadsheet_key
    raise ArgumentError("Must specify spreadsheet_key") if key.nil? || key.empty?
    url = "https://spreadsheets.google.com/feeds/worksheets/#{key}/private/full"
    response = @token.get(url)
    doc = Nokogiri::XML(response.body)
    doc.css('feed entry').map do |e|
      sheet_title = e.css('title').first.content
      sheet_url = e.css('id').first.content
      sheet_id = sheet_url.split('/').last
      [sheet_title, sheet_id]
    end
  end

  def rows(sheet_id)
    key = @spreadsheet_key
    raise ArgumentError("Must specify spreadsheet_key") if key.nil? || key.empty?
    url = "https://spreadsheets.google.com/feeds/list/#{key}/#{sheet_id}/private/full"
    response = @token.get(url)
    doc = Nokogiri::XML(response.body)
    doc.css('entry').map do |e|
      convert_to_hash(e)
    end
  end

  def send_row(row_data, sheet_id)
    key = @spreadsheet_key
    raise ArgumentError("Must specify spreadsheet_key") if key.nil? || key.empty?
    url = "https://spreadsheets.google.com/feeds/list/#{key}/#{sheet_id}/private/full"
    body = <<-"EOS"
      <entry xmlns="http://www.w3.org/2005/Atom"
          xmlns:gsx="http://schemas.google.com/spreadsheets/2006/extended">
        #{convert_to_xml(row_data).join}
      </entry>
    EOS

    @token.post(url, body: body, headers: {'Content-Type' => 'application/atom+xml'})
  end

  private

  def load_or_refresh_token(client_id, client_secret, token_file)
    oauth_params = {
      site: 'https://accounts.google.com',
      authorize_url: '/o/oauth2/auth',
      token_url: '/o/oauth2/token',
    }

    client = OAuth2::Client.new(client_id, client_secret, oauth_params)

    if File.exists?(token_file)
      token = OAuth2::AccessToken.from_hash(client, YAML.load_file(token_file))

      if token.expired?
        puts "Token has been expired at #{Time.at(token.expires_at)}. Refresh one"
        token = token.refresh!
        puts "New token will be expired at #{Time.at(token.expires_at)}."
        save_token(token_file, token)
      end
    else
      token = authorize_with_access_code(client)
      save_token(token_file, token)
    end

    token
  end

  def save_token(token_file, token)
    IO.write(token_file, YAML.dump(token.to_hash))
  end

  def authorize_with_access_code(client)
    auth_url = client.auth_code.authorize_url(redirect_uri: REDIRECT_URI, scope: SCOPE)
    puts "access this url and paste access code: #{auth_url}"
    print "input access_code: "
    access_code = $stdin.gets.strip

    # returns token
    client.auth_code.get_token(access_code, redirect_uri: REDIRECT_URI)
  end

  def convert_to_xml(row_hash)
    row_hash.map do |k, v|
      "<gsx:#{k}>#{v}</gsx:#{k}>"
    end
  end

  def convert_to_hash(row_xml)
    # Remove spreadsheet default columns.
    columns_to_ignore = %w(id updated category title content link)

    Hash[
      row_xml.children.reject { |e|
        columns_to_ignore.include?(e.name)
      }.map { |e|
        [e.name, e.content]
      }
    ]
  end
end
