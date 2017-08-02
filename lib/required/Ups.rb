# Monitor battery backup and voltage level using the apc software. 
# To Use, create object with file name, then call UpsMaintenance.  
#    Returns:  True if first time, or if power or battery level changed.
class Ups

  # @param [String] fileToOpen 
  # @return [Nil] Nothing
  # Just sets the file name class object variable.
  def initialize(fileToRead, fileToWrite, useApc)
    @fileToRead = fileToRead
    @fileToWrite = fileToWrite
    @lastHash = Hash.new
    @upsHash = Hash.new
    @useApc = useApc
    if @useApc
      self.WriteUpsStatusFile
    end
    self.GetUpsStatus
  end
  
  # Reads the file set in the constructor and returns a hash with following info:
  # @return [Hash] lineVoltage, batteryLevel, success, errorMessage
  def GetUpsStatus
    #upsHash = Hash.new
    @lashHash = @upsHash
    begin
      s = File.read(@fileToRead)
      # Get Line Voltage using regex and add to hash
      my_match = /(LINEV)(\s*)(.)(\s*)(\d*.\d*)/.match(s)
      if my_match[5].to_f > 0
        @upsHash[:lineVoltage] = true
      else
        @upsHash[:lineVoltage] = false
      end

      # Get battery level using regex and add to hash
      my_match = /(BCHARGE)(\s*)(.)(\s*)(\d*.\d*)/.match(s)
      @upsHash[:batteryLevel] = my_match[5].to_f

      # Get timestamp using regex and add to hash
      my_match = /(DATE\s*: )(\d*-\d*-\d* \d*:\d*:\d*)/.match(s)
      @upsHash[:timeStamp] = my_match[2]
      @upsHash[:success] = true
      @upsHash[:errorMessage] = ""

    rescue Exception => e
      @upsHash[:lineVoltage] = ""
      @upsHash[:batteryLevel] = ""
      @upsHash[:timeStamp] = ""
      @upsHash[:success] = false
      @upsHash[:errorMessage] = e.message
    end
    return @upsHash
  end

  # @return [Boolean] of whether there is power to UPC or not.
  def GetPowerStatus
    return @upsHash[:lineVoltage]
  end
  
  # @return [Float] of battery level on the UPC.
  def GetBatteryStatus
    return @upsHash[:batteryLevel]
  end

  # @return [Float] of battery level on the UPC.
  def GetLastCheckedTimestamp
    return @upsHash[:timeStamp]
  end
  
  # @return [Bool] Was it successful.
  def WriteUpsStatusFile
    wasSuccessful = false
    if @useApc
      begin
        if File.exist?(@fileToWrite)
          File.delete(@fileToWrite)
        end
        `apcaccess status > "#{@fileToWrite}"`
        wasSuccessful=$?.success?
      rescue Exception => e
        #@@LOG.error "error message goes here!: #{e}"
        wasSuccessful = false
      end
    end
    return wasSuccessful
  end
  
  # @return [Boolean] of did the battery/power change since last time.
  def DidUpsStatusChange(testHash = nil)
    returnResult = false

    returnedHash = self.GetUpsStatus
    if testHash != nil
      @lastHash = testHash
    end
    if @upsHash[:lineVoltage] != @lastHash[:lineVoltage]
      returnResult = true
    end
    if @upsHash[:batteryLevel] != @lastHash[:batteryLevel]
      returnResult = true
    end
    return returnResult
  end
  
  # @return [Boolean] Did the UpsBatterOrVoltageChange since last time.
  def UpsMaintenance
    self.WriteUpsStatusFile
    self.GetUpsStatus
    return self.DidUpsStatusChange
  end

  # @return [Hash] with power and and battery level.
  def UpsMaintenceReturnHash
    self.WriteUpsStatusFile
    return self.GetUpsStatus
  end
  
  # Used only for cucumber tests, should not be called in production.
  def TestStatusChanged(lastHash)
    return self.DidUpsStatusChange(lastHash)
  end
  
end
