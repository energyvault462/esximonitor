@regression
Feature: Read Battery Level and Line Voltage from File. (DidStatusChange.feature)
  This will return a hash with lineVoltage and batteryLevel 

  Scenario Outline: Check the ups test file that has power with full 
    Given I want to start new esxi using ini configuration file cucumberesxiTest.ini
    And I want to use this UPS test file <file name>
    When the hash for power status of <line voltage>, time stamp of <time stamp>, battery level of <battery level>, success of <success>, error message of <error message>, change result of <change result>
    Then the change result will be <change result>

  Examples:
    | file name                     | line voltage | battery level | time stamp          | success | error message | change result |
    | upstestPowerOnBatteryFull.txt | true         | 100.00        | 2014-10-22 08:23:39 | true    |               | false         |
    | upstestPowerOnBatteryFull.txt | false        | 100.00        | 2014-10-22 08:23:39 | true    |               | true          |
    | upstestPowerOnBatteryFull.txt | true         | 50 .00        | 2014-10-22 08:23:39 | true    |               | true          |
    | upstestPowerOnBatteryFull.txt | false        | 20.00         | 2014-10-22 08:23:39 | true    |               | true          |

    | upstestPowerOffBattery20.txt  | false        | 20.00         | 2014-10-22 10:24:39 | true    |               | false         |
    | upstestPowerOffBattery20.txt  | false        | 90.00         | 2014-10-22 10:24:39 | true    |               | true          |
    | upstestPowerOffBattery20.txt  | true         | 20.00         | 2014-10-22 10:24:39 | true    |               | true          |
    | upstestPowerOffBattery20.txt  | true         | 90.00         | 2014-10-22 10:24:39 | true    |               | true          |