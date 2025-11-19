# Deploying to Cloudflare Pages

This guide explains how to deploy the Knowledge Base web interface to Cloudflare Pages.

## Prerequisites

1. A Cloudflare account
2. A GitHub account
3. This repository forked to your GitHub account

## Setup Instructions

1. Log in to your Cloudflare dashboard
2. Navigate to the "Pages" section
3. Click "Create a project"
4. Connect your GitHub account
5. Select the "Knowledge-Base" repository
6. Configure the build settings:
   - Framework preset: Next.js
   - Build command: `npm run build`
   - Build output directory: `.next`
7. Click "Save and Deploy"

## Environment Variables

No environment variables are required for this application.

## Custom Domain

To use a custom domain:
1. In your Cloudflare Pages project, go to "Settings"
2. Click "Custom Domains"
3. Follow the instructions to add your custom domain

## Troubleshooting

If you encounter issues during deployment:
1. Check the build logs in the Cloudflare Pages dashboard
2. Ensure all dependencies are correctly installed
3. Verify the build command is correct