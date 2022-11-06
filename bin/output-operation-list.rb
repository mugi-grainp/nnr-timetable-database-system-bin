#!/usr/bin/env ruby

# output-operation-list.rb
# 車両系統表を出力する
# コマンドライン引数
#     $1 : データベースディレクトリ
#     $2 : ダイヤ区分 (weekday / saturday / holiday)

database_dir = ARGV.shift
dia_day      = ARGV.shift

relation_file       = "#{database_dir}/#{dia_day}/relation_operation_and_train_#{dia_day}.csv"
operation_info_file = "#{database_dir}/#{dia_day}/operation_cartype_info_#{dia_day}.csv"

relations = Hash.new { |h, k| h[k] = [] }
File.open(relation_file) do |f_relation|
  f_relation.each do |line|
    buf = line.chomp.split(',')
    next if buf[0] == '管理番号'
    relations[buf[1]] << buf[0]
  end
end


File.open(operation_info_file) do |f_op_info|
  f_op_info.each do |line|
    buf = line.chomp.split(',')
    next if buf[0] == '系統ID'

    operation_id = buf[0]
    operation_unit_name  = buf[1]
    operation_unit_alias = buf[2]
    cartype = buf[3]
    boxes   = buf[4]
    operation_first_train = relations[operation_id].first
    operation_last_train  = relations[operation_id].last

    operation_start = nil
    operation_end   = nil

    # 系統出庫列車の出庫駅・始発時刻と、系統入庫列車の入庫駅・終着時刻を取得
    first_train_timetable_file = "#{database_dir}/#{dia_day}/timetable_#{dia_day}_#{operation_first_train}.csv"
    if File.exist?(first_train_timetable_file)
      File.open(first_train_timetable_file) do |f_first|
        f_first.readline # ヘッダ行を読み捨て
        operation_start = f_first.readline.chomp.split(',')
      end
    else
      operation_start = ["", "", "", "", ""]
    end

    last_train_timetable_file = "#{database_dir}/#{dia_day}/timetable_#{dia_day}_#{operation_last_train}.csv"
    if File.exist?(last_train_timetable_file)
      File.open(last_train_timetable_file) do |f_last|
        operation_end = f_last.readlines(chomp: true).last.split(',')
      end
    else
      operation_end = ["", "", "", "", ""]
    end

    print "#{operation_unit_name}\t#{operation_unit_alias}\t#{cartype}*#{boxes}\t"
    print "#{operation_start[2]}\t#{operation_start[4].gsub(/^0?([0-9]{1,2}:[0-9]{2}):00$/, "\\1")}\t"
    print "#{operation_end[2]}\t#{operation_end[3].gsub(/^0?([0-9]{1,2}:[0-9]{2}):00$/, "\\1")}\t"
    puts  relations[operation_id].map {|v| v.gsub(/-[12]$/, '') }.join('-')
  end
end

