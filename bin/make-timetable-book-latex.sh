#!/bin/bash

# make-timetable-book-latex.sh
# 時刻表をLaTeXソース形式で出力する
# コマンドライン引数
#     $1: データベースディレクトリ名
#     $2: ダイヤ区分 (weekday/saturday/holiday)
#     $3: 上下の別 (up/down)

basedir="$(dirname $0)/../.."
bindir="$(dirname $0)"

# コマンドライン解析
OPTIONS=$(getopt -n $(basename $0) -o b:d:u: -l database:,dia-day:,direction: -- $@)
eval set -- "$OPTIONS"
while [ $# -gt 0 ]
do
    case $1 in
        -b | --database) db_dir="$2" ;;
        -d | --dia-day ) dia_day="$2" ;;
        -u | --direction) direction="$2" ;;
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

# 列車は1ページにつき20本ずつセット
trains_per_page=20

# 上下の別による着発表示変換箇所設定
if [ "$direction" = "down" ] ; then
    chakuhatsu="紫"
    direction_str="下り"
elif [ "$direction" = "up" ] ; then
    chakuhatsu="味坂"
    direction_str="上り"
else
    exit 1
fi

# ダイヤ区分による変換箇所指定
if [ "$dia_day" = "weekday" ] ; then
    dia_day_str="平日"
elif [ "$dia_day" = "saturday" ] ; then
    dia_day_str="土曜"
elif [ "$dia_day" = "holiday" ] ; then
    dia_day_str="日祝"
else
    exit 1
fi

# 時刻表生成用順序表
train_list_file="$basedir/timetable_book/train_list_for_timetable_${dia_day}_${direction}.csv"
# 時刻表生成用駅一覧
station_list_file="$bindir/station_list_for_timetable_${direction}.txt"

# 各列車の時刻表を出力
# 車両取替前後の重複分だけを取り除くため、5行目の uniq 前にはソートしない
cat $train_list_file           |
cut -d, -f1                    |
sed 's/-[012]//'               |
uniq                           |
tee /tmp/$$-train-num-list.tmp |
xargs -IXXX bash -c "$bindir/sfjoin.rb -t, -j 1 -m LOUTER ${station_list_file} \
    <($bindir/make-timetable-book-each-train.sh ${db_dir} ${dia_day} ${direction} XXX) > /tmp/$$-timetable-XXX.tmp"

# 列車番号リストをもとに、LaTeXソースを作成
# ヘッダ出力
cat <<HEADER
\documentclass[a4paper,10pt]{ltjsarticle}

\input{timetable-preamble}

\begin{document}
% \setlength{\tabrowsep}{1mm}
\setlength{\tabcolsep}{0.3mm}
\chead{※ - 久留米から普通　○ - 二日市から普通　▲ - 筑紫から普通}
% \chead{※ - 花畑から急行　▲ - 筑紫から急行　☆ - 大橋から各駅に停車}
% \chead{○ - 二日市から普通　▲ - 筑紫から普通}
\cfoot{\thepage}

HEADER

# 時刻表本体の出力
cp ${station_list_file} /tmp/$$-timetable-all.tmp

while read tnum
do
   # 優等列車に対し、優等運転区間を太字にするタグを付与
   # 回送列車に対し、時刻を斜体にするタグを付与
   # 時刻表ファイルに対し、生成した列車1本分の列をくっつける
   if [ "$direction" = "down" ]; then
        case $tnum in
            A??? )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | sed 's/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            G??? )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | sed 's/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            H??? )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | sed '1s/[^,]\+,\(.\+\)/\\trexp{\1}/; 4,/花畑/s/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            J??? )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | sed '1s/[^,]\+,\(.\+\)/\\trexp{\1}/; 4,/筑紫/s/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            K??? )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | sed '1s/[^,]\+,\(.\+\)/\\trexp{\1}/; 4,/西鉄二日市_着/s/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            L??? )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | sed 's/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            0??? )
                paste -d, /tmp/$$-timetable-all.tmp \
                   <(cat /tmp/$$-timetable-${tnum}.tmp | \
                   sed 's/[^,]\+,\([0-9:]\+\)/\\troos{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            *    )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
        esac
    elif [ "$direction" = "up" ] ; then
        case $tnum in
            A??? )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | sed 's/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            G??? | S076 | S082 | S086 )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | sed 's/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            H??? | S072 | S088 )
                paste -d, /tmp/$$-timetable-all.tmp \
                   <(cat /tmp/$$-timetable-${tnum}.tmp | \
                   sed '/列車番号/s/[^,]\+,\(.\+\)/\\trexp{\1}/;/花畑_発/,$s/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            J??? | S080 )
                paste -d, /tmp/$$-timetable-all.tmp \
                   <(cat /tmp/$$-timetable-${tnum}.tmp | \
                   sed '/列車番号/s/[^,]\+,\(.\+\)/\\trexp{\1}/;/筑紫_発/,$s/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            K??? | S070 | S074 | S084 | S380 )
                paste -d, /tmp/$$-timetable-all.tmp \
                   <(cat /tmp/$$-timetable-${tnum}.tmp | \
                   sed '/列車番号/s/[^,]\+,\(.\+\)/\\trexp{\1}/;/西鉄二日市_発/,$s/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            L??? )
                paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | sed 's/[^,]\+,\(.\+\)/\\trexp{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
            0??? )
                paste -d, /tmp/$$-timetable-all.tmp \
                   <(cat /tmp/$$-timetable-${tnum}.tmp | \
                   sed 's/[^,]\+,\([0-9:]\+\)/\\troos{\1}/' | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
                ;;
         *    )
            paste -d, /tmp/$$-timetable-all.tmp <(cat /tmp/$$-timetable-${tnum}.tmp | cut -d, -f2) > /tmp/$$-timetable-combined.tmp
            ;;
      esac
   fi
   cp /tmp/$$-timetable-combined.tmp /tmp/$$-timetable-all.tmp
done < /tmp/$$-train-num-list.tmp

cat /tmp/$$-timetable-all.tmp                         |
# 上下により「〃」と「発」を書き分ける駅の着発表記を変換
sed "s/^${chakuhatsu}_〃/${chakuhatsu}_発/"           |
# 正式名称に「西鉄」がついていても案内等には用いないため、一括除去
sed 's/西鉄//g' |
# 時刻表記の秒の部分、および、時の部分の10の位の0を除去
sed -E 's/0([0-9]):([0-9]{2}):00/\1\2/g'   |
sed -E 's/([0-9]{2}):([0-9]{2}):00/\1\2/g' > /tmp/$$-timetable-all-processed.tmp

# 1ページ出力
train_count=$(cat /tmp/$$-train-num-list.tmp | wc -l)
seq 1 $trains_per_page $train_count |
xargs -IXXX bash -c "$bindir/make-timetable-book-latex-each-page.sh \
                     /tmp/$$-timetable-all-processed.tmp XXX $trains_per_page | \
                     sed 's/<DIA_DAY>/$dia_day_str/g;s/<DIRECTION>/$direction_str/g' > /tmp/$$-page-from-XXX.tmp"
# ページ統合
for i in $(seq 1 $trains_per_page $train_count)
do
   cat /tmp/$$-page-from-${i}.tmp
done

# ドキュメントフッタ出力
cat <<FOOTER
\end{document}
FOOTER

rm /tmp/$$-*.tmp
