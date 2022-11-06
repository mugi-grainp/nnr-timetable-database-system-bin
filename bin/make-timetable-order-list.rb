#!/usr/bin/env ruby

# make-timetable-order-list.rb
# 全列車時刻表における掲載順序を決定する
# 天神大牟田線と甘木線の組で作成した掲載順序表に、太宰府線の列車を差し込む

position_list = Hash.new { |h, k| h[k] = [] }
fname_dazaifu_insertion_pos = ARGV.shift

# 太宰府線列車挿入位置ファイルを読み込む
# 列車を挿入すべき行を検出したら、その部分に対応する太宰府線列車を入れる
File.open(fname_dazaifu_insertion_pos) do |f|
  key = ''
  f.each do |line|
    buf = line.chomp.split(',')
    if /^(6|0301|0300)/ =~ buf[0]
      position_list[key] << line.chomp
    else
      key = buf[0]
    end
  end
end

ARGF.each do |line|
  puts line

  buf = line.chomp.split(',')
  if position_list.has_key?(buf[0])
    position_list[buf[0]].each do |elem|
      puts elem
    end
  end
end
