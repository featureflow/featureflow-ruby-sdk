module Featureflow
  class Conditions
    def self.test(op, a, b)
      b = b[0] unless %w(in notIn).include? op
      case op
      when 'equals'
        a.eql? b
      when 'contains'
        a.include? b
      when 'startsWith'
        a.start_with? b
      when 'endsWith'
        a.end_with? b
      when 'matches'
        a.match? Regexp.new(b)
      when 'in'
        b.include? a
      when 'notIn'
        !b.include? a
      when 'greaterThan'
        a > b
      when 'greaterThanOrEqual'
        a >= b
      when 'lessThan'
        a < b
      when 'lessThanOrEqual'
        a <= b
      when 'before'
        a < b
      when 'after'
        a > b
      else
        false
      end
    end
  end
end