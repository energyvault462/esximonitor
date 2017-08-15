#TODO:  	def GetVmInfo is where to begin the verbose logging
require 'net/ssh'
require 'time'

# Require EsxiIni
begin
  require "./required/EsxiIni.rb"
rescue Exception => e
  require "./lib/required/EsxiIni.rb"
end

# Require Log
begin
  require "./required/Notification.rb"
rescue Exception => e
  require "./lib/required/Notification.rb"
end

# Require Ups
begin
  require "./required/Ups.rb"
rescue Exception => e
  require "./lib/required/Ups.rb"
end

#https://github.com/myronmarston/vcr/commit/30b6242a1b0e97a21c27808e416e9b9e8215f994
# Ping
begin
    require 'vcr/ping'
rescue LoadError
    # This is copied, verbatim, from Ruby 1.8.7's ping.rb.
    require 'timeout'
    require "socket"

     module Ping
       def pingecho(host, thetimeout=5, service="echo")
         begin
           Timeout.timeout(thetimeout) do
           s = TCPSocket.new(host, service)
           s.close
           end
         rescue Errno::ECONNREFUSED
             return true
             rescue Timeout::Error, StandardError
                 return false
                 end
       return true
       end
     module_function :pingecho
     end
end

# This class connects to the VMWare Esxi server.
class Vmware

	# Description -- Sets the required fields (host, un, pw) and calls the UpdateVmList
	# @param [String] iniFile
	# @return [Nil] Nothing
  def initialize (args={})
    args[:iniFileName] = args.fetch(:iniFileName, 'cucumberesxiTest.ini')

    @ini = EsxiIni.new(args)

    @iniHash = InitializeIniHash(args)
    @host = self.GetIniValue('serverIp')
    @user = self.GetIniValue('serverName') #need to change this.
    @pw = self.GetIniValue('serverPw')

    @ups = Ups.new(self.GetIniValue('UpsInputName'), self.GetIniValue('UpsOutputName'), self.GetIniValue('useApcaccess'))
    @testVms = self.GetIniValue('testMachines')
    if @testVms.nil?
      @limitVmHosts = false
      @testVms = []
    else
      @limitVmHosts = true
    end

    @notify = Notification.new(CreateNotificationInitHash(self.GetIniValue('writeLogs')))

    self.UpdateVmList

    PostInitialize(args)  # here so any children classes can have a PostInitialize class to do stuff too.

    if GetIniValue('notifyByPush') == true
      self.SendStartupNofication
    end

  end

  def PostInitialize(args)
    nil
  end

  def Destructor

    @notify.CloseLog({:closeMessage=>'Software Closes'})
  end

  def InitializeIniHash(args)
    iniHash = Hash.new

    iniHash[:serverIp] = args.fetch(:serverIp, @ini.GetValue('serverIp'))
    iniHash[:serverIp] = iniHash.fetch(:serverIp, '192.168.1.2')
    iniHash[:serverName] = args.fetch(:serverName, @ini.GetValue('serverName'))
    iniHash[:serverName] = iniHash.fetch(:serverName, 'MyEsxiUserName')
    iniHash[:serverPw] = args.fetch(:serverPw, @ini.GetValue('serverPw'))
    iniHash[:serverPw] = iniHash.fetch(:serverPw, 'MyServerPassword')
    iniHash[:useApcaccess] = args.fetch(:useApcaccess, @ini.GetValue('useApcaccess'))
    iniHash[:useApcaccess] = iniHash.fetch(:useApcaccess, false)

    iniHash[:notifyByPush] = args.fetch(:notifyByPush, @ini.GetValue('notifyByPush'))
    iniHash[:notifyByPush] = iniHash.fetch(:notifyByPush, false)

    iniHash[:pushoverUserToken] = args.fetch(:pushoverUserToken, @ini.GetValue('pushoverUserToken'))
    iniHash[:pushoverUserToken] = iniHash.fetch(:pushoverUserToken, nil)
    iniHash[:pushoverAppToken] = args.fetch(:pushoverAppToken, @ini.GetValue('pushoverAppToken'))
    iniHash[:pushoverAppToken] = iniHash.fetch(:pushoverAppToken, nil)

    iniHash[:allowHostShutdown] = args.fetch(:allowHostShutdown, @ini.GetValue('allowHostShutdown'))
    iniHash[:allowHostShutdown] = iniHash.fetch(:allowHostShutdown, false)


    iniHash[:standAlone] = args.fetch(:standAlone, @ini.GetValue('standAlone'))
    iniHash[:standAlone] = iniHash.fetch(:standAlone, 'standAlone')
    iniHash[:nasVmName] = args.fetch(:nasVmName, @ini.GetValue('nasVmName'))
    iniHash[:nasVmName] = iniHash.fetch(:nasVmName, 'nasVmName')
    iniHash[:noSuspend] = args.fetch(:noSuspend, @ini.GetValue('noSuspend'))
    iniHash[:noSuspend] = iniHash.fetch(:noSuspend, 'noSuspend')
    iniHash[:autoStart] = args.fetch(:autoStart, @ini.GetValue('autoStart'))
    iniHash[:autoStart] = iniHash.fetch(:autoStart, 'autoStart')
    iniHash[:testMachines] = args.fetch(:testMachines, @ini.GetValue('testMachines'))
    iniHash[:testMachines] = iniHash.fetch(:testMachines, 'testMachines')
    iniHash[:useApcaccess] = args.fetch(:useApcaccess, @ini.GetValue('useApcaccess'))
    iniHash[:useApcaccess] = iniHash.fetch(:useApcaccess, false)
    iniHash[:upsPowerOnAtPercent] = args.fetch(:upsPowerOnAtPercent, @ini.GetValue('upsPowerOnAtPercent'))
    iniHash[:upsPowerOnAtPercent] = iniHash.fetch(:upsPowerOnAtPercent, 50.0)
    iniHash[:upsPowerOffAtPercent] = args.fetch(:upsPowerOffAtPercent, @ini.GetValue('upsPowerOffAtPercent'))
    iniHash[:upsPowerOffAtPercent] = iniHash.fetch(:upsPowerOffAtPercent, 80.0)
    iniHash[:UpsOutputName] = args.fetch(:UpsOutputName, @ini.GetValue('UpsOutputName'))
    iniHash[:UpsOutputName] = iniHash.fetch(:UpsOutputName, './upstest.txt')
    iniHash[:UpsInputName] = args.fetch(:UpsInputName, @ini.GetValue('UpsInputName'))
    iniHash[:UpsInputName] = iniHash.fetch(:UpsInputName, './upstest.txt')
    iniHash[:writeLogs] = args.fetch(:writeLogs, @ini.GetValue('writeLogs'))
    iniHash[:writeLogs] = iniHash.fetch(:writeLogs, true)
    iniHash[:verboseLogging] = args.fetch(:verboseLogging, @ini.GetValue('verboseLogging'))
    iniHash[:verboseLogging] = iniHash.fetch(:verboseLogging, false)
    iniHash[:hdDir] = args.fetch(:hdDir, @ini.GetValue('hdDir'))
    iniHash[:hdDir] = iniHash.fetch(:hdDir, '/hd')
    iniHash[:ramDiskDir] = args.fetch(:ramDiskDir, @ini.GetValue('ramDiskDir'))
    iniHash[:ramDiskDir] = iniHash.fetch(:ramDiskDir, '/ramDiskDir')
    iniHash[:fileName] = args.fetch(:fileName, @ini.GetValue('fileName'))
    iniHash[:fileName] = iniHash.fetch(:fileName, 'application.log')
    iniHash[:stopMaintFileName] = args.fetch(:stopMaintFileName, @ini.GetValue('stopMaintFileName'))
    iniHash[:stopMaintFileName] = iniHash.fetch(:stopMaintFileName, './stopmaint.txt')
    iniHash[:secondsBetweenLoggingAllSystemsGood] = args.fetch(:secondsBetweenLoggingAllSystemsGood, @ini.GetValue('secondsBetweenLoggingAllSystemsGood'))
    iniHash[:secondsBetweenLoggingAllSystemsGood] = iniHash.fetch(:secondsBetweenLoggingAllSystemsGood, 3600)

    # Args only, not going to be in the config file.
    iniHash[:notifyPushTest] = args.fetch(:notifyPushTest, false)

    # new key template, use both lines for a single key to get it from the ini if not specified, and to give a default value if not in ini file.
    #iniHash[:key] = @settingsHash.fetch(:key, @ini.GetValue('key'))
    #iniHash[:key] = iniHash.fetch(:key, 'keyValue')

    return iniHash
  end

  def CreateNotificationInitHash(useLogsFromInit)
    tempHash = Hash.new
    if useLogsFromInit == nil
      tempHash[:writeLogs] = self.GetIniValue('writeLogs')
    else
      tempHash[:writeLogs] = useLogsFromInit
    end

    if tempHash[:writeLogs]
      tempHash[:hdDir] = self.GetIniValue('hdDir')
      tempHash[:fileName] = self.GetIniValue('fileName')
      tempHash[:ramDiskDir] = self.GetIniValue('ramDiskDir')
    end

    tempHash[:notifyByPush] = self.GetIniValue('notifyByPush')
    tempHash[:pushoverUserToken] = self.GetIniValue('pushoverUserToken')
    tempHash[:pushoverAppToken] = self.GetIniValue('pushoverAppToken')
    tempHash[:secondsBetweenLoggingAllSystemsGood] = self.GetIniValue('secondsBetweenLoggingAllSystemsGood')
    tempHash[:verboseLogging] = self.GetIniValue('verboseLogging')
    tempHash[:initialActionMsg] = 'Software Starts'
    tempHash
  end

  def SendStartupNofication
    actionStr = "Software Starts"
    msgStr = "Start Details"

    TriggerNotification({:severity=>'info', :action=>'Software Starts', :msg=>msgStr})
  end


  def GetIniValue(keyName)
    #return @ini.GetValue(keyName)
    return @iniHash[keyName.to_sym]
  end

	# This runs a command to the host via SSH and returns the results of the command.
	# @param [String] command -- What is being run on the host machine.
	# @return [String] Output of the command.
	def RunSshCommand(command)
		output = ""
		#start_time = Time.now
		#puts "running: #{command}"
    TriggerNotification({:severity=>'info', :action=>"SSH Command: #{command}", :verbose=>true})
    Net::SSH.start( @host, @user) do|ssh|
			output = ssh.exec!(command)
    end

		#end_time = Time.now
		#elapsed_seconds = (end_time - start_time)
		#puts "Finished: #{command}"
		#puts "Took: #{elapsed_seconds}"
		return output
	end

	# Creates the master list of VMs and their current status.
	# @return [Nil] Nothing
	def UpdateVmList()
		if defined? @vmListHash
			@vmListHash = nil
		end
		@vmListHash = Hash.new

    TriggerNotification({:severity=>'info', :action=>"Starting: UpdateVmList", :verbose=>true})

		output = self.RunSshCommand('vim-cmd vmsvc/getallvms')

		match1 = output.split("\n")

		match1.each_with_index do |item, index|
			if index == 0
				#Do Nothing on the first row, it's the header row.
      else
				match2 = /(\d*)(\s*)(\S*)([ ]*)(\[\S*\] \S*)([ ]*)(\S*)([ ]*)(\S*)/.match(match1[index])
				# match2 example line: 8      VMMinecraft   [DatastoreSSD1] VMMinecraft/VMMinecraft.vmx   ubuntu64Guest       vmx-08
				vmId = match2[1].strip.to_i
				vmname = match2[3].strip
        if @limitVmHosts
          if  @testVms.include?(vmname)
            UpdateVmInfo(vmname, vmId)
          end
        else
          UpdateVmInfo(vmname, vmId)
        end
			end
    end
  end

  # Updates/Creates the vmListHash's single VM Information.
  # @param [String] vmname
  # @param [String] vmId -- Not required if just updating VM
  def UpdateVmInfo(vmname, vmId = nil)
    TriggerNotification({:severity=>'info', :action=>"Starting: UpdateVmInfo", :verbose=>true})
    vmDetails = Hash.new
    vmGuestDetails = Hash.new

    #Gather some info
    powerstate = self.IsVmPoweredOn?(vmId)
    autostart = self.IsAutoStart?(vmname)
    standalone = self.IsStandAlone?(vmname)
    nosuspend = self.IsNoSuspend?(vmname)

    #Create hash based on info gathered, adding the guest details if powered on.
    if powerstate
      vmGuestDetails = self.GetVmGuestDetails(vmId)
      vmDetails = {:id => vmId, :vmname => vmname, :powerstate => powerstate, :autostart => autostart, :standalone => standalone, :nosuspend => nosuspend, :havetools => vmGuestDetails[:toolsStatusReturned]}
    else
      vmDetails = {:id => vmId, :vmname => vmname, :powerstate => powerstate, :autostart => autostart, :standalone => standalone, :nosuspend => nosuspend, :havetools => false, :ipaddress => nil}
    end
    if @vmListHash.has_key?(vmname)  # update this VM's entry
      @vmListHash[vmname][:powerstate] = powerstate
      @vmListHash[vmname][:havetools] = vmDetails[:havetools]
      @vmListHash[vmname][:ipaddress] = vmDetails[:ipaddress]
    else # add this VM into the list.
      @vmListHash[vmname] = vmDetails
    end
    TriggerNotification({:severity=>'info', :action=>"Finished: UpdateVmInfo:  #{vmDetails}", :verbose=>true})
    vmDetails = nil
    vmGuestDetails = nil
  end

  # Checks the configuration file to see if the requested vmname is supposed to autostart
  # @param [String] vmname
  # @return [Boolean] True if autostart
  def IsAutoStart?(vmname)
    TriggerNotification({:severity=>'info', :action=>"Starting: IsAutoStart?(#{vmname})", :verbose=>true})
		autoStart = self.GetIniValue('autoStart')
    TriggerNotification({:severity=>'info', :action=>"Finished: IsAutoStart?(#{vmname}): #{autoStart.include?(vmname)}", :verbose=>true})
		return autoStart.include?(vmname)
	end

  # Checks the configuration file to see if the requested vmname is a standalone machine
  # @param [String] vmname
  # @return [Boolean] True if Stand Alone
	def IsStandAlone?(vmname)
    TriggerNotification({:severity=>'info', :action=>"Starting: IsStandAlone?(#{vmname})", :verbose=>true})
		standAlone = self.GetIniValue('standAlone')
    TriggerNotification({:severity=>'info', :action=>"Finished: IsStandAlone?(#{vmname}): standAlone.include?(vmname)", :verbose=>true})
		return standAlone.include?(vmname)
  end

  # Checks the configuration file to see if the requested vmname cannot be suspended.
  # @param [String] vmname
  # @return [Boolean] True if cannot be suspended.
  def IsNoSuspend?(vmname)
    TriggerNotification({:severity=>'info', :action=>"Starting: IsNoSuspend?(#{vmname})", :verbose=>true})
    noSuspend = self.GetIniValue('noSuspend')
    TriggerNotification({:severity=>'info', :action=>"Finished: IsNoSuspend?(#{vmname}): noSuspend.include?(vmname)", :verbose=>true})
    return noSuspend.include?(vmname)
  end

	# Gets the guest status information of the requested VM by ID.
	# @param [Int] vmId
	# @return [Hash] Hash of the requested information.  :toolsStatusReturned
	def GetVmGuestDetails(vmId)
		vmHash = Hash.new
		commandToRun = "vim-cmd vmsvc/get.guest #{vmId}"
    TriggerNotification({:severity=>'info', :action=>"Starting: GetVmGuestDetails(#{vmId}): CommandToRun: #{commandToRun}", :verbose=>true})
		output = self.RunSshCommand(commandToRun)
		vmHash = Hash.new
		toolsStatusReturned = /toolsStatus = \"(.*)\"/.match(output)

		if toolsStatusReturned == nil
			vmHash[:toolsStatusReturned]=false
		else
			if toolsStatusReturned[1] == "toolsOk"
				vmHash[:toolsStatusReturned]=true
			else
				vmHash[:toolsStatusReturned]=false
			end
    end
    TriggerNotification({:severity=>'info', :action=>"Finished: GetVmGuestDetails(#{vmId}) -  Result: #{vmHash}", :verbose=>true})
		return vmHash
	end


	# Create and return the hash of the information of the requested VM.
	# @param [String] vmName -- Machine name being requested.
	# @return [Hash] Returns full has of the requested virtual machine.  { :id, :vmname,  :powerstate, :havetools, :ipaddress }
	def GetVmInfo(vmName)
		vmHash = Hash.new
		if vmName == nil
			vmHash = { :id=>nil, :vmname=>vmName, :powerstate=>nil, :autostart=>nil, :standalone => nil, :nosuspend => nil,  :havetools=>nil, :ipaddress=>nil }
			return vmHash
		end

		if vmName.strip.length > 0
			if @vmListHash[vmName] == nil #name not found, set everything to nil except :vmname
				vmHash = { :id=>nil, :vmname=>vmName, :powerstate=>nil, :autostart=>nil, :standalone => nil, :nosuspend => nil,  :havetools=>nil, :ipaddress=>nil }
			else
				vmHash = @vmListHash[vmName]
			end
		else # Name was not defined, set everything to nil including :vmname
			vmHash = { :id=>nil, :vmname=>nil, :powerstate=>nil, :autostart=>nil, :standalone => nil, :nosuspend => nil,  :havetools=>nil, :ipaddress=>nil }
    end
    #TriggerNotification({:severity=>'info', :action=>"Finished: GetVmInfo(#{vmName}) -  Result: #{vmHash}", :verbose=>true}
		return vmHash
  end

	# Get the power state of the requested VM.
	# @param [Int] vmId -- Target ID
	# @return [Boolean] True/False
	def IsVmPoweredOn?(vmId)
    TriggerNotification({:severity=>'info', :action=>"Starting:  IsVmPoweredOn?(#{vmId})", :verbose=>true})
		result=false
		commandToRun = "vim-cmd vmsvc/power.getstate #{vmId}"
		output = self.RunSshCommand(commandToRun)
		if (output=~/Powered on/)
			result = true
    end
    TriggerNotification({:severity=>'info', :action=>"Finished:  IsVmPoweredOn?(#{vmId}) - Result: #{result}", :verbose=>true})
		return result
	end

  # Power on 1 or more virtual machines.
  # @param [Array] vmList (by VM name)
  # @return [Boolean] of success or some form of failure.
  def VmGroupPowerOn(vmList)
    TriggerNotification({:severity=>'info', :action=>"Starting: VmGroupPowerOn(#{vmList})", :verbose=>true})
    result=true

    self.TriggerNotification({:severity=>'info', :action=>'Power On (group)', :msg=>vmList})
    commandString = CreateGroupCommandString(vmList, 'power.on')

    output = self.RunSshCommand(commandString)
    if (output=~/Power on failed/)
      result = false
    end
    TriggerNotification({:severity=>'info', :action=>"Finished: VmGroupPowerOn(#{vmList}) - Result: #{result}", :verbose=>true})
    return result
  end

  # Get list of machines that are powered on, standalone and Autostart
  #     by calling ReturnVmListByStatus with correct parameters.
  #     and filtering out Manual starting machines via FilterOutByAutostart.
  # @return [Array] of the Virtual Machines matching this criteria
  def ArrayPoweredOnStandAloneAutostart
    TriggerNotification({:severity=>'info', :action=>"Starting: ArrayPoweredOnStandAloneAutostart", :verbose=>true})
    vmList = ReturnVmListByStatus(true, true)
    result = FilterOutByAutostart(vmList, true)
    TriggerNotification({:severity=>'info', :action=>"Finished: ArrayPoweredOnStandAloneAutostart - Result: #{result}", :verbose=>true})
    return result
  end

  # Get list of machines that are powered on, standalone and Manual Start
  #     by calling ReturnVmListByStatus with correct parameters.
  #     and filtering out Auto starting machines via FilterOutByAutostart.
  # @return [Array] of the Virtual Machines matching this criteria
  def ArrayPoweredOnStandAloneManualStart
    TriggerNotification({:severity=>'info', :action=>"Starting: ArrayPoweredOnStandAloneManualStart", :verbose=>true})
    vmList = ReturnVmListByStatus(true, true)
    result = FilterOutByAutostart(vmList, false)
    TriggerNotification({:severity=>'info', :action=>"Finished: ArrayPoweredOnStandAloneManualStart - Result: #{result}", :verbose=>true})
    return result
  end

  # Get list of machines that are powered on, Dependent and Manual Start
  #     by calling ReturnVmListByStatus with correct parameters.
  #     and filtering out Auto starting machines via FilterOutByAutostart.
  # @return [Array] of the Virtual Machines matching this criteria
  def ArrayPoweredOnDependentManualStart
    TriggerNotification({:severity=>'info', :action=>"Starting: ArrayPoweredOnDependentManualStart", :verbose=>true})
    vmList = ReturnVmListByStatus(true, false)
    result = FilterOutByAutostart(vmList, false)
    TriggerNotification({:severity=>'info', :action=>"Finished: ArrayPoweredOnDependentManualStart - Result: #{result}", :verbose=>true})
    return result
  end


  # Deletes out unwanted autoStart.
  # @param [Array] vmArray is original list of Virtual Machines.
  # @param [Boolean] autoStart is what you want to keep in the list.
  # @return [Array] of list of machines that only include the autoStart Yes/No requested.
  def FilterOutByAutostart(vmArray, autoStart)
    listToDelete = []
    #build list of machines to delete from the vmArray array.
    vmArray.each do |name|
      #using !autoStart since we want to remove the ones that don't qualify.
      if @vmListHash[name][:autostart] == !autoStart
        listToDelete.push(name)
      end
    end

    #delete the machines in the vmArray
    listToDelete.each do |name|
      vmArray.delete(name)
    end

    return vmArray
  end


  # Suspend/Shutdown all Stand Alone virtual Machines.
  def ShutdownStandAlone
    TriggerNotification({:severity=>'info', :action=>"Starting: ShutdownStandAlone", :verbose=>true})
    if self.ArrayPoweredOnStandAlone.length > 0
      TriggerNotification({:severity=>'info', :action=>'Power Down StandAlones'})
      VmGroupPowerOff(self.ArrayPoweredOnStandAlone)
    end
    TriggerNotification({:severity=>'info', :action=>"Finished: ShutdownStandAlone", :verbose=>true})
  end

  # Suspend/Shutdown all powered on NAS Dependent.
  def ShutdownNasDependent
    TriggerNotification({:severity=>'info', :action=>"Starting: ShutdownNasDependent", :verbose=>true})
    if self.ArrayPoweredOnDependent.length > 0
      TriggerNotification({:severity=>'info', :action=>'Power Down NASDependents'})
      result = self.VmGroupPowerOff(self.ArrayPoweredOnDependent)
    end
    TriggerNotification({:severity=>'info', :action=>"Finished: ShutdownNasDependent", :verbose=>true})
  end


  # Starts up all the NAS Dependent Autostarting Virtual Machines after making sure NAS is on.
  def StartupAutostartNasDependent
    TriggerNotification({:severity=>'info', :action=>"Starting: StartupAutostartNasDependent", :verbose=>true})
    while !self.isNasActive?
      self.UpdateVmList

      if !self.isNasPoweredOn?
        TriggerNotification({:severity=>'debug', :action=>'Power On StandAlone AutoStart from StartupAutostartNasDependent'})
        self.VmGroupPowerOn(self.ArrayPoweredOffStandAloneAutostart)
        self.UpdateVmList
      elsif !isNasActive? and self.isNasPoweredOn?
        puts "isNasActive?: #{isNasActive?}"
        sleep (5)
        self.UpdateVmList
      end
    end
    if self.ArrayPoweredOffDependentAutostart.length > 0
      TriggerNotification({:severity=>'info', :action=>'Power On NASDependent AutoStart'})
      self.VmGroupPowerOn(self.ArrayPoweredOffDependentAutostart)
      sleep (5)
      self.UpdateVmList
    end
    TriggerNotification({:severity=>'info', :action=>"Finished: StartupAutostartNasDependent", :verbose=>true})
  end

  # Power off 1 or more virtual machines. -- Suspend is preferred, will shutdown if not allowed to suspend.
  # @param [Array] vmList (by VM name)
  # @return [Boolean] of success or some form of failure.
  def VmGroupPowerOff(vmList)
    result = true
    doNotSuspendList = CheckListForDoNotSuspend(vmList)
    if doNotSuspendList.count == 0  # If All machines can be suspended
      self.TriggerNotification({:severity=>'info', :action=>'Suspend (group)', :msg=>vmList})
      commandString = CreateGroupCommandString(vmList, 'power.suspend')
    else  # If some in the list cannot be suspended

      # Remove from the original list the ones that cannot be suspended.
      doNotSuspendList.each do |vm|
        vmList.delete(vm)
      end
      # Build the command, starting with ones that can be suspended, then shutdown.
      commandArray = []
      if CreateGroupCommandString(vmList, 'power.suspend').length > 0
        self.TriggerNotification({:severity=>'info', :action=>'Suspend (group)', :msg=>vmList})
        commandArray.push(CreateGroupCommandString(vmList, 'power.suspend'))
      end
      if CreateGroupCommandString(doNotSuspendList, 'power.shutdown').length > 0
        self.TriggerNotification({:severity=>'info', :action=>'Power Off (group)', :msg=>doNotSuspendList})
        commandArray.push(CreateGroupCommandString(doNotSuspendList, 'power.shutdown'))
      end
      commandString = commandArray.join(";")
    end

   output = self.RunSshCommand(commandString)
    if (output=~/Power on failed/) or (output=~/Suspend failed/)
      result = false
    end
    return result
  end

  def ServerShutdown()
    if @iniHash[:allowHostShutdown]
      result = true
      output = self.RunSshCommand('poweroff')
      if (output=~/Power on failed/) or (output=~/Suspend failed/)
        result = false
      end
      return result
    else
      return false
    end
  end

  # Check the Arrayed List passed into it for VM's that are flagged as can't suspend.
  # @param [Array] vmList (by VM name)
  # @return [Array] of Virtual Machine names that cannot be suspended.
  def CheckListForDoNotSuspend(vmList)
    doNotSuspendList = []
    vmList.each do |vm|
      if @vmListHash[vm][:nosuspend]
        doNotSuspendList.push(vm)
      end
    end
    return doNotSuspendList
  end

  # Builds the Command string from an array of VM's by VM Name
  # @param [Array] vmList (by VM name)
  # @param [String] cmdModeStr of what's passed to the vim-cmd.. such as:  power.suspend
  # @return [String] of what can be sent to the ESXi host.
  def CreateGroupCommandString(vmList, cmdModeStr)
    commandArray = []
    vmList.each do |vm|
      commandArray.push("vim-cmd vmsvc/#{cmdModeStr} #{@vmListHash[vm][:id]}")

    end
    return commandArray.join(";")
  end



  # Checks to see if the NAS is powered on.
  # @return [Boolean]  True/False depending on if the NAS is powered on.
  def isNasPoweredOn?
    hash = GetVmInfo(self.GetIniValue('nasVmName'))
    return hash[:powerstate]
  end

  # Is the NAS active
  # @return [Boolean] True/False depending on if the NAS is active.  Only 1 NAS allowed.
  def isNasActive?()
    hash = GetVmInfo(self.GetIniValue('nasVmName'))
    return hash[:havetools]
  end


  # Get a list of Virtual Machine Names based on combination of power (on/off) and standalone/nas dependent
  # @param [Boolean] powerstate -- Powered On or off (true/false)
  # @param [Boolean] standalone -- True if NAS can be off.
  # @return [Array] of Virtual Machine Names.  Nil if none found.
  def ReturnVmListByStatus(powerstate, standalone)
		returnArray = []
		@vmListHash.each do |key, array|
			if array[:powerstate] == true
				powerStateOfHash = true
			else
				powerStateOfHash = false
			end
			if array[:standalone] == true
				standaloneStateOfHash = true
			else
				standaloneStateOfHash = false
			end
			if powerStateOfHash == powerstate and standaloneStateOfHash == standalone
				returnArray.push(array[:vmname])
			end
		end
		return returnArray
  end

  # Get a list of Machines that are powered on and Standalone
  #     by calling ReturnVmListByStatus with correct parameters.
  # @return [Array] of the Virtual Machines matching this criteria
  def ArrayPoweredOnStandAlone
		return ReturnVmListByStatus(true, true)
  end

  # Get list of machines that are powered on and Dependent
  #     by calling ReturnVmListByStatus with correct parameters.
  # @return [Array] of the Virtual Machines matching this criteria
	def ArrayPoweredOnDependent
		return ReturnVmListByStatus(true, false)
  end


  # Get list of machines that are powered on and standalone
  #     by calling ReturnVmListByStatus with correct parameters.
  # @return [Array] of the Virtual Machines matching this criteria
	def ArrayPoweredOffStandAlone
		return ReturnVmListByStatus(false, true)
  end

  # Get list of machines that are powered off, standalone and Auto Start
  #     by calling ReturnVmListByStatus with correct parameters.
  #     and filtering out Manual starting machines via FilterOutByAutostart.
  # @return [Array] of the Virtual Machines matching this criteria
  def ArrayPoweredOffStandAloneAutostart
    #Get list of machines that are turned off and not standalone.
    vmList = self.ReturnVmListByStatus(false, true)
    returnList = self.FilterOutByAutostart(vmList, true)
    returnList
  end


  # Get list of machines that are powered off, dependent and auto Start
  #     by calling ReturnVmListByStatus with correct parameters.
  #     and filtering out Manual starting machines via FilterOutByAutostart.
  # @return [Array] of the Virtual Machines matching this criteria
	def ArrayPoweredOffDependentAutostart
		#Get list of machines that are turned off and not standalone.
    vmList = ReturnVmListByStatus(false, false)
    return FilterOutByAutostart(vmList, true)
  end


  # Uses ping to see if the computer responds via ping.
  # @return [Boolean] True if server could be pinged.
  # @param [String] computerNameOrIp is Name or IP of computer being tested.
  def IsComputerOnline?(computerNameOrIp)
    Ping.pingecho computerNameOrIp, 1, 80
  end

  # Send magic packet to wake a system
  # @param [String] mac -- mac address of system to wake up.
  def WakeOnLan(mac)
    # wol.rb: sends out a magic packet to wake up your PC
    #
    # Copyright (c) 2004 zunda <zunda at freeshell.org>
    #
    # This program is free software. You can re-distribute and/or
    # modify this program under the same terms of ruby itself ---
    # Ruby Distribution License or GNU General Public License.
    #

    # target machine
    #mac = 'XX:XX:XX:XX:XX:XX'	# hex numbers

    require 'socket'

    # target network
    subhost = /(\d*.\d*.\d*)/.match(self.GetIniValue('serverIp'))
    host = subhost[1] << ".0"

    local = true

    port = 9	# Discard Protocol
    message = "\xFF"*6 + [ mac.gsub( /:/, '' ) ].pack( 'H12' )*16
    txbytes = UDPSocket.open do |so|
      if local then
        so.setsockopt( Socket::SOL_SOCKET, Socket::SO_BROADCAST, true )
      end
      so.send( message, 0, host, port )
    end
    # puts "#{txbytes} bytes sent to #{host}:#{port}."
  end



  # Builds a hash of all the vital statistics.
  # @param [Boolean] powerstate
  # @param [Boolean] batterylevel
  # @param [Float] upsPowerOnAtPercent
  # @param [Float] upsPowerOffAtPercent
  # @return [Hash] of the vital statistics
 # def BuildVitalHash(powerstate, batterylevel, upsPowerOnAtPercent, upsPowerOffAtPercent)
