#!/bin/bash

bin/sfjoin.rb -t, -j 1 -m LOUTER bin/station_list_for_timetable.txt \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday G111) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday 8111) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday 4111) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday G113) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday 2111) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday 7511) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday G115) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday 8113) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday 4113) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday G117) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday 2113) |
bin/sfjoin.rb -t, -j 1 -m LOUTER - \
    <(bin/make-timetable-book-each-train.sh db20210313 weekday 7513)
