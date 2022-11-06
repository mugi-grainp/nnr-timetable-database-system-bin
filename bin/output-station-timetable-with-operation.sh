#!/bin/bash

# output-station-timetable-with-operation.sh
# 車両運用情報入りの駅時刻表を出力する
# コマンドライン引数
#     $1: データベースディレクトリ名
#     $2: 駅名
#     $3: ダイヤ区分

db_dir="$1"
station_name="$2"
dia_day="$3"

# 各列車の時刻表から指定駅の時刻を検索し，種別・行先ファイルと結合
join -j 1 -t, <(grep -h "${station_name}" ${db_dir}/${dia_day}/timetable_${dia_day}_*.csv | grep -v ',$' | sort -s -t, -k1,1) \
              <(cat ${db_dir}/${dia_day}/train_list_${dia_day}.csv | sort -s -t, -k1,1) |

# 続いて，管理番号と運用IDの関係を記したファイルと結合
join -j 1 -t, - <(cat ${db_dir}/${dia_day}/relation_operation_and_train_${dia_day}.csv | sort -s -t, -k1,1) |

# 運用IDによりソート
LANG=C sort -s -t, -k11,11 |

# 車両運用テーブルと結合
join -1 11 -2 1 -t, - <(cat ${db_dir}/${dia_day}/operation_cartype_info_${dia_day}.csv | sort -s -t, -k1,1) |

# 発車時刻順にソート
LANG=C sort -s -t, -k6,6 |

# 必要なフィールドを切り出す
# フィールド順序は列車番号，発車時刻，種別，行先，車両形式，編成両数
cut -d, -f3,6,8,11,15,16 |
uniq
