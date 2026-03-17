#!/usr/bin/env bash

# AWS Region Test Script
# Version: v2026-03-17
# Purpose:
#   Measure which AWS EC2 region is most responsive from the current server or VPN.
# Method:
#   - DNS resolve for official regional EC2 endpoints
#   - TCP connect test to port 443
#   - Sorted report by fastest successful connection
# Notes:
#   - This is more reliable than ICMP ping for AWS region selection
#   - Script is safe: read-only network checks, no system changes

set -u

REGIONS=(
"eu-central-1|Germany (Frankfurt)|ec2.eu-central-1.amazonaws.com"
"eu-north-1|Sweden (Stockholm)|ec2.eu-north-1.amazonaws.com"
"eu-west-1|Ireland (Dublin)|ec2.eu-west-1.amazonaws.com"
"eu-west-2|UK (London)|ec2.eu-west-2.amazonaws.com"
"eu-west-3|France (Paris)|ec2.eu-west-3.amazonaws.com"
"eu-south-1|Italy (Milan)|ec2.eu-south-1.amazonaws.com"
"eu-south-2|Spain (Madrid)|ec2.eu-south-2.amazonaws.com"
"eu-central-2|Switzerland (Zurich)|ec2.eu-central-2.amazonaws.com"
"us-east-1|USA East (N. Virginia)|ec2.us-east-1.amazonaws.com"
"us-east-2|USA East (Ohio)|ec2.us-east-2.amazonaws.com"
"us-west-1|USA West (N. California)|ec2.us-west-1.amazonaws.com"
"us-west-2|USA West (Oregon)|ec2.us-west-2.amazonaws.com"
"ca-central-1|Canada (Central)|ec2.ca-central-1.amazonaws.com"
"ap-northeast-1|Japan (Tokyo)|ec2.ap-northeast-1.amazonaws.com"
"ap-northeast-2|South Korea (Seoul)|ec2.ap-northeast-2.amazonaws.com"
"ap-northeast-3|Japan (Osaka)|ec2.ap-northeast-3.amazonaws.com"
"ap-southeast-1|Singapore|ec2.ap-southeast-1.amazonaws.com"
"ap-southeast-2|Australia (Sydney)|ec2.ap-southeast-2.amazonaws.com"
"ap-south-1|India (Mumbai)|ec2.ap-south-1.amazonaws.com"
"me-central-1|UAE|ec2.me-central-1.amazonaws.com"
"sa-east-1|Brazil (Sao Paulo)|ec2.sa-east-1.amazonaws.com"
)

TIMEOUT_SEC=3
TMP_RAW="/tmp/aws_region_test_raw_v2026-03-17.txt"

command -v getent >/dev/null 2>&1 || { echo "ERROR: getent not found"; exit 1; }
command -v timeout >/dev/null 2>&1 || { echo "ERROR: timeout not found"; exit 1; }
command -v date >/dev/null 2>&1 || { echo "ERROR: date not found"; exit 1; }

printf "%s\n" "==============================================================="
printf "%s\n" " AWS REGION TEST v2026-03-17"
printf "%s\n" " Method: DNS resolve + TCP connect to 443"
printf "%s\n" "==============================================================="
printf "\n"

: > "$TMP_RAW"

for ITEM in "${REGIONS[@]}"; do
  IFS='|' read -r REGION LABEL HOST <<< "$ITEM"

  printf "> Testing %-24s " "$LABEL"

  IP="$(getent ahostsv4 "$HOST" 2>/dev/null | awk '{print $1}' | sort -u | head -n1)"
  if [ -z "$IP" ]; then
    printf "%s\n" "DNS_FAIL"
    printf "999999|%s|%s|%s|DNS_FAIL|DNS_FAIL\n" "$REGION" "$LABEL" "-" >> "$TMP_RAW"
    continue
  fi

  START_MS="$(date +%s%3N 2>/dev/null)"
  if [ -z "$START_MS" ]; then
    START_MS=$(( $(date +%s) * 1000 ))
  fi

  timeout "$TIMEOUT_SEC" bash -c "exec 3<>/dev/tcp/$HOST/443" >/dev/null 2>&1
  RC=$?

  END_MS="$(date +%s%3N 2>/dev/null)"
  if [ -z "$END_MS" ]; then
    END_MS=$(( $(date +%s) * 1000 ))
  fi

  ELAPSED=$((END_MS - START_MS))
  [ "$ELAPSED" -lt 0 ] && ELAPSED=0

  if [ "$RC" -eq 0 ]; then
    printf "%s ms\n" "$ELAPSED"
    printf "%06d|%s|%s|%s|OK|%s ms\n" "$ELAPSED" "$REGION" "$LABEL" "$IP" "$ELAPSED" >> "$TMP_RAW"
  elif [ "$RC" -eq 124 ]; then
    printf "%s\n" "TIMEOUT"
    printf "999998|%s|%s|%s|TIMEOUT|TIMEOUT\n" "$REGION" "$LABEL" "$IP" >> "$TMP_RAW"
  else
    printf "%s\n" "TCP_FAIL"
    printf "999997|%s|%s|%s|TCP_FAIL|TCP_FAIL\n" "$REGION" "$LABEL" "$IP" >> "$TMP_RAW"
  fi
done

printf "\n"
printf "%s\n" "==============================================================="
printf "%s\n" " FINAL REPORT"
printf "%s\n" "==============================================================="
printf "%-16s | %-24s | %-15s | %-8s | %-10s\n" "REGION" "LOCATION" "IP" "STATUS" "CONNECT"
printf "%s\n" "-----------------------------------------------------------------------------------------------"

sort -n "$TMP_RAW" | while IFS='|' read -r SORTKEY REGION LABEL IP STATUS CONNECT; do
  printf "%-16s | %-24s | %-15s | %-8s | %-10s\n" "$REGION" "$LABEL" "$IP" "$STATUS" "$CONNECT"
done

printf "\n"
printf "%s\n" "Top 5 best regions:"
sort -n "$TMP_RAW" | awk -F'|' '$5=="OK"{printf " - %s (%s): %s\n",$3,$2,$6}' | head -n5

printf "\n"
printf "%s\n" "Done."
