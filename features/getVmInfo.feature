Feature: Get VM Information
  Gets information on the Virtual Machines.  (getVmInfo.feature)
  Setup in VMWARE is:  Turn on VMTest1 and NASTest;  VMTest2 and 3 are powered down (or suspended).

  Scenario Outline: Get basic Info
    Given I want to have esxi with the following keys
      | iniKey       | keyValue             |
      | iniFileName  | cucumberesxiTest.ini |
      | writeLogs    | true                 |
      | notifyByPush | false                |
    And the test VMs are set as true, true, false, false
#    And I want to wait 10 seconds
    When I ask for <has id> for VM <VMName>, power state <Power State>, auto start <Auto Start>, dont suspend <NoSuspend>, stand alone <Standalone>, guest tools <Guest Tools>

    Then I will return a hash with name of <VMName> including the id of <has id>

    Examples:
      | VMName  | has id | Power State | Auto Start | NoSuspend | Standalone | Guest Tools |
      | VMTest1 | true   | true        | true       | false     | false      | true        |
      | VMTest2 | true   | false       | true       | false     | false      | false       |
      | VMTest3 | true   | false       | false      | false     | false      | false       |
      | NASTest | true   | true        | true       | true      | true       | true        |
      | NotReal | false  | nil         | nil        | nil       | nil        | nil         |