#    vitalHash = Hash.new
  def BuildVitalHash()
    vitalHash = Hash.new
    @ups.UpsMaintenance
    vitalHash[:powerstate] = @ups.GetPowerStatus
    vitalHash[:batterylevel] = @ups.GetBatteryStatus
    vitalHash[:upsPowerOnAtPercent] = @ini.GetValue('upsPowerOnAtPercent')
    vitalHash[:upsPowerOffAtPercent] = @ini.GetValue('upsPowerOffAtPercent')

    if vitalHash[:batterylevel].to_f >= vitalHash[:upsPowerOffAtPercent]
      vitalHash[:batterygood] = true
    else
      vitalHash[:batterygood] = false
    end

    if IsComputerOnline?(@iniHash[:serverIp])
      vitalHash[:serverOnline] = true
      vitalHash[:NasPoweredOn] = isNasActive?
      vitalHash[:StandAloneAutoStartPoweredOff] = self.ArrayPoweredOffStandAloneAutostart.length
      vitalHash[:NasDependentAutoStartPoweredOff] = self.ArrayPoweredOffDependentAutostart.length
      vitalHash[:NasDependentPoweredOn] = self.ArrayPoweredOnDependent.length
      vitalHash[:StandAlonePoweredOn] = self.ArrayPoweredOnStandAlone.length
    else
      vitalHash[:serverOnline] = false
      vitalHash[:NasPoweredOn] = false
      vitalHash[:StandAloneAutoStartPoweredOff] = 999
      vitalHash[:NasDependentAutoStartPoweredOff] = 999
      vitalHash[:NasDependentPoweredOn] = 0
      vitalHash[:StandAlonePoweredOn] = 0
    end

    return vitalHash
  end

  # Uses the vital hash to determine what is needed to do...  such as power off machines/server, power back up, etc.
  # @param [Hash] vitalHash
  # @return [String] of what the decision was.
  def VmMaintenanceDecisionTime(vitalHash)
    if vitalHash[:powerstate] == true and vitalHash[:batterylevel] >= vitalHash[:upsPowerOnAtPercent] \
        and vitalHash[:StandAloneAutoStartPoweredOff] == 0 and vitalHash[:NasDependentAutoStartPoweredOff] == 0
          response = 'All Systems Good' # Everything is fine.
      elsif vitalHash[:powerstate] == true and vitalHash[:batterylevel] >= vitalHash[:upsPowerOnAtPercent] \
        and vitalHash[:StandAloneAutoStartPoweredOff] == 0 and vitalHash[:NasDependentAutoStartPoweredOff] > 0
          response = 'Power On NASDependent AutoStart'
      elsif vitalHash[:powerstate] == true and vitalHash[:batterylevel] >= vitalHash[:upsPowerOnAtPercent] \
        and vitalHash[:StandAloneAutoStartPoweredOff] > 0
        response = 'Power On StandAlone AutoStart'
      elsif vitalHash[:powerstate] == false and vitalHash[:batterylevel] <= vitalHash[:upsPowerOffAtPercent] \
        and vitalHash[:StandAlonePoweredOn] == 0 and vitalHash[:NasDependentPoweredOn] == 0
        response = 'Shutdown Server'
      elsif vitalHash[:powerstate] == false and vitalHash[:batterylevel] <= vitalHash[:upsPowerOffAtPercent] \
        and vitalHash[:StandAlonePoweredOn] == 0 and vitalHash[:NasDependentPoweredOn] > 0
        response = 'Error - Confirm NAS Off'
      elsif vitalHash[:powerstate] == false and vitalHash[:batterylevel] <= vitalHash[:upsPowerOffAtPercent] \
        and vitalHash[:StandAlonePoweredOn] > 0 and vitalHash[:NasDependentPoweredOn] == 0
        response = 'Power Down StandAlones'
      elsif vitalHash[:powerstate] == false and vitalHash[:batterylevel] <= vitalHash[:upsPowerOffAtPercent] \
        and vitalHash[:StandAlonePoweredOn] > 0 and vitalHash[:NasDependentPoweredOn] > 0
        response = 'Power Down NASDependents'
      elsif vitalHash[:powerstate] == false and vitalHash[:batterylevel] > vitalHash[:upsPowerOffAtPercent] \
        and vitalHash[:StandAlonePoweredOn] == 0 and vitalHash[:NasDependentPoweredOn] > 0
        response = 'Error - Confirm NAS Off'
      elsif vitalHash[:powerstate] == false and vitalHash[:batterylevel] > vitalHash[:upsPowerOffAtPercent] \
        and vitalHash[:StandAlonePoweredOn] > 0 and vitalHash[:NasDependentPoweredOn] > 0
        response = 'Power Down NASDependents'
      else response = 'Do Nothing'
    end
    return response
  end



  # Implements the response from VmMaintenanceDecisionTime
  # @param [String] toDo
  # @return [String] returns the param toDo
  def MaintenanceAction(toDo)
    case toDo
      when 'Power Up Server'; TriggerNotification({:severity=>'info', :action=>'Power Up Server'}); self.WakeOnLan('F4:6D:04:E1:D8:A0'); self.WakeOnLan('F4:6D:04:E1:D9:C8')
      when 'Power On StandAlone AutoStart'; self.StartupAutostartStandAlone
      when 'Power On NASDependent AutoStart'; self.StartupAutostartNasDependent
      when 'All Systems Good'; TriggerNotification({:severity=>'info', :action=>'All Systems Good'})
      when 'Power Down NASDependents'; self.ShutdownNasDependent
      when 'Power Down StandAlones'; self.ShutdownStandAlone
      when 'Shutdown Server'; TriggerNotification({:severity=>'debug', :action=>'Shutdown Server'}); self.ServerShutdown
      when 'Error - Confirm NAS Off'; TriggerNotification({:severity=>'error', :action=>'Error - Confirm NAS Off'})
      when 'Do Nothing'; TriggerNotification({:severity=>'debug', :action=>'Do Nothing'})
    end
    return toDo
  end

  def Maintenance(args={:test=>false})
    TriggerNotification({:severity=>'info', :action=>'Starting Maintenace Method', :verbose=>true})
    self.UpdateVmList
    responseHash = self.BuildVitalHash

    if args.has_key?(:test) && args[:test]
      if args.has_key?(:powerstate)
        responseHash[:powerstate] = args[:powerstate]
      end
      if args.has_key?(:batterylevel)
        responseHash[:batterylevel] = args[:batterylevel]
      end
    end
    if args.has_key?(:vitalHashOnly) && args[:vitalHashOnly]
      return responseHash
    end

    responseHash[:ActionMessage] = VmMaintenanceDecisionTime(responseHash)
    MaintenanceAction(responseHash[:ActionMessage])
    responseHash
  end

  # Returns the last time the UPS was checked
  # @return [String] Timestamp
  def UpsGetLastCheckedTimestamp
    return @ups.GetLastCheckedTimestamp
  end

  # Returns the UPS Power Status
  # @return [Boolean]
  def UpsGetPowerStatus
    return @ups.GetPowerStatus
  end

  # Returns the UPS Battery Status
  # @return [Float] of the battery level
  def UpsGetBatteryStatus
    return @ups.GetBatteryStatus
  end

  # Runs the UpsMaintenance.
  def UpsMaintenance
    return @ups.UpsMaintenance
  end

  def TriggerNotificationTest(msg, testHash, setStates)
    @notify.SetStatesForTesting(setStates)

    responseHash = TriggerNotification(msg, testHash)
    responseHash

  end

  def TriggerNotification(msg, testHash={})
    verbose = msg.fetch(:verbose, false)
    responseHash = Hash.new
    vitalHash = Hash.new
    if testHash.empty?
      vitalHash = BuildVitalHash()
    else
      vitalHash = testHash
    end

    if verbose == false || (verbose==true && self.GetIniValue('verboseLogging')==true)
       responseHash = @notify.IncomingNotification(msg, vitalHash)
    end
    responseHash
  end

  def SetPushNotificationSetting(setValue)
    @notify.SetPushNotificationSetting(setValue)
  end

  def is_active?
    true
  end

  def PrintStates
    @notify.PrintStates
  end

  # Get list of machines that are powered on, Dependent and Auto Start
  #     by calling ReturnVmListByStatus with correct parameters.
  #     and filtering out Manual starting machines via FilterOutByAutostart.
  # @return [Array] of the Virtual Machines matching this criteria
  def ArrayPoweredOnDependentAutoStart
    vmList = ReturnVmListByStatus(true, false)
    return FilterOutByAutostart(vmList, true)
  end


  # Starts up Stand Alone Autostarting Virtual Machines.
  def StartupAutostartStandAlone
    if self.ArrayPoweredOffStandAloneAutostart.length > 0
      TriggerNotification({:severity=>'info', :action=>'Power On StandAlone AutoStart'})
      self.VmGroupPowerOn(self.ArrayPoweredOffStandAloneAutostart)
      sleep (30)
      self.UpdateVmList
    end
  end


  def TestDoesIniMatch?(args)
    iniTest = EsxiIni.new(args)

    iniTest = InitializeIniHash(args)
    if iniTest == @iniHash
      #puts "(T)new:  #{iniTest}"
      #puts "old:  #{@iniHash}"
      return true
    else
      #puts "(F)new:  #{iniTest}"
      #puts "old:  #{@iniHash}"
      return false
    end
  end
