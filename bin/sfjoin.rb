#!/usr/bin/env ruby
# frozen_string_literal: true

# sfjoin.rb
# Sort-Free Join Command
# データ行のソート無しで2つのテキストファイルを指定したフィールドで結合する
#
# Usage
#     ruby sfjoin.rb [options] FILE1 FILE2
# 引数
#     FILE1            結合するファイル1
#     FILE2            結合するファイル2
#     FILE1に - を指定すると、標準入力から読み込む
# オプション
#     -m JOIN_METHOD   結合の種類
#             'INNER'  内部結合 (デフォルト)
#             'LOUTER' 左外部結合
#     -1 FIELD         FILE1の結合キー (列番号で指定)
#     -2 FIELD         FILE2の結合キー (列番号で指定)
#     -t CHAR          フィールド区切り
#     -e EMPTY         空白フィールドを置き換える文字列
#     -j FIELD         '-1 FIELD -2 FIELD'と同値
# 出力
#     列の出力は、まずFILE1の全列を出力し、FILE2のうち結合キー列を除く全列を、
#     ファイル中に記載した順序で出力する。
# 注記
#     *1  FILE2の全行をメモリに載せるため、FILE2のサイズは小さい方が良い
#        (FILE1は1行ずつ処理するため、理論上どのようなサイズであっても良い)

require 'optparse'

Version = '1.0.0'

# コマンドラインオプション解析
join_method = 'INNER'   # デフォルトは内部結合
joinkey_file1 = 1       # デフォルトはFILE1の1列目で照合
joinkey_file2 = 1       # デフォルトはFILE2の1列目で照合
delimiter = ' '         # デフォルトは半角空白
empty_field_str = ''    # デフォルトは空文字列

opts = OptionParser.new do |o|
  o.banner = "Usage: join.rb [options] FILE1 FILE2\n" \
             'FILE1とFILE2を指定したフィールドで結合する。'
end
opts.on('-m METHOD',
        "結合方法を指定する。'INNER'の場合は内部結合、'LOUTER'の場合は左外部結合である。" \
        '省略時は内部結合。') { |v| join_method = v }
opts.on('-e EMPTY', 'フィールドが空の場合、EMPTYで指定した文字列で置き換える。') { |v| empty_field_str = v }
opts.on('-j FIELD', Integer, "'-1 FIELD -2 FIELD'と同値。") { |v| joinkey_file1 = joinkey_file2 = v }
opts.on('-t CHAR', '区切り文字としてCHARを用いる。省略時は半角空白。') { |v| delimiter = v }
opts.on('-1 FIELD', Integer, 'FILE1のFIELD番目のフィールドを使用して結合する。')  { |v| joinkey_file1 = v }
opts.on('-2 FIELD', Integer, 'FILE2のFIELD番目のフィールドを使用して結合する。')  { |v| joinkey_file2 = v }
opts.parse!(ARGV)

filename_file1 = ARGV.shift
filename_file2 = ARGV.shift
file2_columns_count = 0

# FILE1, FILE2のいずれか一方に "-" (標準入力) が指定されているかどうかの判定
# 両方指定されている場合はエラー
if filename_file1 == '-'
  if filename_file2 == '-'
    warn 'E: 標準入力が指定できるのはFILE1, FILE2のいずれか一方のみです。'
    exit 1
  end
  file1 = STDIN
  file2 = File.open(filename_file2, 'r')
else
  if filename_file2 == '-'
    file2 = STDIN
  else
    file2 = File.open(filename_file2, 'r')
  end
  file1 = File.open(filename_file1, 'r')
end

# FILE2の方のデータは全部メモリに載せる
file2_contents = {}
file2.each do |line2|
  # 空要素にはNULLという文字列を入れておく
  elem2_array = line2.chomp.split(delimiter, -1)
  elem2_array.map! { |e| e == '' ? empty_field_str : e }

  key = elem2_array[joinkey_file2 - 1]
  elem2_array.delete_at(joinkey_file2 - 1)
  file2_contents[key] = elem2_array
  file2_columns_count = elem2_array.length
end
file2.close

# 左外部結合のとき、FILE2にない場合の空白を埋める文字列
FILE2_NULL_ROW = Array.new(file2_columns_count, empty_field_str)

# FILE1を1行ずつ読んで、FILE2のキーを結合する
file1.each do |line1|
  output = []

  # 空要素にはNULLという文字列を入れておく
  file1_row_array = line1.chomp.split(delimiter, -1)
  file1_row_array.map! { |e| e == '' ? empty_field_str : e }

  file2_row_array = file2_contents[file1_row_array[joinkey_file1 - 1]]

  # 内部結合の場合、一方に存在しないキーの行は除外
  # 左外部結合の場合、存在しないフィールドはNULLとする
  if file2_row_array.nil?
    next if join_method == 'INNER'

    file2_row_array = FILE2_NULL_ROW if join_method == 'LOUTER'
  end

  output.concat(file1_row_array)
  output.concat(file2_row_array)

  puts output.join(delimiter)
end

file1.close
