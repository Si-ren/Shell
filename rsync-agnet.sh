#!/bin/bash
echo $LINENO && IP_Addr=$(hostname)-$(hostname -i)
#创建文件夹
echo $LINENO && mkdir -p /backup_client/$IP_Addr
#打包日志
echo $LINENO && cd / && tar -zcf backup_client/$IP_Addr/log_backup_$(date +%F_week%w)
#删除本地7天前的备份数据
echo $LINENO && find /backup_client/$IP_Addr/ type -f -mtime +7 | xargs rm 2>/dev/nnull
#创建finger保证传输完整性
echo $LINENO && find /backup_client/$IP_Addr/ -type f -mtime +7 ! -name "finger*" | xargs md5sum >/backup_client/$IP_Addr/finger.txt
#使用rsync备份，可以增量备份
echo $LINENO && rsync -az /backup_client/$IP_Addr rsync_backup@172.16.1.111::backup --password-file=/etc/rsync.passwd