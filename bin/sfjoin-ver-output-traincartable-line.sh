#!/bin/bash

# output-traincartable-line.sh
# 列車編成両数表の1行を算出
# 列車番号、始発駅、始発時刻、終着駅、終着時刻、系統記号/日中運用区分、車両形式、編成両数を出力
# コマンドライン引数
#     $1: ダイヤ区分 (weekday/saturday/holiday)
#     $2: 管理番号

# 時刻表ファイルの2行目 (データ先頭行) と末尾行を取得
timetable_data_first_line=$(head -n 2 "$(dirname $0)/../db/timetable_$1_$2.csv" | tail -n 1)
timetable_data_tail_line=$(tail -n 1 "$(dirname $0)/../db/timetable_$1_$2.csv")

# 列車番号・始発駅・終着駅情報を取得
## 時刻表ファイルから読み込んだ行をカンマで区切って配列化
origin_sta_info=(${timetable_data_first_line//,/ })
destination_sta_info=(${timetable_data_tail_line//,/ })

## 各情報を取得
train_number=${origin_sta_info[0]}
origin_sta_name=${origin_sta_info[2]}
origin_sta_departure_time=${origin_sta_info[4]}
destination_sta_name=${destination_sta_info[2]}
destination_sta_arrival_time=${destination_sta_info[3]}

# 管理番号に対する運用情報を算出する
ruby $(dirname $0)/../bin/sfjoin.rb -t, -1 2 -2 1 \
        db/relation_operation_and_train.csv db/operation_cartype_info.csv |
        grep "^$2" |
        awk -v tnum=${train_number} \
            -v origin_sta_name=${origin_sta_name} \
            -v origin_sta_departure_time=${origin_sta_departure_time} \
            -v destination_sta_name=${destination_sta_name} \
            -v destination_sta_arrival_time=${destination_sta_arrival_time} \
                'BEGIN{FS=",";OFS=","} \
                {print tnum, origin_sta_name, origin_sta_departure_time, \
                        destination_sta_name, destination_sta_arrival_time, \
                $4, $5, $6, $7}'
