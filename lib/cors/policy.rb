module CORS
  # @private
  module Policy
    module ClassMethods
      attr_reader :rules

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
      def included(other)
        other.extend(ClassMethods)
      end
    end

    def initialize(attributes)
      self.attributes = Hash[attributes.map { |k, v| [k.to_s.downcase, v] }]
      self.errors = rules.validate(self.attributes)
    end

    def rules
      self.class.rules or raise "no rules defined for policy #{inspect}"
    end

    def valid?
      errors.empty?
    end

    attr_reader :attributes
    attr_reader :errors

    private

    attr_writer :errors
    attr_writer :attributes
  end
end
