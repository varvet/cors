describe CORS::Policy::S3Post do
  let(:now) do
    Time.at(1351696066)
  end

  let(:valid_attributes) do
    {
      "bucket" => "shokunin",
      "key" => "upload/BEEFBEEFBEEF.jpg",
      "x-amz-meta-filename" => "$dollar$.jpg",
      "acl" => "public-read",
      "content-type" => "image/jpeg",
      "content-length" => 678,
    }
  end

  let(:rules) do
    lambda do |manifest|
      manifest.required "bucket", "shokunin"
      manifest.required "key", %r!\Aupload/[a-f0-9A-F]{12}\.(jpg|png)!
      manifest.required "acl", "public-read"
      manifest.optional "x-amz-meta-filename", //
      manifest.required "content-type", %r|\Aimage/|
      manifest.required "content-length" do |bytesize|
        (0..1024).cover?(bytesize)
      end
    end
  end

  let(:manifest) { CORS::Policy::S3Post.create(&rules) }

  describe "#manifest" do
    it "generates the policy document as a hash" do
      policy = manifest.new(valid_attributes).policy(now)
      expect(policy["conditions"]).to eq([
        [ "content-length-range", 678, 678 ],
        [ "eq", "$bucket", "shokunin" ],
        [ "eq", "$key", "upload/BEEFBEEFBEEF.jpg" ],
        [ "eq", "$x-amz-meta-filename", "\$dollar$.jpg" ],
        [ "eq", "$acl", "public-read" ],
        [ "eq", "$content-type", "image/jpeg" ],
      ])
    end
  end

  describe "#policy" do
    it "returns the Base64-encoded manifest" do
      request = manifest.new(valid_attributes)
      decoded = Base64.urlsafe_decode64(request.policy_base64(now))
      expect(MultiJson.load(decoded)).to eq(request.policy(now))
    end
  end

  describe "#sign!" do
    it "unconditionally signs the manifest" do
      request = manifest.new(valid_attributes)
      expect(request.sign!("properties", now)).to eq("U1YETIAOqT9mEuCebm5B6BM6feQ=")
    end
  end
end
