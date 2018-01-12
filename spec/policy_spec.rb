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
      expect(manifest.new(anYTHIng: :Yo).attributes).to eq({ "anything" => :Yo })
    end

    it "removes attributes not covered by any rules" do
      expect(manifest.new(cOOl: :Yo).attributes).to eq({})
    end

    it "populates the hash of errors" do
      expect(manifest.new({}).errors).to_not be_empty
    end
  end

  describe "#rules" do
    it "raises an error if no rules have been defined" do
      expect { policy.new({}) }.to raise_error(/no rules defined/)
    end

    it "returns the raw rules" do
      expect(manifest.rules).to be_a CORS::Rules
    end
  end

  describe "#valid?" do
    it "returns true if validation succeeds" do
      manifest.new(valid_attributes).tap do |manifest|
        expect(manifest).to be_valid
        expect(manifest.errors).to eq({})
      end
    end

    it "returns false if validation fails" do
      expect(manifest.new({})).to_not be_valid
    end
  end

  describe "#sign" do
    it "delegates to sign! if the manifest is valid" do
      request = manifest.new(valid_attributes)
      allow(request).to receive(:sign!).and_return("OK")
      expect(request.sign(:a, :b)).to eq "OK"
      expect(request).to have_received(:sign!)
    end

    it "does nothing if the manifest is not valid" do
      request = manifest.new({})
      allow(request).to receive(:sign!)
      expect(request).not_to have_received(:sign!)
      expect(request.sign(:a, :b)).to be_nil
    end
  end
end
