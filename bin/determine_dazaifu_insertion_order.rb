#!/usr/bin/env ruby

lines   = ARGF.readlines(chomp: true)
records = lines.map {|item| item.split(',', -1) }

output_lines = []

record_buffer = []

records.each do |record|
  if /^(6|0301|0300)/ =~ record[0]
    record_buffer.sort_by! {|x| x[5] } if record_buffer.length > 0
    output_lines = output_lines + record_buffer
    output_lines << record
    record_buffer.clear
  else
    record_buffer << record
  end
end

output_lines = output_lines + record_buffer
output_lines.each do |elem|
  puts elem.join(',')
end
