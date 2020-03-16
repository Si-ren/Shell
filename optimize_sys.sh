##############################################
# Author: Siri_Wang
# Mail: wxr_624@163.com
# Last modified: 2020-03-13 11:21
# Filename: optimize.sh
# Description:  
##############################################
 
#!/bin/bash

#获得系统版本
sys_ver=`cat /etc/centos-release | awk '{print $4}'`

#检查是否联网，如果不联网，就不做需要网络的相关优化
ping -c 3 www.baidu.com &> /dev/null
if [ $? -ne 0 ];then
    echo "Warning : Can not connect inetnet!!! "
	echo "Warning : Only do offline optimization!!"
    net_status=1
else
	net_status=0
fi                                                                                                                          

#安装wget
function wget_install(){
	#rpm -qa | grep wget >/dev/null  2>&1 || yum -y install wget >/dev/null  2>&1  && echo "Finish : wget is installed."
	if [ `rpm -qa wget` == "" ];then
		yum -y install epel-release  >/dev/null  2>&1 && yum -y install wget >/dev/null  2>&1 && \
		 echo "Finish : wget is installed."
	else 
    	echo "Finish : wget is installed."
	fi
}

#备份原yum源
function yum_backup(){ 
	if  [ -e /etc/yum.repos.d/CentOS-Base.repo ];then
    	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup && \
    	echo "Finish : CentOS-Base.repo is bachuped."
	fi
}

#下载阿里源
function yum_wget(){
	wget -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-${sys_ver%%.*}.repo && \
	wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-${sys_ver%%.*}.repo  && \
	echo "Finish : yum ali is wgeted"
}

#关闭selinux
function permissive_se(){
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config	&& \
	setenforce 0 && \
	echo "Finish : selinux is permissive."
}


#针对版本做优化
case ${sys_ver%%.*} in
    "6")
		[ ${net_status} -eq 0 ] && wget_install && yum_backup && yum_wget
		/etc/init.d/iptables stop && chconfig iptables off
        ;;
    "7")
		[ ${net_status} -eq 0 ] && wget_install && yum_backup && yum_wget
		systemctl stop firewalld && systemctl disable firewalld
		permissive_se
        ;;
    "8")
        echo 'wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo'
        echo 'yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-8.noarch.rpm'
        sed -i 's|^#baseurl=https://download.fedoraproject.org/pub|baseurl=https://mirrors.aliyun.com|' etc/yum.repos.d/epel*
        sed -i 's|^metalink|#metalink|' etc/yum.repos.d/epel*
		systemctl stop firewalld && systemctl disable firewalld
        ;;
	*)
		echo "此脚本只适配了Centos系统！"
esac

#调整命令提示符
last_row=`tail -n 1 /etc/bashrc`
if [[ ${last_row} != 'PS1="[\t \[\e[31;1m\]\u\[\e[0m\]@\[\e[32;1m\]\h\[\e[0m\] \[\e[34;1m\]\w\[\e[0m\]]\\$"' ]];then
    echo  'PS1="[\t \[\e[31;1m\]\u\[\e[0m\]@\[\e[32;1m\]\h\[\e[0m\] \[\e[34;1m\]\w\[\e[0m\]]\\$"' >> /etc/bashrc && \
    . /etc/bashrc && \
    echo "Finish : /etc/bashrc is modified." 
else
    echo "Finish : /etc/bashrc is modified."
fi

#优化默认编码
localectl set-locale LANG=en_US.UTF-8 && . /etc/locale.conf && echo "Finish : Default encoding is ok."

#优化sshd服务
sed -ri -e 's#(.*)(PermitRootLogin).(.*)#\2 no#' -e 's#(.*)(PermitEmptyPasswords).(.*)#\2 no#' -e 's#(.*)(UseDNS).(.*)#\2 no#' -e 's#(.*)(GSSAPIAuthentication).(.*)#\2 no#' /etc/ssh/sshd_config && \
systemctl restart sshd || /etc/init.d/sshd restart && \
echo "Finish : /etc/sshd/sshd_config is modified."

#优化远程登录信息,可以自定义
cat << EOF >/etc/issue.net
Personal Server! Please get out!
You are not welcome!
EOF

