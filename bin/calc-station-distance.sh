#!/bin/bash

# calc-station-distance.sh
# 列車折り返しがある駅間の距離を計算する

cat $1     |
xargs -IXXX bin/calc-station-distance-main.rb XXX |
paste -d, $1 -
