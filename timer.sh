#!/usr/bin/env bash

source ./agenda.sh

# Detect GNU || BSD style date command
if date --version | grep GNU ; then
  DATE_GNU=true
  DATE_PRE="date -d"
  DATE_TIMER=" minutes"
else
  DATE_GNU=false
  DATE_PRE="date -v"
  DATE_TIMER="M"
fi

C_DEFAULT="\e[0m"
C_YELLOW="\e[43m"
C_GREEN="\e[92m"
C_RED="\e[91m"

planned_time=0
remaining_time=0
c=-1
tc=0
tt=0

format="%20s:"

floor () {
  DIVIDEND=${1}
  DIVISOR=${2}
  RESULT=$(( ( ${DIVIDEND} - ( ${DIVIDEND} % ${DIVISOR}) )/${DIVISOR} ))
  echo ${RESULT}
}

for i in ${!lengths[@]}; do
  planned_time=$((planned_time+${lengths[$i]}))
done

while true; do
  segment_secs=$((m*60))

  tt=$((tt+1))
  tc=$((tc+1))
  clear
  echo
  date

  s=$tt
  HOUR=$( floor ${s} 60/60 )
  s=$((${s}-(60*60*${HOUR})))
  MIN=$( floor ${s} 60 )
  SEC=$((${s}-60*${MIN}))

  printf "$format" "Total Time" "$(printf "%02d:%02d:%02d\033[0K\r" $HOUR $MIN $SEC)"

  s=$tc
  HOUR=$( floor ${s} 60/60 )
  s=$((${s}-(60*60*${HOUR})))
  MIN=$( floor ${s} 60 )
  SEC=$((${s}-60*${MIN}))

  echo -n -e "\nTime in segment: "
  printf "%02d:%02d:%02d\033[0K\r" $HOUR $MIN $SEC
  echo -e "\n\n"

  if [[ "$C" -lt "-1" ]]; then
    c=-1
  fi

  if [[ "$c" -eq "-1" ]]; then
    current_time=$(date)
    planned_end_time=$($DATE_PRE "+${planned_time}${DATE_TIMER}")

    echo "Upcoming:"

    for i in ${!segments[@]}; do
      echo "${segments[$i]}, ${lengths[$i]} minute(s) "
    done
  else
    [[ -z "${lengths[$c]}" ]] && break

    m=${lengths[$c]}
    segment_secs=$((m*60))

    rs=$((segment_secs-tc))
    R_HOUR=$( floor ${rs} 60/60 )
    rs=$((${rs}-(60*60*${R_HOUR})))
    R_MIN=$( floor ${rs} 60 )
    R_SEC=$((${rs}-60*${R_MIN}))

    echo
    echo -e "Current: ${segments[$c]}\n"

    if [[ "$rs" -lt "00" ]]; then
      COLOR=$C_RED
    elif [[ "$rs" -lt "30" ]]; then
      COLOR=$C_YELLOW
    else
      COLOR=$C_GREEN
    fi

    echo -n "Remaining Time: "
    printf "${COLOR}%02d:%02d:%02d\033[0K\r${C_DEFAULT}" $R_HOUR $R_MIN $R_SEC

    echo -e "\n"

    echo -n "Up Next: "
    [[ -z "${segments[$((c + 1))]}" ]] && echo "END" || echo "${segments[$((c + 1))]}"
    echo -e "\nNotes:\n${notes[$c]}"
  fi

  echo -e "\nPlanned end time: ${planned_end_time}"
  end_time=$($DATE_PRE "+${remaining_time}${DATE_TIMER}")
  echo "Tracking end at: ${end_time}"



  read -rsn1 -t1 input

  case $input in
    n)
      remaining_time=$((planned_time-remaining_time-${lengths[$c]}))
      c=$((c + 1))
      tc=0
      ;;
    b)
      remaining_time=$((planned_time-remaining_time+${lengths[$c]}))
      c=$((c - 1))
      ;;
    q)
      exit 0
      ;;
  esac


  # Clear input for older versions of bash
  input=''

done

clear

echo "Planned End Time: ${planned_end_time}"
echo "End Time: $(date)"

echo "Total Time: ${tt}"
