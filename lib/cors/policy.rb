module CORS
  # Mixin for declaring CORS Policies.
  #
  # Classes who include this mixin should define both #manifest and #sign.
  #
  # @example
  #   class S3
  #     include CORS::Policy
  #
  #     def manifest
  #       # create the manifest
  #       [].tap do |manifest|
  #         manifest << attributes["method"].upcase
  #       end.join("\n")
  #     end
  #
  #     def sign(access_key, secret_access_key)
  #       # sign the manifest
  #     end
  #   end
  #
  #   policy = S3.create do |rules|
  #     rules.required "method", %w[GET]
  #   end
  #
  # @see CORS::Rules
  module Policy
    # Class methods added to includers of {CORS::Policy}.
    #
    # @see {CORS::Policy}
    module ClassMethods
      # @return [CORS::Rules]
      attr_reader :rules

      # Create an instance of this policy, declaring rules as well.
      #
      # @example
      #   upload_policy = CORS::Policy::S3.create do |rules|
      #     rules.required "method", %w[GET]
      #   end
      #
      # @raise [ArgumentError] if no block is supplied
      # @yield [rules] allows you to declare rules on the newly created policy
      # @yieldparam [CORS::Rules] rules
      def create(*, &block)
        unless block_given?
          raise ArgumentError, "manifest rules must be specified by a block, no block given"
        end

        Class.new(self) do
          @rules = CORS::Rules.new(&block)
        end
      end
    end

    class << self
      # Extends the target with {ClassMethods}
      #
      # @param [#extend] other
      def included(other)
        other.extend(ClassMethods)
      end
    end

    # Initialize the policy with the given attributes and validate the attributes.
    #
    # @note attribute keys are converted to strings and downcased for validation
    # @note validations are run instantly
    #
    # @param [Hash] attributes
    # @see errors
    # @see valid?
    def initialize(attributes)
      self.attributes = Hash[normalize_attributes(attributes)]
      self.errors = rules.validate(self.attributes)
    end

    # @return [Hash<String, Object>]
    attr_accessor :attributes
    protected :attributes=

    # @return [Hash]
    attr_accessor :errors
    protected :errors=

    # @raise [RuntimeError] raises if no rules have been defined
    # @return [CORS::Rules] rules assigned to this policy
    def rules
      self.class.rules or raise "no rules defined for policy #{inspect}"
    end

    # @return [Boolean] true if no errors was encountered during validation in {#initialize}
    def valid?
      errors.empty?
    end

    # Signs the manifest, but only if it is {#valid?}.
    #
    # @note should not be overridden by the includers!
    # @return (see #sign!)
    def sign(*args, &block)
      sign!(*args, &block) if valid?
    end

    # @note should be overridden by includers!
    # @return [String] signature derived from the manifest
    def sign!(*)
      raise NotImplementedError, "#sign has not been defined on #{inspect}"
    end

    protected

    def normalize_attributes(attributes)
      attributes = attributes.map { |k, v| [k.to_s.downcase, v] }
      attributes.select { |(k, _)| rules[k] }
    end
  end
end
