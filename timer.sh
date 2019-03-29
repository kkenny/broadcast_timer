#!/usr/bin/env bash

print_help() {
  echo "This is a tool to time-box a meeting / presentation / service."
  echo
  echo "Options:"
  echo "  Move to next segment: n|l|j"
  echo "  Move to previous segment: b|h|k"
  echo "  Quit: q"

  exit 1
}

unknown_option() {
  echo "Unknown option: ${1}"
  echo
  echo "To get help, execute with -h or --help"
  echo "Otherwse, pass no arguments to start program."

  exit 2
}

case $1 in
  help|h|-h|--help)
    print_help
    ;;
  "")
    ;;
  *)
    unknown_option $1
    ;;
esac

source ./agile-review-agenda.sh

# Detect GNU || BSD style date command
if date --version | grep GNU >/dev/null 2>&1; then
  DATE_GNU=true
  DATE_PRE="date -d"
  DATE_TIMER=" minutes"
  DATE_TIMER_S=" seconds"
else
  DATE_GNU=false
  DATE_PRE="date -v"
  DATE_TIMER="M"
  DATE_TIMER_S="s"
fi

C_DEFAULT="\e[0m"
C_YELLOW="\e[43m"
C_GREEN="\e[92m"
C_RED="\e[91m"

planned_time=0
remaining_time=0
total_over_under=0
segment_over_under=0
c=-1
tc=0
tt=0

floor () {
  DIVIDEND=${1}
  DIVISOR=${2}
  RESULT=$(( ( ${DIVIDEND} - ( ${DIVIDEND} % ${DIVISOR}) )/${DIVISOR} ))
  echo ${RESULT}
}

for i in ${!lengths[@]}; do
  planned_time=$((planned_time+${lengths[$i]}))
done

planned_time_seconds=$((planned_time*60))

while true; do
  segment_secs=$((m*60))

  tt=$((tt+1))
  tc=$((tc+1))
  clear
  echo
  date

  s=$planned_time_seconds
  P_HOUR=$( floor ${s} 60/60 )
  s=$((${s}-(60*60*${P_HOUR})))
  P_MIN=$( floor ${s} 60 )
  P_SEC=$((${s}-60*${P_MIN}))
  echo -n -e "\nPlanned Time:      "
  printf "%02d:%02d:%02d\033[0K\r" $P_HOUR $P_MIN $P_SEC

  s=$tt
  HOUR=$( floor ${s} 60/60 )
  s=$((${s}-(60*60*${HOUR})))
  MIN=$( floor ${s} 60 )
  SEC=$((${s}-60*${MIN}))

  echo
  echo -n "Total Time:        "
  printf "%02d:%02d:%02d\033[0K\r" $HOUR $MIN $SEC

  s=$tc
  HOUR=$( floor ${s} 60/60 )
  s=$((${s}-(60*60*${HOUR})))
  MIN=$( floor ${s} 60 )
  SEC=$((${s}-60*${MIN}))

  echo -n -e "\nTime in segment:   "
  printf "%02d:%02d:%02d\033[0K\r" $HOUR $MIN $SEC
  echo -e "\n\n"

  if [[ "$C" -lt "-1" ]]; then
    c=-1
  fi

  if [[ "$c" -eq "-1" ]]; then
    current_time=$(date)
    planned_end_time=$($DATE_PRE "+${planned_time}${DATE_TIMER}")

    echo
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
    echo -e "Current:           ${segments[$c]}\n"

    if [[ "$rs" -lt "00" ]]; then
      COLOR=$C_RED
    elif [[ "$rs" -lt "30" ]]; then
      COLOR=$C_YELLOW
    else
      COLOR=$C_GREEN
    fi

    echo -n "Remaining Time:    "
    printf "${COLOR}%02d:%02d:%02d\033[0K\r${C_DEFAULT}" $R_HOUR $R_MIN $R_SEC

    echo -e "\n"

    echo -n "Up Next:           "
    [[ -z "${segments[$((c + 1))]}" ]] && echo "END" || echo "${segments[$((c + 1))]} (${lengths[$((c + 1))]} Minute(s))"
    echo -e "\nNotes:\n${notes[$c]}"
  fi

  echo -e "\nPlanned end time:  ${planned_end_time}"
  end_time=$($DATE_PRE "+${planned_time}${DATE_TIMER} +${total_over_under}${DATE_TIMER_S}")
#  echo "Total Over/Under: ${total_over_under}"
  echo "Tracking End Time: ${end_time}"



  read -rsn1 -t1 input

  case $input in
    n|l|j)
      c=$((c + 1))
      [[ "${lengths[$c]}" -ge "0" ]] && segment_over_under=$((tc-(${lengths[$c]}*60)))
      total_over_under=$((total_over_under+segment_over_under))
      tc=0
      ;;
    b|h|k)
      c=$((c - 1))
      [[ "${lengths[$c]}" -ge "0" ]] && segment_over_under=$((tc+(${lengths[$((c + 1))]}*60)))
      total_over_under=$((total_over_under+segment_over_under))
      ;;
    q)
      exit 0
      ;;
  esac


  # Clear input for older versions of bash
  input=''

done

clear
s=$tt
T_HOUR=$( floor ${s} 60/60 )
s=$((${s}-(60*60*${T_HOUR})))
T_MIN=$( floor ${s} 60 )
T_SEC=$((${s}-60*${T_MIN}))


echo "Planned End Time: ${planned_end_time}"
echo "End Time: $(date)"
echo -n "Total Time: "
printf "${COLOR}%02d:%02d:%02d\033[0K\r${C_DEFAULT}" $T_HOUR $T_MIN $T_SEC

s=$total_over_under
T_HOUR=$( floor ${s} 60/60 )
s=$((${s}-(60*60*${T_HOUR})))
T_MIN=$( floor ${s} 60 )
T_SEC=$((${s}-60*${T_MIN}))
echo
echo -n "Over/Under: "
printf "${COLOR}%02d:%02d:%02d\033[0K\r${C_DEFAULT}" $T_HOUR $T_MIN $T_SEC
echo
