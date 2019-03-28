#!/usr/bin/env bash

function get_time() {
  date_time=$(date)
  echo ${date_time}
}

segments=(Introduction Video Response "Agile Feedback Review")
lengths=(5 4 3 5)
notes=("Thank you..." "Set audio input\nPlay Video" "*Reset audio input\nAsk for response" "Feedback Deck")

c=-1

while true; do
  clear
  echo
  date
  echo -e "\n\n"

  if [[ "$c" -eq "-1" ]]; then
    echo "Upcoming:"
    for i in ${!segments[@]}; do
      echo "${segments[$i]}, ${lengths[$i]} minute(s) "
    done
  else
    echo "Current: ${segments[$c]}"
    echo "Up Next: ${segments[$((c + 1))]}"
    echo -e "\nNotes:\n${notes[$c]}"
  fi

  read -rsn1 -t1 input

  case $input in
    s)
      start_timer
      ;;
    n)
      c=$((c + 1))
      ;;
    b)
      c=$((c - 1))
      ;;
    q)
      exit 0
      ;;
  esac

  if [ "$input" = "a" ]; then
    echo "hello world"
  fi

#  sleep 0.11

  # Clear input for older versions of bash
  input=''

done
