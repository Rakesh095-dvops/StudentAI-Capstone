# Capstone -  CI/CD pipelines, credentials, agent setup, deployment automation, and server/bootstrap via Ansible.


CI/CD solution for deploying Node.js backend and React frontend applications using Jenkins and Ansible.

## Architecture Overview

- **Frontend**: React application served via Nginx as static files
- **Backend**: Node.js/Express API managed by PM2
- **CI/CD**: Jenkins with declarative pipeline
- **Configuration Management**: Ansible for server bootstrap and deployment
- **Target OS**: Ubuntu 22.04 LTS

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Jenkins Setup](#jenkins-setup)
3. [Ansible Setup](#ansible-setup)
4. [Deployment Flow](#deployment-flow)
5. [Troubleshooting](#troubleshooting)
6. [Rollback Procedures](#rollback-procedures)

## Prerequisites

### Required Software
- Jenkins 2.400+ with Blue Ocean plugin
- Node.js 18+ LTS
- Ansible 2.14+
- Docker (optional, for containerized deployment)
- Ubuntu 22.04 target servers

### Required Credentials
- `scm_pat`: GitHub/GitLab Personal Access Token
- `ansible_ssh_key`: SSH private key for deploy user
- `dockerhub_creds` (optional): Docker Hub credentials

## Jenkins Setup

### 1. Install Jenkins on Ubuntu 22.04

```bash
# Install Java 17
sudo apt update
sudo apt install -y openjdk-17-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 2. Install Required Jenkins Plugins

Navigate to **Manage Jenkins** → **Manage Plugins** → **Available** and install:

- Pipeline
- Blue Ocean
- Git
- NodeJS Plugin
- Ansible Plugin
- Docker Pipeline Plugin
- Credentials Plugin
- Timestamper
- Build Timeout
- Workspace Cleanup

### 3. Configure Global Tool Configuration

**Manage Jenkins** → **Global Tool Configuration**:

#### Node.js Installation
- Name: `nodejs-18`
- Version: `NodeJS 18.19.0`

#### Git
- Name: `Default`
- Path to Git executable: `/usr/bin/git`

### 4. Setup Jenkins Agent

Create an agent labeled `ansible-builder`:

```bash
# On the agent machine
sudo apt update
sudo apt install -y openjdk-17-jdk nodejs npm ansible docker.io

# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Install Node.js 18 via NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installations
node --version  # Should show v18.x.x
npm --version
ansible --version
docker --version
```

### 5. Configure Credentials

**Manage Jenkins** → **Manage Credentials** → **Global**:

1. **scm_pat** (Secret text)
   - ID: `scm_pat`
   - Description: `Source Control Personal Access Token`

2. **ansible_ssh_key** (SSH Username with private key)
   - ID: `ansible_ssh_key` 
   - Username: `deploy`
   - Private Key: Enter directly or from file

3. **dockerhub_creds** (Username with password) - Optional
   - ID: `dockerhub_creds`
   - Description: `Docker Hub Credentials`

## Ansible Setup

### 1. Install Ansible on Jenkins Server

```bash
sudo apt update
sudo apt install -y ansible sshpass

# Create ansible directory structure
sudo mkdir -p /etc/ansible/{playbooks,roles,inventories}
```

### 2. Configure Ansible Inventory

Create `/etc/ansible/inventories/production.ini`:

```ini
[webservers]
web1 ansible_host=<HOST_1> ansible_user=deploy
web2 ansible_host=<HOST_2> ansible_user=deploy

[webservers:vars]
ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/deploy_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 3. Setup SSH Keys

```bash
# Generate SSH key pair for deploy user
ssh-keygen -t rsa -b 4096 -f /var/lib/jenkins/.ssh/deploy_key -N ""
sudo chown jenkins:jenkins /var/lib/jenkins/.ssh/deploy_key*

# Copy public key to target servers
ssh-copy-id -i /var/lib/jenkins/.ssh/deploy_key.pub deploy@<HOST_1>
ssh-copy-id -i /var/lib/jenkins/.ssh/deploy_key.pub deploy@<HOST_2>
```

## Deployment Flow

### 1. Pipeline Stages Overview

1. **Checkout**: Clone repository from Git
2. **Setup**: Install Node.js and dependencies
3. **Install Dependencies**: Run `npm install` for backend and frontend
4. **Build Frontend**: Create React production build
5. **Test**: Execute test suites
6. **Package**: Create deployment artifacts
7. **Docker Build/Push**: Optional containerization
8. **Bootstrap**: Configure target servers
9. **Deploy**: Deploy application using Ansible

### 2. Frontend Deployment
- React build artifacts deployed to `/var/www/nodeapp/frontend`
- Served by Nginx on port 80/443
- Nginx proxies API requests to backend

### 3. Backend Deployment
- Node.js application deployed to `/opt/nodeapp/backend`
- Managed by PM2 process manager
- Runs on port 3000 (internal)
- Health checks and auto-restart enabled


## Troubleshooting

### Jenkins Issues

#### Node.js Plugin Not Working
```bash
# Verify Node.js installation
node --version
npm --version

# Check Jenkins global tool configuration
# Manage Jenkins → Global Tool Configuration → NodeJS
```

#### Pipeline Fails at Dependencies Stage
```bash
# Check npm cache
npm cache clean --force

# Verify package.json files exist in both directories
ls -la backend/package.json
ls -la frontend/package.json
```

### Ansible Issues

#### SSH Connection Failures
```bash
# Test SSH connectivity
ansible webservers -m ping -i ansible/inventories/production.ini

# Check SSH key permissions
chmod 600 /var/lib/jenkins/.ssh/deploy_key
```

#### PM2 Process Not Starting
```bash
# Check PM2 status
sudo -u deploy pm2 status

# View PM2 logs
sudo -u deploy pm2 logs nodeapp

# Restart PM2 daemon
sudo -u deploy pm2 kill
sudo -u deploy pm2 resurrect
```

### Nginx Issues

#### 502 Bad Gateway
```bash
# Check backend service status
sudo -u deploy pm2 status nodeapp

# Test backend connectivity
curl -I http://localhost:3000/health

# Check Nginx configuration
sudo nginx -t
```

#### Static Files Not Serving
```bash
# Check file permissions
ls -la /var/www/nodeapp/frontend/

# Verify Nginx config
cat /etc/nginx/sites-enabled/nodeapp
```

### Application Issues

#### React Build Failures
```bash
# Clear React cache
cd frontend
rm -rf node_modules package-lock.json
npm install

# Check for build errors
npm run build -- --verbose
```

#### Backend API Errors
```bash
# Check application logs
sudo -u deploy pm2 logs nodeapp --lines 100

# Monitor real-time logs
sudo -u deploy pm2 logs nodeapp
```

## Rollback Procedures

### Quick Rollback
```bash
# Rollback to previous version
ansible-playbook -i ansible/inventories/production.ini \
    ansible/playbooks/rollback.yml

# Rollback to specific version
ansible-playbook -i ansible/inventories/production.ini \
    ansible/playbooks/rollback.yml \
    -e rollback_to=123
```

### Manual Rollback
```bash
# SSH to server
ssh deploy@<HOST_1>

# Check available releases
ls -la /opt/nodeapp/releases/

# Switch to previous release
ln -sfn /opt/nodeapp/releases/<PREVIOUS_BUILD> /opt/nodeapp/current

# Restart application
pm2 restart nodeapp

# Update frontend files
cp -r /opt/nodeapp/current/public/* /var/www/nodeapp/frontend/
```

### Database Rollback (if applicable)
```bash
# TODO: Add database migration rollback scripts
# MongoDB:
# mongo myapp --eval "db.migrations.find().sort({_id:-1}).limit(5)"

# PostgreSQL:
# psql -d myapp -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;"
```

## Production Considerations

### Security Hardening
- Enable UFW firewall with minimal open ports
- Use SSH key authentication only
- Regular security updates
- SSL/TLS certificates (Let's Encrypt recommended)
- Rate limiting on API endpoints
- Input validation and sanitization

### Monitoring Setup
```bash
# Install monitoring tools
sudo apt install -y htop iotop nethogs

# Setup log rotation
sudo logrotate -d /etc/logrotate.d/nodeapp

# Monitor PM2 processes
sudo -u deploy pm2 monit
```

### Backup Procedures
```bash
# Create backup script
```

### Performance Optimization
```bash
# Enable PM2 monitoring
```

## CI/CD Pipeline Triggers

### Webhook Configuration
1. **GitHub**: Repository Settings → Webhooks
   - Payload URL: `http://your-jenkins-server/github-webhook/`
   - Content type: `application/json`
   - Events: `push`, `pull_request`

2. **GitLab**: Project Settings → Integrations
   - URL: `http://your-jenkins-server/project/your-job-name`
   - Token: Use Jenkins API token
   - Trigger: `Push events`, `Merge request events`


## Security Checklist

### Server Security
- [ ] UFW firewall enabled with minimal ports
- [ ] SSH key-only authentication
- [ ] Regular security updates scheduled
- [ ] Non-root user for application processes
- [ ] File permissions properly set
- [ ] SSL/TLS certificates installed
- [ ] Rate limiting configured
- [ ] Security headers implemented

### Application Security
- [ ] Environment variables for secrets
- [ ] Input validation implemented
- [ ] SQL injection prevention
- [ ] XSS protection enabled
- [ ] CORS configured properly
- [ ] Authentication/authorization implemented
- [ ] Dependency security scanning
- [ ] Error handling doesn't expose internals

### CI/CD Security
- [ ] Jenkins secured with authentication
- [ ] Credentials stored securely
- [ ] Build artifacts signed/verified
- [ ] Pipeline access controlled
- [ ] Audit logging enabled
- [ ] Secrets not in source code
- [ ] Container image scanning (if using Docker)

## Commands FYR

### Jenkins Pipeline
```bash
# Trigger build manually
curl -X POST "http://jenkins-server/job/nodeapp/build" \
     --user "username:api-token"

# Get build status
curl "http://jenkins-server/job/nodeapp/lastBuild/api/json" \
     --user "username:api-token"
```

### Ansible Commands
```bash
# Bootstrap servers
ansible-playbook -i ansible/inventories/production.ini \
    ansible/playbooks/bootstrap.yml

# Deploy application
ansible-playbook -i ansible/inventories/production.ini \
    ansible/playbooks/deploy.yml \
    -e build_number=123

# Rollback to previous version
ansible-playbook -i ansible/inventories/production.ini \
    ansible/playbooks/rollback.yml

# Check server status
ansible webservers -i ansible/inventories/production.ini -m shell \
    -a "sudo -u deploy pm2 status"
```

### PM2 Commands
```bash
# Application management
sudo -u deploy pm2 start ecosystem.config.js
sudo -u deploy pm2 restart nodeapp
sudo -u deploy pm2 stop nodeapp
sudo -u deploy pm2 reload nodeapp

# Monitoring
sudo -u deploy pm2 status
sudo -u deploy pm2 logs nodeapp
sudo -u deploy pm2 monit

# Process management
sudo -u deploy pm2 save
sudo -u deploy pm2 resurrect
```

### Nginx Commands
```bash
# Configuration management
sudo nginx -t                    # Test configuration
sudo systemctl reload nginx      # Reload configuration
sudo systemctl restart nginx     # Restart service

# Log monitoring
sudo tail -f /var/log/nginx/nodeapp_access.log
sudo tail -f /var/log/nginx/nodeapp_error.log
```

### Troubleshooting Commands
```bash
# Check service status
systemctl status nginx
systemctl status pm2-deploy

# Monitor resource usage
htop
iotop -o
nethogs

# Check disk space
df -h
du -sh /opt/nodeapp/*

# Network connectivity
netstat -tlnp | grep :3000
curl -I http://localhost/health
```



## Conclusion

This comprehensive DevOps solution provides:

1. **Automated CI/CD pipeline** with Jenkins for Node.js/React applications
2. **Infrastructure automation** using Ansible for server configuration
3. **Production-ready deployment** with PM2 process management and Nginx reverse proxy
4. **Monitoring and logging** setup for operational visibility
5. **Security hardening** with best practices implemented
6. **Rollback capabilities** for quick recovery from issues
7. **Comprehensive documentation** for maintenance and troubleshooting

The solution is designed to be production-ready with proper error handling, security considerations, and operational procedures. All components are configured to work together seamlessly while maintaining security and performance standards.

**TODO:**
- Configure database connections and migrations
- Set up SSL/TLS certificates
- Implement application-specific monitoring
- Configure external service integrations
- Set up centralized logging if needed
- Customize security policies for your organization
- Add backup and disaster recovery procedures