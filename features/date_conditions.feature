# Ruby-specific scenarios guarding the SDK contract's date rules
# (featureflow-client-sdk-testbed/CONTRACT.md, "Operators"): a condition value with no
# timezone information — including a date-only value from the dashboard's date picker —
# denotes UTC, never the host's local time.
#
# The host timezone is deliberately varied: parsing in local time was the bug, so these
# scenarios only mean anything when at least one of them runs under a non-UTC TZ.
Feature: Date condition values are timezone-independent

  Scenario Outline: A date-only value is UTC midnight whatever the host timezone
    Given the host timezone is "<timezone>"
    When the date value "2026-07-03" is parsed
    Then the parsed instant should be "2026-07-03T00:00:00Z"

    Examples:
      | timezone         |
      | UTC              |
      | Australia/Sydney |
      | America/New_York |
      | Asia/Kolkata     |

  Scenario Outline: A value with no timezone is read as UTC, one with an offset is not shifted
    Given the host timezone is "Australia/Sydney"
    When the date value "<value>" is parsed
    Then the parsed instant should be "<instant>"

    Examples:
      | value                     | instant              |
      | 2026-07-03T10:00:00       | 2026-07-03T10:00:00Z |
      | 2026-07-03T10:00:00Z      | 2026-07-03T10:00:00Z |
      | 2026-07-03T10:00:00+04:00 | 2026-07-03T06:00:00Z |
      | 2026-07-03T10:00:00-05:00 | 2026-07-03T15:00:00Z |

  Scenario Outline: Instants either side of a date-only value compare against UTC midnight
    Given the host timezone is "<timezone>"
    And the target is a "string" with the value of "<target>"
    And the attribute is a "string" with the value of "2026-07-03"
    When the operator test "<operator>" is run
    Then the output should equal "<result>"

    Examples:
      | timezone         | operator | target               | result |
      | Australia/Sydney | after    | 2026-07-03T00:00:01Z | true   |
      | Australia/Sydney | after    | 2026-07-02T23:59:59Z | false  |
      | America/New_York | after    | 2026-07-03T00:00:01Z | true   |
      | America/New_York | after    | 2026-07-02T23:59:59Z | false  |
      | Australia/Sydney | before   | 2026-07-02T23:59:59Z | true   |
      | Australia/Sydney | before   | 2026-07-03T00:00:01Z | false  |

  Scenario Outline: An unparseable value returns no match rather than raising
    Given the host timezone is "Australia/Sydney"
    And the target is a "string" with the value of "<target>"
    And the attribute is a "string" with the value of "<attribute>"
    When the operator test "<operator>" is run
    Then the output should equal "false"

    Examples:
      | operator | target               | attribute            |
      | after    | not-a-date           | 2026-07-03           |
      | before   | not-a-date           | 2026-07-03           |
      | after    | 2026-07-03T00:00:01Z | not-a-date           |
      | before   |                      | 2026-07-03           |
      | after    | 2026-99-99           | 2026-07-03           |
