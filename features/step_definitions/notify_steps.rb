#TODO: Change this to use a data table in the steps
#TODO: Change the table so it'll act like the first data table (can put previous state in it)
#TODO: Change to queue and only send when sendnow or 3 minutes have passed.


def StateBoolNotificationHashTransform(input)
  one, two, three = input.scan(/(t|f|n)\/([t|f|n]|\d*)\/([t|f|n])/i).flatten
  tempHash = Hash.new
  case one.downcase
    when 't'
      tempHash = {:state=>true}
    when 'f'
      tempHash = {:state=>false}
    when 'n'
      tempHash = {:state=>nil}
  end

  if two == 'n'  #only nil and time are allowed, so set n/t/f as nil
    tempHash[:TimeLastLogged] = nil
  elsif two== 't'
    tempHash[:TimeLastLogged] = nil
  elsif two== 'f'
    tempHash[:TimeLastLogged] = nil
  else
    tempHash[:TimeLastLogged] = (Time.new - two.to_i)
  end

  if three == 't'  #only true, false, and nil
    tempHash[:pushed] = true
  elsif three== 'f'
    tempHash[:pushed] = false
  else
    tempHash[:pushed] = nil
  end


  return tempHash
end


def BuildTestVitalHash(valueHash)
  return {:powerstate=>valueHash[:powerstate], :batterylevel=>valueHash[:batterylevel], :upsPowerOnAtPercent=>valueHash[:upsPowerOnAtPercent], 	:upsPowerOffAtPercent=>valueHash[:upsPowerOffAtPercent], 	:serverOnline=>valueHash[:serverOnline], 	:NasPoweredOn=>valueHash[:NasPoweredOn], :StandAloneAutoStartPoweredOff=>valueHash[:StandAloneAutoStartPoweredOff], :NasDependentAutoStartPoweredOff=>valueHash[:NasDependentAutoStartPoweredOff], :NasDependentPoweredOn=>valueHash[:NasDependentPoweredOn], :StandAlonePoweredOn=>valueHash[:StandAlonePoweredOn]}
end

def BuildNotifyConstructorHash(tempHash)
  constructorHash = Hash.new

  constructorHash[:writeLogs] = tempHash[:writeLogs]
  constructorHash[:notifyByPush] = tempHash[:notifyByPush]

  if constructorHash[:writeLogs]
    constructorHash[:hdDir] = $esxi.GetIniValue('logHdFolder')
    constructorHash[:fileName] = $esxi.GetIniValue('logFileName')
    constructorHash[:ramDiskDir] = $esxi.GetIniValue('logRamFolder')
  end

  if constructorHash[:notifyByPush]
    constructorHash[:pushoverUserToken] = $esxi.GetIniValue('pushoverUserToken')
    constructorHash[:pushoverAppToken] = $esxi.GetIniValue('pushoverAppToken')
    constructorHash[:emailTarget] = $esxi.GetIniValue('emailTarget')
  end
  return constructorHash
end


When(/^I call notify with (.*), severity info, a message of (.*), and the last message sent was (.*) seconds ago$/) do  |severity, message, secondsAgo|
  pending # express the regexp above with the code you wish you had
end

Then(/^I expect email sent will be (.*) and log entered will be (.*)$/) do   |emailExpectedResult, loggedExpectedResult|
  pending # express the regexp above with the code you wish you had
end

Given(/^I start with just turning on the software$/) do
  tempHash = Hash.new
  BuildNotifyConstructorHash(tempHash)
  @note = Notification.new(tempHash)
  tempHash = nil
end

