#!/usr/local/bin/perl -w
use strict;
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
open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
print OUTPUT "#Sequence",
			"\t",
     		"HitCount",
     		"\n";
open (INPUT,"$input") or die "can't open IN-FILE: $!";
while(<INPUT>)
{
	if(/Sequence: (.*)(\s+)from/)
	{
		print OUTPUT $1,"\t";
	}
	if(/HitCount: (\d*)/)
	{
		print OUTPUT $1,"\n";
	}
}
close (INPUT);

close (OUTPUT);
exit; 

__END__

=head1 NAME

cvtFuzznucToTabular.pl - Conver fuzznuc (EMBOSS) format  to tabular format

=head1 SYNOPSIS

cvtFuzznucToTabular.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file (fuzznuc)
   -output          output file (tabular)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Name of input file in original fuzznuc format.

=item B<-output>

Name of output file in tabular format.

=back

=head1 DESCRIPTION

B<cvtFuzznucToTabular> will convert fuzznuc output format to tabular.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

none.

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
