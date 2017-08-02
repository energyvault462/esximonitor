require "./required/Vmware.rb"
require "./required/Ups.rb"
require "./required/EsxiIni.rb"

require 'colored'

# Class for running the Vmware as a console utility.
class EsxiUtil

  # Constructor -- Creates required objects.
  # @return [Nil] Nothing returned
  def initialize
    @esxi = VmwareUtil.new('./esxi.ini', {})
    #puts @esxi.ArrayPoweredOnStandAlone
  end

  # Destructor -- called manually, destroys the objects.
  def destruct
    @esxi = nil
  end

  # Prints the main menu to the console.
  def printMainMenu()
    puts "-".cyan * 25
    puts "#{'-'.cyan}    #{'MAIN MENU v0.01'.yellow}    #{'-'.cyan}"
    puts "-".cyan * 25

    if @esxi.isHostActive?; puts "#{'-'.cyan}  #{'Server Online:'.ljust(14, ' ').cyan} #{'Yes'.ljust(5, ' ').green} #{'-'.cyan} "
    else;    puts "#{'-'.cyan}  #{'Server Online:'.ljust(14, ' ').cyan} #{'No'.ljust(5, ' ').red} #{'-'.cyan} "; end

    if @esxi.isNasActive?; puts "#{'-'.cyan}  #{'NAS Online:'.ljust(14, ' ').cyan} #{'Yes'.ljust(5, ' ').green} #{'-'.cyan} "
    else;    puts "#{'-'.cyan}  #{'NAS Online:'.ljust(14, ' ').cyan} #{'No'.ljust(5, ' ').red} #{'-'.cyan} "; end

    puts "#{'-'.cyan}  #{'VMs Online:'.ljust(14, ' ').cyan} #{@esxi.countVmsByPowerStatus(true).to_s.ljust(5, ' ').green} #{'-'.cyan} "
    puts "#{'-'.cyan}  #{'VMs Offline:'.ljust(14, ' ').cyan} #{@esxi.countVmsByPowerStatus(false).to_s.ljust(5, ' ').yellow} #{'-'.cyan} "
    if @esxi.ArrayPoweredOffStandAloneAutostart.length == 0
      puts "#{'-'.cyan}  #{'A/S S/A:'.ljust(14, ' ').cyan} #{@esxi.ArrayPoweredOnStandAloneAutostart.length.to_s.ljust(5, ' ').green} #{'-'.cyan} "
    else
      puts "#{'-'.cyan}  #{'A/S S/A:'.ljust(14, ' ').cyan} #{@esxi.ArrayPoweredOnStandAloneAutostart.length.to_s.ljust(2, ' ').green} #{@esxi.ArrayPoweredOffStandAloneAutostart.length.to_s.ljust(2, ' ').red} #{'-'.cyan} "
    end
    #here!!!
    if @esxi.ArrayPoweredOffDependentAutostart.length == 0
      puts "#{'-'.cyan}  #{'A/S !S/A:'.ljust(14, ' ').cyan} #{@esxi.ArrayPoweredOnDependentAutoStart.length.to_s.ljust(5, ' ').green} #{'-'.cyan} "
    else
      puts "#{'-'.cyan}  #{'A/S !S/A:'.ljust(14, ' ').cyan} #{@esxi.ArrayPoweredOnDependentAutoStart.length.to_s.ljust(2, ' ').green} #{@esxi.ArrayPoweredOffDependentAutostart.length.to_s.ljust(2, ' ').red} #{'-'.cyan} "
    end
    puts "-".cyan * 25

    puts "#{'-'.cyan}  #{@esxi.UpsGetLastCheckedTimestamp.to_s.ljust(20, ' ').green} #{'-'.cyan} "

    if @esxi.UpsGetPowerStatus; puts "#{'-'.cyan}  #{'Power:'.ljust(14, ' ').cyan} #{'On'.ljust(5, ' ').green} #{'-'.cyan} "
    else;    puts "#{'-'.cyan}  #{'Power:'.ljust(14, ' ').cyan} #{'Off'.ljust(5, ' ').red} #{'-'.cyan} "; end

    if @esxi.UpsGetBatteryStatus >= @esxi.GetIniValue('upsPowerOnAtPercent').to_f; puts "#{'-'.cyan}  #{'Battery:'.ljust(14, ' ').cyan} #{@esxi.UpsGetBatteryStatus.to_s.ljust(5, ' ').green} #{'-'.cyan} "
    else;    puts "#{'-'.cyan}  #{'Battery:'.ljust(14, ' ').cyan} #{@esxi.UpsGetBatteryStatus.to_s.ljust(5, ' ').red} #{'-'.cyan} "; end

    puts "-".cyan * 25
  end

  # Prints VM's to the console.
  # @param [String] title - String to print as the title.
  # @param [Array] vmsToPrint -- The list of Virtual Machines to print
  # @param [String] printColor is "green" or "red"
  # @return [Nil]
  def PrintVms(title, vmsToPrint, printColor)
    totalWidth = 25
    wordWidth = totalWidth - 6
    # Array to comma delimited string.
    str = vmsToPrint.map(&:inspect).join(', ')
    #delete the double quotes.
    str.delete! '\""'
    #split into new array based on length
    wordWrapped = str.scan(/\S.{0,#{wordWidth-1}}\S(?=\s|$)|\S+/)

    #Print the array in color nicely formatted
    puts '-'.cyan * totalWidth
    puts "#{'-'.cyan}  #{title.ljust(20, ' ').yellow} #{'-'.cyan}"
    wordWrapped.each do |line|
      if line.length > 0
        if printColor == 'green'; puts "#{'-'.cyan}  #{line.ljust(wordWidth+1, ' ').green} #{'-'.cyan}"; end
        if printColor == 'red'; puts "#{'-'.cyan}  #{line.ljust(wordWidth+1, ' ').red} #{'-'.cyan}"; end
      else
        if printColor == 'green'; puts "#{'-'.cyan}  #{'No Matches'.ljust(wordWidth+1, ' ').green} #{'-'.cyan}"; end
        if printColor == 'red'; puts "#{'-'.cyan}  #{'No Matches'.ljust(wordWidth+1, ' ').red} #{'-'.cyan}"; end
      end
    end
    puts '-'.cyan * totalWidth
  end

  # Centers the value (T or F) and prints in green when T and red when F
  # @param [String] value -- "T" or "F"
  # @param [Integer] centerBy is how many chacters to center.
  def printTFColored(value, centerBy)
    if value
      "T".center(centerBy, ' ').green
    else
      "F".center(centerBy, ' ').red
    end
  end

  # Prints the Virtual Machines names and details to the console.
  # @return [Nil] Nothing is returned
  def printVmDetails()
    vmListHash = @esxi.ReturnVmHashs()
    puts "-".cyan * 67
    puts "#{'-'.cyan} #{'ALL VIRTUAL MACHINES'.center(63,' ').cyan} #{'-'.cyan} "
    puts "-".cyan * 67
    puts "#{'-'.cyan} #{'ID'.ljust(2, ' ').cyan} #{'VM Name'.ljust(12, ' ').cyan} #{'Auto'.ljust(4, ' ').cyan} #{'Standalone'.ljust(10, ' ').cyan} #{'CanSuspend'.ljust(10, ' ').cyan} #{'Tools'.ljust(5, ' ').cyan} #{'IP Address'.ljust(14, ' ').cyan} #{'-'.cyan} "
    vmListHash.each do |key, array|
      if array[:ipaddress] == nil
        ipaddress = "NA"
      else
        ipaddress = array[:ipaddress]
      end
      if array[:powerstate] == true
        puts "#{'-'.cyan} #{array[:id].to_s.ljust(2, ' ').green} #{array[:vmname].ljust(12, ' ').green} " + printTFColored(array[:autostart], 4) + " " + printTFColored(array[:standalone], 10) + " " + printTFColored(!array[:nosuspend], 10) + " " + printTFColored(array[:havetools], 5) + " #{ipaddress.ljust(14, ' ').green} #{'-'.cyan}"
      else
        puts "#{'-'.cyan} #{array[:id].to_s.ljust(2, ' ').red} #{array[:vmname].ljust(12, ' ').red} " + printTFColored(array[:autostart], 4) + " " + printTFColored(array[:standalone], 10) + " " + printTFColored(!array[:nosuspend], 10) + " " + printTFColored(array[:havetools], 5) + " #{ipaddress.ljust(14, ' ').red} #{'-'.cyan}"
      end
    end
    puts "-".cyan * 67
  end

  # Start of the program.  This is the main menu.
  # @return [Nil] Nothing is returned.
  def mainMenu()
    menuSelection = "a"

    while menuSelection.downcase != "q"
      printMainMenu
      time = Time.new
      if File.exist?(@esxi.GetIniValue('stopMaintFileName'))
        puts "#{"(".cyan}#{"M".yellow}#{")aintance Resume".cyan}"
      else
        puts "#{"(".cyan}#{"M".yellow}#{")aintenance Halt".cyan}"
      end
      puts "#{"(".cyan}#{"P".yellow}#{")ower Computer Menu".cyan}"
      puts "#{"(".cyan}#{"U".yellow}#{")PS Refresh".cyan}"
      puts "#{"(".cyan}#{"V".yellow}#{")irtual Machines".cyan}"
      puts "#{"(".cyan}#{"Q".red}#{")uit".cyan}"
      print "#{"Please enter selection (".cyan}#{time.strftime("%H:%M:%S").green}#{"): ".cyan}"
      menuSelection = $stdin.gets.chomp
      case menuSelection.downcase
        when "m"; self.MaintenanceToggle
        when "p"; self.PowerOnComputersMenu
        when "u"; @esxi.UpsMaintenance;
        when "v"; virtualMachinesMenu
      end
    end
  end

  # Virtual Machines Menu.
  # @return [Nil] Nothing is returned
  def virtualMachinesMenu()
    menuSelection = "a"

    while menuSelection.downcase != "q"
      printVmDetails
      puts "#{"   View".ljust(4, ' ').yellow} #{"Pwr".center(3, ' ').cyan} #{"S/A".center(3, ' ').cyan} #{"A/S".center(3, ' ').cyan} #{"View".ljust(4, ' ').yellow} #{"Pwr".center(3, ' ').cyan} #{"S/A".center(3, ' ').cyan} #{"A/S".center(3, ' ').cyan}"
      puts "#{"    (".cyan}#{"A".yellow}#{")".cyan} #{"T".center(3, ' ').green} #{"T".center(3, ' ').green} #{"-".center(3, ' ').cyan} #{" (".cyan}#{"G".yellow}#{")".cyan} #{"F".center(3, ' ').red} #{"T".center(3, ' ').green} #{"-".center(3, ' ').cyan}"
      puts "#{"    (".cyan}#{"B".yellow}#{")".cyan} #{"T".center(3, ' ').green} #{"T".center(3, ' ').green} #{"T".center(3, ' ').green} #{" (".cyan}#{"H".yellow}#{")".cyan} #{"F".center(3, ' ').red} #{"T".center(3, ' ').green} #{"T".center(3, ' ').green}"
      puts "#{"    (".cyan}#{"C".yellow}#{")".cyan} #{"T".center(3, ' ').green} #{"T".center(3, ' ').green} #{"F".center(3, ' ').red} #{" (".cyan}#{"I".yellow}#{")".cyan} #{"F".center(3, ' ').red} #{"T".center(3, ' ').green} #{"F".center(3, ' ').red}"
      puts "#{"    (".cyan}#{"D".yellow}#{")".cyan} #{"T".center(3, ' ').green} #{"F".center(3, ' ').red} #{"-".center(3, ' ').cyan} #{" (".cyan}#{"J".yellow}#{")".cyan} #{"F".center(3, ' ').red} #{"F".center(3, ' ').red} #{"-".center(3, ' ').cyan}"
      puts "#{"    (".cyan}#{"E".yellow}#{")".cyan} #{"T".center(3, ' ').green} #{"F".center(3, ' ').green} #{"T".center(3, ' ').green} #{" (".cyan}#{"K".yellow}#{")".cyan} #{"F".center(3, ' ').red} #{"F".center(3, ' ').red} #{"T".center(3, ' ').green}"
      puts "#{"    (".cyan}#{"F".yellow}#{")".cyan} #{"T".center(3, ' ').green} #{"F".center(3, ' ').red} #{"F".center(3, ' ').red} #{" (".cyan}#{"L".yellow}#{")".cyan} #{"F".center(3, ' ').red} #{"F".center(3, ' ').red} #{"F".center(3, ' ').red}"
      puts "#{"(".cyan}#{"U".yellow}#{")pdate List".cyan}"
      puts "#{"(".cyan}#{"P1".yellow}#{") Power On All A/S".cyan}"
      puts "#{"(".cyan}#{"P2".yellow}#{") Power Down All".cyan}"
      print "#{"Enter".cyan} #{"ID".yellow} #{"number or (".cyan}#{"Q".yellow}#{")uit: ".cyan}"
      menuSelection = $stdin.gets.chomp
      case menuSelection
        #PrintVms(subject, vmsToPrint, printColor)
        when "a"; PrintVms('On, S/A', @esxi.ArrayPoweredOnStandAlone.sort, 'green')
        when "b"; PrintVms('On, S/A, A/S', @esxi.ArrayPoweredOnStandAloneAutostart.sort, 'green')
        when "c"; PrintVms('On, S/A, !A/S', @esxi.ArrayPoweredOnStandAloneManualStart.sort, 'green')
        when "d"; PrintVms('On, !S/A', @esxi.ArrayPoweredOnDependent.sort, 'green')
        when "e"; PrintVms('On, !S/A, A/S', @esxi.ArrayPoweredOnDependentAutoStart.sort, 'green')
        when "f"; PrintVms('On, !S/A, !A/S', @esxi.ArrayPoweredOnDependentManualStart.sort, 'green')
        when "g"; PrintVms('Off, S/A', @esxi.ArrayPoweredOffStandAlone.sort, 'red')
        when "h"; PrintVms('Off, S/A, A/S', @esxi.ArrayPoweredOffStandAloneAutostart.sort, 'red')
        when "i"; PrintVms('Off, S/A, !A/S', @esxi.ArrayPoweredOffStandAloneManualStart.sort, 'red')
        when "j"; PrintVms('Off, !S/A', @esxi.ArrayPoweredOffDependent.sort, 'red')
        when "k"; PrintVms('Off, !S/A, A/S', @esxi.ArrayPoweredOffDependentAutostart.sort, 'red')
        when "l"; PrintVms('Off, !S/A, !A/S', @esxi.ArrayPoweredOffDependentManualStart.sort, 'red')
        when "u"; puts "Updating List.  Please wait...".green; @esxi.UpdateVmList; #printVmDetails
        when "p1"; puts "Powering up all Autostart...".green; @esxi.StartupAutostarts;# printVmDetails
        when "p2"; puts "Powering down all virtual Machines...".green; @esxi.ShutdownAll;# printVmDetails
        when "v"; printVmDetails
        else if menuSelection.to_i > 0; SingleVmMenu(menuSelection.to_i); end;
      end
    end
  end

  # Power On Computers Menu.
  # @return [Nil] Nothing is returned
  def PowerOnComputersMenu()
    menuSelection = "a"
    while menuSelection.downcase != "q"
      puts "#{'-'.cyan}  #{'POWER ON COMPUTERS'.ljust(20, ' ').yellow} #{'-'.cyan}"
      puts "#{"(".cyan}#{"G".yellow}#{")ame System Power On".cyan}"
      puts "#{"(".cyan}#{"V".yellow}#{")MWare Power On".cyan}"
      puts "#{"(".cyan}#{"B".yellow}#{")edroom XBMC Power On".cyan}"
      puts "#{"(".cyan}#{"L".yellow}#{")ivingRoom XBMC Power On".cyan}"
      print "#{"Enter Letter to Turn on, or ".cyan}#{"Q".yellow}#{")uit: ".cyan}"
      menuSelection = $stdin.gets.chomp
      case menuSelection
        when "g"; @esxi.WakeOnLan('1C:6F:65:A9:8F:FA')
        when "b"; @esxi.WakeOnLan('bc:5f:f4:47:cf:a6')
        when "l"; @esxi.WakeOnLan('bc:5f:f4:4a:3f:bc')
        when "v"; @esxi.WakeOnLan('f4:6d:04:e1:d8:a0');@esxi.WakeOnLan('f4:6d:04:e1:d9:c8')
      end

    end
  end

  # Print Confirmation text and ask for Yes or No to confirm.
  # @param [String] text of the prompt
  # @param [String] color of the prompt, defaults to green
  # @return [Boolean]
  def Confirm(text, printColor = 'green')
    menuSelection = "a"

    while menuSelection.downcase != "q"
      case printColor.downcase
        when "green"; print "#{text.green}  "
        when "yellow"; print "#{text.yellow}  "
        when "red"; print "#{text.red.bold}  "
        when "magenta"; print "#{text.magenta}  "
      end

      print "#{"Enter".cyan} #{"Yes".yellow} #{"or".cyan} #{"No".yellow} #{"then press enter: ".cyan}"
      menuSelection = $stdin.gets.chomp
      case menuSelection
        when "yes"; return true
        when "no"; return false
      end
    end
  end

  # Menu for when a single Virtual Machine is specified by ID number.
  # @param [String] vmId of the Virtual Machine selected within the virtualMachinesMenu()
  # @return [Nil] Nothing is returned.
  def SingleVmMenu(vmId)
    menuSelection = "a"

    while menuSelection.downcase != "q"

      vmname = @esxi.GetNameById(vmId)
      vmhash = @esxi.GetVmInfo(vmname)
      PrintSingleVmMenu(vmname)
      if vmhash[:powerstate]
          print "#{"(".cyan}#{"S".yellow}#{")Suspend, (".cyan}#{"H".yellow}#{")Shutdown, (".cyan}"
          print "#{"R".yellow}#{")Reboot".cyan}\n"
          puts "-".cyan * 25
          puts "#{"(".cyan}#{"P".yellow}#{")Power Off, (".cyan}#{"E".yellow}#{")Reset".cyan}"
          print "#{"Enter selection, (".cyan}#{"U".yellow}#{")pdate or (".cyan}#{"Q".yellow}#{")uit: ".cyan}"
          menuSelection = $stdin.gets.chomp
          case menuSelection
            when "s";
                if self.Confirm("Suspend?", 'magenta')
                  @esxi.VmPowerSuspend(vmId)
                  @esxi.UpdateVmInfo(vmname, vmId)
                  menuSelection = 'q'
                end
            when "h";
              if self.Confirm("Shutdown?", 'magenta')
                @esxi.VmPowerShutdown(vmId)
                @esxi.UpdateVmInfo(vmname, vmId)
                menuSelection = 'q'
              end
            when "r";
              if self.Confirm("Reboot?", 'magenta')
                @esxi.VmPowerReboot(vmId)
                @esxi.UpdateVmInfo(vmname, vmId)
                menuSelection = 'q'
              end
            when "p";
              if self.Confirm("Power Off?", 'red')
                @esxi.VmPowerOff(vmId)
                @esxi.UpdateVmInfo(vmname, vmId)
                menuSelection = 'q'
              end
            when "e";
              if self.Confirm("Reset?", 'red')
                @esxi.VmPowerReset(vmId)
                @esxi.UpdateVmInfo(vmname, vmId)
                menuSelection = 'q'
              end
            when "u"; @esxi.UpdateVmInfo(vmname, vmId)
          end
        else
          puts "#{"(".cyan}#{"O".yellow}#{")n".cyan}"
          print "#{"Enter selection, (".cyan}#{"U".yellow}#{")pdate or (".cyan}#{"Q".yellow}#{")uit: ".cyan}"
          menuSelection = $stdin.gets.chomp
          case menuSelection
            when "o";
              if self.Confirm("Power On?")
                @esxi.VmPowerOn(vmId)
                @esxi.UpdateVmInfo(vmname, vmId)
                menuSelection = 'q'
              end
            when "u"; @esxi.UpdateVmInfo(vmname, vmId)
          end
        end


    end
  end

  # Prints the Single Virtual Machine Menu.
  # @param [String] vmId of the Virtual Machine being printed.
  # @return [Nil] Nothing is returned.
  def PrintSingleVmMenu(vmname)

    puts "-".cyan * 45
    puts "#{'-'.cyan}#{vmname.center(43, ' ').cyan}#{'-'.cyan}"
    puts "-".cyan * 45

  end

  # Deletes/Creates the Maintenance stoppage file.
  # @return [Nil] Nothing is returned
  def MaintenanceToggle
    if File.exist?(@esxi.GetIniValue('stopMaintFileName'))
      File.delete(@esxi.GetIniValue('stopMaintFileName'))
    else
      maintFile = File.open(@esxi.GetIniValue('stopMaintFileName'), 'w')
      maintFile.puts('Stop Maintenance')
      maintFile.close
    end
  end

end

