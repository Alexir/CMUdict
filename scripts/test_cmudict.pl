#!/usr/bin/perl -w

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

# do a sanity check on a dictionary (# of tabs, duplicates)
# this should be done after manual editing and before checking in
#
# [21oct98] (air) Created
# [30oct98] (air) expanded functionality: check for phonetic symbols
# [03feb99] (air) bug fix; added noise symbols to check
# [20010623] (air) added cmd-line flags; word/pron bound now \s+
# [20080422] (air) fixed for DOS eol's, also noisefile now properly optional
# [20090331] (air) *** RENAMED to test_cmudict.pl ***
#                  added tests specific to the raw cmudict

#
# correct dictionary format is:   ^WORD(\(\d\))*\tW ER\d* DD\n$
# 
# - "W ER DD" are symbols from the legal phone set(s)
# - no leading/trailing spaces allowed
# - no duplicates words allowed
# - character collating sequence enforced for baseform
# 
# above spec should cover all (current) consumers of the dictionary file.
# not all conventions checked however (eg, for multiple pronunciations)
#

use strict;
use Getopt::Long;


my ($word, $pron, $tok);
my (%dict, %phone, %class);
my %dicdup = ();
my $haslowercase = 0;
my $problems=0;

my ($phonefile,$symbfile,$dictfile);
GetOptions("phone=s" => \$phonefile, "dict=s"  => \$dictfile);
if ( not defined $phonefile or not defined $dictfile ) {
    die("usage: test_cmudict -p <phonefile> -d <dictfile>\n");
}


# get the legal symbol set (and class label)
open(PH,$phonefile) || die("can't open $phonefile!\n");
while (<PH>) {
    s/[\r\n]*$//;
    /(\w+)\t(\w+)/;
    $phone{$1} = 0;
    $class{$1} = $2;
}
close(PH);

open(DICT,$dictfile) ||die("$dictfile not found!\n");

# go through dict, do tests
%dict = (); my $last = ""; my ($lead, $trail); my $word_cnt = 0;
while (<DICT>) {
    # chomp;  #    s/^\s*(.+?)\s*$/$1/;
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    if ( /^;;;/ ) { next; }  # ignore all comments in this pass
    my $line = $_;
    if ( $line  =~ /^\s*$/ ) { next; }  # empty lines allowed

    # general spacing issues
    ($lead = $_) =~ s/^\s*(.+)/$1/;
    ($trail = $_) =~ s/(.+?)\s*$/$1/;
    if ($line ne $trail) { print "ERROR: trailing space in '$line'!\n"; $problems++; }
    if ($line ne $lead) { print "ERROR: leading space in '$line'!\n"; $problems++; }

    # examine the head term and the pronunciation
    ($word,$pron) = split (/\s+/,$line,2);
    $dict{$word}++;
    if ( $word =~ /[a-z]/ ) {
	$haslowercase++;
	if ( $haslowercase le 5 ) { print "WARN: $word has lower-case\n"; }
    }

    # check tabbing (2 spaces)
    my @line = split (/  /,$line);
    if ( ($line[0] ne $word) or (scalar @line ne 2) ) { 
	print "WARNING: tabbing error (",scalar @line, ") in: $line\n";
	$problems++;
    }

    # check variant suffix
    my $tok = "";
    # note that other than it being a digit, it only has to be unique
    if ( $word =~ /^[\(\)]/ ) {  # ignore 1st char if it's a paren
	$tok = substr $word, 1;  # this isn't right...
    } else { $tok = $word; }
    if ( ($tok =~ /\(/) or ($tok =~ /\)/) ) {
	if ( not ($tok =~ /^.+?\(\d\)$/) ) {
	    print "ERROR: malformed variant tag in '$word'\n"; $problems++;
	}
    }

    # check for duplicate variants
    my ($root,$variant);
    if ($tok =~ /\)$/) { # variant
      ($root,$variant) = ($tok =~ m/(.+?)\((.+?)\)/);
    } else {
      $root = $word;
      $variant = 0;
    }
    if ( defined $dicdup{$root}{$pron} ) {
	print "ERROR: duplicate variants in $root($variant) $pron \n"; $problems++;
    } else {
	$dicdup{$root}{$pron} = 0;
    }

    # check for legal phonetic symbols
    my @sym = split(/\s/,$pron);
    my @errs = ();
    my ($ph,$stress,$tail,$legalV);
    foreach my $s (@sym) {
	if ( $s eq '' ) {
	    print "ERROR: $word has a null phone! (extra space?)\n";
	    next;
	}
	$ph = $stress = $tail = '';
	($ph,$stress,$tail) = ($s =~ /([A-Z]+)([012]*)(.*)$/);
	$|=1;
	#print join( '|', ($s =~ /([A-Z]+)([012]*)(.*)$/)),"\n";
	
	$legalV =  defined $phone{$ph} && ($class{$ph} eq 'vowel') && ($stress ne '') && ($tail eq '');
	if ( not defined $phone{$ph} ) { push @errs, $s; }
	elsif ( $legalV ) { $phone{$s}++; }  # doesn't do anything here, yet
	else { $phone{$s}++; }  # could be a bare vowel...

	if ( $tail ne '' ) { push @errs, $s; }  # junk past the pron
	elsif ( (defined $class{$ph}) and
		($class{$ph} eq 'vowel') and ($stress eq '') ){
	    print "ERROR: $word has a bare phone: $ph\n"; $problems++;
	}
	elsif  ( (defined $class{$ph}) and ($class{$ph} eq 'vowel') and
		 (not (($stress =~ /[012]/) and (length($stress) eq 1)))
	    ) {
	    print "ERROR: $word has bad stress mark: '"."$ph $stress"."'\n"; $problems++;
	}
	elsif ( (defined $class{$ph}) and ($class{$ph} ne 'vowel') and ($stress ne '') ){
	    push @errs, $s; }
    }
    if (scalar @errs ne 0) {
	print "ERROR: $word has unknown phone(s): '".join(' ',@errs)."'\n"; $problems++;
    }


    # word order
    if ( &strip_variant($last) gt &strip_variant($word) ) {
	print "*ERR:\tcollation sequence for $last, $word wrong\n"; $problems++;
	print "\t",&strip_variant($last)," ?? ",&strip_variant($word),"\n";
    }

    # tests passed (or not) keep going
    $word_cnt++;
    $last = $word;
}
close(DICT);

# check for duplicates entries
foreach my $x (keys %dict) {
    if ($dict{$x}>1) {
	print "ERROR: '$x' occurs ", $dict{$x}, " times!\n";
	$problems++;
    }
}

print "\nprocessed $word_cnt words\n";
if ( $haslowercase ne 0 ) { print "$haslowercase entries have lower case\n"; }
if ($problems eq 0) { print "no errors encountered!\n"; }

# print out the phone counts
print "symbol occurence statistics:\n";
$last = "";
my $sum = 0; my $vow = 0;
foreach (sort keys %phone) {
    if ( substr($_,0,2) eq substr($last,0,2) ) { print "\t| "; $vow = 1;}
    elsif ($vow) { print "\t= ",$sum,"\n"; $sum = 0; $vow = 0}
    else { print "\n"; }
    print "$_\t$phone{$_}"; if ($vow) { $sum += int($phone{$_}); }
    $last = $_;
}
print "\n";

#

sub strip_variant {
    my $token = shift;
    my $result = "";
    if ($token =~ /(..*?)\(/) { $result = $1; } else { return $token; }
    return $result;
}

###
