#!/usr/bin/env -S perl -w

use Bio::DB::Fasta;

my $usage = "Usage: RPFpeptidePredict.pl <cdsCGFF> <genomeFasta> <RPFcoverageArray> <outFilename>\n";
my $cdsCGFF = shift or die $usage; 
my $genomeFasta = shift or die $usage;
my $RPFcoverage = shift or die $usage; # ribosome-protect fragment 
my $outFilename = shift or die $usage;

my $genomeDB = Bio::DB::Fasta->new($genomeFasta);
my %genetic_code = getTranslateMap();

# cds 
my %geneInfoHoA=();
my %cdsHoA=();
open(FILE,"<$cdsCGFF");
my $seqId;
while(<FILE>) {
	my $line = trim($_);
	my @token = split(/\s+/, $line);
	if($line=~/^>/) {
		$seqId = substr($token[0],1);
		$geneInfoHoA{$seqId} = \@token; # id, chr, start, stop, strand
	}else{
		push @{$cdsHoA{$seqId}}, [$token[0],$token[1]]; # start, stop
	}
}
close FILE;

# size of each block
my %blockSizes=();
for my $id(keys %geneInfoHoA){
	my @sizes;
	push @sizes, ($$_[1]-$$_[0]+1) for(@{$cdsHoA{$id}});
	@{$blockSizes{$id}} = ($geneInfoHoA{$id}[4] eq "+")? @sizes : reverse @sizes;
}

# start position (0-base) of each block 
my %blockStarts=();
for my $id(keys %blockSizes){
	my $prev=0;
	for my $size(@{$blockSizes{$id}}){
		push @{$blockStarts{$id}}, $prev;
		$prev += $size;
	}
}

# RPF 
my %rpfHoA=();
open(FILE,"<$RPFcoverage");
while(<FILE>){
	next if /^#/; 
	my $line=trim($_);
	my @token=split(/\t/,$line); #GeneID, chr, start, readCnt, CoverageArray

	$token[4] =~ /\[(.+)\]/;
	my @array=split(/,\s/,$1); 
	
	my $idx1; 
	my $idx2;
	for my $i (0..(@array-1)){ 
		if($array[$i]>0){ 
			$idx1=$i if not defined $idx1; 
			$idx2=$i; 
		}
	} 
	@{$rpfHoA{$token[0]}}=($token[2]+$idx1, $token[2]+$idx2); 
}
close FILE;

# Main processing
open(OUT,">$outFilename");
print OUT "#geneID\tchr\tstart\tstop\tRPF_start\tRPF_stop\torfID\tAA_start\tAA_stop\tAA_seq\n";

