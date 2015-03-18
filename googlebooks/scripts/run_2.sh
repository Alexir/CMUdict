#!/bin/bash
# launch a bunch of googlebook extractions
# [20150227] (air)
#

alph="a b c d e f g h i j k l m n o p q r s t u v w x y z"
stub="googlebooks-eng-all-1gram-20120701"

year=1970

echo "|------------------>  collating for year >= $year"
for x in $alph ; do
    echo $x
    nohup ./scripts/procGB_2.pl \
	-f data/${stub}-${x}.gz \
	-a ${x}_${year} \
	-y $year \
	&> logs/${x}_${year}.log &
done

#
