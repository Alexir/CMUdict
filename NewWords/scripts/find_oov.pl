#!perl -w
#
# for a specified dictionary and a log of pronounce.exe 
# determine which words are OOV
# [20141122] (air) Created
# -- to identify words that should be in a dict update
#

use strict;
use Getopt::Long;

my %dict = ();
my %oov  = ();
my ($word, $pron, $tok, $unk);

my ($pronlogfile,$dictfile);
GetOptions("pronlog=s" => \$pronlogfile, "dict=s"  => \$dictfile)
    or die("usage: test_cmudict -p <pronlogfile> -d <dictfile>\n");


# read in the dict. NOTE: assumes the dict is in correct format!
open(DICT,"<",$dictfile) or die "can't open $dictfile!\n";
while (<DICT>) {
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    if ( /^;;;/ ) { next; }  # ignore all comments in this pass
    my $line = $_;
    if ( $line  =~ /^\s*$/ ) { next; }  # empty lines allowed

    # split word/pron
    ($word,$pron) = split (/\s+/,$line,2);
    $dict{$word}++;
   
    # focus on the word; check variant suffix
    my ($ortho, $var);
    if ( $word =~ /^[\(\)]/ ) {  # ignore 1st char if it's a paren
	$tok = substr $word, 1;  # a hack: this isn't right...
    } else { $tok = $word; }

    # got var? Note it (should end up with the largest number, ie count-1)
    if ($tok =~ /^(.+?)\(\d+\)$/) {
	($ortho, $var) = ($tok =~ /^(.+?)\((\d+)\)$/);
	$dict{$ortho} = $var;
    } else {
	$dict{$tok} = 0;
    }
}
close(DICT);

# process the pron log file (which should have been excerpted)
open(PRONLOG,"<",$pronlogfile) or die "can't open $pronlogfile!\n";
while (<PRONLOG>) {
    s/[\r\n]*$//;  # deal with dos/unix/ios annoyance
    my ($source,$word);
    ($source,$word) = (/(.+?):(.+?) /);
    if (defined $dict{$word}) { next; }  # skip known words

    # it's an OOV, note and count
    elsif (not defined $oov{$word}{'WORD'}) {
	$oov{$word} = {'WORD'=>$word, 'COUNT'=>0, 'EXAMPLE'=>$source,}
    } else {
	$oov{$word}{'COUNT'}++;
    }
}
close(PRONLOG);

# look for actual oovs; produce a list suitable to lookups
foreach my $w (keys %oov) {
    if (defined $dict{$w}) {
	# print "+ $w\n";   # note in-vocab words
    } else {
	print "$w\n";
	$unk++;
    }
}
print STDERR "\n$unk unknowm words\n";

#
