#!/usr/bin/perl -w
use strict;
use Cwd;
my $dir = getcwd;
print "This script is to merge all fasta files in a run directory and generate a '.rawreads.fasta' file.\n";
print "Please a run directory or .fofn file to be collected:";
chop(my $smrtrun=<STDIN>);
print "The $smrtrun.rawreads.fasta existed. It seems that you've merged the data already.\n" and exit if (-e "$smrtrun.rawreads.fasta"); # this is to avoid overwrite.

if (-f $smrtrun) # if provide a list of smrtcells, can be used for collecting data from original directories
{
	open FILE, "$smrtrun";
	while (<FILE>)
	{
		chomp;
		/^#/ and next;
		print "cat $_ >>$smrtrun.rawreads.fasta\n";
		`cat $_ >>$smrtrun.rawreads.fasta`;
	}
	close FILE;
}
elsif(-d $smrtrun) # if provide a run directory, can be used for a collection data directory.
{
	opendir(DIR, $smrtrun) or die "can't opendir $smrtrun: $!";
	my @cells = readdir(DIR);
	closedir DIR;
	foreach my $cell (sort @cells)
	{
		next if ($cell =~ /^\./);
		if (-f "$smrtrun/$cell")
		{
			next if ($cell !~ /\.fasta$/);
			print "cat $dir/$smrtrun/$cell >>$smrtrun.rawreads.fasta";
			`cat $dir/$smrtrun/$cell >>$smrtrun.rawreads.fasta`;
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
				print "cat $dir/$smrtrun/$cell/Analysis_Results/$fasta >>$smrtrun.rawreads.fasta";
				`cat $dir/$smrtrun/$cell/Analysis_Results/$fasta >>$smrtrun.rawreads.fasta`;
			}
		}
	}
}
else
{
	print "No $smrtrun found.\n";
}


