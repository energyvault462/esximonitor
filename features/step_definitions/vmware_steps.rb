
def MakeInitArgsHash(iniHash)
  argsHash=Hash.new
  iniHash.each do |i|
    argsHash[i[:iniKey].to_sym]=EvalForTrueFalseNil(i[:keyValue])
  end
  argsHash
end

def CheckVMPowerState(args={})
  returnValue = nil
  vminfo = $esxi.GetVmInfo(args[:name])
  if vminfo[:powerstate] == args[:desiredPowerState]
    returnValue = nil
  else
    return args[:desiredPowerState]
  end
end

def SetVMPowerStates(args={})
  powerOnArray = []
  powerOffArray = []
  args.each do |key, array|
    if array == true
      powerOnArray.push(key.to_s)
    elsif array == false
      powerOffArray.push(key.to_s)
    end
  end
  returnHash = Hash.new
  returnHash[:countPowerOn] = powerOnArray.length
  returnHash[:countPowerOff] = powerOffArray.length
  $esxi.VmGroupPowerOn(powerOnArray)
  $esxi.VmGroupPowerOff(powerOffArray)
  if (powerOnArray.length + powerOffArray.length) > 0
    sleep(15)
    $esxi.UpdateVmList
  end
  returnHash
end

def OpenEsxiObject(args={})
  args[:iniFileName] = File.join(File.dirname(__FILE__), '..', '..', 'features', 'support', args[:iniFileName].lstrip)
  args[:iniSectionName] = 'esxi_settings'
  if $esxi && $esxi.is_active?
    if !$esxi.TestDoesIniMatch?(args)
      $esxi = nil
      $esxi = Vmware.new(args)
    end
  else
    $esxi = Vmware.new(args)
  end
end

Given(/^I want to start new esxi using ini configuration file (.*)$/) do  |iniConfigFile|
  if $esxiStartCode != iniConfigFile
    $esxi = nil
    $esxiStartCode = iniConfigFile
    OpenEsxiObject({:iniFileName=>iniConfigFile, :iniSectionName=>'esxi_settings'})
  end
end

Given(/^I want to have esxi with the following keys$/) do |initArgsHash|
  args = MakeInitArgsHash(initArgsHash)
  OpenEsxiObject(args)
end

Given(/^the test VMs are set as (.*), (.*), (.*), (.*)/) do  |nastest, vmtest1, vmtest2, vmtest3|
  # Adds to a hash, nil do nothing, false need to power down, true need to power up.
  myHash = Hash.new
  myHash[:NASTest]=CheckVMPowerState({:name=>'NASTest', :desiredPowerState=>nastest})
  myHash[:VMTest1]=CheckVMPowerState({:name=>'VMTest1', :desiredPowerState=>vmtest1})
  myHash[:VMTest2]=CheckVMPowerState({:name=>'VMTest2', :desiredPowerState=>vmtest2})
  myHash[:VMTest3]=CheckVMPowerState({:name=>'VMTest3', :desiredPowerState=>vmtest3})
  SetVMPowerStates(myHash)
end

When(/^I ask for (.*) for VM (.*), power state (.*), auto start (.*), dont suspend (.*), stand alone (.*), guest tools (.*)$/) do |hasId, vmName, vmPowerState, vmAutoStart, vmNoSuspend, vmStandalone, vmGuestTools|
  @vmHash = Hash.new
  @vmHash = { :id => hasId, :vmname => vmName, :powerstate=>vmPowerState, :autostart=>vmAutoStart, :standalone => vmStandalone, :nosuspend => vmNoSuspend, :havetools => vmGuestTools}
end

When(/^I run the maintenance with (.*) and (.*)$/) do |powerstate, batterylevel|
   @maintReturnHash = $esxi.Maintenance({:test=>true, :powerstate=>powerstate, :batterylevel=>batterylevel})
   #$stdout.puts "notifyResult: #{$esxi.PrintStates}"
end



Then /^I will return a hash with name of (.*) including the id of (.*)$/ do  |vmName, idNumber|

	testhash = $esxi.GetVmInfo(vmName)
  testhash.delete(:path)
  testhash.delete(:pool)
  testhash.delete(:ipaddress)
  if testhash[:id].to_i > 0
    testhash[:id] = true
  else
    testhash[:id] = false
  end
  #$stdout.puts "@vmHash: #{@vmHash}"
  #$stdout.puts "testhash: #{testhash}"
	expect(testhash).to eq(@vmHash)
end

Then /^the action should be (.*)$/ do  |action|
  expect(action).to eq(@maintReturnHash[:ActionMessage])
end

Then(/^I should wait for (\d+) seconds$/) do |waitTime|
  sleep(waitTime)
end


Given(/^Line Voltage is (.*), the Battery Level is (\d+\.\d+), the upsPowerOnAtPercent is (\d+), and the upsPowerOffAtPercent is (\d+)$/) do |lineVoltage, batteryLevel, upsPowerOnAtPercent, upsPowerOffAtPercent|
  @vmVitalHashStart = Hash.new
  @vmVitalHashStart = { :powerstate =>lineVoltage, :batterylevel =>batteryLevel, :upsPowerOnAtPercent =>upsPowerOnAtPercent, :upsPowerOffAtPercent =>upsPowerOffAtPercent }
end

When(/^The circumstances are that NasPoweredOn is (.*), StandAloneAutoStartPoweredOff is (.*), NasDependentAutoStartPoweredOff is (\d+),  NasDependentPoweredOn is (\d+), and StandAlonePoweredOn is (\d+)$/) do |nasPoweredOn, standAloneAutoStartPoweredOff, nasDependentAutoStartPoweredOff, nasDependentPoweredOn, standAlonePoweredOn|
  @vmVitalHash = @vmVitalHashStart
  @vmVitalHash[:NasPoweredOn] = nasPoweredOn
  @vmVitalHash[:StandAloneAutoStartPoweredOff] = standAloneAutoStartPoweredOff.to_i
  @vmVitalHash[:NasDependentAutoStartPoweredOff] = nasDependentAutoStartPoweredOff.to_i
  @vmVitalHash[:NasDependentPoweredOn] = nasDependentPoweredOn.to_i
  @vmVitalHash[:StandAlonePoweredOn] = standAlonePoweredOn.to_i
end

Then(/^I will receive a result of (.*)$/) do |result|
  #testResult = 'Do Nothing'  # Change from static to the method's return
  testResult = $esxi.VmMaintenanceDecisionTime(@vmVitalHash)
  expect(testResult).to eq(result)
end

