#!/bin/bash

###### UPDATE APT-GET
sudo apt-get update

###### INSTALL AWS CLI & DOWNLOAD BLENDER FILE TO INSTANCE
sudo apt --yes install awscli

##############################################
## CONFIGURATION
##############################################

##############################################
## AWS BUCKET
AWS_BUCKET=map-blender

##############################################
## AWS BUCKET REGION (https://docs.aws.amazon.com/general/latest/gr/rande.html)
AWS_REGION=us-east-1

##############################################
## SETTING UP AWS CREDENTIALS
AWS_USER_ID=[aws_access_key_id]
AWS_SECRET_KEY=[aws_secret_access_key]
aws configure set default.aws_access_key_id $AWS_USER_ID   
aws configure set default.aws_secret_access_key $AWS_SECRET_KEY


##############################################
## BLENDER LINUX VERSION DL URL
BLENDER_DL_URL=https://mirror.clarkson.edu/blender/release/Blender2.81/blender-2.81a-linux-glibc217-x86_64.tar.bz2
BLENDER_FOLDER=blender-2.81a-linux-glibc217-x86_64


###### DOWNLOAD BLEND FILE AND ALL ASSTES  FOR RENDERERERRING
aws s3 cp s3://$AWS_BUCKET  /home/ubuntu/ --recursive 


##############################################
## Blender file inside of S3
## FIND THE BLEND FILE ON S3 TO RENDER - ASSUMES ONLY 1 !

BLENDER_FILENAME=`aws s3 ls $AWS_BUCKET/ | grep .blend | awk  '{print $4}' | sed 's/.blend//g'`
##############################################


###### DOWNLOAD BLENDER AND UNZIP THAT SHIT
curl -o blender.tar.bz2 $BLENDER_DL_URL
tar xvjf blender.tar.bz2
sudo apt-get --yes install libglu1 libxi6 libgconf-2-4 libfontconfig1 libxrender1

###### INSTALL S3FS
sudo apt-get --yes install build-essential libxml2-dev libfuse-dev libcurl4-openssl-dev libssl-dev pkg-config autotools-dev automake
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse
./autogen.sh
./configure
make
sudo make install

###### SETUP S3FS
AWS_USER_ID=$AWS_USER_ID AWS_SECRET_KEY=$AWS_SECRET_KEY runuser ubuntu -c 'echo $AWS_USER_ID:$AWS_SECRET_KEY > /home/ubuntu/.passwd-s3fs'
runuser ubuntu -c 'chmod 600 /home/ubuntu/.passwd-s3fs'
runuser ubuntu -c 'mkdir /home/ubuntu/blenderrender'
runuser ubuntu -c 'chmod 777 /home/ubuntu/blenderrender'
AWS_BUCKET=$AWS_BUCKET runuser ubuntu -c 's3fs $AWS_BUCKET /home/ubuntu/blenderrender -o passwd_file=/home/ubuntu/.passwd-s3fs'

# EVERY 8 MINUTES, DELETE RENDERS THAT ARE 0 BYTES AND OVER 10 MINUTES OLD (This cleans up ghost instances)
crontab -l | { cat; echo "*/8 * * * * find /home/ubuntu/blenderrender/renders/$BLENDER_FILENAME/frames -name '*' -size 0 -mmin +10 -print0 | xargs -0 rm"; } | crontab -

###### RUN BLENDER AND RENDER 
## -s 0 -e 20 for specific frames
BLENDER_FOLDER=$BLENDER_FOLDER BLENDER_FILENAME=$BLENDER_FILENAME runuser ubuntu -c '/$BLENDER_FOLDER/blender -b /home/ubuntu/$BLENDER_FILENAME.blend -o /home/ubuntu/blenderrender/renders/$BLENDER_FILENAME/frames/##### -E CYCLES -a'

###### TERMINATE INSTANCE 
sudo shutdown now
