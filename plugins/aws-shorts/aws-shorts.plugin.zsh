#!/usr/bin/env zsh
## CloudFormation related
function cfnstacks() {
  aws cloudformation describe-stacks --query 'Stacks[*].[StackName,StackStatus]' --output table
}

function cfnresources() {
  aws cloudformation describe-stack-resources --stack-name ${1} --query 'StackResources[*].[ResourceType,ResourceStatus,PhysicalResourceId]' --output table
}

function cfnoutputs() {
  aws cloudformation describe-stacks --stack-name ${1} --query 'Stacks[*].[Outputs]' --output table
}

function cfnparams() {
  aws cloudformation describe-stacks --stack-name ${1} --query 'Stacks[0].Parameters' --output json
}

function whichcfn() {
  aws cloudformation describe-stack-resources --physical-resource-id ${1}
}

compdef _rcfn cfnresources cfnoutputs cfnparams

# Find the autocompletion list
_rcfn_get_list() {
    DIRS=("${(@f)$(aws cloudformation describe-stacks --query 'Stacks[*].[StackName]' --output text)}")
    print -C 1 $DIRS | awk '{gsub(/\/.*\//,"",$1); print}'
}

# Add the autocompletion list to the autocompleter
_rcfn() {
   compadd `_rcfn_get_list`
}

## Network related
function getaclentries() {
  aws ec2 describe-network-acls --filters Name=network-acl-id,Values=${1} --query 'NetworkAcls[0].Entries'
}

function getroutes() {
  aws ec2 describe-route-tables --filters Name=route-table-id,Values=${1} --query 'RouteTables[0].Routes'
}

function vpcbyname() {
  aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${1}" --query 'Vpcs[0].VpcId' --output text
}

## EC2 related
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

compdef _insts ec2ip ussh essh

# Find the autocompletion list
_insts_get_list() {
    DIRS=("${(@f)$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --output text)}")
    print -C 1 $DIRS | awk '{gsub(/\/.*\//,"",$1); print}'
}

# Add the autocompletion list to the autocompleter
_insts() {
   compadd `_insts_get_list`
}

## Container related

# Log into EKS cluster
function ekslogin() {
  aws eks update-kubeconfig --name ${1}
}

compdef _eksclusters ekslogin

# Find the autocompletion list
_eksclusters_get_list() {
    DIRS=("${(@f)$(aws eks list-clusters --query 'clusters[*]' --output text)}")
    print -C 1 $DIRS | awk '{gsub(/\/.*\//,"",$1); print}'
}

# Add the autocompletion list to the autocompleter
_eksclusters() {
   compadd `_eksclusters_get_list`
}

## Login/access related

## Clear all exported AWS settings
function caws() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_DEFAULT_REGION
  unset AWS_REGION
  unset AWS_SESSION_TOKEN
  unset AWS_SECURITY_TOKEN
  unset AWS_DEFAULT_PROFILE
  unset AWS_PROFILE
  unset AWS_EB_PROFILE
}

function awsregion() {
  export AWS_DEFAULT_REGION=$1; export AWS_REGION=$1
}

function awsus() {
  awsregion us-east-1
}

function awsau() {
  awsregion ap-southeast-2
}

function awsaccount() {
  aws iam list-account-aliases --query 'AccountAliases[0]' --output text
}

function getmfa() {
  aws iam list-mfa-devices --query 'MFADevices[0].SerialNumber' --output text
}

function getsts() {
  mfa=$(getmfa)
  code=${1}
  token=$(aws sts get-session-token --serial-number $mfa --token-code ${code})
  export AWS_ACCESS_KEY_ID=$(echo $token | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo $token | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo $token | jq -r '.Credentials.SessionToken')
}

function awslogin() {
  aws sso login --profile $1
}

## Exports keys for the currently set SSO profile
function awsexportcurrent() {
  sso_start_url=$(aws configure get sso_start_url --profile $AWS_PROFILE)
  sso_role_name=$(aws configure get sso_role_name --profile $AWS_PROFILE)
  sso_account_id=$(aws configure get sso_account_id --profile $AWS_PROFILE)
  sso_region=$(aws configure get sso_region --profile $AWS_PROFILE)
  # find token in cache
  token_cache_file=$(grep -l \"$sso_start_url\" ~/.aws/sso/cache/*)
  if [[ -z "$token_cache_file" ]]; then
    # need to login
    echo "you need to aws sso login first"
    return 1
  else
    access_token=$(jq -r '.accessToken' < $token_cache_file)
  fi
  creds=$(aws sso get-role-credentials \
    --profile $AWS_PROFILE \
    --role-name $sso_role_name \
    --account-id $sso_account_id \
    --region $sso_region \
    --access-token $access_token)
  export AWS_ACCESS_KEY_ID=$(jq -r '.roleCredentials.accessKeyId' <<< $creds)
  export AWS_SECRET_ACCESS_KEY=$(jq -r '.roleCredentials.secretAccessKey' <<< $creds)
  export AWS_SESSION_TOKEN=$(jq -r '.roleCredentials.sessionToken' <<< $creds)
}

compdef _regions awsregion

# Find the autocompletion list for regions
_regions_get_list() {
    DIRS=("${(@f)$(aws ec2 describe-regions --query 'Regions[*].[RegionName]' --output text)}")
    print -C 1 $DIRS | awk '{gsub(/\/.*\//,"",$1); print}'
}

# Add the region autocompletion list to the autocompleter
_regions() {
   compadd `_regions_get_list`
}

## Copied into the theme
function awsLoginDetails() {
  [[ -z $AWS_ACCESS_KEY_ID ]] || [[ -z $AWS_SECRET_ACCESS_KEY ]] && [[ -z $AWS_PROFILE ]] && return ""
  AWS_IDENTIFIER=$AWS_ACCESS_KEY_ID
  if [[ ! -z $AWS_PROFILE ]]; then
    AWS_IDENTIFIER=$AWS_PROFILE
  fi
  if [[ -a "$HOME/.aws/accounts/$AWS_IDENTIFIER" ]]; then
    # nothing
  else
    if [[ -z $AWS_PROFILE ]]; then
      user=$(aws sts get-caller-identity --query "Arn" --output text | cut -f 2 -d "/")
      if [[ $user == 'AWSReservedSSO'* ]]; then
        user=$(echo $user | cut -f 2 -d "_")
      fi
    else
      user=$(aws configure get profile.$AWS_PROFILE.sso_role_name)
    fi
    account=$(aws iam list-account-aliases --query 'AccountAliases[0]' --output text)
    mkdir -p $HOME/.aws/accounts
    echo "${user}@${account}" > $HOME/.aws/accounts/$AWS_IDENTIFIER
    echo "Added account cache"
  fi
  account=$(cat $HOME/.aws/accounts/$AWS_IDENTIFIER)
  if [[ -n $AWS_REGION ]]; then
    account="${account}:${AWS_REGION}"
  fi
}