#!/usr/bin/perl

# creates a diagramm file with gnuplot from temperature and humidity values 
#   from a weewx database file
#
# created_on: 2017-03-12
# created by: debock
# changed on: 2017-03-19
# software_id: 36233b42-0c2f-11e7-8dda-6c626dd6c3ad
# version: 0.3.0001
# implementation_id: 36a1728c-0c2f-11e7-8dda-6c626dd6c3ad

use strict;

### test installation of sqlite3
my $sqlite3_exe = 'sqlite3';
my $sqlite_version = `$sqlite3_exe -version`;
if ($sqlite_version eq '') {
  print "Tool $sqlite3_exe not found.\n";
  print "Quit!\n";
  exit(1);
}

### test installation of gnuplot
my $gnuplot_exe = 'gnuplot';
my $gnuplot_version = `$gnuplot_exe -V`;
if ($gnuplot_version eq '') {
  print "Tool $gnuplot_exe not found.\n";
  print "Quit!\n";
  exit(1);
}


### get command line parameter

## test number of parameters
if (@ARGV < 2) {
  print ("No data base and/or working directory given.\n");
  print ("Quit!\n");
  exit (1);
}

## get name for database file
my $file_name ='weewx-kl.sdb';
my $working_directory = '.';

if ($ARGV[0] ne '') {
  $file_name = $ARGV[0];
}

## working directory
if ($ARGV[1] ne '') {
  $working_directory = $ARGV[1];
}

### test existence of database file
my $result_file_open = open (FI, $file_name);
if (not $result_file_open) {
  print ("Could not open '$file_name': $!\n");
  exit (2);
}
close (FI);

### open data output file in working directory
my $f_tsv_out;
my $result_file_open = open ($f_tsv_out, ">$working_directory/plot_data.tsv");
if (not $result_file_open) {
  print ("Could not open output file for TSV data 'plot_data.tsv' in working directory '$working_directory': $!\n");
  exit (3);
}

### test database file
my $db_test = system ("$sqlite3_exe -batch $file_name \"select dateTime, interval, round(temp1,2), round (temp2,2) from archive where dateTime < 0;\"");

if ($db_test != 0) {
  print ("Error in database file.\n");
  print ("Exit code of $sqlite3_exe was $db_test.\n");
  print ("Quit!\n");
  exit (4);
}

### query database
my $now = time();
my $before_24h = $now - 24*3600;
my $sql_res = `$sqlite3_exe -batch $file_name "select dateTime, interval, round(temp1,2), round (temp2,2) from archive where dateTime >= $before_24h order by 1;"`;


### evaluate result records
my ($line, @vals);
my @lines = split(/\n/, $sql_res);

foreach $line(@lines)
{
  @vals = split(/\|/,$line);
}

### print data file for gnutplot
my ($sec, $min, $hour);
my $hour_timer = 0;
foreach $line(@lines)
{
  @vals = split(/\|/,$line);
  ($sec, $min, $hour) = localtime($vals[0]);
  print $f_tsv_out "$vals[0]\t$vals[2]\t$vals[5]\n";

}

close ($f_tsv_out);

### write gnuplot file

my $f_plot_out;
my $result_file_open = open ($f_plot_out, ">$working_directory/temper1.plt");
if (not $result_file_open) {
  print ("Could not open output file for plotting commands 'temper1.plt' in working directory '$working_directory': $!\n");
  exit (3);
}

print_plotfile_temper($f_plot_out, "$working_directory/plot_data.tsv");

close ($f_plot_out);

### call gnuplot
my $db_test = system ("$gnuplot_exe -c $working_directory/temper1.plt");


#############
# Subroutines

sub print_plotfile_temper
{
  my $f_out = $_[0];
  my $data_file_fullpath = $_[1];
my $plot_file_content = << 'GNUPLOT_TEMP';
# Gnuplot script

# created on: 2017-03-17
# created by: debock
# changed on: 2017-03-19
# version: 0.3.0001
# file-id: c394ad32-0c32-11e7-8dda-6c626dd6c3ad


# set SVG output
set terminal svg size 640,480 fname 'Verdana' fsize 10
set output 'temp_last24h.svg'

# fill background with white colour
set object 1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb"white" behind

# titles
set title "Temperaturverlauf in den letzten 24 Stunden" font ",12"
set ylabel 'Temperatur (°C)'

# print labels for graphs
set key

# print grid
set grid

# set interval for x tics to 1 hour (= 3600 Sekunden)
set xtics autofreq 3600
# set interval for y tics to 1 degree
set ytics autofreq 1

# set input format for x to Unix time format
set timefmt '%s'
set xdata time

# rotate x tics for higher denstity of labels
set xtics rotate right

# set output format for to hours:minutes
set format x '%H:%M'

# plot

GNUPLOT_TEMP

$plot_file_content .= "plot '$data_file_fullpath' using 1:2 with lines t 'temp1' \n";

print $f_out $plot_file_content;

}

# Subroutines
#############

