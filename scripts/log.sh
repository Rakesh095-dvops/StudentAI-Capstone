# centralized logging [Tested in local]
sudo apt install -y rsyslog

# Configure application logs to forward to syslog
cat > /etc/rsyslog.d/50-nodeapp.conf << 'EOF'
# NodeApp logs
$InputFileName /var/log/nodeapp/combined.log
$InputFileTag nodeapp:
$InputFileStateFile stat-nodeapp
$InputFileSeverity info
$InputRunFileMonitor

# Forward to remote syslog server (optional)
# *.* @@your-log-server:514
EOF

sudo systemctl restart rsyslog