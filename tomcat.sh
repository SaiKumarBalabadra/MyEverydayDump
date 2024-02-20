#!/bin/bash

# Update and upgrade system
sudo apt-get update -y 

# Install Java -17
sudo apt-get install openjdk-17-jdk -y

# Download and extract Tomcat
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.18/bin/apache-tomcat-10.1.18.tar.gz

sudo tar xzf apache-tomcat-10.1.18.tar.gz -C /opt
sudo mv /opt/apache-tomcat-10.1.18 /opt/tomcat

# Add tomcat user
sudo useradd -r -U -d /opt/tomcat -s /bin/false tomcat

# Set ownership
sudo chown -R tomcat: /opt/tomcat 

# Set execute permission to scripts
sudo chmod +x /opt/tomcat/bin/*.sh

# Edit tomcat-users.xml
sudo tee /opt/tomcat/conf/tomcat-users.xml > /dev/null <<'EOF'
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
  <!-- user manager can access only the manager section -->
  <role rolename="manager-gui" />
  <user username="manager" password="manager" roles="manager-gui" />
 
  <!-- user admin can access manager and admin section both -->
  <role rolename="admin-gui" />
  <user username="admin" password="admin" roles="manager-gui,admin-gui" />
</tomcat-users>
EOF

# Edit context.xml for manager and host-manager
sudo sed -i 's/<Context>/<Context antiResourceLocking="false" privileged="true" >\n  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor" sameSiteCookies="strict" \/>/' /opt/tomcat/webapps/manager/META-INF/context.xml
sudo sed -i 's/<Context>/<Context antiResourceLocking="false" privileged="true" >\n  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor" sameSiteCookies="strict" \/>/' /opt/tomcat/webapps/host-manager/META-INF/context.xml

# Create systemd service file
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<'EOF'
[Unit]
Description=Apache Tomcat 10 Web Application Server
After=network.target
 
[Service]
Type=forking
 
User=tomcat
Group=tomcat
 
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
 
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
 
[Install]
WantedBy=multi-user.target
EOF


#port Change
sudo sed -i 's/port="8080"/port="8181"/' /opt/tomcat/conf/server.xml

# Reload systemd daemon
sudo systemctl daemon-reload 

# Start Tomcat
sudo systemctl start tomcat 

# Check status
sudo systemctl status tomcat 

# Enable Tomcat to start on boot
sudo systemctl enable tomcat 
