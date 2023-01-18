#!/bin/bash

# extract-timetable-from-pagetext.sh
# にしてつ時刻表の各列車時刻表ページをテキストファイルとして保存したものを
# 時刻表の形式に加工する

# 管理番号を取得
operation_id=$(basename -s .txt $1 | cut -d_ -f2)

# 列車番号を取得
train_number=${operation_id%-*}

# ヘッダ出力
echo "管理番号,列車番号,駅名,着時刻,発時刻"

cat $1 |

# 時刻表が含まれる範囲を切り出す
sed -e '1,/乗る予定/d' -e '/\* <https:\/\/jik\.nishitetsu\.jp\/bus\/busnaviapp\.pdf>/,$d' |
# 行頭空白を消し，また空行と*だけの行を消す
sed -e 's/^ \+//' -e '/^\r$/d' -e '/^*/d' |
# 各駅フィールドの区切りにもなっているURLを線に変換
sed 's;<https://.\+>;-----;'              |

awk '
    BEGIN{
        FS="\r\n";RS="-----\r\n";OFS=",";ORS="\n"
    }
    NR==1{
        print $2, "", $1
        next
    }
    $4=="降車専用"{
        print $2, $1, ""
        next
    }
    {
        print $3,$1,$2
    }' |
sed -e 's/o //g' -e 's/着,/:00,/' -e 's/発$/:00/' |

# 駅名順序表と合わせることにより，通過駅込みで時刻表を作る
ruby bin/sfjoin.rb -m LOUTER -j 1 -t, station_list.txt - |

# 管理番号と列車番号を付与
awk -v id=$operation_id -v tnum=$train_number '
    BEGIN{FS=",";OFS=","}
    {print id, tnum, $0}
    '
