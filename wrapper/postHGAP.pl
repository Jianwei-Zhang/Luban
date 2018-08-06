#!/usr/bin/perl -w
use Bio::SeqIO;
use Getopt::Long;
use Pod::Usage;
#
# postHGAP.pl
#

my $man = '';
my $help = '';
my $input = '';
my $format = 'fasta';
my $output = '';
my $blastn = 'blastn';
my $vector = 'pAGIBAC1_HindIII.txt';
my $shortCutoff = 10000;
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'format=s' => \$format,
			'vector=s' => \$vector,
			'output=s' => \$output
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output);

#clean up
unlink("$output");
unlink("$output.gapped");
unlink("$output.short");
unlink("$output.noVector");
unlink("$output.vector");
unlink("$output.partial");
unlink("$output.aln");

open (OUTPUT,">$output") or die "can't open file: $output";
open (LOG,">$output.log") or die "can't open file: $output.log";

my $vectorLength;
my $inVector = Bio::SeqIO->new(-file => $vector,
						-format => 'fasta');
while ( my $seq = $inVector->next_seq() )
{
	$vectorLength = $seq->length();
	print LOG $seq->id() . "\t$vectorLength\tVector\n";
}
#read sequences
my $in = Bio::SeqIO->new(-file => $input,
						-format => $format);
