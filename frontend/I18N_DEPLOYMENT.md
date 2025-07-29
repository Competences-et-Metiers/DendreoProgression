# Internationalization (i18n) Deployment Guide

This guide covers deploying the Dendreo Progression frontend with the new internationalization feature.

## 🎯 Overview

The frontend now supports multiple languages with French as the default language. This includes:

- **French (fr)** - Default language
- **English (en)** - Secondary language
- **Language Selector** - Globe icon in the top-right corner
- **Persistent Language Choice** - Saved in localStorage

## 🚀 Quick Deployment

### 1. Local Testing (Recommended)

Before deploying to production, test the build locally:

```bash
cd frontend
chmod +x test-build.sh
./test-build.sh
```

This script will:
- Clean previous builds
- Install dependencies with `--legacy-peer-deps`
- Test the production build
- Verify i18n functionality

### 2. Docker Deployment

The Dockerfiles have been updated to handle the dependency conflicts:

#### Development Environment
```bash
# Build with development Dockerfile
docker build -f Dockerfile.dev -t dendreo-frontend-dev .

# Run development container
docker run -p 3000:3000 dendreo-frontend-dev
```

#### Production Environment
```bash
# Build with production Dockerfile
docker build -f Dockerfile.prod -t dendreo-frontend-prod .

# Run production container
docker run -p 80:80 dendreo-frontend-prod
```

### 3. Docker Compose Deployment

Update your docker-compose files to use the updated Dockerfiles:

```yaml
frontend:
  build:
    context: ./frontend
    dockerfile: Dockerfile.dev  # or Dockerfile.prod
  ports:
    - "3000:3000"
  environment:
    - REACT_APP_API_URL=http://backend:8000/api
```

## 🔧 Dependency Resolution

### Issue
The i18n packages (react-i18next, i18next) require TypeScript 5.x, but react-scripts expects TypeScript 4.x.

### Solution
All npm install commands now use `--legacy-peer-deps` flag:

```bash
npm install --legacy-peer-deps
npm ci --legacy-peer-deps
```

### Updated Files
- `frontend/Dockerfile.dev` - Added `--legacy-peer-deps` to npm ci
- `frontend/Dockerfile.prod` - Added `--legacy-peer-deps` to npm ci
- `frontend/package.json` - Added `install-deps` script

## 🌐 Language Features

### User Interface
- **Language Selector**: Globe icon (🌐) in the top-right corner of the dashboard
- **Language Flags**: 🇫🇷 for French, 🇺🇸 for English
- **Persistent Choice**: Language preference saved in localStorage
- **Dynamic Updates**: HTML lang attribute updates automatically

### Translation Coverage
- ✅ Dashboard titles and statistics
- ✅ Navigation elements
- ✅ Error messages and loading states
- ✅ Button labels and actions
- ✅ Filter and sort options
- ✅ Cache status information
- ✅ Course and participant details

## 🧪 Testing

### Local Development
```bash
cd frontend
npm install --legacy-peer-deps
npm start
```

### Production Build Test
```bash
cd frontend
npm install --legacy-peer-deps
npm run build
```

### Language Switching Test
1. Open the application
2. Look for the globe icon (🌐) in the top-right corner
3. Click to open the language dropdown
4. Switch between French and English
5. Verify that all text updates immediately
6. Refresh the page to confirm language preference persists

## 📁 File Structure

```
frontend/src/i18n/
├── index.js              # i18n configuration
├── locales/
│   ├── fr.json          # French translations
│   └── en.json          # English translations
└── components/
    └── LanguageSelector.js  # Language switcher component
```

## 🔍 Troubleshooting

### Build Errors
If you encounter dependency conflicts:

```bash
# Clean and reinstall
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

### Language Not Switching
1. Check browser console for errors
2. Verify localStorage is enabled
3. Clear browser cache and try again

### Missing Translations
1. Check the translation files in `src/i18n/locales/`
2. Verify the translation keys are being used correctly
3. Check the browser console for missing key warnings

## 🚀 Deployment Checklist

- [ ] Test local build with `./test-build.sh`
- [ ] Verify Docker images build successfully
- [ ] Test language switching functionality
- [ ] Confirm translations appear correctly
- [ ] Check that language preference persists
- [ ] Verify HTML lang attribute updates
- [ ] Test on different browsers

## 📝 Notes

- **Default Language**: French (fr) is set as the default
- **Fallback**: If a translation is missing, it falls back to French
- **Development**: Debug mode is enabled in development environment
- **Performance**: Translations are loaded efficiently with minimal impact

## 🆘 Support

If you encounter issues:

1. Check the browser console for errors
2. Verify all dependencies are installed with `--legacy-peer-deps`
3. Ensure the i18n configuration is properly imported in `App.js`
4. Test with a clean build using the provided test script 