# Which shared-testbed feature files this SDK runs.
#
# The testbed carries scenarios for behaviour this SDK does not implement, so the feature
# files are listed rather than globbed -- globbing `testbed/gherkin` wholesale turns every
# upstream addition into a hard --strict-undefined failure here.
#
# A bare list trades one silent failure for another, though: a file added upstream would
# simply never run, which is the drift the testbed exists to prevent. So every .feature in
# the testbed must appear in exactly one of the two lists below, and the check in
# testbed_completeness.rb fails the suite on any that does not. Promoting a file from
# UNSUPPORTED to SUPPORTED is then a deliberate act with a visible diff.
#
# This file is loaded both by cucumber's support tree and by cucumber.yml (which is ERB-
# evaluated), so the paths cucumber runs and the paths checked here cannot drift apart.

module TestbedManifest
  GHERKIN_DIR = 'testbed/gherkin'.freeze

  SUPPORTED = %w[
    application_tag.feature
    bucketing.feature
    conditions.feature
    feature_evaluation.feature
    json_value.feature
    rules.feature
    user_builder.feature
  ].freeze

  # Each entry records why, so an unimplemented suite cannot quietly become permanent.
  UNSUPPORTED = {
    'events.feature' => 'client-side event summarisation is not implemented in this SDK',
    'goals.feature' => 'goal tracking is not implemented in this SDK (SDK-BACKLOG item 7)',
    'sdk_config.feature' => 'server-driven SDK config is not implemented in this SDK',
    'tracked_exposures.feature' => 'per-flag exposure fidelity is not implemented in this SDK'
  }.freeze

  # json_value.feature is listed as supported but tag-excluded at the command line; it is
  # here so that removing the tag exclusion is all that is needed to start running it.
  def self.paths
    SUPPORTED.map { |name| File.join(GHERKIN_DIR, name) }
  end
end
