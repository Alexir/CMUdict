#!/usr/bin/perl -w

# ====================================================================
# Copyright (C) 1999-2015 Carnegie Mellon University and Alexander
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
# Removes acronyms from the cmudict, to make a g2p training set
# No checking is done. Inputs should have already been proofed!
# [20150110] (air) Created
#

use strict;
use Getopt::Long;
$|=0;

my ( %acron,%dict);
my ($entry,$word,$pron);

my ($acronfile,$trainfile,$dictfile);
GetOptions("acron=s" => \$acronfile,
	   "dict=s"  => \$dictfile,
	   "train=s" => \$trainfile);
if ( not defined $trainfile or
     not defined $dictfile or
     not defined $acronfile ) {
    die("usage: test_cmudict -a <acronfile> -d <dictfile> -t <trainfile>\n");
}

open(DICT,$dictfile) ||die("$dictfile not found!\n");
open(ACRO,$acronfile) ||die("$acronfile not found!\n");

# read in the dict
while (<DICT>) {
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    if ( /^;;;/ ) { next; }  # ignore all comments in this pass
    my $line = $_;
    if ( $line  =~ /^\s*$/ ) { next; }  # empty lines allowed

    # get the head term and the pronunciation, store
    ($word,$pron) = split (/\s+/,$line,2);
    $dict{$word} = $pron;
}
close(DICT); print STDERR "dict read\n";

# read in the acronym set
while (<ACRO>) {
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    if ( /^;;;/ ) { next; }  # ignore all comments in this pass
    my $line = $_;
    if ( $line  =~ /^\s*$/ ) { next; }  # empty lines allowed

    # get the head term and the pronunciation, store
    ($word,$pron) = split (/\s+/,$line,2);
    $acron{$word} = $pron;
}
close(ACRO); print STDERR "acron read\n";

# output training file, with acronyms removed
open(TRAIN,,">",$trainfile) or die "can't open $trainfile to write!\n";
# words will be out of dict order, since dict collation is not standard
# this should not matter for the current use...
foreach my $word (sort keys %dict ) {  
    if ( defined $acron{$word} and defined $dict{$word} ) { next; }
    else { print TRAIN "$word  $dict{$word}\n"; }
}
close(TRAIN);

#
