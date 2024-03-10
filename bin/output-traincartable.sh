#!/bin/bash

# output-traincartable.sh
# 列車編成両数表全体を出力
# コマンドライン引数
#     $1: データベースディレクトリ名
#     $2: ダイヤ区分 (weekday/saturday/holiday)
#     $3: "all-list"を指定したとき、時刻表データがない列車も出力する [オプション]

db_dir="$1"
dia_day="$2"
basedir="$(dirname $0)/../.."
bindir="$(dirname $0)"

case "$3" in
    "all-list"          ) output_flag="-a 1" ;;
    "all-timetable"     ) output_flag="-a 1" ;;
    "missing-timetable" ) output_flag="-v 1" ;;
    "missing-in-list"   ) output_flag="-v 2" ;;
    * ) output_flag="" ;;
esac

# フィールド出力順序説明を兼ねて、ヘッダを出力する
echo -n '管理番号,掲載順序,列車種別,始発駅,終着駅,列車表示行先,'
echo -n '列車番号,始発駅（再掲）,始発駅時刻,終着駅（再掲）,終着時刻,系統記号,'
echo '日中運用区分,車両形式,編成両数'


# 時刻表ファイルを列挙
find ${db_dir}/${dia_day}/ -type f -name 'timetable_'"${dia_day}"'*.csv'        |

# ファイル名から曜日と列車番号を切り出す
# 「曜日 列車番号」の形になるので、そのまま引数2つ分として渡せる
sed -e "s;^${db_dir}/${dia_day}/timetable_;;" -e 's;\.csv$;;' -e 's;_; ;'       |

# 列車編成両数表の1行を出力する
xargs -IXXX bash -c "bash ${bindir}/output-traincartable-line.sh ${db_dir} XXX" |
LANG=C sort -s -t, -k1,1                                                        > /tmp/$$-traincartable-list.tmp

# 列車リストを結合用にソートする
cat ${db_dir}/${dia_day}/train_list_${dia_day}.csv |
LANG=C sort -s -t, -k1,1                           > /tmp/$$-trainlist.tmp

# 追加情報を結合する
join -t, -j 1 ${output_flag} /tmp/$$-trainlist.tmp /tmp/$$-traincartable-list.tmp |

# 掲載順序の通りに並べ替える
LANG=C sort -s -t, -k2,2n

# 一時ファイルを削除
rm /tmp/$$-*.tmp