end

class VmwareUtil < Vmware
  def PrintVmList()
    puts @vmListHash
  end

  # Power on the requested VM.
  # @param [Int] vmId -- Target ID
  # @return [Boolean] True/False
  def VmPowerOn(vmId)
    commandToRun = "vim-cmd vmsvc/power.on #{vmId}"
    result=true
    output = self.RunSshCommand(commandToRun)
    if (output=~/Power on failed/)
      result = false
    end
    return result
  end

  # Shutdown all virtual machines starting with the NAS dependent ones.
  def ShutdownAll
    self.ShutdownNasDependent
    self.ShutdownStandAlone
    self.UpdateVmList
  end

  # Startup all Autostartup Virtual Machines, startin with stand alone machines, then NAS dependent.
  def StartupAutostarts
    self.StartupAutostartStandAlone
    self.StartupAutostartNasDependent
  end

  # Suspend the requested VM.
  # @param [Int] vmId -- Target ID
  # @return [Boolean] True/False
  def VmPowerSuspend(vmId)
    commandToRun = "vim-cmd vmsvc/power.suspend #{vmId}"
    result = true
    output = self.RunSshCommand(commandToRun)
    if (output=~/Suspend failed/)
      result = false
    end
    return result
  end


  # Shutdown the requested VM.
  # @param [Int] vmId -- Target ID
  # @return [Boolean] True/False
  def VmPowerShutdown(vmId)
    result = true
    commandToRun = "vim-cmd vmsvc/power.shutdown #{vmId}"
    output = self.RunSshCommand(commandToRun)
    if (output=~/The attempted operation cannot be performed in the current state/)
      result = false
    end
    return result
  end

  # Power Off (hard) the requested VM.
  # @param [Int] vmId -- Target ID
  # @return [Boolean] True/False
  def VmPowerOff(vmId)
    result = true
    commandToRun = "vim-cmd vmsvc/power.off #{vmId}"
    output = self.RunSshCommand(commandToRun)
    if (output=~/Power off failed/)
      result = false
    end
    return result
  end

  # Reboot the requested VM.
  # @param [Int] vmId -- Target ID
  # @return [Boolean] True/False
  def VmPowerReboot(vmId)
    result = true
    commandToRun = "vim-cmd vmsvc/power.reboot #{vmId}"
    output = self.RunSshCommand(commandToRun)
    if (output=~/The attempted operation cannot be performed in the current state/)
      result = false
    end
    return result
  end

  # Reset (hard) the requested VM.
  # @param [Int] vmId -- Target ID
  # @return [Boolean] True/False
  def VmPowerReset(vmId)
    result = true
    commandToRun = "vim-cmd vmsvc/power.reset #{vmId}"
    output = self.RunSshCommand(commandToRun)
    if (output=~/Reset failed/)
      result = false
    end
    return result
  end

  # Return count of the VM's by wheather they are powered on or off.
  # @param [Boolean] powerStatus True/False (Powered on or off)
  # @return [Integer] Count (0-x)
  def countVmsByPowerStatus(powerStatus)
    count = 0
    @vmListHash.each do |key, array|
      if array[:powerstate] == powerStatus
        count += 1
      end
    end
    return count
  end

  # Returns a name of the VM by the ID Number.
  # @param [Integer] vmId ID of the requested machine
  # @return [String] Name of the Virtual Machine, nil if not found.
  def GetNameById(vmId)
    returnName = nil
    @vmListHash.each do |vmname, vmhash|
      if vmhash[:id] == vmId
        returnName = vmname
      end
    end
    return returnName

  end


  # Is the Host active
  # @return [Boolean] True/False depending on if the esxi host is active.
  def isHostActive?()
    Ping.pingecho @host, 1, 80
  end

  # Return entire hash list of all the VMs.
  # @return [Hash] of all machines and their statuses
  def ReturnVmHashs
    return @vmListHash
  end





  # Get list of machines that are powered off, standalone and Manual Start
  #     by calling ReturnVmListByStatus with correct parameters.
  #     and filtering out Auto starting machines via FilterOutByAutostart.
  # @return [Array] of the Virtual Machines matching this criteria
  def ArrayPoweredOffStandAloneManualStart
    vmList = ReturnVmListByStatus(false, true)
    return FilterOutByAutostart(vmList, false)
  end

  # Get list of machines that are powered off and dependent
  #     by calling ReturnVmListByStatus with correct parameters.
  # @return [Array] of the Virtual Machines matching this criteria
  def ArrayPoweredOffDependent
    return ReturnVmListByStatus(false, false)
  end


  # Get list of machines that are powered off, dependent and Manual Start
  #     by calling ReturnVmListByStatus with correct parameters.
  #     and filtering out Auto starting machines via FilterOutByAutostart.
  # @return [Array] of the Virtual Machines matching this criteria
  def ArrayPoweredOffDependentManualStart
    vmList = ReturnVmListByStatus(false, false)
    return FilterOutByAutostart(vmList, false)
  end


end