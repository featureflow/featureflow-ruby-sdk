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

    # Both operands must be strings for a string operator to mean anything.
    def self.both_strings?(a, b)
      a.is_a?(String) && b.is_a?(String)
    end

    # Numeric-to-numeric or string-to-string only. Mixing the two raises in Ruby, and
    # coercing would answer version comparisons wrongly.
    def self.comparable?(a, b)
      (a.is_a?(Numeric) && b.is_a?(Numeric)) || (a.is_a?(String) && b.is_a?(String))
    end

    def self.test(op, a, b)
      case op
      when 'equals'
        a.eql? b[0]
      # The string operators assume both sides are strings. A numeric attribute against
      # `contains` raised NoMethodError straight into the host application — the same
      # fail-closed violation as the invalid regex below, and reachable the same way,
      # from a rule somebody typed into the dashboard. Python already guards these with
      # an explicit type check; this brings Ruby into line. A type mismatch is a
      # no-match, not an exception.
      when 'contains'
        both_strings?(a, b[0]) && a.include?(b[0])
      when 'startsWith'
        both_strings?(a, b[0]) && a.start_with?(b[0])
      when 'endsWith'
        both_strings?(a, b[0]) && a.end_with?(b[0])
      when 'matches'
        # The pattern is untrusted configuration, not code: it comes from a targeting
        # rule somebody typed into the dashboard, so a malformed one like "[unclosed"
        # is a user's mistake rather than a bug in the SDK. The contract
        # (featureflow-client-sdk-testbed/CONTRACT.md, "Operators") therefore requires
        # an invalid regex to return false — a flag SDK must degrade rather than take
        # the host application down with it.
        #
        # Only the regex failure is rescued, never everything: RegexpError for a
        # pattern that will not compile, TypeError for a value that is not a string at
        # all. A genuine bug anywhere else still surfaces.
        begin
          a.match? Regexp.new(b[0])
        rescue RegexpError, TypeError
          false
        end
      when 'in'
        b.include? a
      when 'notIn'
        !b.include? a
      # Comparing a String with a Numeric raises ArgumentError in Ruby, so an attribute
      # whose type does not match the rule's took the host application down. The
      # contract requires a numeric operator to return false on non-numeric input
      # rather than coercing — "1.10.0" > "1.9.0" must not silently succeed — so a
      # mismatch is simply a no-match. String-to-string comparison is kept, since Ruby
      # orders strings meaningfully and the server behaves the same way.
      when 'greaterThan'
        comparable?(a, b[0]) && a > b[0]
      when 'greaterThanOrEqual'
        comparable?(a, b[0]) && a >= b[0]
      when 'lessThan'
        comparable?(a, b[0]) && a < b[0]
      when 'lessThanOrEqual'
        comparable?(a, b[0]) && a <= b[0]
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