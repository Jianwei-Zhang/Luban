#!/usr/local/bin/perl -w
#
# This script count some elements from the sequences

print "Please input fasta sequence file:";
chop($seqdb=<STDIN>);
print "Which element(s) to be searched (two or more elements must be separated by comma ',', eg. CG, CTG,CAG):";
chop($elements=<STDIN>);


print "*"x80,"\n";
print "Output file will be named as $seqdb.elements\n";
print "*"x80,"\n";

$elements =~ s/ //g;
@elements=split(/,/,uc($elements));

open (SEQDB,"$seqdb") or die "can't open fasta sequence FILE: $!";
while(<SEQDB>)
{
	$_ =~ s/\s*$//g;
	if(/>/)
	{
		$seqtitle=$';
		$seq{$seqtitle}="";
		next;
	}
  $seq{$seqtitle} .= uc($_);
}
close (SEQDB);

open (OUTPUT,">$seqdb.elements") or die "can't open OUT-FILE: $!";
print OUTPUT "#seqid\t";
print OUTPUT join "\t",@elements;
print OUTPUT "\n";
foreach $seqid (keys %seq)
{
	print OUTPUT "$seqid\t";
#	print $seq{$seqid};
#	print "\n";
  foreach $element (@elements)
  {
    $number{$element}=0;
    while($seq{$seqid} =~ /$element/ig)
    {
      $number{$element}++;
    }
    print OUTPUT $number{$element};
    print OUTPUT "\t";
  }
  print OUTPUT "\n";
}
close (OUTPUT);
