#!/usr/local/bin/perl -w
#
# This script draw a PNG figure from a table file.
use GD;

#please note, the first data line should be the whole coordinator

#sample data
#>cen8_OB	1080570	grey
#Cen8.t00464.1	50431	52635	pink	exon
#Cen8.t00481.1	72426	82718	pink	intron
#Cen8.t00506.1	89701	90573	pink	exon
#

#pre-defined band types
@bandtype=(
"gene",
"exon",
"intron",
);

print "Please input data file name:";
chop($datafile=<STDIN>);

print "Please input image width (>=500, default 2000 pixels):";
chop($imgwidth=<STDIN>);
if(($imgwidth eq "")||($imgwidth =~ /\D/)||($imgwidth < 500))
{
	$imgwidth=2000;
}

print "Please input image margin (>=5, default 5 pixels):";
chop($margin=<STDIN>);
if(($margin eq "")||($margin =~ /\D/)||($margin < 5))
{
	$margin=5;
}

print "Please input bar height (>=10, default 10 pixels):";
chop($barheight=<STDIN>);
if(($barheight eq "")||($barheight =~ /\D/)||($barheight < 10))
{
	$barheight=10;
}

$maxmargin=$margin*2+$barheight;

%bandheight=();
foreach (@bandtype)
{
	print "Please input annotation $_ height (<= $maxmargin, default $barheight pixels):";
	chop($bandheight{$_}=<STDIN>);
	if(($bandheight{$_} eq "")||($bandheight{$_} =~ /\D/)||($bandheight{$_} > $maxmargin))
	{
		$bandheight{$_}=$barheight;
	}
}

print "Please type output file name(default $datafile.png):";
chop($outputfile=<STDIN>);
if($outputfile eq "")
{
	$outputfile=$datafile.".png";
}
if($outputfile !~ /\.png$/ig)
{
	$outputfile .= ".png";
}

$groupnumber=0;
$maxgrouplength=0;
$maxgroupidlength=0;
open (DATAFILE,"$datafile") or die "can't open DATA-FILE: $datafile!";
while(<DATAFILE>)
{
	chomp;
	/^#/ and next;
	if(/^>/)
	{
		$group=$';
		@group=split(/\t/,$group);
		if($group[1] > $maxgrouplength)
		{
			$maxgrouplength = $group[1];
		}
		if(length ($group[0]) > $maxgroupidlength)
		{
			$maxgroupidlength=length ($group[0]);
		}
		$groupnumber++;
		next;
	}
	else
	{
		push @{$group{$group}},$_;
	}
}
close (DATAFILE);


$imgheight=$groupnumber*$maxmargin;
$unitlength=($imgwidth-$margin*2)/$maxgrouplength;

#gdSmallFont 6x12; gdLargeFont 8x16; gdMediumBoldFont 7x13; gdTinyFont 5x8; gdGiantFont 9x15;
$fontw=6; #use gdSmallFont
$fonth=12;

$lblwidth = ($maxgroupidlength+1)*$fontw;
$imgwidth += $lblwidth;
# create a new image
$im = new GD::Image($imgwidth,$imgheight);

# allocate some colors
$color{white}= $im->colorAllocate(255,255,255);
$color{black} = $im->colorAllocate(0,0,0);       
$color{red} = $im->colorAllocate(255,0,0);      
$color{blue} = $im->colorAllocate(0,0,255);
$color{green} = $im->colorAllocate(0,255,0);
$color{coral} = $im->colorAllocate(255,127,80);
$color{grey} = $im->colorAllocate(128,128,128);
$color{pink} = $im->colorAllocate(255,192,203);


## make the background transparent and interlaced
$im->transparent($color{white});
$im->interlaced('true');
#
## Put a black frame around the picture

$im->rectangle(0,0,$imgwidth-1,$imgheight-1,$color{black});

$groupnumber=0;
$objectnumber=0;
foreach (keys %group)
{
	@group=split(/\t/,$_);

	$im->filledRectangle($margin+$lblwidth,$groupnumber*$maxmargin+$margin,$margin+$lblwidth+$group[1]*$unitlength,$groupnumber*$maxmargin+$margin+$barheight,$color{$group[2]});
	$im->string(gdSmallFont,$margin,$groupnumber*$maxmargin+$margin+($barheight-$fonth)/2,$group[0],$color{black});
	
	foreach (@{$group{$_}})
	{
		$objectnumber++;
		@objectline=split(/\t/,$_);
		$im->filledRectangle($margin+$lblwidth+$objectline[1]*$unitlength,$groupnumber*$maxmargin+($maxmargin-$bandheight{$objectline[4]})/2,$margin+$lblwidth+$objectline[2]*$unitlength,$groupnumber*$maxmargin+($maxmargin+$bandheight{$objectline[4]})/2,$color{$objectline[3]});		
	}
	$groupnumber++;
}


#create a png file
open (IMHANDLE,">$outputfile");
# make sure we are writing to a binary stream
binmode IMHANDLE;
print IMHANDLE $im->png;
close (IMHANDLE);

print "$objectnumber objects ($groupnumber groups) were drawn in $outputfile.\n";