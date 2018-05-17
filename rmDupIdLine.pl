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

%queryid=();
open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
open (INPUT,"$input") or die "can't open input File: $!";
while(<INPUT>)
{
	@line=split(/\t/,$_);
	if (!exists $queryid{$line[0]})
	{
		print OUTPUT $_;
		$queryid{$line[0]}=$_;
	}
}
close (INPUT);
close (OUTPUT);
__END__

=head1 NAME

rmDupIdLine.pl - Removing Duplicate Ids

=head1 SYNOPSIS

rmDupIdLine.pl [options]

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

Input data from a file in Tab delimited text format. For example, blast results in tabular format are welcome.

=item B<-output>

Output data to a file.

=back

=head1 DESCRIPTION

B<rmDupIdLine> will remove the duplicate lines of blast result by the query id and keep the first line for each query.

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
