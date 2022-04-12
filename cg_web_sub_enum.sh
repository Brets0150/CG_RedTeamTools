#!/usr/bin/env bash
#
# Author: Bret.s
# Last Update: 4/12/2022
# Version: 1.2
# Made In: Kali 2 Rolling
# OS Tested: Kali 2 Rolling
# Purpose: When you find a webserver but you don't know what sub-domains are up, this script will scan the IPs and find the sub-domains.
#          This is usefull on internal networks engaments when there is no DNS, or to find find old web app that admin forgot to remove.
#
# Command Line Usage: ./cg_web_sub_enum.sh -h"
##
# Note:
##
# Version Change Notes.
# 1.0 - Done main purpose of script.
# 1.1 - Added argument to specify settings, allowing Dictionary set via command line. Fixed Header option.
# 1.2 - Added Status code filtering and added random User Agent to curl requests.
##

# Set script current build version.
str_version="1.2"

# Set basic varables for script.
str_scriptsName="${0}"
# Set current date and time logging.
str_date="$(date +'%D - %T')"
# Get this scripts current directory
str_script_dir="$(dirname "${0}")"
#set default subdomain Dictionary file.
str_subDomainDefaultDict="/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt"

# set Random user agents array.
declare -a ary_userAgents=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
    "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36"
    "Mozilla/5.0 (Windows NT 5.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36"
    "Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36"
    "Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36"
    "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
    "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
    "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:54.0) Gecko/20100101 Firefox/54.0"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.79 Safari/537.36 Edge/14.14393"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36 OPR/38.0.2220.41"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.79 Safari/537.36 Edge/14.14393"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.79 Safari/537.36 Edge/14.14393"
)

# Command usage for this script.
str_commandUsage="${str_scriptsName} -i <ip> -d <main domain name> {-w <wordlist> -f <HTTP Status Code> -p <port#> -s -h -v} \n
    -i <ip> - IP address to scan.\n
    -d <main domain name> - Main domain name to scan.\n
    -w <wordlist> - Wordlist to use for sub-domain brute-force.\n
    -f <HTTP Status Codes> - HTTP Status Codes to filter out. Filter multiple status codes with comma seperated.\n
    -h - Display this help message.\n
    -v - Display script version.\n
    -s - Connect to target using HTTPS. HTTP is used if this option is omitted. \n
    -p - Port to connect to.\n
    example: ./cg_web_sub_enum.sh -i 10.1.0.12 -d example.com -w subdomains.txt -f 502,404 -p 8443 -s \n"

# User provided command line flags to set options for -i str_ip, -d str_main_domainname, -w str_dictionaryFile, -h str_help.
# -i str_ip - single IP address.
# -d str_main_domainname - Main domain name to scan.
# -w str_dictionaryFile - Wordlist to use for sub-domain enumeration.
# -h str_help - Help menu.
# -f str_statusCodeFilter - Filter out status codes. Filter multiple status codes with comma seperated.
# -v str_version - Version of script.
# -s str_protocol - Connect to target using HTTPS. HTTP is used if this option is omitted.
# -p str_port - Port to use for scanning.
while getopts "i:d:w:f:p:shv" opt; do
  case $opt in
    i)
      str_ip="${OPTARG}"
      ;;
    d)
      str_main_domainname="${OPTARG}"
      ;;
    w)
      str_dictionaryFile="${OPTARG}"
      ;;
    f)
      str_statusCodeFilter="${OPTARG}"
      ;;
    p)
      str_port="${OPTARG}"
      ;;
    s)
      str_protocol="https"
      ;;
    h)
      echo -e "Command Line Usage: ${str_commandUsage}"
      exit 0
      ;;
    v)
      echo "Version: ${str_version}"
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      echo -e "Command Line Usage: ${str_commandUsage}"
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument." >&2
      echo -e "Command Line Usage: ${str_commandUsage}"
      exit 1
      ;;
  esac
done

# Check is the curl command is installed.
if ! hash curl 2>/dev/null; then
    echo "curl is not installed. Please install curl and try again."
    exit 1
fi

# make sure we have an IP
if [ "${str_ip}" == '' ]; then echo -e "Missing IP range...\n ${str_commandUsage}";exit 1;fi

