# Ruby-specific scenarios. The shared featureflow-sdk-testbed submodule covers
# evaluation semantics common to every SDK; these cover this SDK's own surface —
# the Featureflow::Client constructor forms and the Rails controller helper.
#
# No network is needed: the client is pointed at an unreachable endpoint, so every
# feature falls back to its failover variant ('off' by default).
Feature: Ruby client construction and the Rails helper

  Scenario: Creating a client from a Hash of configuration options
    Given there is access to the Featureflow library
    When a client is created with a Hash of configuration options
    Then a client should be returned without an error

  Scenario: Creating a client from an explicit Configuration
    Given there is access to the Featureflow library
    When a client is created with an explicit Configuration
    Then a client should be returned without an error

  Scenario: Creating a client with no arguments reads the server key from the environment
    Given there is access to the Featureflow library
    And the environment variable FEATUREFLOW_SERVER_KEY is set
    When a client is created with no arguments
    Then a client should be returned without an error
    And the client configuration should use the server key from the environment

  Scenario: Creating a client with an unknown configuration option
    Given there is access to the Featureflow library
    When a client is created with an unknown configuration option
    Then the featureflow client should throw an error

  # The shared scenarios for the application tag itself are in
  # testbed/gherkin/application_tag.feature; the environment-variable fallback is
  # Ruby-specific configuration surface, so it lives here.
  Scenario: The application tag falls back to the FEATUREFLOW_APPLICATION environment variable
    Given a features endpoint capturing request headers
    And the environment variable FEATUREFLOW_APPLICATION is set to "env-app"
    When a client is initialised against it with no application
    Then the captured features request has X-Featureflow-Application "env-app"

  Scenario: The Rails helper evaluates a feature for a plain user id
    Given the featureflow client is configured against an unreachable endpoint
    And a rails request from ip "10.0.0.1" with url "http://example.com/home"
    When the rails helper evaluates "a-feature" for the user id "user1"
    Then the rails helper should not raise an error
    And the evaluated user should have the id "user1"
    And the evaluated user should have the attribute "featureflow.ip" with value "10.0.0.1"
    And the evaluated user should have the attribute "featureflow.url" with value "http://example.com/home"

  Scenario: The Rails helper evaluates a feature for a user with attributes
    Given the featureflow client is configured against an unreachable endpoint
    And a rails request from ip "10.0.0.1" with url "http://example.com/home"
    When the rails helper evaluates "a-feature" for the user id "user1" with attribute "country" of "AU"
    Then the rails helper should not raise an error
    And the evaluated user should have the id "user1"
    And the evaluated user should have the attribute "country" with value "AU"
    And the evaluated user should have the attribute "featureflow.ip" with value "10.0.0.1"
    And the evaluated user should have the attribute "featureflow.url" with value "http://example.com/home"
