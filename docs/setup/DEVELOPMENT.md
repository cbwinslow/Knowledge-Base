# Development Guide

This guide explains how to set up and work with the Knowledge Base web interface.

## Prerequisites

- Node.js (version 18 or higher)
- npm (comes with Node.js)

## Setting Up the Development Environment

1. Clone the repository:
   ```bash
   git clone https://github.com/cbwinslow/Knowledge-Base.git
   ```

2. Navigate to the web directory:
   ```bash
   cd Knowledge-Base/web
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

## Running the Development Server

To start the development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser to see the application.

The page will automatically reload when you make changes to the code.

## Project Structure

```
web/
├── public/              # Static assets
├── src/
│   ├── app/             # App Router components
│   │   ├── api/         # API routes
│   │   ├── globals.css  # Global styles
│   │   ├── layout.js    # Root layout
│   │   └── page.js      # Home page
│   ├── components/      # React components
│   ├── styles/          # CSS files
│   └── lib/             # Utility functions
├── next.config.js       # Next.js configuration
├── tailwind.config.js   # Tailwind CSS configuration
├── postcss.config.js    # PostCSS configuration
└── package.json         # Dependencies and scripts
```

## Adding New Components

To add a new component:

1. Create a new file in the `src/components/` directory
2. Name the file with PascalCase (e.g., `FileCard.js`)
3. Export the component as a default export
4. Import and use the component in your pages

## Styling

This project uses Tailwind CSS for styling. You can:

1. Use utility classes directly in your JSX
2. Add custom styles in `src/app/globals.css`
3. Create component-specific styles using Tailwind's `@apply` directive

## API Routes

API routes are located in `src/app/api/`. Each route is a directory with a `route.js` file that exports HTTP methods (GET, POST, etc.).

## Building for Production

To create a production build:

```bash
npm run build
```

This will generate a static export in the `out/` directory.

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for deployment instructions.