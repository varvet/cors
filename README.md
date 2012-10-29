#

## Manifest

Manifest provides a simple DSL for describing what values you will
and will not accept in the request that will be sent to the AWS API.

```ruby
UploadManifest = CORS::Policy::S3.create do |policy|
  policy.required "method", "PUT"
  policy.optional "md5" do |value|
    Base64.strict_decode64(value)
  end
  policy.required "content-type", %r|image/|
  policy.required "x-amz-date" do |date|
    "2012-10-22T16:10:47+02:00" == date
  end
  policy.required "filename", %r|uploads/|
end

manifest = UploadManifest.new(params)

response = if manifest.valid?
  { success: manifest.sign(access_key, secret_access_key) }
else
  { error: manifest.errors }
end
```
