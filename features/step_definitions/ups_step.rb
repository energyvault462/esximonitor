
Given /^I want to use this UPS test file (.*)$/ do |fileToTest|
	@fileToTest = File.join(File.dirname(__FILE__), '..', '..', 'features', 'support', fileToTest.lstrip)
end

When /^I ask for power status of (.*), time stamp of (.*), battery level of (.*), success of (.*), error message of (.*)$/ do |lineVoltage, timeStamp, batteryLevel, success, errorMessage |
	@upsStatus = Hash.new 
	@upsStatus[:lineVoltage] = lineVoltage
	@upsStatus[:batteryLevel] = batteryLevel
	@upsStatus[:timeStamp] = timeStamp
	@upsStatus[:success] = success
	@upsStatus[:errorMessage] = errorMessage
end

Then /^I will return a hash with line voltage of (.*), time stamp of (.*), battery level of (.*), success of (.*), error message of (.*)$/ do  |lineVoltage, timeStamp, batteryLevel, success, errorMessage |
  #require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'required', 'Ups')

  testUps = Ups.new(@fileToTest, @fileToTest, false)
	testhash = testUps.GetUpsStatus
  if testhash[:errorMessage].include? "No such file or directory"
		testhash[:errorMessage] = "No such file or directory"
  end



  expect(testhash).to eq(@upsStatus)
	#expect(@upsStatus).to eq(@upsStatus)
end

When /^I ask for the battery level of (.*)$/ do | batteryLevel |
	@batteryLevel = batteryLevel
end

Then /^I will receive a battery level of (.*)$/ do  | batteryLevel |
	require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'required', 'Ups')

  testUps = Ups.new(@fileToTest, @fileToTest, false)
	testBatteryLevel = testUps.GetBatteryStatus

	expect(@batteryLevel).to eq(testBatteryLevel)
end

When /^I ask for the power status of (.*)$/ do | lineVoltage |
	@lineVoltage = lineVoltage
end

Then /^I will receive a power status of (.*)$/ do  | lineVoltage |
	require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'required', 'Ups')

  testUps = Ups.new(@fileToTest, @fileToTest, false)
	testPowerStatus = testUps.GetPowerStatus

	expect(@lineVoltage).to eq(testPowerStatus)
end



#DidStatusChange.feature
When /^the hash for power status of (.*), time stamp of (.*), battery level of (.*), success of (.*), error message of (.*), change result of (.*)$/ do |lineVoltage, timeStamp, batteryLevel, success, errorMessage, changeResult |
	@oldHash = Hash.new 
	@oldHash[:lineVoltage] = lineVoltage
	@oldHash[:batteryLevel] = batteryLevel
	@oldHash[:timeStamp] = timeStamp
	@oldHash[:success] = success
	@oldHash[:errorMessage] = errorMessage
	@changeResult = changeResult
end

#DidStatusChange.feature
Then /^the change result will be (.*)$/ do  |changeResult|
	require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'required', 'Ups')
    testUps = Ups.new(@fileToTest, @fileToTest, false)
	changeResult = testUps.TestStatusChanged(@oldHash)

	expect(@changeResult).to eq(changeResult)
end