my $orfNum = 1;
for my $ID (sort {$a cmp $b} keys %rpfHoA){
	my ($Chr,$strand) = ($geneInfoHoA{$ID}[1],$geneInfoHoA{$ID}[4]);
	my ($geneStart,$geneStop) = ($geneInfoHoA{$ID}[2],$geneInfoHoA{$ID}[3]);
	my ($rpfStart,$rpfStop) = ($strand eq "+")? @{$rpfHoA{$ID}} : reverse @{$rpfHoA{$ID}};
	my @cdsAoA;
	if($strand eq "+"){
		push @cdsAoA, [@$_] for(@{$cdsHoA{$ID}});
	}else{
		my @reversedAoA = reverse @{$cdsHoA{$ID}};
		push @cdsAoA, [reverse @$_] for(@reversedAoA);
	}

	# define the start and stop of investigating region
	my ($srhBeginPos,$srhEndPos) = (0,0); 
	my ($startIntronic,$stopIntronic) = (1,1); 
	for(my $i=0;$i<@cdsAoA;$i++){
		my ($pos1, $pos2) = sort {$a<=>$b} @{$cdsAoA[$i]};
		if( $pos1<=$rpfStart && $rpfStart<=$pos2 ){
			my $num = abs($rpfStart - ${$cdsAoA[$i]}[0]) + 1;
			$srhBeginPos = ${$blockStarts{$ID}}[$i] + $num - 130; 
			$startIntronic=0;
			last;
		}
	}
	if($startIntronic){
		for(my $i=0;$i<@cdsAoA; $i++){
			if( ($strand eq "+" && ${$cdsAoA[$i]}[0] > $rpfStart) || ($strand eq "-" && ${$cdsAoA[$i]}[0] < $rpfStart) ){
				$srhBeginPos = ${$blockStarts{$ID}}[$i] + 1 - 130;
				last;
			}	
		}
	}
	
	for(my $i=0;$i<@cdsAoA;$i++){
		my ($pos1, $pos2) = sort {$a<=>$b} @{$cdsAoA[$i]};
		if( $pos1<=$rpfStop && $rpfStop<=$pos2 ){	
			my $num = abs($rpfStop - ${$cdsAoA[$i]}[0]) + 1;
			$srhEndPos = ${$blockStarts{$ID}}[$i] + $num + 130; 
			$stopIntronic=0;
			last;
		}
	}
	if($stopIntronic){
		for(my $i=0;$i<@cdsAoA; $i++){
			if( ($strand eq "+" && ${$cdsAoA[$i]}[0] > $rpfStop) || ($strand eq "-" && ${$cdsAoA[$i]}[0] < $rpfStop) ){
				$srhEndPos = ${$blockStarts{$ID}}[$i-1] + ${$blockSizes{$ID}}[$i-1] + 130;
				last;
			} 
		}
	}
	
	# generate the sequence for investigating
	my $Seq="";
	$Seq .= $genomeDB->seq($Chr, $$_[0]=>$$_[1]) for(@{$cdsHoA{$ID}});
	$Seq = getRC($Seq) if($strand eq "-");
	
	if($srhBeginPos < 1){ 
		my $upseq;
		if($strand eq "+"){
			$upseq = $genomeDB->seq($Chr, ($cdsAoA[0][0]-(1-$srhBeginPos))=>($cdsAoA[0][0]-1));
		}else{
			$upseq = $genomeDB->seq($Chr, ($cdsAoA[0][0]+1)=>($cdsAoA[0][0]+(1-$srhBeginPos)));
			$upseq = getRC($upseq);
		}
		$Seq = $upseq . $Seq;
	}else{
		$Seq = substr $Seq, $srhBeginPos-1;
	}
	
	my $dist = $srhEndPos - (${$blockStarts{$ID}}[-1] + ${$blockSizes{$ID}}[-1]);
	if($dist > 0){
		my $downseq;
		if($strand eq "+"){
			$downseq = $genomeDB->seq($Chr, ($cdsAoA[-1][1]+1)=>(${$cdsAoA[-1]}[1]+$dist));
		}else{
			$downseq = $genomeDB->seq($Chr, ($cdsAoA[-1][1]-$dist)=>($cdsAoA[-1][1]-1));
			$downseq = getRC($downseq);
		}
		$Seq = $Seq . $downseq;
		
		# update
		${$blockSizes{$ID}}[-1] = ${$blockSizes{$ID}}[-1] + length($downseq);
		${$cdsAoA[-1]}[1] = ($strand eq "+")? ${$cdsAoA[-1]}[1] + length($downseq) : ${$cdsAoA[-1]}[1] - length($downseq);
	}else{
		$Seq = substr $Seq, 0, (length($Seq) + $dist);
		
		# update
		my $k;
		for($k=0; $k<@{$blockStarts{$ID}}; $k++){
			last if( ${$blockStarts{$ID}}[$k] < $srhEndPos && $srhEndPos <= (${$blockStarts{$ID}}[$k]+${$blockSizes{$ID}}[$k]) );
		}
		splice @{$blockStarts{$ID}}, ($k+1);
		splice @{$blockSizes{$ID}}, ($k+1);
		splice @cdsAoA, ($k+1);

		$dist = $srhEndPos - (${$blockStarts{$ID}}[-1] + ${$blockSizes{$ID}}[-1]); # WDLIN

		${$blockSizes{$ID}}[-1] = ${$blockSizes{$ID}}[-1] + $dist;
		${$cdsAoA[-1]}[1] = ($strand eq "+")? ${$cdsAoA[-1]}[1] + $dist : ${$cdsAoA[-1]}[1] - $dist;
	}
	
	# search for start codons
	my @atgIndexes = ();
	my $idx = index $Seq, "ATG";
	while($idx != -1){
		push @atgIndexes, $idx;
		$idx = index $Seq, "ATG", ($idx+1);
	}
	if(@atgIndexes==0){
		print OUT "$ID\t$Chr\t$geneStart\t$geneStop\t$rpfStart\t$rpfStop\t\t\t\tno ATG\n";
		next;
	}
	
	# ORFs 
	for my $atgIdx (@atgIndexes){
		my $orfSeq = substr $Seq, $atgIdx;
		my @blockSizeArr = @{$blockSizes{$ID}};
		my @cloneAoA = ();
		push @cloneAoA, [@$_] for (@cdsAoA);
		
		# offset of 3-mer
		my $offset = 3-(length($orfSeq)%3);
		if($offset<3){
			my $piece;
			if($strand eq "+"){
				$piece = $genomeDB->seq($Chr, (${$cloneAoA[-1]}[1]+1)=>(${$cloneAoA[-1]}[1]+$offset));
			}else{
				$piece = $genomeDB->seq($Chr, (${$cloneAoA[-1]}[1]-$offset)=>(${$cloneAoA[-1]}[1]-1));
				$piece = getRC($piece);
			}
			$orfSeq .= $piece;

			${$cloneAoA[-1]}[1] = ($strand eq "+")? ${$cloneAoA[-1]}[1] + $offset : ${$cloneAoA[-1]}[1] - $offset;
			$blockSizeArr[-1] = $blockSizeArr[-1] + $offset;
		}
		
		# elongate until encounter a stop codon if necessary
		if(seq2aa($orfSeq) !~ /\*/){
			my $extSeq = "";
			if($strand eq "+"){
				for(my $p = (${$cloneAoA[-1]}[1]+1); $p <= $genomeDB->length($Chr); $p+=3) {
					my $codon = $genomeDB->seq($Chr,$p=>$p+2);
					$extSeq .= $codon;
					last if exists $genetic_code{$codon} && $genetic_code{$codon} eq "*";
				}
			}else{
				for(my $p = (${$cloneAoA[-1]}[1]-1); $p >= 1; $p-=3) {
					my $codon = $genomeDB->seq($Chr,$p-2=>$p);
					$codon = getRC($codon);
					$extSeq .= $codon;
					last if exists $genetic_code{$codon} && $genetic_code{$codon} eq "*";
				}
			}
			$orfSeq .= $extSeq;

			$blockSizeArr[-1] = $blockSizeArr[-1] + length($extSeq);
			${$cloneAoA[-1]}[1] = ($strand eq "+")? ${$cloneAoA[-1]}[1] + length($extSeq) : ${$cloneAoA[-1]}[1] - length($extSeq);
		}
		
		# translation
		my $pep = seq2aa($orfSeq);
		
		# extract seq end with stop codon
		next if index($pep,"*") == -1;
		my $AAseq = substr $pep, 0, (index($pep,"*") + 1); 
		my $startCodonPos = $srhBeginPos + $atgIdx;
		my $stopCodonPos = $startCodonPos + (length($AAseq)*3) - 1;
		
		# translation start site
		my $TSS = getGenomeSite($startCodonPos, $blockStarts{$ID}, \@blockSizeArr, \@cloneAoA, $strand);
		# translation stop site
		my $TTS = getGenomeSite($stopCodonPos, $blockStarts{$ID}, \@blockSizeArr, \@cloneAoA, $strand);
	
		print OUT "$ID\t$Chr\t$geneStart\t$geneStop\t$rpfStart\t$rpfStop\tORF_$orfNum\t$TSS\t$TTS\t$AAseq\n";
		$orfNum++;
	}
	
}
close OUT;


