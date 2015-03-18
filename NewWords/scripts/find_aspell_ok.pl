#!perl

# given two word lists: one raw and one nixed by aspell get the words ok'd by aspell
# of course the source doesn't have to be aspell.
# think Venn diagram... 
# These become candidates for addition.
# [20141123] (air) Created.
# 

use strict;
use Getopt::Long;

my %dic = ();  # the dictionary
my %raw = ();  # original list of oov words, from log
my %nix = ();  # words that aspell (or somebody) doesn't like
my %out = ();  # resulting "true" oov candidate words
my $scrub = '';  # do extra cleaning?
my $word;

my ($dicfile,$rawfile,$nixfile,$outfile);
GetOptions("raw=s"=>\$rawfile,
	   "nix=s"=>\$nixfile,
	   "outfile=s"=>\$outfile,
	   "dict=s"=>\$dicfile,
	   "scrub"=>\$scrub,
    )
    or die("usage: test_cmudict -d <dict> -r <raw> -n <nix> -o <out>\n");

open(RAW,"<",$rawfile) or "can't open $rawfile!\n";
open(NIX,"<",$nixfile) or "can't open $nixfile!\n";
open(OUT,">",$outfile) or "can't open $outfile!\n";
open(DIC,"<",$dicfile) or "can't open $dicfile!\n";

# get the words
while(<RAW>) { s/[\r\n]*$//;  my @iraw = split;  $raw{$iraw[0]} = 0; }
while(<NIX>) { s/[\r\n]*$//;  $nix{$_} = 0; }
# get the dict
while(<DIC>) {
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    if ( /^;;;/ ) { next; }  # ignore all comments in this pass
    my $line = $_;
    if ( $line  =~ /^\s*$/ ) { next; }  # empty lines allowed
    (my $word,my $pron) = split (/\s+/,$line,2);
    $dic{$word}++;
}

my $neww = 0;
# find the compliment (non-nixed words, not in dict)
foreach my $word (keys %raw) {
    if ( defined $nix{$word} ) { next; } #it's been nixed
    elsif ( defined $dic{$word} ) { next; } #already in the current dic
    else { 
	$out{$word}=0;  # a "good" word, ok'd by spell checker
    }
}

if ( $scrub ) { print STDERR "applying additional scrubbing\n"; }
foreach my $word (sort keys %out) {

    #  some additional filtering to remove bogus items
    if ( $scrub ) {
	# ignore the non-ascii words
	if ( $word =~ /[[:^ascii:]]/ ) { next; }
	# double quotes, parens, brackets are superfluous, I think
	$word =~ s/[\(\)\["\?]//g;   
	# remove entries with otherwise weird characters
	if ( not ($word =~ m/[A-Za-z_\-']/g )) { next; }
    }
    
    $neww++;
    $word = uc $word;
    print OUT "$word\n";
}
close(OUT);

print STDERR "$neww new aspell-ok words.\n";

#
