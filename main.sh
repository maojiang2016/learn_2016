#!/bin/bash

## �ű�����Ŀ¼·��
ROOT_DIR=$(cd "$(dirname "$0")"; pwd)

######################
## ��¼������־
## @param $1 ��־����
#####################
function log() {
        echo $1 >> $ROOT_DIR/op.log
}

IPTABLES_FILE=$ROOT_DIR/iptables.now
FORBIDDEN_FILE=$ROOT_DIR/should_forbidden.now

## ��ǰϵͳʱ��
NOW=`date +%s`
NOW_STR=`date +%Y-%m-%dT%H:%M:%S`
log "================================="
log "Begin iptables job at $NOW_STR"

## ��⵽�ڵ�iptables
for ip in `iptables -n -L|grep -v "forever"|grep "DROP"|awk '{if(NF>6 && $7<'$NOW') print $4}'`; do
        id=`iptables -n -L --line-numbers|grep "$ip"|awk '{print $1}'`
        log "[$NOW_STR] Release ip forbidden rules : $ip"
    ## /sbin/iptables -D INPUT -s $ip -j DROP 
        /sbin/iptables -D DROP $id
done

## ȡ�����µ�iptables��IP
/sbin/iptables -n -L|grep "DROP"|awk '{print $4}' > $IPTABLES_FILE

## ȡ����־��IP
tail -n20000 /data/log/nginx/register-www.log|awk '{print $1}'|sort|uniq -c|sort -nr|awk '{if($1>100) print $2}' > $FORBIDDEN_FILE

## ���δ�����IP
NOW=`date +%s`
NOW=$(($NOW+10800))
NOW_STR=`date +%Y-%m-%dT%H:%M:%S`
for ip in `awk '{if(FILENAME=="'$FORBIDDEN_FILE'")a[$1]=1;else b[$1]=1}END{for(x in a)if(b[x] != 1) print x}' $FORBIDDEN_FILE $IPTABLES_FILE`; do
        log "[$NOW_STR] Forbidden ip access : $ip"
        /sbin/iptables -I INPUT -s $ip -j DROP -m comment --comment "$NOW"
done

NOW_STR=`date +%Y-%m-%dT%H:%M:%S`
log "Finish iptables job at $NOW_STR"
log ""