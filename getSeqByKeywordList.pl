#!/usr/local/bin/perl -w
#
# This script separate the sequences from fasta file according to the keywords in title line

print "Please input fasta sequence file:";
chop($seqdb=<STDIN>);
print "Please type keywords list file:";
chop($keywordlist=<STDIN>);
print "Please type output file:";
chop($output=<STDIN>);

open (SEQDB,"$seqdb") or die "can't open fasta sequence FILE: $!";
while(<SEQDB>)
{
	$_ =~ s/\s*$//; #delete blanks in the end
	if(/>/)
	{
		$seqtitle=$';
		$sequence{$seqtitle} = "";
		next;
	}
	$sequence{$seqtitle} .= $_;
}
close (SEQDB);

open (KWLIST,"$keywordlist") or die "can't open fasta sequence FILE: $!";
while(<KWLIST>)
{
	$_ =~ s/\s*$//; #delete blanks in the end
  push @keywords,$_;
}
close (KWLIST);

%found=();
%printed=();
open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
foreach $seqid (keys %sequence)
{
  foreach $keyword (@keywords)
  {
  	if ($seqid =~ /$keyword/)
  	{
  		if(!exists $printed{$seqid})
  		{
  	   	print OUTPUT ">$seqid\n$sequence{$seqid}\n";
  	   	$printed{$seqid}=1;
      }
      else
      {
  	   	$printed{$seqid}++;
      }
    	if (exists $found{$keyword})
    	{
        $found{$keyword}++;
    	}
    	else
    	{
        $found{$keyword}=1;
      }
  	}
  }
}
close (OUTPUT);
open (OUTPUT,">$output.log") or die "can't open OUT-FILE: $!";

foreach $keyword (@keywords)
{
	if (!exists $found{$keyword})
	{
    print OUTPUT "I coundn't find the sequence by $keyword.\n";
	}
	else
	{
    if($found{$keyword} == 1)
    {
      print OUTPUT "I found $found{$keyword} sequence by $keyword.\n";
    }
    else
    {
     print OUTPUT "I found $found{$keyword} sequences by $keyword.\n";
    }
  }
}
close (OUTPUT);


