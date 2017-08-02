@regression
Feature: Power Statuses Change  (automateVmOffAndOn.feature)
  This will power up/down the virtual machines based on power status and battery level.

  Scenario Outline: Testing the decision Making Process
    Given I want to have esxi with the following keys
      | iniKey        | keyValue             |
      | iniFileName   | cucumberesxiTest.ini |
      | writeLogs     | true                 |
      | notifyByPush  | true                |
    And Line Voltage is <Power>, the Battery Level is <Battery>, the upsPowerOnAtPercent is <upsPowerOnAtPercent>, and the upsPowerOffAtPercent is <upsPowerOffAtPercent>
    When The circumstances are that NasPoweredOn is <NasPOn>, StandAloneAutoStartPoweredOff is <SAASPOff>, NasDependentAutoStartPoweredOff is <NDASPOff>,  NasDependentPoweredOn is <NDPOn>, and StandAlonePoweredOn is <SAPOn>
    Then I will receive a result of <Result>

  Examples:
    | Power | Battery | upsPowerOnAtPercent | upsPowerOffAtPercent | NasPOn | SAASPOff | NDASPOff | SAPOn | NDPOn | Result                          |
    | true  | 100.00  | 90                  | 80                   | true   | 0        | 0        | 55    | 55    | All Systems Good                |
    | true  | 100.00  | 90                  | 80                   | true   | 0        | 1        | 55    | 55    | Power On NASDependent AutoStart |
    | true  | 100.00  | 90                  | 80                   | true   | 1        | 0        | 55    | 55    | Power On StandAlone AutoStart   |
    | true  | 100.00  | 90                  | 80                   | true   | 1        | 1        | 55    | 55    | Power On StandAlone AutoStart   |
    | true  | 50.00   | 90                  | 80                   | true   | 0        | 0        | 55    | 55    | Do Nothing                      |
    | true  | 50.00   | 90                  | 80                   | true   | 0        | 1        | 55    | 55    | Do Nothing                      |
    | true  | 50.00   | 90                  | 80                   | true   | 1        | 0        | 55    | 55    | Do Nothing                      |
    | true  | 50.00   | 90                  | 80                   | true   | 1        | 1        | 55    | 55    | Do Nothing                      |
    | false | 50.00   | 90                  | 80                   | 55     | 55       | 55       | 0     | 0     | Shutdown Server                 |
    | false | 50.00   | 90                  | 80                   | 55     | 55       | 55       | 0     | 1     | Error - Confirm NAS Off         |
    | false | 50.00   | 90                  | 80                   | 55     | 55       | 55       | 1     | 0     | Power Down StandAlones          |
    | false | 50.00   | 90                  | 80                   | 55     | 55       | 55       | 1     | 1     | Power Down NASDependents        |
    | false | 100.00  | 90                  | 80                   | 55     | 55       | 55       | 0     | 0     | Do Nothing                      |
    | false | 100.00  | 90                  | 80                   | 55     | 55       | 55       | 0     | 1     | Error - Confirm NAS Off         |
    | false | 100.00  | 90                  | 80                   | 55     | 55       | 55       | 1     | 0     | Do Nothing                      |
    | false | 100.00  | 90                  | 80                   | 55     | 55       | 55       | 1     | 1     | Power Down NASDependents        |
