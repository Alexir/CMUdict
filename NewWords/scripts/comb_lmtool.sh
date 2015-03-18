#/bin/bash
#
# diff lmtool log of LtoS words using aspell in different modes
# output those that seem spellable in some variant of en
# [20141221] (air)
# 

if [ $# -ne 1 ] ; then echo "usage: comb_tool <LtoS list>"; exit ; fi
file=$1

export LC_ALL='C'

# pull out the LtoS words
in=comb_lmtool.$$
cat $file |awk '{print $1;}' |sort -u |grep -v LETTER- > $in

# run through successively laxer dicts
aspell  list --ignore=1 -d en --rem-variety=en-variant-0  <$in >mispell.0

# now run each list through the diff filter
# to get list of probably real EN words (well, according to the aspell guy).
./scripts/find_aspell_ok.pl -d ../cmudict-0.7b -r $file \
    --scrub \
    -n mispell.0 \
    -o mispell_0.words

rm $in
#

