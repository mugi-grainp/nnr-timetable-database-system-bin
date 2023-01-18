#!/bin/bash

# output-operation-table.sh
# 運用一覧表 (系統別整理) を出力する
# パラメータ
#     $1: 列車編成両数表向けの一覧ファイル
#     (output-traincartable.sh で出力される)


on_exit() {
    trap 1 2 3 15
    rm ${tmp_prefix}-*
    exit $1
}
trap 'on_exit 1' 1 2 3 15

# 一時ファイル用プレフィクス
tmp_prefix="/tmp/${0##*/}.$$"

# *** 準備 ********************************************
cat $1                      |
# タイトル行を削除
sed '1d'                    |
# 時刻の秒を削除
sed 's/:00\([,\n]\)/\1/g'   |
# 時の部分の頭0を削除
sed 's/,0\([5-9]:\)/, \1/g' |
# 系統記号と発時刻でソート
sort -s -t, -k12,12 -k9,9   |
# ソート済みデータを一時ファイルに置く
tee $tmp_prefix-operations-sorted-by-opcode |
# 車両系統一覧を生成
cut -d, -f12-15             |
uniq                        > $tmp_prefix-opcode-list
# *****************************************************

# *** 車両系統でグループ分けして取り出す **************
cat $tmp_prefix-opcode-list |
while read opcode
do
    # 車両系統抽出
    grep $opcode $tmp_prefix-operations-sorted-by-opcode |
    tee $tmp_prefix-filtered-operation                   |
    # 駅名の「西鉄」を削除
    sed 's/西鉄//g'                                      |
    awk '
        BEGIN{FS=",";OFS="\t"}
        # NR==1{printf "%-8s%-6s\t%-6s\t%-9s%-6s\t%-6s\t%s",$7,$3,$8,$9,$10,$11,"出庫"}
        # NR>=2{printf "\n%-8s%-6s\t%-6s\t%-9s%-6s\t%s",$7,$3,$8,$9,$10,$11}
        NR==1{printf "%s,%s,%s,%s,%s,%s,%s",$7,$3,$8,$9,$10,$11,"出庫"}
        NR>=2{printf "\n%s,%s,%s,%s,%s,%s,%s",$7,$3,$8,$9,$10,$11,""}
        END{if(NR==1){printf "/%s\n","入庫"}else{printf "%s\n","入庫"}}
    ' > $tmp_prefix-operation-table

    # 距離計算
    distance="$(\
        cat $tmp_prefix-filtered-operation            |
        # 起終点駅を切り出す
        cut -d, -f4,5                                 |
        # 距離計算本体 (総距離)
        $(dirname $0)/../bin/calc-station-distance.rb
    )"

    # 出力
    (
        IFS=,
        set -- $opcode
        # $1: 系統記号, $2: 日中運用区分, $3: 車両形式, $4: 両数
        if [ "$2" = "" ]; then
            # echo "$1 : $3形 $4両   運用距離: $distance km"
            echo "<h4>$1</h4>"
            echo "<p>$3形$4両 運用距離 : $distance km</p>"
        else
            # echo "$1 (日中運用 $2) : $3形 $4両   運用距離: $distance km"
            echo "<h4>$1 (日中運用 $2)</h4>"
            echo "<p>$3形$4両 運用距離 : $distance km</p>"
        fi
    )

    # HTML構造出力
    echo "<table>"
    echo "<tr><th>列車番号</th><th>種別</th><th colspan=\"2\">始発</th><th colspan=\"2\">終着</th><th>備考</th></tr>"

    cat $tmp_prefix-operation-table  |
    tr -d ' '                        |
    sed 's;,;</td><td>;g'            |
    sed 's;.*;<tr><td>&</td></tr>;g'

    echo "</table>"
done
# *****************************************************

on_exit 0
