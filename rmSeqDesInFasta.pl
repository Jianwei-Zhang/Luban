#!/usr/bin/perl -w
use strict;
use Bio::SeqIO;
print "Please input sequence file:";
chop(my $infile=<STDIN>);

print "Please output sequence file:";
chop(my $output=<STDIN>);
open (OUTPUT, ">$output");
my $starttime=time();
	my $in = Bio::SeqIO->new(-file => $infile,
	    					-format => 'Fasta');
	while ( my $seq = $in->next_seq() )
	{
		print OUTPUT ">",$seq->id,"\n",$seq->seq,"\n";
	}
close (OUTPUT);
my $endtime=time();
my $totaltime=$endtime-$starttime;
print "Completed! (in $totaltime s)\n";