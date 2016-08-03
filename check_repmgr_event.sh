#!/bin/bash

#
# Nagios plugin to monitor repmgr [http://repmgr.org] state.
#
# This is designed as a passive plugin, that is executed by
# repmgrd and submits its result by NSCA.
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

readonly SEND_NSCA="/usr/sbin/send_nsca"
readonly NSCA_SERVER="nagios.example.com"
readonly NSCA_SERVICE="PGSQL_REPMGR_EVENTS"
readonly HOSTNAME_PREFIX=

if [ $# -lt 5 ] || \
   [ -z "$1" ] || \
   [ -z "$2" ] || \
   [ -z "$3" ] || \
   [ -z "$4" ] || \
   [ -z "$5" ]; then
   echo "UNKNOWN - invalid number of parameter provided!"
   exit 3
fi

readonly NODE_ID="$1"
readonly EVENT_TYPE="$2"
readonly SUCCESS="$3"
readonly TIMESTAMP="$4"
readonly DETAILS="$5"

if [ "x${SUCCESS}" == "x1" ]; then
   RESULT="OK"
   RETVAL=0
else
   RESULT="WARNING"
   RETVAL=1
fi

if [ -z "${DETAILS}" ]; then
   TEXT="${RESULT} - ${NODE_ID} event '${EVENT_TYPE}' at ${TIMESTAMP}. No further details."
else
   TEXT="${RESULT} - ${NODE_ID} event '${EVENT_TYPE}' at ${TIMESTAMP}. ${DETAILS}."
fi

NAGIOS_HOSTNAME="${HOSTNAME_PREFIX}$(/bin/hostname | sed 's/-/_/g')"
NAGIOS_HOSTNAME=${NAGIOS_HOSTNAME^^}

echo -e "${NAGIOS_HOSTNAME}\t${NSCA_SERVICE}\t${RETVAL}\t${TEXT}" | ${SEND_NSCA} -H ${NSCA_SERVER} > /dev/null
exit $RETVAL
