# make-timetable-book-latex.sh
# 時刻表の1ページをLaTeXソース形式で出力する
# コマンドライン引数
#     $1: 時刻表（一覧形式）
#     $2: 出力開始位置（m本目から）
#     $3: 出力本数（n本分）

bindir="$(dirname $0)/../bin"

# 出力区間指定
timetable_file="$1"
start_pos="$2"
trains_per_page="$3"
end_pos="$((${start_pos} + ${trains_per_page} - 1))"

cat <<HEADER
\begin{table}[htbp]
HEADER

# ページ柱の出力
# TODO: 偶数ページは左・奇数ページは右に出力
cat <<HASHIRA_L
\begin{minipage}{1.1\zw}
\centering
\printifeven{%
    \pbox<t>[0.8\vsize][l]{\large 西鉄甘木線　<DIA_DAY>ダイヤ　<DIRECTION>}%
}{%
    \pbox<t>[0.8\vsize][l]{ }%
}
\end{minipage}
\hfill
HASHIRA_L

# 時刻表ヘッダの出力
cat <<TT_HEADER
\begin{minipage}{0.92\hsize}
\centering
    \begin{tabular}{|cc|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|wr{2em}|}
        \hline
TT_HEADER

# 時刻表1ページ分本体の出力
cat $timetable_file |
# 1ページに掲載する分を切り出し
cut -d, -f1,${start_pos}-${end_pos}  |
# LaTeXコードへの変換の主要部分
awk -v trains_per_page=${trains_per_page} -f $bindir/translate-to-latex-amagiline.awk |
# 区切り記号（カンマ）を、TeXの表区切り記号である & に置換
sed 's/,/ \& /g' |
# 生成過程で生じる優等列車太字タグの空タグを除去
sed 's/\\trexp{}//g' |
# 生成過程で生じる時刻無表示印への各種タグ適用を排除
sed 's/\\destination{\\timetspace}//g' |
# 行先欄における「福岡(天神)」表記を「福岡」に改める
sed '/行先/s/福岡(天神)/福岡/g' |
# 種別注記・通過・非経由印に優等列車太字タグを適用しようとすると
# エラーが起きるため、太字にしない（タグ除去）
sed 's/\\trexp{\([^0-9A-Z}]*\)}/\1/g'

# 時刻表フッタ出力
cat <<TT_FOOTER
        \hline
        \hline
    \end{tabular}
\end{minipage}
TT_FOOTER

cat <<HASHIRA_R
\hfill
\begin{minipage}{1.1\zw}
\centering
\printifodd{%
    \pbox<t>[0.8\vsize][l]{\large 西鉄甘木線　<DIA_DAY>ダイヤ　<DIRECTION>}%
}{%
    \pbox<t>[0.8\vsize][l]{ }%
}
\end{minipage}
HASHIRA_R

cat <<FOOTER
\end{table}
\clearpage
FOOTER
