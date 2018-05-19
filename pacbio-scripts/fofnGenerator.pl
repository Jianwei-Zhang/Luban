#!/usr/bin/perl -w
use strict;
use Cwd;
my $dir = getcwd;
print "This script is to collect the fasta files and generate a '.fofn' list in a run directory.\n";
print "Please a run directory to be collected:";
chop(my $smrtrun=<STDIN>);

open (OUTPUT,">$smrtrun.fofn") or die "can't open OUT-FILE: $!";
opendir(DIR, $smrtrun) or die "can't opendir $smrtrun: $!";
my @cells = readdir(DIR);
closedir DIR;
foreach my $cell (sort @cells)
{
	next if ($cell =~ /^\./);
	if (-f "$smrtrun/$cell")
	{
		next if ($cell !~ /\.fasta$/);
		print OUTPUT "$dir/$smrtrun/$cell\n";
	}
	else
	{
		opendir(DIR, "$smrtrun/$cell/Analysis_Results") or die "can't opendir $smrtrun/$cell/Analysis_Results: $!";
		my @fastas = readdir(DIR);
		closedir DIR;
		foreach my $fasta (sort @fastas)
		{
			next if ($fasta =~ /^\./);
			next if ($fasta !~ /\.fasta$/);
			print OUTPUT "$dir/$smrtrun/$cell/Analysis_Results/$fasta\n";
		}
	}
}
close (OUTPUT);
