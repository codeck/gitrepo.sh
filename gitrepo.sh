#!/bin/bash

base58sym=({1..9} {A..H} {J..N} {P..Z} {a..k} {m..z})
calcmod58() {
	local sum=0
	local nzero=0
	for((i=0;i<${#array[@]};i++)); do
		((sum = sum*256 + array[$i]))
		array[$i]=$((sum/58))
		((sum = sum%58))
		((nzero += array[$i]))
	done
	if ((nzero == 0)) 
	then
		echo ${base58sym[$sum]}$1
	else
		calcmod58 ${base58sym[$sum]}$1
	fi
}

hex2base58() {
	local array=()
	local h=$1
	local i=${#h}
	while (( $i > 0 )); do
		case $i in
			1)
				array=($((16#${h:0:1})) ${array[@]})
				;;
			*)
				array=($((16#${h:$i-2:2})) ${array[@]})
				;;
		esac
		((i = i-2))
	done
	calcmod58	
}

read -p "Username: " uname
#read -s -p "Password: " passwd
unset passwd
prompt="Password:"
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt='*'
    passwd+="$char"
done
echo

blobid=`echo -n $uname | openssl sha  -sha256 -hmac $passwd`

case $1 in
	pack) 
		pushd $2
		randkey=$(hex2base58 `openssl rand -hex 16`)
		namepre=`basename $2`-`date +%F.%H%M`
		echo "packing using random key $randkey..."
		echo -n $randkey|openssl aes-128-cbc -salt -k $uname:$passwd -a -out $namepre.ss
		tar cfz - *.git |openssl aes-256-cbc -salt -k $randkey -out $namepre.stgz
		popd
		;;
	unpack) 
		randkey=`openssl aes-128-cbc -d -k $uname:$passwd -base64 -in $2`
		openssl aes-256-cbc -d -k $randkey -in ${2%.ss}.stgz | tar zx
		;;
	*)
		echo "only pack/unpack command supported!"
		;;
esac
	
