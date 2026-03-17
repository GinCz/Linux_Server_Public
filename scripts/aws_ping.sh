#!/usr/bin/env bash
# Script: aws_ping.sh
# Version: v2026-03-17
# Purpose: Check ping latency to selected AWS regional endpoints.
# What it does: sends 3 ICMP echo requests to predefined AWS EC2 endpoints
# and prints average latency or TIMEOUT for each region.
# Usage: aws_ping.sh
# Alias: awsping='sudo /opt/server_tools/scripts/aws_ping.sh'

R="ec2.eu-central-1.amazonaws.com ec2.us-east-1.amazonaws.com ec2.eu-north-1.amazonaws.com ec2.ap-northeast-1.amazonaws.com"; for h in $R; do echo -n "Ping $h: "; ping -c 3 -W 2 "$h" 2>/dev/null | awk -F'/' 'END{print (/^rtt/ ? $5" ms" : "TIMEOUT")}'; done
