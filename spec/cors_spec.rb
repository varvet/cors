require "base64"
require "date"

describe CORS do
  let(:attributes) do
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

  describe ".initialize" do
    it "requires a block" do
      expect { CORS::Policy::S3.create }.to raise_error(ArgumentError, /no block given/)
    end
  end

  describe "#initialize" do
    it "requires attributes" do
      expect { manifest.new }.to raise_error(ArgumentError, /wrong number of arguments/)
    end

    it "stringifies the attribute keys" do
      manifest.new(cool: :Yo).attributes.should eq({ "cool" => :Yo })
    end

    it "populates the hash of errors" do
      manifest.new({}).errors.should_not be_empty
    end
  end

  describe "#valid?" do
    it "returns true if validation succeeds" do
      manifest.new(attributes).tap do |manifest|
        manifest.should be_valid
        manifest.errors.should eq({})
      end
    end

    it "returns false if validation fails" do
      manifest.new({}).should_not be_valid
    end

    context "validation rules" do
      describe "#required" do
        it "does not accept arbitrary constraints" do
          rules = lambda { |manifest| manifest.required "method", false }
          expect { CORS::Policy::S3.create(&rules) }.to raise_error(ArgumentError, /unknown matcher/)
        end

        it "results in an error when the value is missing" do
          rules = lambda { |manifest| manifest.required "method", // }
          manifest = CORS::Policy::S3.create(&rules).new({})

          manifest.should_not be_valid
          manifest.errors.should eq({ "method" => [:required, manifest.rules.first] })
        end

        it "results in an error when the value does not match" do
          rules = lambda { |manifest| manifest.required "content-type", %r|image/jpe?g| }
          manifest = CORS::Policy::S3.create(&rules).new({ "content-type" => "image/png" })

          manifest.should_not be_valid
          manifest.errors.should eq({ "content-type" => [:match, manifest.rules.first] })
        end

        it "can match a regexp" do
          rules = lambda { |manifest| manifest.required "content-type", %r|image/jpe?g| }
          manifest = CORS::Policy::S3.create(&rules)

          manifest.new({ "content-type" => "image/jpeg" }).should be_valid
          manifest.new({ "content-type" => "image/jpg" }).should be_valid
          manifest.new({ "content-type" => "image/png" }).should_not be_valid
        end

        it "can match a literal string" do
          rules = lambda { |manifest| manifest.required "content-type", "image/jpeg" }
          manifest = CORS::Policy::S3.create(&rules)

          manifest.new({ "content-type" => "image/jpeg" }).should be_valid
          manifest.new({ "content-type" => "image/jpg" }).should_not be_valid
        end

        it "can match an array" do
          rules = lambda { |manifest| manifest.required "content-type", ["image/jpeg", "image/png"] }
          manifest = CORS::Policy::S3.create(&rules)

          manifest.new({ "content-type" => "image/jpeg" }).should be_valid
          manifest.new({ "content-type" => "image/png" }).should be_valid
          manifest.new({ "content-type" => "image/jpg" }).should_not be_valid
        end

        it "can match a block" do
          rules = lambda do |manifest|
            manifest.required "content-type" do |type|
              "image/jpeg" == type
            end
          end
          manifest = CORS::Policy::S3.create(&rules)

          manifest.new({ "content-type" => "image/jpeg" }).should be_valid
          manifest.new({ "content-type" => "image/png" }).should_not be_valid
        end
      end

      describe "#optional" do
        it "results in no error when the value is missing" do
          rules = lambda { |manifest| manifest.optional "method", // }
          manifest = CORS::Policy::S3.create(&rules).new({})
          manifest.should be_valid
        end

        it "results in an error when the value is present but does not match" do
          rules = lambda { |manifest| manifest.optional "content-type", %r|image/jpe?g| }
          manifest = CORS::Policy::S3.create(&rules).new({ "content-type" => "image/png" })

          manifest.should_not be_valid
          manifest.errors.should eq({ "content-type" => [:match, manifest.rules.first] })
        end
      end
    end
  end

  describe "#manifest" do
    it "is built according to specifications" do
      manifest = CORS::Policy::S3.create(&rules).new(attributes)
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
      manifest = CORS::Policy::S3.create(&rules).new(attributes)
      manifest.sign("LAWL", "HELLO").should eq "AWS LAWL:WZGsk2VzLz85B6oU19a5+fvzxXM="
    end

    it "does not sign if the manifest is invalid" do
      manifest = CORS::Policy::S3.create(&rules).new(attributes)
      manifest.should_receive(:valid?).and_return(false)
      manifest.sign("LAWL", "HELLO").should be_nil
    end
  end
end
