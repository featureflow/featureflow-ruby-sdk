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

See [.env.example](../../.env.example) in the repo root if you'd rather keep your key in a gitignored `.env` file and export it before running (e.g. `export $(cat .env | xargs)`, or use a tool like [dotenv](https://github.com/bkeepers/dotenv) / your editor's env-file support).
