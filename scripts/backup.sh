cat > /opt/nodeapp/backup.sh << 'EOF'
#!/bin/bash
# Backup script for Node.js application

BACKUP_DIR="/opt/backups/nodeapp"
DATE=$(date +%Y%m%d_%H%M%S)
APP_DIR="/opt/nodeapp"

mkdir -p $BACKUP_DIR

# Backup application files
tar -czf $BACKUP_DIR/app_$DATE.tar.gz -C $APP_DIR current
tar -czf $BACKUP_DIR/frontend_$DATE.tar.gz -C /var/www/nodeapp frontend

# Backup configuration files
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
    /etc/nginx/sites-available/nodeapp \
    /opt/nodeapp/ecosystem.config.js

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/nodeapp/backup.sh

# crontab for daily backups [Is this neccessary ???]
echo "0 2 * * * /opt/nodeapp/backup.sh" | sudo crontab -u deploy -