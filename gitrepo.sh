#!/bin/bash

# repo = depots + (mirros) + build
# update: download latest from remote and do git remote update
# save: upload to the main site(sae) and dispread to multi remotes (qiniu/oss/...)

# read -p "Username: " uname
# #read -s -p "Password: " passwd
# unset passwd
# prompt="Password:"
# while IFS= read -p "$prompt" -r -s -n 1 char
# do
#     if [[ $char == $'\0' ]]
#     then
#         break
#     fi
#     prompt='*'
#     passwd+="$char"
# done
# echo


#$ echo -n|openssl sha1 -sha256 -hmac ""
#b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad

# http://justmoon.github.io/pakdf/

###blobid=`echo -n $uname | openssl sha  -sha256 -hmac $passwd`
###randkey=`openssl rand -hex 32`

base58sym=({1..9} {A..H} {J..N} {P..Z} {a..k} {m..z})
calcmod58() {
	local sum=0
	local nzero=0
	for((i=0;i<${#array[@]};i++)); do
		((sum = sum*256 + array[$i]))
		array[$i]=$((sum/58))
		if (( array[$i] !=0 )) 
		then
			((nzero++))
		fi
		((sum = sum%58))
	done
	if ((nzero > 0)) 
	then
		calcmod58 ${base58sym[$sum]}$1
	else
		echo ${base58sym[$sum]}$1
	fi
}

hex2base58() {
	local array=()
	local h=$1
	local i=${#h}
	while (( $i > 0 )); do
		case $i in
			1)
				array=($((16#${s:0:1})) ${array[@]})
				;;
			*)
				array=($((16#${s:$i-2:2})) ${array[@]})
				;;
		esac
		((i = i-2))
	done
	calcmod58	
}

#"12345" =>PAc
#"122000000" => 8QwQj1
#"807542FB6685F9FD8F37D56FAF62F0BB4563684A51539E4B26F0840DB361E0027CCD5C4A8E" =>"5JhvsapkHeHjy2FiUQYwXh1d74evuMd3rGcKGnifCdFR5G8e6nH"

s="807542FB6685F9FD8F37D56FAF62F0BB4563684A51539E4B26F0840DB361E0027CCD5C4A8E"
hex2base58 $s

case $1 in
	save) 
		pushd $2
		tar cfz - depots |openssl aes-256-cbc -salt -k 123456 -out out.tgz.aes
		popd
		;;
	update) 
		openssl aes-256-cbc -d -in $2/out.tgz.aes | tar zx
		;;
	*)
		echo "only save/upload command supported!"
		;;
esac
	
