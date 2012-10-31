describe CORS::Policy do
  let(:policy) do
    Class.new { include CORS::Policy }
  end

  let(:valid_attributes) do
    {
      "anything" => "Yay!"
    }
  end

  let(:manifest) do
    policy.create do |rules|
      rules.required "anything", //
    end
  end

  describe ".initialize" do
    it "requires a block" do
      expect { CORS::Policy::S3.create }.to raise_error(ArgumentError, /no block given/)
    end
  end

  describe "#initialize" do
    it "requires attributes" do
      expect { manifest.new }.to raise_error(ArgumentError, /wrong number of arguments/)
    end

    it "normalizes the attribute keys" do
      manifest.new(anYTHIng: :Yo).attributes.should eq({ "anything" => :Yo })
    end

    it "removes attributes not covered by any rules" do
      manifest.new(cOOl: :Yo).attributes.should eq({})
    end

    it "populates the hash of errors" do
      manifest.new({}).errors.should_not be_empty
    end
  end

  describe "#rules" do
    it "raises an error if no rules have been defined" do
      expect { policy.new({}) }.to raise_error(/no rules defined/)
    end

    it "returns the raw rules" do
      manifest.rules.should be_a CORS::Rules
    end
  end

  describe "#valid?" do
    it "returns true if validation succeeds" do
      manifest.new(valid_attributes).tap do |manifest|
        manifest.should be_valid
        manifest.errors.should eq({})
      end
    end

    it "returns false if validation fails" do
      manifest.new({}).should_not be_valid
    end
  end
end
