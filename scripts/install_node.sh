# TEMPLATE FOR NEW NODE INSTALLATION:
# cd /root && [ -f .server_env ] && OLD_TAG=$(grep "SERVER_TAG" .server_env | cut -d'"' -f2); [ -z "$OLD_TAG" ] && DN=$(hostname) || DN="$OLD_TAG"; read -p "Enter Server Name [Default '$DN']: " UN; [ -z "$UN" ] && UN="$DN"; TGT="YOUR_TG_TOKEN"; TGC="YOUR_TG_CHAT_ID"; SP="YOUR_SMB_PASS"; apt update && apt install git curl -y && cat > /root/.server_env << EOC
# TG_TOKEN="$TGT"
# TG_CHAT_ID="$TGC"
# SERVER_TAG="$UN"
# SMB_PASS="$SP"
# EOC
# mkdir -p /root/.ssh && chmod 700 /root/.ssh && touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && rm -rf /root/scripts && git clone https://github.com/GinCz/Linux_Server_Public.git /root/scripts && cd /root/scripts && bash setup.sh && systemctl restart smbd
