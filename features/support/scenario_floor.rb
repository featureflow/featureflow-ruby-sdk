# A floor on how many scenarios the suite is allowed to run.
#
# --strict-undefined (see cucumber.yml and the Rakefile) catches steps that no longer
# match a definition. It cannot catch a suite that stopped loading its feature files at
# all: cucumber happily reports "0 scenarios" and exits zero. testbed/ is a git
# submodule, so an uninitialised or empty checkout does exactly that.
#
# This is a floor, not an exact count -- scenarios are added to the testbed regularly,
# so the number below is expected to lag the real total. Raise it when the testbed
# grows; never lower it to make a sudden drop go green without first working out where
# the missing scenarios went.
MIN_SCENARIOS = 138 # 145 run today

scenarios_run = 0

After do
  scenarios_run += 1
end

AfterAll do
  if scenarios_run < MIN_SCENARIOS
    raise "Only #{scenarios_run} scenarios ran, expected at least #{MIN_SCENARIOS}. " \
          'The testbed submodule is probably uninitialised (run `git submodule update ' \
          '--init`), or the paths/tags in cucumber.yml no longer select the shared features.'
  end
end
