#!/usr/bin/perl -w
use strict;
use Bio::SeqIO;
use Bio::Seq;

print "Please type CTG Sequence file name:";
chop(my $ctgFile=<STDIN>);

print "Please type AGP file name:";
chop(my $agpFile=<STDIN>);

print "Please type SCF output file name:";
chop(my $outFile=<STDIN>);

my %seq;
my %len;
my $seqfile = Bio::SeqIO->new(-file=>"$ctgFile",-format=>'fasta');
while(my $seqobj = $seqfile->next_seq){
    my ($seqId,$length) = ($seqobj->id,$seqobj->length);
    $seq{$seqId} = $seqobj->seq;
    $len{$seqId} = $length;
}

my $object = '';
my $line = 0;
open AGP,"$agpFile";
open OUT,">$outFile.tmp";
while (<AGP>){
    chomp;
    $line++;
	/^#/ and next;
    my @agpLine = split/\t/;
    if ($object ne $agpLine[0])
    {
        $object = $agpLine[0];
        print OUT ">$object\n";
    }
	if ($agpLine[4] eq 'N' || $agpLine[4] eq 'U') #gaps
	{
    	print OUT 'N'x$agpLine[5],"\n";
    }
    else
    {
		if($len{$agpLine[5]} < $agpLine[6] || $len{$agpLine[5]} < $agpLine[7])
		{
			print "Error (line: $line) found in the AGP file.\n";
			close OUT;
			close AGP;
			unlink ("$outFile.tmp");	
			exit;
		}
		my $sequence = substr($seq{$agpLine[5]}, $agpLine[6] - 1, $agpLine[7] - $agpLine[6] + 1);
		$sequence = reverseComplement($sequence) if($agpLine[8] eq '-');
        print OUT "$sequence\n";
    }
}
close AGP;
close OUT;

#reformat fasta file
my $in = Bio::SeqIO->new(-file => "$outFile.tmp",
						-format => 'fasta');
my $out = Bio::SeqIO->new(-file => ">$outFile",
						-format => 'fasta');
while ( my $seq = $in->next_seq() )
{
	$out->write_seq($seq);
}
unlink ("$outFile.tmp");

sub reverseComplement {
	my $dna = shift;

	# reverse the DNA sequence
	my $revcomp = reverse($dna);

	# complement the reversed DNA sequence
	$revcomp =~ tr/ACGTacgt/TGCAtgca/;
	return $revcomp;
}


