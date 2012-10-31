require "openssl"
require "base64"

module CORS::Policy
  # CORS policy for Amazon S3. See {CORS} module documenation for an example.
  #
  # @see CORS
  class S3
    include CORS::Policy

    # Compile the S3 authorization manifest from the parameters.
    #
    # @see http://docs.amazonwebservices.com/AmazonS3/latest/dev/RESTAuthentication.html#ConstructingTheAuthenticationHeader
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

    # Sign the {#manifest} with the AWS credentials.
    #
    # @param [String] access_key
    # @param [String] secret_access_key
    def sign!(access_key, secret_access_key)
      digest = OpenSSL::HMAC.digest("sha1", secret_access_key, manifest)
      signature = Base64.strict_encode64(digest)
      "AWS #{access_key}:#{signature}"
    end

    protected

    # @return [Array] list of aws-specific headers properly sorted
    def normalized_headers
      attributes.select  { |property, _| property =~ /x-amz-/ }
                .map     { |(header, values)| [header.downcase, values] }
                .sort_by { |(header, _)| header }
    end
  end
end
