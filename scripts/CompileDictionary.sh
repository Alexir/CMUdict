#!/usr/bin/bash
# [20080422] (air) Compile cmudict into SPHINX_40 form
# [20100118] (air)
# [20141225] (air) some house keeping

if [ "$#" -eq 0 ] ; then echo "usage: CompileDictionary <dictname>"; exit 1; fi
DIR=sphinxdict
DICT_BASE=cmudict

DICTIONARY=$1  # note that this hard-coded; update as versions creep up.
if [ ! -e $DICTIONARY ] ; then echo "can't find $DICTIONARY"; exit 1; fi

echo "Compiling $DICTIONARY"; echo ""

# make_baseforms.pl removes stress marks and eliminates resulting duplicates
echo "Collapse stress information..."
perl ./scripts/make_baseform.pl $DICTIONARY $DIR/$$_SPHINX_40
echo "" 


echo "Do final cmudict_SPHINX check... "
if ./scripts/test_dict.pl -p $DIR/SphinxPhones_40 $DIR/$$_SPHINX_40
then
    cp -p $DIR/$$_SPHINX_40 $DIR/${DICT_BASE}_SPHINX_40
    cp -p $DIR/$$_SPHINX_40 $DIR/${DICTIONARY}_SPHINX_40
    echo "Dictionary successfully compiled"
else
    if [ -e $DIR/${DICT_BASE}_SPHINX_40 ] ; then rm $DIR/${DICT_BASE}_SPHINX_40 ; fi
    if [ -e $DIR/${DICTIONARY}_SPHINX_40 ] ; then  rm $DIR/${DICTIONARY}_SPHINX_40 ; fi
    echo ""
    echo "$0 encountered errors"
    echo "DICTIONARY COMPILATION NOT COMPLETED"
    exit
fi
echo ""

rm $DIR/$$_SPHINX_40
echo "Done."

#
