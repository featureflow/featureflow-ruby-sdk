module Featureflow
  class ContextBuilder
    def initialize(key)
      raise ArgumentError, 'Parameter key must be a String' unless key.is_a?(String) && !key.empty?
      @context_key = key
      @values = {}
      self
    end

    def with_values(hash)
      raise ArgumentError, 'Parameter hash must be a Hash' unless hash.is_a?(Hash)
      hash = hash.dup
      hash.each do |k, v|
        raise ArgumentError, "Value for #{k} must be a valid 'primitive' JSON datatype" unless valid_value?(v)
        hash[k.to_s] = h.delete(k) unless k.is_a?(String)
      end
      @values = @values.merge(hash)
      self
    end

    def build
      {
        key: @context_key,
        values: @values
      }
    end

    private def valid_value?(values)
      Array(values).all? do |v|
        [String, Numeric, TrueClass, FalseClass].any? { |type| v.is_a?(type) }
      end
    end
  end
end
