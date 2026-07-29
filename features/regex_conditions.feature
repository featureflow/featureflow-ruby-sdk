# Ruby-specific scenarios guarding the SDK contract's rule on the "matches" operator
# (featureflow-client-sdk-testbed/CONTRACT.md, "Operators"): "An invalid regex in
# `matches` returns `false` rather than throwing."
#
# The pattern is untrusted configuration — somebody typed it into a targeting rule in
# the dashboard — so a malformed one must fail the condition, never raise into the
# host application. Regexp.new raised RegexpError here until 2026-07-29. The shared
# testbed submodule carries the same three patterns; these scenarios keep the
# behaviour covered in this repo regardless of the submodule's pointer.
Feature: An invalid regex in a targeting rule never raises

  Scenario Outline: A pattern that will not compile returns no match rather than raising
    Given the target is a "string" with the value of "my-test-value"
    And the attribute is a "string" with the value of "<pattern>"
    When the operator test "matches" is run
    Then the output should equal "false"

    Examples:
      | pattern         |
      | [unclosed       |
      | (unbalanced     |
      | *bad-quantifier |
      | a{2,1}          |
      | a)b             |

  Scenario: A valid pattern still matches
    Given the target is a "string" with the value of "my-test-value"
    And the attribute is a "string" with the value of "my.test.+"
    When the operator test "matches" is run
    Then the output should equal "true"

  Scenario: A pattern that is not a string returns no match rather than raising
    Given the target is a "string" with the value of "my-test-value"
    And the attribute is a "number" with the value of "123"
    When the operator test "matches" is run
    Then the output should equal "false"