#内核tcp优化
#cat << EOF >/etc/sysctl.conf 
#net.ipv4.tcp_fin_timeout = 2           #保持在FIN-WAIT-2状态的时间，使系统可以处理更多的连接。此参数值为整数，单位为秒。
#net.ipv4.tcp_tw_reuse = 1              #开启重用，允许将TIME_WAIT socket用于新的TCP连接。默认为0，表示关闭。
#net.ipv4.tcp_tw_recycle = 1            #开启TCP连接中TIME_WAIT socket的快速回收。默认值为0，表示关闭。
#net.ipv4.tcp_syncookies = 1            #开启SYN cookie，出现SYN等待队列溢出时启用cookie处理，防范少量的SYN攻击。默认为0，表示关闭。
#net.ipv4.tcp_keepalive_time = 600      #keepalived启用时TCP发送keepalived消息的拼度。默认位2小时。
#net.ipv4.tcp_keepalive_probes = 5      #TCP发送keepalive探测以确定该连接已经断开的次数。根据情形也可以适当地缩短此值。
#net.ipv4.tcp_keepalive_intvl = 15      #探测消息发送的频率，乘以tcp_keepalive_probes就得到对于从开始探测以来没有响应的连接杀除的时间。默认值为75秒，也就是没有活动的连接将在大约11分钟以后将被丢弃。对于普通应用来说,这个值有一些偏大,可以根据需要改小.特别是web类服务器需要改小该值。
#net.ipv4.ip_local_port_range = 1024 65000 #指定外部连接的端口范围。默认值为32768 61000。
#net.ipv4.tcp_max_syn_backlog = 262144  #表示SYN队列的长度，预设为1024，这里设置队列长度为262 144，以容纳更多的等待连接。
#net.ipv4.tcp_max_tw_buckets =5000      #系统同时保持TIME_WAIT套接字的最大数量，如果超过这个数值将立刻被清楚并输出警告信息。默认值为180000。对于squid来说效果不是很大，但可以控制TIME_WAIT套接字最大值，避免squid服务器被拖死。
#net.ipv4.tcp_syn_retries = 1           #表示在内核放弃建立连接之前发送SYN包的数量。
#net.ipv4.tcp_synack_retries = 1        #设置内核放弃连接之前发送SYN+ACK包的数量。
#net.core.somaxconn = 16384             #定义了系统中每一个端口最大的监听队列的长度, 对于一个经常处理新连接的高负载 web服务环境来说，默认值为128，偏小。
#net.core.netdev_max_backlog = 16384    #表示当在每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许发送到队列的数据包的最大数量。
#net.ipv4.tcp_max_orphans = 16384       #表示系统中最多有多少TCP套接字不被关联到任何一个用户文件句柄上。如果超过这里设置的数字，连接就会复位并输出警告信息。这个限制仅仅是为了防止简单的DoS攻击。此值不能太小。
#net.ipv4.ip_nonlocal_bind = 1          #可以绑定虚拟的地址，高可用的时候需要使用
#net.ipv4.tcp_congestion_control=hybla	#如果想设置TCP 拥塞算法为hybla
#net.ipv4.tcp_fastopen= 3				#额外的，对于内核版高于于3.7.1的，我们可以开启tcp_fastopen
#net.ipv4.tcp_max_syn_backlog= 65536		#记录的那些尚未收到客户端确认信息的连接请求的最大值。对于有128M内存的系统而言，缺省值是1024，小内存的系统则是128。
#net.core.netdev_max_backlog= 32768		#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目。
#net.core.somaxconn= 32768		#例如web应用中listen函数的backlog默认会给我们内核参数的net.core.somaxconn限制到128，而nginx定义的NGX_LISTEN_BACKLOG默认为511，所以有必要调整这个值。
#net.core.wmem_default= 8388608
#net.core.rmem_default= 8388608
#net.core.rmem_max= 16777216 #最大socket读buffer,可参考的优化值:873200
#net.core.wmem_max= 16777216 #最大socket写buffer,可参考的优化值:873200
#net.ipv4.tcp_timestsmps= 0	#时间戳可以避免序列号的卷绕。一个1Gbps的链路肯定会遇到以前用过的序列号。时间戳能够让内核接受这种“异常”的数据包。这里需要将其关掉。
#net.ipv4.tcp_synack_retries= 2	#为了打开对端的连接，内核需要发送一个SYN并附带一个回应前面一个SYN的ACK。也就是所谓三次握手中的第二次握手。这个设置决定了内核放弃连接之前发送SYN+ACK包的数量。
#net.ipv4.tcp_syn_retries= 2	#在内核放弃建立连接之前发送SYN包的数量。
##net.ipv4.tcp_tw_len= 1
#net.ipv4.tcp_tw_reuse= 1		#开启重用。允许将TIME-WAITsockets重新用于新的TCP连接。
#net.ipv4.tcp_wmem= 8192 436600 873200	#TCP写buffer,可参考的优化值:8192 436600 873200
#net.ipv4.tcp_rmem = 32768 436600 873200	#TCP读buffer,可参考的优化值:32768 436600 873200
#net.ipv4.tcp_mem= 94500000 91500000 92700000
##同样有3个值,意思是:
##net.ipv4.tcp_mem[0]:低于此值，TCP没有内存压力。
##net.ipv4.tcp_mem[1]:在此值下，进入内存压力阶段。
##net.ipv4.tcp_mem[2]:高于此值，TCP拒绝分配socket。
##上述内存单位是页，而不是字节。可参考的优化值是:7864321048576 1572864
#net.ipv4.tcp_max_orphans= 3276800		#系统中最多有多少个TCP套接字不被关联到任何一个用户文件句柄上,如果超过这个数字，连接将即刻被复位并打印出警告信息,这个限制仅仅是为了防止简单的DoS攻击，不能过分依靠它或者人为地减小这个值，更应该增加这个值(如果增加了内存之后)。
#net.ipv4.tcp_fin_timeout= 30			#如果套接字由本端要求关闭，这个参数决定了它保持在FIN-WAIT-2状态的时间。对端可以出错并永远不关闭连接，甚至意外当机。缺省值是60秒。2.2 内核的通常值是180秒，你可以按这个设置，但要记住的是，即使你的机器是一个轻载的WEB服务器，也有因为大量的死套接字而内存溢出的风险，FIN-WAIT-2的危险性比FIN-WAIT-1要小，因为它最多只能吃掉1.5K内存，但是它们的生存期长些。
#EOF
#[ $? -eq 0 ] && sysctl -p &&  echo "Finish : tcp_set is ok."

#文件优化，单进程最大打开文件数限制
#ulimit -n 65535
#cat <<EOF >>/etc/security/limits.conf
#* soft nofile 102400
#* hard nofile 102400
#EOF
