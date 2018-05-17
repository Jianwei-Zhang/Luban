#!/usr/local/bin/perl -w
use Getopt::Long;
use Pod::Usage;

my $man = '';
my $help = '';
my $input = '';
my $output = '';
my $collist = '';

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help,
			man => \$man,
			'input=s' => \$input,
			'output=s' => \$output,
			'collist=s' => \$collist,
			)
 or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage(1) unless ($input && $output && $collist);

#prepare columns to be added
foreach (split (/,/,$collist))
{
	if(/:/)
	{
		$addcol{$`}=$';
	}
	else
	{
		$addcol{$_}=1; #set defaut to add 1 column after the position.
	}
}

open (OUTPUT,">$output") or die "can't open OUT-FILE: $!";
open (INPUT,"$input") or die "can't open input file: $!";
while(<INPUT>)
{
	chop;
	@inline=split(/\t/,$_);
	$addedcols=0;
	foreach (sort { $a <=> $b } uniq(keys %addcol))
	{
		@insert=();
		for($i=0;$i<$addcol{$_};$i++)
		{
			push @insert,"";
		}
		splice(@inline, $_+$addedcols, 0, @insert);
		$addedcols += $addcol{$_};
	}
	print OUTPUT join ("\t",@inline)."\n";
}
close (INPUT);
close (OUTPUT);

sub uniq { 
    return keys %{{ map { $_ => 1 } @_ }}; 
#       my %hash = map { $_, 1 } @array;
# or a hash slice: @hash{ @array } = ();
# or a foreach: $hash{$_} = 1 foreach ( @array );
#       my @unique = keys %hash;
} 
__END__

=head1 NAME

addCol.pl - Adding columns into a table

=head1 SYNOPSIS

addCol.pl [options]

 Options:
   -help            brief help message
   -man             full documentation
   -input           input file
   -output          output file
   -collist         column list

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-input>

Input data from a file in Tab delimited text format.

=item B<-output>

Output data to a file.

=item B<-collist>

Columns list to be added. For example,

 "-collist 1:2" means "add 2 columns after 1st column".
 "-collist 1:2,4:5" means "add 2 columns after 1st column, and 5 columns after 4th column". "1st" and "4th" are the column numbers in the input file.

Multiple insertions must be saperated by "Comma[,]". No blank-spaces allowed.

=back

=head1 DESCRIPTION

B<addCol> will add columns to a table by a given list.

=head1 AUTHOR 

Jianwei Zhang @ Arizona Genomics Institute

=head1 EMAIL

jzhang@cals.arizona.edu

=head1 BUGS

none.

=head1 SEE ALSO 

rmCol.pl row2col.pl

=head1 COPYRIGHT 

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
