#! /bin/bash

BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Help
if [[ "$1" = "-h" ]];
then
  echo """Usage : bash bckup.sh user host port dest
    user : Should be a user that can access /var/log/syslog
    host : Should be a host (eg: 192.168.1.1)
    port : Should be the port to ssh to the host
    dest : Should be a location on the drive (eg: /var/log/test.txt)"""
  exit
fi

# Check if all arguments are provided
if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]];
then
  echo -e "${RED}[Error]${NC} Missing arguments please type bckup.sh -h"
  exit
fi

# Define variables
user=$1
host=$2
port=$3
dst=$4
src="/tmp/syslogtemp"

# Check user inputs
if [[ ! "$host" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
then
  echo -e "${RED}[Error]${NC} Please enter a correct ip"
  exit
fi

if [[ ! "$port" =~ ^[0-9]{1,6} ]]
then
  echo -e "${RED}[Error]${NC} Please enter a correct port number"
  exit
fi

# Get logs from remote server
scp -P $port $user@$host:/var/log/syslog $src

if [[ ! -f $src ]];
then
  echo -e "${RED}[Error]${NC} File not found"
  exit
fi

# Handles the log creation
if [ ! -f $dst ];
then
  echo -e "${BLUE}[Info]${NC} Creating log file."
  cat $src > $dst
else
  if [[ -z "$(cat $dst)" ]];
  then
    cat $src > $dst
    echo -e "${BLUE}[Info]${NC} Log file was empty, backed up!"
  else
    last_line_dst=$(tail -n 1 $dst | cut -d' ' -f1)
    if [[ ! -z "$(grep -A 50000000000 "$last_line_dst" $src)" ]]
    then
      echo -e "${BLUE}[Info]${NC} Backing up new logs."
      grep -A 50000000000 "$last_line_dst" $src
      grep -A 50000000000 "$last_line_dst" $src >> $dst
    else
      echo -e "${BLUE}[Info]${NC} Everything is already backed up!"
    fi
  fi
fi

rm $src

if [ $(wc -l < $dst) -gt 1000 ];
then
  nb=$(ls -l $dst-*.tar.gz | wc -l | rev | cut -d' ' -f1 | rev)
  echo -e "${BLUE}[Info]${NC} Log file to big ($(wc -l < $dst) lines), compressing it"
  last_line=$(tail -n 1 $dst)
  tar -czvf "$dst-$nb.tar.gz" $dst
  echo $last_line > $dst
fi

echo -e "${BLUE}[Info]${NC} Done!"