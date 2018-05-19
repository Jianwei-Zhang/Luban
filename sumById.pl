#!/usr/local/bin/perl -w
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $output = '';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'output=s' => \$output,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output);

my %queryid=();
my %members=();
open (INPUT,"$input") or die "can't open input File: $!";
while(<INPUT>)
{
	chomp;
	/^\#/ and next;
	my @line=split(/\t/,$_);
	if (exists $queryid{$line[0]})
	{
		$queryid{$line[0]} += $line[1];
		$members{$line[0]} .= ", ".$line[1];
	}
	else
	{
		$queryid{$line[0]} = $line[1];
		$members{$line[0]} = $line[1];
	}
}
close (INPUT);

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
print OUTPUT "#Id\tSum\tIndividual\n";
foreach (sort keys %queryid)
{
	print OUTPUT "$_\t$queryid{$_}\t$members{$_}\n";
}
close (OUTPUT);
__END__

=head1 NAME

sumById.pl - get sum by id

=head1 SYNOPSIS

sumById.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -output          output file

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a file in Tab delimited text format. For example,

	#seqId	Hit-numbers
	seq1	2
	seq1	4
	seq2	1
	seq2	4
	...

=item B<-output>

Output data to a file. For example,

	#Id	Sum
	seq1	6
	seq2	5
	...

=back

=head1 DESCRIPTION

B<sumById> will get the sum of second column by the id column.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 



=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
