#!/bin/bash

#convert hex to base58 without dc
# hex2base58 "122000000"
# echo "8QwQj1 ?"
# hex2base58 "807542FB6685F9FD8F37D56FAF62F0BB4563684A51539E4B26F0840DB361E0027CCD5C4A8E"
# echo "5JhvsapkHeHjy2FiUQYwXh1d74evuMd3rGcKGnifCdFR5G8e6nH ?"
bin2hex() {
	od -A n -v -t x1|tr -d '\n[:space:]'
}
# repo = depots + (mirros) + build
# update: download latest from remote and do git remote update
# save: upload to the main site(sae) and dispread to multi remotes (qiniu/oss/...)

calcmod() {
	local sum=0
	local nzero=0
	for((i=0;i<${#array[@]};i++)); do
		((sum = sum*$sbase + array[$i]))
		array[$i]=$((sum/$dbase))
		((sum = sum%dbase))
		((nzero += array[$i]))
	done
	if ((nzero == 0)) 
	then
		echo ${syms[$sum]}$1
	else
		calcmod ${syms[$sum]}$1
	fi
}

base58sym=({1..9} {A..H} {J..N} {P..Z} {a..k} {m..z})
base58symstr=$(IFS=""; echo "${base58sym[*]}")
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

	local sbase=256
	local dbase=58
	local syms=(${base58sym[@]})
	calcmod
}

hexsym=({0..9} {a..f})
base582hex() {
	local array=()
	local h=$1
	local i=${#h}
	for ((i=0;i<${#h};i++)) 
	do
		local tmpstr=${base58symstr%${h:$i:1}*}
		array=(${array[@]} ${#tmpstr})
	done

	local sbase=58
	local dbase=16
	local syms=(${hexsym[@]})
	calcmod
}

hex2base58 "122000000"
echo "8QwQj1 ?"
hex2base58 "807542FB6685F9FD8F37D56FAF62F0BB4563684A51539E4B26F0840DB361E0027CCD5C4A8E"
echo "5JhvsapkHeHjy2FiUQYwXh1d74evuMd3rGcKGnifCdFR5G8e6nH ?"
base582hex "5JhvsapkHeHjy2FiUQYwXh1d74evuMd3rGcKGnifCdFR5G8e6nH"
echo "807542FB6685F9FD8F37D56FAF62F0BB4563684A51539E4B26F0840DB361E0027CCD5C4A8E ?"
echo "012"|bin2hex
exit

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
	
