#!/usr/local/bin/perl -w
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $postfix = '';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'postfix=s' => \$postfix,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input);

open (INPUT,"$input") or die "can't open input FILE: $!";
while(<INPUT>)
{
	my @line=split (/\t/, $_);
	my $outputfile=shift @line;
	$outputfile .=".$postfix" if $postfix;
	open (OUTPUT,">$outputfile") or die "can't open output FILE: $!";
	print OUTPUT join "\n",@line;
	close (OUTPUT);
}
close (INPUT)


__END__

=head1 NAME

cvtLine2File.pl - convert list to files

=head1 SYNOPSIS

cvtLine2File.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a list file. The first column will be the name of output file.

=item B<-postfix>

Postfix of the output file.

=back

=head1 DESCRIPTION

B<cvtLine2File> will create files in a given list. Please contact author for some specific request if needed.

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
