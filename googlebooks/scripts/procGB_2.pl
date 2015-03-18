#!/usr/bin/perl
# process a file of googlebooks 1-grams
# [20150227] (air)
#
# -- extract counts, collapsed over all years
# -- extract baseforms (everything up to a _POS tag)
#
# Purpose: 
# develop a list of legitimate words that can be used to filter
# cmudict/lmtool OOVs for tokens to manually examine.
# weakness is that googlebooks ngram only go up to 2009 or so.
#



use strict ;
use warnings ;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;
use Getopt::Long;
$|=1; # autoflush

my $sink = "results";
my $file = "";
my $alph = "";
my $years = 1040;  # Bin Sheng invents movable type; GoogleBooks starts ~1840
GetOptions (
    "file=s" => \$file,   # the compressed file from google
    "alph=s" => \$alph,   # the head letter (of the file name)
    "years:i" => \$years  # cutoff date (use .ge. of years)
    );

# get a handle for the data file
my $z = new IO::Uncompress::Gunzip $file
    or die "IO::Uncompress::Gunzip failed-->  $GunzipError\n";


my %words = ();
my %baseform = ();
my %annot = ();

my $count = 0;
my $wcnt  = 0;
my $bcnt  = 0;
my $skip  = 0;

# read each entry and get token, baseform, affix
open(OUTS,">","$sink/$alph.skipped") or die " arglgh!...\n";
while (<$z>) {
    chomp;
    $count++;
    if ( ($count%1000000) eq 0 ) { print "."; } # heartbeat
    (my $token, my $year, my $words, my $vols) = split /\t/;

    # filter out apparent oddities (non-printing chars)
    if ( !($token =~ /[[:graph:]]/) ) {  #  glyphs (still too much)
	$skip++;
	print OUTS join( "\t",$token,$year,$words,$vols),"\n";
	next;
    }

    # apply year fence; only entries later that 'year' are counted
    if ( $year lt $years) { next; }

    # count up tokens
    if ( ! defined $words{$token} ) {
	$words{$token} = $words; # count up instances (word + POS)
	$wcnt++;
    } else {
	$words{$token} += $words;
    }

    # extract baseform words (some entries are annotated, some are not.)
    # baseform: no _POS affix + upcased
    my $base= "";
    my  $ann = "";
    if ( $token =~ /_/ ) {
	$token =~ /^(.+)_(.*)$/;
	$base = uc ( $1 );  ############ uc everything!
	$ann = $2;
    } else {
	$base = uc ( $token );   ############ uc everything!
	$ann = "";
    }
    if ( ! defined $baseform{$base} ) {
	$baseform{$base} = $words;    # count up baseforms
	$bcnt++;
    } else {
	$baseform{$base} += $words;
    }

    # inventory the markers
    if ( ! defined $annot{$ann} ) {
	$annot{$ann} = 1;
    } else {
	$annot{$ann}++;
    }
}
close(OUTS);
print "\n";

# print tokens and counts, also thresholded lists
# use count cutoffs to limit list sizes
my $cutA = 10000;
my $cutB = 100000;
my $cutC = 1000000;
open(OUT, ">","$sink/$alph.word");
open(OUTA,">","$sink/$alph.word_$cutA");
open(OUTB,">","$sink/$alph.word_$cutB");
foreach my $w ( sort keys %words ) {
    print OUT "$w\t$words{$w}\n";
    if ( $words{$w} >= $cutA ) { print OUTA "$w\t$words{$w}\n"; }
    if ( $words{$w} >= $cutB ) { print OUTB "$w\t$words{$w}\n"; }
}
close(OUT); close(OUTA); close(OUTB);

# perint baseforms, with counts (case-insensitive, no POS info)
open(OUTC, ">","$sink/$alph.base");
open(OUTCA,">","$sink/$alph.base_$cutB");
open(OUTCB,">","$sink/$alph.base_$cutC");
foreach my $w ( sort keys %baseform ) {
    print OUTC "$w\t$baseform{$w}\n";
    # the following are versions of: (smarter to use the awk thing tho)
    #     $> awk '{if ( $2 > 1000000 ) { print $0; }}' 
    if ( $baseform{$w} >= $cutB )  { print OUTCA "$w\t$baseform{$w}\n"; }
    if ( $baseform{$w} >= $cutC )  { print OUTCB "$w\t$baseform{$w}\n"; }
}
close(OUTC); close(OUTCA); close(OUTCB);

# print affixes, but only the reasonably common ones
open(OUTP,">","$sink/$alph.annotations") or die "no can open P\n";
foreach my $a ( sort keys %annot ) {
    if ( $annot{$a} < 2000 ) { next; }    # lotsa junk; set a floor
    print OUTP "$a\t$annot{$a}\n";
}
close(OUTP);


# log some stats
print "------------------\n";
print "$alph\ttokens\t$count\n";
print "$alph\twords\t$wcnt\n";
print "$alph\tbase \t$bcnt\n";
print "$alph\tskipped\t$skip\n";

##
#

