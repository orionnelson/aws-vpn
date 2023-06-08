## Q: What is this aws-vpn?
- This repo is for making an ipv4 vpn with terraform and aws

# Running Instructions

- Fill out the aws.env.template 
- cd wireguard_vpn 
- Create an key pair named terraform-vpn-key and drop the pem in the wireguard_vpn folder
- Run the workflow with `bash  ./build/aws.sh` then a to apply the terraform config
- Install the wireguard gui `windows` and load the generated client_config.conf
- To decompose run the bash  ./build/aws.sh then enter d.  Removing artifacts.


## How do I use this vpn

- Fast ipv4 vpn to the states to experiment with google bard. 
- ipv4 vpn for webscraping stuff. 
