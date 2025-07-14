# Backend Subdirectory Knowledge Base

This document contains specific instructions, conventions, and patterns relevant to the `backend` subdirectory.

## Overview

This directory contains the Firebase Functions (Node.js/TypeScript) that power the backend services for the CenthiosV2 application. It handles authentication, data storage, and business logic.

## Local Conventions

- All TypeScript code must follow the project's Prettier and ESLint configurations.
- **Service Layer**: All database interactions must be handled through a dedicated service layer located in `src/services`. Route handlers should call these services and not access Firestore directly.
- Environment variables must be used for all secrets and configurations.

## @imports

- @import "../../project_coordination.md" 