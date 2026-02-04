# PiliMinus Development Guidelines

## Core Philosophy

**PiliMinus = PiliPlus - Login Features**

This branch is a "subtraction" fork of PiliPlus. The core principle is to remove or replace all functionality that requires Bilibili login.

## Development Rules

### 1. Login-Required Features
- **Replace** with login-free API alternatives when available
- **Remove entirely** if no login-free alternative exists

### 2. Features to Remove
- Comment functionality (posting, replying)
- User interactions requiring auth (like, coin, favorite that require login)
- Personal account features (history sync, watch later that require login)
- Any feature that calls authenticated API endpoints

### 3. Features to Keep (Login-Free)
- Video playback
- Search
- Browse recommendations (anonymous)
- Download functionality
- Local history/favorites (stored locally, not synced)

## Technical Notes

- Package ID: `com.example.piliminus`
- App Name: `PiliMinus`
- Data directory is separate from PiliPlus to allow parallel installation
