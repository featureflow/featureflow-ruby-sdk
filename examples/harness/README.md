# SDK harness

Small WEBrick app in `server.rb` that uses the SDK straight from `../../lib` (no build step -- Ruby doesn't need one).

```bash
FEATUREFLOW_SERVER_KEY=srv-env-<your_key> bundle exec ruby examples/harness/server.rb

# Staging (or any custom app host)
FEATUREFLOW_BASE_URL=https://beta.featureflow-staging.com FEATUREFLOW_SERVER_KEY=srv-env-<your_key> bundle exec ruby examples/harness/server.rb
```

Defaults to `http://127.0.0.1:3456/` (override with `PORT`). The home page can trigger evaluations in the browser; JSON endpoints:

- `GET /health`
- `GET /api/config`
- `GET /api/evaluate?feature=<key>&userId=<id>&role=<role>&tier=<tier>`

Env vars:

- `FEATUREFLOW_SERVER_KEY` (required) -- your environment's server API key (`srv-env-...`)
- `FEATUREFLOW_BASE_URL` (optional) -- override the features endpoint, e.g. for staging
- `FEATUREFLOW_EVENTS_URL` (optional) -- override the events endpoint
- `FEATUREFLOW_DISABLE_EVENTS` (optional) -- the harness disables the events client by default (no calls to the events API); set to `false` to send evaluation events like a full production client
- `PORT` (optional) -- defaults to `3456`

An `example-feature` feature is pre-registered with a failover variant of `off` -- this matches the default feature created in any new Featureflow environment, so a fresh environment's key works out of the box. If it doesn't exist yet, evaluation falls back to the `off` failover.

This directory is for local development only and is not published in the gem (see the `spec.files` filter in `featureflow.gemspec`, which excludes `examples/`).

## .env file

The harness auto-loads a `.env` file from the repo root (gitignored -- copy [.env.example](../../.env.example)), so you can keep your key there instead of passing it on the command line:

```bash
cp .env.example .env   # then fill in FEATUREFLOW_SERVER_KEY
bundle exec ruby examples/harness/server.rb
```

Variables already set in the shell take precedence over `.env`.

## Debugging in VS Code / Cursor

Install the recommended [VSCode rdbg Ruby Debugger](https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg) extension (it's in [.vscode/extensions.json](../../.vscode/extensions.json); the `debug` gem is a dev dependency, so `bundle install` provides `rdbg`). Then in **Run and Debug** (F5) pick:

- **Harness: example server** -- launches this server under the debugger; config comes from `.env`. Set breakpoints anywhere in `lib/` (e.g. `Featureflow::Evaluate#evaluate_variant`) and hit an endpoint to stop on them.
- **Cucumber: all (not @integration)** / **Cucumber: current feature file** -- run the test suite (or the `.feature` file open in the editor) under the debugger.
