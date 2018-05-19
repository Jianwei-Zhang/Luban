#!/usr/bin/perl -w
use strict;

print "This script is to check files based on a given list of smrtcells.\n";
print "Please see 'sampleSmrtcell.list' for an example.\n";
print "Please input a list of Smrtcells or a run directory to be checked:";
chop(my $input=<STDIN>);
print "Show detailed processing?(Yes/No):";
chop(my $details=<STDIN>);
until ($details =~ /^NO$/i || $details =~ /^YES$/i)
{
	print "Show detailed processing?(Yes/No):";
	chop($details=<STDIN>);
}
print "Please type report file name:";
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

my @essentialFileSuffix = ('s1_p0.1.bax.h5','s1_p0.2.bax.h5','s1_p0.3.bax.h5','s1_p0.metadata.xml'); #4 files
my @requiredLevelOneFileSuffix = ('s1_p0.1.xfer.xml','s1_p0.2.xfer.xml','s1_p0.3.xfer.xml','s1_p0.mcd.h5','s1_p0.metadata.xml'); #5 files
my @requiredLevelTwoFileSuffix = ('s1_p0.1.bax.h5','s1_p0.1.log','s1_p0.1.subreads.fasta','s1_p0.1.subreads.fastq','s1_p0.2.bax.h5','s1_p0.2.log','s1_p0.2.subreads.fasta','s1_p0.2.subreads.fastq','s1_p0.3.bax.h5','s1_p0.3.log','s1_p0.3.subreads.fasta','s1_p0.3.subreads.fastq','s1_p0.bas.h5','s1_p0.sts.csv','s1_p0.sts.xml'); #15 files

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
for my $cell (sort @cellDir)
{
	print OUTPUT "$number. $cell\n" if ($details =~ /^YES$/i);
	my $match;
	my $essential;
	my $nonValue = 0;
	opendir(DIR, $cell) or die "can't opendir $cell: $!";
	my @fileAndDirs = readdir(DIR);
	closedir DIR;
	foreach my $fileAndDir (sort @fileAndDirs)
	{
		next if ($fileAndDir =~ /^\./);
		if(-d "$cell/$fileAndDir")
		{
			if($fileAndDir eq "Analysis_Results")
			{
				print OUTPUT "d\t$cell/$fileAndDir\n" if ($details =~ /^YES$/i);
				opendir(DIR, "$cell/$fileAndDir") or die "can't opendir $cell/$fileAndDir: $!";
				my @inAnalysisResults = readdir(DIR);
				closedir DIR;
				foreach my $inAnalysisResult (sort @inAnalysisResults)
				{
					next if ($inAnalysisResult =~ /^\./);
					if (-d "$cell/$fileAndDir/$inAnalysisResult")
					{
						print OUTPUT "d(s)\t$cell/$fileAndDir/$inAnalysisResult\n" if ($details =~ /^YES$/i);
						$nonValue++
					}
					else
					{
						my $levelTwoMatchFlag = 0;
						for my $levelTwoFileSuffix (@requiredLevelTwoFileSuffix)
						{
							if($inAnalysisResult =~ /$levelTwoFileSuffix$/g)
							{
								$match->{$levelTwoFileSuffix}++;
								$levelTwoMatchFlag++;
							}
						}
						my $essentialFlag = 0;
						for my $essentialFileSuffix (@essentialFileSuffix)
						{
							if($inAnalysisResult =~ /$essentialFileSuffix$/g)
							{
								$essential->{$essentialFileSuffix}++;
								$essentialFlag++;
							}
						}
						
						if ($levelTwoMatchFlag)
						{
							if($essentialFlag)
							{
								print OUTPUT "f(e)\t$cell/$fileAndDir/$inAnalysisResult\n" if ($details =~ /^YES$/i);
							}
							else
							{
								print OUTPUT "f\t$cell/$fileAndDir/$inAnalysisResult\n" if ($details =~ /^YES$/i);
							}
						}
						else
						{
							print OUTPUT "f(s)\t$cell/$fileAndDir/$inAnalysisResult\n" if ($details =~ /^YES$/i);
							$nonValue++
						}
					}
				}
			}
			else
			{
				print OUTPUT "d(s)\t$cell/$fileAndDir\n" if ($details =~ /^YES$/i);
				$nonValue++
			}
		}
		else
		{
			my $levelOneMatchFlag = 0;
			for my $levelOneFileSuffix (@requiredLevelOneFileSuffix)
			{
				if($fileAndDir =~ /$levelOneFileSuffix$/g)
				{
					$match->{$levelOneFileSuffix}++;
					$levelOneMatchFlag++;
				}
			}
			my $essentialFlag = 0;
			for my $essentialFileSuffix (@essentialFileSuffix)
			{
				if($fileAndDir =~ /$essentialFileSuffix$/g)
				{
					$essential->{$essentialFileSuffix}++;
					$essentialFlag++;
				}
			}
			if ($levelOneMatchFlag)
			{
				if($essentialFlag)
				{
					print OUTPUT "f(e)\t$cell/$fileAndDir\n" if ($details =~ /^YES$/i);
				}
				else
				{
					print OUTPUT "f\t$cell/$fileAndDir\n" if ($details =~ /^YES$/i);
				}
			}
			else
			{
				print OUTPUT "f(s)\t$cell/$fileAndDir\n" if ($details =~ /^YES$/i);
				$nonValue++
			}
		}
	}
	my $checkValue = keys %$match;
	my $essentialValue = keys %$essential;
	if($checkValue == 20)
	{
		print OUTPUT ">$number. $cell: $checkValue/20 files passed; $essentialValue/4 essential files; $nonValue suspicious item(s).\n";
	}
	else
	{
		if ($essentialValue == 4)
		{
			print OUTPUT "*$number. $cell: $checkValue/20 files passed; $essentialValue/4 essential files; $nonValue suspicious item(s).\n";
		}
		else
		{
			print OUTPUT "?$number. $cell: $checkValue/20 files passed; $essentialValue/4 essential files; $nonValue suspicious item(s).\n";
		}
	}
	$number++;
}
close (OUTPUT);

