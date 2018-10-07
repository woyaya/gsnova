#!/bin/sh

ROOT=`whoami`
[ "$ROOT" != "root" ] && {
	echo "Run as root"
	exit 1
}

EXEC=/usr/bin/gsnova
CONF=/etc/gsnova/client.json
CNIP=/etc/gsnova/cnipset.txt
INIT=/etc/init.d/gsnova

list="$EXEC $CONF $CNIP"
for name in $list;do
	[ -f `basename $name` ] && continue
	echo "Can not find file `basename $name`"
	exit 1
done
for name in $list;do
	mkdir -p `dirname $name`
	cp -rf `basename $name` $name
	chown root:root $name
	chmod 644 $name
done
chown nobody $EXEC
chmod u+rwxs,g+x,o+x $EXEC

cat <<-EOF >$INIT
#!/bin/sh -e
### BEGIN INIT INFO
# Provides:         gsnova
# Required-Start:   \$local_fs \$network \$named \$time \$syslog
# Required-Stop:    \$local_fs \$network \$named \$time \$syslog
# Default-Start:    2 3 4 5
# Default-Stop:     0 1 6
# Short-Description: Start gsnova.
### END INIT INFO

#EXEC=/usr/bin/gsnova
#CONF=/etc/gsnova/client.json
#CNIP=/etc/gsnova/cnipset.txt
[ -f $CONF ] && conf="-conf $CONF"
[ -f $CNIP ] && cnip="-cnip $CNIP"

case "\$1" in
start)
        OWNER=\$(/usr/bin/stat -c "%U" $EXEC)
        [ "\$OWNER" != "nobody" ] && chown nobody $EXEC
        ACCESS=\$(/usr/bin/stat -c "%A" $EXEC | /bin/sed 's/^.\(...\).*/\1/')
        [ "\$ACCESS" != "rws" ] && chmod +rwxs $EXEC

        nohup $EXEC -client \$conf \$cnip 2>/dev/null 1>/dev/null &
        ;;

stop)
        killall `basename $EXEC`
        ;;

restart)
       stop
       sleep 0.5
       start
       ;;

*)
       echo "Usage: $INIT {start|stop|restart}"
       exit 1
       ;;
esac

exit 0

EOF

chmod 755 $INIT
update-rc.d -f gsnova defaults
update-rc.d -f gsnova enable
