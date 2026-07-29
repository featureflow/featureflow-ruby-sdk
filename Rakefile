require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "cucumber/rake/task"
require_relative "features/support/testbed_manifest"

RSpec::Core::RakeTask.new(:spec)

# Keep in step with cucumber.yml's default profile -- including --strict-undefined /
# --strict-pending, without which cucumber prints "N undefined" and still exits zero.
# The testbed feature files come from the shared manifest rather than a glob; see
# features/support/testbed_manifest.rb.
Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = "-r features/step_definitions -r features/support " \
    "--strict-undefined --strict-pending " \
    "--tags 'not @integration and not @builder-injects-implicit-attributes and not @json-value' " \
    "#{TestbedManifest.paths.join(' ')} features"
end

task :default => :cucumber