while ( my $seq = $in->next_seq() )
{
	my $seqLength = $seq->length();
	if($seqLength < $shortCutoff)
	{
		#ignore short sequences
		open (SHORT,">>$output.short") or die "can't open file: $output.short";
		print SHORT ">" . $seq->id() . " $seqLength bp\n" . $seq->seq() ."\n";
		close(SHORT);
		print LOG $seq->id() . "\t$seqLength\tSHORT\n";
		next;
	}
	else
	{
		print LOG $seq->id() . "\t$seqLength\tLONG(>$shortCutoff)\n";
		open (UNITIG,">UNITIG") or die "can't open OUT-FILE: $!";
		print UNITIG ">" . $seq->id() . "\n" . $seq->seq() ."\n";
		close (UNITIG);
	}

	#break unitigs by vector
	my %breakPoint;
	$breakPoint{"1"} = "SequenceEnd";
	$breakPoint{$seqLength} = "SequenceEnd";
	open (ALN,">>$output.aln") or die "can't open file: $output.aln";
	open (CMD,"$blastn -query UNITIG -subject $vector -dust no -evalue 1e-200 -outfmt 6 |") or die "can't open CMD: $!";
	while(<CMD>)
	{
		print ALN $_;
		/^#/ and next;
		my @vectorHit = split("\t",$_);
		if($vectorHit[8] < $vectorHit[9])
		{
			if($vectorHit[8] == 1)
			{
				if($vectorHit[6]-1 > 1)
				{
					$breakPoint{$vectorHit[6]} = "VectorEnd";
					$breakPoint{$vectorHit[6]-1} = "InsertEnd";
				}
				else
				{
					$breakPoint{1} = "VectorEnd"; #for avoiding vector happens to be at the end of raw sequences;
				}
			}
			if($vectorHit[9] == $vectorLength)
			{
				if($vectorHit[7]+1 < $seqLength)
				{
					$breakPoint{$vectorHit[7]} = "VectorEnd";
					$breakPoint{$vectorHit[7]+1} = "InsertEnd";
				}
				else
				{
					$breakPoint{$seqLength} = "VectorEnd";#for avoiding vector happens to be at the end of raw sequences
				}
			}
		}
		else
		{
			if($vectorHit[9] == 1)
			{
				if($vectorHit[7]+1 < $seqLength)
				{
					$breakPoint{$vectorHit[7]} = "VectorEnd";
					$breakPoint{$vectorHit[7]+1} = "InsertEnd";
				}
				else
				{
					$breakPoint{$seqLength} = "VectorEnd";#for avoiding vector happens to be at the end of raw sequences
				}
			}
			if($vectorHit[8] == $vectorLength)
			{
				if($vectorHit[6]-1 > 1)
				{
					$breakPoint{$vectorHit[6]} = "VectorEnd";
					$breakPoint{$vectorHit[6]-1} = "InsertEnd";
				}
				else
				{
					$breakPoint{1} = "VectorEnd"; #for avoiding vector happens to be at the end of raw sequences;
				}
			}
		}
	}
	close(CMD);
	close(ALN);		

	#determine sequence piece type
	my $pieceNumber = 0;
	my $pieceLeft;
	my $pieceLeftPosition;
	my $subSeqALeft;
	my $subSeqARight;
	my $subSeqBLeft;
	my $subSeqBRight;
	for(sort {$a <=> $b} keys %breakPoint)
	{
		if($pieceLeft)
		{
			$pieceNumber++;
			if ($pieceLeft eq "SequenceEnd")
			{
				if($breakPoint{$_} eq "SequenceEnd")
				{
					#no vector;
					open (NOVECTOR,">>$output.noVector") or die "can't open file: $output.noVector";
					print NOVECTOR ">" . $seq->id() . " $seqLength bp\n" . $seq->seq() ."\n";
					close(NOVECTOR);
					print LOG $seq->id() . "\t$pieceLeftPosition\t$_\tNoVector\tSequenceEnd-SequenceEnd\n";
				}
				elsif($breakPoint{$_} eq "VectorEnd")
				{
					#vector or mixer
					open (VECTOR,">>$output.vector") or die "can't open file: $output.vector";
					print VECTOR ">" . $seq->id() . "-vector/mixer (SequenceEnd-VectorEnd) " . ($_ - $pieceLeftPosition + 1) . " bp $pieceLeftPosition-$_\n" .
								$seq->subseq($pieceLeftPosition,$_) ."\n";
					close(VECTOR);					
					print LOG $seq->id() . "\t$pieceLeftPosition\t$_\tVector\tSequenceEnd-VectorEnd\n";
				}
				else # "InsertEnd"
				{
					#left end (sub-sequence one)
					open (SUBSEQONE,">subSeqA") or die "can't open OUT-FILE: $!";
					print SUBSEQONE ">" . $seq->id() . "-subSeqA\n" . $seq->subseq($pieceLeftPosition,$_) . "\n";
					close (SUBSEQONE);
					$subSeqALeft = $pieceLeftPosition;
					$subSeqARight = $_;
					print LOG $seq->id() . "\t$pieceLeftPosition\t$_\tSubSeqOne\tSequenceEnd-InsertEnd\n";
				}
			}
			elsif($pieceLeft eq "VectorEnd")
			{
				if($breakPoint{$_} eq "SequenceEnd")
				{
					#vector or mixer
					open (VECTOR,">>$output.vector") or die "can't open file: $output.vector";
					print VECTOR ">" . $seq->id() . "-vector/mixer (VectorEnd-SequenceEnd) " . ($_ - $pieceLeftPosition + 1) . " bp $pieceLeftPosition-$_\n" .
								$seq->subseq($pieceLeftPosition,$_) ."\n";
					close(VECTOR);					
					print LOG $seq->id() . "\t$pieceLeftPosition\t$_\tVector\tVectorEnd-SequenceEnd\n";
				}
				elsif($breakPoint{$_} eq "VectorEnd")
				{
					#vector
					open (VECTOR,">>$output.vector") or die "can't open file: $output.vector";
					print VECTOR ">" . $seq->id() . "-vector (VectorEnd-VectorEnd) " . ($_ - $pieceLeftPosition + 1) . " bp $pieceLeftPosition-$_\n" .
								$seq->subseq($pieceLeftPosition,$_) ."\n";
					close(VECTOR);					
					print LOG $seq->id() . "\t$pieceLeftPosition\t$_\tVector\tVectorEnd-VectorEnd\n";
				}
				else # "InsertEnd"
				{
					#mixer
					open (PARTIAL,">>$output.partial") or die "can't open file: $output.partial";
					print PARTIAL ">" . $seq->id() . "-mixer (VectorEnd-InsertEnd) " . ($_ - $pieceLeftPosition + 1) . " bp $pieceLeftPosition-$_\n" .
								$seq->subseq($pieceLeftPosition,$_) ."\n";
					close(PARTIAL);					
					print LOG $seq->id() . "\t$pieceLeftPosition\t$_\tMixer\tVectorEnd-InsertEnd\n";
				}
			}
			else # "InsertEnd"
			{
				if($breakPoint{$_} eq "SequenceEnd")
				{
					#right end (sub-sequence two)
					open (SUBSEQTWO,">subSeqB") or die "can't open OUT-FILE: $!";
					print SUBSEQTWO ">" . $seq->id() . "-subSeqB\n" . $seq->subseq($pieceLeftPosition,$_) . "\n";
					close (SUBSEQTWO);
					$subSeqBLeft = $pieceLeftPosition;
					$subSeqBRight = $_;
					print LOG $seq->id() . "\t$pieceLeftPosition\t$_\tSubSeqTwo\tInsertEnd-SequenceEnd\n";
				}
				elsif($breakPoint{$_} eq "VectorEnd")
				{
					#mixer
					open (PARTIAL,">>$output.partial") or die "can't open file: $output.partial";
					print PARTIAL ">" . $seq->id() . "-mixer (InsertEnd-VectorEnd) " . ($_ - $pieceLeftPosition + 1) . " bp $pieceLeftPosition-$_\n" .
								$seq->subseq($pieceLeftPosition,$_) ."\n";
					close(PARTIAL);
					print LOG $seq->id() . "\t$pieceLeftPosition\t$_\tMixer\tInsertEnd-VectorEnd\n";
				}
				else # "InsertEnd"
				{
					#good insert sequence
					print OUTPUT ">" . $seq->id() ."-$pieceNumber-Insert " . ($_ - $pieceLeftPosition + 1) . " bp ($pieceLeftPosition-$_)\n" .
								$seq->subseq($pieceLeftPosition, $_) ."\n";
					print LOG $seq->id() . "\t$pieceLeftPosition\t$_\tInsert\tInsertEnd-InsertEnd\n";
				}
			}
			$pieceLeft = '';
		}
		else
		{
			$pieceLeft = $breakPoint{$_};
			$pieceLeftPosition = $_;
		}
	}
	if (-e "subSeqA")
	{
		if(-e "subSeqB")
		{
			# This script use blast2seq function to count length of overlapping region between 2 subseqs
			my $identity = 98;
			my $minOverlap = 500;
			my $midHit = 0;
			my $queryPosition = 0;
			my $subjectPosition = 0;
			my $overlapLength = 0;
			my $overlapIdentities = 0;
			open (ALN,">>$output.aln") or die "can't open file: $output.tmp";
			open (CMD,"$blastn -query subSeqA -subject subSeqB -dust no -evalue 1e-200 -perc_identity $identity |") or die "can't open CMD: $!";
			while(<CMD>)
			{
				print ALN $_;
				last if ($subjectPosition > 0);
				/Strand=Plus\/Minus/ and last;
				if(/Sbjct  (\d*)/)
				{
					$subjectPosition = $1 if ($queryPosition > 0);
				}
				if(/Query  (\d*)/)
				{
					$queryPosition = $1 if ($1 > $midHit);
				}
				if(/Identities = (\d+)\/(\d+)/)
				{
					$midHit = int ($1/2);
					$overlapLength = $1;
					$overlapIdentities = $1/$2;
					last if ($1 < $minOverlap);
				}		
			}
			close(CMD);
			close(ALN);	
			if($queryPosition > 0)
			{
				my $subSeqBEnd = $subSeqBLeft + $subjectPosition - 2;
				my $subSeqAStart = $subSeqALeft + $queryPosition - 1;
				if($subjectPosition == 1) #only subSeqA is used because alignment of the subSeqB start from 1.
				{
					#good Circularized sequence (type-2)
					#this is very special case: alignment looks like below
					#             1234567...
					# subSeqB     ----------
					#             ||||||||||
					# subSeqA -------------------------
					#             ^cut here
					print OUTPUT ">" . $seq->id() ."-Circularized " . ($subSeqARight - $subSeqAStart + 1) ." bp ($subSeqAStart-$subSeqARight,Overlap:$overlapLength-$overlapIdentities)\n" .
								$seq->subseq($subSeqAStart, $subSeqARight) ."\n"; #subSeqA only
					print LOG $seq->id() . "\t$subSeqAStart\t$subSeqARight\tCircularized\tsubSeqA only(Overlap:$overlapLength,$overlapIdentities)\n";
				}
				else
				{
					#good Circularized sequence (type-2)
					#normal alignment looks like below
					#         1234567...
					# subSeqB --------------
					#             ||||||||||
					# subSeqA     -------------------------
					#                  ^cut here

					print OUTPUT ">" . $seq->id() ."-Circularized " . ($subSeqBEnd - $subSeqBLeft + 1 + $subSeqARight - $subSeqAStart + 1) . " bp ($subSeqBLeft-$subSeqBEnd,$subSeqAStart-$subSeqARight,Overlap:$overlapLength-$overlapIdentities)\n" .
								$seq->subseq($subSeqBLeft, $subSeqBEnd) ."\n" .
								$seq->subseq($subSeqAStart, $subSeqARight) ."\n";
					print LOG $seq->id() . "\t$subSeqBLeft-$subSeqBEnd\t$subSeqAStart-$subSeqARight\tCircularized\tsubSeqB-subSeqA(Overlap:$overlapLength,$overlapIdentities)\n";
				}
			}
			else
			{
				if($pieceNumber > 3)
				{
					#partial sequence;
					open (PARTIAL,">>$output.partial") or die "can't open file: $output.partial";
					print PARTIAL ">" . $seq->id() . "-subSeqA " . ($subSeqARight - $subSeqALeft + 1) . " bp $subSeqALeft-$subSeqARight\n" .
								$seq->subseq($subSeqALeft,$subSeqARight) ."\n" .
								">" . $seq->id() . "-subSeqB " . ($subSeqBRight - $subSeqBLeft + 1) . " bp $subSeqBLeft-$subSeqBRight\n" .
								$seq->subseq($subSeqBLeft,$subSeqBRight) ."\n";
					close(PARTIAL);
					print LOG $seq->id() . "\t$subSeqALeft\t$subSeqARight\tPartial\tsubSeqA\n";
					print LOG $seq->id() . "\t$subSeqBLeft\t$subSeqBRight\tPartial\tsubSeqB\n";
				}
				else
				{
					#gapped sequence
					open (GAPPED,">>$output.gapped") or die "can't open file: $output.gapped";
					print GAPPED ">" . $seq->id(). " (subSeqB:$subSeqBLeft-$subSeqBRight,100Ns,subSeqA:$subSeqALeft-$subSeqARight)\n" .
								$seq->subseq($subSeqBLeft,$subSeqBRight) . "N" x 100 . $seq->subseq($subSeqALeft,$subSeqARight) ."\n";
					close(GAPPED);
					print LOG $seq->id() . "\t$subSeqBLeft-$subSeqBRight\t$subSeqALeft-$subSeqARight\tGapped\tsubSeqB-subSeqA\n";
				}
			}			
		}
		else
		{
			#partial sequence;
			open (PARTIAL,">>$output.partial") or die "can't open file: $output.partial";
			print PARTIAL ">" . $seq->id() . "-subSeqA " . ($subSeqARight - $subSeqALeft + 1) . " bp $subSeqALeft-$subSeqARight\n" .
						$seq->subseq($subSeqALeft,$subSeqARight) ."\n";
			close(PARTIAL);
			print LOG $seq->id() . "\t$subSeqALeft\t$subSeqARight\tPartial\tsubSeqA\n";
		}
	}
	else
	{
		if(-e "subSeqB")
		{
			#partial sequence;
			open (PARTIAL,">>$output.partial") or die "can't open file: $output.partial";
			print PARTIAL ">" . $seq->id() . "-subSeqB " . ($subSeqBRight - $subSeqBLeft + 1) . " bp $subSeqBLeft-$subSeqBRight\n" .
						$seq->subseq($subSeqBLeft,$subSeqBRight) ."\n";
			close(PARTIAL);
			print LOG $seq->id() . "\t$subSeqBLeft\t$subSeqBRight\tPartial\tsubSeqB\n";
		}
	}
	unlink("subSeqA");
	unlink("subSeqB");
	unlink("UNITIG");
}
close(OUTPUT);		
close(LOG);		


__END__

=head1 NAME

postHGAP.pl - Circularize BAC assemblies

=head1 SYNOPSIS

postHGAP.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -format          input sequence format
   -vector          vector sequence file
   -output          output file prefix

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a fasta file.

=item B<-format> (optional)

Input sequence format, default is fasta.
Format list: fasta, genbank, scf, pir, embl, raw, gcg, ace, bsml, swiss, phd.

=item B<-vector> (optional)

Vector sequence file, default is "pAGIBAC1_HindIII.txt".
The sequence needs to be in fasta format. (No enzyme site included)

=item B<-output>

Output data to a file.

=back

=head1 DESCRIPTION

B<postHGAP.pl> will .....

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 



=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut



