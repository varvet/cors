# CORS policy validation- and signing library

[![Build Status](https://secure.travis-ci.org/varvet/cors.png)](http://travis-ci.org/varvet/cors)

Cross-origin resource sharing (CORS) is great; it allows your visitors to asynchronously upload files to
e.g. Amazon S3, without the files having to round-trip through your web server. Unfortunately,
giving your users complete write access to your online storage also exposes you to malicious intent.

To combat harmful usage, good upload services that allow client-side upload, support a mechanism that allows
you to validate and sign all upload requests to your online storage. By validating every request, you can
give your visitors a nice upload experience, while keeping the bad visitors at bay.

## Deprecation

The functionality of CORS is now provided by the ruby AWS SDK. We recommend
using that instead, as CORS will no longer receive updates:

[Amazon S3 SDK PresignedPost](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/PresignedPost.html)

## Usage

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

## Supported services

Out-of-the box, the CORS library comes with support for the Amazon S3 REST API.

- [Amazon S3 REST API Authentication Header](http://docs.amazonwebservices.com/AmazonS3/latest/dev/RESTAuthentication.html#ConstructingTheAuthenticationHeader)
- [Amazon S3 REST API POST Upload Policy](http://docs.amazonwebservices.com/AmazonS3/latest/dev/HTTPPOSTForms.html#HTTPPOSTConstructPolicy)

## License

Copyright (c) 2012 Kim Burgestrand

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
