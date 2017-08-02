@iniReset @regression
Feature: Maintain Logging States  (StateNotify.feature)
  Tracks program States

  @logging
  Scenario Outline:  Test Logging
    Given I want to have esxi with the following keys
      | iniKey        | keyValue             |
      | iniFileName   | cucumberesxiTest.ini |
      | writeLogs     | true                 |
      | notifyByPush  | false                |
    When The states are currently <allSystemsGoodState>, <powerState>
    And the vitalHash template is <vitalHashTemplate>
    And I want to wait <waitTime> seconds
    And a notification is sent with <action>, <message>
    Then the logged result should be <loggedResult>

  Examples:
    | action                          | waitTime | message | allSystemsGoodState | powerState | vitalHashTemplate                                                      | loggedResult |
    | Software Starts                 | 0        |         | n/n/n               | nil       | PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero  | true         |
    | Do Nothing                      | 0        |         | n/n/n               | nil       | PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero  | true         |
    | Power Up Server                 | 0        |         | n/n/n               | nil       | PowerOn-BatteryFull-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero | true         |
    | Power On StandAlone AutoStart   | 0        |         | n/n/n               | nil       | PowerOn-BatteryFull-ServerOn-NASOff-StandAlonesOnZero-DependentsOnZero  | true         |
    | Power On NASDependent AutoStart | 0        |         | n/n/n               | nil       | PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnZero    | true         |
    | All Systems Good                | 0        |         | n/n/n               | nil       | PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo     | true         |
    | All Systems Good                | 0        |         | t/5/t               | nil       | PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo     | false        |
    | All Systems Good                | 0        |         | t/30/t              | nil       | PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo     | true         |
    | Power Failure                   | 0        |         | n/n/n               | nil       | PowerOff-BatteryGood-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo    | true         |
    | Power Down NASDependents        | 0        |         | n/n/n               | nil       | PowerOff-BatteryGood-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo    | true         |
    | Do Nothing                      | 0        |         | n/n/n               | nil       | PowerOff-BatteryGood-ServerOn-NASOn-StandAlonesOnOne-DependentsOnZero   | true         |
    | Power Down StandAlones          | 0        |         | n/n/n               | nil       | PowerOff-BatteryLow-ServerOn-NASOn-StandAlonesOnOne-DependentsOnZero    | true         |
    | Shutdown Server                 | 0        |         | n/n/n               | nil       | PowerOff-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero | true         |
    | Software Closes                 | 0        |         | n/n/n               | nil       | PowerOff-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero | false        |
    | Power Restored                  | 0        |         | n/n/n               | nil       | PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero  | true         |
    | Power Restored                  | 0        |         | n/n/n               | true      | PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero  | false        |
    | Software Starts                 | 0        |         | n/n/n               | nil       | PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero  | true         |

  @push
  Scenario Outline: Test push queue
    Given I want to have esxi with the following keys
      | iniKey        | keyValue             |
      | iniFileName   | cucumberesxiTest.ini |
      | writeLogs     | true                 |
      | notifyByPush  | true                 |
    And I want to test notification queues
    When the first <numberOfEvents> are done
    Then I should receive <totalPushesExpected> push notifications

    Examples:
      | numberOfEvents| totalPushesExpected|
      | 16            | 8                  |