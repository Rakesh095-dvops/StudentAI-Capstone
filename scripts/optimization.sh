sudo -u deploy pm2 install pm2-logrotate

# Configure log rotation
sudo -u deploy pm2 set pm2-logrotate:max_size 10M
sudo -u deploy pm2 set pm2-logrotate:retain 30

# optional NGINIX caching
cat > /etc/nginx/conf.d/cache.conf << 'EOF'
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=1g 
                 inactive=60m use_temp_path=off;
EOF