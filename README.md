#

## Manifest

Manifest provides a simple DSL for describing what values you will
and will not accept in the request that will be sent to the AWS API.

```ruby
UploadManifest = Manifest.new do |manifest|
  manifest.required "method", "PUT"
  manifest.optional "md5" do |value|
    Base64.strict_decode64(value)
  end
  manifest.required "content-type", %r|image/|
  manifest.required "x-amz-date" do |date|
    "2012-10-22T16:10:47+02:00" == date
  end
  manifest.required "filename", %r|uploads/|
end

manifest = UploadManifest.new(params)

response = if manifest.valid?
  { success: manifest.sign(access_key, secret_access_key) }
else
  { error: manifest.errors }
end
```
