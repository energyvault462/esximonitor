Feature: Maintenance Testing
  Power On/off, notify, log, etc. (MonitorSimulator.feature)

  Scenario Outline: Do a maintenance cycle check
    Given I want to have esxi with the following keys
      | iniKey        | keyValue             |
      | esxiStartCode | default              |
      | iniFileName   | cucumberesxiTest.ini |
      | writeLogs     | true                 |
      | notifyByPush  | false                |
    And the test VMs are set as <NASTest>, <VMTest1>, <VMTest2>, <VMTest3>
    When I run the maintenance with <line voltage> and <battery level>
    Then the action should be <action>
    And I should wait for 0 seconds

    Examples:  Not tested for valid in the code
      | NASTest | VMTest1 | VMTest2 | VMTest3 | line voltage | battery level | action                          |
      | true    | false   | false   | false   | true         | 100.00        | Power On NASDependent AutoStart |
      | true    | true    | true    | false   | true         | 100.00        | All Systems Good                |
      | true    | true    | true    | false   | false        | 100.00        | Power Down NASDependents        |
      | true    | false   | false   | false   | false        | 20.00         | Power Down StandAlones          |