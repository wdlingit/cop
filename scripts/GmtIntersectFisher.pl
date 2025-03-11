#!/usr/bin/env -S perl -w

use IPC::Open2;
use Data::Dumper;

# for tmp file
use strict;
use warnings;
use File::Temp;

my $usage  = "Usage: GmtIntersect4fisher.pl <geneFile> <GMT> <bkgNumber> <rackjJARpath>\n";
   $usage .= "     -group     : input <geneFile> is a two column group-gene file (default: NO)\n";

my $inputIsGroupFile = 0;

#Retrieve parameter
my @arg_idx=(0..@ARGV-1);
for my $i (0..@ARGV-1) {
	if ($ARGV[$i] eq '-group') {
		$inputIsGroupFile = 1;
		delete $arg_idx[$i];
    }
}
my @new_arg;
for (@arg_idx) { push(@new_arg,$ARGV[$_]) if (defined($_)); }
@ARGV=@new_arg;

my $geneFile = shift or die $usage;
my $gmtFile  = shift or die $usage;
my $bkgNum   = shift or die $usage;
my $jarPath  = shift or die $usage;

my $pid = open2( *queryOUT, *queryIN,"java -classpath $jarPath statistics.FisherExactTest");

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

if($inputIsGroupFile){
    my %groupGeneHash = ();

    open(FILE,"<$geneFile");
    while(<FILE>){
        chomp;
        
        my @t=split;
        $groupGeneHash{$t[0]}{$t[1]}=1;
    }
    close FILE;
    
    for my $group (keys %groupGeneHash){
        my $tempfile = File::Temp->new();
        for my $g (keys %{$groupGeneHash{$group}}){
            print $tempfile "$g\n";
        }
        close $tempfile;
        
        gmtComputeOneSet($tempfile->filename,$group);
    }
}else{
    gmtComputeOneSet($geneFile,"");
}

### subroutine
sub gmtComputeOneSet {
    my $geneSetFile = shift;
    my $groupName   = shift;

    # read gene file
    my %geneHash = ();
    
    open(FILE,"<$geneSetFile");
    while(<FILE>){
        next if /^#/;
        chomp;
        my @t=split;
        $geneHash{$t[0]}=1;
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
            print "$groupName\t" if length($groupName)>0;
            print "$id\t$setName{$id}\t$oTarget\t$oBackground\t$xTarget\t$xBackground\t";
            
            print queryIN "$oTarget\t$oBackground\t$xTarget\t$xBackground\n";
            my $msg = <queryOUT>;
            $msg =~ s/^\s+|\s+$//g;
            my @t=split(/\s+/,$msg);
            print join("\t",@t)."\n";
        }
    }

}
