#!/bin/bash

# output-timetable.sh
# データベースから取り出した情報から1本の時刻表を取り出す
# コマンドライン引数
#     $1: データベースディレクトリ名
#     $2: ダイヤ区分 (weekday/saturday/holiday)
#     $3: 列車番号

db_dir="$1"
dia_day="$2"
train_num="$3"

train_info=($(cat ${db_dir}/${dia_day}/train_list_${dia_day}.csv | grep "^${train_num}" | head -n 1 | awk -F, '{print $1, $3, $6}'))

# ヘッダ出力
echo "列車番号,${train_num}"
echo "種別,${train_info[1]}"
echo "行先,${train_info[2]}"

# 列車番号から関係ファイルをすべて取り出す
find ${db_dir}/${dia_day}/ -type f -name 'timetable_'"${dia_day}_${train_num}"'*.csv' |
xargs awk '
    BEGIN { FS = ","; OFS = "," }
    $1 == "管理番号" { next }

    # 着発表示すべき主要駅
    $3 ~ /西鉄福岡\(天神\)|大橋|春日原|西鉄二日市|筑紫|西鉄小郡|宮の陣|西鉄久留米|花畑|大善寺|西鉄柳川|大牟田|太宰府|^甘木/ {
        if ($4 != "") { print $3 "_着", $4 }
        if ($5 != "") { print $3 "_発", $5 }
        if (($4 == "") && ($5 == "")) { 
            print $3 "_着", ""
            print $3 "_発", ""
        }
        next
    }

    # 主要駅以外で終着列車が存在する途中駅（津福・北野・本郷）
    # $4 != "" && $5 == "" { print $3 "_着", $4; next }
    # 冊子時刻表生成の場合は、結合のため「〃」のままとする
    $4 != "" && $5 == "" { print $3 "_〃", $4; next }

    { print $3 "_〃", $5 }
'

