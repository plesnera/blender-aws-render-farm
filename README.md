# Blender AWS Render Farm

## Simple instructions and a couple scripts to set up a AWS EC2/S3 Blender Render Farm.

This project was forked from https://github.com/wonderunit/blender-aws-render-farm.
It has been slightly modified to simplify things a bit and handle texture assets.
It assumes an s3 bucket with 1 (and only) .blender file and any texture assets used.
Be sure to save your blender file with the relative file paths as described below in the steps.  

The benefits of rendering through AWS is that it is nearly infinitely scalable and the rates are better than any render farm I've seen.

![image](https://user-images.githubusercontent.com/441117/71633838-d425b400-2be4-11ea-935f-03eb607695db.png)

# How it works

You create a spot instance fleet that runs a configured script that downloads all the stuff needed to render. It automatically gets the latest .blend file on the S3 bucket and starts rendering it. The rendered frames are automatically saved to S3 so if an instance stops, it doesn't matter, you still have the frames! Also in your blender file, you have to set the render outputs to: [ ] Overwrite AND [X] Use Placeholders. This means that other instances will know when instances are rendering and it will not overwrite other frames. When it's done, the instances will shut themselves down, and you can run the cleanup script to generate a zip file and download it.

There's another project called Brenda https://github.com/gwhobbs/brenda which is a way more complicated but customizable version of this. It appears to be abandoned by the orginal author. I wanted to make something that was super simple at its core: 1 bash script. If something stops working, it's easy to figure out!

# Setting up AWS Account

* Create a bucket 
* Create service account (limit scope to only read the S3 bucket) in IAM - insert the access_key_id and secret_key in the userdata for the launch template.
It can easily be improved and made more secure using secrets in parameter store and KMS - so feel free to do so.  
* Create a Launch Template with the userdata.bash as 'userdata' in the launch template:
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html?icmpid=docs_ec2_console


# Preparing your Blend File
* Collect all your assets and blender file in a single directory and ensure that relative paths in blender is selected when saving: https://docs.blender.org/manual/en/2.79/data_system/files/relative_paths.html

This ensures that your project is easily portable to a flat directory structure in S3 for use in your render farm.

# Starting an instance fleet
EC2 -> Spot Requests in the console let's you launch a fleet easily guided. 

# Checking it 

Terminal or S3

# Cleaning up
Make sure your cleanup instance has enough EBS to store the frames and the zip!


# MAKE SURE YOUR INSTANCES ARE STOPPED WHEN YOU ARE DONE!
This is handled by default by the userdata script but better safe than sorry ....

If you don't cancel, you could get a bill for a lot!
