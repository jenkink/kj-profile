#!/bin/bash

set -e
#export AWS_DEFAULT_PROFILE="kj"
if [ ! $1 ]; then
  echo "Usage: $(basename $0) CF_TEMPLATE_DIR "
  echo ""
  echo "        CF_TEMPLATE_DIR - The directory where the cloudformation template lives."
  echo ""
  exit 1
fi

CF_TEMPLATE_DIR=$1
CREATE_TYPE=""
DOCKER_REPO=""
REGION="us-east-1"
TEMPLATE="cloudformation/$CF_TEMPLATE_DIR/compute/$CF_TEMPLATE_DIR.json"
REVISION=$(echo $GIT_COMMIT|awk '{print substr($0,0,7)}')
PARAMSFILE="cloudformation/$CF_TEMPLATE_DIR/compute/params.json"

function build_docker_image(){
  echo "BUILDING DOCKER"
  #docker login
  $(aws ecr get-login --region us-east-1 --no-include-email)

  DOCKER_REPO="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO:$REVISION"

  echo $DOCKER_REPO
  echo "Building image..."
  docker build -t $DOCKER_REPO .
  echo "Pushing image"
  docker push $DOCKER_REPO
}
function s3_copy(){
  echo "Putting templates in s3"
  aws s3 cp cloudformation/$CF_TEMPLATE_DIR/ s3://$CF_TEMPLATE_DIR/cf-templates/ --recursive
  aws s3 cp cloudformation/puppet/ s3://$CF_TEMPLATE_DIR/cf-templates/ --recursive
  sleep 10 #wait for files to propagate
  echo "pulling down params file"
  aws s3 cp s3://$CF_TEMPLATE_DIR/cf-templates/compute/params_$CF_TEMPLATE_DIR.json $PARAMSFILE

  echo $DOCKER_REPO
  jq -e -r --arg  DOCKER_REPO "$DOCKER_REPO" 'map ((select(.ParameterKey=="DockerImageURL") | .ParameterValue) |= $DOCKER_REPO)' \
  "$PARAMSFILE" > "cloudformation/$CF_TEMPLATE_DIR/compute/temp.json" && mv "cloudformation/$CF_TEMPLATE_DIR/compute/temp.json" "$PARAMSFILE"
   
}
#find out if our stack has already been created
function check_stack(){
    stackid=(aws cloudformation describe-stacks --stack-name $CF_TEMPLATE_DIR --region $REGION --query Stacks[].StackId)
    if "${stackid[@]}" > /tmp/out.txt 2> /tmp/describe-error.txt; then
      #stack exists
      CREATE_TYPE="UPDATE"
    else
      #no existing stack
      CREATE_TYPE="CREATE"
    fi
}
function create_stack(){
  echo "Stack $CF_TEMPLATE_DIR not found...creating"
  aws cloudformation create-stack --stack-name $CF_TEMPLATE_DIR --template-body file://$TEMPLATE --capabilities CAPABILITY_IAM \
    --parameters file://cloudformation/$CF_TEMPLATE_DIR/compute/params.json

  aws cloudformation wait stack-create-complete --stack-name $CF_TEMPLATE_DIR --region $REGION
  echo "Stack Update has completed."
}
function update_stack(){
  echo "Updating $CF_TEMPLATE_DIR..."
  aws cloudformation update-stack --stack-name $CF_TEMPLATE_DIR --template-body file://$TEMPLATE --capabilities CAPABILITY_IAM \
    --parameters file://cloudformation/$CF_TEMPLATE_DIR/compute/params.json

  echo "updating stack"
  aws cloudformation wait stack-update-complete --stack-name $CF_TEMPLATE_DIR --region $REGION
  echo "Stack Update has completed."
}
function main(){
  build_docker_image
  s3_copy
  check_stack

  if [ $CREATE_TYPE == "CREATE" ]; then 
    create_stack
  else
    update_stack
  fi
}

main
