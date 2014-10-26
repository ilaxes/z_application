#!/bin/bash

HOST=10.11.12.13
PORT=22
LOGIN=helloFTP
PASSWORD=world
DATA_DIR='/home/Marketing\ Report/Data/'
SCRIPT_DIR='/home/Marketing\ Report/Scripts'

# ftp transfert
ftp -i -n $HOST $PORT << END_SCRIPT
quote USER $LOGIN
quote PASS $PASSWORD
bin
cd $DATA_DIR
mget webtrekk_marketing*
quit
END_SCRIPT

# run python script
python $SCRIPT_DIR/ZMR.py

# run sql script
DATABASE=zalora
USERNAME=helloDB
HOSTDB=10.11.12.13
PORTDB=5439
export PGPASSWORD=world
psql -d $DATABASE -h $HOSTDB -p $PORTDB -U $USERNAME -w -f $SCRIPT_DIR/UpdateWebtrekk.sql

