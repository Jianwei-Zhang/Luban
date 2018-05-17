#!/usr/local/bin/perl -w
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $start = '';
my $end = '';
my $sample = '';
my $output = '';
my $replacement = 1;

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'start=i' => \$start,
			'end=i' => \$end,
			'sample=i' => \$sample,
			'output=s' => \$output,
			'replacement!' => \$replacement,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($start && $end && $sample && $output);

@numberrange=($start .. $end);
if($replacement)
{
	print "Simple random sampling with replacement.\n";
}
else
{
	print "Simple random sampling without replacement.\n";
}
open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
for ($i=0;$i<$sample;$i++)
{
	$ramdomindex=rand @numberrange;
	print OUTPUT $numberrange[$ramdomindex]."\n";	
	if(! $replacement)
	{
		splice(@numberrange, $ramdomindex, 1);
	}
}
close (OUTPUT);
__END__

=head1 NAME

randomNumbers.pl - Generating random numbers

=head1 SYNOPSIS

randomNumbers.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -start           range start
   -end             range end
   -sample          sample size
   -output          output file
   -replacement     sampling method

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-start>

Give a range start number (int > 0).

=item B<-end>

Give a range end number (int > 0), must larger than start.

=item B<-sample>

Give a sample size (int > 0).

=item B<-output>

Output data to a file.

=item B<-replacement> (optional)

Default is sampling with replacement.

B<-noreplacement> is to sample without replacement.

=back

=head1 DESCRIPTION

B<randomNumbers> will generate random numbers from a given list.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

extractRowByLineNumber.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
