# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "google_spreadsheet_recorder"
  spec.version       = "0.1.0"
  spec.authors       = ["saeki"]
  spec.email         = ["nobuo.seaki@gmail.com"]
  spec.summary       = %q{Simple google spreadsheet data uploader.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/nsaeki/google_spreadsheet_recorder"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "oauth2"
  spec.add_dependency "nokogiri"

end
