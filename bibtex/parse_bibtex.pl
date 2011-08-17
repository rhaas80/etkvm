#!/usr/bin/perl -w
use strict;
use Text::BibTeX;
use Date::Manip;
use Pod::Usage;
use Getopt::Long;
use Data::Dumper;

=head1 NAME 

parse_bibtex - parse bibtex file, and sort and/or filter it

=cut

# parse command line options
my $inputfilename = undef;
my $keys_s   = undef;
my $sort     = undef;
my $short    = undef;
my $showkey  = undef;
my $filter_s = undef;
my $rsort    = undef;
my $help     = undef;

=head1 OPTIONS

=over 4

=item B<--input=<filename>>

Specify input file name

=item B<--keys=<list>>

Filters for keys in given list

=item B<--sort|-reversesort>

Sorts entries by 'receiveddate' field

=item B<--short>

Only prints keys

=item B<--filter=<list>>

Filter entries with define keys in list

=item B<--showkey=<key>>

Only print entry key and given key value

=item B<--help>

Prints this help message and exits

=cut

GetOptions('input=s'     => \$inputfilename,
           'keys=s'      => \$keys_s,
           'sort'        => \$sort,
           'short'       => \$short,
           'filter=s'    => \$filter_s,
           'showkey=s'   => \$showkey,
           'reversesort' => \$rsort,
           'help'        => \$help,
          ) or pod2usage(-verbose=>2);
if (defined($help) or !defined($inputfilename)) {
  pod2usage(1);
}

if (defined($sort) and defined($rsort)) {
  die("The two options --sort and --reversesort cannot be used together.");
}

my $infile  = new Text::BibTeX::File $inputfilename;
$infile->set_structure('Bib');
my @entries = ();
my $out     = "";

# populate @entries with data from $infile
my $entry = 0;
while ($entry = new Text::BibTeX::Entry $infile) {
  push(@entries, $entry);
}
# filter @entries
if (defined($filter_s)) {
  my %filter;
  my @new_entries = ();
  if ($filter_s =~ /,/) {
    %filter = map {$_=~/([^=]*)=*(.*)/; $1=>$2} split(",", $filter_s);
  } else {
    %filter = map {$_=~/([^=]*)=*(.*)/; $1=>$2} split(" ", $filter_s);
  }
  #@entries = grep {$filter{$_->get('status')}} @entries;
  # go through each specified filter key
  foreach my $one_filter (keys(%filter)) {
    # check if the key needs to be present or also have a certain value
    if ($filter{$one_filter}) {
      # only include entries with the key present and the value identical
      @new_entries = (@new_entries, grep {$_->get($one_filter)eq$filter{$one_filter}} @entries);
    } else {
      # include entries which have the specified filter key present
      @new_entries = (@new_entries, grep {$_->get($one_filter)} @entries);
    }
  }
  @entries = @new_entries;
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
  if (defined($short)) {
    $out .= $entry->key()."\n";
  } elsif (defined($showkey)) {
    $out .= $entry->key()." ".$entry->get($showkey)."\n";
  } else {
    $out .= $entry->print_s();
  }
}
print $out;

