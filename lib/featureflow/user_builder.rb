module Featureflow
  class UserBuilder
    def initialize(id)
      raise ArgumentError, 'Parameter id must be a String' unless id.is_a?(String) && !id.empty?
      @user_id = id
      @attributes = {}
      self
    end

    def with_attributes(hash)
      raise ArgumentError, 'Parameter hash must be a Hash' unless hash.is_a?(Hash)
      normalized = {}
      hash.each do |k, v|
        raise ArgumentError, "Value for #{k} must be a valid 'primitive' JSON datatype" unless valid_attribute?(v)
        normalized[k.to_s] = v
      end
      @attributes = @attributes.merge(normalized)
      self
    end

    def build
      {
        id: @user_id,
        attributes: @attributes
      }
    end

    private def valid_attribute?(attributes)
      Array(attributes).all? do |v|
        [String, Numeric, TrueClass, FalseClass].any? { |type| v.is_a?(type) }
      end
    end
  end
end
