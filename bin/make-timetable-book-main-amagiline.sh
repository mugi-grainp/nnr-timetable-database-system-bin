#!/bin/bash

# make-timetable-book-main.sh
# 時刻表を出力する
# コマンドライン引数
#     $1: データベースディレクトリ名
#     $2: ダイヤ区分 (weekday/saturday/holiday)
#     $3: 上下の別 (up/down)

db_dir="$1"
dia_day="$2"
direction="$3"

train_list_file="timetable_book/train_list_for_timetable_${dia_day}_${direction}.csv"
station_list_file="bin/station_list_for_timetable_amagiline_${direction}.txt"

# 各列車の時刻表を出力
# 車両取替前後の重複分だけを取り除くため、5行目の uniq 前にはソートしない
cat $train_list_file           |
grep -E '甘木|本郷|北野'       |
grep -v '^9'                   |
cut -d, -f1                    |
sed 's/-[12]//'                |
LANG=C uniq                    |
tee /tmp/$$-train-num-list.tmp |
xargs -IXXX bash -c "bin/sfjoin.rb -t, -j 1 -m LOUTER ${station_list_file} \
    <(bin/make-timetable-book-each-train-amagiline.sh ${db_dir} ${dia_day} ${direction} XXX) > /tmp/$$-timetable-XXX.tmp"

# 列車番号リストをもとに、1本ずつくっつける
cp ${station_list_file} /tmp/$$-timetable-all.tmp
while read tnum
do
    paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
    cp /tmp/$$-timetable-combined.tmp /tmp/$$-timetable-all.tmp
done < /tmp/$$-train-num-list.tmp

cat /tmp/$$-timetable-all.tmp |
sed 's/西鉄//g;s/\(列車番号\|種別\|行先\)/&,/;s/_/,/'

rm /tmp/$$-*.tmp
