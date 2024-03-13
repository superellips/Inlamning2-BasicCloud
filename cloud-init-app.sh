#!/bin/bash

app_name="GithubActionsDemo"
app_port=5000

# Install microsoft package repo and runtime
package_name="packages-microsoft-prod.deb"

distro_version=$(
if command -v lsb_release &> /dev/null; then
    lsb_release -r -s;
else
    grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"';
fi
)

wget https://packages.microsoft.com/config/ubuntu/$distro_version/$package_name -O $package_name

sudo dpkg -i $package_name

rm $package_name

apt-get update -y && apt-get install -y aspnetcore-runtime-8.0

# Write unit file
cat << EOF > /etc/systemd/system/$app_name.service
[Unit]
Description=Erikas shiny new web application

[Service]
WorkingDirectory=/opt/$app_name
ExecStart=/usr/bin/dotnet /opt/$app_name/$app_name.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=$app_name
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_NOLOGO=true
Environment=ASPNETCORE_URLS="http://*:$app_port"

[Install]
WantedBy=multi-user.target
EOF

# Reload daemon thing
systemctl daemon-reload
systemctl enable $app_name.service

# Add self-hosted runner

mkdir /home/azureuser/actions-runner; cd /home/azureuser/actions-runner
curl -o actions-runner-linux-x64-2.314.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.314.1/actions-runner-linux-x64-2.314.1.tar.gz
tar xzf ./actions-runner-linux-x64-2.314.1.tar.gz
chown -R azureuser:azureuser ../actions-runner
sudo -u azureuser ./config.sh --unattended --url https://github.com/superellips/$app_name --token $token
./svc.sh install azureuser
./svc.sh start
