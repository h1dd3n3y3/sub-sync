#!/bin/bash

check_installation() {
    if [ -z "$(which "$1")" ]; then
        echo "'bc' tool is essential for running the script."
        read -p "\nDo you wish to install it right now? [Y/n] " ans

        if [ -z "$ans" ] || [ "$ans" = "Y" ] || [ "$ans" = "y" ]; then
            sudo apt install "$1" -y
        elif [ "$ans" = "N" ] || [ "$ans" = "n" ]; then
            exit 1
        else # Invalid input
            echo "Invalid input. Please try again."
            check_installation "$1"
        fi
    fi
}

ts_to_sec() {
    ts=$1
    hh=${ts:0:2}
    mm=${ts:3:2}
    ss=${ts:6:2}
    ms=0.${ts:9:3}

    totsec0=$((10#$hh * 3600 + 10#$mm * 60 + 10#$ss)) # Avoid bash confusion by forcing base ten with 10#
    totsec=$(echo "$totsec0 + $ms" | bc)
}

offset() {
    off=$1
    newtotsec=$(echo "$totsec + $off" | bc)
}

sec_to_ts() {
    extrsec=${newtotsec:0:${#newtotsec}-4}
    extrms=${newtotsec: -3}
    newhh=$((extrsec / 3600))
    mod=$((extrsec % 3600))
    newmm=$((mod / 60))
    newss=$((mod % 60))

    [ ${#newhh} -lt 2 ] && newhh=0$newhh #
    [ ${#newmm} -lt 2 ] && newmm=0$newmm # 2 digit timestamp formatting
    [ ${#newss} -lt 2 ] && newss=0$newss #

    newts=$newhh:$newmm:$newss,$extrms
}

dialogue() {
    old=$1
    new=$2

    clear
    echo -e "\e[36m +-----------------------------+-----------------------------+\e[0m\n"\
        "\e[36m|\e[93m Old timestamp: \e[94m$old \e[36m|\e[93m New timestamp: \e[94m$new \e[36m|\e[0m\n"\
        "\e[36m+-----------------------------+-----------------------------+\e[0m"
}

percentage() {
    prog=$1

    [ "${prog:0:1}" = "." ] && newprog=0           # Take care the percentage form because `bc -l`
    [ "${prog:1:1}" = "." ] && newprog=${prog:0:1} # division results are displayed without
    [ "${prog:2:1}" = "." ] && newprog=${prog:0:2} # leading zero if the result is lower than 1
    [ "${prog:0:3}" = "100" ] && echo -e "\r\t\t\t\e[32m   Finished!\e[0m   "\
        || echo -ne "\r\t\t\t\e[95mStatus: \e[91m$newprog% ...\e[0m"
}

check_installation "bc" # Check and install 'bc'

if [ $# -ge 2 ]; then
    args=( "$@" )

    for a in "${!args[@]}"; do
        if [ "${args[$a]}" = "--silent" ] || [ "${args[$a]}" = "-s" ]; then # Silent mode
            silent="true"
        fi

        if [[ "${args[$a]}" =~ \.srt$ ]]; then
            subs=${args[$a]}

            dos2unix "$subs" # Convert DOS to Unix format to avoid carriage return issues

            cp "$subs" "$(echo $subs | awk -F'.srt' '{print $1}')_$(date +"%Y-%m-%d_%H-%M-%S").srt" # Backup the original subtitle file
            
            n=0
            totts=$(grep -o '[0-5][0-9]:[0-5][0-9]:[0-5][0-9],[0-9][0-9][0-9]' "$subs" | wc -l)
        fi
        
        if [[ "${args[$a]}" =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]; then
            timeoff=${args[$a]}

            if [ "${timeoff:0:1}" = "+" ]; then
                timeoff=${timeoff:1} # remove '+' from the offset
            fi
        fi
    done

    echo Shifting $timeoff seconds...
    echo -n Processing

    # for i in $(grep -- "-->" | awk '{print $1"\n"$3}' "$subs"); do
    for i in $(grep -o '[0-5][0-9]:[0-5][0-9]:[0-5][0-9],[0-9][0-9][0-9]' "$subs"); do
        ts_to_sec "$i"                  # Convert the extracted timestamp to seconds
        offset "$timeoff"               # Add the given offset seconds to the previously converted timestamp
        sec_to_ts                       # Convert the new seconds back to timestamp
        sed -i "s/$i/$newts/" "$subs"   # Replace old timestamp with the new one

        if ! [ $silent ]; then
            ((n++))
            progress=$(echo "$n / $totts * 100" | bc -l)
            progress=${progress:0:3}
            dialogue "$i" "$newts"
            percentage "$progress"
        else
	        echo -n '.' # Progress dots
        fi
    done

    echo; echo "Done!"

elif [ $# -lt 2 ]; then
    echo "Try '$0 [OPTION] <subtitles> <offset>'"
    echo -e "\nOPTION:\n\t-s, --silent: Suppress graphical progress."
fi
