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
GetOptions (
    "file=s" => \$file,   # the compressed file from google
    "alph=s" => \$alph,   # the head letter (of the file name)
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
    my @line = split /\t/;

    # filter out apparent oddities (non-printing chars)
    if ( !($line[0] =~ /[[:graph:]]/) ) {  #  glyphs (still too much)
	$skip++;
	print OUTS join "\t",@line,"\n";
	next;
    }

    # count up tokens, ignoring years
    if ( ! defined $words{$line[0]} ) {
	$words{$line[0]} = $line[2]; # count up instances (word + POS)
	$wcnt++;
    } else {
	$words{$line[0]} += $line[2];
    }

    # extract baseform words (some entries are annotated, some are not.)
    # baseform: no _POS affix + upcased
    my $base= "";
    my  $ann = "";
    if ( $line[0] =~ /_/ ) {
	$line[0] =~ /^(.+)_(.*)$/;
	$base = uc ( $1 );  ############ uc everything!
	$ann = $2;
    } else {
	$base = uc ( $line[0] );   ############ uc everything!
	$ann = "";
    }
    if ( ! defined $baseform{$base} ) {
	$baseform{$base} = $line[2];    # count up baseforms
	$bcnt++;
    } else {
	$baseform{$base} += $line[2];
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
# these are not directly useful, but are collapse over years
open(OUT, ">","$sink/$alph.word");
open(OUTA,">","$sink/$alph.word_1000");
open(OUTB,">","$sink/$alph.word_10000");
foreach my $w ( sort keys %words ) {
    print OUT "$w\t$words{$w}\n";
    if ( $words{$w} >= 1000 )  { print OUTA "$w\t$words{$w}\n"; }
    if ( $words{$w} >= 10000 ) { print OUTB "$w\t$words{$w}\n"; }
}
close(OUT); close(OUTA); close(OUTB);

# perint baseforms, with counts (case-insensitive, no POS info)
open(OUTC, ">","$sink/$alph.base");
open(OUTCA,">","$sink/$alph.base_1000");
open(OUTCB,">","$sink/$alph.base_10000");
foreach my $w ( sort keys %baseform ) {
    print OUTC "$w\t$baseform{$w}\n";
    # the following are versions of: (smarter to use the awk thing tho)
    #     $> awk '{if ( $2 > 1000000 ) { print $0; }}' 
    if ( $baseform{$w} >= 1000 )   { print OUTCA "$w\t$baseform{$w}\n"; }
    if ( $baseform{$w} >= 10000 )  { print OUTCB "$w\t$baseform{$w}\n"; }
}
close(OUTC); close(OUTCA); close(OUTCB);

# print affixes, but only the reasonably common ones
open(OUTP,">","$sink/$alph.annotations") or die "no can open P\n";
foreach my $a ( sort keys %annot ) {
    if ( $annot{$a} < 5000 ) { next; }    # lotsa junk; set a floor
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

