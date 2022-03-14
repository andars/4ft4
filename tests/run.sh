#!/usr/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CLEAR='\033[0m'

source="$1"
binary="$2"

sim="./sim"
sim_args=""
sim_log="${binary%.*}.sim.log"
end_log="${binary%.*}.end.sim.log"

expected=()

while read -r cmd args; do
    if [ $cmd = '!rand' ]; then
        sim_args="$sim_args -r";
    fi

    if [ $cmd = '!expect' ]; then
        expected+=("$args");
    fi

    if [ $cmd = '!cycles' ]; then
        sim_args="$sim_args -c $args"
    fi

    if [ $cmd = '!ram' ]; then
        sim_args="$sim_args -m"
    fi

    if [ $cmd = '!romport' ]; then
        sim_args="$sim_args -p $args"
    fi
done < <(grep '!' $source)

echo "sim_args $sim_args"
echo "expected"
declare -p expected

echo 'running simulator'
echo "sim command: $sim $sim_args $binary"
output=`$sim $sim_args $binary`
echo 'done'

echo "simulator log: $sim_log"
echo "$output">$sim_log

echo "end log: $end_log"
end=`echo "$output" | grep -A500 'Finished.'`
echo "$end">$end_log

for line in "${expected[@]}"; do
    echo -n "expecting to see '$line'...";

    if echo "$end" | grep -q "$line"; then
        echo " found."
    else
        echo " not found."
        echo -e "${RED}FAILED${CLEAR} $source"
        exit 1
    fi
done

echo -e "${GREEN}PASSED${CLEAR} $source"
