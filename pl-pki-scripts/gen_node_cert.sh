#!/bin/bash
set -e
NODE_NAME=node-$1

if [ -z "$3" ] ; then
  unset CA_PASS KS_PASS
  read -p "Enter CA pass: " -s CA_PASS ; echo
  read -p "Enter Keystore pass: " -s KS_PASS ; echo
 else
  KS_PASS=$2
  CA_PASS=$3
fi

rm -f $NODE_NAME-keystore.jks
rm -f $NODE_NAME.csr
rm -f $NODE_NAME-signed.pem

echo Generating keystore and certificate for node $NODE_NAME

keytool -genkey \
        -alias     $NODE_NAME \
        -keystore  $NODE_NAME-keystore.jks \
        -keyalg    RSA \
        -keysize   2048 \
        -validity  712 \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$4, OU=SSL, O=Test, L=Test, C=DE" \
        -ext san=dns:$4,dns:elastic.svc.pl.internal,ip:$1,oid:1.2.3.4.5.5

echo Generating certificate signing request for node $NODE_NAME

keytool -certreq \
        -alias      $NODE_NAME \
        -keystore   $NODE_NAME-keystore.jks \
        -file       $NODE_NAME.csr \
        -keyalg     rsa \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$4, OU=SSL, O=Test, L=Test, C=DE" \
        -ext san=dns:$4,dns:elastic.svc.pl.internal,ip:$1,oid:1.2.3.4.5.5

echo Sign certificate request with CA
openssl ca \
    -in $NODE_NAME.csr \
    -notext \
    -out $NODE_NAME-signed.pem \
    -config etc/signing-ca.conf \
    -extensions v3_req \
    -batch \
	-passin pass:$CA_PASS \
	-extensions server_ext 

echo "Import back to keystore (including CA chain)"

cat ca/chain-ca.pem $NODE_NAME-signed.pem | keytool \
    -importcert \
    -keystore $NODE_NAME-keystore.jks \
    -storepass $KS_PASS \
    -noprompt \
    -alias $NODE_NAME
    
keytool -importkeystore -srckeystore $NODE_NAME-keystore.jks -srcstorepass $KS_PASS -srcstoretype JKS -deststoretype PKCS12 -deststorepass $KS_PASS -destkeystore $NODE_NAME-keystore.p12

echo All done for $NODE_NAME
	
