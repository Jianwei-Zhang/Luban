#!/usr/bin/perl -w
use strict;
use Bio::SeqIO;

my $binSize = 1000;
print "This script is to check fasta stats based on a given list of smrtcells.\n";
print "Please see 'sampleSmrtcell.list' for an example.\n";
print "Please input a list of Smrtcells or a run directory to be checked:";
chop(my $input=<STDIN>);
print "Please type stats file name:";
chop(my $output=<STDIN>);
until (!-e $output)
{
	print "Report file exists. Please type another name:";
	chop($output=<STDIN>);
}

my @cellDir;
if (-f $input) # if provide a list of smrtcells, can be used for collecting data from original directories
{
	open FILE, "$input";
	while (<FILE>)
	{
		chomp;
		/^#/ and next;
		my @smrtcellLine = split /\s+/,$_;	
		push @cellDir, $smrtcellLine[1];
	}
	close FILE;
}
elsif(-d $input) # if provide a run directory, can be used for a collection data directory.
{
	opendir(DIR, $input) or die "can't opendir $input: $!";
	my @cells = readdir(DIR);
	closedir DIR;
	foreach my $cell (sort @cells)
	{
		next if ($cell =~ /^\./);
		push @cellDir, "$input/$cell";
	}
}

my $number = 1;

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
for my $cell (sort @cellDir)
{
	print OUTPUT "$number. $cell\n";
	my $sampleName = '';
	opendir(DIR, $cell) or die "can't opendir $cell: $!";
	my @fileAndDirs = readdir(DIR);
	closedir DIR;
	foreach my $fileAndDir (reverse @fileAndDirs)
	{
		next if ($fileAndDir =~ /^\./);
		if ($fileAndDir =~ /metadata.xml$/)
		{
			open FILE, "$cell/$fileAndDir";
			while (<FILE>)
			{
				if (/<Sample><Name>(.*)<\/Name><PlateId>/)
				{
					$sampleName = $1 ? $1 : 'noName';
				}
			}
			close FILE;
		}
	}
	foreach my $fileAndDir (reverse @fileAndDirs)
	{
		next if ($fileAndDir =~ /^\./);
		if ($fileAndDir =~ /Analysis_Results/)
		{
			my $totalLength = 0;
			my $totalNumber = 0;
			my $bin;
			my $binLength;

			my $totalLengthInsert = 0; #by max length from a ZMW
			my $totalNumberInsert = 0; #by ZMW
			my $binInsert;
			my $binLengthInsert;
			my $insertLength;
			
			my $subreadsOfZMW;

			opendir(DIR, "$cell/$fileAndDir") or die "can't opendir $cell/$fileAndDir: $!";
			my @fastas = readdir(DIR);
			closedir DIR;
			foreach my $fasta (sort @fastas)
			{
				next if ($fasta =~ /^\./);
				next if ($fasta !~ /\.fasta$/);

				my $in = Bio::SeqIO->new(-file => "$cell/$fileAndDir/$fasta",
										-format => "fasta");
				while ( my $seq = $in->next_seq() )
				{

					my $sequenceLength = length $seq->seq;
					my $binNumber = int (($sequenceLength -1)/$binSize) + 1;
					$totalLength += $sequenceLength;
					$totalNumber++;
					$bin->{$binNumber}++;
					$binLength->{$binNumber} += $sequenceLength;
					my @sequenceId = split "/", $seq->id();
					$subreadsOfZMW->{$sequenceId[1]}++;
					if (exists $insertLength->{$sequenceId[1]})
					{
						if ($insertLength->{$sequenceId[1]} < $sequenceLength)
						{
							$totalLengthInsert += $sequenceLength - $insertLength->{$sequenceId[1]};
							my $previousBinNumber =  int (($insertLength->{$sequenceId[1]} -1)/$binSize) + 1;;
							$binInsert->{$previousBinNumber}--;
							$binLengthInsert->{$previousBinNumber} -= $insertLength->{$sequenceId[1]};
							$binInsert->{$binNumber}++;
							$binLengthInsert->{$binNumber} += $sequenceLength;
							$insertLength->{$sequenceId[1]} = $sequenceLength;
						}
					}
					else
					{
						$totalLengthInsert += $sequenceLength;
						$totalNumberInsert++;
						$binInsert->{$binNumber}++;
						$binLengthInsert->{$binNumber} += $sequenceLength;
						$insertLength->{$sequenceId[1]} = $sequenceLength;
					}
				}
			}

			my $totalLengthFullInsert = 0; #by max length from a ZMW
			my $totalNumberFullInsert = 0; #by ZMW
			my $binFullInsert;
			my $binLengthFullInsert;

			foreach (keys %$subreadsOfZMW)
			{
				if ($subreadsOfZMW->{$_} > 2)
				{
					my $binNumber = int (($insertLength->{$_} -1)/$binSize) + 1;
					$totalLengthFullInsert += $insertLength->{$_};
					$totalNumberFullInsert++;
					$binFullInsert->{$binNumber}++;
					$binLengthFullInsert->{$binNumber} += $insertLength->{$_};
				}
			}

			print OUTPUT "#SBN\tbinNumber\tCount\t\% of subreads\tLength\t\% of totalLength\n";
			print OUTPUT "#SBNT\t$sampleName\t$totalNumber\t\t$totalLength\t\n";
			foreach (sort {$a <=> $b} keys %$bin)
			{
				my $countPercent = (int (10000*$bin->{$_}/$totalNumber))/100;
				my $binLegnthPercent = (int (10000*$binLength->{$_}/$totalLength))/100;
				print OUTPUT "SBN\t$_\t$bin->{$_}\t$countPercent\t$binLength->{$_}\t$binLegnthPercent\n";
			}
			print OUTPUT "#LBN\tbinNumber\tCount\t\% of ZMWs\tLength\t\% of totalLength\n";
			print OUTPUT "#LBNT\t$sampleName\t$totalNumberInsert\t\t$totalLengthInsert\t\n";
			foreach (sort {$a <=> $b} keys %$binInsert)
			{
				my $countPercent = (int (10000*$binInsert->{$_}/$totalNumberInsert))/100;
				my $binLegnthPercent = (int (10000*$binLengthInsert->{$_}/$totalLengthInsert))/100;
				print OUTPUT "LBN\t$_\t$binInsert->{$_}\t$countPercent\t$binLengthInsert->{$_}\t$binLegnthPercent\n";
			}
			print OUTPUT "#IBN\tbinNumber\tCount\t\% of fullInsert\tLength\t\% of totalLength\n";
			print OUTPUT "#IBNT\t$sampleName\t$totalNumberFullInsert\t\t$totalLengthFullInsert\t\n";
			foreach (sort {$a <=> $b} keys %$binFullInsert)
			{
				my $countPercent = (int (10000*$binFullInsert->{$_}/$totalNumberFullInsert))/100;
				my $binLegnthPercent = (int (10000*$binLengthFullInsert->{$_}/$totalLengthFullInsert))/100;
				print OUTPUT "IBN\t$_\t$binFullInsert->{$_}\t$countPercent\t$binLengthFullInsert->{$_}\t$binLegnthPercent\n";
			}
		}
	}
	$number++;
}
close (OUTPUT);