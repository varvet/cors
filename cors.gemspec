# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cors/version'

Gem::Specification.new do |gem|
  gem.name          = "cors"
  gem.version       = CORS::VERSION
  gem.authors       = ["Kim Burgestrand"]
  gem.email         = ["kim@burgestrand.se"]
  gem.homepage      = "http://github.com/elabs/cors"
  gem.summary       = "CORS policy validation- and signing library for Amazon S3 REST API."
  gem.description   = <<-DESCRIPTION.gsub(/ +/, "")
    Cross-origin resource sharing (CORS) is great; it allows your visitors to
    asynchronously upload files to e.g. Filepicker or Amazon S3, without the
    files having to round-trip through your web server. Unfortunately, giving
    your users complete write access to your online storage also exposes you to
    malicious intent.

    To combat harmful usage, good upload services that allow client-side
    upload, support a mechanism that allows you to validate and sign all upload
    requests to your online storage. By validating every request, you can give
    your visitors a nice upload experience, while keeping the bad visitors at
    bay.

    The CORS gem comes with support for the Amazon S3 REST API.
  DESCRIPTION

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rspec", "~> 2.0"
end
