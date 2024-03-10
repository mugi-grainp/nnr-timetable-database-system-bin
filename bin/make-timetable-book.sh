#!/bin/bash

# make-timetable-book.sh
# 時刻表出力のために実行する一連のコマンドをまとめたファイル
# コマンドライン引数
#     -b, --database  データベースディレクトリ名
#     -d, --dia-day   ダイヤ区分 (weekday/saturday/holiday)
#     -u, --direction 上下の別 (up/down)
#     --list-only     列車順序ファイルのみ出力

# 初期値設定
list_only="no"

# 基準ディレクトリ設定
basedir="$(dirname $0)/../.."
bindir="$(dirname $0)"

# コマンドライン解析
OPTIONS=$(getopt -n $(basename $0) -o b:d:u: -l database:,dia-day:,direction:,list-only -- $@)
eval set -- "$OPTIONS"
while [ $# -gt 0 ]
do
    case $1 in
        -b | --database) db_dir="$2" ;;
        -d | --dia-day ) dia_day="$2" ;;
        -u | --direction) direction="$2" ;;
        --list-only)      list_only="yes" ;;
        --) shift; break;;
    esac
    shift
done

if [ "$db_dir" = "" ] || [ "$dia_day" = "" ] || [ "$direction" = "" ] ; then
    echo "$(basename $0): データベースディレクトリ、ダイヤ区分、上下線区分はいずれも必須です。" >&2
    exit 1
fi

echo "database  : $db_dir" >&2
echo "dia-day   : $dia_day" >&2
echo "direction : $direction" >&2
echo "list-only : $list_only" >&2

# 上下の別による列車一覧フィルタリング範囲設定
if [ "$direction" = "down" ] ; then
    omuta_begin_index=100
    omuta_end_index=500
    dazaifu_begin_index=1100
    dazaifu_end_index=1500
elif [ "$direction" = "up" ] ; then
    omuta_begin_index=500
    omuta_end_index=1000
    dazaifu_begin_index=1500
    dazaifu_end_index=2000
else
    exit 1
fi

# 列車順序ファイルパスを決定
train_list_file="${db_dir}/${dia_day}/train_list_${dia_day}.csv"

# 上下・曜日の別による最終列車フィルタリング範囲設定
last_train=$(cat ${train_list_file} | \
             awk -F, -v begin_index=${omuta_begin_index} -v end_index=${omuta_end_index} '$2 < end_index' | \
             sort -t, -k2,2nr | head -n 1 | cut -d, -f1)

# 二日市駅基準における列車発着順序を算出
grep -h '西鉄二日市' ${db_dir}/${dia_day}/timetable_${dia_day}_*.csv |
awk 'BEGIN{FS=",";OFS=","}$4==""{$4=$5}$5==""{$5=$4}{print}'         |
sort -s -t, -k1,1                                                    |
join -j 1 -t, - <(cat ${train_list_file} | sort -s -t, -k1,1) |
awk -F, -v omuta_begin=${omuta_begin_index} \
        -v omuta_end=${omuta_end_index} \
        -v dazaifu_begin=${dazaifu_begin_index} \
        -v dazaifu_end=${dazaifu_end_index} '($6 > omuta_begin && $6 < omuta_end) || ($6 > dazaifu_begin && $6 < dazaifu_end)' |
sort -s -t, -k5,5 > /tmp/$$-train-order-at-futsukaichi.tmp

# 太宰府線列車をどの天神大牟田線列車の後に入れるかを算出
$bindir/determine_dazaifu_insertion_order.rb /tmp/$$-train-order-at-futsukaichi.tmp |
grep -E -B1 '^(6|0301|0300)'    |
grep -v -- '--'                 |
cut -d, -f1,6-12 > /tmp/$$-dazaifu_insertion_pos.tmp

# 時刻表生成用の列車順序リストを生成
$bindir/make-timetable-order-list.rb \
    /tmp/$$-dazaifu_insertion_pos.tmp \
    ${train_list_file} |
awk -F, -v omuta_begin=${omuta_begin_index} \
        -v omuta_end=${omuta_end_index} \
        -v dazaifu_begin=${dazaifu_begin_index} \
        -v dazaifu_end=${dazaifu_end_index} '($2 > omuta_begin && $2 < omuta_end) || ($2 > dazaifu_begin && $2 < dazaifu_end)' |
sed "/^${last_train}/q" > ${basedir}/timetable_book/train_list_for_timetable_${dia_day}_${direction}.csv

# 時刻表を生成して標準出力へ出力
if [ "$list_only" = "yes" ]; then
    exit 0
else
    $bindir/make-timetable-book-main.sh ${db_dir} ${dia_day} ${direction}
fi

rm /tmp/$$-*
