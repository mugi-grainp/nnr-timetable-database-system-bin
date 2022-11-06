#!/usr/bin/env ruby

require 'set'
require 'bigdecimal'

# 距離計算用テーブル
kilometers = Hash.new

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
kilometers[pair_fukuoka_futsukaichi] = BigDecimal('15.2')
kilometers[pair_fukuoka_chikushi]    = BigDecimal('20.8')
kilometers[pair_fukuoka_ogori]       = BigDecimal('28.7')
kilometers[pair_fukuoka_miyanojin]   = BigDecimal('36.5')
kilometers[pair_fukuoka_kurume]      = BigDecimal('38.6')
kilometers[pair_fukuoka_hanabatake]  = BigDecimal('39.5')
kilometers[pair_fukuoka_shikenjomae] = BigDecimal('40.1')
kilometers[pair_fukuoka_tsubuku]     = BigDecimal('41.4')
kilometers[pair_fukuoka_daizenji]    = BigDecimal('45.1')
kilometers[pair_fukuoka_yanagawa]    = BigDecimal('58.4')
kilometers[pair_fukuoka_omuta]       = BigDecimal('74.8')

pair_futsukaichi_dazaifu    = Set.new ['西鉄二日市', '太宰府']
kilometers[pair_futsukaichi_dazaifu]    = BigDecimal('2.4')

pair_miyanojin_kitano      = Set.new ['宮の陣', '北野']
pair_miyanojin_hongo       = Set.new ['宮の陣', '本郷']
pair_miyanojin_amagi       = Set.new ['宮の陣', '甘木']
kilometers[pair_miyanojin_kitano]      = BigDecimal('5.4')
kilometers[pair_miyanojin_hongo]       = BigDecimal('13.1')
kilometers[pair_miyanojin_amagi]       = BigDecimal('17.9')


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

origin, destination = ARGV.shift.split(',')

section_set = Set.new [origin, destination]
branch_section = nil
main_section = nil
calc_sections = []

total_distance = 0.0

if section_set.include?('太宰府')
  branch_section, main_section = divide_branch_section(section_set, '太宰府')
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

main_calc_sections = divide_main_section(main_section)
if main_calc_sections.length == 1
  main_distance = kilometers[main_calc_sections[0]]
else
  main_distance = (kilometers[main_calc_sections[0]] - kilometers[main_calc_sections[1]]).abs
end

total_distance += main_distance
total_distance += kilometers[branch_section] if branch_section.length != 0

printf "%2.1f\n", total_distance
