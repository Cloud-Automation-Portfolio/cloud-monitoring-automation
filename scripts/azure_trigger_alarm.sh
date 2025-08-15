#!/bin/bash
# Simulate high CPU load on Azure VM to trigger Azure Monitor alert

sudo apt-get update
sudo apt-get install stress -y
stress --cpu 2 --timeout 120
