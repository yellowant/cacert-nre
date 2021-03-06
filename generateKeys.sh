#!/bin/bash
# this script generates a set of sample keys
set -e

. structure
. commonFunctions

mkdir -p generated
cd generated

####### create various extensions files for the various certificate types ######
cat <<TESTCA > ca.cnf
basicConstraints = critical,CA:true
keyUsage =critical, keyCertSign, cRLSign

subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always

crlDistributionPoints=URI:http://g2.crl.${DOMAIN}/g2/root.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.${DOMAIN},caIssuers;URI:http://g2.crt.${DOMAIN}/g2/root.crt
TESTCA


rootSign(){ # csr
    POLICY=ca.cnf
    if [[ "$1" != "root" ]] ; then
	KNAME=$1
	POLICY=subca.cnf
	. ../CAs/${KNAME}
	cat <<TESTCA > subca.cnf

basicConstraints =critical, CA:true
keyUsage =critical, keyCertSign, cRLSign

subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always

crlDistributionPoints=URI:http://g2.crl.${DOMAIN}/g2/root.crl
authorityInfoAccess = OCSP;URI:http://g2.ocsp.${DOMAIN},caIssuers;URI:http://g2.crt.${DOMAIN}/g2/root.crt

certificatePolicies=@polsect

[polsect]
policyIdentifier = 1.3.6.1.4.1.18506.9.2.${CPSID}
CPS.1="http://g2.cps.${DOMAIN}/g2/${KNAME}.cps"

TESTCA
    fi
    caSign "$1.ca/key" root $POLICY
}


# Generate the super Root CA
genca "/CN=Cacert-gigi testCA" root
#echo openssl x509 -req $ROOT_VALIDITY -in root.ca/key.csr -signkey root.ca/key.key -out root.ca/key.crt -extfile ca.cnf
rootSign root

# generate the various sub-CAs
for ca in $STRUCT_CAS; do
    . ../CAs/$ca
    genca "/CN=$name" $ca
    rootSign $ca
done

rm ca.cnf subca.cnf



