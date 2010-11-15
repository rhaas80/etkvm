#!/usr/bin/perl -w
use strict;
use Text::BibTeX;
use Date::Manip;
use Pod::Usage;
use Getopt::Long;

=head1 NAME 

parse_bibtex - parse bibtex file, and sort and/or filter it

=cut

# parse command line options
my $inputfilename = undef;
my $status_s = undef;
my $keys_s   = undef;
my $sort     = undef;
my $short    = undef;
my $rsort    = undef;
my $help     = undef;

=head1 OPTIONS

=over 4

=item B<--input=<filename>>

Specify input file name

=item B<--status=<list>>

Filters for given 'status' fields

=item B<--keys=<list>>

Filters for keys in given list

=item B<--sort|-reversesort>

Sorts entries by 'receiveddate' field

=item B<--short>

Only prints keys

=item B<--help>

Prints this help message and exits

=cut

GetOptions('input=s'     => \$inputfilename,
           'status=s'    => \$status_s,
           'keys=s'      => \$keys_s,
           'sort'        => \$sort,
           'short'       => \$short,
           'reversesort' => \$rsort,
           'help'        => \$help,
          ) or pod2usage(-verbose=>2);
if (defined($help)) {
  pod2usage(1);
}

if (defined($sort) and defined($rsort)) {
  die("The two options --sort and --reversesort cannot be used together.");
}
if (!defined($inputfilename)) { $inputfilename = "references.bib"; }
print "-> $inputfilename\n";

my $infile  = new Text::BibTeX::File $inputfilename;
my @entries = ();
my $out     = "";

# populate @entries with data from $infile
my $entry = 0;
while ($entry = new Text::BibTeX::Entry $infile) {
  push(@entries, $entry);
}
# filter @entries
if (defined($status_s)) {
  my %status;
  if ($status_s =~ /,/) {
    %status = map {$_=>1} split(",", $status_s);
  } else {
    %status = map {$_=>1} split(" ", $status_s);
  }
  @entries = grep {$status{$_->get('status')}} @entries;
}
if (defined($keys_s)) {
  my %keys;
  if ($keys_s =~ /,/) {
    %keys = map {$_=>1} split(",", $keys_s);
  } else {
    %keys = map {$_=>1} split(" ", $keys_s);
  }
  @entries = grep {$keys{$_->key()}} @entries;
}
# sort @entries
if (defined($sort)) {
  @entries = sort {  Date_Cmp($a->get('receiveddate'), $b->get('receiveddate')) } @entries;
}
if (defined($rsort)) {
  @entries = sort { -Date_Cmp($a->get('receiveddate'), $b->get('receiveddate')) } @entries;
}
# generate output
foreach my $entry (@entries) {
  if (!defined($short)) {
    $out .= $entry->print_s();
  } else {
    $out .= $entry->key()."\n";
  }
}
print $out;