# subroutines
sub trim {
	my $str=shift;
	$str =~ s/(^\s+|\s+$)//g;
	return $str;
}

sub getTranslateMap{
	my (%retuenMap) = (
		'TCA' => 'S',    #Serine
		'TCC' => 'S',    #Serine
		'TCG' => 'S',    #Serine
		'TCT' => 'S',    #Serine
		'TCN' => 'S',    #Serine
		'TTC' => 'F',    #Phenylalanine
		'TTT' => 'F',    #Phenylalanine
		'TTA' => 'L',    #Leucine
		'TTG' => 'L',    #Leucine
		'TAC' => 'Y',    #Tyrosine
		'TAT' => 'Y',    #Tyrosine
		'TAA' => '*',    #Stop
		'TAG' => '*',    #Stop
		'TGC' => 'C',    #Cysteine
		'TGT' => 'C',    #Cysteine
		'TGA' => '*',    #Stop
		'TGG' => 'W',    #Tryptophan
		'CTA' => 'L',    #Leucine
		'CTC' => 'L',    #Leucine
		'CTG' => 'L',    #Leucine
		'CTT' => 'L',    #Leucine
		'CTN' => 'L',    #Leucine
		'CAT' => 'H',    #Histidine
		'CAC' => 'H',    #Histidine
		'CAA' => 'Q',    #Glutamine
		'CAG' => 'Q',    #Glutamine
		'CGA' => 'R',    #Arginine
		'CGC' => 'R',    #Arginine
		'CGG' => 'R',    #Arginine
		'CGT' => 'R',    #Arginine
		'CGN' => 'R',    #Arginine
		'ATA' => 'I',    #Isoleucine
		'ATC' => 'I',    #Isoleucine
		'ATT' => 'I',    #Isoleucine
		'ATG' => 'M',    #Methionine
		'ACA' => 'T',    #Threonine
		'ACC' => 'T',    #Threonine
		'ACG' => 'T',    #Threonine
		'ACT' => 'T',    #Threonine
		'ACN' => 'T',    #Threonine
		'AAC' => 'N',    #Asparagine
		'AAT' => 'N',    #Asparagine
		'AAA' => 'K',    #Lysine
		'AAG' => 'K',    #Lysine
		'AGC' => 'S',    #Serine
		'AGT' => 'S',    #Serine
		'AGA' => 'R',    #Arginine
		'AGG' => 'R',    #Arginine
		'CCA' => 'P',    #Proline
		'CCC' => 'P',    #Proline
		'CCG' => 'P',    #Proline
		'CCT' => 'P',    #Proline
		'CCN' => 'P',    #Proline
		'GTA' => 'V',    #Valine
		'GTC' => 'V',    #Valine
		'GTG' => 'V',    #Valine
		'GTT' => 'V',    #Valine
		'GTN' => 'V',    #Valine
		'GCA' => 'A',    #Alanine
		'GCC' => 'A',    #Alanine
		'GCG' => 'A',    #Alanine
		'GCT' => 'A',    #Alanine
		'GCN' => 'A',    #Alanine
		'GAC' => 'D',    #Aspartic Acid
		'GAT' => 'D',    #Aspartic Acid
		'GAA' => 'E',    #Glutamic Acid
		'GAG' => 'E',    #Glutamic Acid
		'GGA' => 'G',    #Glycine
		'GGC' => 'G',    #Glycine
		'GGG' => 'G',    #Glycine
		'GGT' => 'G',    #Glycine
		'GGN' => 'G',    #Glycine
	);
	return %retuenMap;
}

