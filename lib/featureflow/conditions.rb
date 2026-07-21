require 'time'

module Featureflow
  class Conditions
    # Mirrors the Node SDK's dateParse: dates compare by instant, not by string,
    # so ISO values with different UTC offsets (e.g. "+04:00" vs "Z") compare correctly.
    def self.to_epoch(value)
      case value
      when Time then value.to_f
      when Numeric then value.to_f
      when String
        begin
          Time.parse(value).to_f
        rescue ArgumentError, TypeError
          nil
        end
      end
    end

    def self.test(op, a, b)
      case op
      when 'equals'
        a.eql? b[0]
      when 'contains'
        a.include? b[0]
      when 'startsWith'
        a.start_with? b[0]
      when 'endsWith'
        a.end_with? b[0]
      when 'matches'
        a.match? Regexp.new(b[0])
      when 'in'
        b.include? a
      when 'notIn'
        !b.include? a
      when 'greaterThan'
        a > b[0]
      when 'greaterThanOrEqual'
        a >= b[0]
      when 'lessThan'
        a < b[0]
      when 'lessThanOrEqual'
        a <= b[0]
      when 'before'
        a_time = to_epoch(a)
        b_time = to_epoch(b[0])
        !!(a_time && b_time && a_time < b_time)
      when 'after'
        a_time = to_epoch(a)
        b_time = to_epoch(b[0])
        !!(a_time && b_time && a_time > b_time)
      else
        false
      end
    end
  end
end