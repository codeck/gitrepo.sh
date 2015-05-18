#!/bin/bash

module(){ IFS='' read -r -d '' ${1} || true; }

module MISCUTIL<<'EOF'
bin2hex() {
	od -A n -v -t x1|tr -d '\n[:space:]'
}
blobid=`echo -n $uname | openssl sha  -sha256 -hmac $passwd`

EOF

module READPASS <<'EOF'
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

EOF

module BASE58 <<'EOF'
#convert hex to base58 without dc
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

EOF

eval "$BASE58"

case $1 in
	memo)
		[[ -z $2 ]] && echo "need memo file name!" && exit
		if [[ -e $2 ]]			
			then read -n 1 -p "file exits, append to $2 ? (y/n)" yn
			echo ""
			if [ "y" = $yn ]
			then 
				randkey=''
				eval "$(sed -n '0,/^#V2PayLoads$/p' $2)"
				echo "say the secret to append... (ctrl-d to end, then encrypt by random key $randkey)"
				secret=$(cat|openssl aes-256-cbc -salt -k $randkey -a)
				echo "openssl aes-256-cbc -d -k \$randkey -base64 <<'=EOF='" >>$2
				echo "$secret" >>$2
				echo "=EOF=" >>$2
				echo "done!"
			else
				echo "abort!"
			fi
			exit
		fi
		eval "$READPASS"
		randkey=$(hex2base58 `openssl rand -hex 16`)
		sskey=$(echo -n $randkey|openssl aes-128-cbc -salt -k $uname:$passwd -a)

		echo "say the secret... (ctrl-d to end, then encrypt by random key $randkey)"
		secret=$(cat|openssl aes-256-cbc -salt -k $randkey -a)

		echo "#!/bin/bash">$2
		echo "$READPASS" >>$2
		echo "randkey=\`openssl aes-128-cbc -d -k \$uname:\$passwd -base64 <<'=EOF='" >>$2
		echo "$sskey" >>$2
		echo "=EOF=\`" >>$2
		echo "if [[ \$? != 0 || -z randkey ]]" >>$2
		echo "then echo 'Wrong password!';  unset randkey; exit 1" >>$2
		echo "fi" >>$2
		echo "#V2PayLoads" >>$2
		echo "openssl aes-256-cbc -d -k \$randkey -base64 <<'=EOF='" >>$2
		echo "$secret" >>$2
		echo "=EOF=" >>$2
		echo "secret saved to $2"
		;;
	pack) 
		pushd $2
		namepre=`basename $2`-`date +%F.%H%M`
		eval "$READPASS"
		randkey=$(hex2base58 `openssl rand -hex 16`)
		sskey=$(echo -n $randkey|openssl aes-128-cbc -salt -k $uname:$passwd -a)
		echo "packing using random key $randkey..."
		echo "#!/bin/bash">$namepre.ss
		echo "$READPASS" >>$namepre.ss
		echo "randkey=\`openssl aes-128-cbc -d -k \$uname:\$passwd -base64 <<'=EOF='" >>$namepre.ss
		echo "$sskey" >>$namepre.ss
		echo "=EOF=\`" >>$namepre.ss
		echo "openssl aes-256-cbc -d -k \$randkey -in \${0%.ss}.stgz | tar zx" >>$namepre.ss
		tar cfz - *.git |openssl aes-256-cbc -salt -k $randkey -out $namepre.stgz
		popd
		;;
	*)
		echo "only memo/pack command supported!"
		;;
esac
	
