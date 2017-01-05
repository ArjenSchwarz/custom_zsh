#!/usr/bin/env zsh
function cfnstacks() {
  aws cloudformation describe-stacks --query 'Stacks[*].[StackName,StackStatus]' --output table
}

function cfnresources() {
  aws cloudformation describe-stack-resources --stack-name ${1} --query 'StackResources[*].[ResourceType,ResourceStatus,PhysicalResourceId]' --output table
}

function cfnoutputs() {
  aws cloudformation describe-stacks --stack-name ${1} --query 'Stacks[*].[Outputs]' --output table
}

compdef _rcfn cfnresources
compdef _rcfn cfnoutputs

compdef _insts ec2ip
compdef _insts ussh
compdef _insts essh

# Find the autocompletion list
_rcfn_get_list() {
    DIRS=("${(@f)$(aws cloudformation describe-stacks --query 'Stacks[*].[StackName]' --output text)}")
    print -C 1 $DIRS | awk '{gsub(/\/.*\//,"",$1); print}'
}

# Add the autocompletion list to the autocompleter
_rcfn() {
   compadd `_rcfn_get_list`
}

# Find the autocompletion list
_insts_get_list() {
    DIRS=("${(@f)$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --output text)}")
    print -C 1 $DIRS | awk '{gsub(/\/.*\//,"",$1); print}'
}

# Add the autocompletion list to the autocompleter
_insts() {
   compadd `_insts_get_list`
}

function instancenames() {
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].{name:Tags[?Key==`Name`].Value,id:InstanceId,state:State.Name}' --output table
}

function instances() {
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].{id:InstanceId,state:State.Name}' --output table
}

function ec2ip() {
  ip=$(aws ec2 describe-instances --instance-id ${1} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
  echo ${ip} | pbcopy
  echo ${ip}
}

function ussh() {
  ip=`ec2ip ${1}`
  ssh ubuntu@${ip}
}

function essh() {
  ip=`ec2ip ${1}`
  ssh ec2-user@${ip}
}

function caws() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_DEFAULT_REGION
  unset AWS_REGION
  unset AWS_SESSION_TOKEN
  unset AWS_SECURITY_TOKEN
  unset AWS_DEFAULT_PROFILE
}
