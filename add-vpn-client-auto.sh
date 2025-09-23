#!/bin/bash

WG_DIR="/etc/wireguard"

# Gather all the client numbers into an array
mapfile -t nums < <(
  for path in "$WG_DIR"/client*; do
    # extract digits after “client”
    if [[ $(basename "$path") =~ client([0-9]+) ]]; then
      printf '%d\n' "${BASH_REMATCH[1]}"
    fi
  done
)

# If no clients yet, start at 1
if [[ ${#nums[@]} -eq 0 ]]; then
  echo 1
  exit 0
fi

# Find max and add 1
max=0
for n in "${nums[@]}"; do
  (( n > max )) && max=$n
done

next=$((max + 1))
echo "$next"


echo "Next available CLIENT_NUMBER is: $next"

./add-vpn-client-by-num.sh $next
