#!/bin/bash

# make-timetable-book-each-train.sh
# 冊子時刻表編成用のデータを1列車分出力する
# コマンドライン引数
#     $1: データベースディレクトリ名
#     $2: ダイヤ区分 (weekday/saturday/holiday)
#     $3: 上下の別 (up/down)
#     $4: 列車番号

db_dir="$1"
dia_day="$2"
direction="$3"
train_num="$4"
station_list_file="bin/station_list_for_timetable_amagiline_${direction}.txt"

bin/output-timetable.sh ${db_dir} ${dia_day} ${train_num} |
awk 'BEGIN{FS=",";OFS=","}$2==""{$2="↓"}{print}'         > /tmp/$$-timetable-with-passmark.tmp

# ヘッダ出力
train_info=($(cat ${db_dir}/${dia_day}/train_list_${dia_day}.csv | grep "^${train_num}" | head -n 1 | awk -F, '{print $1, $3, $6}'))
echo "列車番号,${train_num}"
echo "種別,${train_info[1]}"
echo "行先,${train_info[2]}"

# 始発駅・終着駅を取得
origin=$(head -n 4 /tmp/$$-timetable-with-passmark.tmp | tail -n 1 | cut -d, -f1)
destination=$(tail -n 1 /tmp/$$-timetable-with-passmark.tmp | cut -d, -f1)

# 時刻表用駅一覧と結合して割り付け
bin/sfjoin.rb -t, -j 1 -m LOUTER -e "||" \
    ${station_list_file} \
    /tmp/$$-timetable-with-passmark.tmp |
# 列車の運行区間外となる行を削除
# ただし、着発表示でない途中駅終着（試験場前・大善寺・北野・本郷）は
# 次の駅の欄に == （終着表示）を入れるためその処理を実施
awk -v origin=${origin} -v destination=${destination} \
    'BEGIN {
         FS=","; OFS=","; output = 0
         origin_re = "^" gensub(/([\(\)])/, "\\\\\\1", "g", origin)
         dest_re   = "^" gensub(/([\(\)])/, "\\\\\\1", "g", destination)
    }
    $1 ~ origin_re { output = 1 }
    $1 ~ dest_re {
        print
        if ($1 ~ /花畑_着$/) { exit }
        if (getline > 0) {
            $2 = "\\terminated"
            print
        }
        exit
    }
    output == 1 { print }
    '
rm /tmp/$$-*.tmp
