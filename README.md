# featureflow-ruby-sdk
Ruby SDK for featureflow

[![][dependency-img]][dependency-url]

[![][rubygems-img]][rubygems-url]

> Featureflow Ruby SDK

Get your Featureflow account at [featureflow.io](http://www.featureflow.io)

## Get Started

The easiest way to get started is to follow the [Featureflow quick start guides](http://docs.featureflow.io/docs)

## Change Log

Please see [CHANGELOG](https://github.com/featureflow/featureflow-node-sdk/blob/master/CHANGELOG.md).

## Usage

### Getting Started

##### Ruby

Add the following line to your Gemfile

```ruby
gem 'featureflow'
```

Requiring `featureflow` in your ruby application will expose the classes
 `Featureflow::Client`, `Featuerflow::ContextBuilder` and `Featureflow::Feature`.

The usage of each class is documented below.

### Quick start

Firstly you will need to get your environment's Featureflow Server API key and initialise a new Featureflow client

This will load the rules for each feature for the current environment, specified by the api key.
These rules can be changed at `https://<your-org-key>.featureflow.io`. 
When the rules are updated, the changes made will be applied to your application.

##### Ruby Quick Start

If you are using ruby you can create a featureflow client like this:

```ruby
featureflow = Featureflow::Client.new api_key: '<Your server api key goes here>'
```

Or, you can set the environment variable `FEATUREFLOW_SERVER_KEY` and just write:

```ruby
featureflow = Featureflow::Client.new
```
**Note: `featureflow`, as instantiated above, should be treated as a singleton. You are responsible for sharing it with the rest of your application**

##### Rails Quick Start

If you are using rails you can run the generator to setup Featureflow in your Rails application.

```bash
$ rails generator featureflow <Your server api key goes here>
```

Or, you can set the environment variable `FEATUREFLOW_SERVER_KEY` and the Rails Featureflow client will pick it up and use that.

You will then be able to access your Featureflow client in your controllers, for example:

```ruby
class MainController < ApplicationController
  def index
    featureflow # this method will now reference the featureflow client
  end
end
```



#### Defining Context

Before evaluating a feature you must define a context for the current user.  
Featureflow uses context to target different user groups to specific feature variants. 
A featureflow context has a `key`, which should uniquely identify the current user, and optionally additional `values`. 
Featureflow requires the context `key` to be unique per user for gradual rollout of features.

There are two ways to define context:
```ruby
require 'featureflow'
context_key = '<unique_user_identifier>'

# option 1, use the context builder
context = Featureflow::ContextBuilder.new(context_key)
                                     .with_values(country: 'US',
                                                  roles: %w[USER_ADMIN, BETA_CUSTOMER])
                                     .build

# option 2, use just a string
context = context_key
```

#### Evaluating Features

In your code, you can test the value of your feature using something similar to below
For these examples below, assume the feature `my-feature-key` is equal to `'on'` for the current `context`
```ruby
if featureflow.evaluate('my-feature-key', context).is? 'on'
  # this code will be run because 'my-feature-key' is set to 'on' for the given context
end
```
Because the most common variants for a feature are `'on'` and `'off'`, we have provided two helper methods `.on?` and `.off?`

```ruby
if featureflow.evaluate('my-feature-key', context).on?
  # this feature code will be run because 'my-feature-key' is set to 'on'
end

if featureflow.evaluate('my-feature-key', context).off?
  # this feature code won't be run because 'my-feature-key' is not set to 'off'
end
```

#### Pre-registering Features

Featureflow allows you to pre-register features that may not be defined in your Featureflow project to ensure that those 
features are available when that version of your code is running. 
If in the off-chance your application is unable to access the Featureflow servers and you don't have access 
to a cached version of the features, you can specify a failover variant for any feature. 

The failover variant allows you to control what variant a feature will evaluate to when no rules are available for the feature.
If a failover variant isn't defined, each feature will use a default feailover variant of `'off'`.

You can pre-register features at the initialisation of your featureflow client like below:

```ruby
require 'featureflow'

FEATUREFLOW_SERVER_KEY = '<Your server api key goes here>'

featureflow = Featureflow::Client.new(api_key: FEATUREFLOW_SERVER_KEY,
                                      with_features: [
                                        Featureflow::Feature.create('key-one', 'on'),
                                        Featureflow::Feature.create('key-two'),
                                        Featureflow::Feature.create('key-three', 'custom'),
                                      ])

# ... app has been started offline
featureflow.evaluate('key-one', context).on? # == true
featureflow.evaluate('key-two', context).off? # == true
featureflow.evaluate('key-three', context).is? 'custom' # == true

```

#### Further documentation
Further documentation can be found [here](http://docs.featureflow.io/docs)

## Roadmap
- [x] Write documentation
- [x] Release to RubyGems
- [x] Write Ruby on Rails integration
- [ ] Add Ruby on Rails helper to user featureflow in views

## License

Apache-2.0

[rubygems-url]: https://rubygems.org/gems/featureflow
[rubygems-img]: https://badge.fury.io/rb/featureflow.png

[dependency-url]: https://www.featureflow.io
[dependency-img]: https://www.featureflow.io/wp-content/uploads/2016/12/featureflow-web.png

#Developer documentation

To build and test the SDK

```
rvm install 2.5.1
rvm use --default 2.5.1
bundle install
ruby test.rb
```