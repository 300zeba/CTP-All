#!/bin/bash

if (($# != 2)); then
  echo "usage: ./get_vazao.sh <FIRST> <LAST>"
  exit 1
fi

INIT=$1
END=$2
for i in $(seq $INIT $END)
do
  if [ -e outputs/out_$i.txt ]
  then
    python process_vazao_testes.py $i
  fi
done
