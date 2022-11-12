#!/usr/bin/env ruby

# output-gnuplot-command.rb
# 箱ダイヤを出力するためのGnuplotコマンドを生成する
# コマンドライン引数
#      $1 : データベースディレクトリ名
#      $2 : ダイヤ区分
#      $3 : 系統記号

require 'set'
require 'bigdecimal'

# 列車情報を定義するクラス
class TrainData
  def initialize(trainid, originstaname, origindeparttime, deststaname, destarrivaltime)
    @train_id = trainid
    @origin_station  = originstaname
    @origin_departtime = origindeparttime
    @dest_station = deststaname
    @dest_arrivaltime = destarrivaltime
  end

  attr_reader :train_id, :origin_station, :origin_departtime, :dest_station, :dest_arrivaltime
end

# 車両系統情報を定義し、追加情報を算出するクラス
class OperationData
  # 距離計算用テーブル
  @@kilometers = Hash.new

  pair_fukuoka_futsukaichi = Set.new ['西鉄福岡(天神)', '西鉄二日市']
  pair_fukuoka_chikushi    = Set.new ['西鉄福岡(天神)', '筑紫']
  pair_fukuoka_ogori       = Set.new ['西鉄福岡(天神)', '西鉄小郡']
  pair_fukuoka_miyanojin   = Set.new ['西鉄福岡(天神)', '宮の陣']
  pair_fukuoka_kurume      = Set.new ['西鉄福岡(天神)', '西鉄久留米']
  pair_fukuoka_hanabatake  = Set.new ['西鉄福岡(天神)', '花畑']
  pair_fukuoka_shikenjomae = Set.new ['西鉄福岡(天神)', '試験場前']
  pair_fukuoka_tsubuku     = Set.new ['西鉄福岡(天神)', '津福']
  pair_fukuoka_daizenji    = Set.new ['西鉄福岡(天神)', '大善寺']
  pair_fukuoka_yanagawa    = Set.new ['西鉄福岡(天神)', '西鉄柳川']
  pair_fukuoka_omuta       = Set.new ['西鉄福岡(天神)', '大牟田']
  @@kilometers[pair_fukuoka_futsukaichi] = BigDecimal('15.2')
  @@kilometers[pair_fukuoka_chikushi]    = BigDecimal('20.8')
  @@kilometers[pair_fukuoka_ogori]       = BigDecimal('28.7')
  @@kilometers[pair_fukuoka_miyanojin]   = BigDecimal('36.5')
  @@kilometers[pair_fukuoka_kurume]      = BigDecimal('38.6')
  @@kilometers[pair_fukuoka_hanabatake]  = BigDecimal('39.5')
  @@kilometers[pair_fukuoka_shikenjomae] = BigDecimal('40.1')
  @@kilometers[pair_fukuoka_tsubuku]     = BigDecimal('41.4')
  @@kilometers[pair_fukuoka_daizenji]    = BigDecimal('45.1')
  @@kilometers[pair_fukuoka_yanagawa]    = BigDecimal('58.4')
  @@kilometers[pair_fukuoka_omuta]       = BigDecimal('74.8')

  pair_futsukaichi_dazaifu    = Set.new ['西鉄二日市', '太宰府']
  @@kilometers[pair_futsukaichi_dazaifu]    = BigDecimal('2.4')

  pair_miyanojin_kitano      = Set.new ['宮の陣', '北野']
  pair_miyanojin_hongo       = Set.new ['宮の陣', '本郷']
  pair_miyanojin_amagi       = Set.new ['宮の陣', '甘木']
  @@kilometers[pair_miyanojin_kitano]      = BigDecimal('5.4')
  @@kilometers[pair_miyanojin_hongo]       = BigDecimal('13.1')
  @@kilometers[pair_miyanojin_amagi]       = BigDecimal('17.9')

  def initialize(sortid, opename, opealias, cartype, boxes)
    @sort_id = sortid
    @operation_name = opename
    @operation_alias = opealias
    @car_type = cartype
    @car_boxes = boxes
    @trains = []
  end

  def add_train(t)
    @trains << t
  end

  def run_distance
    total_distance = 0.0
    @trains.each do |train|
      section_set = Set.new [train.origin_station, train.dest_station]
      branch_section = nil
      main_section = nil

      if section_set.include?('太宰府')
        if section_set.include?('西鉄二日市')
          branch_section = []
          main_section = section_set
        else
          branch_section, main_section = divide_branch_section(section_set, '太宰府')
        end
      elsif section_set.include?('甘木')
        branch_section, main_section = divide_branch_section(section_set, '甘木')
      elsif section_set.include?('本郷')
        branch_section, main_section = divide_branch_section(section_set, '本郷')
      elsif section_set.include?('北野')
        branch_section, main_section = divide_branch_section(section_set, '北野')
      else
        branch_section = []
        main_section = section_set
      end

      if main_section.include?('太宰府') && main_section.include?('西鉄二日市')
        main_calc_sections = [main_section] 
      else
        main_calc_sections = divide_main_section(main_section)
      end
      if main_calc_sections.length == 1
        main_distance = @@kilometers[main_calc_sections[0]]
      else
        main_distance = (@@kilometers[main_calc_sections[0]] - @@kilometers[main_calc_sections[1]]).abs
      end

      total_distance += main_distance
      total_distance += @@kilometers[branch_section] if branch_section.length != 0
    end
    total_distance.to_s("F")
  end

  def operation_title
    if @operation_alias != ""
      @operation_name + "（日中運用 #{@operation_alias}）"
    else
      @operation_name
    end
  end

  attr_reader :sort_id, :operation_name, :operation_alias, :car_type, :car_boxes, :trains
  private

  def divide_branch_section(section_set, branch_station)
    section_set_temp = section_set.dup
    calc_sections = []

    case branch_station
    when '太宰府'
      section_set_temp.delete('太宰府')
      section_set_temp.add('西鉄二日市')
      section_dazaifu = Set.new ['西鉄二日市', '太宰府']
      calc_sections << section_dazaifu
    when '甘木', '本郷', '北野'
      section_set_temp.delete(branch_station)
      section_set_temp.add('宮の陣')
      section_amagi = Set.new ['宮の陣', branch_station]
      calc_sections << section_amagi
    end
    calc_sections << section_set_temp

    calc_sections
  end

  def divide_main_section(section_set)
    calc_sections = []
    section_set.each do |station|
      sec_n = Set.new ['西鉄福岡(天神)', station]
      calc_sections << sec_n if sec_n.size == 2
    end
    calc_sections
  end
