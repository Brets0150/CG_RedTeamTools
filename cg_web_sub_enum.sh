#!/usr/bin/env bash
#
# Author: Bret.s
# Last Update: 4/5/2022
# Version: 1.0
# Made In: Kali 2 Rolling
# OS Tested: Kali 2 Rolling
# Purpose: When you find a webserver but you don't know what sub-domains are up, this script will scan the IPs and find the sub-domains.
#          This is usefull on internal networks engaments when there is no DNS, or to find find old web app that admin forgot to remove.
#
# Command Line Usage: ./cg_web_sub_enum.sh"
##
# Note:
##
# Version Change Notes.
# 1.0 - Done main purpose of script.
##

# Set varables from command line arguments
str_ip="${1}"
str_date="$(date +'%s')"
str_main_domainname="${2}"

# Get this scripts current directory
str_script_dir="$(dirname "${0}")"

# Log file names
str_outFile="${str_script_dir}/${str_ip}_${str_main_domainname}_scan-log"

# make sure we have an IP
if [ "${str_ip}" == '' ]; then echo "missing IP range..";exit 1;fi

#make sure we have a domain name
if [ "${str_main_domainname}" == '' ]; then echo "missing domain name..";exit 1;fi

# Ask the user to provide a dictionary file from subdomain enumeration. If none given default to "/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt".
echo "Please provide a dictionary file for subdomain enumeration."
echo "Default is /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt"
read -r -p "Dictionary file: " str_dictionaryFile
if [ "${str_dictionaryFile}" == '' ]; then str_dictionaryFile="/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt";fi

# chcek if the dictionary file exists, else exit.
if [ ! -f "${str_dictionaryFile}" ]; then echo "Dictionary file does not exist..";exit 1;fi

# Get the number of lines in the dictionary file.
int_dictionaryFileLines=$(wc -l "${str_dictionaryFile}" | awk '{print $1}')

# Ask the user to select from the options HTTP or HTTPS. If none given default to HTTP.
echo "Please select from the options HTTP or HTTPS."
echo "Default is HTTP."
echo "1. HTTP"
echo "2. HTTPS"
read -r -p "Option: " str_protocol
# case statement to set the protocol
case "${str_protocol}" in
    1) str_protocol="http";;
    2) str_protocol="https";;
    *) echo "Using Default HTTP";str_protocol="http";;
esac

# if the protocol is not HTTP or HTTPS exit.
if [ "${str_protocol}" != 'http' ] && [ "${str_protocol}" != 'https' ]; then echo "Protocol must be HTTP or HTTPS..";exit 1;fi

# if the protocol is HTTP, ask user what port to use. If none given default to 80.
if [ "${str_protocol}" == 'http' ]; then
    echo "Please provide a port number for HTTP."
    echo "Default is 80."
    read -r -p "Port number: " str_port
    if [ "${str_port}" == '' ]; then str_port="80";fi
    # if the port is not a number exit.
    if ! [[ "${str_port}" =~ ^[0-9]+$ ]]; then echo "Port must be a number..";exit 1;fi
fi

# if the protocol is HTTPS, ask user what port to use. If none given default to 443.
if [ "${str_protocol}" == 'https' ]; then
    echo "Please provide a port number for HTTPS."
    echo "Default is 443."
    read -r -p "Port number: " str_port
    if [ "${str_port}" == '' ]; then str_port="443";fi
    # if the port is not a number exit.
    if ! [[ "${str_port}" =~ ^[0-9]+$ ]]; then echo "Port must be a number..";exit 1;fi
fi

# Tell user the the sub domain brute force will start.
echo "Sub domain brute force starting. Start Time ${str_date}."

# Use curl to get the Content-Length of IP request only
int_ip_request_responce_length=$(curl -Is "${str_protocol}://${str_ip}:${str_port}" | grep 'Content-Length' | awk -F' ' '{print $2}')

# set a counter to 0
int_counter=0

# Foreach line of the dictionary file do the following append to the front of the domain name, and curl that domain name.
while read -r str_subdomain; do
    # Append the subdomain to the main domain name.
    str_domainname="${str_subdomain}.${str_main_domainname}"

    # curl the subdomain name and save the content length of the response.
    str_subdomain_request_responce_data="""$(curl -Is "${str_protocol}://${str_domainname}" --resolve "${str_domainname}:${str_port}:${str_ip}" -H "HOSTNAME: ${str_domainname}")"""

    # Extract the content length from the response.
    int_subdomain_request_responce_length="""$(echo "${str_subdomain_request_responce_data}" | grep 'Content-Length' | awk -F' ' '{print $2}')"""

    # Extract the status code from the response.
    int_subdomain_request_responce_status="""$(echo "${str_subdomain_request_responce_data}" | grep 'HTTP/' | awk -F' ' '{print $2}')"""

    # If the response length is the same as the IP request length then the subdomain is live.
    if [ "${int_subdomain_request_responce_length}" != "${int_ip_request_responce_length}" ] && [ "${int_subdomain_request_responce_status}" != "" ] ; then
        echo "FOUND - STATUS: ${int_subdomain_request_responce_status} SUBDOMAIN: ${str_domainname} IP: ${str_ip} PORT: ${str_port} PROTOCOL: ${str_protocol}" | tee -a "${str_outFile}"
    fi

    # increment the counter
    int_counter=$((int_counter+1))

    # echo the counter and the total number of lines in the dictionary file.
    echo -ne "Progress: ${int_counter}/${int_dictionaryFileLines}\r"

done < "${str_dictionaryFile}"

# exit script
exit 0