# Proxy into a Cassandra host and run jconsole
function jc {
    # set this to the host you'll proxy through.
    host=$1

    jmxport=7199 # as specified by JMX_PORT in cassandra-env.sh
    proxy_port=${2:-8123}

    if [ "x$host" = "x" ]; then
        echo "Usage: jc  [proxy port]"
        return 1
    fi

    # start up a background ssh tunnel on the desired port
    ssh -N -f -D$proxy_port $host

    # if the tunnel failed to come up, fail gracefully.
    if [ $? -ne 0 ]; then
        echo "Ssh tunnel failed"
        return 1
    fi

    ssh_pid=`ps awwwx | grep "[s]sh -N -f -D$proxy_port" | awk '{print $1}'`
    echo "ssh pid = $ssh_pid"

    # Fire up jconsole to your remote host
    jconsole -J-DsocksProxyHost=localhost -J-DsocksProxyPort=$proxy_port \
        service:jmx:rmi:///jndi/rmi://${host}:${jmxport}/jmxrmi

    # tear down the tunnel
    kill $ssh_pid
}

orphans() {
  if [[ ! -n $(pacman -Qdt) ]]; then
    echo "No orphans to remove."
  else
    sudo pacman -Rs $(pacman -Qdtq)
  fi
}