end

# 引数を取得する
database_dir = ARGV.shift
dia_day      = ARGV.shift
operation_id = ARGV.shift

# 1車両系統に登場する駅の一覧
station_list = Set.new

# 各駅の座標比率による駅出力位置定義
x_position = {}
x_position["西鉄福岡(天神)"] = 2.0
x_position["西鉄二日市"] = 6.0
x_position["太宰府"] = 8.0
x_position["筑紫"] = 10.0
x_position["甘木"] = 11.0
x_position["本郷"] = 13.0
x_position["西鉄小郡"] = 14.0
x_position["北野"] = 15.0
x_position["西鉄久留米"] = 17.0
x_position["花畑"] = 19.0
x_position["試験場前"] = 21.0
x_position["津福"] = 23.0
x_position["大善寺"] = 25.0
x_position["西鉄柳川"] = 27.0
x_position["大牟田"] = 31.0

# 車両系統に属する列車の一覧ファイル
relation_file       = "#{database_dir}/#{dia_day}/relation_operation_and_train_#{dia_day}.csv"
# 車両系統に対する車両形式・編成両数の情報
operation_info_file = "#{database_dir}/#{dia_day}/operation_cartype_info_#{dia_day}.csv"

# 1車両系統に属する列車一覧を取得する
# 列車に関して取得すべき情報は、
# 列車番号, 起点駅名・起点発時刻, 着点駅名・着点着時刻, 車両系統記号, 日中運用区分名, 車両形式, 編成両数

