#!/bin/bash
clear
# = Rooted by VladiMIR | AI =
# v2026-04-02
# Script: aws_test.sh
# Alias:  aws-test
# Location: /root/Linux_Server_Public/222/aws_test.sh

W="\e[36m"
Y="\e[93m"
G="\e[92m"
C="\e[96m"
X="\e[0m"
LINE="${W}$(printf '═%.0s' {1..50})${X}"

echo -e "$LINE"
echo -e "${Y}  AWS FREE TIER — LATENCY TEST${X}"
echo -e "${C}  Packet: 1450 bytes | Sequential${X}"
echo -e "$LINE"
echo

regions=(
  "Germany (Frankfurt)     ec2.eu-central-1.amazonaws.com"
  "Sweden (Stockholm)      ec2.eu-north-1.amazonaws.com"
  "Ireland (Dublin)        ec2.eu-west-1.amazonaws.com"
  "UK (London)             ec2.eu-west-2.amazonaws.com"
  "France (Paris)          ec2.eu-west-3.amazonaws.com"
  "USA East (N. Virginia)  ec2.us-east-1.amazonaws.com"
  "USA East (Ohio)         ec2.us-east-2.amazonaws.com"
  "USA West (Oregon)       ec2.us-west-2.amazonaws.com"
  "Canada (Central)        ec2.ca-central-1.amazonaws.com"
  "Japan (Tokyo)           ec2.ap-northeast-1.amazonaws.com"
  "South Korea (Seoul)     ec2.ap-northeast-2.amazonaws.com"
  "Singapore               ec2.ap-southeast-1.amazonaws.com"
  "India (Mumbai)          ec2.ap-south-1.amazonaws.com"
)

results=()
for entry in "${regions[@]}"; do
  name=$(echo "$entry" | sed 's/ ec2\..*//')
  host=$(echo "$entry" | awk '{print $NF}')
  printf "${C}  > Testing %-26s${X}" "$name..."
  output=$(ping -c 4 -s 1450 -W 2 "$host" 2>/dev/null)
  if [ $? -eq 0 ]; then
    avg=$(echo "$output" | grep -oP 'rtt min/avg/max/mdev = [\d.]+/\K[\d.]+')
    loss=$(echo "$output" | grep -oP '\d+(?=% packet loss)')
    results+=("$name|$avg|$loss")
    echo -e "${G}OK${X}"
  else
    results+=("$name|9999|100")
    echo -e "\e[31mTIMEOUT${X}"
  fi
done

sorted=$(printf '%s\n' "${results[@]}" | sort -t'|' -k2 -n)

clear
echo -e "$LINE"
echo -e "${Y}  AWS FREE TIER — FINAL REPORT${X}"
echo -e "$LINE"
printf "${Y}  %-26s %-12s %-6s${X}\n" "REGION" "AVG PING" "LOSS"
echo -e "$LINE"

while IFS='|' read -r country ping loss; do
  if [ "$ping" = "9999" ]; then
    echo -e "  \e[90m$(printf '%-26s %-12s %-6s%%' "$country" "TIMEOUT" "$loss")${X}"
  else
    int_ping=${ping%.*}
    if [ "$int_ping" -lt 50 ]; then
      col="$G"
    elif [ "$int_ping" -lt 150 ]; then
      col="$C"
    else
      col="\e[90m"
    fi
    echo -e "  ${col}$(printf '%-26s %-12s %-6s%%' "$country" "${ping} ms" "$loss")${X}"
  fi
done <<< "$sorted"

echo
echo -e "$LINE"
echo -e "${Y}  = Rooted by VladiMIR | AI =${X}"
echo -e "$LINE"
echo
read -p "  Press Enter to exit..."
