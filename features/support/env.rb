require 'rspec/expectations'

at_exit do
  if $esxi != nil
    $esxi.Destructor
  end
end

require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'required', 'EsxiIni')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'required', 'Vmware')

$esxiStartCode ||= 'NotStarted'
