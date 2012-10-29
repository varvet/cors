describe CORS::Rules do
  describe "#each" do
    let(:list) { [] }
    let(:rules) do
      CORS::Rules.new do |rules|
        list << rules.required("yay", //)
        list << rules.optional("boo", //)
      end
    end

    it "is enumerable" do
      result = rules.each_with_object([]) { |rule, result| result << rule }

      result.should eq(list)
    end

    it "returns an enumerator without a block" do
      result = rules.each.with_object([]) { |rule, result| result << rule }

      result.should eq(list)
    end
  end

  describe "#required" do
    it "does not accept arbitrary constraints" do
      rules = lambda { |rules| rules.required "method", false }
      expect { CORS::Rules.new(&rules) }.to raise_error(ArgumentError, /unknown matcher/)
    end

    it "results in an error when the value is missing" do
      rules  = CORS::Rules.new { |rules| rules.required "method", // }
      errors = rules.validate({})

      errors.should eq({ "method" => [:required, rules.first] })
    end

    it "results in an error when the value does not match" do
      rules = CORS::Rules.new { |rules| rules.required "content-type", %r|image/jpe?g| }
      errors = rules.validate({ "content-type" => "image/png" })

      errors.should eq({ "content-type" => [:match, rules.first] })
    end

    it "can match a regexp" do
      rules = CORS::Rules.new { |rules| rules.required "content-type", %r|image/jpe?g| }

      rules.validate({ "content-type" => "image/jpeg" }).should be_empty
      rules.validate({ "content-type" => "image/jpg" }).should be_empty
      rules.validate({ "content-type" => "image/png" }).should_not be_empty
    end

    it "can match a literal string" do
      rules = CORS::Rules.new { |rules| rules.required "content-type", "image/jpeg" }

      rules.validate({ "content-type" => "image/jpeg" }).should be_empty
      rules.validate({ "content-type" => "image/jpg" }).should_not be_empty
    end

    it "can match an array" do
      rules = CORS::Rules.new { |rules| rules.required "content-type", ["image/jpeg", "image/png"] }

      rules.validate({ "content-type" => "image/jpeg" }).should be_empty
      rules.validate({ "content-type" => "image/png" }).should be_empty
      rules.validate({ "content-type" => "image/jpg" }).should_not be_empty
    end

    it "can match a block" do
      rules = lambda do |rules|
        rules.required "content-type" do |type|
          "image/jpeg" == type
        end
      end
      rules = CORS::Rules.new(&rules)

      rules.validate({ "content-type" => "image/jpeg" }).should be_empty
      rules.validate({ "content-type" => "image/png" }).should_not be_empty
    end
  end

  describe "#optional" do
    it "results in no error when the value is missing" do
      rules = CORS::Rules.new { |rules| rules.optional "method", // }
      errors = rules.validate({})

      errors.should be_empty
    end

    it "results in an error when the value is present but does not match" do
      rules = CORS::Rules.new { |rules| rules.optional "content-type", %r|image/jpe?g| }
      errors = rules.validate({ "content-type" => "image/png" })

      errors.should eq({ "content-type" => [:match, rules.first] })
    end
  end
end
