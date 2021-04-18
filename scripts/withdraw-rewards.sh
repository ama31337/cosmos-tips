#!/bin/bash

#export path
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:/usr/local/go/bin:$GOBIN

# set app and network
APP_NAME="regen"
APP_PATH=`which $APP_NAME`
CHAIN_ID="regen-1"
NODE_URL="http://127.0.0.1:26657"
MIN_WITHDRAW=1000000
TX_FEES="50000uregen"

# set acc & pass
VAL_ACCOUNT="name1"
DELEG_ACCOUNT="name2"
PASS=`cat ${HOME}/ppp`
VAL_ADDRESS=$(echo -e ${PASS} | ${APP_PATH} keys show ${VAL_ACCOUNT} -a)
DELEG_ADDRESS=$(echo -e ${PASS} | ${APP_PATH} keys show ${DELEG_ACCOUNT} -a)
VALOPER=$(echo ${PASS} | ${APP_PATH} keys show ${VAL_ACCOUNT} --bech val --address)

# check rewards
VAL_FEE_REWARDS=$(${APP_PATH} q distribution validator-outstanding-rewards ${VALOPER} --chain-id ${CHAIN_ID} --node=${NODE_URL} -oj | jq -r '.rewards | .[].amount' | egrep -o '[0-9]+\.' | tr -d .)

VAL_REWARDS=$(${APP_PATH} q distribution rewards ${VAL_ADDRESS} ${VALOPER} --chain-id ${CHAIN_ID} --node ${NODE_URL} -oj | jq -r '.rewards | .[].amount' | egrep -o '[0-9]+\.' | tr -d .)

DELEG_REWARDS=$(${APP_PATH} q distribution rewards ${DELEG_ADDRESS} ${VALOPER} --chain-id ${CHAIN_ID} --node ${NODE_URL} -oj | jq -r '.rewards | .[].amount' | egrep -o '[0-9]+\.' | tr -d .)

# echo data
#echo "val addr:" $VAL_ADDRESS
#echo "valoper:" $VALOPER
#echo "delegator addr:" $DELEG_ADDRESS
echo "validator fee rewards:" $VAL_FEE_REWARDS
echo "validator rewards:" $VAL_REWARDS
echo "delegator rewards:" $DELEG_REWARDS

sleep 5

# withdraw validator rewards
if [[ $(bc -l <<< "${VAL_REWARDS} > ${MIN_WITHDRAW}") -eq 1 ]]
  then
    echo "let's withdraw validator rewards"
    echo -e "${PASS}\n" | ${APP_PATH} tx distribution withdraw-rewards ${VALOPER} --from ${VAL_ACCOUNT} --chain-id ${CHAIN_ID} --node=${NODE_URL} --fees ${TX_FEES} --yes
  else
    echo "no validator rewards to withdraw"
fi

sleep 5

# withdraw delegator rewards
if [[ $(bc -l <<< "${DELEG_REWARDS} > ${MIN_WITHDRAW}") -eq 1 ]]
  then
    echo "let's withdraw delegator rewards"
    echo -e "${PASS}\n" | ${APP_PATH} tx distribution withdraw-rewards ${VALOPER} --from ${DELEG_ACCOUNT} --chain-id ${CHAIN_ID} --node=${NODE_URL} --fees ${TX_FEES} --yes
  else
    echo "no delegator rewards to withdraw"
fi


