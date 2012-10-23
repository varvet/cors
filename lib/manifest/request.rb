require "openssl"
require "base64"

# @public
module Manifest
  class Request
    class << self
      attr_reader :rules
    end

    def initialize(attributes, rules = self.class.rules)
      @attributes = Hash[attributes.map { |k, v| [k.to_s.downcase, v] }]
      @errors     = {}
      @rules      = rules
    end

    attr_reader :attributes
    attr_reader :errors
    attr_reader :rules

    def valid?
      @errors = rules.validate(attributes)
      @errors.empty?
    end

    def manifest
      [].tap do |manifest|
        manifest << attributes["method"].upcase
        manifest << attributes["md5"]
        manifest << attributes["content-type"]
        manifest << attributes["date"]
        normalized_headers.each do |(header, *values)|
          manifest << "#{header}:#{values.join(",")}"
        end
        manifest << attributes["filename"]
      end.join("\n")
    end

    def sign(access_key, secret_access_key)
      return unless valid?
      digest = OpenSSL::HMAC.digest("sha1", secret_access_key, manifest)
      signature = Base64.strict_encode64(digest)
      "AWS #{access_key}:#{signature}"
    end

    protected

    def normalized_headers
      attributes.select  { |property, _| property =~ /x-amz-/ }
                .map     { |(header, values)| [header.downcase, values] }
                .sort_by { |(header, _)| header }
    end
  end
end

