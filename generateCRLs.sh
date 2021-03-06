#!/bin/bash

set -e

[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure
. commonFunctions
cd generated

generateCRL() { # name, year, month
    echo CRL $1 $2-$3
    BASE="$PWD"
    pushd $1.ca > /dev/null
    TZ=UTC LD_PRELOAD=`ls /usr/lib/*/faketime/libfaketime.so.1` FAKETIME="${year}-${month}-01 00:00:00" openssl ca -gencrl -config "$BASE/../selfsign.config" -keyfile key.key -cert key.crt -crldays 35 -out $2_$3.crl
    popd > /dev/null
}

generateCRLs (){ #name start
    [[ "$2" == "" ]] && start=$(echo {01..12})
    [[ "$2" == "07" ]] && start=$(echo {07..12})
    for month in $start; do
	generateCRL "$1" "$year" "$month"
    done
}

generateYearCRLs (){ #name idx
    [[ "$2" == "1" ]] && start=$(echo {01..12})
    [[ "$2" == "2" ]] && start=$(echo {07..12})
    for month in $start; do
	generateCRL "$1" "$year" "$month"
    done
    [[ "$2" == "1" ]] && start=$(echo {01..12})
    [[ "$2" == "2" ]] && start=$(echo {01..12})
    for month in $start; do
	generateCRL "$1" "$((year+1))" "$month"
    done
    [[ "$2" == "1" ]] && return
    [[ "$2" == "2" ]] && start=$(echo {01..06})
    for month in $start; do
	generateCRL "$1" "$((year+2))" "$month"
    done
}
generateCRLs root
for ca in $STRUCT_CAS; do
    generateCRLs $ca
done

for i in ${TIME_IDX}; do
generateYearCRLs $year/ca/env_${year}_$i $i
generateYearCRLs $year/ca/env_${year}_$i $i

done
