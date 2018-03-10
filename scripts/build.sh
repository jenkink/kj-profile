#!/usr/bin/sh

set -e

if [ ! $1 ]; then
  echo "Usage: $(basename $0) CF_TEMPLATE_DIR "
  echo
  echo "        BUILD_TYPE - (CREATE_CHANGE_SET, EXECUTE_CHANGE_SET, DELETE_CHANGE_SET)"
  echo "        CF_TEMPLATE_DIR - The directory where the cloudformation template lives."
  echo "        ENV - The environment that this build is for."
  echo ""
  exit 1
fi

#BUILD_TYPE=$1
CF_TEMPLATE_DIR=$1
#ENV=$3

TEMPLATE="cloudformation/$CF_TEMPLATE_DIR/compute/$CF_TEMPLATE_DIR.json"
echo $TEMPLATE
REVISION=$(echo $GIT_COMMIT|awk '{print substr($0,0,7)}')

#docker login
$(aws ecr get-login --region us-east-1 --no-include-email)

DOCKER_REPO="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO:$REVISION"

echo $DOCKER_REPO
echo "Building image..."
docker build -t $DOCKER_REPO .
echo "Pushing image"
docker push $DOCKER_REPO
echo "putting templates in s3"
aws s3 cp cloudformation/$CF_TEMPLATE_DIR/ s3://$CF_TEMPLATE_DIR/cf-templates/ --recursive
aws s3 cp cloudformation/puppet/ s3://$CF_TEMPLATE_DIR/cf-templates/ --recursive
echo "pulling down params file"
aws s3 cp s3://$CF_TEMPLATE_DIR/cf-templates/compute/params_$STACK_NAME.json cloudformation/$CF_TEMPLATE_DIR/compute/params.json
echo "Updating CFN"
aws cloudformation update-stack --stack-name $STACK_NAME --template-body file://$TEMPLATE --capabilities CAPABILITY_IAM \
  --parameters file://cloudformation/$CF_TEMPLATE_DIR/computeparams.json

