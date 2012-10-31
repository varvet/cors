# encoding: utf-8
require "cors/version"
require "cors/rules"
require "cors/policy"
require "cors/policy/s3"
require "cors/policy/s3_post"

# CORS policy validation and signature generation.
#
# @example usage for S3 REST API authorization header
#   UploadManifest = CORS::Policy::S3.create do |policy|
#     policy.required "method", "PUT"
#     policy.optional "md5" do |value|
#       Base64.strict_decode64(value)
#     end
#     policy.required "content-type", %r|image/|
#     policy.required "x-amz-date" do |date|
#       "2012-10-22T16:10:47+02:00" == date
#     end
#     policy.required "filename", %r|uploads/|
#   end
#
#   manifest = UploadManifest.new(params)
#
#   response = if manifest.valid?
#     { success: manifest.sign(access_key, secret_access_key) }
#   else
#     { error: manifest.errors }
#   end
#
# @see CORS::Policy
module CORS
end
