#!/bin/bash
# Simulate high CPU load on AWS EC2 to trigger CloudWatch alarm

sudo amazon-linux-extras install epel -y
sudo yum install stress -y
stress --cpu 2 --timeout 120
