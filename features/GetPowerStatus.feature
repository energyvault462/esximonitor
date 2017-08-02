@regression
Feature: Read Line Voltage from File (GetPowerStatus.feature)
  This will return True or False depending on if there is voltage to the UPC. 

  Scenario Outline: Check the ups test file
    Given I want to use this UPS test file <file name>
    When I ask for the power status of <line voltage>
    Then I will receive a power status of <line voltage>

  Examples:
    | file name                     | line voltage |
    | upstestPowerOffBattery20.txt  | false        |
	| upstestPowerOffBattery90.txt  | false        |
	| upstestPowerOnBattery30.txt   | true         |
	| upstestPowerOnBatteryFull.txt | true         |