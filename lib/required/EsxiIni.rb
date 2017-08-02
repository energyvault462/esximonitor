require 'inifile'

# Read the ini file and return value of the key asked.
# Known limitation:  only supports 1 section at this time.
class BsjIni
  # TODO: pull inifile out into it's own directory, and create the appropriate tests.
  # TODO: fix cucumber test for createIniFile so it actually creates it and checks to make sure it's right.

  def initialize(args)
    if !args.key?(:iniFileName)
      begin
        raise 'iniFileName is required'
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        exit (1)
      end
    end
    if !args.key?(:iniSectionName)
      begin
        raise 'iniSectionName is required'
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        exit (1)
      end
    else
      @sectionName = args[:iniSectionName]
    end
    if File.exist?(args[:iniFileName])
      @ini = IniFile.load(args[:iniFileName])
    else
      self.CreateInifile(args)
    end

  end

  def PostInitialize
    nil
  end

  def CreateInifile(args)

    iniDefaultSettings = CreateIniSettingsDefaults(args)
    @ini = IniFile.new(:filename => args[:iniFileName])
    iniDefaultSettings.each do |hashKey, hashValue|
      @ini[@sectionName][hashKey] = hashValue
      @ini.save
    end
  end

  def CreateIniSettingsDefaults(args)
    args
  end

  # Gets the value by keyname from the INI.
  # @param [String] keyname key name of what's being asked.
  # @return [String] value of the key asked for, or Nil if not found.
  def GetValue(keyname)
    #Strip spaces around a comma
    if @ini[@sectionName][keyname].is_a? String
      s = @ini[@sectionName][keyname]
      s.gsub!(/ +?,/, ',')
      s.gsub!(/, +?/, ',')
      return s
    else
      return @ini[@sectionName][keyname]
    end
  end

  def SetValue(keyname, value)
     @ini[@sectionName][keyname] = value
     @ini.save
  end


end

class EsxiIni < BsjIni
  def CreateIniSettingsDefaults(args)
    iniHash = Hash.new
    iniHash[:serverIp] = args.fetch(:serverIp, '0.0.0.0')
    iniHash[:serverName] = args.fetch(:serverName, 'ESXi_Server_User_Name')
    iniHash[:notifyByPush] = args.fetch(:notifyByPush, false)
    iniHash[:pushoverUserToken] = args.fetch(:pushoverUserToken, nil)
    iniHash[:pushoverAppToken] = args.fetch(:pushoverAppToken, nil)
    iniHash[:allowHostShutdown] = args.fetch(:testMachines, false)
    iniHash[:testMachines] = args.fetch(:testMachines, 'values,coma,separated')
    iniHash[:standAlone] = args.fetch(:standAlone, 'values,coma,separated')
    iniHash[:nasVmName] = args.fetch(:nasVmName, 'value')
    iniHash[:noSuspend] = args.fetch(:noSuspend, 'values,coma, separated')
    iniHash[:autoStart] = args.fetch(:autoStart, 'values,coma ,separated')
    iniHash[:useApcaccess] = args.fetch(:useApcaccess, false)
    iniHash[:upsPowerOnAtPercent] = args.fetch(:upsPowerOnAtPercent, '70.0')
    iniHash[:upsPowerOffAtPercent] = args.fetch(:upsPowerOffAtPercent, '80.0')
    iniHash[:UpsOutputName] = args.fetch(:UpsOutputName, 'fullPathAndFileName')
    iniHash[:UpsInputName] = args.fetch(:UpsInputName, 'fullPathAndFileName')
    iniHash[:writeLogs] = args.fetch(:writeLogs, true)
    iniHash[:hdDir] = args.fetch(:hdDir, 'FullPath')
    iniHash[:ramDiskDir] = args.fetch(:ramDiskDir, 'FullPath')
    iniHash[:fileName] = args.fetch(:fileName, 'esxiMonitor.log')
    iniHash[:stopMaintFileName] = args.fetch(:stopMaintFileName, 'FullPathAndFileName')
    iniHash[:secondsBetweenLoggingAllSystemsGood] = args.fetch(:secondsBetweenLoggingAllSystemsGood, '3600')
    iniHash
  end
end