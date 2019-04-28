#!/bin/ksh

#############################################################################
# Source name: pk_cert_tool.sh
# Author : BKO
# Date : 04/04/2019
# Description : This script manages the signing and verification and 
#                generation of private/public keys
# Code reviewer : FBM
# Date review : XX/04/2019
#############################################################################

function fDisplayINFO {
    echo -e "\033[32m [INFO] $*\033[00m"
}

function fDisplayWARNING {
    echo -e "\033[33m [WARNING] $*\033[00m"
}

function fDisplayERROR {
    echo -e "\033[31m [ERROR] $*\033[00m"
}

function fDisplayUSAGE {
    
    echo -e "\033[33m  USAGE: pk_cert_tool.sh [generate|sign|verify] <file to sign> \033[00m"
    echo -e "\033[33m                --> generate key/pair        pk_cert_tool.sh generate \033[00m"
    echo -e "\033[33m                --> sign a file              pk_cert_tool.sh sign <file name> \033[00m"
    echo -e "\033[33m                --> verify a file            pk_cert_tool.sh verify  <file name> \033[00m"
}

function generatePair {

    openssl genrsa -aes128 -passout pass:$passWord -out $private_key 4096
    value=$?
    if [[ $value -eq 0 ]]; then
       fDisplayINFO    "Generation of private key  [$private_key]    -->   OK"
    else
       fDisplayERROR "Issue generation of private key  [$private_key]-->  FAILURE"
       exit 1
    fi
    openssl rsa -in $private_key -passin pass:$passWord -pubout -out $public_key 
    value=$?
    if [[ $value -eq 0 ]]; then
       fDisplayINFO    "Generation of public key  [$public_key]    -->   OK"
    else
       fDisplayERROR "Issue generation of public key  [$public_key]  -->  FAILURE"
       exit 1
    fi

}

function signFile {
    fileName=$1
    fDisplayINFO "CMD: openssl dgst -sha256 -sign $private_key -out /tmp/$fileName.sha256 -passin pass:XXXXXX $fileName"
    openssl dgst -sha256 -sign $private_key -out /tmp/$fileName.sha256 -passin pass:$passWord $fileName
    value=$?
    if [[ $value -eq 0 ]]; then
       fDisplayINFO    "Signing of [$1]    -->   OK"
    else
       fDisplayERROR "Issue with signing $1 -->  FAILURE"
       exit 1
    fi
    fDisplayINFO "CMD:openssl base64 -in /tmp/$fileName.sha256 -out $fileName.signed-SHA256 "
    openssl base64 -in /tmp/$fileName.sha256 -out $fileName.signed-SHA256
    value=$?
    if [[ $value -eq 0 ]]; then
       fDisplayINFO    "Signing of [$1]    -->   OK"
    else
       fDisplayERROR "Issue with signing $1 -->  FAILURE"
       exit 1
    fi
    rm /tmp/$fileName.sha256
}



function verifyFile {
    
    signiture=$1
    fileName=$2

    fDisplayINFO "CMD: openssl base64 -d -in $signiture -out /tmp/$fileName.sha256"
    openssl base64 -d -in $signiture -out /tmp/$fileName.sha256
    value=$?
    if [[ $value -eq 0 ]]; then
       fDisplayINFO    "Generate temp sig file  /tmp/$fileName.sha256  OK"
    else
       fDisplayERROR "Issue with generate of sig temp  [/tmp/$fileName.sha256] FAILURE"
       exit 1
    fi

    fDisplayINFO "CMD: openssl dgst -sha256 -verify $public_key -signature /tmp/$fileName.sha256 $fileName"
    result=$(openssl dgst -sha256 -verify $public_key -signature /tmp/$fileName.sha256 $fileName)
    value=$?
    if [[ $value -eq 0 ]]; then
       fDisplayINFO    "Verification [$result]   OK"
    else
       fDisplayERROR "Issue with verification [$result] FAILURE"
       exit 1
    fi
    
    rm /tmp/$fileName.sha256 
}

##########################################################
## MAIN
###########################################################

###########################################################
# Global VARIABLES

passWord="Thaler?123"
private_key="/opt/scm/scmtools/tmp/bko/private.pem"
public_key="/opt/scm/scmtools/tmp/bko/public.pem"

###########################################################

# Process user input
cmd=$1
file=$2
signatureFile="$file.signed-SHA256"

case $cmd in
        "generate")
                generatePair
                ;;
        "sign")
                signFile $file
                ;;
        "verify")
                verifyFile  $signatureFile $file
                ;;
        *)
                fDisplayUSAGE
                ;;
esac
