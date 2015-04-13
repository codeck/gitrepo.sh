gitrepo.sh
==========

A bash script to backup git repos with encryption

The script require Bash above v3 (msysgit matches) only.


## Scenario: backup git repos

```bash
$ ls myrepos/
projectA.git  projectB.gti
```

```bash
$ gitrepo.sh pack myrepos/
~/myrepos ~
Username: nobody
Password:******
Loading 'screen' into random state - done
packing using random key 6pcSHmgeN5qZCkdqACS1y6...
~
```

Here we typed "nobody" as username and "passed" as password, gitrepo will geenerate a random (base58 encoded) key.
The random key will be encrypt by Username-Password pair in the following generated script

```bash
$ ls myrepos/
myrepos-2014-04-13.0910.ss  myrepos-2014-04-13.0910.stgz  projectA.git  projectB.git

$ cat myrepos/myrepos-2014-04-13.0910.ss
#!/bin/bash
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


randkey=`openssl aes-128-cbc -d -k $uname:$passwd -base64 <<'=EOF='
U2FsdGVkX1/XoKf1FoWCGFR3SkdOlFoN/CYTm7Lsbp5b4h6nH4j4OfbdTcNUTw91
=EOF=`
openssl aes-256-cbc -d -k $randkey -in ${0%.ss}.stgz | tar zx
```

We can restore the repos from the .ss and .stag files with username/password.
The files can be stored publicly.

```bash
$ mkdir restore

$ cd restore/

$ ../myrepos/myrepos-2014-04-13.0910.ss
Username: nobody
Password:******

$ ls
projectA.git  projectB.git
```

## Scenario: write a secret memo

```
$ gitrepo.sh/gitrepo.sh memo shudong.ss
Username: nobody
Password:******
Loading 'screen' into random state - done
say the secret... (ctrl-d to end, then encrypt by random key TRm53vEQxuHK9vR1R7oqEF)
the secret number is 42
don't tell anyone
保密!  
(Ctrl-D typed)
secret saved to shudong.ss
```
```bash
$ cat shudong.ss
#!/bin/bash
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


randkey=`openssl aes-128-cbc -d -k $uname:$passwd -base64 <<'=EOF='
U2FsdGVkX18itKKgULUwYkVjgvMBe25+rH4JiCvQLvdyAC6Mk4Hf4+iU7ejEsUvk
=EOF=`
openssl aes-256-cbc -d -k $randkey -base64 <<'=EOF='
U2FsdGVkX18y3u5YkHZ3qzmjPljekaT85WvT+cjiWuuEhKj93MF2pvFZKLKuq3Ru
J1uWtYu4Pr5L1wdr3ILwu4zs0GyhUjyvFky50ICQ1ms=
=EOF=
```
```
$ ./shudong.ss
Username: nobody
Password:******
the secret number is 42
don't tell anyone
保密!
```