# Test it the IP is a valid IP address.
if [[ ! "${str_ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then echo -e "Invalid IP address...\n ${str_commandUsage}";exit 1;fi

# make sure we have a domain name
if [ "${str_main_domainname}" == '' ]; then echo -e "missing domain name...\n ${str_commandUsage}";exit 1;fi

# check if str_dictionaryFile is set.
if [ "${str_dictionaryFile}" == '' ]; then
    # Ask the user to provide a dictionary file from subdomain enumeration. If none given default to str_subDomainDefaultDict.
    echo "Please provide a dictionary file for subdomain enumeration."
    echo "Default is ${str_subDomainDefaultDict}"
    read -r -p "Dictionary file: " str_dictionaryFile
    if [ "${str_dictionaryFile}" == '' ]; then str_dictionaryFile="${str_subDomainDefaultDict}";fi
fi

# echo the dictionary file name being used.
echo "Using dictionary file: ${str_dictionaryFile}"

# chcek if the dictionary file exists, else exit.
if [ ! -f "${str_dictionaryFile}" ]; then echo "Dictionary file does not exist..";exit 1;fi

# Get the number of lines in the dictionary file.
int_dictionaryFileLines=$(wc -l "${str_dictionaryFile}" | awk '{print $1}')

# Check if str_statusCodeFilter is set.
if [ "${str_statusCodeFilter}" != '' ]; then
    # Parse str_statusCodeFilter for multiple status codes.
    arr_statusCodeFilter=(${str_statusCodeFilter//,/ })
    # Loop through the status code array.
    for str_statusCode in "${arr_statusCodeFilter[@]}"; do
        # Check if the status code is a valid number.
        if [[ ! "${str_statusCode}" =~ ^[0-9]+$ ]]; then echo "Invalid status code: ${str_statusCode}";exit 1;fi
        # echo the status code being used.
        echo "Filter status code: ${str_statusCode}"
    done
fi

# Check if str_protocol is set.
if [ "${str_protocol}" == '' ]; then
    str_protocol="http"
fi

# if the protocol is not HTTP or HTTPS exit.
if [ "${str_protocol}" != 'http' ] && [ "${str_protocol}" != 'https' ]; then echo "Protocol must be HTTP or HTTPS..";exit 1;fi

# if the protocol is HTTP, ask user what port to use. If none given default to 80.
if [ "${str_protocol}" == 'http' ]; then
    # Check if str_port is set.
    if [ "${str_port}" == '' ]; then
        # Ask the user to provide a port number. If none given default to 80.
        echo "Please provide a port number for HTTP."
        echo "Default is 80."
        read -r -p "Port number: " str_port
        if [ "${str_port}" == '' ]; then str_port="80";fi
    fi
    # if the port is not a number exit.
    if ! [[ "${str_port}" =~ ^[0-9]+$ ]]; then echo "Port must be a number..";exit 1;fi
fi

# if the protocol is HTTPS, ask user what port to use. If none given default to 443.
if [ "${str_protocol}" == 'https' ]; then
    # Check if str_port is set.
    if [ "${str_port}" == '' ]; then
        # Ask the user to provide a port number. If none given default to 443.
        echo "Please provide a port number for HTTPS."
        echo "Default is 443."
        read -r -p "Port number: " str_port
        if [ "${str_port}" == '' ]; then str_port="443";fi
    fi
    # if the port is not a number exit.
    if ! [[ "${str_port}" =~ ^[0-9]+$ ]]; then echo "Port must be a number..";exit 1;fi
fi

# Select a random varable from ary_userAgents and set it to str_randomUserAgent
str_randomUserAgent="""${ary_userAgents[$RANDOM % ${#ary_userAgents[@]} ]}"""

# Tell user the the sub domain brute force will start.
echo "Sub domain brute force starting. Start Time ${str_date}."

# Curl the IP address and save the response data.
str_ip_request_responce_data="""$( curl -Is -A "${str_randomUserAgent}" "${str_protocol}://${str_ip}:${str_port}" )"""

# Use curl to get the Content-Length of IP request only
int_ip_request_responce_length="""$( grep 'Content-Length' <<<"${str_ip_request_responce_data}" | awk -F' ' '{print $2}')"""

# Log file names
str_outFile="${str_script_dir}/${str_ip}_${str_main_domainname}_scan-log"

# set a counter to 0
int_counter=0

# Foreach line of the dictionary file do the following append to the front of the domain name, and curl that domain name.
while read -r str_subdomain; do
    # Select a random varable from ary_userAgents and set it to str_randomUserAgent
    str_randomUserAgent="${ary_userAgents[$RANDOM % ${#ary_userAgents[@]} ]}"

    # Append the subdomain to the main domain name.
    str_domainname="${str_subdomain}.${str_main_domainname}"

    # curl the subdomain name and save the content length of the response.
    str_subdomain_request_responce_data="""$(curl -Is -A "${str_randomUserAgent}" "${str_protocol}://${str_domainname}:${str_port}" --resolve "${str_domainname}:${str_port}:${str_ip}" -H "HOST: ${str_domainname}" )"""

    # Extract the content length from the response.
    int_subdomain_request_responce_length="""$(grep 'Content-Length' <<<"${str_subdomain_request_responce_data}" | awk -F' ' '{print $2}')"""

    # Extract the status code from the response.
    int_subdomain_request_responce_status="""$(grep 'HTTP/' <<<"${str_subdomain_request_responce_data}" | awk -F' ' '{print $2}')"""

    # Check if the int_subdomain_request_responce_length is empty.
    if [ "${int_subdomain_request_responce_length}" == '' ]; then
        # if the int_subdomain_request_responce_length is empty, set it to 0.
        int_subdomain_request_responce_length=0
    fi

    # If the response length is the same as the IP request length then the subdomain is live.
    if [ "${int_subdomain_request_responce_length}" != "${int_ip_request_responce_length}" ] && [ "${int_subdomain_request_responce_status}" != "" ] ; then

        # if the status code filter is set, check if the status code is in the array.
        if [ "${str_statusCodeFilter}" != '' ]; then
            # if the status code is not in the array, then echo the subdomain.
            if [[ ! " ${arr_statusCodeFilter[@]} " =~ " ${int_subdomain_request_responce_status} " ]]; then
                echo "FOUND - STATUS: ${int_subdomain_request_responce_status} SUBDOMAIN: ${str_domainname} IP: ${str_ip} PORT: ${str_port} PROTOCOL: ${str_protocol}" | tee -a "${str_outFile}"
            fi
        else
            # if the status code filter is not set, echo the subdomain.
            echo "FOUND - STATUS: ${int_subdomain_request_responce_status} SUBDOMAIN: ${str_domainname} IP: ${str_ip} PORT: ${str_port} PROTOCOL: ${str_protocol}" | tee -a "${str_outFile}"
        fi
    fi

    # increment the counter
    int_counter=$((int_counter+1))

    # Printf the progress to the screen of the current count and the total number of lines in the dictionary file with no carriage return over the last line.
    printf "Progress: %s/%s\r" "${int_counter}" "${int_dictionaryFileLines}"

done < "${str_dictionaryFile}"

# echo the script completed at the current time.
echo "Sub domain brute force completed. End Time $(date +'%D - %T')"

# exit script
exit 0