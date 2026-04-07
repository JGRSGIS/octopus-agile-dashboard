# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.0.0] - 2026-01-17

### Added
- Configurable consumption period and running totals on the dashboard (#23)
- Agile vs Fixed tariff comparison tab for cost modelling (#22)
- Real-time electricity monitoring via Octopus Home Mini (GraphQL subscription) (#14)
- Documentation for the live monitoring feature (#14)
- Purge script for complete uninstallation of the stack (#15)
- Terraform/OpenTofu configurations for Oracle Cloud Infrastructure deployment (#11)
- Security policy and vulnerability reporting guidelines (`SECURITY.md`) (#10)
- Comprehensive linting, formatting, and pre-commit hooks (ESLint, Prettier, Ruff, Black) (#9)
- Comprehensive third-party license documentation (#13)
- Alembic database migration configuration (#1)

### Fixed
- Cost breakdown on the Analysis tab now fetches full 7-day price history (#21)
- Live Demand chart showing kW instead of the correct unit W (#20)
- TypeScript errors for possibly undefined values in LiveCostTracker (#19)
- PostgreSQL cluster initialisation in setup script (#18)
- PostgreSQL setup hang — script now waits for service readiness before proceeding (#17)
- Nginx startup failure when the package was in a broken state (#16)
- Deployment issues identified during dry-run testing (#12, #2)
- API URL changed to relative paths to allow network access from other devices (#6)
- PostgreSQL schema permissions for PostgreSQL 15+ (#6)
- Nginx now listens on all network interfaces, not just localhost (#6)
- OOM crash during frontend build on Raspberry Pi — Plotly.js loaded from CDN (#5, #4)
- npm deprecation warnings and OOM build issues (#3)

### Changed
- Updated README with comprehensive setup and configuration documentation (#7)
- Audited and updated all project dependencies to current versions (#8)

[Unreleased]: https://github.com/JGRSGIS/octopus-agile-dashboard/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/JGRSGIS/octopus-agile-dashboard/commits/main
