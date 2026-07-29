require 'date'
require 'time'

module Featureflow
  class Conditions
    # Mirrors the Node SDK's dateParse: dates compare by instant, not by string,
    # so ISO values with different UTC offsets (e.g. "+04:00" vs "Z") compare correctly.
    #
    # A value carrying no timezone information is read as UTC, per the SDK contract
    # ("A date-only value denotes UTC midnight"): the dashboard's date picker emits
    # date-only values like "2026-07-03", and reading those as *local* midnight would
    # make a scheduled rollout fire at a different instant on every host in a fleet.
    # Values with an explicit offset or "Z" keep their instant, unshifted.
    def self.to_epoch(value)
      case value
      when Time then value.to_f
      when Numeric then value.to_f
      when String
        begin
          parsed = Time.parse(value)
          # Time.parse silently falls back to the process's timezone when the value
          # carries no zone; adding back the offset it applied re-reads the same
          # wall-clock components as UTC. Date._parse only reports :offset when the
          # value actually stated a zone.
          parsed += parsed.utc_offset unless Date._parse(value).key?(:offset)
          parsed.to_f
        rescue ArgumentError, TypeError, RangeError
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