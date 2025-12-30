# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

1. **DO NOT** create a public GitHub issue for security vulnerabilities
2. Email the maintainers directly with details of the vulnerability
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes (optional)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your report within 48 hours
- **Assessment**: We will assess the vulnerability and determine its severity within 7 days
- **Resolution**: Critical vulnerabilities will be addressed within 14 days
- **Disclosure**: After a fix is released, we will publicly acknowledge your contribution (unless you prefer to remain anonymous)

## Security Best Practices for Deployment

### Environment Variables

**Never commit secrets to version control.** Always use environment variables:

```bash
# Copy the example and fill in your values
cp .env.example .env

# Required secrets:
# - OCTOPUS_API_KEY: Your Octopus Energy API key
# - DB_PASSWORD: PostgreSQL database password
```

### API Key Security

- Your Octopus Energy API key (`sk_live_*`) provides access to your consumption data
- Store it only in `.env` files (which are gitignored)
- Never share your API key publicly
- Rotate your API key if you suspect it has been compromised

### Database Security

1. **Use strong passwords**: Avoid default passwords in production
2. **Network isolation**: The database should not be exposed to the internet
3. **Principle of least privilege**: Use a dedicated database user with minimal permissions

### Docker Deployment

When deploying with Docker:

```bash
# Set a strong database password
export DB_PASSWORD="your-strong-password-here"

# Run with environment variables
docker-compose up -d
```

### Nginx/Reverse Proxy

For production deployments:

1. Enable HTTPS with Let's Encrypt or similar
2. Configure proper security headers
3. Restrict access to trusted networks if possible

## Security Audit Summary

This section documents the security review conducted on 2025-12-30.

### Findings Summary

| Category | Status | Severity |
|----------|--------|----------|
| Hardcoded Secrets | ✅ Pass | - |
| SQL Injection | ✅ Pass | - |
| Dependency Vulnerabilities | ⚠️ Found | Medium |
| Input Validation | ✅ Pass | - |
| Authentication | ⚠️ Note | Info |
| CORS Configuration | ⚠️ Note | Low |

### Detailed Findings

#### 1. Dependency Vulnerabilities (Medium)

**Issue**: Starlette (FastAPI dependency) has known vulnerabilities.

**CVEs Identified**:
- CVE-2025-54121: Fixed in starlette >= 0.47.2
- CVE-2025-62727: Fixed in starlette >= 0.49.1

**Recommendation**: Update FastAPI to the latest version, which includes patched Starlette:

```bash
pip install --upgrade fastapi uvicorn
```

#### 2. Default Database Password (Low)

**Issue**: `docker-compose.yml` includes a fallback default password:
```yaml
POSTGRES_PASSWORD: ${DB_PASSWORD:-octopus_secret}
```

**Recommendation**: Always set `DB_PASSWORD` environment variable in production:
```bash
export DB_PASSWORD="$(openssl rand -base64 32)"
```

#### 3. CORS Configuration (Low)

**Issue**: CORS allows all methods and headers:
```python
allow_methods=["*"],
allow_headers=["*"],
```

**Recommendation**: For production, restrict to specific methods:
```python
allow_methods=["GET", "POST", "OPTIONS"],
allow_headers=["Content-Type", "Authorization"],
```

#### 4. No User Authentication (Info)

**Status**: The API is designed for personal/home use and does not implement user authentication.

**Recommendation**: If exposing to the internet:
- Use a VPN (e.g., Tailscale) for secure access
- Implement API key authentication
- Place behind HTTP Basic Auth via nginx

### Positive Security Features

The following security best practices are already implemented:

1. **Parameterized Queries**: SQLAlchemy ORM prevents SQL injection
2. **Input Validation**: FastAPI/Pydantic validates all inputs
3. **Secrets Management**: `.env` files are gitignored
4. **Secret Detection**: Pre-commit hooks include `detect-secrets`
5. **Non-root Container**: Docker runs as non-root user
6. **Type Safety**: TypeScript frontend with strict typing
7. **Dependency Pinning**: All dependencies have pinned versions

## Security Checklist for Operators

Before deploying to production:

- [ ] Set strong, unique passwords for database
- [ ] Configure HTTPS with valid certificates
- [ ] Review and restrict CORS origins
- [ ] Enable firewall rules to restrict access
- [ ] Set `DEBUG=false` in production
- [ ] Regularly update dependencies
- [ ] Monitor logs for suspicious activity
- [ ] Back up database regularly
- [ ] Use secrets management (e.g., Docker secrets, Vault)

## Dependency Updates

To check for and fix vulnerabilities:

```bash
# Python dependencies
pip install pip-audit
pip-audit -r backend/requirements.txt

# Node.js dependencies
cd frontend
npm audit
npm audit fix
```

## Contact

For security concerns, please contact the repository maintainers through GitHub's private vulnerability reporting feature or via email listed in the repository profile.
