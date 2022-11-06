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

    # 着発表示をする主要駅の着側で、駅名を2行にまたがって表示する措置
    if ($1 ~ /宮の陣_着|久留米_着|花畑_着/) {
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
    if ($1 ~ /宮の陣_発|久留米_発|花畑_発/) {
        $1 = ",発"
        for (i = 2; i <= trains_per_page + 1; i++) {
            if ($i == "") {
                $i = "\\timetspace"
            }
        }
        print $0 " \\\\"
        next
    }

    split($1, staname, "_")

    $1 = "\\station{" staname[1] "}," staname[2]
    for (i = 2; i <= trains_per_page + 1; i++) {
        if ($i == "") {
            $i = "\\timetspace"
        }
    }

    $0 = $0 " \\\\"

    print
}
