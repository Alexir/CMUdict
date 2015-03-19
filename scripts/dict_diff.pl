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
# given a dict and a word list, output words from the list that are not
# in the dict
# [20150120] (air)
#

use strict;
use Getopt::Long;
$|=0;

my ( %wlist,%dict,%oov);
my ($entry,$word,$pron);

my ($wordfile,$outfile,$dictfile);
GetOptions("words=s" => \$wordfile,
	   "dict=s"  => \$dictfile,
	   "out=s" => \$outfile);
if ( not defined $wordfile or
     not defined $dictfile or
     not defined $outfile ) {
    die("usage: winnow_dict -w <wordfile> -d <dictfile> -o <outfile>\n");
}

open(DICT,$dictfile) ||die("$dictfile not found!\n");
open(WORD,$wordfile) ||die("$wordfile not found!\n");

# read in the dict
my $d = 0;
while (<DICT>) {
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    if ( /^;;;/ ) { next; }  # ignore all comments in this pass
    my $line = $_;
    if ( $line  =~ /^\s*$/ ) { next; }  # empty lines allowed

    # get the head term and the pronunciation, remember word
    ($word,$pron) = split (/\s+/,$line,2);
    $dict{$word} = 1;
    $d++;
}
close(DICT); print STDERR "dict read, $d words\n";

# get the wordlist
print STDERR "word list will be up-cased!\n";
while (<WORD>) {
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    my $w = uc $_;
    $wlist{$w} = 1;
    if ( not defined $dict{$w} ) { $oov{$w} = 1; }
}
close(WORD);

open(OUT,">",$outfile)  || die "can't output!\n";
my $c;
foreach my $w ( sort keys %oov ) {
    print OUT "$w\n";
    $c++;
}
close(OUT);

print STDERR "found $c oov words.\n";

#
