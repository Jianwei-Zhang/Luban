#!/usr/bin/perl -w
use strict;
use POSIX ":sys_wait_h";

my $binSize = 1000; #1 kb/bin
my $cutoff = 20; #20 kb
my $threads = 20;

print "This script is to check bam stats based on a given list of smrtcells.\n";
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
		next if (-f "$input/$cell");
		push @cellDir, "$input/$cell";
	}
}

my @allPid;
my $runningPid;

my $number = 1;
for my $cell (sort @cellDir)
{
	print "Compute $number. $cell\n";
	$number++;
	my $cellStats = "$cell.stats";
	$cellStats =~ s/[^A-Za-z0-9\-\.\~\_]/-/g; #replace invalid characters with '-' for filename.
	$cellStats =~ s/^\W+//g;# replace the first non-word characters
	$cellStats =~ s/\W+$//g;# replace the last non-word characters
	$cellStats =~ s/\-\-/-/g;
	next if (-f "/tmp/$cellStats");

	my  $pid = fork();
	# Check if parent/child process
	if ($pid)
	{ # Parent
		push @allPid, $pid;
	}
	elsif ($pid == 0)
	{ # Child
		my $sampleNameOfCell = 'noName';
		my $sampleCreatedAt = 'noTime';
		my $totalLengthOfCell = 0;
		my $totalNumberOfCell = 0;
		my $binOfCell;
		my $binLengthOfCell;
	
		opendir(DIR, $cell) or die "can't opendir $cell: $!";
		my @fileAndDirs = readdir(DIR);
		closedir DIR;
		foreach my $fileAndDir (@fileAndDirs)
		{
			next if ($fileAndDir =~ /^\./);
			next if(-d "$cell/$fileAndDir");

			if ($fileAndDir =~ /subreadset.xml$/)
			{
				open FILE, "$cell/$fileAndDir";
				while (<FILE>)
				{
					if (/WellSample Name=\"(.*)\" Description="(.*)" CreatedAt="(.*)" ModifiedAt=/)
					{
						$sampleNameOfCell = $1 ? $1 : 'noName';
						$sampleCreatedAt = $3 ? $3 : 'noTime';
					}
				}
				close FILE;
			}
			if ($fileAndDir =~ /subreads.bam$/)
			{
				open (CMD,"samtools view $cell/$fileAndDir |") or die "can't open CMD: $!";
				while(<CMD>)
				{
					my @line = split "\t", $_;
					my $sequenceLength = length $line[9];
					my $binNumber = int (($sequenceLength -1)/$binSize) + 1;
					$totalLengthOfCell += $sequenceLength;
					$totalNumberOfCell++;
					$binOfCell->{$binNumber}++;
					$binLengthOfCell->{$binNumber} += $sequenceLength;
				}
				close(CMD);
			}
		}
		open (OUTPUT,">/tmp/$cellStats") or die "can't open OUT-FILE: $!";
		print OUTPUT "#SBNT\t$sampleNameOfCell\t$totalNumberOfCell\t$sampleCreatedAt\t$totalLengthOfCell\t\n";
		print OUTPUT "#SBN\tbinNumber\tCount\t\% of subreads\tLength\t\% of totalLength\n";
		foreach (sort {$a <=> $b} keys %$binOfCell)
		{
			my $countPercent = (int (10000*$binOfCell->{$_}/$totalNumberOfCell))/100;
			my $binLegnthPercent = (int (10000*$binLengthOfCell->{$_}/$totalLengthOfCell))/100;
			print OUTPUT "SBN\t$_\t$binOfCell->{$_}\t$countPercent\t$binLengthOfCell->{$_}\t$binLegnthPercent\n";
		}
		close (OUTPUT);
		exit 0;  # It is STRONGLY recommended to exit your child process
	}
	else
	{ # Unable to fork
		die "ERROR: Could not fork new process: $!\n\n";
	}
	$runningPid = @allPid; #wait until less threads
	do {
		$runningPid = 0;
		foreach my $pidMember (@allPid)
		{
			my $kid = waitpid($pidMember, WNOHANG);
			$runningPid++ if $kid == 0;
		}
	} while $runningPid > $threads;
}
$runningPid = @allPid; #wait until all threads finished
do {
	$runningPid = 0;
	foreach my $pidMember (@allPid)
	{
		my $kid = waitpid($pidMember, WNOHANG);
		$runningPid++ if $kid == 0;
	}
} while $runningPid > 0;

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
my $sampleName = '';
my $totalNumber = 0;
my $totalLength = 0;
my $totalNumberOfCutoff = 0;
my $totalLengthOfCutoff = 0;
my $bin;
my $binLength;
$number = 1;
for my $cell (sort @cellDir)
{
	print "Merge $number. $cell\n";
	$number++;
	my $cellStats = "$cell.stats";
	$cellStats =~ s/[^A-Za-z0-9\-\.\~\_]/-/g; #replace invalid characters with '-' for filename.
	$cellStats =~ s/^\W+//g;# replace the first non-word characters
	$cellStats =~ s/\W+$//g;# replace the last non-word characters
	$cellStats =~ s/\-\-/-/g;

	my $totalNumberOfCutoffOfCell = 0;
	my $totalLengthOfCutoffOfCell = 0;
	my $totalNumberOfCell = 0;
	my $totalLengthOfCell = 0;
	my $sampleCreatedAt = 'noTime';

	open (STATS,"/tmp/$cellStats") or die "can't open STATS-FILE: $!";
	while(<STATS>)
	{
		/\[Sum\]/ and last;
		print OUTPUT $_;
		my @statsLine = split /\t/,$_;
		next if ($statsLine[0] eq '#SBNC'); #cutoff summary
		next if ($statsLine[0] eq '#SBN');
		if ($statsLine[0] eq '#SBNT')
		{
			$sampleName .= ($sampleName) ? " $statsLine[1]" : $statsLine[1];
			$totalNumber += $statsLine[2];
			$totalNumberOfCell = $statsLine[2];
			$sampleCreatedAt = $statsLine[3];
			$totalLength += $statsLine[4];
			$totalLengthOfCell = $statsLine[4];
			next;
		}
		$bin->{$statsLine[1]} += $statsLine[2];
		$totalNumberOfCutoff += $statsLine[2] if ($statsLine[1] <= $cutoff);
		$totalNumberOfCutoffOfCell += $statsLine[2] if ($statsLine[1] <= $cutoff);
		$binLength->{$statsLine[1]} += $statsLine[4];
		$totalLengthOfCutoff += $statsLine[4] if ($statsLine[1] <= $cutoff);
		$totalLengthOfCutoffOfCell += $statsLine[4] if ($statsLine[1] <= $cutoff);
	}
	close (STATS);
	print OUTPUT "#SBNC\t[<cutoff]$cutoff kb\t$totalNumberOfCell\t$totalNumberOfCutoffOfCell\t$totalLengthOfCell\t$totalLengthOfCutoffOfCell\t$sampleCreatedAt\n";	
}

print OUTPUT "#SBNT\t[Sum]$sampleName\t$totalNumber\t\t$totalLength\t\n";
print OUTPUT "#SBN\tbinNumber\tCount\t\% of subreads\tLength\t\% of totalLength\n";
foreach (sort {$a <=> $b} keys %$bin)
{
	my $countPercent = (int (10000*$bin->{$_}/$totalNumber))/100;
	my $binLegnthPercent = (int (10000*$binLength->{$_}/$totalLength))/100;
	print OUTPUT "SBN\t$_\t$bin->{$_}\t$countPercent\t$binLength->{$_}\t$binLegnthPercent\n";
}
print OUTPUT "#SBNC\t[<cutoff]$cutoff kb\t$totalNumber\t$totalNumberOfCutoff\t$totalLength\t$totalLengthOfCutoff\n";	
close (OUTPUT);