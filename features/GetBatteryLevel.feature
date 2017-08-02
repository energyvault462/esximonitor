@regression
Feature: Read Battery Level and Line Voltage from File. (GetBatteryLevel.feature)
  This will return a hash with lineVoltage and batteryLevel 

  Scenario Outline: Check the ups test file that has power with full 
    Given I want to use this UPS test file <file name>
    When I ask for the battery level of <battery level>
    Then I will receive a battery level of <battery level>

  Examples:
    | file name                     | battery level |
    | upstestPowerOffBattery20.txt  | 20.00         |
	| upstestPowerOffBattery90.txt  | 90.00         |
	| upstestPowerOnBattery30.txt   | 30.00         |
	| upstestPowerOnBatteryFull.txt | 100.00        |