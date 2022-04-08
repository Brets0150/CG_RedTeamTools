#!/usr/bin/env bash
#
# Author: Bret.s
# Last Update: 4/5/2022
# Version: 1.0
# Made In: Kali 2 Rolling
# OS Tested: Kali 2 Rolling
# Purpose:
#
# Command Line Usage: ./"
##
# Note:
##
# Version Change Notes.
# 1.0 - Done main purpose of script.
##

ip="${1}"
date="$(date +'%s')"
ip_name="$(echo ${ip}| tr '/' '-')"
str_outFileQuickScan="${ip_name}_scan-log"
str_outFileFullScan="${str_outFileQuickScan}_full"
ip_live="liveips_${date}_.txt"

if [ "${ip}" == '' ]; then echo "missing IP range..";exit 1;fi

fun_getLiveIps(){
    #
    nmap -Pn -T3 --top-ports 20 -oA "./${str_outFileQuickScan}" ${ip}
    #
    grep 'Ports:' "./${str_outFileQuickScan}.gnmap" |grep open | awk -F' ' '{print $2}' > "./${ip_live}"
}

fun_scanLiveIpsAllPorts(){
    #
    nmap -Pn -T3 -p- --open -oA "./${str_outFileFullScan}" -iL "./${ip_live}"
}

fun_scanPortsDetails(){
    tmp_ipList="${str_outFileFullScan}.gnmap"
    declare -a ary_linesOfFile ary_tmp_openPort
    readarray -t ary_linesOfFile <<<"""$(grep 'Ports:' "./${tmp_ipList}" |grep -i open)"""
    for str_tmp_line in "${ary_linesOfFile[@]}";do
        # Put Host IP in to array.
        str_hostIP="$(echo "${str_tmp_line}"|awk -F'\t' '{print $1}'|tr -d '(\|)\| '|cut -c 6-)"
        # Parse data to form NMap ready variable of open ports.
        readarray -d ',' ary_tmp_openPort <<<"""$(echo "${str_tmp_line}"|awk -F'\t' '{print $2}'|tr -d '(\|)\| '|cut -c 7-)"""
        str_nmapPortList=''
        for str_port in "${ary_tmp_openPort[@]}";do
            str_tmp_ports="$(echo "${str_port}"|awk -F'/' '{print $1}')"
            str_nmapPortList+="${str_tmp_ports},"
        done
        str_openPort="${str_nmapPortList:0:-1}"
        #
        nmap -Pn -p "${str_openPort}" -oA "./${str_hostIP}_detail-port-scan" -sCV -A -T3 "${str_hostIP}"
    done

}


fun_getLiveIps
fun_scanLiveIpsAllPorts
fun_scanPortsDetails
exit 0