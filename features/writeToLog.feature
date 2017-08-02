@regression
Feature: Log Simple Message  (writeToLog.feature)
  Writes a line into the log file using the WriteToLog method

  Scenario Outline: Write log in live mode.
    Given I want to write a log entry
    When I send <severity> with a message of <message>
    Then I will return a hash using <severity> with the message of <message>

  Examples:
    | severity | message                          |
    | Debug    | Hey, I do not want to debug this |
    | info     | Just Singing a tune              |
    | WARN     | Danger Will                      |
    | error    | Now you did it                   |
    | fatal    | He is dead Jim.                  |

  Scenario Outline: Write log in test mode.
    Given I want to write a log entry
    When I call notify with <action>, <severity>, and a message of <message>
    Then I will return a hash using <action>, <severity>, and a message of <message>

  Examples:
    | action                          | severity | message                         |
    | softwareonline                  | info     | Esxi Cucumber Test Starting.... |
    | vmsuspend                       | info     | VM Suspend:  VMCucumber         |
    | vmshutdown                      | info     | VM Shutdown: VMCucumber         |
    | vmpoweroff                      | info     | VM POWEROFF: VMCucumber         |
    | vmreboot                        | info     | VM Reboot:   VMCucumber         |
    | vmreset                         | info     | VM RESET :   VMCucumber         |
    | vmpoweron                       | info     | VM PowerOn:  VMCucumber         |
    | Power Up Server                 | info     | ESXI Server Powering On         |
    | Shutdown Server                 | info     | ESXI Server Powering Off        |
    | Power On StandAlone AutoStart   | info     | Power On StandAlone AutoStart   |
    | Power On NASDependent AutoStart | info     | Power On NASDependent AutoStart |
    | All Systems Good                | info     | All Systems Good                |
    | Power Down NASDependents        | info     | Power Down NASDependents        |
    | Power Down StandAlones          | info     | Power Down StandAlones          |
    | Error - Confirm NAS Off         | info     | Error - Confirm NAS Off         |
    | Do Nothing                      | info     | Do Nothing                      |
    | housePowerOn                    | info     | PGE Power Is On                 |
    | housePowerOff                   | info     | PGE Power Is Off                |
    | batteryPowerLow                 | info     | UPS Battery is Low on Juice     |
    | batteryPowerGood                | info     | UPS Battery is Good Enough      |
    | batteryPowerFull                | info     | UPS Battery is Full             |
    | softwareoffline                 | info     | Esxi Cucumber Test Closing      |
