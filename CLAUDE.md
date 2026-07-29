# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ruby SDK (`featureflow` gem) for Featureflow, a feature-flag SaaS. It polls the Featureflow flag-delivery backend (`event-server`/`sdk-server` in the wider workspace) for feature rules, evaluates them client-side per user, and reports evaluation events back. Includes an optional Rails integration (Railtie + generator).

## Commands

```bash
bundle install

bundle exec rake            # default task: runs cucumber (tags 'not @integration')
bundle exec rake cucumber   # same, explicit
bundle exec rake spec       # rspec — note: no spec/ directory currently exists, this task has nothing to run
bundle exec cucumber features/rules.feature   # run a single feature file
bundle exec cucumber features/rules.feature:12  # run a single scenario by line

bundle exec cucumber --profile integration  # @integration-tagged scenarios (see below)

FEATUREFLOW_SERVER_KEY=sdk-srv-env-<key> bundle exec ruby examples/harness/server.rb  # manual local harness, see examples/harness/README.md
```

There are no unit tests under `spec/`; all behavioral testing is Cucumber features under `features/`. `rake spec` is wired up but currently has nothing to execute.

The default profile runs two sets of `.feature` files: `testbed/gherkin` (the shared `featureflow-sdk-testbed` submodule — cross-SDK scenarios, don't edit them here) and `features/` (Ruby-specific scenarios: `ruby_client.feature` covers the constructor forms and the Rails controller helper, `date_conditions.feature` covers timezone handling in `before`/`after`). Step definitions for both live in `features/step_definitions/`.

### Integration tests

`features/integration.feature` is tagged `@integration` and excluded from the default profile (`cucumber.yml`: `default: --tags 'not @integration'`). It drives a real `Featureflow::Client` against a live backend and requires:

- `FEATUREFLOW_TEST_API_KEY` — a real server SDK key (`sdk-srv-env-...`) for an environment with a `test-integration` feature matching the Examples table in that feature file
- `FEATUREFLOW_TEST_BASE_URL` (optional) — override the endpoint (e.g. to point at a local `event-server`/`sdk-server` instead of production)

Run with `bundle exec cucumber --profile integration`. One scenario group ("throw an error when the wrong/no key is used") is currently unreachable/documented-as-broken: `PollingClient#load_features` rescues all errors internally and only logs them, so a bad or missing key never raises synchronously from `Client.new` — see the comment block at the top of `features/integration.feature`.

## Architecture

Everything is wired through `lib/featureflow.rb`, which holds process-wide singletons (`Featureflow.configuration`, `Featureflow.client`) — the README's documented usage pattern is one shared `Featureflow::Client` instance per app.

**Initialization flow** (`Client#initialize` in [lib/featureflow/client.rb](lib/featureflow/client.rb)):
1. Validates `Configuration` ([lib/featureflow/configuration.rb](lib/featureflow/configuration.rb)) — holds `api_key`, `endpoint` (default `https://app.featureflow.io`), `event_endpoint` (default `https://events.featureflow.io`), `disable_events`, `with_features` (pre-registered failover features via `Featureflow::Feature.create`), and `logger`.
2. Builds a map of failover variants from `with_features`.
3. Unless `disable_events`, creates an `EventsClient` and registers `with_features` with the backend.
4. Starts a `PollingClient`, which does a synchronous initial `load_features` GET against `<endpoint>/api/sdk/v1/features` (ETag-conditional), then polls on a background `Thread` every `poll_interval` seconds (default 10s in `Client`, 30s if `PollingClient` is used standalone). Feature data is cached in an instance var guarded by a class-level `Mutex` (`PollingClient::LOCK`).

**Evaluation flow** (`Client#evaluate`):
- Accepts a `user` as either a raw String id or a Hash built by `Featureflow::UserBuilder` ([lib/featureflow/user_builder.rb](lib/featureflow/user_builder.rb)); a String is auto-wrapped. The user's own id is injected into `attributes['featureflow.user.id']` before evaluation — targeting rules can match on it like any other attribute.
- Constructs an `Evaluate` object ([lib/featureflow/evaluate.rb](lib/featureflow/evaluate.rb)) which resolves the variant *at construction time*, not lazily:
  - No cached feature → falls back to the registered failover variant, or `'off'` if none was registered.
  - Feature disabled → the feature's configured `offVariantKey`.
  - Otherwise, iterates the feature's `rules` in order, evaluating each rule's audience conditions against the user (`EvaluateHelpers.rule_matches`), and for the first matching rule computes a variant via consistent-hash bucketing (`EvaluateHelpers.calculate_hash` = SHA-1 of `salt:featureKey:userId`, then `EvaluateHelpers.get_variant_value` mods into 1–100, then `get_variant_split_key` walks the rule's `variantSplits` percentages to pick the bucket). This bucketing scheme must stay consistent with the other Featureflow SDKs/servers (see the cross-repo workspace conventions on variant bucketing).
  - `defaultRule` on a rule always matches.
- `Evaluate#is?`/`#on?`/`#off?` fire an evaluation event to `EventsClient` as a side effect of checking the value (not at construction) — calling `.is?`/`.on?`/`.off?` on the same `Evaluate` multiple times reports multiple events.
- Condition operators live in `lib/featureflow/conditions.rb`.

**Events** (`EventsClient`, [lib/featureflow/events_client.rb](lib/featureflow/events_client.rb)): fire-and-forget. Feature registration (`register_features`) is sent immediately on its own `Thread`. Evaluation events are pushed onto an in-process `Queue` and flushed by a background scheduler thread every 10s (or immediately if the queue reaches 10,000), POSTed as a batch to `/api/sdk/v1/events`; feature registration goes to `/api/sdk/v1/register`. All HTTP is via `excon`; failures are logged, never raised.

**Rails integration** (`lib/featureflow/rails/`, `lib/generators/featureflow_generator.rb`): a Railtie autoloads when `Rails` is defined; the generator (`rails generate featureflow <api_key>`) validates the key format (`sdk-srv-env-[a-f0-9]{32}`) and writes a `config/initializers/featureflow.rb` calling `Featureflow.configure`.

## Working in this repo

- The gemspec deliberately excludes `test/`, `spec/`, `features/`, and `examples/` from the packaged gem (`spec.files` filter) — test-only and example-only additions there never need gemspec changes.
- `examples/harness/server.rb` is a small WEBrick app (dev-only dependency) that loads the SDK straight from `lib/` for manually testing against a real environment/key — no build step needed, unlike the equivalent harness in `featureflow-node-sdk`.
- `Featureflow::VERSION` in [lib/featureflow/version.rb](lib/featureflow/version.rb) is the single source of truth for gem version; bump it as its own step when releasing (see `CHANGELOG.md`).
- This repo is part of a larger multi-repo Featureflow workspace; the wire format for `/api/sdk/v1/*` (features endpoint, events endpoint, ETag/ headers, ETag behavior, ISO-8601 timestamp) must stay compatible with `event-server`, `sdk-server`, and `featureflow-edge-proxy`, and the SHA-1 bucketing algorithm must match the other language SDKs.
- **Implicit attributes** (`featureflow.user.id`, `featureflow.date`, `featureflow.hourofday`) are injected into user attributes by `Client#evaluate` at evaluation time — never by `UserBuilder#build` — so date/hour rules match the moment of evaluation. **Partial evaluation** (*deferring* date/hourofday conditions to the client for CDN cacheability) is a different thing and is `sdk-server`-only, serving the JS client SDKs via `/evaluate`; server SDKs like this one evaluate those conditions locally against "now" instead.
- The `before`/`after` condition operators compare parsed instants (`Conditions.to_epoch`), not strings — rule values from the dashboard carry arbitrary UTC offsets (e.g. `+04:00`) that lexicographic comparison mishandles.
- Watch symbol-vs-string hash keys in the evaluation path: user hashes built in Ruby (`UserBuilder`) have **symbol** keys (`user[:id]`, `user[:attributes]`), while feature/rule data from `JSON.parse` has **string** keys (`feature['rules']`, `rule['variantSplits']`). Mixing them fails silently (`nil`), e.g. a past bug where `@user['id']` made every user hash to the same rollout bucket.
