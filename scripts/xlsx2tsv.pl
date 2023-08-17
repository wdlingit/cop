#!/usr/bin/env perl
 
use strict;
use Spreadsheet::ParseXLSX;

my $usage = "Usage: xlsx2tsv.pl <XLSX> <sheet index (0-base)>\n";

die $usage if @ARGV<2;

my $xlsxFile = shift;
my $sheetIdx = shift;

my $parser   = Spreadsheet::ParseXLSX->new();
my $workbook = $parser->parse($xlsxFile);
 
if ( !defined $workbook ) {
    die $parser->error(), ".\n";
}

my $worksheet = $workbook->worksheet($sheetIdx);
my ( $row_min, $row_max ) = $worksheet->row_range();
my ( $col_min, $col_max ) = $worksheet->col_range();

binmode(STDOUT, "encoding(UTF-8)");

for my $row ( 0 .. $row_max ) {
    for my $col ( 0 .. $col_max ) {

        my $cell = $worksheet->get_cell( $row, $col );

        print "\t" if $col>0;

        if(defined $cell){
            print $cell->value();
        }
    }
    print "\n";
}
