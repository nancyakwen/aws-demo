#!/bin/bash
set -eo pipefail

# create an initial bucket
BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
BUCKET_NAME=lambda-artifacts-$BUCKET_ID
echo $BUCKET_NAME > bucket-name.txt
aws s3 mb s3://$BUCKET_NAME

# create db password
DB_PASSWORD=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
aws secretsmanager create-secret --name rds-mysql-admin --description "database password" --secret-string "{\"username\":\"admin\",\"password\":\"$DB_PASSWORD\"}"

# deploy the stack
ARTIFACT_BUCKET=$(cat bucket-name.txt)
STACK=rds-mysql
if [[ $# -eq 1 ]] ; then
    STACK=$1
    echo "Deploying to stack $STACK"
fi
cd lib/nodejs && npm install && cd ../../
aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name $STACK --capabilities CAPABILITY_NAMED_IAM

# attach to different VPC
#aws cloudformation deploy --template-file out.yml --stack-name $STACK --capabilities CAPABILITY_NAMED_IAM --parameter-overrides vpcStackName=lambda-vpc secretName=lambda-db-password

# examples
echo "invoking examples"
FUNCTION=$(aws cloudformation describe-stack-resource --stack-name rds-mysql --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)

# create table
aws lambda invoke --function-name $FUNCTION --payload file://events/db-create-table.json out.json

# invoke once
aws lambda invoke --function-name $FUNCTION --payload file://events/db-read-table.json out.json
cat out.json

# 