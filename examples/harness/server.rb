#!/usr/bin/env ruby
# frozen_string_literal: true

# Local harness: WEBrick app using the SDK straight from ../../lib
#
#   FEATUREFLOW_SERVER_KEY=srv-env-xxxxxxxxx ruby examples/harness/server.rb
#   FEATUREFLOW_BASE_URL=https://beta.featureflow-staging.com FEATUREFLOW_SERVER_KEY=srv-env-xxxxxxxxx ruby examples/harness/server.rb
#
# Open http://127.0.0.1:3456/ -- or use the JSON API below.

$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))

require 'featureflow'
require 'webrick'
require 'json'

# Load repo-root .env (see .env.example) without overriding vars already set in the shell.
env_file = File.expand_path('../../.env', __dir__)
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')
    key, value = line.split('=', 2)
    next unless key && value
    ENV[key] ||= value.strip
  end
end

api_key = ENV['FEATUREFLOW_SERVER_KEY'].to_s.strip
if api_key.empty?
  warn "Set FEATUREFLOW_SERVER_KEY to your Featureflow server API key.\n" \
       "Example:\n" \
       "  FEATUREFLOW_SERVER_KEY=srv-env-xxxxxxxxx ruby examples/harness/server.rb\n"
  exit 1
end

port = Integer(ENV['PORT'] || 3456)
disable_events = ENV['FEATUREFLOW_DISABLE_EVENTS'] != 'false'

Featureflow.configure do |config|
  config.api_key = api_key
  config.endpoint = ENV['FEATUREFLOW_BASE_URL'] if ENV['FEATUREFLOW_BASE_URL']
  config.event_endpoint = ENV['FEATUREFLOW_EVENTS_URL'] if ENV['FEATUREFLOW_EVENTS_URL']
  config.disable_events = disable_events
  config.with_features = [Featureflow::Feature.create('example-feature', 'off')]
  config.logger.level = Logger::INFO
end

# Featureflow.client lazily builds the singleton Client, which does a synchronous
# initial poll before returning -- so by the time this line completes we've made
# at least one attempt to fetch features.
client = Featureflow.client

def build_user(user_id, role, tier)
  Featureflow::UserBuilder.new(user_id)
                           .with_attributes(role: role, tier: tier)
                           .build
end

server = WEBrick::HTTPServer.new(Port: port, BindAddress: '127.0.0.1', AccessLog: [])

server.mount_proc('/health') do |_req, res|
  res['Content-Type'] = 'application/json'
  res.body = JSON.generate(status: 'ok')
end

server.mount_proc('/api/config') do |_req, res|
  res['Content-Type'] = 'application/json'
  res.body = JSON.generate(
    endpoint: Featureflow.configuration.endpoint,
    eventEndpoint: Featureflow.configuration.event_endpoint,
    disableEvents: !!Featureflow.configuration.disable_events
  )
end

server.mount_proc('/api/evaluate') do |req, res|
  feature = req.query['feature'].to_s
  res['Content-Type'] = 'application/json'
  if feature.empty?
    res.status = 400
    res.body = JSON.generate(error: 'Query parameter "feature" is required')
    next
  end

  user_id = req.query['userId'].to_s
  user_id = 'anonymous' if user_id.empty?
  role = req.query['role'].to_s
  role = 'pvt_tester' if role.empty?
  tier = req.query['tier'].to_s
  tier = 'gold' if tier.empty?

  user = build_user(user_id, role, tier)
  evaluated = client.evaluate(feature, user)
  res.body = JSON.generate(
    feature: feature,
    user: user,
    value: evaluated.value,
    on: evaluated.on?,
    off: evaluated.off?
  )
end

server.mount_proc('/') do |_req, res|
  res['Content-Type'] = 'text/html'
  res.body = INDEX_HTML
end

trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

base_log = ENV['FEATUREFLOW_BASE_URL'] || 'https://app.featureflow.io (default)'
events_log = ENV['FEATUREFLOW_EVENTS_URL'] || 'https://events.featureflow.io (default)'
puts "Featureflow Ruby SDK harness listening on http://127.0.0.1:#{port}/"
puts '  GET  /health  GET  /api/config'
puts '  GET  /api/evaluate?feature=<key>&userId=<id>&role=<role>&tier=<tier>'
puts "  effective endpoint (from env or default): #{base_log}"
puts "  effective event endpoint (from env or default): #{events_log}"
puts "  (harness disables events HTTP by default; set FEATUREFLOW_DISABLE_EVENTS=false to enable)\n\n"

INDEX_HTML = <<~HTML
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Featureflow Ruby SDK -- harness</title>
    <style>
      body { font-family: system-ui, sans-serif; max-width: 42rem; margin: 2rem auto; padding: 0 1rem; }
      label { display: block; margin-top: 0.75rem; }
      input { width: 100%; max-width: 24rem; padding: 0.25rem 0.5rem; }
      pre { background: #f4f4f4; padding: 0.75rem; overflow: auto; }
      .err { color: #c00; }
    </style>
  </head>
  <body>
    <h1>Featureflow Ruby SDK harness</h1>
    <p>Uses the SDK from this repo's <code>lib/</code>. Set <code>FEATUREFLOW_SERVER_KEY</code>; use <code>FEATUREFLOW_BASE_URL</code> for staging.</p>
    <p>SDK endpoint: <strong id="endpoint">&hellip;</strong></p>
    <label>Feature key <input id="feature" type="text" value="example-feature" placeholder="my-feature-key" /></label>
    <label>User id <input id="userId" type="text" value="harness-user" placeholder="user id" /></label>
    <label>Role attribute <input id="role" type="text" value="pvt_tester" placeholder="role" /></label>
    <label>Tier attribute <input id="tier" type="text" value="gold" placeholder="tier" /></label>
    <p><button type="button" id="go">Evaluate</button></p>
    <h2>Result</h2>
    <pre id="out">&mdash;</pre>
    <h2>Raw JSON</h2>
    <pre id="raw">&mdash;</pre>
    <script>
    (function () {
      function get(path) { return fetch(path).then(function (r) { return r.json(); }); }
      get('/api/config').then(function (c) {
        document.getElementById('endpoint').textContent = c.endpoint + ' -- events: ' + c.eventEndpoint;
      }).catch(function () {
        document.getElementById('endpoint').textContent = '(unavailable)';
      });
      var outEl = document.getElementById('out');
      var rawEl = document.getElementById('raw');
      document.getElementById('go').onclick = function () {
        var f = document.getElementById('feature').value.trim();
        var u = document.getElementById('userId').value.trim() || 'anonymous';
        var r = document.getElementById('role').value.trim();
        var t = document.getElementById('tier').value.trim();
        var q = '/api/evaluate?feature=' + encodeURIComponent(f) + '&userId=' + encodeURIComponent(u) +
          '&role=' + encodeURIComponent(r) + '&tier=' + encodeURIComponent(t);
        get(q).then(function (d) {
          if (d.error) {
            outEl.textContent = d.error;
            outEl.className = 'err';
            return;
          }
          outEl.textContent = 'value: ' + d.value + '\\n' + 'on: ' + d.on + ', off: ' + d.off;
          outEl.className = '';
          rawEl.textContent = JSON.stringify(d, null, 2);
        }).catch(function () {
          outEl.textContent = 'Request failed';
          outEl.className = 'err';
        });
      };
    })();
    </script>
  </body>
  </html>
HTML

server.start
