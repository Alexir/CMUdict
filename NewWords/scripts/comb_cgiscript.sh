#/bin/bash
#
# fetch current log from the server
# [20150221] (air)
# 

#if [ $# -ne 1 ] ; then echo "usage: comb_tool <condensedCGIlog>"; exit ; fi
#file=$1

export LC_ALL='C'

#retrieve the web log file (use compression)
logfile="http://www.speech.cs.cmu.edu/cmudict/dict_access.log"
dat=`date +%Y%j%H%M`  # year/day/hour/min
wget --header='Accept-Encoding: gzip' -nv \
     --output-document=${dat}.tz \
     $logfile
gzip -d -c ${dat}.tz > ${dat}.cgilog
rm ${dat}.tz

# filter down to get only unknown strings (ie not in cmudict)
../scripts/filter.pl \
    -i ${dat}.cgilog \
    -s ${dat}.keep \
    -d ../../cmudict-0.7b \
    -o ${dat}.oov


# run unknown strings through aspell to get its 'non-dict' word list
# .misp has all "mispelled" words (per aspell's dict)
aspell  list --ignore=1 -d en \
    --extra-dicts=en-variant_2 \
    < ${dat}.oov \
    > ${dat}.misp

# remove all .misp words from the .oov file
# in theory, these are bonafide English words (per aspell dict)
../scripts/find_aspell_ok.pl \
    -d ../../cmudict-0.7b \
    -r ${dat}.oov \
    --scrub \
    -n ${dat}.misp \
    -o ${dat}.cands

#


