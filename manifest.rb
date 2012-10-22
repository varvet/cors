# encoding: utf-8
require "openssl"
require "base64"

class Manifest
  class Rules
    include Enumerable

    def initialize
      @rules = []
      yield self if block_given?
    end

    def each
      if block_given?
        @rules.each { |rule| yield rule }
      else
        @rules.enum_for(__method__)
      end
    end

    def required(name, constraints = nil, options = {}, &block)
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

      { name: name, matcher: matcher, options: options, required: true }.tap do |rule|
        @rules << rule
      end
    end

    def optional(*args, &block)
      required(*args, &block).tap { |rule| rule[:required] = false }
    end
  end

  def initialize(attributes, &block)
    @attributes = Hash[attributes.map { |k, v| [k.to_s.downcase, v] }]
    @errors     = {}

    unless block_given?
      raise ArgumentError, "manifest rules must be specified by a block, no block given"
    end

    @rules = Rules.new(&block)
  end

  attr_reader :attributes
  attr_reader :errors
  attr_reader :rules

  def validate
    @errors = rules.each_with_object({}) do |rule, failures|
      fail = lambda do |reason|
        failures[rule[:name]] = [reason, rule]
      end

      unless attributes.has_key?(rule[:name])
        fail[:required] if rule[:required]
        next
      else
        value = attributes[rule[:name]]
      end

      unless rule[:matcher].call(value)
        fail[:match]
      end
    end

    errors.none?
  end

  alias valid? validate

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
