#!/usr/bin/env perl
 
use Excel::Writer::XLSX;

my $usage = "Usage: tsv2xlsx.pl <TSV> <XLSX> <sheet_name>\n";

my $tsvFile   = shift or die $usage;
my $xlsxFile  = shift or die $usage;
my $sheetName = shift or die $usage;

# avoiding override existing files
if(-e "$xlsxFile"){
    die "File $xlsxFile exists! Stopped.\n";
}

# Create a new Excel workbook
my $workbook = Excel::Writer::XLSX->new($xlsxFile);
die "Problems creating new Excel file: $!" unless defined $workbook;

# Add a worksheet
my $worksheet = $workbook->add_worksheet($sheetName);

open(FILE,"<$tsvFile");
my $rowCnt = 0;
while(<FILE>){
    my @t=split(/\t/);
    for(my $colCnt=0; $colCnt<@t; $colCnt++){
        $worksheet->write($rowCnt,$colCnt,$t[$colCnt]);
    }
    $rowCnt++;
}
close FILE;
 
$workbook->close();
