#!/bin/bash

# timetable-download-and-convert.sh
# 時刻表のダウンロードと変換
# 呼び出し
#     ./timetable-download-and-convert.sh OPTIONS URL_LIST_FILE
# コマンドライン引数
#     -b, --database  データベースディレクトリ名
#     -d, --dia-day   ダイヤ区分 (weekday/saturday/holiday)
#     -u, --direction 上下の別 (up/down)
# URL_LIST_FILE 各列車別時刻表へのURL

show_help() {
    cat << HELP_MSG >&2
timetable-download-and-convert.sh v1.0
時刻表のダウンロードと変換

呼び出し
    ./timetable-download-and-convert.sh OPTIONS URL_LIST_FILE

オプション（必須）
    -b, --database  データベースディレクトリ名
    -d, --dia-day   ダイヤ区分 (weekday/saturday/holiday)
    -u, --direction 上下の別 (up/down)

ヘルプ
    -h, --help      このヘルプを表示
    --version       バージョン情報を表示

コマンドライン引数
    URL_LIST_FILE   取得済フラグ(X),各列車別時刻表へのURLを記述した
                    CSV形式のリストファイル
HELP_MSG
}

# コマンドライン解析
OPTIONS=$(getopt -n $(basename $0) -o b:d:u:h -l database:,dia-day:,direction:,version,help -- $@)
eval set -- "$OPTIONS"
while [ $# -gt 0 ]
do
    case $1 in
        -b | --database) db_dir="$2" ;;
        -d | --dia-day ) dia_day="$2" ;;
        -u | --direction) direction="$2" ;;
        --help )
            show_help
            exit 0
            ;;
        --version )
            echo 'timetable-download-and-convert.sh v1.0'
            exit 0
            ;;
        --) shift; break;;
    esac
    shift
done

if [ "$db_dir" = "" ] || [ "$dia_day" = "" ] || [ "$direction" = "" ] ; then
    echo "$(basename $0): データベースディレクトリ、ダイヤ区分、上下線区分はいずれも必須です。" >&2
    show_help
    exit 1
fi

# にしてつ時刻表におけるダイヤ（曜日）区分コードの設定
case $dia_day in
    weekday ) dia_code="11" ;;
    saturday) dia_code="14" ;;
    holiday ) dia_code="15" ;;
    shogatsu) dia_code="13" ;;
    *       )
        echo "$(basename $0): ダイヤ区分は平日 (weekday)・土曜 (saturday)・日祝 (holiday)・正月 (shogatsu) で指定してください。" >&2
        exit 1
        ;;
esac


echo "database  : $db_dir" >&2
echo "dia-day   : $dia_day" >&2
echo "direction : $direction" >&2

# URLリストファイルを読み込み
cat $1       |
# 行頭に "X" が入った行は処理しない
grep -v '^X' |
sed 's/,//' > /tmp/$$-urllist.tmp

while read -u 9 line
do
    keitou_code="$(echo $line | cut -d'&' -f4 | sed 's/keito_cd=//'| sed -e 's/^'"$dia_code"'/'"$dia_day"'_/')"
    read -p "1. Download and convert ${keitou_code} / 2. Abort? [1-2]: " ans

    case "$ans" in
        1 ) : ;;
        2 )
            echo "Aborted."
            exit 0
            ;;
        * ) exit 1 ;;
    esac

    echo "$line"
    curl -sS "$line" > ${dia_day}/${keitou_code}-0.htm
    ./extract-timetable-from-html.sh --direction=${direction} ${dia_day}/${keitou_code}-0.htm > ${db_dir}/${dia_day}/timetable_${keitou_code}-0.csv

done 9< /tmp/$$-urllist.tmp

rm /tmp/$$-*.tmp
