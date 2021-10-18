#!/bin/bash
#
# Script for create database and user
# Paul Ljungqvist - 160217
#

# Some constants

  red='\033[01;31m'
  blue='\033[01;34m'
  green='\033[01;32m'
  norm='\033[00m'

  MYSQL=`which mysql`
  LOAD_BALANCER1='sql-clu04-lb01.se.axis.com'
  LOAD_BALANCER2='sql-clu04-lb02.se.axis.com'

# The input

  echo -ne "Database name (Db will be created if not exist): "
  read db_name

  echo -ne "User name: "
  read user_name

  echo -ne "Host name (FQN): "
  read host_name

  echo -ne "Password: "
  read password

  echo -ne "\n"
  echo -ne "Select base privileges for $user_name@$host_name > \n"
  echo -ne "1 - ALL PRIVILEGES ON $db_name.* \n"
  echo -ne "2 - SELECT ON $db_name.* \n"
  echo -ne "3 - DELETE, INSERT, SELECT, UPDATE ON $db_name.* \n"
  
  read character
  case $character in
      1 ) echo "ALL PRIVILEGES ON $db_name.*"
	      PRIVS="ALL PRIVILEGES"
          ;;
      2 ) echo "SELECT ON $db_name.*"
	      PRIVS="SELECT"
          ;;
      3 ) echo "DELETE, INSERT, SELECT, UPDATE ON $db_name.*"
	      PRIVS="DELETE, INSERT, SELECT, UPDATE"
          ;;
      * ) echo "You did not enter a valid number"
          echo "between 1 and 3."
		  break
  esac
  
    if [[ -z "$var" ]]; then
  		Q1="CREATE DATABASE IF NOT EXISTS $db_name;"
  	else
  		Q1=""
    fi

  Q2="GRANT USAGE ON $db_name.* TO $user_name@'$host_name' IDENTIFIED BY '$password';"
  Q3="GRANT USAGE ON $db_name.* TO $user_name@'$LOAD_BALANCER1' IDENTIFIED BY '$password';"
  Q4="GRANT USAGE ON $db_name.* TO $user_name@'$LOAD_BALANCER2' IDENTIFIED BY '$password';"
  Q5="GRANT $PRIVS ON $db_name.* TO $user_name@'$host_name';"
  Q6="GRANT $PRIVS ON $db_name.* TO $user_name@'$LOAD_BALANCER1';"
  Q7="GRANT $PRIVS ON $db_name.* TO $user_name@'$LOAD_BALANCER2';"
  Q8="FLUSH PRIVILEGES;"
  SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}${Q8}"

  echo -e "\n${blue}-Creating mysql DATABASE ${red}${db_name}${norm}\n${blue}-Creating mysql USER ${red}${user_name}@${host_name}${norm}\n"
  for query in "$Q1" "$Q2" "$Q3" "$Q4" "$Q5" "$Q6" "$Q7" "$Q8"
  do
  $MYSQL -e "$query" && echo -e "$query  [${green}OK${norm}]" || echo -e "$query  [${red}BAD${norm}]"

  done
  echo -e " "