## 取得すべき列車の管理番号, 列車配列順序を得る
train_operation_list = []
File.open(relation_file) do |f|
  f.each do |line|
    buf = line.chomp.split(',')
    train_operation_list << buf if buf[1] == operation_id
  end
end

## 車両系統の情報を得る
operation = nil
File.open(operation_info_file) do |f_op|
  f_op.each do |line|
    buf = line.chomp.split(',')
    if buf[0] == operation_id
      operation = OperationData.new(0, buf[1], buf[2], buf[3], buf[4])
      break
    end
  end
end

## 各列車の起終点駅・時刻を得る
train_operation_list.each do |train_op|
  timetable_file = "#{database_dir}/#{dia_day}/timetable_#{dia_day}_#{train_op[0]}.csv"
  File.open(timetable_file) do |f_tt|
    data = f_tt.readlines(chomp: true).map { |e| e.split(',') }
    train_record = TrainData.new(train_op[0].gsub(/-[12]/, ''), data[1][2], data[1][4], data[data.length - 1][2], data[data.length - 1][3])
    operation.add_train(train_record)
    station_list.add(train_record.origin_station)
    station_list.add(train_record.dest_station)
  end
end

# 駅出力位置を決定
station_list_output_line = (operation.trains.length + 0.75).to_f
right_pos_max = (station_list.map {|staname| x_position[staname]}).max
left_pos_min = (station_list.map {|staname| x_position[staname]}).min

# Gnuplot命令を出力
## 基本設定を出力
puts "set encoding utf8"

puts "unset key"
puts "unset xtics"
puts "unset ytics"

puts "set xrange [#{left_pos_min - 2}:#{right_pos_max + 2}]"
puts "set yrange [0:#{station_list_output_line + 1}]"

puts "set terminal emf color size 1300,#{(operation.trains.length + 2) * 100}"
puts "set output \"#{dia_day}_#{operation_id}.emf\""

## 駅ラベルを出力
puts "set label 1  center at first  2.0, #{station_list_output_line} \"福岡（天神）\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("西鉄福岡(天神)")
puts "set label 2  center at first  6.0, #{station_list_output_line} \"二日市\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("西鉄二日市")
puts "set label 15 center at first  8.0, #{station_list_output_line} \"太宰府\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("太宰府")
puts "set label 3  center at first  10.0, #{station_list_output_line} \"筑紫\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("筑紫")
puts "set label 4  center at first  11.0, #{station_list_output_line} \"甘木\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("甘木")
puts "set label 5  center at first 13.0, #{station_list_output_line} \"本郷\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("本郷")
puts "set label 6  center at first 14.0, #{station_list_output_line} \"小郡\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("小郡")
puts "set label 7  center at first 15.0, #{station_list_output_line} \"北野\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("北野")
puts "set label 8  center at first 17.0, #{station_list_output_line} \"久留米\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("西鉄久留米")
puts "set label 9  center at first 19.0, #{station_list_output_line} \"花畑\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("花畑")
puts "set label 10 center at first 21.0, #{station_list_output_line} \"試験場前\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("試験場前")
puts "set label 11 center at first 23.0, #{station_list_output_line} \"津福\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("津福")
puts "set label 12 center at first 25.0, #{station_list_output_line} \"大善寺\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("大善寺")
puts "set label 13 center at first 27.0, #{station_list_output_line} \"柳川\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("西鉄柳川")
puts "set label 14 center at first 31.0, #{station_list_output_line} \"大牟田\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\"" if station_list.include?("大牟田")

