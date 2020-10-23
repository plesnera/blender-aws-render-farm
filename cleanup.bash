#!/bin/bash

##############################################
## CLEAN UP BASH SCRIPT
## All this script does is:
## 1) download all rendered frames,
## 2) zip them up
## 3) upload them to s3 so you can just DL one file.
##
## You can copy / paste run this on tiny instance.
## Make sure to edit the config below.
##
##                      - <3 Charles
##                       \\ WONDER UNIT
##############################################

###### UPDATE APT-GET
sudo apt-get update

###### INSTALL AWS CLI & DOWNLOAD BLENDER FILE TO INSTANCE
sudo apt --yes install awscli zip unzip


##############################################
##############################################
## CONFIGURATION
AWS_USER_ID=[aws_access_key_id]
AWS_SECRET_KEY=[aws_secret_access_key]
aws configure set default.aws_access_key_id $AWS_USER_ID
aws configure set default.aws_secret_access_key $AWS_SECRET_KEY
##############################################
##############################################

## AWS BUCKET
AWS_BUCKET=map-blender

##############################################

## AWS BUCKET REGION (https://docs.aws.amazon.com/general/latest/gr/rande.html)
AWS_REGION=us-east-1

##############################################

## GET THE LATEST BLEND FILE ON S3 TO RENDER
BLENDER_FILENAME=`aws s3 ls $AWS_BUCKET/ | grep .blend | awk  '{print $4}' | sed 's/.blend//g'`
## OPTIONAL: USE A SPECIFIC BLEND NAME _____.blend
# BLENDER_FILENAME=slater

##############################################

mkdir /home/ubuntu/frames
aws s3 sync s3://$AWS_BUCKET/renders/$BLENDER_FILENAME/frames /home/ubuntu/frames --region $AWS_REGION
zip -r -0 /home/ubuntu/frames.zip /home/ubuntu/frames
aws s3 cp /home/ubuntu/frames.zip s3://$AWS_BUCKET/renders/$BLENDER_FILENAME/ --region $AWS_REGION

sudo shutdown now
