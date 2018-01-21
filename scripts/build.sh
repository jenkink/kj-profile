#!/usr/bin/sh

set -e

REVISION=$(echo $GIT_COMMIT|awk '{print substr($0,0,7)}')

#docker login
$(aws ecr get-login --region us-east-1 --no-include-email)

DOCKER_REPO="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO:$REVISION"

echo $DOCKER_REPO
echo "Building image..."
docker build -t $DOCKER_REPO .
echo "Pushing image"
docker push $DOCKER_REPO
echo "Updating CFN"
aws cloudformation update-stack --stack-name $STACK_NAME --use-previous-template --capabilities CAPABILITY_IAM \
  --parameters ParameterKey=DockerImageURL,ParameterValue=$DOCKER_REPO \
  ParameterKey=DesiredCapacity,UsePreviousValue=true \
  ParameterKey=InstanceType,UsePreviousValue=true \
  ParameterKey=MaxSize,UsePreviousValue=true \
  ParameterKey=SubnetIDs,UsePreviousValue=true \
  ParameterKey=VpcId,UsePreviousValue=true
