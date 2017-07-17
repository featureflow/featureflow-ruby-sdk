module Featureflow
  class Feature
    def self.create(key, failover_variant = 'off')
      raise ArgumentError, 'Parameter key must be a String' unless valid_key?(key)
      raise ArgumentError, 'Parameter failover_variant must be a String containing only letters, numbers, hyphens or underscores' unless valid_key?(failover_variant) || failover_variant.is_a?(NilClass)
      {
          key: key,
          failover_variant: failover_variant,
          variants: [{
                       key: 'on',
                       name: 'On'
                     },
                     {
                       key: 'off',
                       name: 'Off'
                     }]
      }
    end
  end
end

def valid_key?(value)
  value.is_a?(String) && !value.empty? &&  value =~ /^[a-z\-\_0-9]+$/
end
