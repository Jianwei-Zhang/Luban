#!/usr/bin/perl -w
use strict;

print "Caution: This script can only handle the Chr-Ctg AGP file from GPM !!!\n";

print "Please type GFF file name (based on chromosome):";
chop(my $gffFile=<STDIN>);

print "Please type AGP file name:";
chop(my $agpFile=<STDIN>);

print "Please type output file name:";
chop(my $outFile=<STDIN>);

my $ctg;
my $posLeft;
my $posRight;
my $orientation;
open AGP,$agpFile;
while (<AGP>){
	s/^\s+//;
    s/\s+$//;
	/^#/ and next;
    my @agpLine = split/\t/;
    if ($agpLine[4] ne 'N' && $agpLine[4] ne 'U' )
	{
        $ctg->{$agpLine[0]}->{$agpLine[1]}->{$agpLine[2]} = $agpLine[5];
        $posLeft->{$agpLine[0]}->{$agpLine[1]}->{$agpLine[2]} = $agpLine[6];
        $posRight->{$agpLine[0]}->{$agpLine[1]}->{$agpLine[2]} = $agpLine[7];
        $orientation->{$agpLine[0]}->{$agpLine[1]}->{$agpLine[2]} = $agpLine[8];
	}
}
close AGP;
my $line = 0;
open GFF,$gffFile;
open OUT,">$outFile";
while (<GFF>){
	$line++;
	my $convertable = 0;
	s/^\s+//;
    s/\s+$//;
	if (/^#/)
	{
		print OUT "$_\n";
		next;
	}	
    my @gffLine = split/\t/;
    my ($left,$right);
	for my $start (sort {$a <=> $b} keys %{$ctg->{$gffLine[0]}})
	{
		if ($start <= $gffLine[3] && $start <= $gffLine[4])
		{
			for my $end (sort {$a <=> $b} keys %{$ctg->{$gffLine[0]}->{$start}})
			{
				if($gffLine[3] <= $end && $gffLine[4] <= $end)
				{
					$convertable = 1;
					if($orientation->{$gffLine[0]}->{$start}->{$end} ne '-')
					{
						$left = $gffLine[3] - $start + $posLeft->{$gffLine[0]}->{$start}->{$end};
						$right = $gffLine[4] - $start + $posLeft->{$gffLine[0]}->{$start}->{$end};
						print OUT "$ctg->{$gffLine[0]}->{$start}->{$end}\t$gffLine[1]\t$gffLine[2]\t$left\t$right\t$gffLine[5]\t$gffLine[6]\t$gffLine[7]\t$gffLine[8]\n";
					}
					else
					{
						$left = $end - $gffLine[4] + $posLeft->{$gffLine[0]}->{$start}->{$end};
						$right = $end - $gffLine[3] + $posLeft->{$gffLine[0]}->{$start}->{$end};
						if($gffLine[6] ne '-')
						{
							print OUT "$ctg->{$gffLine[0]}->{$start}->{$end}\t$gffLine[1]\t$gffLine[2]\t$left\t$right\t$gffLine[5]\t-\t$gffLine[7]\t$gffLine[8]\n";
						}
						else
						{
							print OUT "$ctg->{$gffLine[0]}->{$start}->{$end}\t$gffLine[1]\t$gffLine[2]\t$left\t$right\t$gffLine[5]\t+\t$gffLine[7]\t$gffLine[8]\n";    
						}
					}
				}
			}
		}
	}
	print "Warning: Line $line can't be converted.\n" if (!$convertable);
}
close GFF;
close OUT;
