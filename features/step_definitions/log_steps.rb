
Given(/^I want to write a log entry$/) do
  @logging = Log.new({:hdDir => '/log', :ramDiskDir => '/ram', :fileName => 'application.log', :writeLogs => true})
end

When(/^I send (.*) with a message of (.*)$/) do |severity, message|
		@logSimpleHash = Hash.new 
		@logSimpleHash[:severity] = severity.downcase
		@logSimpleHash[:logMsg] = message
		@logSimpleHash[:logged] = true
end

Then /^I will return a hash using (.*) with the message of (.*)$/ do  |severity, message|
	require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'required', 'Log')
  writeHash = {:logMsg => message, :severity => severity.downcase}
  testhash = @logging.WriteToLog(writeHash)
  @logging.CopyToHd
	expect(@logSimpleHash).to eq(testhash)
end

When (/^I call notify with (.*), (.*), and a message of (.*)$/) do |actionDone, severity, message|
  @logSimpleNotifyHash = Hash.new
  @logSimpleNotifyHash[:actionDone] = actionDone
  @logSimpleNotifyHash[:severity] = severity.downcase
  @logSimpleNotifyHash[:logMsg] = message
  @logSimpleNotifyHash[:logged] = true
end

#Then /^I will return a hash using <action>, <severity>, and a message of <message>$/ do  |actionDone, severity, message|
Then /^I will return a hash using (.*), (.*), and a message of (.*)$/ do  |actionDone, severity, message|
  require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'required', 'Log')
  notifyHash = {:actionDone => actionDone, :logMsg => message, :severity => severity.downcase}
  testhash = @logging.WriteToLog(notifyHash)
  @logging.CopyToHd
  expect(@logSimpleNotifyHash).to eq(testhash)
end