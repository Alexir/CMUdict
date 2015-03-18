#!/bin/bash
# launch a bunch of googlebook extractions
# [20150227] (air)
#

alph="a b c d e f g h i j k l m n o p q r s t u v w x y z"
stub="googlebooks-eng-all-1gram-20120701"

for x in $alph ; do
    echo $x
    nohup ./processGBooks.pl -f data/${stub}-${x}.gz -a $x &> ${x}.log &
done

#
