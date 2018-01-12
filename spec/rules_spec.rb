describe CORS::Rules do
  describe "#each" do
    let(:list) { [] }
    let(:rules) do
      CORS::Rules.new do |r|
        list << r.required("yay", //)
        list << r.optional("boo", //)
      end
    end

    it "is enumerable" do
      expect(rules.each_with_object([]) { |rule, result| result << rule }).to eq(list)
    end

    it "returns an enumerator without a block" do
      expect(rules.each.with_object([]) { |rule, result| result << rule }).to eq(list)
    end
  end

  describe "#[]" do
    let(:yay) { [] }
    let(:boo) { [] }

    let(:rules) do
      CORS::Rules.new do |r|
        yay << r.required("yay", //)
        yay << r.required("yay", /./)
        boo << r.optional("boo", //)
      end
    end

    it "returns the list of rules for a property" do
      expect(rules["yay"]).to eq yay
      expect(rules["boo"]).to eq boo
    end

    it "returns nil if there are no rules for the property" do
      expect(rules["does_not_exist"]).to be_nil
    end
  end

  describe "#required" do
    it "does not accept arbitrary constraints" do
      expect { CORS::Rules.new { |r| r.required "method", false } }.to raise_error(ArgumentError, /unknown matcher/)
    end

    it "results in an error when the value is missing" do
      rules  = CORS::Rules.new { |r| r.required "method", // }
      errors = rules.validate({})

      expect(errors).to eq({ "method" => [:required, rules.first] })
    end

    it "results in an error when the value does not match" do
      rules = CORS::Rules.new { |r| r.required "content-type", %r|image/jpe?g| }
      errors = rules.validate({ "content-type" => "image/png" })

      expect(errors).to eq({ "content-type" => [:match, rules.first] })
    end

    it "can match a regexp" do
      rules = CORS::Rules.new { |r| r.required "content-type", %r|image/jpe?g| }

      expect(rules.validate({ "content-type" => "image/jpeg" })).to be_empty
      expect(rules.validate({ "content-type" => "image/jpg" })).to be_empty
      expect(rules.validate({ "content-type" => "image/png" })).to_not be_empty
    end

    it "can match a literal string" do
      rules = CORS::Rules.new { |r| r.required "content-type", "image/jpeg" }

      expect(rules.validate({ "content-type" => "image/jpeg" })).to be_empty
      expect(rules.validate({ "content-type" => "image/jpg" })).to_not be_empty
    end

    it "can match an array" do
      rules = CORS::Rules.new { |r| r.required "content-type", ["image/jpeg", "image/png"] }

      expect(rules.validate({ "content-type" => "image/jpeg" })).to be_empty
      expect(rules.validate({ "content-type" => "image/png" })).to be_empty
      expect(rules.validate({ "content-type" => "image/jpg" })).to_not be_empty
    end

    it "can match a block" do
      rules = CORS::Rules.new do |r|
        r.required "content-type" do |type|
          "image/jpeg" == type
        end
      end

      expect(rules.validate({ "content-type" => "image/jpeg" })).to be_empty
      expect(rules.validate({ "content-type" => "image/png" })).to_not be_empty
    end
  end

  describe "#optional" do
    it "results in no error when the value is missing" do
      rules = CORS::Rules.new { |r| r.optional "method", // }
      errors = rules.validate({})

      expect(errors).to be_empty
    end

    it "results in an error when the value is present but does not match" do
      rules = CORS::Rules.new { |r| r.optional "content-type", %r|image/jpe?g| }
      errors = rules.validate({ "content-type" => "image/png" })

      expect(errors).to eq({ "content-type" => [:match, rules.first] })
    end
  end
end
