## Q: What is this template?

This template is for autoinstalling terraform and aws cli on windows within a workflow. The way that the workflow works is a python venv is created and everything is built off of the python venv. 
Meaning you do not permanently install either on your system. 

## Why did you make this?
I made this template to both imporove my skill in shell and because I needed a way to run terraform without having it system installed.
This means you can run terraform from any machine only having python and venv package installed.

## How do I use this template.

Fill out your aws.env file using the aws.env.template with your aws credentials then fill it out.
Write your terraform code in the workflow then run build/aws.sh 
