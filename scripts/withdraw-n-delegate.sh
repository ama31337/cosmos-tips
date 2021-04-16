#!/bin/bash

# set app and network
APP_NAME="regen"
APP_PATH=`which $APP_NAME`
CHAIN_ID="regen-1"
NODE_URL="http://127.0.0.1:36657"
MIN_WITHDRAW=1000000
MIN_BALANCE=1000000
MIN_STAKE=2000000
TX_FEES="50000uregen"

# set acc & pass
VAL_ACCOUNT="addr1"
DEL_ACCOUNT="addr2"
PASS=`cat ${HOME}/ppp`
VAL_ADDRESS=$(echo -e ${PASS} | ${APP_PATH} keys show ${VAL_ACCOUNT} -a)
DEL_ADDRESS=$(echo -e ${PASS} | ${APP_PATH} keys show ${DEL_ACCOUNT} -a)
VALOPER=$(echo ${PASS} | ${APP_PATH} keys show ${VAL_ACCOUNT} --bech val --address)

VAL_REWARDS=$(${APP_PATH} q distribution rewards ${VAL_ADDRESS} ${VALOPER} --chain-id ${CHAIN_ID} --node ${NODE_URL} -oj | jq -r '.rewards | .[].amount' | egrep -o '[0-9]+\.' | tr -d .)

DEL_REWARDS=$(${APP_PATH} q distribution rewards ${DEL_ADDRESS} ${VALOPER} --chain-id ${CHAIN_ID} --node ${NODE_URL} -oj | jq -r '.rewards | .[].amount' | egrep -o '[0-9]+\.' | tr -d .)

# echo data
echo "validator rewards:" $VAL_REWARDS
echo "delegator rewards:" $DEL_REWARDS

sleep 5

# withdraw validator rewards
if [[ $(bc -l <<< "${VAL_REWARDS} > ${MIN_WITHDRAW}") -eq 1 ]]
  then
    echo "let's withdraw validator rewards"
    echo -e "${PASS}\n" | ${APP_PATH} tx distribution withdraw-rewards ${VALOPER} --from ${VAL_ACCOUNT} --chain-id ${CHAIN_ID} --node ${NODE_URL} --fees ${TX_FEES} --yes
  else
    echo "no validator rewards to withdraw"
fi

sleep 5

# withdraw delegator rewards
if [[ $(bc -l <<< "${DEL_REWARDS} > ${MIN_WITHDRAW}") -eq 1 ]]
  then
    echo "let's withdraw delegator rewards"
    echo -e "${PASS}\n" | ${APP_PATH} tx distribution withdraw-rewards ${VALOPER} --from ${DEL_ACCOUNT} --chain-id ${CHAIN_ID} --node ${NODE_URL} --fees ${TX_FEES} --yes
  else
    echo "no delegator rewards to withdraw"
fi

sleep 30

# check updated balance
VAL_BALANCE=$(${APP_PATH} query bank balances ${VAL_ADDRESS} --node ${NODE_URL} -oj | jq -r '.balances | .[].amount')
DEL_BALANCE=$(${APP_PATH} query bank balances ${DEL_ADDRESS} --node ${NODE_URL} -oj | jq -r '.balances | .[].amount')

VAL_BALANCE2=$(bc -l <<< "$VAL_BALANCE/1000000")
DEL_BALANCE2=$(bc -l <<< "$DEL_BALANCE/1000000")

echo "validator balance:" $VAL_BALANCE2
echo "delegator balance:" $DEL_BALANCE2

VAL_BALANCE_TO_STAKE=$(bc -l <<< "$VAL_BALANCE - $MIN_BALANCE")
DEL_BALANCE_TO_STAKE=$(bc -l <<< "$DEL_BALANCE - $MIN_BALANCE")

VAL_BALANCE_TO_STAKE2=$(bc -l <<< "$VAL_BALANCE_TO_STAKE/1000000")
DEL_BALANCE_TO_STAKE2=$(bc -l <<< "$DEL_BALANCE_TO_STAKE/1000000")

# stake from validator address
sleep 5
if [[ $(bc -l <<< "${VAL_BALANCE_TO_STAKE} > ${MIN_STAKE}") -eq 1 ]]
  then
    echo "staking $VAL_BALANCE_TO_STAKE regen from validator address"
    echo -e "${PASS}\n" | ${APP_PATH} tx staking delegate ${VALOPER} ${VAL_BALANCE_TO_STAKE}uregen --from ${VAL_ACCOUNT} --chain-id ${CHAIN_ID} --node ${NODE_URL} --fees ${TX_FEES} --yes
  else
    echo "nothing to stake from validator address"
fi

# stake from delegator address
sleep 5
if [[ $(bc -l <<< "${DEL_BALANCE_TO_STAKE} > ${MIN_STAKE}") -eq 1 ]]
  then
    echo "staking $DEL_BALANCE_TO_STAKE regen from delegator address"
    echo -e "${PASS}\n" | ${APP_PATH} tx staking delegate ${VALOPER} ${DEL_BALANCE_TO_STAKE}uregen --from ${DEL_ACCOUNT} --chain-id ${CHAIN_ID} --node ${NODE_URL} --fees ${TX_FEES} --yes
  else
    echo "nothing to stake from delegator address"
fi

echo "done"
