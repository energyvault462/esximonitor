@regression
Feature: Get a key from the ini file using the getKey method. (getKey.feature)
  Read from the ini file and return the correct key based on the different Given statements.

  Scenario Outline: Return the setting of the ini file.
    Given I want to test this getKeyFeature.ini file
    When I ask for esxi_settings <ini variable>
    Then I will get <ini setting>

    Examples:
      | ini variable                        | ini setting           |
      | serverIp                            | 0.0.0.0               |
      | stopMaintFileName                   | FullPathAndFileName   |
      | notifyByPush                        | false                 |
      | standAlone                          | values,coma,separated |
      | nasVmName                           | value                 |
      | noSuspend                           | values,coma,separated |
      | autoStart                           | values,coma,separated |
      | useApcaccess                        | false                 |
      | upsPowerOnAtPercent                 | 70.0                  |
      | upsPowerOffAtPercent                | 80.0                  |
      | UpsOutputName                       | fullPathAndFileName   |
      | UpsInputName                        | fullPathAndFileName   |
      | writeLogs                           | true                  |
      | hdDir                               | FullPath              |
      | ramDiskDir                          | FullPath              |
      | fileName                            | esxiMonitor.log       |
      | stopMaintFileName                   | FullPathAndFileName   |
      | secondsBetweenLoggingAllSystemsGood | 3600                  |
      | testMachines                        | values,coma,separated |
      | allowHostShutdown                   | false                 |
      | pushoverUserToken                   | nil                   |
