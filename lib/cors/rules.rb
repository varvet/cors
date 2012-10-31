module CORS
  # Internal class for handling rule definitions and validation.
  #
  # @private
  class Rules
    include Enumerable

    # @example
    #   Rules.new do |rules|
    #     rules.required …
    #     rules.optional …
    #   end
    #
    # @yield [self]
    # @yieldparam [Rules] self
    def initialize
      @rules = []
      @rules_map = Hash.new { |h, k| h[k] = [] }
      yield self if block_given?
    end

    # Yields each rule in order, or returns an Enumerator
    # if no block was given.
    #
    # @example
    #   rules.each do |rule|
    #     …
    #   end
    #
    # @example without block
    #   rules.each.with_index do |rule, index|
    #     …
    #   end
    #
    # @return [Hash<:name, :matcher, :required>, Enumerator]
    def each
      if block_given?
        @rules.each { |rule| yield rule }
      else
        @rules.enum_for(__method__)
      end
    end

    # Retrieve a list of rules for a given attribute.
    #
    # @param name same name as given to {#required} or {#optional}
    # @return [Array<Hash<:name, :matcher, :required>>, nil] list of rules for attribute, or nil.
    def [](name)
      @rules_map.fetch(name, nil)
    end

    # Declare a required rule; the value must be present, and it must
    # match the given constraints or block matcher.
    #
    # @example with a regexp
    #   @required "content-type", %r|image/jpe?g|
    #
    # @example with a string
    #   required "content-type", "image/jpeg"
    #
    # @example with an array
    #   required "content-type", ["image/jpeg", "image/jpg"]
    #
    # @example with a block
    #   required "content-type" do |value|
    #     value =~ %r|image/jpe?g|
    #   end
    #
    # @param name can be any valid hash key of the parameters to be validated
    # @param [Regexp, String, Array] constraints
    # @yield [value]
    # @yieldparam value of the key `name` in the parameters to be validated
    # @return [Hash] the newly created rule
    def required(name, constraints = nil, &block)
      matcher = if block_given? then block
      elsif constraints.is_a?(Regexp)
        constraints.method(:===)
      elsif constraints.is_a?(String)
        constraints.method(:===)
      elsif constraints.is_a?(Array)
        constraints.method(:include?)
      else
        raise ArgumentError, "unknown matcher #{(constraints || block).inspect}"
      end

      { name: name, matcher: matcher, required: true }.tap do |rule|
        @rules << rule
        @rules_map[name] << rule
      end
    end

    # Same as {#required}, but the rule won’t run if the key is not present.
    #
    # @param (see required)
    # @return (see required)
    # @see required
    def optional(*args, &block)
      required(*args, &block).tap { |rule| rule[:required] = false }
    end

    # Validate a set of attributes against the defined rules.
    #
    # @example
    #   errors = rules.validate(params)
    #   if errors.empty?
    #     # valid
    #   else
    #     # not valid, errors is a hash of { name => [ reason, rule ] }
    #   end
    #
    # @see required
    # @param [#has_key?, #[]] attributes
    # @return [Hash<name: [reason, rule]>] list of errors, empty if attributes are valid
    def validate(attributes)
      each_with_object({}) do |rule, failures|
        fail = lambda do |reason|
          failures[rule[:name]] = [reason, rule]
        end

        unless attributes.has_key?(rule[:name])
          fail[:required] if rule[:required]
          next
        end

        unless rule[:matcher].call(attributes[rule[:name]])
          fail[:match]
        end
      end
    end
  end
end
