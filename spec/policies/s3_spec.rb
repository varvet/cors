describe CORS::Policy::S3 do
  let(:valid_attributes) do
    {
      "method" => "PUT",
      "md5"    => "CCummMp6o4ZgypU7ePh7QA==",
      "content-type" => "image/jpeg",
      "x-amz-meta-filename" => "roflcopter.gif",
      "x-amz-date" => "2012-10-22T16:10:47+02:00",
      "x-amz-meta-ROFLCOPTER" => ["yes", "no", "maybe"],
      "x-not-amz-header" => "I am ignored",
      "filename" => "uploads/roflcopter.gif"
    }
  end

  let(:rules) do
    lambda do |manifest|
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
  end

  let(:manifest) { CORS::Policy::S3.create(&rules) }

  describe "#manifest" do
    it "is built according to specifications" do
      manifest = CORS::Policy::S3.create(&rules).new(valid_attributes)
      manifest.manifest.should eq <<-MANIFEST.gsub(/^ +/, "").rstrip
        PUT
        CCummMp6o4ZgypU7ePh7QA==
        image/jpeg

        x-amz-date:2012-10-22T16:10:47+02:00
        x-amz-meta-filename:roflcopter.gif
        x-amz-meta-roflcopter:yes,no,maybe
        uploads/roflcopter.gif
      MANIFEST
    end
  end

  describe "#sign" do
    it "signs the manifest if it is valid" do
      manifest = CORS::Policy::S3.create(&rules).new(valid_attributes)
      manifest.sign("LAWL", "HELLO").should eq "AWS LAWL:WZGsk2VzLz85B6oU19a5+fvzxXM="
    end

    it "does not sign if the manifest is invalid" do
      manifest = CORS::Policy::S3.create(&rules).new(valid_attributes)
      manifest.should_receive(:valid?).and_return(false)
      manifest.sign("LAWL", "HELLO").should be_nil
    end
  end
end
