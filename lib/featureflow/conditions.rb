module Featureflow
  class Conditions
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
        a < b[0]
      when 'after'
        a > b[0]
      else
        false
      end
    end
  end
end