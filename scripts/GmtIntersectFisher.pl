#!/usr/bin/perl -w

use IPC::Open2;
use Data::Dumper;

$usage  = "Usage: GmtIntersect4fisher.pl <geneFile> <GMT> <bkgNumber> <rackjJARpath>\n";

my $geneFile = shift or die $usage;
my $gmtFile  = shift or die $usage;
my $bkgNum   = shift or die $usage;
my $jarPath  = shift or die $usage;

my $pid = open2( *queryOUT, *queryIN,"java -classpath $jarPath statistics.FisherExactTest");

# read gene file
my %geneHash = ();

open(FILE,"<$geneFile");
while(<FILE>){
    next if /^#/;
    chomp;
    my @t=split;
    $geneHash{$t[0]}=1;
}
close FILE;

# read GMT file
my %setName = ();
my %setGene = ();

open(FILE,"<$gmtFile");
while(<FILE>){
    next if /^#/;
    chomp;
    my @t=split(/\t/);
    my $setID = shift @t;
    my $setName = shift @t;
    
    $setName{$setID} = $setName;
    for my $x (@t){
        $setGene{$setID}{$x}=1;
    }
}
close FILE;

# for each set, compute four numbers for fisher exact test
for my $id (sort keys %setGene){

    my $oTarget=0;
    for my $x (keys %geneHash){
        $oTarget++ if exists $setGene{$id}{$x};
    }
    
    my $setNum = keys %{$setGene{$id}};
    my $oBackground = $setNum-$oTarget;

    my $targetNum = keys %geneHash;
    my $xTarget = $targetNum - $oTarget;

    my $xBackground = $bkgNum - $oTarget - $oBackground - $xTarget;
    
    if($oTarget>0){
        print "$id\t$setName{$id}\t$oTarget\t$oBackground\t$xTarget\t$xBackground\t";

        print queryIN "$oTarget\t$oBackground\t$xTarget\t$xBackground\n";
        my $msg = <queryOUT>;
        $msg =~ s/^\s+|\s+$//g;
        my @t=split(/\s+/,$msg);
        print join("\t",@t)."\n";
    }
}
