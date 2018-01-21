#!/usr/bin/sh

set -e

SERVICE_NAME="kj-profileCI-kj-profile-service"
TASK_FAMILY="kj-profileCI-kj-profile-task"

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

TASK_REVISION=`aws ecs describe-task-definition --task-definition $TASK_FAMILY | egrep "revision" | tr "/" " " | awk '{print $2}' | sed 's/"$//'`
DESIRED_COUNT=`aws ecs describe-services --services ${SERVICE_NAME} | egrep "desiredCount" | tr "/" " " | awk '{print $2}' | sed 's/,$//'`
if [ ${DESIRED_COUNT} = "0" ]; then
    DESIRED_COUNT="1"
fi

aws ecs update-service --cluster default --service $SERVICE_NAME --task-definition $TASK_FAMILY:$TASK_REVISION --desired-count $DESIRED_COUNT