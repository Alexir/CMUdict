#!/usr/bin/perl -w
#
# Check for various patterns in the dict
# [20141226] (air) Created.
#
#
use strict;
use Getopt::Long;
$|=0;

my ($word, $pron, $tok);
my (%dict, %phone, %class);

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


###  go through dict, do tests  ####################################
%dict = (); my $last = ""; my ($lead, $trail); my $word_cnt = 0;
while (<DICT>) {
    # chomp;  #    s/^\s*(.+?)\s*$/$1/;
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    if ( /^;;;/ ) { next; }  # ignore all comments in this pass
    my $line = $_;
    if ( $line  =~ /^\s*$/ ) { next; }  # empty lines allowed

    # get the head term and the pronunciation, store
    # need to have the phones in an array, maybe letters
    ($word,$pron) = split (/\s+/,$line,2);

    my @letter = split '', $word;
    $dict{$word}{'LETTER'} = @letter;
    my @phone = split /\s/, $pron;
    $dict{$word}{'PHONE'}  = @phone;

    my @stress = ();
    my @pattrn = ();
    foreach my $ph ( @phone ) {
	if ( $ph =~ /(\d)$/ ) {
	    push @stress, $1;
	    push @pattrn, $1;
	} else {
	    push @pattrn, '.';
	}
    }
    @{$dict{$word}{'STRESS'}} = @stress;
    @{$dict{$word}{'PATTRN'}} = @pattrn;
}
close(DICT);


# make the abstracted patterns
my %pattern = ();
my %patreg =  ();
my %wordpat = ();
my %wordeg  = ();
foreach my $p (sort keys %dict ) {
    my $pat= join "_", @{$dict{$p}{'STRESS'}};
    $pattern{$pat}++;
    push @{$patreg{$pat}{'EG'}}, $p;
    my $wrp = join "", @{$dict{$p}{'PATTRN'}};
    $wordpat{$wrp}++;
    push @{$wordeg{$wrp}{'EG'}}, $p;
    
}


# output stress and patterns and their counts, plus examples
open(STR,">","out.stress") or die "can't open for output!\n";
open(WRD,">","out.pattrn") or die "can't open for output!\n";
my $pad = '';
foreach my $p (sort keys %pattern ) {
    if ( length $p < 8 ) {$pad = "\t\t";} else {$pad = "\t";}
    print STR "$pattern{$p}\t$p$pad";

    for (my $i=0; $i<scalar @{$patreg{$p}{'EG'}}; $i++) {
	print STR "  $patreg{$p}{'EG'}[$i]";
	if ($i > 4 ) { last; }
    }
    print STR "\n";
}
foreach my $p (sort keys %wordpat ) {
    if ( length $p < 8 ) {$pad = "\t\t";} else {$pad = "\t";}
    print WRD "$wordpat{$p}\t$p$pad";

    for (my $i=0; $i<scalar @{$wordeg{$p}{'EG'}}; $i++) {
	print WRD "  $wordeg{$p}{'EG'}[$i]";
	if ($i > 4 ) { last; }
    }
    print WRD "\n";

}
close(STR);
close(WRD);


#
