nagios-plugins
==============

* EnhanceIO

 - check_enhanceio.pl, nagios plugin to monitor EnhanceIO caches.
   requires Nagios::Plugin and File::Basename.
 - check_enhanceio.php, pnp4nagios template

* repmgr

 - check_repmgr_state.sh, nagios plugin that checks the repmgr state
   (Replication Manager for PostgreSQL clusters, www.repmgr.org)

 - check_repmgr_event.sh, a script that can be used by repmgr and gets
   trigger on an event is occuring. example repmgr.conf entry:

   event_notification_command='/usr/lib/nagios/plugins/check_repmgr_event.sh %n %e %s "%t" "%d"'
