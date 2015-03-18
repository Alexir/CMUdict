#!/usr/bin/perl -w
#
# filter cmudict.tool log into a more compact form, highlighting OOVs
#
# [20150126] (air)
#

use strict;
use Getopt::Long;
$|=0;

my $VERBOSE = 0;

# assume that this is run in candidates/cmudict-log/ as ../scripts/filter.pl <...>
my $infil = "dict_access.log";
my $stub = "keep";
my $dictfile = "../../cmudict-0.7b";
my $oovlist = "OOVlist";
GetOptions("infile=s" => \$infil,
	   "stub=s" => \$stub,
	   "dict=s" => \$dictfile,
	   "oovlist=s" => \$oovlist,
    ) or die "usage: filter -i logfile -d dictionary -s outfilestub\n";

# read in the dict. NOTE: assumes the dict is in correct format!
print STDERR "reading dict... ";
my %CMUdict = ();
my $tok;
open(DICT,"<",$dictfile) or die "can't open $dictfile!\n";
while (<DICT>) {
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    if ( /^;;;/ ) { next; }  # ignore all comments in this pass
    my $line = $_;
    if ( $line  =~ /^\s*$/ ) { next; }  # empty lines allowed

    # split word/pron
    (my $word,my $pron) = split (/\s+/,$line,2);
    $CMUdict{$word}++;
   
    # focus on the word; check variant suffix
    my ($ortho, $var);
    if ( $word =~ /^[\(\)]/ ) {  # ignore 1st char if it's a paren
	$tok = substr $word, 1;  # a hack: this isn't right...
    } else { $tok = $word; }

    # got var? Note it (should end up with the largest number, ie count-1)
    if ($tok =~ /^(.+?)\(\d+\)$/) {
	($ortho, $var) = ($tok =~ /^(.+?)\((\d+)\)$/);
	$CMUdict{$ortho} = $var;
    } else {
	$CMUdict{$tok} = 0;
    }
}
close(DICT);
print "done\n";

print STDERR "processing log ";
open(IN,"<",$infil);
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
my $date = sprintf("%04d%02d%02d_%02d%02d", ($year+1900),($mon+1),$mday,$hour,$min);
open(KEEP,">",$stub) or die "can't open log file...";

my $start = "";  my $end = "";
my $cnt = 0; my $oov = 0;
my ($in, $pron);
my %OOVlist = ();

# process the log file  [2015014 version: no empty line in wordset, tab delimiters]
while (<IN>) {
    s/[\r\n]*$//;

    if ( $_ eq "" ) { next; }

    if ( /^---/ ) {  # audit line (daytime, etc)
	(my $duma, my $dumb, my $daytime) = split /\t/;
	if ( $start eq "" ) {
	    $start = $end = $daytime;
	} else {     $end = $daytime; }

	$in = <IN>;    $in   =~  s/[\r\n]*$//;  # what the user typed
	$pron = <IN>;  $pron =~  s/[\r\n]*$//;  # what the system replied

	$cnt += 1;
	if ( $pron =~ /^\?/ ) {  # is it OOVish?
	    $in =~ s/^\s*//;  # remove annoying leading space

	    # input line may have multiple words, split entered string by spaces
	    my @words = split /\s+/, $in;
	    foreach my $w (@words) {
		if ( ($cnt % 100) eq 0 ) {print STDERR ".";}

		# for some reason people add quotes around words
		$w =~ /["' ]*(.+?)["'. !?]*$/;  # also, trailing periods... 
		$w = $1; 
		if ( defined $CMUdict{uc $w} ) { next; } # already in dict, skip it
		printf KEEP "%-12s\t%s\n", $w,$pron;  # keep the primary entry
		if ( $w =~ /[0-9]/ ) { next; }  # ignore numbers
		$OOVlist{uc $w} = $pron;  # keep the residue
		$oov += 1;
		if ($VERBOSE) {  # an actual oov! red it!
		    printf STDOUT "[0;31m%-12s[0m\t%s\n", $in,$pron;
		}
	    }
	}

    } elsif ( $in eq "C M U Dictionary" ) {
	if ($VERBOSE) { print STDOUT "------\n"; }  # it's the default example; ignore

    } else {
	if ($VERBOSE) { printf STDOUT "%-12s\t%s\n", $in,$pron; } # just a regular word
    }
}
close(IN);
close(KEEP);
print STDERR " done\n";

# write file of uniq'd oov words
open(OOV,">",$oovlist);
foreach my $word (sort keys %OOVlist) {
    print OOV "$word\n";
}
close(OOV);

print STDERR "FROM $start\n  TO $end\n";
printf STDERR "%d words, %d new words (%.1f%%)\n", $cnt,$oov, ($oov * 100.0)/$cnt;

#
