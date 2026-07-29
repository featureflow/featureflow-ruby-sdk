require_relative 'testbed_manifest'

# Counterpart to --strict-undefined: that catches a step that stopped matching, this
# catches a whole feature file that was never wired up. Without it, the explicit path list
# in cucumber.yml would silently ignore anything added to the testbed upstream.
AfterAll do
  present = Dir.glob(File.join(TestbedManifest::GHERKIN_DIR, '*.feature')).map { |p| File.basename(p) }

  if present.empty?
    raise "No feature files found in #{TestbedManifest::GHERKIN_DIR} -- the testbed " \
          'submodule is probably uninitialised (run `git submodule update --init`).'
  end

  known = TestbedManifest::SUPPORTED + TestbedManifest::UNSUPPORTED.keys

  unaccounted = present - known
  unless unaccounted.empty?
    raise "Testbed feature file(s) #{unaccounted.join(', ')} are in neither SUPPORTED nor " \
          'UNSUPPORTED in features/support/testbed_manifest.rb. Add step definitions and ' \
          'list the file as supported, or record there why it is not implemented.'
  end

  missing = known - present
  unless missing.empty?
    raise "Feature file(s) #{missing.join(', ')} are listed in testbed_manifest.rb but no " \
          'longer exist in the testbed -- they were probably renamed upstream.'
  end
end
