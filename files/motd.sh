#!/bin/bash

# This script is based upon https://github.com/gagle/raspberrypi-motd

clear

function color () {
  echo "\e[$1m$2\e[0m"
}

function extend () {
  local str="$1"
  let spaces=60-${#1}
  while [ $spaces -gt 0 ]; do
    str="$str "
    let spaces=spaces-1
  done
  echo "$str"
}

function center () {
  local str="$1"
  let spacesLeft=(78-${#1})/2
  let spacesRight=78-spacesLeft-${#1}
  while [ $spacesLeft -gt 0 ]; do
    str=" $str"
    let spacesLeft=spacesLeft-1
  done

  while [ $spacesRight -gt 0 ]; do
    str="$str "
    let spacesRight=spacesRight-1
  done

  echo "$str"
}

function sec2time () {
  local input=$1

  if [ $input -lt 60 ]; then
    echo "$input seconds"
  else
    ((days=input/86400))
    ((input=input%86400))
    ((hours=input/3600))
    ((input=input%3600))
    ((mins=input/60))

    local daysPlural="s"
    local hoursPlural="s"
    local minsPlural="s"

    if [ $days -eq 1 ]; then
      daysPlural=""
    fi

    if [ $hours -eq 1 ]; then
      hoursPlural=""
    fi

    if [ $mins -eq 1 ]; then
      minsPlural=""
    fi

    echo "$days day$daysPlural, $hours hour$hoursPlural, $mins minute$minsPlural"
  fi
}

borderColor=35
headerLeafColor=32
headerRaspberryColor=31
greetingsColor=36
statsLabelColor=33

borderLine="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
borderTopLine=$(color $borderColor "┏$borderLine┓")
borderBottomLine=$(color $borderColor "┗$borderLine┛")
borderBar=$(color $borderColor "┃")
borderEmptyLine="$borderBar                                                                              $borderBar"

# Header
header="$borderTopLine\n$borderEmptyLine\n"
header="$header$borderBar$(color $headerLeafColor      "          .~~.   .~~.                                                         ")$borderBar\n"
header="$header$borderBar$(color $headerLeafColor      "         '. \ ' ' / .'                                                        ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "          .~ .~~~..~.                      _                          _       ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "         : .~.'~'.~. :     ___ ___ ___ ___| |_ ___ ___ ___ _ _    ___|_|      ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "        ~ (   ) (   ) ~   |  _| .'|_ -| . | . | -_|  _|  _| | |  | . | |      ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "       ( : '~'.~.'~' : )  |_| |__,|___|  _|___|___|_| |_| |_  |  |  _|_|      ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "        ~ .~ (   ) ~. ~               |_|                 |___|  |_|          ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "         (  : '~' :  )                                                        ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "          '~ .~~~. ~'                                                         ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "              '~'                                                             ")$borderBar"

me=$(whoami)

# Greetings
greetings="$borderBar$(color $greetingsColor "$(center "Hello $me!")")$borderBar\n"
greetings="$greetings$borderBar$(color $greetingsColor "$(center "$(date +"%A %d %B %Y, %T")")")$borderBar"
#greetings="$greetings$borderBar$(center "")$borderBar\n"
#greetings="$greetings$borderBar$(color $greetingsColor "$(center "Built with Pi Oven - www.pioven.com")")$borderBar"

# System information

read loginFrom loginIP loginMonth loginDay loginTime loginYear <<< $(last $me -2 -F | awk 'NR==2 { print $2,$3,$5,$6,$7,$8 }')


# TTY login
if [[ $loginDay == - ]]; then
  loginDate=$loginIP
  loginIP=$loginFrom
fi

if [[ $loginDay =~ ^[0-9]+ ]]; then
  login=$( date -d "${loginDay}-${loginMonth}-${loginYear} ${loginTime}" +'%A %d %B %Y, %T' )
else
  # Not enough logins
  login="None"
fi

label1="$(extend $(hostname))"
label1="$borderBar  $(color $statsLabelColor "Hostname......:") $label1$borderBar"

ipAddress=', ' read -r -a array <<< "$(hostname -I)"

label2="$(extend ${array[0]})"
label2="$borderBar  $(color $statsLabelColor "IP Address....:") $label2$borderBar"

label3="$(extend "$login")"
label3="$borderBar  $(color $statsLabelColor "Last Login....:") $label3$borderBar"

uptime="$(sec2time $(cut -d "." -f 1 /proc/uptime))"
uptime="$uptime ($(date -d "@"$(grep btime /proc/stat | cut -d " " -f 2) +"%Y-%m-%d %H:%M:%S"))"

label4="$(extend "$uptime")"
label4="$borderBar  $(color $statsLabelColor "Uptime........:") $label4$borderBar"

label5="$(extend "$(free -m | awk 'NR==2 { printf "Total: %sMB, Used: %sMB, Free: %sMB",$2,$3,$4; }')")"
label5="$borderBar  $(color $statsLabelColor "Memory........:") $label5$borderBar"

label6="$(extend "$(df -h ~ | awk 'NR==2 { printf "Total: %sB, Used: %sB, Free: %sB",$2,$3,$4; }')")"
label6="$borderBar  $(color $statsLabelColor "Home space....:") $label6$borderBar"

stats="$label1\n$label2\n$label3\n$label4\n$label5\n$label6"

# Print motd
echo -e "$header\n$borderEmptyLine\n$greetings\n$borderEmptyLine\n$stats\n$borderEmptyLine\n$borderBottomLine"
