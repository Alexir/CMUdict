#!/usr/bin/perl -w
#
# compare a wordlist (1st field) to given cmudict; show exceptions
# [20150315] (air)
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
    die("usage: compare -w <wordfile> -d <dictfile> -o <outfile>\n");
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
    $dict{$word} = $pron;
    $d++;
}
close(DICT); print STDERR "dict read, $d words\n";

# get the wordlist
my $wc = 0;
while (<WORD>) {
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    my $w = uc $_;
    ($word, my $dum) = split(/\t/,$_,2);
    $wlist{$word} = $dum;
    $wc++;
    if ( not defined $dict{$word} ) { $oov{$word} = $dum; }
}
close(WORD);
print STDERR "$wc words in list (words will be upcased)\n";

# find wordlist words not in dict
open(OUT,">",$outfile)  || die "can't output!\n";
my $c = 0;
foreach my $w ( sort keys %oov ) {
    print OUT "$w\t$oov{$w}\n";
    $c++;
}
close(OUT);

print STDERR "found $c oov words.\n";

#
