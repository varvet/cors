require "base64"
require "date"

describe Manifest do
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
    lambda do
      required "method", "PUT"
      optional "md5" do |value|
        Base64.strict_decode64(value)
      end
      required "content-type", %r|image/|
      required "x-amz-date" do |date|
        "2012-10-22T16:10:47+02:00" == date
      end
      required "filename", %r|uploads/|
    end
  end

  describe "#initialize" do
    it "requires a block" do
      expect { Manifest.new(attributes) }.to raise_error(ArgumentError, /no block given/)
    end

    it "requires attributes" do
      expect { Manifest.new(&rules) }.to raise_error(ArgumentError, /wrong number of arguments/)
    end

    it "stringifies the attribute keys" do
      Manifest.new(cool: :Yo, &rules).attributes.should eq({ "cool" => :Yo })
    end
  end

  describe "#validate" do
    it "returns true if validation succeeds" do
      manifest = Manifest.new(attributes, &rules)
      manifest.should be_valid
      manifest.errors.should eq({})
    end

    it "returns false if validation fails" do
      Manifest.new({}, &rules).should_not be_valid
    end

    it "populates the hash of errors" do
      manifest = Manifest.new({}, &rules)
      expect { manifest.validate }.to change { manifest.errors }.from({})
    end

    context "validation rules" do
      describe "#required" do
        it "does not accept arbitrary constraints" do
          rules = lambda { required "method", false }
          expect { Manifest.new({}, &rules) }.to raise_error(ArgumentError, /unknown matcher/)
        end

        it "results in an error when the value is missing" do
          rules = lambda { required "method", // }
          manifest = Manifest.new({}, &rules)

          manifest.should_not be_valid
          manifest.errors.should eq({ "method" => [:required, manifest.rules[0]] })
        end

        it "results in an error when the value does not match" do
          rules = lambda { required "content-type", %r|image/jpe?g| }
          manifest = Manifest.new({ "content-type" => "image/png" }, &rules)

          manifest.should_not be_valid
          manifest.errors.should eq({ "content-type" => [:match, manifest.rules[0]] })
        end

        it "can match a regexp" do
          rules = lambda { required "content-type", %r|image/jpe?g| }

          Manifest.new({ "content-type" => "image/jpeg" }, &rules).should be_valid
          Manifest.new({ "content-type" => "image/jpg" }, &rules).should be_valid
          Manifest.new({ "content-type" => "image/png" }, &rules).should_not be_valid
        end

        it "can match a literal string" do
          rules = lambda { required "content-type", "image/jpeg" }

          Manifest.new({ "content-type" => "image/jpeg" }, &rules).should be_valid
          Manifest.new({ "content-type" => "image/jpg" }, &rules).should_not be_valid
        end

        it "can match an array" do
          rules = lambda { required "content-type", ["image/jpeg", "image/png"] }

          Manifest.new({ "content-type" => "image/jpeg" }, &rules).should be_valid
          Manifest.new({ "content-type" => "image/png" }, &rules).should be_valid
          Manifest.new({ "content-type" => "image/jpg" }, &rules).should_not be_valid
        end

        it "can match a block" do
          rules = lambda do
            required "content-type" do |type|
              "image/jpeg" == type
            end
          end

          Manifest.new({ "content-type" => "image/jpeg" }, &rules).should be_valid
          Manifest.new({ "content-type" => "image/png" }, &rules).should_not be_valid
        end
      end

      describe "#optional" do
        it "results in no error when the value is missing" do
          rules = lambda { optional "method", // }
          manifest = Manifest.new({}, &rules)
          manifest.should be_valid
        end

        it "results in an error when the value is present but does not match" do
          rules = lambda { optional "content-type", %r|image/jpe?g| }
          manifest = Manifest.new({ "content-type" => "image/png" }, &rules)

          manifest.should_not be_valid
          manifest.errors.should eq({ "content-type" => [:match, manifest.rules[0]] })
        end
      end
    end
  end

  describe "#manifest" do
    it "is built according to specifications" do
      manifest = Manifest.new(attributes, &rules)
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
      manifest = Manifest.new(attributes, &rules)
      manifest.sign("LAWL", "HELLO").should eq "AWS LAWL:WZGsk2VzLz85B6oU19a5+fvzxXM="
    end

    it "does not sign if the manifest is invalid" do
      manifest = Manifest.new(attributes, &rules)
      manifest.should_receive(:valid?).and_return(false)
      manifest.sign("LAWL", "HELLO").should be_nil
    end
  end
end
