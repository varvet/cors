# encoding: utf-8
require "openssl"
require "base64"

# @public
class Manifest
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
    # @param [#has_key?, #[]]
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

  def initialize(attributes, &block)
    @attributes = Hash[attributes.map { |k, v| [k.to_s.downcase, v] }]
    @errors     = {}

    if block_given?
      @rules = Rules.new(&block)
    else
      raise ArgumentError, "manifest rules must be specified by a block, no block given"
    end
  end

  attr_reader :attributes
  attr_reader :errors
  attr_reader :rules

  def valid?
    @errors = rules.validate(attributes)
    @errors.empty?
  end

  def manifest
    [].tap do |manifest|
      manifest << attributes["method"].upcase
      manifest << attributes["md5"]
      manifest << attributes["content-type"]
      manifest << attributes["date"]
      normalized_headers.each do |(header, *values)|
        manifest << "#{header}:#{values.join(",")}"
      end
      manifest << attributes["filename"]
    end.join("\n")
  end

  def sign(access_key, secret_access_key)
    return unless valid?
    digest = OpenSSL::HMAC.digest("sha1", secret_access_key, manifest)
    signature = Base64.strict_encode64(digest)
    "AWS #{access_key}:#{signature}"
  end

  protected

  def normalized_headers
    attributes.select  { |property, _| property =~ /x-amz-/ }
              .map     { |(header, values)| [header.downcase, values] }
              .sort_by { |(header, _)| header }
  end
end
