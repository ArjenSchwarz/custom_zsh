#!/usr/bin/env zsh
# Convenience functions for blog actions

# Upload image to S3 and put the Markdown'd URL in the clipboard
ignoreimage() {
  aws s3api put-object --bucket assets2.nore.me --key posts/$1 --body $1 --profile blogs;
  echo "![alttext](http://assets2.nore.me/posts/$1)" | pbcopy;
}

# Just give me the Markdown'd URL in the clipboard
blogimg() {
  echo "![alttext](/img/posts/$1)" | pbcopy;
}

# # Update the cloudformation stack with the default values
# blogcf() {
#   echo "Updating blog cloudformation with default values"
#   cd ~/projects/server_personal; aws cloudformation update-stack --stack-name blog-server --template-body file://cloudformation-generated.json --profile blogs
# }

# # Update the cloudformation stack with my current external IP address
# blogcfssh() {
#   externalip=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
#   echo "Current IP is: ${externalip}\n"
#   echo "Updating blog cloudformation template with current IP address"
#   cd ~/projects/server_personal; aws cloudformation update-stack --stack-name blog-server --template-body file://cloudformation-generated.json --parameters ParameterKey=SshIp,ParameterValue=${externalip}/32 --profile blogs
# }

# Compile the cloudformation template from the DSL
blogcfdsl() {
  echo "Compiling blog cloudformation DSL into JSON"
  cd ~/projects/server_personal; cfndsl Cloudformation-template.rb | json_pp > cloudformation-generated.json
}

# Update access for my servers
cfnip() {
  externalip=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
  echo "Current IP is: ${externalip}\n"
  echo "Updating Personal Access template with current IP address"
  aws cloudformation update-stack --stack-name cron-vpc --use-previous-template --parameters ParameterKey=AccessIP,ParameterValue=${externalip}/32 --profile arjen
}

cronssh() {
  ip=`aws ec2 describe-instances --instance-id i-ce5d016e --profile arjen --query 'Reservations[0].Instances[0].PublicIpAddress' --output text`
  ssh -i ~/.ssh/keys/arjen-admin-us-east.pem ubuntu@${ip}
}
