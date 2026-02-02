#!/bin/bash

# Test script to verify the frontend build works with the new i18n dependencies

echo "🧪 Testing frontend build with i18n dependencies..."

# Clean any existing build
echo "📦 Cleaning previous build..."
rm -rf build node_modules package-lock.json

# Install dependencies with legacy peer deps
echo "📥 Installing dependencies..."
npm install --legacy-peer-deps

# Test the build
echo "🔨 Building the application..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build successful! The i18n implementation is working correctly."
    echo "🌐 You can now deploy to your remote server."
else
    echo "❌ Build failed. Please check the error messages above."
    exit 1
fi 