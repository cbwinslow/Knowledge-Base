# Cloudflare Pages Setup Guide

This guide will help you set up Cloudflare Pages to host your Knowledge Base web interface.

## Prerequisites

1. A Cloudflare account (sign up at https://dash.cloudflare.com/sign-up if you don't have one)
2. A GitHub account (you already have this)
3. This repository connected to your GitHub account

## Setting Up Cloudflare Pages

1. Log in to your Cloudflare dashboard at https://dash.cloudflare.com/login

2. In the left sidebar, click on "Pages" under the "WEBSITES" section

3. Click the "Create a project" button

4. Connect your GitHub account by clicking "Begin setup" next to GitHub

5. Install the Cloudflare Pages GitHub app on your repository:
   - Select the repository "cbwinslow/Knowledge-Base"
   - Click "Install & Authorize"

6. Configure your project settings:
   - Project name: `knowledge-base`
   - Production branch: `master`
   - Framework preset: `Next.js`
   - Build command: `npm run build`
   - Build output directory: `out`

7. Click "Save and Deploy"

## Custom Domain (Optional)

If you want to use a custom domain:

1. In your Cloudflare Pages project, go to "Settings"
2. Click "Custom Domains"
3. Click "Setup a custom domain"
4. Enter your domain name
5. Follow the instructions to update your DNS records

## Environment Variables

No environment variables are needed for this project.

## Troubleshooting

If you encounter issues during deployment:
1. Check the build logs in the Cloudflare Pages dashboard
2. Ensure all dependencies are correctly installed
3. Verify the build command is correct