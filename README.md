# Knowledge Base

A centralized repository for documents, scripts, configurations, and other knowledge assets with a modern web interface.

## Folder Structure

- **documents/** - Documentation files, guides, and manuals
- **scripts/** - Executable scripts and code snippets
- **configurations/** - Configuration files and templates
- **projects/** - Project-specific documentation
- **tasks/** - Task management and tracking files
- **web/** - Next.js web application for browsing and managing the knowledge base

## Web Interface

The web interface is built with Next.js and provides a modern, responsive interface for browsing and managing your knowledge base.

### Features

- Responsive design that works on desktop and mobile
- File browsing by category
- Search functionality
- File type icons for quick identification
- Dark mode support

### Development

To run the web interface locally:

1. Navigate to the `web/` directory:
   ```bash
   cd web
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run the development server:
   ```bash
   npm run dev
   ```

4. Open [http://localhost:3000](http://localhost:3000) in your browser

### Deployment

The web interface is configured for static export and can be deployed to Cloudflare Pages or any static hosting service.

See [CLOUDFLARE_PAGES_SETUP.md](CLOUDFLARE_PAGES_SETUP.md) for detailed deployment instructions.

## Security

This repository includes several security measures to prevent secrets from being committed:

- Pre-commit hooks using gitleaks for secret scanning
- GitHub Actions workflow for secret scanning
- Comprehensive `.gitignore` file to exclude sensitive files

## Configuration

The knowledge base is configured using YAML files in the `configurations/` directory. See `configurations/kb_config.yaml` for details on the folder structure and naming conventions.

## Project Documentation

- [agents.md](projects/agents.md) - Documentation about agents used in this knowledge base
- [qwen.md](projects/qwen.md) - Documentation about Qwen Code
- [tasks.md](projects/tasks.md) - Documentation about task management

## Contributing

To contribute to this knowledge base:
1. Fork the repository
2. Create a new branch for your changes
3. Commit your changes
4. Push to your fork
5. Create a pull request