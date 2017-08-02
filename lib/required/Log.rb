require 'logger'

# Write to a log file and return a hash of info about what was done (hash is mostly for testing)
class Log
  # @param [String] hdDir Main directory where the HD storage of log files are kept (for reboots etc)
  # @param [String] ramDiskDir is the main directory where the RAM Disk is located.  
  # @param [String] fileName of the log file... such as application.log.
  # @return [Nil] Nothing
  #{:hdDir => '/log', :ramDiskDir => '/ram', :fileName => 'application.log', :writeLogs => true}
  def initialize(args)
    @logHash = Hash.new
    @logHash = self.InitializeLogHashValues(args)
    self.SetLogFile
    self.InitializeRAMDisk
    self.InitializeLogFile
  end



  def InitializeLogHashValues(args)
    iniHash = Hash.new
    iniHash[:writeLogs] = args.fetch(:writeLogs, true)
    iniHash[:hdDir] = args.fetch(:hdDir, nil)
    iniHash[:fileName] = args.fetch(:fileName, 'esxiMonitor.log')
    iniHash[:ramDiskDir] = args.fetch(:ramDiskDir, nil)
    iniHash[:initialActionMsg] = args.fetch(:initialActionMsg, nil)
    iniHash
  end

  def SetLogFile(batteryGood=true)
    if @logHash[:ramDiskDir] != nil and batteryGood == true
      @logHash[:useRamDisk] = true
      @logHash[:logFolder] = File.join(@logHash[:ramDiskDir], 'log')
      @logHash[:logFile] = File.join(@logHash[:ramDiskDir], 'log', @logHash[:fileName])
      @logHash[:logFile]
    else
      @logHash[:useRamDisk] = false
      @logHash[:logFile] = File.join(@logHash[:hdDir], @logHash[:fileName])
    end
  end

  def InitializeRAMDisk
    if @logHash[:writeLogs]
      #RamDisk
      if @logHash[:useRamDisk] == true
        if !File.exist?(@logHash[:ramDiskDir])
          exit(2)
        else
          if !File.directory?(@logHash[:logFolder])
            Dir.mkdir @logHash[:logFolder]
            FileUtils.chmod 0777, @logHash[:logFolder]
          end
        end
      end
    end
  end

  def InitializeLogFile
    if @logHash[:useRamDisk]
      self.CopyToRamDisk
    end

    @LOG = Logger.new(@logHash[:logFile], 'daily', 2)
    @LOG.datetime_format = "%Y%m%d-%H:%M:%S"

    # Setup the formatter.
      @LOG.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.strftime('%Y%m%d %H:%M:%S')} %-7s- #{msg}\n" % [severity]
      end

    if @logHash[:initialActionMsg] != nil
      self.WriteToLog({:severity=>'info', :logMsg=>@logHash[:initialActionMsg]})
      @logHash[:initialActionMsg] = nil
    end

    if @logHash[:currentlyUsingRamDisk]
      self.WriteToLog({:severity=>'info', :logMsg=>'Writing to RAMDisk'})
    else
      self.WriteToLog({:severity=>'info', :logMsg=>'Writing to HD'})
    end

  end

  def CopyToRamDisk
    if File.exist?("#{@logHash[:hdDir]}/#{@logHash[:fileName]}")
      begin
        cmd = "cp #{@logHash[:hdDir]}/* #{@logHash[:ramDiskDir]}/log"
        cmdrsult = `#{cmd}`
        @logHash[:currentlyUsingRamDisk] = true
      rescue Exception => e
        @logHash[:currentlyUsingRamDisk] = false
      end
    else
      @logHash[:currentlyUsingRamDisk] = true
    end
  end

  def CopyToHd
    if @logHash[:currentlyUsingRamDisk]
      if File.exist?("#{@logHash[:hdDir]}/#{@logHash[:fileName]}")
        cmd = "rm #{@logHash[:hdDir]}/*; cp #{@logHash[:ramDiskDir]}/log/* #{@logHash[:hdDir]};rm #{@logHash[:ramDiskDir]}/log/*"
        `#{cmd}`
      else
        cmd = "cp #{@logHash[:ramDiskDir]}/log/* #{@logHash[:hdDir]};rm #{@logHash[:ramDiskDir]}/log/*"
        `#{cmd}`
      end

    end
    @logHash[:currentlyUsingRamDisk] = false
  end

  def CloseLog(args={:action=>nil})
    if @logHash[:currentlyUsingRamDisk] == true
      self.WriteToLog({:severity=>'info', :logMsg=>'Moving Log file: RAMDisk->HD'})
    end
    if args[:action] != nil
      self.WriteToLog({:severity=>'info', :logMsg=>args[:action]})
    end
    @LOG.close
    self.CopyToHd
  end

  def LowPower
   if @logHash[:currentlyUsingRamDisk]
      self.CloseLog
      self.SetLogFile(false)
      self.InitializeLogFile
   end
  end

  def NormalPower
    if @logHash.has_key?(:ramDiskDir)
      self.WriteToLog({:severity=>'info', :logMsg=>'Moving Log file: HD->RAMDisk'})
    end
    self.CloseLog
    self.SetLogFile(true)
    self.InitializeLogFile

  end

  def WriteToLog(logHash)
    logHash[:severity] = logHash.fetch(:severity, 'info')

    if @logHash[:writeLogs]
      case logHash[:severity].downcase
        when 'debug'
          begin
            logHash[:logged] = @LOG.debug(logHash[:logMsg])
          rescue => e
            logHash[:error] = e.backtrace
          end
        when 'info'
          begin
            logHash[:logged] = @LOG.info(logHash[:logMsg])
          rescue => e
            logHash[:error] = e.backtrace
          end
        when 'warn'
          begin
            logHash[:logged] = @LOG.warn(logHash[:logMsg])
          rescue => e
            logHash[:error] = e.backtrace
          end
        when 'error'
          begin
            logHash[:logged] = @LOG.error(logHash[:logMsg])
          rescue => e
            logHash[:error] = e.backtrace
          end
        when 'fatal'
          begin
            logHash[:logged] = @LOG.fatal(logHash[:logMsg])
          rescue => e
            logHash[:error] = e.backtrace
          end
        else
          logHash[:logged] = false
      end
    end
    return logHash
  end


end

