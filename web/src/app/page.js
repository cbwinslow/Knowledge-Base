"use client";

import { useState, useEffect } from 'react';
import Navigation from '../components/Navigation';
import FileListing from '../components/FileListing';
import SearchBar from '../components/SearchBar';

export default function Home() {
  const [activeSection, setActiveSection] = useState('documents');
  const [searchQuery, setSearchQuery] = useState('');

  // Mock data for file listings
  const fileData = {
    documents: [
      { name: 'Installation Guide.md', type: 'markdown', size: '2.4 KB', lastModified: '2025-09-15' },
      { name: 'API Documentation.md', type: 'markdown', size: '15.7 KB', lastModified: '2025-09-10' },
      { name: 'User Manual.pdf', type: 'pdf', size: '1.2 MB', lastModified: '2025-09-05' },
    ],
    scripts: [
      { name: 'deploy.sh', type: 'bash', size: '1.1 KB', lastModified: '2025-09-12' },
      { name: 'backup.py', type: 'python', size: '3.2 KB', lastModified: '2025-09-08' },
      { name: 'utils.js', type: 'javascript', size: '5.6 KB', lastModified: '2025-09-14' },
    ],
    configurations: [
      { name: 'database.yml', type: 'yaml', size: '0.8 KB', lastModified: '2025-09-16' },
      { name: 'nginx.conf', type: 'config', size: '2.3 KB', lastModified: '2025-09-11' },
      { name: 'environment.prod.env', type: 'env', size: '0.3 KB', lastModified: '2025-09-09' },
    ],
    projects: [
      { name: 'agents.md', type: 'markdown', size: '3.1 KB', lastModified: '2025-09-17' },
      { name: 'qwen.md', type: 'markdown', size: '5.4 KB', lastModified: '2025-09-17' },
      { name: 'tasks.md', type: 'markdown', size: '2.8 KB', lastModified: '2025-09-17' },
    ],
    tasks: [
      { name: 'task-list.json', type: 'json', size: '1.5 KB', lastModified: '2025-09-18' },
      { name: 'progress-report.md', type: 'markdown', size: '4.2 KB', lastModified: '2025-09-13' },
    ]
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-white shadow-md">
        <div className="container mx-auto px-4 py-6">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between">
            <div>
              <h1 className="text-3xl font-bold text-indigo-800">Knowledge Base</h1>
              <p className="text-gray-600 mt-1">Centralized repository for documents, scripts, and configurations</p>
            </div>
            <div className="mt-4 md:mt-0">
              <SearchBar onSearch={setSearchQuery} />
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="flex flex-col lg:flex-row gap-8">
          {/* Sidebar Navigation */}
          <div className="lg:w-1/4">
            <Navigation 
              activeSection={activeSection} 
              setActiveSection={setActiveSection} 
            />
            
            {/* Stats Card */}
            <div className="bg-white rounded-lg shadow-md p-6 mt-6">
              <h3 className="text-lg font-semibold text-gray-800 mb-4">Repository Stats</h3>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Documents</span>
                  <span className="font-medium">{fileData.documents.length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Scripts</span>
                  <span className="font-medium">{fileData.scripts.length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Configurations</span>
                  <span className="font-medium">{fileData.configurations.length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Projects</span>
                  <span className="font-medium">{fileData.projects.length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Tasks</span>
                  <span className="font-medium">{fileData.tasks.length}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Main Content */}
          <div className="lg:w-3/4">
            <div className="bg-white rounded-lg shadow-md overflow-hidden">
              <div className="border-b border-gray-200 px-6 py-4">
                <h2 className="text-xl font-semibold text-gray-800 capitalize">
                  {activeSection}
                </h2>
                <p className="text-gray-600 mt-1">
                  Browse and manage your {activeSection} files
                </p>
              </div>
              
              <div className="p-6">
                <FileListing 
                  files={fileData[activeSection]} 
                  category={activeSection}
                  searchQuery={searchQuery}
                />
              </div>
            </div>

            {/* Quick Actions */}
            <div className="mt-8 bg-white rounded-lg shadow-md p-6">
              <h3 className="text-lg font-semibold text-gray-800 mb-4">Quick Actions</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <button className="bg-indigo-600 hover:bg-indigo-700 text-white py-3 px-4 rounded-lg transition duration-200 flex items-center justify-center">
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                  </svg>
                  Add New Document
                </button>
                <button className="bg-green-600 hover:bg-green-700 text-white py-3 px-4 rounded-lg transition duration-200 flex items-center justify-center">
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M9 19l3 3m0 0l3-3m-3 3V10"></path>
                  </svg>
                  Upload Files
                </button>
                <button className="bg-amber-600 hover:bg-amber-700 text-white py-3 px-4 rounded-lg transition duration-200 flex items-center justify-center">
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                  </svg>
                  Settings
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-gray-800 text-white py-8 mt-12">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="mb-4 md:mb-0">
              <h3 className="text-xl font-bold">Knowledge Base</h3>
              <p className="text-gray-400 mt-1">Organize and access your knowledge efficiently</p>
            </div>
            <div className="flex space-x-6">
              <a href="#" className="text-gray-300 hover:text-white transition duration-200">Documentation</a>
              <a href="#" className="text-gray-300 hover:text-white transition duration-200">GitHub</a>
              <a href="#" className="text-gray-300 hover:text-white transition duration-200">Support</a>
            </div>
          </div>
          <div className="border-t border-gray-700 mt-6 pt-6 text-center text-gray-400">
            <p>&copy; 2025 Knowledge Base. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}