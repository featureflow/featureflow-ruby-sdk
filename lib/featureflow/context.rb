class Featureflow::Context
  attr_accessor :key, :values

  def initialize(key, values = {})
    @key = key
    @values = values
  end

  def self.from_params(*args)
    if args.length == 2
      new(args.first, args.last)
    elsif args.first.is_a?(String)
      new(args.first, {})
    elsif args.first.is_a?(Hash)
      key = if args.first.key?(:key)
        args.first[:key]
      else
        args.first['key']
      end

      new(key, args.first)
    elsif args.first.is_a?(Featureflow::Context)
      args.first
    else
      raise
    end
  end

  def validate
    raise ArgumentError, 'key is required' unless @key.present?
    raise ArgumentError, 'values must be a Hash' unless @values.is_a?(Hash)
    @values.each do |k, v|
      raise ArgumentError, "Value for #{k} must be a valid 'primitive' JSON datatype" unless valid_value?(v)
    end
  end

  def serialize
    validate

    {
      key: @key,
      values: serialize_values
    }
  end

  def serialize_values
    hash = default_values.merge(@values).dup
    hash.each { |k, v| hash[k.to_s] = h.delete(k) unless k.is_a?(String) }
    hash
  end

  def default_values
    {
      'featureflow.key' => @key,
      'featureflow.date' => Time.now.iso8601
    }
  end

  def valid_value?(values)
    Array(values).all? do |v|
      [String, Numeric, TrueClass, FalseClass].any? { |type| v.is_a?(type) }
    end
  end
end