## 車両系統基礎情報を出力
puts "set label 21 left at graph 0.0, 1.0 offset 2, -1.5 \"#{operation.operation_title}\" textcolor rgb \"gray0\" font \"MS PGothic,24pt\" boxed"
puts "set label 22 center at graph 0.5, 1.0 offset 0, -1.5 \"#{operation.car_type}形#{operation.car_boxes}両\" textcolor rgb \"gray0\" font \"MS PGothic,24pt\""
puts "set label 23 right at graph 1.0, 1.0 offset -2, -1.5 \"運用距離：#{operation.run_distance} km\" textcolor rgb \"gray0\" font \"MS PGothic,24pt\""
puts "set arrow 1 nohead from #{left_pos_min - 2}, #{station_list_output_line + 0.25} to #{right_pos_max + 2}, #{station_list_output_line + 0.25}"

## 各列車を示す線と列車番号・時刻を出力
counter = 0
label_train_id_counter = 501
label_time_counter = 101
pos_list = []

operation.trains.each do |train|
  train_id_label_xpos = (x_position[train.origin_station] + x_position[train.dest_station]) / 2
  train_id_label_ypos = (operation.trains.length - counter).to_f

  # 時刻ラベルを出力
  # 線の左側に来るときは左に、線の右側に来るときは右に
  origin_deptime = train.origin_departtime.sub(/:00$/, "").sub(/^0/, "")
  dest_arrivaltime = train.dest_arrivaltime.sub(/:00$/, "").sub(/^0/, "")

  if x_position[train.origin_station] - x_position[train.dest_station] > 0
    # 始発時刻を始発座標の右・終着時刻を終着座標の左
    puts "set label #{label_time_counter} left at first " +
        "#{x_position[train.origin_station]}, #{train_id_label_ypos} " +
         "offset 1.5, 0 \"#{origin_deptime}\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\""
    puts "set label #{label_time_counter + 1} right at first " +
         "#{x_position[train.dest_station]}, #{train_id_label_ypos} " +
         "offset -1.5, 0 \"#{dest_arrivaltime}\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\""
  else
    # 始発時刻を始発座標の左・終着時刻を終着座標の右
    puts "set label #{label_time_counter} right at first " +
         "#{x_position[train.origin_station]}, #{train_id_label_ypos} " +
         "offset -1.5, 0 \"#{origin_deptime}\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\""
    puts "set label #{label_time_counter + 1} left at first " +
         "#{x_position[train.dest_station]}, #{train_id_label_ypos} " +
         "offset 1.5, 0 \"#{dest_arrivaltime}\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\""
  end

  # 列車番号ラベルを出力
  puts "set label #{label_train_id_counter} center at first #{train_id_label_xpos}, #{train_id_label_ypos} offset 0, 1 \"#{train.train_id}\" textcolor rgb \"gray0\" font \"MS PGothic,20pt\""

  # 回送表示の四角を出力
  # 箱ダイヤを引くための座標リストを出力
  pos_list << "#{x_position[train.origin_station]}, #{train_id_label_ypos}" << "#{x_position[train.dest_station]}, #{train_id_label_ypos}"
  counter  += 1
  label_train_id_counter += 1
  label_time_counter += 2
end

## 座標をインラインデータ形式で出力
puts "$train_graph << TGR"
puts pos_list.join("\n")
puts "TGR"

## 起点記号座標を出力
start_pos = pos_list.first
puts "$start_pos << STP"
puts start_pos
puts "STP"

# 終点記号座標を出力
end_pos = pos_list.last
puts "$end_pos << EDP"
puts end_pos
puts "EDP"

## プロット命令
puts "plot $train_graph with lines linecolor rgb \"gray0\"," +
     "$start_pos with points pointtype 6 pointsize 1 linecolor rgb \"gray0\"," +
     "$end_pos with points pointtype 8 pointsize 1 linecolor rgb \"gray0\"," +
     "$start_pos with points pointtype 7 pointsize 0.7 linecolor rgb \"gray100\"," +
     "$end_pos with points pointtype 9 pointsize 0.7 linecolor rgb \"gray100\""

## 終了処理
puts "set output"

