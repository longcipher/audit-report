Feature: Checkout Process
  As a user
  I want to process a checkout
  So that I can complete my purchase

  Scenario: Valid checkout
    Given I have a valid cart
    When I process the checkout
    Then the checkout should succeed
    And I should receive a confirmation

  Scenario: Empty cart checkout
    Given I have an empty cart
    When I process the checkout
    Then the checkout should fail
    And I should see an error message

  Scenario: Invalid payment
    Given I have a valid cart
    And I have invalid payment information
    When I process the checkout
    Then the checkout should fail
    And I should see a payment error