sub seq2aa{
	my $seq=uc $_[0];
	my $Ns = 3-(length($seq)%3);
	$seq .= 'N' x $Ns if $Ns < 3;  # complement Sequence to 3mer
	
	my $AA_seq='';
	for $k (0 .. length($seq)/3-1) {
		my $codon = substr($seq,3*$k,3);
		
		if(exists $genetic_code{$codon}) {
			$AA_seq.=$genetic_code{$codon};
		}else{
			$AA_seq.="x";
		}
	}
	return $AA_seq;
}

sub getRC{
	my $seq=shift;
	$seq = reverse $seq;
	$seq =~ tr/ATCG/TAGC/;	
	return $seq;
}

# getGenomeSite($startCodonPos, $blockStarts{$ID}, $blockSizes{$ID}, @cdsAoA, $strand)
sub getGenomeSite {
	my $Pos = $_[0];
	my @block_starts = @{$_[1]};
	my @block_sizes = @{$_[2]};
	my @cds_AoA = @{$_[3]};
	my $strand = $_[4];
	
	my $gSite=0;
	if($Pos < 1){
		$gSite = ($strand eq "+")? $cds_AoA[0][0] - (1-$Pos) : $cds_AoA[0][0] + (1-$Pos);
		return $gSite;
	}
	
	for(my $i=0; $i<@block_starts; $i++){
		if( $block_starts[$i] < $Pos && $Pos <= ($block_starts[$i]+$block_sizes[$i]) ){
			my $step = $Pos - $block_starts[$i] - 1;
			$gSite = ($strand eq "+")? ${$cds_AoA[$i]}[0] + $step : ${$cds_AoA[$i]}[0] - $step;
			last;
		}
	}
	return $gSite;
}
