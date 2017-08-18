require "./lib/required/Vmware.rb"
require "./lib/required/EsxiIni.rb"



# This is the script to run.
esxi = Vmware.new({:iniFileName=>'./esxiMonitor.ini', :iniSectionName=>'esxi_settings', :writeLogs=>true, :notifyByPush=>false})

begin
    while true
      maintHash = esxi.Maintenance()
      esxi.MaintenancePause({:pauseTime=>maintHash[:pauseTime], :pauseMsg=>maintHash[:pauseMsg]})
    end
rescue SignalException => e
  esxi.Destructor
rescue Exception => e
  esxi.Destructor
end

esxi= nil
