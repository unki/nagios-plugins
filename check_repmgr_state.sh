#!/bin/bash

#
# Nagios plugin to monitor repmgr [http://repmgr.org] state.
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

check_parameters () {
   if [ $# -lt 1 ] || [ -z $1 ]; then
      show_help;
      exit 0
   fi

   while getopts :ht:r:u: OPTS; do
      ARGSPARSED=1
      case $OPTS in
         h)
            show_help
            exit 0
            ;;
         t)
            readonly REQUIRE_HOST=${OPTARG,,}
            ;;
         r)
            readonly REQUIRE_ROLE=${OPTARG,,}
            ;;
         u)
            readonly REQUIRE_UPSTREAM=${OPTARG,,}
            ;;
         *)
            echo "Invalid parameter(s)!"
            echo
            show_help
            exit 1
            ;;
      esac
   done

   if [ -z "${REQUIRE_HOST}" ] || [ -z "${REQUIRE_ROLE}" ]; then
      echo "Invalid parameter(s)!"
      echo
      show_help
      exit 1
   fi
}

show_help ()
{
echo $0
echo
echo "  -t host ... target host"
echo "  -r role ... target role"
echo "  -u host ... target upstream"
echo
}

check_parameters "${@}"

REPMGR_BIN="/usr/bin/repmgr"
REPMGR_CONF="/etc/repmgr/repmgr.conf"

[ -x ${REPMGR_BIN} ] || { echo "${REPMGR_BIN} not found or isn't executable!"; exit 1; }
[ -f ${REPMGR_CONF} ] || { echo "${REPMGR_CONF} not found or isn't readable!"; exit 1; }

REPMGR="${REPMGR_BIN} -f ${REPMGR_CONF} cluster show"

declare -a REPMGR_STATE=()

mapfile -t REPMGR_STATE < <(${REPMGR})

[ "x${?}" == "x0" ] || { echo "Fetching repmgr status by '${REPMGR}' failed!"; exit 1; }

[ ${#REPMGR_STATE[@]} -ge 1 ] || { echo "No state returned by '${REPMGR}'!"; exit 1; }

LINES=${!REPMGR_STATE[@]}
ROLE_MISMATCH=0
UPSTREAM_MISMATCH=0
HOST_FOUND=0

for LINE in ${LINES[@]}; do
   #
   # skip all non-cluster-node-lines
   #
   if ! [[ "${REPMGR_STATE[LINE]}" =~ (master|standby|witness)[[:blank:]]+\|[[:blank:]]+([[:graph:]]+)[[:blank:]]+\|[[:blank:]]+([[:print:]]*)[[:blank:]]+\|[[:blank:]]+[[:graph:]]+[[:blank:]]+ ]]; then
      continue
   fi

   [ ! -z "${BASH_REMATCH[1]}" ] || continue
   [ ! -z "${BASH_REMATCH[2]}" ] || continue

   ROLE=${BASH_REMATCH[1]}
   HOST=${BASH_REMATCH[2]}
   UPSTREAM=${BASH_REMATCH[3]}

   [ "${HOST}" == "${REQUIRE_HOST}" ] || continue

   HOST_FOUND=1

   if [ "${ROLE}" != "${REQUIRE_ROLE}" ]; then
      ROLE_MISMATCH=1
   fi

   if [ "${ROLE}" == "standby" ] && \
      [ ! -z "${REQUIRE_UPSTREAM}" ] && \
      [ "${UPSTREAM}" != "${REQUIRE_UPSTREAM}" ]; then
      UPSTREAM_MISMATCH=1
   fi

   break;
done

if [ ${ROLE_MISMATCH} == 0 ] && \
   [ ${UPSTREAM_MISMATCH} == 0 ] && \
   [ ${HOST_FOUND} == 1 ]; then
   if [ "${ROLE}" != "standby" ]; then
      echo "OK - host ${HOST} has role ${ROLE^^}."
      exit 0
   else
      echo "OK - host ${HOST} has role ${ROLE^^} (upstream ${UPSTREAM})."
      exit 0
   fi
fi

if [ ${HOST_FOUND} == 0 ]; then
   echo "CRITICAL - host ${REQUIRE_HOST} not found!"
   exit 2
elif [ ${ROLE_MISMATCH} == 1 ]; then
   echo "WARNING - host ${HOST} does not have role ${REQUIRE_ROLE^^} but uses ${ROLE^^} instead."
   exit 1
elif [ ${UPSTREAM_MISMATCH} == 1 ]; then
   echo "WARNING - host ${HOST} does not use upstream ${REQUIRE_UPSTREAM} but uses ${UPSTREAM} instead."
   exit 1
fi

echo "UNKNOWN - unhandled error state."
exit 3
