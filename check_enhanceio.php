<?php

#
# pnp4nagios plugin for check_enhanceio.pl
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
#

// swap the $NAME array to faster locate our statistics later
$stats = Array();
foreach($NAME as $k => $v) {
   $stats[$v] = $k;
}

// every EnhanceIO statistic is prefixed by the cache name.
// we loop to all known data sources and extract the prefix
// of their names to have a list of caches we have to take
// care about.
// locate caches we have to care about
$caches = Array();
$matches = Array();
foreach(array_keys($stats) as $item) {

   // extract the prefix from the data sources name
   if(!preg_match("/(^[a-z]+)_.*/", $item, $matches))
      continue;

   // skip if we already know this cache
   if(array_search($matches[1], $caches) !== false)
      continue;

   // push the newly found name to $caches array
   array_push($caches, $matches[1]);
}

// this counter gets increment by every graph
$cnt=1;

// iterate over all known caches
foreach($caches as $cache) {

   // read statistics
   $reads = $cache ."_reads";
   $read_cache = $cache ."_readcache";
   $read_hits = $cache ."_read_hits";
   $read_errors_disk = $cache ."_disk_read_errors";
   $read_errors_ssd = $cache ."_ssd_read_errors";

   // write statistics
   $writes = $cache ."_writes";
   $write_cache = $cache ."_writecache";
   $write_hits = $cache ."_write_hits";
   $write_errors_disk = $cache ."_disk_write_errors";
   $write_errors_ssd = $cache ."_ssd_write_errors";

   // read and write percentage
   $read_pct = $cache ."_read_hit_pct";
   $write_pct = $cache ."_write_hit_pct";

   // others
   $memory_alloc_errors = $cache ."_memory_alloc_errors";
   $nr_dirty = $cache ."_nr_dirty";

   /**
    * read/write percentage
    */
   $ds_name[$cnt] = "read/write cache hit percentage";
   $opt[$cnt] = sprintf('-l 0 --vertical-label "Percent" --title "%s / %s"', $hostname, $ds_name[1]);
   $def[$cnt] = '';
   $def[$cnt].= rrd::def("var1", $RRDFILE[$stats[$read_pct]], $DS[$stats[$read_pct]], 'AVERAGE');
   $def[$cnt].= rrd::def("var2", $RRDFILE[$stats[$write_pct]], $DS[$stats[$write_pct]], 'AVERAGE');
   $def[$cnt].= rrd::line2 ("var1", rrd::color(0), "Read");
   $def[$cnt].= rrd::line2 ("var2", rrd::color(1), "Write");
   $cnt++;

   /**
    * read statistics
    */
   $ds_name[$cnt] = "read statistics";
   $opt[$cnt] = sprintf('-l 0 --vertical-label "Reads" --title "%s / %s"', $hostname, $ds_name[$cnt]);
   $def[$cnt] = '';
   $def[$cnt].= rrd::def("var1", $RRDFILE[$stats[$reads]], $DS[$stats[$reads]], 'AVERAGE');
   $def[$cnt].= rrd::def("var2", $RRDFILE[$stats[$read_cache]], $DS[$stats[$read_cache]], 'AVERAGE');
   $def[$cnt].= rrd::def("var3", $RRDFILE[$stats[$read_hits]], $DS[$stats[$read_hits]], 'AVERAGE');
   $def[$cnt].= rrd::line2 ("var1", rrd::color(0), "Read");
   $def[$cnt].= rrd::line2 ("var2", rrd::color(1), "Read Cache");
   $def[$cnt].= rrd::line2 ("var3", rrd::color(2), "Read Hits");
   $cnt++;

   /**
    * write statistics
    */
   $ds_name[$cnt] = "write statistics";
   $opt[$cnt] = sprintf('-l 0 --vertical-label "Writes" --title "%s / %s"', $hostname, $ds_name[$cnt]);
   $def[$cnt] = '';
   $def[$cnt].= rrd::def("var1", $RRDFILE[$stats[$writes]], $DS[$stats[$writes]], 'AVERAGE');
   $def[$cnt].= rrd::def("var2", $RRDFILE[$stats[$write_cache]], $DS[$stats[$write_cache]], 'AVERAGE');
   $def[$cnt].= rrd::def("var3", $RRDFILE[$stats[$write_hits]], $DS[$stats[$write_hits]], 'AVERAGE');
   $def[$cnt].= rrd::line2 ("var1", rrd::color(0), "Write");
   $def[$cnt].= rrd::line2 ("var2", rrd::color(1), "Write Cache");
   $def[$cnt].= rrd::line2 ("var3", rrd::color(2), "Write Hits");
   $cnt++;

   /**
    * errors
    */
   $ds_name[$cnt] = "error statistics";
   $opt[$cnt] = sprintf('-l 0 --vertical-label "Errors" --title "%s / %s"', $hostname, $ds_name[$cnt]);
   $def[$cnt] = '';
   $def[$cnt].= rrd::def("var1", $RRDFILE[$stats[$read_errors_disk]], $DS[$stats[$read_errors_disk]], 'AVERAGE');
   $def[$cnt].= rrd::def("var2", $RRDFILE[$stats[$read_errors_ssd]], $DS[$stats[$read_errors_ssd]], 'AVERAGE');
   $def[$cnt].= rrd::def("var3", $RRDFILE[$stats[$write_errors_disk]], $DS[$stats[$write_errors_disk]], 'AVERAGE');
   $def[$cnt].= rrd::def("var4", $RRDFILE[$stats[$write_errors_ssd]], $DS[$stats[$write_errors_ssd]], 'AVERAGE');
   $def[$cnt].= rrd::line2 ("var1", rrd::color(0), "Read Errors Disk");
   $def[$cnt].= rrd::line2 ("var2", rrd::color(1), "Read Errors SSD");
   $def[$cnt].= rrd::line2 ("var3", rrd::color(2), "Write Errors Disk");
   $def[$cnt].= rrd::line2 ("var4", rrd::color(3), "Write Errors SSD");
   $cnt++;

   /**
    * memory allocation errors
    */
   $ds_name[$cnt] = "memory allocation error statistics";
   $opt[$cnt] = sprintf('-l 0 --vertical-label "Errors" --title "%s / %s"', $hostname, $ds_name[$cnt]);
   $def[$cnt] = '';
   $def[$cnt].= rrd::def("var1", $RRDFILE[$stats[$memory_alloc_errors]], $DS[$stats[$memory_alloc_errors]], 'AVERAGE');
   $def[$cnt].= rrd::line2 ("var1", rrd::color(0), "Memory Allocation Errors");
   $cnt++;

   /**
    * number of dirty pages backlog
    */
   $ds_name[$cnt] = "dirty pages backlog";
   $opt[$cnt] = sprintf('-l 0 --vertical-label "Number" --title "%s / %s"', $hostname, $ds_name[$cnt]);
   $def[$cnt] = '';
   $def[$cnt].= rrd::def("var1", $RRDFILE[$stats[$nr_dirty]], $DS[$stats[$nr_dirty]], 'AVERAGE');
   $def[$cnt].= rrd::line2 ("var1", rrd::color(0), "Dirty Pages");
   $cnt++;

   //error_log(print_r($matches, TRUE));
   //$def[1] .= rrd::line2 ("var2", rrd::color(1), rrd::cut(ucfirst($NAME[$stats[$write_pct]]), 15));
   //$def[1] .= rrd::gprint  ("var1", array('LAST','MAX'), "%4.2lf %s\\t");
   //$def[1] .= rrd::gprint  ("var2", array('LAST','MAX'), "%4.2lf %s\\t");
}

?>
