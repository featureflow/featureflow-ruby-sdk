# Change log
## [0.8.0] - 2026-08-13
### Added
- `application` configuration option (falling back to the `FEATUREFLOW_APPLICATION`
  environment variable): names this workload, sent as `X-Featureflow-Application` on
  every request so the dashboard can attribute usage and flag evaluations per
  application. Slug-validated client-side (case forgiven; an invalid value is dropped
  with a warning and no header is sent).

## [0.7.0] - 2026-08-11
### Fixed
- Condition operators fail closed instead of raising into the host application: an
  invalid `matches` regex, a non-string attribute against a string operator, or a
  string/number type mismatch on a comparison operator is now a no-match, never an
  exception.
- `before`/`after` compare parsed instants rather than strings, so rule values with
  arbitrary UTC offsets compare correctly; date-only values are read as UTC midnight
  on every host, not local midnight.
- Rollout bucketing hashed every user to the same bucket (`user['id']` vs
  `user[:id]`); percentage splits now distribute correctly.
- `RailsClient#evaluate` and `UserBuilder#with_attributes` were broken; both work
  again, and the Rails generator accepts current `sdk-srv-env-` keys.
### Added
- `Featureflow::Client.new(api_key: '...')` accepts a configuration Hash; unknown
  options raise rather than being silently dropped.
- Implicit `featureflow.date` / `featureflow.hourofday` attributes are injected at
  evaluation time, matching the other server SDKs.
### Changed
- Requires Ruby >= 3.1 (excon ~> 1.5).
- The packaged gem now contains only `lib/`, README, CHANGELOG and LICENSE.

## [0.6.0] - 2018-12-17
### Fixed 
- Use User over Context matching all other SDKs
- Use events.featureflow.io endpoint
## [0.5.1] - 2017-07-17
### Fixed 
- Feature registration now compatible with Ruby 2.4
## [0.5.0] - 2017-06-29
### Fixed
- Changed `feature[:failoverVariant]` to `feature[:failover_variant]` for feature registration
## [0.4.0] - 2017-06-26
### Changed
- Added Rails support
## [0.3.3] - 2017-06-23
### Changed
- Initial Release