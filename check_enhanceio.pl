#!/usr/bin/perl -w
#
# Nagios plugin to monitor EnhanceIO
#
# License: GPL3
# Copyright (c) by Andreas Unterkircher, unki@netshadow.at
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use vars qw($PROGNAME $VERSION $output $result);
use Nagios::Plugin;
use File::Basename;

$PROGNAME = basename($0);
$VERSION = '0.1';

my $np = Nagios::Plugin->new(
  usage => "Usage: %s -C <cache>\n"
    . '    [ -V ] [ -h ]',
  version => $VERSION,
  plugin  => $PROGNAME,
  shortname => uc($PROGNAME),
  blurb => 'Plugin for monitoring EnhanceIO',
  extra   => "Supported commands :\n"
    . "\n\nCopyright (c) Andreas Unterkircher, unki\@netshadow.at"
); 

$np->add_arg(
  spec => 'cache|C=s',
  help => "-C, --cache=<cache>\n"
    . "   Cache name. If ALL, plugin will check all caches\n",
  required => 1,
);

$np->getopts;

my $findcache = $np->opts->cache;
my @caches = </proc/enhanceio/*>;
my %cachestates;
my $perfdata = "";

foreach my $cache (@caches) {

   next if ($cache eq "/proc/enhanceio/version");
   next if ($findcache ne "ALL" && $findcache ne basename($cache));

   my $cachename = basename($cache);

   # get state from /proc/enhanceio/$cache/config
   my $state;
   open(STATE, $cache."/config");
   while(<STATE>) {

      my $line = $_;
      next if $line !~ /state/;

      $line =~ /state\s+([a-z]+)/;
      $state = $1;
      last;
   }
   close(STATE);

   # get error counters from /proc/enhanceio/$cache/errors
   my %errors;
   open(STATE, $cache."/errors");
   while(<STATE>) {
      my $line = $_;
      $line =~ /(^[a-z_]+)\s+(\d*)/;
      $errors{$1} = $2;
   }
   close(STATE);

   # get statistics counters from /proc/enhanceio/$cache/stats
   my %stats;
   open(STATE, $cache."/stats");
   while(<STATE>) {
      my $line = $_;
      $line =~ /(^[a-z_]+)\s+(\d*)/;
      $stats{$1} = $2;
   }
   close(STATE);

   for(keys %errors) {
      my $counter = $_;
      $np->add_perfdata(
         label => $cachename ."_". $counter,
         value => $errors{$counter},
         uom => "c"
      ); 
   }

   for(keys %stats) {
      my $counter = $_;
      my $uom;
      if($counter =~ /_pct/) {
         $uom = "%";
      } else {
         $uom = "c";
      }
      $np->add_perfdata(
         label => $cachename ."_". $counter,
         value => $stats{$counter},
         uom => $uom
      ); 
   }

   $cachestates{$cachename} = {
      state => $state,
      errors => %errors,
      stats => %stats
   };
    
}

if(!%cachestates) {
   $np->nagios_exit(WARNING, "no caches found");
}

my $overallstate = OK;
my $retval = "";

for(keys %cachestates) {

   my $cache = $_;

   if($cachestates{$cache}{'state'} ne "normal") {
      $overallstate = CRITICAL;
      $retval.= $cache .": state not normal, ";
   }
   else {
      $retval.= $cache .": state normal, ";
   }
}

$retval =~ s/,\s$//;

$np->nagios_exit($overallstate, $retval);
