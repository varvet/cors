describe Manifest do
  let(:attributes) do
    {
      "method" => "GET",
    }
  end

  let(:rules) do
    lambda do
      required "method", %w[GET]
    end
  end

  let(:manifest) { Manifest.new(attributes, &rules) }

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

    context "validation rules" do
      describe "#required" do
      end

      describe "#optional" do
      end
    end
  end

  describe "#validate" do
    it "returns true if validation succeeds" do
      manifest.validate.should be_true
      manifest.errors.should eq({})
    end

    it "returns false if validation fails" do
      Manifest.new({}, &rules).validate.should be_false
    end

    it "populates the hash of errors" do
      manifest = Manifest.new({}, &rules)
      expect { manifest.validate }.to change { manifest.errors }.from({})
    end
  end

  describe "#sign" do
    it "signs the manifest if it is valid" do
      manifest = Manifest.new(attributes, &rules)
      manifest.should_receive(:valid?).and_return(true)
      manifest.sign("LAWL", "HELLO").should eq "AWS LAWL:AT+TyO+xcWzLFqHGDR4jRDFdUUc="
    end

    it "does not sign if the manifest is invalid" do
      manifest = Manifest.new(attributes, &rules)
      manifest.should_receive(:valid?).and_return(false)
      manifest.sign("LAWL", "HELLO").should be_nil
    end
  end
end
