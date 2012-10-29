require "openssl"
require "base64"

# @public
module CORS::Policy
  class S3
    include CORS::Policy

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
      return if not valid?
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
