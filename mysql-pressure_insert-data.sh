#!/bin/bash
HOSTNAME="localhost"
PORT="3306"
USERNAME="root"
PASSWORD="root"
DBNAME="test"
TABLENAME="test_pressure"

#create database
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "drop database if exists ${DBNAME}"
create_db_sql="create database if not exists ${DBNAME} charset utf8"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${create_db_sql}"

#create table
create_table_sql="create table if not exists ${TABLENAME}(stuid int not null primary key,stuname varchar(20) not null,stusex enum('F','M','N') default 'M' NOT NULL,cardid varchar(20) not null,birthday datetime,entertime datetime,address varchar(50)default null)engine innodb;"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${create_table_sql}"

#insert data to table
i="1"
while [ $i -le 500000 ]
do
insert_sql="insert into ${TABLENAME} values(${i},'alexsb_${i}','F','1201301257823756123','1996-06-24','2014-09-10','井冈山')"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${insert_sql}"
let i++
done

#select data
select_sql="select count(stuid) from ${TABLENAME}"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} ${DBNAME} -e "${select_sql}"