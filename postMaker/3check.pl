#!/usr/bin/perl -w
use strict;
#this is to check if a parent exists or not.
print "Please type input gff file name:";
chop(my $input=<STDIN>);
print "Please type output gff file name:";
chop(my $outfile=<STDIN>);

my %parent;
my %seqid;
my %position;
open (FL,$input) or die("Can't open '$input': $!");
my @input = <FL>;
close (FL);

open (FLS,">$outfile") or die("Can't open '$outfile': $!");
open (FLSLOG,">$outfile.log") or die("Can't open '$outfile.log': $!");
foreach (@input){
	chomp;
	my @line = split/\t/;
	if ($line[2] eq 'gene'){
		if ($line[8] =~ /ID=([^;]+);/)
		{
			my $id = $1;
			$parent{$id} = 1;
			$seqid{$id} = $line[0];
			$position{$id} = $line[3];
		}
		else
		{
			print FLSLOG "err\t$_\n";
		}
	}
}
foreach (@input){
	chomp;
	my @line = split/\t/;
	if ($line[2] eq 'mRNA'){
		if ($line[8] =~ /\S+;Parent=([^;]+)/)
		{
			my @newParents;
			my @parents = split /,/,$1;
			for my $name (@parents)
			{
				if (exists $parent{$name})
				{
					push @newParents,$name;
				}
			}
			my $newParents = join ',',@newParents;
			if ($#newParents >= 0)
			{
				if ($line[8] =~ /ID=([^;]+);/)
				{
					my $id = $1;
					$parent{$id} = 1;
					$seqid{$id} = $line[0];
					$position{$id} = $line[3];
				}
				else
				{
					print FLSLOG "err\t$_\n";
				}
			}
			else
			{
				print FLSLOG "noParent\t$_\n";
			}
		}
	}
}

foreach (@input){
	chomp;
	my @line = split/\t/;
	if($line[2] eq 'gene')
	{
		print FLS "$_\n";
	}
	else
	{
		if ($line[8] =~ /\S+;Parent=([^;]+)/)
		{
			my @newParents;
			my @parents = split /,/,$1;
			for my $name (@parents)
			{
				if (exists $parent{$name})
				{
					push @newParents,$name;
				}
			}
			my $newParents = join ',',@newParents;
			if ($#newParents >= 0)
			{
				$line[8] =~ s/Parent=([^;]+)/Parent=$newParents/g;
				if ($line[8] =~ /ID=([^;]+);/)
				{
					print FLS "$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\n";
				}
				else
				{
					print FLSLOG "err\t$_\n";
				}
			}
			else
			{
				print FLSLOG "noParent\t$_\n";
			}
		}
		else
		{
			print FLSLOG "noParent\t$_\n";
		}
	}
}
close (FLS);
close (FLSLOG);
