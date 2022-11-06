#!/usr/bin/awk -f
# trainslate-to-latex.awk
# 時刻表をLaTeXソースコードに変換する
# 外部から与えられる変数
#     trains_per_page : 1ページあたりの列車数

BEGIN {
    FS = ","
    OFS = ","
}

# 最終ページにおいて、1ページすべてが埋まらない場合は
# 残りを空白または時刻無表示表記で埋める
# 列車番号・種別（注記）・行先欄の題字はセル2つ結合
# また、他のセルは空白
NR >= 1 && NR <= 3 {
    $1 = "\\multicolumn{2}{|c|}{" $1 "}"
    for (i = NF + 1; i <= trains_per_page + 1; i++) {
        $i = " "
    }
}

# 1行目（列車番号）は渡されてきたまま出力
NR == 1 {
    print $0 "\\\\ \\hline"
    next
}

# 2行目（種別注記）は注記と種別に行を分離する
NR == 2 {
    remark_line = $0
    train_type_line = $0
    remark_line = gensub(/普通|急行|特急|観光|回送/, "", "g", remark_line)
    remark_line = gensub(/ワンマン/, "\\\\onemanmark", "g", remark_line)
    remark_line = gensub(/※/, "\\\\\\exph", "g", remark_line)
    remark_line = gensub(/▲/, "\\\\\\expj", "g", remark_line)
    remark_line = gensub(/○/, "\\\\\\expk", "g", remark_line)
    remark_line = gensub(/種別/, "注記", "g", remark_line)
    train_type_line = gensub(/[○▲※]/, "", "g", train_type_line)
    train_type_line = gensub(/普通/, "", "g", train_type_line)
    train_type_line = gensub(/急行/, "\\\\expmark", "g", train_type_line)
    train_type_line = gensub(/特急/, "\\\\ltdexpmark", "g", train_type_line)
    train_type_line = gensub(/ワンマン/, "", "g", train_type_line)
    print remark_line " \\\\"
    print train_type_line " \\\\"
    next
}

# 3行目（行先）は均等割付タグを指定
NR == 3 {
    for (i = 2; i <= trains_per_page + 1; i++) {
        $i = "\\destination{" $i "}"
    }
    print $0 " \\\\ \\hline"
    next
}

NR >= 4 && NR <= 67 {
    gsub(/\|\|/, "\\notthrough")
    gsub(/↓/, "\\pass")
    for (i = NF + 1; i <= trains_per_page + 1; i++) {
        $i = "\\timetspace"
    }

    # 太宰府線と甘木線の区切りのために罫線を引くべき駅
    if ($1 ~ /^太宰府_着|^甘木_着|^味坂_〃|^紫_〃/) {
        border_bottom = 1
    }

    # 一文字駅名を中央に配置するため、前後に空白を入れて均等揃えタグでかこむ
    if ($1 ~ /^紫|^開/) {
         gsub(/^紫_/, "　紫　_", $1)
         gsub(/^開_/, "　開　_", $1)
    }

    # 着発表示をする主要駅の着側で、駅名を2行にまたがって表示する措置
    if ($1 ~ /大橋_着|春日原_着|二日市_着|筑紫_着|小郡_着|宮の陣_着|久留米_着|花畑_着|大善寺_着|柳川_着/) {
        split($1, staname, "_")
        $1 = "\\multirow{2}{*}{\\station{" staname[1] "}}," staname[2]
        for (i = 2; i <= trains_per_page + 1; i++) {
            if ($i == "") {
                $i = "\\timetspace"
            }
        }

        print $0 " \\\\"
        # 着発時刻間に線を引くよう指定
        print "\\cline{2-22}"
        next
    }

    # 着発表示をする主要駅の発側で、駅名を省略
    if ($1 ~ /大橋_発|春日原_発|二日市_発|筑紫_発|小郡_発|宮の陣_発|久留米_発|花畑_発|大善寺_発|柳川_発/) {
        $1 = ",発"
        for (i = 2; i <= trains_per_page + 1; i++) {
            if ($i == "") {
                $i = "\\timetspace"
            }
        }
        print $0 " \\\\"
        next
    }

    # 太宰府線・甘木線で背景を灰色にすべき駅の指定
    if ($1 ~ /五条|太宰府|北野|本郷|^甘木/) {
        gray_row = 1
     }

    split($1, staname, "_")

    $1 = "\\station{" staname[1] "}," staname[2]
    for (i = 2; i <= trains_per_page + 1; i++) {
        if ($i == "") {
            $i = "\\timetspace"
        }
    }

    $0 = $0 " \\\\"

    # 太宰府線と甘木線の区切りのために罫線を引くべき駅
    if (border_bottom == 1) {
        $0 = $0 " \\hline"
        border_bottom = 0
    }
    if (gray_row == 1) {
        $0 = "\\grayrow " $0
        gray_row = 0
    }
    print
}
