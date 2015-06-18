#!/usr/bin/perl
use warnings;
use strict;
use utf8;

my $FN = $ARGV[0];
my $SMA_BINS1 = $ARGV[1];
my $SMA_BINS2 = $ARGV[2];

# API server uses in UTC in query and results

open(IN, "<${FN}")
	or die("$! , exitting");
open(OUT, ">${FN}.data")
	or die("$! , exitting");


my @sma_bins = ();
my $t_prev = -1;
my $dt_prev = 36000;	# NOTE: Big number initially, 10h
while(<IN>)
{
	my @R = split(/,/, $_, 6);

	push @sma_bins, $R[4];							# push in buffer
	shift @sma_bins								# trim the oldest, if buffer too big
		if (scalar(@sma_bins) > $SMA_BINS1);
	#print STDERR  join(":", $#sma_bins-11, $#sma_bins), "\t", join("\t", @sma_bins), "\n";
	my $sma1 = (eval join('+', @sma_bins)) / scalar(@sma_bins);		# eval buffer
	my $sma2 = $sma1;							# place for smaller buffer

	if (scalar(@sma_bins) > $SMA_BINS2)					# 
	{
		$sma2 = (eval join('+', @sma_bins[$#sma_bins-$SMA_BINS2 + 1 .. $#sma_bins])) / $SMA_BINS2;	# use only last $SMA_BINS2 bins, NOTE: OB1
	}

	print OUT join(',', $R[0], $R[4],sprintf("%0.3f,%0.3f\n", $sma1, $sma2));
}

close(OUT)
	or die("$!, exitting");
close(IN)
	or die("$! ,exitting");

print STDOUT "${FN}.data\n"; 