Given(/^I want to test notification queues$/) do
  @totalNotifiationsSent = 0
  @notificationArray = Array.new
  @notificationArray << {:action=>'Software Starts', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'}
  @notificationArray << {:action=>'Do Nothing', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'}
  @notificationArray << {:action=>'Power Up Server', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOn-BatteryFull-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'}
  @notificationArray << {:action=>'Power On StandAlone AutoStart', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOn-BatteryFull-ServerOn-NASOff-StandAlonesOnZero-DependentsOnZero'}
  @notificationArray << {:action=>'Power On NASDependent AutoStart', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnZero'}
  @notificationArray << {:action=>'All Systems Good', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo'}
  @notificationArray << {:action=>'All Systems Good', :msg=>'', :waitTime=>6, :vitalHashTemplate=>'PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo'}
  @notificationArray << {:action=>'All Systems Good', :msg=>'', :waitTime=>15, :vitalHashTemplate=>'PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo'}
  @notificationArray << {:action=>'Power Failure', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOff-BatteryGood-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo'}
  @notificationArray << {:action=>'Power Down NASDependents', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOff-BatteryGood-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo'}
  @notificationArray << {:action=>'Do Nothing', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOff-BatteryGood-ServerOn-NASOn-StandAlonesOnOne-DependentsOnZero'}
  @notificationArray << {:action=>'Shutdown Server', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOff-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'}
  @notificationArray << {:action=>'Software Closes', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOff-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'}
  @notificationArray << {:action=>'Power Restored', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'}
  @notificationArray << {:action=>'Power Restored', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'}
  @notificationArray << {:action=>'Software Starts ', :msg=>'', :waitTime=>0, :vitalHashTemplate=>'PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'}
end



And(/^the vitalHash is (.*), (.*), (.*), (.*), (.*), (.*), (.*), (.*), (.*), (.*)$/) do |powerstate, batterylevel, upsPowerOnAtPercent, upsPowerOffAtPercent, isServerOnline, nasPoweredOn, standAloneAutoStartPoweredOff, nasDependentAutoStartPoweredOff, nasDependentPoweredOn, standAlonePoweredOn|
  @vitalHash = Hash.new

  @vitalHash = {:powerstate=>powerstate, :batterylevel=>batterylevel, :upsPowerOnAtPercent=>upsPowerOnAtPercent, :upsPowerOffAtPercent=>upsPowerOffAtPercent, :serverOnline=>isServerOnline, :NasPoweredOn=>nasPoweredOn, :StandAloneAutoStartPoweredOff=>standAloneAutoStartPoweredOff.to_i, :NasDependentAutoStartPoweredOff=>nasDependentAutoStartPoweredOff.to_i, :NasDependentPoweredOn=>nasDependentPoweredOn.to_i, :StandAlonePoweredOn=>standAlonePoweredOn.to_i}

  if @vitalHash[:batterylevel] > @vitalHash[:upsPowerOnAtPercent]
    @vitalHash[:batterygood]=true
  else
    @vitalHash[:batterygood]=false
  end

   #$stdout.puts "vitalHash: #{@vitalHash}"

end

def CreateVitalHashFromTemplate(hashTemplate)
  case hashTemplate
    when 'PowerOn-BatteryGood-ServerOn-NASOn-StandAlonesTrue-DependentsTrue'
      vitalHash = {:powerstate => true,
                    :batterylevel => 100.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => true,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 0,
                    :NasDependentPoweredOn => 2,
                    :StandAlonePoweredOn => 1,
                    :batterygood => true}
    when 'PowerOn-BatteryFull-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'
      vitalHash = {:powerstate => true,
                    :batterylevel => 100.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => false,
                    :NasPoweredOn => false,
                    :StandAloneAutoStartPoweredOff => 1,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 0,
                    :batterygood => true}
    when 'PowerOn-BatteryFull-ServerOn-NASOff-StandAlonesOnZero-DependentsOnZero'
      vitalHash = {:powerstate => true,
                    :batterylevel => 100.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => false,
                    :StandAloneAutoStartPoweredOff => 1,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 0,
                    :batterygood => true}
    when 'PowerOn-BatteryFull-ServerOn-NASOff-StandAlonesOnOne-DependentsOnZero'
      vitalHash = {:powerstate => true,
                    :batterylevel => 100.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => false,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 1,
                    :batterygood => true}
    when 'PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnZero '
      vitalHash = {:powerstate => true,
                    :batterylevel => 100.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => true,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 1,
                    :batterygood => true}
    when 'PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnOne'
      vitalHash = {:powerstate => true,
                    :batterylevel => 100.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => true,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 1,
                    :NasDependentPoweredOn => 1,
                    :StandAlonePoweredOn => 1,
                    :batterygood => true}
    when 'PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo'
      vitalHash = {:powerstate => true,
                    :batterylevel => 100.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => true,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 0,
                    :NasDependentPoweredOn => 2,
                    :StandAlonePoweredOn => 1,
                    :batterygood => true}
    when 'PowerOff-BatteryGood-ServerOn-NASOn-StandAlonesOnOne-DependentsOnTwo'
      vitalHash = {:powerstate => false,
                    :batterylevel => 85.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => true,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 0,
                    :NasDependentPoweredOn => 2,
                    :StandAlonePoweredOn => 1,
                    :batterygood => true}
    when 'PowerOff-BatteryGood-ServerOn-NASOn-StandAlonesOnOne-DependentsOnOne'
      vitalHash = {:powerstate => false,
                    :batterylevel => 85.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => true,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 1,
                    :NasDependentPoweredOn => 1,
                    :StandAlonePoweredOn => 1,
                    :batterygood => true}
    when 'PowerOff-BatteryGood-ServerOn-NASOn-StandAlonesOnOne-DependentsOnZero'
      vitalHash = {:powerstate => false,
                    :batterylevel => 85.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => true,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 1,
                    :batterygood => true}
    when 'PowerOff-BatteryLow-ServerOn-NASOn-StandAlonesOnOne-DependentsOnZero'
      vitalHash = {:powerstate => false,
                    :batterylevel => 75.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => true,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 1,
                    :batterygood => false}
    when 'PowerOff-BatteryLow-ServerOn-NASOff-StandAlonesOnZero-DependentsOnZero'
      vitalHash = {:powerstate => false,
                    :batterylevel => 55.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => false,
                    :StandAloneAutoStartPoweredOff => 1,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 0,
                    :batterygood => false}
    when 'PowerOff-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'
      vitalHash = {:powerstate => false,
                    :batterylevel => 50.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => false,
                    :NasPoweredOn => false,
                    :StandAloneAutoStartPoweredOff => 1,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 0,
                    :batterygood => false}
    when 'PowerOn-BatteryLow-ServerOff-NASOff-StandAlonesOnZero-DependentsOnZero'
      vitalHash = {:powerstate => true,
                    :batterylevel => 50.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => false,
                    :NasPoweredOn => false,
                    :StandAloneAutoStartPoweredOff => 1,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 0,
                    :batterygood => false}
    when 'PowerOn-BatteryFull-ServerOn-NASOn-StandAlonesOnOne-DependentsOnZero'
      vitalHash = {:powerstate => true,
                    :batterylevel => 100.0,
                    :upsPowerOnAtPercent => 90.0,
                    :upsPowerOffAtPercent => 80.0,
                    :serverOnline => true,
                    :NasPoweredOn => true,
                    :StandAloneAutoStartPoweredOff => 0,
                    :NasDependentAutoStartPoweredOff => 2,
                    :NasDependentPoweredOn => 0,
                    :StandAlonePoweredOn => 1,
                    :batterygood => false}
  end
  vitalHash
end

Given(/^I want push notifications to be false$/) do
  $esxi.SetPushNotificationSetting(false)
end

Given(/^I want push notifications to be true$/) do
  $esxi.SetPushNotificationSetting(true)
end


And(/^the vitalHash template is (.*)$/) do |hashTemplate|
  @vitalHash = CreateVitalHashFromTemplate(hashTemplate)
end

And(/^I want to wait (\d*) seconds$/) do |waitTime|
  sleep(waitTime)
end

And(/^a notification is sent with (.*), (.*)$/) do |action, message|
  if message == 'nil'
    notifyMessage = {:action=>action, :msg=>nil, :severity=>'info'}

  else
    notifyMessage = {:action=>action, :msg=>message, :severity=>'info'}
  end
  @notifyResult = $esxi.TriggerNotificationTest(notifyMessage, @vitalHash, @lastState)
  #$stdout.puts "notifyResult: #{@notifyResult}"
end

When(/The states are currently (.*), (.*), (.*), (.*)$/) do  |software, power, server, allSystems|
  @lastState = Hash.new
  @lastState[:software] = StateBoolNotificationHashTransform(software)
  @lastState[:power] = StateBoolNotificationHashTransform(power)
  @lastState[:server] = StateBoolNotificationHashTransform(server)
  @lastState[:allSystems] = StateBoolNotificationHashTransform(allSystems)

  # $stdout.puts "lastState: #{@lastState}"
end

When(/The states are currently (.*), (.*)$/) do  |allSystemsGoodState, power|
  @lastState = Hash.new
  @lastState[:allSystemsGood] = StateBoolNotificationHashTransform(allSystemsGoodState)
  @lastState[:power]={:state=> EvalForTrueFalseNil(power)}
end

When(/^the first (.*) are done$/) do |numberOfEvents|
  testArray = @notificationArray.first(numberOfEvents)
  testArray.each do |x|
    msg = {:action=>x[:action], :msg=>x[:msg], :severity=>'info'}
    sleep(x[:waitTime])
    result = $esxi.TriggerNotification(msg, CreateVitalHashFromTemplate(x[:vitalHashTemplate]))
    if (result[:triggerPush] == true)
      @totalNotifiationsSent = @totalNotifiationsSent + 1
    end
  end
end

Then(/^I should receive (.*) push notifications$/) do |totalPushesExpected|
  expect(@totalNotifiationsSent).to eq(totalPushesExpected)
end


Then(/^the logged result should be (.*)$/) do |logExpectation|
  expect(@notifyResult[:logged]).to eq(logExpectation)
end

Then(/^the pushed result should be (.*)$/) do |emailExpectation|
  #puts "expect:  #{emailExpectation}, notifyResult: #{@notifyResult}"
  expect(@notifyResult[:triggerPush]).to eq(emailExpectation)
end