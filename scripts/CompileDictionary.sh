#!/usr/bin/bash

# ====================================================================
# Copyright (C) 1999-2008 Carnegie Mellon University and Alexander
# Rudnicky. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# This work was supported in part by funding from the Defense Advanced
# Research Projects Agency and the National Science Foundation of the
# United States of America, and the CMU Sphinx Speech Consortium.
#
# THIS SOFTWARE IS PROVIDED BY CARNEGIE MELLON UNIVERSITY ``AS IS'' AND
# ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY
# NOR ITS EMPLOYEES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ====================================================================
#
#
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
