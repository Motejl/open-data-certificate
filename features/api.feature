@api
Feature: Open Data Certificate API

  Background:
    Given I want to create a certificate via the API

  @sidekiq_fake
  Scenario: API call returns pending initially
    When I request a certificate via the API
    And I request the status via the API
    Then the API response should return pending
    When the certificate is created
    And I request the results via the API
    Then the API response should return sucessfully

  Scenario: API call with autocompleting data
    Given my URL autocompletes via DataKitten
    When I request a certificate via the API
    And I request the results via the API
    Then the API response should return sucessfully
    And my certificate should be published
    And I should get the certificate URL

  Scenario: API call when documentation URL already exists
    Given my URL autocompletes via DataKitten
    And that URL already has a published certificate
    When I request a certificate via the API
    Then the API response should return unsucessfully
    And there should only be one dataset
