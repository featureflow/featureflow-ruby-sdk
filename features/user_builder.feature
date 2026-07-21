Feature: UserBuilder
  Scenario: Test the User Builder can build a valid user with an id
    Given there is access to the User Builder module
    When the builder is initialised with the id "user"
    And the user is built using the builder
    Then the result user should have an id "user"
    And the result user should have no attributes

  Scenario: Test the User Builder can build a valid user with an id
    Given there is access to the User Builder module
    When the builder is initialised with the id "user"
    And the builder is given the following attributes
      | key  | value  |
      | age  | 21     |
      | type | beta   |
    And the user is built using the builder
    Then the result user should have an id "user"
    And the result user should have a attribute with key "age" and value "21"
    And the result user should have a attribute with key "type" and value "beta"
    # Note: the builder does not inject implicit attributes. "featureflow.user.id",
    # "featureflow.date" and "featureflow.hourofday" are merged in by Client#evaluate
    # at evaluation time, so date/hour rules match the moment of evaluation rather
    # than when the user object was built. (Partial evaluation — *deferring* these
    # conditions to the client — is sdk-server-only for the JS client SDKs.)
    And the result user should not have a attribute with key "featureflow.user.id"
    And the result user should not have a attribute with key "featureflow.date"

  Scenario: Test the User Builder throws an error when no key is provided
    Given there is access to the User Builder module
    When the builder is initialised with the id ""
    Then the builder should throw an error
