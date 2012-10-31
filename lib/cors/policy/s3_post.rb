# encoding: utf-8
require "multi_json"
require "base64"
require "time"
require "set"

module CORS::Policy
  # POST form upload policy for Amazon S3.
  class S3Post
    include CORS::Policy

    # Generate the policy used to sign the request.
    #
    # @param [Time] expiration
    # @return [Hash] policy as a hash
    def policy(expiration)
      conditions = []
      properties = attributes.dup

      if properties.has_key?("content-length")
        length = escape(properties.delete("content-length"))
        conditions << [ "content-length-range", length, length ]
      end

      {
        "expiration" => expiration.gmtime.iso8601,
        "conditions" => conditions + properties.map do |(name, value)|
          [ "eq", "$#{escape(name)}", escape(value) ]
        end
      }
    end

    # Generate a policy and encode it in URL-safe Base64 encoding.
    #
    # @param [Time] expiration
    # @return [String] the policy, in JSON, in URL-safe base64 encoding.
    def policy_base64(expiration)
      json = MultiJson.dump(policy(expiration))
      Base64.urlsafe_encode64(json)
    end

    # Sign the {#policy} for the given expiration.
    #
    # @param [String] secret_access_key
    # @param [Time] expiration
    # @return [String] signed policy in Base64-encoding.
    def sign!(secret_access_key, expiration)
      digest = OpenSSL::HMAC.digest("sha1", secret_access_key, policy_base64(expiration))
      Base64.strict_encode64(digest)
    end

    protected

    def escape(string)
      return string unless string.is_a?(String)

      unicode_safe = string.codepoints.each_with_object("") do |i, result|
        result << if i <= 127 then i.chr else
          "\\u#{i.to_s(16).rjust(4, "0")}"
        end
      end

      unicode_safe.sub(/\A$/, "\$")
    end
  end
end
