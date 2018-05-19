#!/usr/local/bin/perl -w
use strict;
use Bio::SeqIO;

print "Please input fasta sequence file name:";
chop(my $infile=<STDIN>);
print "Please type out-file name:";
chop(my $outfile=<STDIN>);
open (OUTPUT,">$outfile.tmp") or die "can't open OUT-FILE(SEQ): $!";
open (OUTPUTAGP,">$outfile.agp") or die "can't open OUT-FILE(AGP): $!";
my $i=1;
my $in = Bio::SeqIO->new(-file => $infile,
	    				-format => 'Fasta');

print OUTPUTAGP "##agp-version 2.0\n";

while ( my $seq = $in->next_seq() )
{
	my $j=1;
	my $seqend=0;
	foreach (split(/([N|n]{20,})/,$seq->seq)) #at least 20 Ns to be a gap
	{
		my $seqstart=$seqend+1;
		$seqend=$seqend + length($_);
		my $seqid = $seq->id."-".sprintf("%05s",$i);
		if($_ =~ /^[N|n]+$/)
		{
			if($j == 1 || $seq->length() == $seqend)
			{
				print OUTPUTAGP $seq->id."\t$seqstart\t$seqend\t$j\tU\t".length($_)."\ttelomere\tno\tna\n";
			}
			else
			{
				print OUTPUTAGP $seq->id."\t$seqstart\t$seqend\t$j\tU\t".length($_)."\tcontig\tno\tna\n";
			}
		}
		else
		{
			next if (length($_) < 1);
			print OUTPUT ">$seqid part-$j of ".$seq->id."\n",MultiLineSeq($_,80);
			print OUTPUTAGP $seq->id."\t$seqstart\t$seqend\t$j\tW\t$seqid\t1\t".length($_)."\t+\n";
			$i++;
		}
		$j++;
	}
}
close (OUTPUT);
close (OUTPUTAGP);

#reformat fasta file
my $intemp = Bio::SeqIO->new(-file => "$outfile.tmp",
						-format => 'fasta');
my $out = Bio::SeqIO->new(-file => ">$outfile.seq",
						-format => 'fasta');
while ( my $seq = $intemp->next_seq() )
{
	$out->write_seq($seq);
}
unlink ("$outfile.tmp");


sub MultiLineSeq
{ #split a long sequence to multi-line
	my ($readSequence, $lineLength) = @_;
	my $multiLineSeq;
	$readSequence =~ s/\s//g;
	for (my $position=0;$position < length($readSequence); $position +=$lineLength)
	{
		$multiLineSeq .= substr($readSequence,$position,$lineLength)."\n";
	}
	return $multiLineSeq;
}
