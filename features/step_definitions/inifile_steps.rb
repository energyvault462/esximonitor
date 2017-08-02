Given(/^the (.*) doesn't exist$/) do |fileToTest|
  @iniConfigFile = File.join(File.dirname(__FILE__), '..', '..', 'features', 'support', fileToTest.lstrip)
  if File.exist?(@iniConfigFile)
    File.delete(@iniConfigFile)
  end
end

When(/^the software loads up$/) do
  test=true
end

Then(/^the file should be created and populated with default settings\.$/) do
  esxiini = EsxiIni.new({:iniFileName=>@iniConfigFile, :iniSectionName=>'esxi_settings'})
end



When /^I ask for esxi_settings (.*)$/ do |settingName|
  @iniSetting = {:iniName => settingName}
end

Given /^I want to test this (.*) file$/ do |fileToTest|
  @iniConfigFile = File.join(File.dirname(__FILE__), '..', '..', 'features', 'support', fileToTest.lstrip)
end

Then /^I will get (.*)$/ do |settingValue|
    esxiini = EsxiIni.new({:iniFileName=>@iniConfigFile, :iniSectionName=>'esxi_settings'})


  iniValueReturned = esxiini.GetValue(@iniSetting[:iniName])
  # if it's a comma separated array, need to change the expected value to an array
  if iniValueReturned.kind_of?(Array)
    settingValue = settingValue.split(',')
  end
  expect(iniValueReturned).to eq(settingValue)

end