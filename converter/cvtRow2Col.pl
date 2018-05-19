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

@outline=();
open (INPUT,"$input") or die "can't open input file: $!";
while(<INPUT>)
{
	chop;
	#$_ =~ s/\s*$//g; #don't use this to remove last blank spaces in case of Tab.
	$i=0;
	foreach (split(/\t/,$_))
	{
		$outline[$i] .= $_."\t";
		$i++;
	}
}
close (INPUT);
open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
foreach (@outline)
{
	print OUTPUT $_."\n";
}
close (OUTPUT);
__END__

=head1 NAME

row2col.pl - Convert rows to columns

=head1 SYNOPSIS

row2col.pl [options]

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

Input data from a file in Tab delimited text format. Each line in the input line must have the same columns.

=item B<-output>

Output data to a file.

=back

=head1 DESCRIPTION

B<row2col> will transpose the data from rows to columns in table.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

addCol.pl rmCol.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
