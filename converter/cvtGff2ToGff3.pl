#!/usr/local/bin/perl -w
use strict;
use Bio::Tools::GFF;
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

my $gffout = Bio::Tools::GFF->new(-file=>">$output",-gff_version=>3);
my $gffin = Bio::Tools::GFF->new(-file=>"$input",-gff_version=>2);
while( my $feature = $gffin->next_feature() ) {
	$gffout->write_feature($feature);
}
exit; 

__END__

=head1 NAME

cvtGff2ToGff3.pl - GFF2 to GFF3 format

=head1 SYNOPSIS

cvtGff2ToGff3.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file (GFF2)
   -output          output file (GFF3)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Name of input file in GFF2 format.

=item B<-output>

Name of output file in GFF3 format.

=back

=head1 DESCRIPTION

B<cvtGff2ToGff3> will convert data in gff2 format to gff3.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

cvtGff3ToGff2.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
