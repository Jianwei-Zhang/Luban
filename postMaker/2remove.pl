#!/usr/bin/perl -w
use strict;
#this is to remove genes by matched ids
print "Please type input gff file name:";
chop(my $input=<STDIN>);
print "Please type to-be-removed file name (gene name only):";
chop(my $toBeRemovedList=<STDIN>);
print "Please type output gff file name:";
chop(my $outfile=<STDIN>);

my %toBeRemoved;
my %removed;
open (FL,$toBeRemovedList) or die("Can't open '$toBeRemovedList': $!");
while (<FL>)
{
	chomp;
	my @line = split /\t/, $_;
#	$line[0] =~ s/maker-//g;
	$toBeRemoved{$line[0]}++;
}
close (FL);

open (FL,$input) or die("Can't open '$input': $!");
open (FLS,">$outfile") or die("Can't open '$outfile': $!");
open (FLSLOG,">$outfile.log" or die("Can't open '$outfile.log': $!");
while (<FL>)
{
	chomp;
	my @line = split /\t/, $_;
	if ($line[8] =~ /ID=([^;]+);/)
	{
		my $id = $1;
		if (exists $toBeRemoved{$id})
		{
			print FLSLOG "del\t$_\n";
			$removed{$id} = 1;
			next;
		}
		else
		{
			print FLS "$_\n";
		}
	}
	else
	{
		print FLSLOG "err\t$_\n";
	}
}
print FLSLOG "===count===\n";
for (sort keys %toBeRemoved)
{
	if(exists $removed{$_})
	{
		print FLSLOG "removed\t$_\t$toBeRemoved{$_}\n";
	}
	else
	{
		print FLSLOG "notFound\t$_\t$toBeRemoved{$_}\n";
	}
}
close (FL);
close (FLS);
close (FLSLOG);
