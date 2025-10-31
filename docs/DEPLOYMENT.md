# Mealy Backend - Production Deployment Guide

## Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Environment Setup](#environment-setup)
3. [Docker Deployment](#docker-deployment)
4. [Cloud Platform Deployment](#cloud-platform-deployment)
5. [Post-Deployment](#post-deployment)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Troubleshooting](#troubleshooting)

## Pre-Deployment Checklist

### Security
- [ ] Change all default secrets (`SECRET_KEY`, `JWT_SECRET_KEY`)
- [ ] Rotate Firebase service account credentials
- [ ] Configure proper CORS origins (remove `localhost`)
- [ ] Enable HTTPS/TLS certificates
- [ ] Review and update firewall rules
- [ ] Scan for vulnerabilities (`safety check`, `trivy`)
- [ ] Set up secret management (AWS Secrets Manager, Azure Key Vault, etc.)

### Configuration
- [ ] Set `FLASK_ENV=production`
- [ ] Configure production database (if not using Firebase)
- [ ] Set up Redis for caching (recommended)
- [ ] Configure log aggregation
- [ ] Set up monitoring (Sentry, DataDog, etc.)
- [ ] Configure rate limiting
- [ ] Disable demo mode (`DEMO_MODE_ENABLED=false`)

### Testing
- [ ] Run full test suite (`pytest`)
- [ ] Test with production-like data
- [ ] Load testing (Apache Bench, Locust, etc.)
- [ ] Security testing (OWASP ZAP, Burp Suite)

### Infrastructure
- [ ] Set up CI/CD pipeline
- [ ] Configure backup strategy
- [ ] Plan scaling strategy
- [ ] Set up CDN for static assets
- [ ] Configure health checks
- [ ] Set up alerting

## Environment Setup

### Required Environment Variables

Create a `.env` file with production values:

```env
# Application
FLASK_ENV=production
PORT=5000
HOST=0.0.0.0

# Security (CHANGE THESE!)
SECRET_KEY=<generate-strong-secret-key>
JWT_SECRET_KEY=<generate-strong-jwt-secret>

# Firebase
FIREBASE_PROJECT_ID=your-production-project-id
FIREBASE_CREDENTIAL_PATH=/app/firebase-credentials.json

# AI Services
GEMINI_API_KEY=<your-production-gemini-key>
GEMINI_MODEL=gemini-2.0-flash-exp

# CORS (production domains only)
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Logging
LOG_LEVEL=INFO

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_DEFAULT=100 per hour

# Demo Mode (disable in production)
DEMO_MODE_ENABLED=false
```

### Generate Strong Secrets

```python
import secrets

# Generate SECRET_KEY
print(secrets.token_urlsafe(32))

# Generate JWT_SECRET_KEY
print(secrets.token_hex(32))
```

## Docker Deployment

### 1. Build Docker Image

```bash
docker build -t mealy-backend:latest .
```

### 2. Run Container

```bash
docker run -d \
  --name mealy-backend \
  -p 5000:5000 \
  --env-file backend/.env \
  -v $(pwd)/backend/data:/app/backend/data \
  -v $(pwd)/backend/logs:/app/backend/logs \
  --restart unless-stopped \
  mealy-backend:latest
```

### 3. Using Docker Compose (Recommended)

```bash
# Create production docker-compose override
cat > docker-compose.prod.yml << EOF
version: '3.8'

services:
  backend:
    image: mealy-backend:latest
    restart: always
    environment:
      - FLASK_ENV=production
      
  nginx:
    restart: always
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt:ro
      
  redis:
    restart: always
EOF

# Deploy
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Cloud Platform Deployment

### Google Cloud Run

```bash
# 1. Build and push to GCR
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/mealy-backend

# 2. Deploy
gcloud run deploy mealy-backend \
  --image gcr.io/YOUR_PROJECT_ID/mealy-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars FLASK_ENV=production \
  --set-secrets GEMINI_API_KEY=gemini-api-key:latest,SECRET_KEY=secret-key:latest
```

### AWS ECS (Fargate)

```bash
# 1. Push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

docker tag mealy-backend:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/mealy-backend:latest
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/mealy-backend:latest

# 2. Create task definition
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json

# 3. Update service
aws ecs update-service --cluster mealy-cluster --service mealy-backend --task-definition mealy-backend:1
```

### Azure Container Instances

```bash
# 1. Push to ACR
az acr build --registry mealyregistry --image mealy-backend:latest .

# 2. Deploy
az container create \
  --resource-group mealy-rg \
  --name mealy-backend \
  --image mealyregistry.azurecr.io/mealy-backend:latest \
  --cpu 2 \
  --memory 4 \
  --registry-login-server mealyregistry.azurecr.io \
  --registry-username <username> \
  --registry-password <password> \
  --dns-name-label mealy-backend \
  --ports 5000 \
  --environment-variables FLASK_ENV=production
```

### Heroku

```bash
# 1. Login
heroku login

# 2. Create app
heroku create mealy-backend

# 3. Set config
heroku config:set FLASK_ENV=production
heroku config:set SECRET_KEY=<secret>
heroku config:set GEMINI_API_KEY=<key>

# 4. Deploy
git push heroku main
```

## Post-Deployment

### 1. Verify Health

```bash
curl https://your-domain.com/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-31T10:00:00Z",
  "version": "2.0.0",
  "environment": "production",
  "services": {
    "database": {
      "status": "connected",
      "healthy": true
    },
    "ai": {
      "available": true,
      "model": "gemini-2.0-flash-exp"
    }
  }
}
```

### 2. Test API Endpoints

```bash
# Test recipe generation
curl -X POST https://your-domain.com/api/recipes/generate-with-ai \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"ingredients": ["chicken", "rice"], "servings": 4}'
```

### 3. Monitor Logs

```bash
# Docker
docker logs -f mealy-backend

# Docker Compose
docker-compose logs -f backend

# Cloud Run
gcloud run services logs read mealy-backend --limit=50

# AWS ECS
aws logs tail /ecs/mealy-backend --follow
```

### 4. Set Up SSL/TLS

#### Using Let's Encrypt (with Nginx)

```bash
# Install Certbot
apt-get install certbot python3-certbot-nginx

# Obtain certificate
certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renewal (cron)
0 0 * * * certbot renew --quiet
```

## Monitoring & Maintenance

### Health Monitoring

Set up regular health checks:

```bash
# Cron job for health check
*/5 * * * * curl -f https://your-domain.com/api/health || echo "Health check failed" | mail -s "Mealy Alert" admin@yourdomain.com
```

### Log Aggregation

Recommended tools:
- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Splunk**
- **Datadog**
- **CloudWatch** (AWS)
- **Cloud Logging** (GCP)

### Error Tracking

Integrate Sentry:

```python
# In app_enhanced.py
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration

sentry_sdk.init(
    dsn="your-sentry-dsn",
    integrations=[FlaskIntegration()],
    traces_sample_rate=1.0,
    environment=config.ENV
)
```

### Performance Monitoring

Tools:
- **New Relic**
- **Datadog APM**
- **Application Insights** (Azure)
- **Cloud Trace** (GCP)

### Backup Strategy

```bash
# Daily Firebase backup
gcloud firestore export gs://your-backup-bucket/$(date +%Y%m%d) --project=your-project-id

# Backup logs
tar -czf logs-backup-$(date +%Y%m%d).tar.gz backend/logs/
```

## Troubleshooting

### High Memory Usage

```bash
# Check container stats
docker stats mealy-backend

# Increase memory limit
docker update --memory="2g" --memory-swap="4g" mealy-backend
```

### Slow Response Times

1. Enable Redis caching
2. Optimize database queries
3. Add CDN for static assets
4. Scale horizontally (add more instances)

### Database Connection Issues

```bash
# Check Firebase connectivity
python -c "from utils.firebase_connector import get_db; db = get_db(); print('Connected!')"

# Verify credentials
echo $FIREBASE_CREDENTIAL_PATH
ls -la $FIREBASE_CREDENTIAL_PATH
```

### AI Service Errors

```bash
# Test Gemini API
curl "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY"

# Check rate limits
# Gemini Free: 60 requests/minute
```

### CORS Issues

Update `CORS_ORIGINS` in `.env`:
```env
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com,https://app.yourdomain.com
```

## Scaling Strategies

### Vertical Scaling
- Increase CPU/memory resources
- Optimize code performance
- Add caching layer

### Horizontal Scaling
- Use load balancer
- Run multiple backend instances
- Implement session management (Redis)
- Use container orchestration (Kubernetes)

### Database Scaling
- Enable Firebase read replicas
- Implement query caching
- Optimize indexes
- Consider sharding for large datasets

## Security Best Practices

1. **Keep Dependencies Updated**
   ```bash
   pip list --outdated
   pip install --upgrade -r requirements.txt
   ```

2. **Regular Security Scans**
   ```bash
   safety check
   trivy image mealy-backend:latest
   ```

3. **Implement Rate Limiting**
   Use Redis-backed rate limiting for production

4. **Monitor for Anomalies**
   Set up alerts for:
   - Unusual traffic patterns
   - High error rates
   - Authentication failures
   - Slow response times

5. **Regular Backups**
   - Daily database backups
   - Weekly full system backups
   - Test restoration procedures

## Support

For deployment issues:
- 📧 Email: devops@mealy.com
- 📖 Docs: https://docs.mealy.com
- 🐛 Issues: https://github.com/Tarekazabou/projet_web/issues

---

**Last Updated**: October 31, 2025
