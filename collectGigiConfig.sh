#!/bin/bash

set -e
[ "$1" == "" ] && echo "Usage: $0 <year>" && exit 1
year=$1

. structure
cd generated

mkdir -p gigi-config/config/ca
cp root.ca/key.crt gigi-config/config/ca/root.crt
for ca in $STRUCT_CAS; do
    cp ${ca}.ca/key.crt gigi-config/config/ca/${ca}.crt
    [ "$ca" == "env" ] && continue
    for i in $TIME_IDX; do
	cp ${year}/ca/${ca}_${year}_${i}.crt gigi-config/config/ca/${ca}_${year}_${i}.crt
    done
done

cp -R ../profiles gigi-config/config

mkdir -p gigi-config/keys
for k in ${year}/keys/{api,mail,secure,static,www}.pkcs12; do
   cp $k gigi-config/keys
done

tar czf gigi-$year.tar.gz -C gigi-config config keys

rm -Rf gigi-config
