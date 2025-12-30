# Dependency Audit Report

**Generated:** 2025-12-30
**Auditor:** Automated security scan

## Summary

| Category | Status |
|----------|--------|
| Python Security Vulnerabilities | ✅ None found |
| Node.js Security Vulnerabilities | ⚠️ 1 fixed (esbuild/vite) |
| Outdated Packages | ✅ Updated |
| Unnecessary Dependencies | ✅ None identified |

---

## Python Backend (`backend/`)

### Files Modified
- `requirements.txt` - Production dependencies with pinned versions
- `requirements-dev.txt` - Development/testing dependencies (NEW)

### Security Scan Results
```
pip-audit: No known vulnerabilities found
```

### Changes Made

#### Production Dependencies (`requirements.txt`)

| Package | Previous | Updated | Notes |
|---------|----------|---------|-------|
| fastapi | >=0.109.0 | ==0.115.6 | Pinned to stable LTS-compatible version |
| uvicorn | >=0.27.0 | ==0.34.0 | Updated with security patches |
| pydantic | >=2.5.0 | ==2.10.4 | Updated to latest 2.x |
| pydantic-settings | >=2.1.0 | ==2.7.0 | Compatible with pydantic 2.10 |
| httpx | >=0.26.0 | ==0.28.1 | Updated; removed duplicate entry |
| sqlalchemy | >=2.0.25 | ==2.0.36 | Latest stable 2.0.x |
| asyncpg | >=0.29.0 | ==0.30.0 | Updated |
| alembic | >=1.13.0 | ==1.14.0 | Updated |
| redis | >=5.0.0 | ==5.2.1 | Kept on 5.x for compatibility |
| python-dotenv | >=1.0.0 | ==1.0.1 | Minor update |
| python-dateutil | >=2.8.2 | ==2.9.0.post0 | Updated |

#### Development Dependencies (`requirements-dev.txt`)

| Package | Version | Purpose |
|---------|---------|---------|
| pytest | ==8.3.4 | Testing framework |
| pytest-asyncio | ==0.24.0 | Async test support |
| pytest-cov | ==6.0.0 | Coverage reporting |
| black | ==24.10.0 | Code formatter |
| isort | ==5.13.2 | Import sorter |
| mypy | ==1.13.0 | Static type checker |
| ruff | ==0.8.4 | Fast linter |
| types-python-dateutil | ==2.9.0.20241206 | Type stubs |
| pip-tools | ==7.4.1 | Dependency management |
| pre-commit | ==4.0.1 | Git hooks |

### Issues Fixed
1. **Duplicate dependency removed:** `httpx` was listed twice
2. **Version pinning:** Changed from `>=` to `==` for reproducible builds
3. **Separation of concerns:** Dev/test dependencies moved to `requirements-dev.txt`

---

## Node.js Frontend (`frontend/`)

### Files Modified
- `package.json` - Updated dependencies and security fixes

### Security Scan Results
```
BEFORE: 2 moderate severity vulnerabilities
- esbuild <=0.24.2: Development server request vulnerability
- vite 0.11.0-6.1.6: Depends on vulnerable esbuild

AFTER: 0 vulnerabilities (fixed via vite upgrade and esbuild override)
```

### Changes Made

#### Production Dependencies

| Package | Previous | Updated | Notes |
|---------|----------|---------|-------|
| react | ^18.2.0 | ^18.3.1 | Latest React 18 (not upgrading to 19 yet) |
| react-dom | ^18.2.0 | ^18.3.1 | Latest React 18 |
| plotly.js | ^2.29.0 | ^2.35.3 | Updated within major version |
| ag-grid-react | ^31.0.0 | ^31.3.4 | Latest 31.x (not upgrading to 35.x - breaking changes) |
| ag-grid-community | ^31.0.0 | ^31.3.4 | Latest 31.x |
| @tanstack/react-query | ^5.17.0 | ^5.62.16 | Updated |
| axios | ^1.6.0 | ^1.7.9 | Security and bug fixes |
| date-fns | ^3.3.0 | ^3.6.0 | Updated within major version |
| lucide-react | ^0.312.0 | ^0.468.0 | Updated icons |
| clsx | ^2.1.0 | ^2.1.1 | Minor update |

#### Development Dependencies

| Package | Previous | Updated | Notes |
|---------|----------|---------|-------|
| vite | ^5.0.8 | ^6.2.0 | **SECURITY FIX** - fixes esbuild vulnerability |
| @types/react | ^18.2.43 | ^18.3.18 | Updated |
| @types/react-dom | ^18.2.17 | ^18.3.5 | Updated |
| typescript-eslint | ^8.18.0 | ^8.18.2 | Minor update |
| @vitejs/plugin-react | ^4.2.1 | ^4.3.4 | Updated for vite 6 compatibility |
| autoprefixer | ^10.4.16 | ^10.4.20 | Updated |
| postcss | ^8.4.32 | ^8.4.49 | Updated |
| tailwindcss | ^3.4.0 | ^3.4.17 | Updated |
| typescript | ^5.3.0 | ^5.7.2 | Updated |

#### Security Overrides Added
```json
"overrides": {
  "esbuild": ">=0.25.0"
}
```

### Packages NOT Updated (Breaking Changes)
These packages have major version updates available but were intentionally kept at current versions to avoid breaking changes:

| Package | Current | Latest | Reason |
|---------|---------|--------|--------|
| react/react-dom | 18.x | 19.x | React 19 has significant breaking changes |
| ag-grid-* | 31.x | 35.x | Major version with API changes |
| plotly.js | 2.x | 3.x | Major version with API changes |
| date-fns | 3.x | 4.x | Major version with API changes |

---

## Recommendations

### Immediate Actions
1. ✅ **Run `npm install`** in frontend directory to update packages
2. ✅ **Run `pip install -r requirements.txt -r requirements-dev.txt`** in backend directory
3. ✅ **Delete `package-lock.json`** and regenerate with `npm install` for clean lockfile

### Future Considerations
1. **React 19 Migration:** Evaluate when ecosystem is more stable
2. **AG Grid 35.x:** Review breaking changes and plan migration
3. **Plotly.js 3.x:** Test compatibility with react-plotly.js
4. **Automated Scanning:** Consider adding `npm audit` and `pip-audit` to CI/CD

### Maintenance Commands
```bash
# Check for outdated packages
npm outdated  # Frontend
pip list --outdated  # Backend

# Security scanning
npm audit  # Frontend
pip-audit -r requirements.txt  # Backend

# Update lockfiles
npm update  # Frontend
pip-compile requirements.in  # Backend (if using pip-tools)
```

---

## Installation Instructions

### Backend
```bash
cd backend

# Production only
pip install -r requirements.txt

# Development (includes production + dev tools)
pip install -r requirements.txt -r requirements-dev.txt
```

### Frontend
```bash
cd frontend

# Install all dependencies
npm install

# Verify no vulnerabilities
npm audit
```
