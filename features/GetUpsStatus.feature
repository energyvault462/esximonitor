@regression
Feature: Read Battery Level and Line Voltage from File. (GetUpsStatus.feature)
  This will return a hash with lineVoltage and batteryLevel 

  Scenario Outline: Check the ups test file that has power with full 
    Given I want to use this UPS test file  <file name>
    When I ask for power status of <line voltage>, time stamp of <time stamp>, battery level of <battery level>, success of <success>, error message of <error message>
    Then I will return a hash with line voltage of <line voltage>, time stamp of <time stamp>, battery level of <battery level>, success of <success>, error message of <error message>

  Examples:
    | file name                     | line voltage | battery level | time stamp          | success | error message             |
    | upstestPowerOffBattery20.txt  | false        | 20.00         | 2014-10-22 10:24:39 | true    |                           |
    | upstestPowerOffBattery90.txt  | false        | 90.00         | 2014-10-22 10:21:39 | true    |                           |
    | upstestPowerOnBattery30.txt   | true         | 30.00         | 2014-10-22 10:22:39 | true    |                           |
    | upstestPowerOnBatteryFull.txt | true         | 100.00        | 2014-10-22 10:23:39 | true    |                           |
    | upstestFileDoesntExist.txt    |              |               |                     | false   | No such file or directory |
	