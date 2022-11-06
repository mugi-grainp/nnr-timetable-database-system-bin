#!/bin/bash

# output-traincartable-line.sh
# 列車編成両数表の1行を算出
# 列車番号、始発駅、始発時刻、終着駅、終着時刻、系統記号/日中運用区分、車両形式、編成両数を出力
# コマンドライン引数
#     $1: データベースディレクトリ名
#     $2: ダイヤ区分 (weekday/saturday/holiday)
#     $3: 管理番号
# (*1) UNIX sort / join コマンドを利用

# データベースディレクトリ名
db_dir="$1""/""$2"

# 時刻表ファイルの2行目 (データ先頭行) と末尾行を取得
timetable_data_first_line=$(head -n 2 "$(dirname $0)/../${db_dir}/timetable_$2_$3.csv" | tail -n 1)
timetable_data_tail_line=$(tail -n 1 "$(dirname $0)/../${db_dir}/timetable_$2_$3.csv")

# 列車番号・始発駅・終着駅情報を取得
## 時刻表ファイルから読み込んだカンマ区切り行を配列化
IFS_ORIG=${IFS}
IFS=','
origin_sta_info=(${timetable_data_first_line})
destination_sta_info=(${timetable_data_tail_line})
IFS=${IFS_ORIG}

## 各情報を取得
operation_id=${origin_sta_info[0]}
origin_sta_name=${origin_sta_info[2]}
origin_sta_departure_time=${origin_sta_info[4]}
destination_sta_name=${destination_sta_info[2]}
destination_sta_arrival_time=${destination_sta_info[3]}

# 出力
echo "${operation_id},,,${origin_sta_name},${destination_sta_name},,${origin_sta_departure_time},${destination_sta_arrival_time}"

# 一時ファイル群を削除
rm -f /tmp/$$-*
