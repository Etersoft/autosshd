#!/bin/sh

# Do not load RH compatibility interface.
WITHOUT_RC_COMPAT=1

# Source function library.
. /etc/init.d/functions

# Source networking configuration.
SourceIfNotEmpty /etc/sysconfig/network

# AutoSSHDaemon configuration
SYSCONFIGFILE="/etc/sysconfig/autosshd"
SourceIfNotEmpty $SYSCONFIGFILE

BASE=autossh
###========= Functions =========
#===== help message =====
help()
{
    echo "
Usage: ${0##*/} ACTION [CHANNEL]
ACTION  - requested action of all or given AutoSSH channel
CHANNEL - optional name of AutoSSH channel (with corresponding 
          CHANNEL.* files in $CONFIGDIR)

Usefull actions is:
start       - start all configured channels except listed 
              in MANUAL variable in $CONFIGDIR/CHANNEL.conf file
stop        - stop all running channels
restart     - restart running channels
reload      - restart running channels
list        - print list of running channels
status      - print status of running channels
help        - print this message.
"
        RETVAL=1
        return $RETVAL
}

list_channels()
{
        LIST=`/bin/ls $CONFIGDIR/*.conf 2>/dev/null`
        CHANNELS=""
	echo "Configured channels:"
        if [ -n "$LIST" ]; then
            for config in $LIST; do
		SourceIfNotEmpty $config
		echo "   `basename $config .conf`. Manual: ${MANUAL} "
            done
        fi
        return 0
}

running_channels()
{
	LIST=`/bin/ls $PIDFILEDIR/*.pid 2>/dev/null`
        CHANNELS=""
        if [ -n "$LIST" ]; then
                for proc in $LIST; do
                        CHANNELS="$CHANNELS`basename $proc .pid` "
                done
        fi
        return 0
}

do_run_one()
{
    if [ -f $1 ]; then
	SourceIfNotEmpty $1
        start_daemon --pidfile "$AUTOSSH_PIDFILE" --make-pidfile --lockfile "/var/lock/subsys/autossh.d/$AUTOSSH_LOCKFILE" --user _autossh --name autossh -- autossh ${AUTOSSH_OPTIONS}
        RETVAL=$?
        #sleep 2
        #ps ax | grep autossh: | grep -v grep | awk {'print $1'} > "$AUTOSSH_PIDFILE"
        return $RETVAL
    else
	echo "Configuration file $1 not found"
	RETVAL=1
        return $RETVAL
    fi
}

do_stop_one()
{
    if [ -f $1 ]; then
	SourceIfNotEmpty $1
        stop_daemon --pidfile "$AUTOSSH_PIDFILE"  --lockfile "/var/lock/subsys/autossh.d/$AUTOSSH_LOCKFILE" --user _autossh --name autossh -- autossh
        RETVAL=$?
	rm -f "$PIDFILEDIR/$AUTOSSH_PIDFILE"
        return $RETVAL
    else
	echo "Configuration file $1 not found"
	RETVAL=1
        return $RETVAL
    fi
}


show_status()
{
        RETVAL=0
        if [ -z "$CHANNELS" ]; then # Show status of every running channel
                running_channels
        fi
	echo "$CHANNELS"

        if [ -z "$CHANNELS" ]; then
                msg_not_running $BASE
                echo
                RETVAL=1
        else
                for CHANNEL in $CHANNELS; do 
                        status --pidfile "$PIDFILEBASE/$CHANNEL.pid" -- autossh
                        st=$?
                        #if [ $st -le 1 ]; then
                        #        kill -s SIGUSR2 `cat "$PIDFILEBASE-$CHANNEL.pid"` >/dev/null 2>&1
                        #        st=$?
                        #        if [ $st -eq 0 ]; then
                        #                echo "Status of VPN $CHANNEL written to /var/log/messages"
                        #        fi
                        #fi
                        RETVAL=$(( $RETVAL + $? ))
                done
        fi
        return $RETVAL
}

start()
{
    LIST=`/bin/ls $CONFIGDIR/*.conf 2>/dev/null`
    CHANNELS=""
        if [ -n "$LIST" ]; then
            for config in $LIST; do
		SourceIfNotEmpty $config
		is_no $MANUAL && do_run_one $config
            done
        fi
    return 0
}

stop()
{
    running_channels
        if [ -n "$CHANNELS" ]; then
            for config in $CHANNELS; do
		SourceIfNotEmpty $config
		do_stop_one $CONFIGDIR/$config.conf
            done
        fi
    return 0
}

###====== Main =====
RETVAL=0

OP=$1
shift
CHANNELS=$@

is_yes "$NETWORKING" || return 0

# See how we were called.
case "$OP" in
        start)
	    if [ "x$CHANNELS" = "x" ]; then
                start 
	    else
		for i in "$CHANNELS"; do
		    do_run_one $CONFIGDIR/$i.conf
		done
	    fi
        ;;
        stop)
	    if [ "x$CHANNELS" = "x" ]; then
                stop
	    else
		for i in "$CHANNELS"; do
		    do_stop_one $CONFIGDIR/$i.conf
		done
	    fi
        ;;
        reload|restart)
                restart
                ;;
        status)
                show_status
                ;;
        list)
                list_channels
                ;;
        help)
                help
                ;;
        *)
                msg_usage "${0##*/} {start|stop|reload|restart|status|list|help}"
                RETVAL=1
esac

exit $RETVAL
