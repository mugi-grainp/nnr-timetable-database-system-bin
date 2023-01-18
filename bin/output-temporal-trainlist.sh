#!/bin/bash

# output-traincartable.sh
# 列車編成両数表全体を出力
# コマンドライン引数
#     $1: データベースディレクトリ名
#     $2: ダイヤ区分 (weekday/saturday/holiday)
#     $3: "all-list"を指定したとき、時刻表データがない列車も出力する [オプション]

db_dir="$1"
dia_day="$2"

case "$3" in
    "all-list"          ) output_flag="-a 1" ;;
    "all-timetable"     ) output_flag="-a 1" ;;
    "missing-timetable" ) output_flag="-v 1" ;;
    "missing-in-list"   ) output_flag="-v 2" ;;
    * ) output_flag="" ;;
esac

# フィールド出力順序説明を兼ねて、ヘッダを出力する
echo '管理番号,掲載順序,列車種別,起点駅,終点駅,行先表示駅名,起点出発時刻,終点到着時刻'

# 時刻表ファイルを列挙
find ${db_dir}/${dia_day}/ -type f -name 'timetable_'"${dia_day}"'*.csv'        |

# ファイル名から曜日と列車番号を切り出す
# 「曜日 列車番号」の形になるので、そのまま引数2つ分として渡せる
sed -e "s;^${db_dir}/${dia_day}/timetable_;;" -e 's;\.csv$;;' -e 's;_; ;'       |

# 列車編成両数表の1行を出力する
xargs -IXXX bash -c "bin/output-temporal-trainlist-line.sh ${db_dir} XXX" |
LANG=C sort -s -t, -k1,1                                             > /tmp/$$-traincartable-list.tmp

cat /tmp/$$-traincartable-list.tmp
# 一時ファイルを削除
rm /tmp/$$-*.tmp
