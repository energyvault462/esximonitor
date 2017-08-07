require "./lib/required/Vmware.rb"
require "./lib/required/EsxiIni.rb"



# This is the script to run.
esxi = Vmware.new({:iniFileName=>'./features/support/cucumberesxiTest.ini', :iniSectionName=>'esxi_settings', :writeLogs=>true, :notifyByPush=>false})

begin
    while true
        esxi.Maintenance({:test=>true})
        sleep 30
    end
rescue SignalException => e
  esxi.Destructor
rescue Exception => e
  esxi.Destructor
end

esxi= nil
