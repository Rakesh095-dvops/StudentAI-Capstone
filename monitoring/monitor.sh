#!/bin/bash
# Simple monitoring script

APP_NAME="nodeapp"
HEALTH_URL="http://localhost/health"
LOG_FILE="/var/log/nodeapp/monitor.log"

check_service() {
    local service=$1
    if systemctl is-active --quiet $service; then
        echo "$(date): $service is running" >> $LOG_FILE
        return 0
    else
        echo "$(date): $service is not running" >> $LOG_FILE
        return 1
    fi
}

check_http() {
    local url=$1
    if curl -f -s $url > /dev/null; then
        echo "$(date): HTTP check passed for $url" >> $LOG_FILE
        return 0
    else
        echo "$(date): HTTP check failed for $url" >> $LOG_FILE
        return 1
    fi
}

# Check services
check_service nginx
nginx_status=$?

check_service "pm2-deploy"
pm2_status=$?

# Check application health
check_http $HEALTH_URL
health_status=$?

# Alert if any check fails
if [ $nginx_status -ne 0 ] || [ $pm2_status -ne 0 ] || [ $health_status -ne 0 ]; then
    echo "$(date): ALERT - Service checks failed" >> $LOG_FILE
    # TODO: Send alert (email, Slack, etc.)
    # curl -X POST -H 'Content-type: application/json' \
    #     --data '{"text":"Application health check failed"}' \
    #     YOUR_SLACK_WEBHOOK_URL
fi