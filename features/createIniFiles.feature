@regression
Feature: Create ini files when they do not exist (createIniFiles.feature)
  Create default ini files

  Scenario Outline: Return the setting of the ini file.
    Given the <ini file name> doesn't exist
    When the software loads up
    Then the file should be created and populated with default settings.

  Examples:
    | ini file name                        |
    | createLive.ini                       |
    | createTest.ini                       |



