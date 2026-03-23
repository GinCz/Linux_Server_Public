#!/usr/bin/env bash
# Description: Ping benchmark for AWS regions to check network latency.
# Alias: awsping
R="ec2.eu-central-1.amazonaws.com ec2.us-east-1.amazonaws.com ec2.eu-north-1.amazonaws.com ec2.ap-northeast-1.amazonaws.com"; for h in $R; do echo -n "Ping $h: "; ping -c 3 -W 2 $h 2>/dev/null | awk -F'/' 'END{ print (/^rtt/ ? $5" ms" : "TIMEOUT") }'; done
