#!/usr/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CLEAR='\033[0m'

src="$1"
log="$2"

end_log="${log%.*}.end.sim.log"

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

done < <(grep '!' $src)

echo "expected"
declare -p expected

output=`cat $log`

echo "end log: $end_log"
end=`echo "$output" | grep -A500 'Finished.'`
echo "$end">$end_log

for line in "${expected[@]}"; do
    echo -n "expecting to see '$line'...";

    if echo "$end" | grep -q "$line"; then
        echo " found."
    else
        echo " not found."
        echo -e "${RED}FAILED${CLEAR} $src"
        exit 1
    fi
done

echo -e "${GREEN}PASSED${CLEAR} $src"
