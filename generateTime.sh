#!/bin/bash

. structure
. commonFunctions

[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

cd generated

genTimeCA(){ #csr,ca to sign with,start,end
    KNAME=$2
    . ../CAs/${KNAME}
    cat <<TESTCA > timesubca.cnf
basicConstraints=critical,CA:true
keyUsage=critical,keyCertSign, cRLSign

subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always

crlDistributionPoints=URI:http://g2.crl.${DOMAIN}/g2/$2.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.${DOMAIN},caIssuers;URI:http://g2.crt.${DOMAIN}/g2/$2.crt

certificatePolicies=@polsect

[polsect]
policyIdentifier = 1.3.6.1.4.1.18506.9.2.${CPSID}
CPS.1="http://g2.cps.${DOMAIN}/g2/${KNAME}.cps"

TESTCA
    caSign $1 $2 timesubca.cnf "$3" "$4"
    rm timesubca.cnf
}

mkdir -p $year/ca


for i in $TIME_IDX; do
    point=${year}${points[${i}]}
    nextp=${points[$((${i} + 1))]}
    if [[ "$nextp" == "" ]]; then
	epoint=$((${year} + 3 ))${epoints[${i}]}
    else
	epoint=$((${year} + 2 ))${epoints[${i}]}
    fi

    . ../CAs/env
    genca "/CN=$name ${year}-${i}" $year/ca/env_${year}_${i}
    genTimeCA $year/ca/env_${year}_${i}.ca/key env "$point" "$epoint"
    
    for ca in $STRUCT_CAS; do
	[ "$ca" == "env" ] && continue
	. ../CAs/$ca
	genKey "/CN=$name ${year}-${i}" $year/ca/${ca}_${year}_${i}
	genTimeCA $year/ca/${ca}_${year}_${i} $ca "$point" "$epoint"
    done
done
