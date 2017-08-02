def symbolize_table(table)
  hash_table = table.hashes
  hash_table.inject([]) do |row, (hash)|
    row << hash.inject({}) do |element, (key, value)|
      element[key.to_sym] = value
      element
    end
  end
end

def EvalForTrueFalseNil(truefalsenil)
  case truefalsenil
    when 'true'
      true
    when 'false'
      false
    when 'nil'
      nil
    else
      truefalsenil
  end

end

Transform /^-?\d+$/ do |number|
  number.to_i
end

Transform /^[-+]?[0-9]*\.?[0-9]+$/ do |number|
  number.to_f
end

Transform /^true|false|nil$/ do |truefalsenil|
  eval(truefalsenil)
end


Transform /^table:iniKey,keyValue/ do |iniTable|
  symbolize_table(iniTable)
end

