# Scenarios that pin the host timezone set ENV['TZ'], which Ruby consults on every
# local-time conversion. Always put it back, or one scenario's timezone silently
# becomes the next one's.
After do
  ENV['TZ'] = @original_tz if instance_variable_defined?(:@original_tz)
end
