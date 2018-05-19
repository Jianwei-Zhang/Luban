#!/usr/local/bin/perl -w
#
# 5bpdic.pl
#
# This script creat 5-bp oligos

@bp=(A,C,G,T);

open (BPDIC,">5bp.dic") or die "can't open 5bp.dic: $!";
foreach $bp1 (@bp)
{
	foreach $bp2 (@bp)
	{
		foreach $bp3 (@bp)
		{
			foreach $bp4 (@bp)
			{
				foreach $bp5 (@bp)
				{
					print BPDIC $bp1.$bp2.$bp3.$bp4.$bp5."\n";
				}
			}
		}
	}
}
close (BPDIC);

