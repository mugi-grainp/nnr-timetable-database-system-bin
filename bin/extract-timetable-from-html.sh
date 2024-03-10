#!/bin/bash

# extract-timetable-from-html.sh
# にしてつ時刻表の各列車時刻表ページをHTMLファイルとして保存したものを
# 時刻表の形式に加工する
# 呼び出し
#     ./extract-timetable-from-html.sh OPTIONS FILE
# コマンドライン引数
#     -u, --direction 上下の別 (up/down)
#     FILE : HTMLファイルへのパス

# コマンドライン解析
OPTIONS=$(getopt -n $(basename $0) -o u: -l direction: -- $@)
eval set -- "$OPTIONS"
while [ $# -gt 0 ]
do
    case $1 in
        -u | --direction) direction="${2:=down}" ;;
        --) shift; break;;
    esac
    shift
done

# 管理番号を取得
operation_id=$(basename -s .htm $1 | cut -d_ -f2)
# 列車番号を取得
train_number=${operation_id%-*}
# 駅名順序表の決定
case $train_number in
    6??? ) station_list_file="./station_list_dazaifuline.txt" ;;
    8??? ) station_list_file="./station_list_dazaifuline.txt" ;;
    L??? ) station_list_file="./station_list_dazaifuline.txt" ;;
    7??? ) station_list_file="./station_list_amagiline.txt" ;;
    * ) station_list_file="./station_list.txt" ;;
esac

# ヘッダ出力
echo "管理番号,列車番号,駅名,着時刻,発時刻"

cat $1 |
# Unicode数値参照を漢字に変換
nkf -wLux --numchar-input |
# 時刻表が含まれる範囲を切り出す
sed -e '1,/<section class="p-page-schedule__content">/d' -e '/<\/section>/,$d' |
# 行頭空白をを消す
sed -e 's/^[ \t]\+//' |

awk '
    BEGIN{
        FS="\n";RS="\n\n\n";OFS=",";ORS="\n"
    }
    NR==1{
        next
    }
    {
        gsub(/<\/?[^>]+>/, "", $0)
        split($4, arrival_departure, /\t/)
    }
    NR==2{
        print $6, "", arrival_departure[1]
        next
    }
    NR>=3{
        print $6, arrival_departure[1], arrival_departure[2]
    }' |

# 時刻欄に秒の桁を付加
sed -e 's/着/:00/' -e 's/発/:00/' > /tmp/$$-timetable.tmp

# 駅名順序表と合わせることにより，通過駅込みで時刻表を作る
if [ $direction = "down" ]; then
    ## 下り処理時
    ruby sfjoin.rb -m LOUTER -j 1 -t, "$station_list_file" /tmp/$$-timetable.tmp > /tmp/$$-timetable2.tmp
elif [ $direction = "up" ]; then
    ## 上り処理時
    ruby sfjoin.rb -m LOUTER -j 1 -t, <(tac "$station_list_file") /tmp/$$-timetable.tmp > /tmp/$$-timetable2.tmp
fi

# 管理番号と列車番号を付与
cat /tmp/$$-timetable2.tmp |
awk -v id=$operation_id -v tnum=$train_number '
    BEGIN { FS=","; OFS=","; flag=0 }
    flag == 0 && $3 != "" { flag = 1; print id, tnum, $1, "", $3; next }
    flag == 1 { print id, tnum, $0 }
    $2 != "" && $3 == ""{ exit }
    '

rm /tmp/$$-*
