require 'time'
require "net/https"

begin
  require "./required/Log.rb"
rescue Exception => e
  require "./lib/required/Log.rb"
end


# Write to a log file and return a hash of info about what was done (hash is mostly for testing)
class Notification
  # @param [Hash]
  # Required in Hash:
  #   :writeLogs -- bool required -- if true the follow section applies
  #     :hdDir -- required for writeLogs. physical drive location (HD) of where the log files are stored
  #     :fileName -- required for writeLogs.   File name of the current log (ie: application.log)
  #     :ramDiskDir -- Optional for writeLogs.  Use if wanting to write logs to ram disk
  #   :sendNotifications -- bool required -- Send push notifications?
  #     All these are required if sending pushover notifications
  #     :pushoverUserToken -- gmail account sending from
  #     :pushoverAppToken -- gmail password of account sending from
  #     :emailTarget -- email address of where the email is being sent.
  # @return [Nil] Nothing
  #{:hdDir => '/log', :ramDiskDir => '/ram', :fileName => 'application.log', :writeLogs => true}
  #def initialize()
  def initialize(args)
    @lastNotifiedVitalHash = Hash.new
    @pushCount = 0
    @queue = Queue.new


    @settingsHash = self.InitializeArgs(args)

    if @settingsHash[:writeLogs]
      @log = Log.new({:hdDir => @settingsHash[:hdDir], :ramDiskDir => @settingsHash[:ramDiskDir], :fileName => @settingsHash[:fileName], :writeLogs => @settingsHash[:writeLogs], :initialActionMsg => @settingsHash[:initialActionMsg]})
    end

    self.InitializeState
  end

  def InitializeArgs(args)
    iniHash = Hash.new

    iniHash[:writeLogs] = args.fetch(:writeLogs, true)
    iniHash[:notifyByPush] = args.fetch(:notifyByPush, false)

    iniHash[:hdDir] = args.fetch(:hdDir, nil)
    iniHash[:fileName] = args.fetch(:fileName, nil)
    iniHash[:ramDiskDir] = args.fetch(:ramDiskDir, nil)
    iniHash[:pushoverUserToken] = args.fetch(:pushoverUserToken, nil)
    iniHash[:pushoverAppToken] = args.fetch(:pushoverAppToken, nil)
    iniHash[:secondsBetweenLoggingAllSystemsGood] = args.fetch(:secondsBetweenLoggingAllSystemsGood, nil)
    iniHash[:initialActionMsg] = args.fetch(:initialActionMsg, nil)

    iniHash
  end

  def SetPushNotificationSetting(pushValue)
    @settingsHash[:notifyByPush] = pushValue
  end

  def InitializeState
    @state = {
        :power => {:state=>nil},
        :allSystemsGood => {:state=>nil, :pushed=>nil, :TimeLastLogged=>nil},
        :batteryLevelGood => {:state=>nil}
    }
  end

  def IncomingNotification(msg, vitalHash={})
      resultHash = Hash.new
      resultHash = {:toLog=>false, :triggerPush=>false, :logged=>false, :pushed=>false}

      if msg[:msg].nil? || msg[:msg].empty?
        logMsg = msg[:action]
      else
        logMsg = "#{msg[:action]}: #{msg[:msg]}"
      end

      if msg[:action] != 'software closes'
        TriggerNotificationCheck('batteryLevel', vitalHash)
      end
     #
    case msg[:action].downcase
        when "power failure", "power restored"

          triggerResults = TriggerNotificationCheck('power', vitalHash)
          if  triggerResults[:log]== true
            resultHash[:toLog] = true
          end
          if  triggerResults[:push]== true
            resultHash[:triggerPush] = true
          end
        when "power up server"
          resultHash[:toLog] = true
          resultHash[:triggerPush] = true
        when "power on standalone autostart"
          resultHash[:toLog] = true
        when "power on nasdependent autostart"
          resultHash[:toLog] = true
        when "all systems good"

          triggerResults = TriggerNotificationCheck('all systems good', vitalHash)
          if  triggerResults[:log]== true
            resultHash[:toLog] = true
          end
          if  triggerResults[:push]== true
            resultHash[:triggerPush] = true
          end
        when "power down nasdependents"
          resultHash[:toLog] = true
        when "power down standalones"
          resultHash[:toLog] = true
          resultHash[:triggerPush] = true
        when "shutdown server"
          resultHash[:toLog] = true
          resultHash[:triggerPush] = true
        when "error - confirm nas off"
          resultHash[:toLog] = true
          resultHash[:triggerPush] = true
        when "do nothing"
          # TODO: need to replace this with a check if it writes to log, definitely doesn't send email
          resultHash[:toLog] = true
        when "software starts"
          resultHash[:toLog] = true
          resultHash[:triggerPush] = true
      when "software closes"
          resultHash[:toLog] = false
          resultHash[:triggerPush] = true
        when "vm power up"
          resultHash[:toLog] = true
        when "vm power down"
          resultHash[:toLog] = true
        else
          if msg[:action]
            resultHash[:toLog] = true
            resultHash[:triggerPush] = true
          else
            resultHash[:toLog] = false
            resultHash[:triggerPush] = false
          end
      end

      if resultHash[:toLog] == true
        logResult = @log.WriteToLog({:severity=>msg[:severity], :logMsg=>logMsg})
        resultHash[:logged] = logResult[:logged]
      else
        resultHash[:logged] = false
      end

      if resultHash[:triggerPush] == true
        @queue << logMsg
        SendPush(vitalHash)
        #resultHash[:pushed] = true
      end
      resultHash
  end

  def TriggerNotificationCheck(mode, vitalHash)
    case mode
      when 'batteryLevel'
        if @state[:power][:batteryLevelGood] !=  vitalHash[:batterygood]
          if vitalHash[:batterygood] == true
            self.LogNormalPower
          else
            self.LogLowPower
          end
          @state[:power][:batteryLevelGood] =  vitalHash[:batterygood]
        end
      when 'power'
         if @state[:power][:state] != vitalHash[:powerstate]
           returnValue = {:log=>true, :push=>true}
           @state[:power][:state] = vitalHash[:powerstate]
         else
           returnValue = {:log=>false, :push=>false}
         end
        if vitalHash[:powerstate] == false
          @state[:allSystemsGood][:state] = false
        end
      when 'all systems good'
        returnValue = {:log=>false, :push=>false}
        if @state[:allSystemsGood][:state] != true
          returnValue = {:log=>true, :push=>true}
          @state[:allSystemsGood][:state] = true
          @state[:allSystemsGood][:TimeLastLogged] = Time.now
          @state[:allSystemsGood][:pushed] = true
        else
          if @state[:allSystemsGood][:pushed] == true
            if (Time.now - @state[:allSystemsGood][:TimeLastLogged]) >= @settingsHash[:secondsBetweenLoggingAllSystemsGood]
              returnValue[:log] = true
              @state[:allSystemsGood][:TimeLastLogged] = Time.now
            else
              returnValue[:log] = false
            end
          else
            returnValue[:push] = true
            @state[:allSystemsGood][:pushed] = true
          end
        end
    end
    returnValue
  end

  def SendPush(vitalHash)
    queueCount = 0
    until @queue.empty?
      queueCount = queueCount + 1
      pushMessage = "#{@queue.pop(true) rescue nil}\n"
    end


    pushSucess = true
    resResponse = nil

    if @settingsHash[:notifyByPush] == true
      begin
        url = URI.parse("https://api.pushover.net/1/messages.json")
        req = Net::HTTP::Post.new(url.path)
        req.set_form_data({
                              :token => @settingsHash[:pushoverAppToken],
                              :user => @settingsHash[:pushoverUserToken],
                              :message => pushMessage,
                          })
        res = Net::HTTP.new(url.host, url.port)
        res.use_ssl = true
        res.verify_mode = OpenSSL::SSL::VERIFY_PEER
        resResponse = res.start {|http| http.request(req) }
        @pushCount = @pushCount + 1
      rescue Exception => e
        puts "Exception:  #{e}"
        pushSucess = false
      end
    end




    pushSucess
  end


  def CloseLog(args={:closeMessage=>nil})
    if @settingsHash[:writeLogs]
      if args[:closeMessage] != nil
        self.IncomingNotification({:action=>args[:closeMessage]})
        @log.CloseLog({:action=>args[:closeMessage]})
      else
        @log.CloseLog
      end
      @log.CloseLog
    end
  end

  def LogLowPower
    if @settingsHash[:writeLogs]
      @log.LowPower
    end
  end

  def LogNormalPower
    if @settingsHash[:writeLogs]
      @log.NormalPower
    end
  end

  def SetStatesForTesting(statesFromTestingSteps)
    @state = statesFromTestingSteps
  end

  def PrintStates
    @state
  end

end


