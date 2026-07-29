# The whole suite runs on a deliberately non-UTC zone.
#
# A condition value with no timezone information -- including a date-only value such as
# "2026-07-03" from the dashboard's date picker -- denotes UTC, never the host's local
# time (testbed CONTRACT.md, "Operators"). An implementation that parses it in local
# time passes those assertions anyway whenever the runner sits on UTC, which is exactly
# how the bug survived unnoticed in three SDKs. features/date_conditions.feature pins
# its own zone per scenario, but the shared testbed scenarios do not, so without a
# default they are inert on a UTC CI box.
#
# Asia/Tokyo is +09:00 all year: a whole-hour offset with no DST, so expected instants
# stay easy to reason about. Do not remove this to make a failing date scenario go green.
DEFAULT_TEST_TZ = 'Asia/Tokyo'

BeforeAll do
  ENV['TZ'] = DEFAULT_TEST_TZ
end

# Scenarios that pin the host timezone set ENV['TZ'], which Ruby consults on every
# local-time conversion. Always put it back, or one scenario's timezone silently
# becomes the next one's.
After do
  ENV['TZ'] = @original_tz if instance_variable_defined?(:@original_tz)
end
