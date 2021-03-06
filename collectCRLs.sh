#!/bin/bash

set -e

[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure
. commonFunctions
cd generated

fetchCRLS(){ #year, cyear month timeIdx
    year=$1
    cyear=$2
    month=$3
    timeIdx=$4
    cp -v $year/ca/env_${year}_${timeIdx}.ca/${cyear}_${month}.crl crls-${year}/$cyear-$month/${year}/env_${year}_${timeIdx}.crl
    # no "for ca in $STRUCT_CAs" because that's cassiopeias work.
}

rm -Rf crls-${year}
mkdir -p crls-${year}
for month in {01..12}; do
    BASE=crls-${year}/$year-$month
    mkdir -p $BASE
    cp root.ca/${year}_${month}.crl $BASE/root.crl
    for ca in $STRUCT_CAS; do
	cp $ca.ca/${year}_${month}.crl $BASE/$ca.crl
    done
done

cyear=$year
for month in {01..12}; do
    BASE=crls-${year}/$cyear-$month
    mkdir -p $BASE/$year

    fetchCRLS $year $cyear $month 1
    [ "$month" -gt "6" ] && fetchCRLS $year $cyear $month 2
done

cyear=$((year+1))
for month in {01..12}; do
    BASE=crls-${year}/$cyear-$month
    mkdir -p $BASE/$year

    fetchCRLS $year $cyear $month 1
    fetchCRLS $year $cyear $month 2
done

cyear=$((year+2))
for month in {01..06}; do
    BASE=crls-${year}/$cyear-$month
    mkdir -p $BASE/$year

    fetchCRLS $year $cyear $month 2
done

pushd crls-${year}
rm -f crl-passwords1.txt crl-passwords2.txt
for i in *; do
    PASSW1=`head -c15 /dev/urandom | base64`
    PASSW2=`head -c15 /dev/urandom | base64`
    echo "Crypting CRL $i"
    echo "$i: $PASSW1" >> crl-passwords1.txt
    echo "$i: $PASSW2" >> crl-passwords2.txt
    tar c -C $i . | openssl enc -e -kfile <(echo -n "$PASSW1$PASSW2") -md sha256 -aes-256-cbc > $i.tar.aes-256-cbc
    PASSW1=
    PASSW2=

done
popd
