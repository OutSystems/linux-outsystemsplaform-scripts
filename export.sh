#!/bin/bash

if [ -z $1 ]; then
	echo "usage $0 file.pkf"
	exit
fi

read -p "Please enter the password for pkf file: " -s PASSWORD

if [ -z $PASSWORD ]; then
	echo
	echo "You must enter a password for this to work"
	exit
fi


openssl pkcs12 -passin pass:$PASSWORD -passout pass:jibberish -in $1 -nocerts -out key.pem
openssl pkcs12 -passin pass:$PASSWORD -in $1 -clcerts -nokeys -out cert.pem
openssl pkcs12 -passin pass:$PASSWORD -in $1 -cacerts -nokeys -out cert_chain.pem

openssl rsa -passin pass:jibberish -in key.pem -out priv.key


# After this is ran you end up with the following files:
# key.pem cert.pem cert_chain.pem priv.key

# Enter the contents of priv.key to the private key space in AWS

# enter the contents between ----BEGIN CERTIFICATE and ----END CERTIFICATE from
# cert.pem to the public certificate space in AWS


# the cert_chain may be trickier, but you need to put the certificates
# one after the other.

# TODO find a way to correctly pre-process the files