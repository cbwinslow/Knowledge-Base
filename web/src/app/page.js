"use client";

import { useState, useMemo } from 'react';
import Navigation from '../components/Navigation';
import FileListing from '../components/FileListing';
import SearchBar from '../components/SearchBar';

const sectionDetails = {
  agents: {
    title: 'Agents',
    description: 'Autonomous operators with well-defined roles, stacks, and dependencies ready for CrewAI orchestrations.',
  },
  tools: {
    title: 'Tools',
    description: 'Reusable primitives with inputs, outputs, and owners. Keep capability coverage and version history visible.',
  },
  toolsets: {
    title: 'Toolsets',
    description: 'Composed packs of tools curated for specific workflows such as releases, incident response, and research.',
  },
  crews: {
    title: 'Crews',
    description: 'CrewAI crews with missions, members, and operating cadences. Track operational readiness at a glance.',
  },
  crewConfigs: {
    title: 'Crew Configs',
    description: 'Environment-scoped configuration, routing, and safeguards for each crew entrypoint.',
  },
};

const resourceConfigs = {
  agents: {
    searchFields: ['name', 'role', 'stack', 'toolset', 'owner', 'status'],
    columns: [
      { key: 'role', label: 'Role' },
      { key: 'stack', label: 'Stack' },
      { key: 'toolset', label: 'Toolset' },
      { key: 'owner', label: 'Owner' },
      { key: 'status', label: 'Status', type: 'status' },
      { key: 'updated', label: 'Updated' },
    ],
    actions: [
      { label: 'Open sheet', tone: 'indigo' },
      { label: 'Launch run', tone: 'green' },
    ],
  },
  tools: {
    searchFields: ['name', 'type', 'version', 'owner', 'coverage', 'status'],
    columns: [
      { key: 'type', label: 'Type' },
      { key: 'version', label: 'Version' },
      { key: 'coverage', label: 'Coverage' },
      { key: 'owner', label: 'Owner' },
      { key: 'status', label: 'Status', type: 'status' },
      { key: 'updated', label: 'Updated' },
    ],
    actions: [
      { label: 'Docs', tone: 'indigo' },
      { label: 'Pin to crew', tone: 'green' },
    ],
  },
  toolsets: {
    searchFields: ['name', 'composition', 'defaultCrew', 'useCases', 'status'],
    columns: [
      { key: 'composition', label: 'Composition' },
      { key: 'defaultCrew', label: 'Default Crew' },
      { key: 'useCases', label: 'Use Cases' },
      { key: 'status', label: 'Status', type: 'status' },
      { key: 'updated', label: 'Updated' },
    ],
    actions: [
      { label: 'Open pack', tone: 'indigo' },
      { label: 'Assign', tone: 'green' },
    ],
  },
  crews: {
    searchFields: ['name', 'mission', 'toolset', 'cadence', 'status'],
    columns: [
      { key: 'mission', label: 'Mission' },
      { key: 'toolset', label: 'Toolset' },
      { key: 'cadence', label: 'Cadence' },
      { key: 'slo', label: 'SLO' },
      { key: 'status', label: 'Status', type: 'status' },
      { key: 'updated', label: 'Updated' },
    ],
    actions: [
      { label: 'Open dashboard', tone: 'indigo' },
      { label: 'Start run', tone: 'green' },
    ],
  },
  crewConfigs: {
    searchFields: ['name', 'environment', 'entrypoint', 'version', 'status'],
    columns: [
      { key: 'environment', label: 'Environment' },
      { key: 'entrypoint', label: 'Entrypoint' },
      { key: 'version', label: 'Version' },
      { key: 'routing', label: 'Routing' },
      { key: 'status', label: 'Status', type: 'status' },
      { key: 'updated', label: 'Updated' },
    ],
    actions: [
      { label: 'Edit config', tone: 'indigo' },
      { label: 'Promote', tone: 'green' },
    ],
  },
};

const resourceData = {
  agents: [
    {
      name: 'Atlas Planner',
      role: 'Strategic Planner',
      stack: 'LangGraph + OpenAI Functions',
      toolset: 'Release Ops Pack',
      owner: 'Platform',
      status: 'ready',
      updated: '2025-11-18',
    },
    {
      name: 'Helix Researcher',
      role: 'Research & Synthesis',
      stack: 'Llama 3 + RAG',
      toolset: 'Research Pack',
      owner: 'Labs',
      status: 'ready',
      updated: '2025-11-17',
    },
    {
      name: 'Nova Navigator',
      role: 'Incident Triage',
      stack: 'LangGraph + Cortex XSOAR',
      toolset: 'Incident Response Pack',
      owner: 'SRE',
      status: 'live',
      updated: '2025-11-19',
    },
    {
      name: 'Quanta QA',
      role: 'QA & Regression',
      stack: 'OpenAI + Playwright',
      toolset: 'QA Pack',
      owner: 'QA Guild',
      status: 'maintenance',
      updated: '2025-11-15',
    },
    {
      name: 'Orion Shepherd',
      role: 'Data Pipeline Steward',
      stack: 'LangGraph + Dagster',
      toolset: 'Data Engineering Pack',
      owner: 'Data Platform',
      status: 'ready',
      updated: '2025-11-16',
    },
  ],
  tools: [
    {
      name: 'GitSync',
      type: 'Repository',
      version: '1.4.2',
      coverage: 'Repos + PR metadata',
      owner: 'DevEx',
      status: 'ready',
      updated: '2025-11-18',
    },
    {
      name: 'Runbook Fetch',
      type: 'Knowledge',
      version: '0.9.0',
      coverage: 'Markdown, Confluence',
      owner: 'SRE',
      status: 'ready',
      updated: '2025-11-17',
    },
    {
      name: 'Telemetry Pulse',
      type: 'Observability',
      version: '2.1.0',
      coverage: 'Grafana, Datadog, CloudWatch',
      owner: 'Observability',
      status: 'live',
      updated: '2025-11-19',
    },
    {
      name: 'Secure Vault',
      type: 'Secrets',
      version: '1.3.1',
      coverage: 'HashiCorp Vault + KMS',
      owner: 'Security',
      status: 'ready',
      updated: '2025-11-16',
    },
    {
      name: 'Test Runner',
      type: 'Quality',
      version: '1.0.5',
      coverage: 'Playwright + Lighthouse',
      owner: 'QA Guild',
      status: 'maintenance',
      updated: '2025-11-14',
    },
  ],
  toolsets: [
    {
      name: 'Release Ops Pack',
      composition: ['GitSync', 'Runbook Fetch', 'Telemetry Pulse'],
      defaultCrew: 'Release Management Crew',
      useCases: ['Release notes', 'Approval flow', 'Smoke validation'],
      status: 'ready',
      updated: '2025-11-18',
    },
    {
      name: 'Incident Response Pack',
      composition: ['Telemetry Pulse', 'Runbook Fetch', 'Secure Vault'],
      defaultCrew: 'Incident Response Team',
      useCases: ['Triage', 'Impact analysis', 'Stakeholder updates'],
      status: 'live',
      updated: '2025-11-19',
    },
    {
      name: 'Research Pack',
      composition: ['Runbook Fetch', 'GitSync'],
      defaultCrew: 'Example Research Crew',
      useCases: ['Competitive research', 'RFC drafting', 'Context expansion'],
      status: 'ready',
      updated: '2025-11-17',
    },
    {
      name: 'Data Engineering Pack',
      composition: ['Secure Vault', 'Telemetry Pulse'],
      defaultCrew: 'Data Engineering Team',
      useCases: ['DAG audits', 'Schema drift alerts'],
      status: 'ready',
      updated: '2025-11-16',
    },
    {
      name: 'QA Pack',
      composition: ['Test Runner', 'GitSync'],
      defaultCrew: 'Software Development Team',
      useCases: ['Regression sweeps', 'Accessibility checks'],
      status: 'maintenance',
      updated: '2025-11-15',
    },
  ],
  crews: [
    {
      name: 'Software Development Team',
      mission: 'Plan, build, and validate features',
      toolset: 'QA Pack',
      cadence: 'Daily',
      slo: 'P95 tasks < 2h',
      status: 'ready',
      updated: '2025-11-16',
    },
    {
      name: 'Release Management Crew',
      mission: 'Cut, test, and ship releases',
      toolset: 'Release Ops Pack',
      cadence: 'Per release',
      slo: 'Release cycle < 24h',
      status: 'live',
      updated: '2025-11-18',
    },
    {
      name: 'Incident Response Team',
      mission: 'Detect, triage, and mitigate incidents',
      toolset: 'Incident Response Pack',
      cadence: 'On-call',
      slo: 'MTTR < 30m',
      status: 'live',
      updated: '2025-11-19',
    },
    {
      name: 'Data Engineering Team',
      mission: 'Keep data platforms healthy and compliant',
      toolset: 'Data Engineering Pack',
      cadence: 'Weekly',
      slo: 'Pipeline success > 99%',
      status: 'ready',
      updated: '2025-11-16',
    },
    {
      name: 'Example Research Crew',
      mission: 'Rapid discovery and synthesis',
      toolset: 'Research Pack',
      cadence: 'Ad hoc',
      slo: 'Briefs < 4h',
      status: 'maintenance',
      updated: '2025-11-15',
    },
  ],
  crewConfigs: [
    {
      name: 'Release Crew - Production',
      environment: 'prod',
      entrypoint: 'release_manager.py',
      version: 'v2.1.0',
      routing: 'Primary LLM + backup, approvals required',
      status: 'live',
      updated: '2025-11-19',
    },
    {
      name: 'Incident Crew - Staging',
      environment: 'staging',
      entrypoint: 'incident_coordinator.yaml',
      version: 'v1.6.0',
      routing: 'Observation heavy, auto page',
      status: 'ready',
      updated: '2025-11-18',
    },
    {
      name: 'Research Crew - Sandbox',
      environment: 'sandbox',
      entrypoint: 'research_crew.yaml',
      version: 'v1.2.3',
      routing: 'Exploratory, low risk',
      status: 'ready',
      updated: '2025-11-17',
    },
    {
      name: 'Data Crew - Production',
      environment: 'prod',
      entrypoint: 'data_guardian.py',
      version: 'v1.4.2',
      routing: 'Strict guardrails, sync with Dagster',
      status: 'live',
      updated: '2025-11-16',
    },
    {
      name: 'QA Crew - Pre-prod',
      environment: 'preprod',
      entrypoint: 'qa_commander.yaml',
      version: 'v1.0.5',
      routing: 'Regression-first, UI snapshots',
      status: 'maintenance',
      updated: '2025-11-15',
    },
  ],
};

const operationalReads = [
  {
    title: 'Release freeze window ends in 2 hours',
    type: 'alert',
    detail: 'Queue ready for promotion with Release Ops Pack and Atlas Planner.',
  },
  {
    title: 'Incident playbook updated',
    type: 'update',
    detail: 'Incident Response Pack routing now mirrors the on-call escalation sheet.',
  },
  {
    title: 'New telemetry coverage added',
    type: 'info',
    detail: 'Telemetry Pulse now scrapes CloudWatch anomalies for Nova Navigator.',
  },
];

export default function Home() {
  const [activeSection, setActiveSection] = useState('agents');
  const [searchQuery, setSearchQuery] = useState('');

  const stats = useMemo(() => (
    Object.keys(resourceData).map((key) => ({
      label: sectionDetails[key]?.title || key,
      value: resourceData[key].length,
    }))
  ), []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100">
      <header className="bg-white shadow-md">
        <div className="container mx-auto px-4 py-6">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <div className="inline-flex items-center space-x-2 rounded-full bg-indigo-50 px-3 py-1 text-sm font-medium text-indigo-700">
                <span className="h-2 w-2 rounded-full bg-indigo-500"></span>
                <span>Crew Ops Control Room</span>
              </div>
              <h1 className="mt-3 text-3xl font-bold text-indigo-800">CrewAI Asset Manager</h1>
              <p className="text-gray-600 mt-2 max-w-3xl">
                Manage every agent, tool, toolset, crew, and configuration from a single pane of glass.
                Curate orchestration assets, launch runs, and keep configuration drift visible.
              </p>
            </div>
            <div className="w-full md:w-96">
              <SearchBar onSearch={setSearchQuery} />
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-10">
        <div className="flex flex-col lg:flex-row gap-8">
          <div className="lg:w-1/4 space-y-6">
            <Navigation
              activeSection={activeSection}
              setActiveSection={setActiveSection}
            />

            <div className="bg-white rounded-lg shadow-md p-6">
              <h3 className="text-lg font-semibold text-gray-800 mb-4">Control Room Stats</h3>
              <div className="space-y-4">
                {stats.map((stat) => (
                  <div key={stat.label} className="flex justify-between">
                    <span className="text-gray-600">{stat.label}</span>
                    <span className="font-semibold text-gray-900">{stat.value}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6">
              <h3 className="text-lg font-semibold text-gray-800 mb-4">Operational Reads</h3>
              <div className="space-y-4">
                {operationalReads.map((item) => (
                  <div key={item.title} className="border-l-4 border-indigo-500 pl-3">
                    <p className="text-sm uppercase text-indigo-600 font-semibold">{item.type}</p>
                    <p className="font-semibold text-gray-900">{item.title}</p>
                    <p className="text-gray-600 text-sm">{item.detail}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="lg:w-3/4 space-y-6">
            <div className="bg-white rounded-lg shadow-md overflow-hidden">
              <div className="border-b border-gray-200 px-6 py-5 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
                <div>
                  <h2 className="text-xl font-semibold text-gray-800">{sectionDetails[activeSection].title}</h2>
                  <p className="text-gray-600 mt-1">{sectionDetails[activeSection].description}</p>
                </div>
                <div className="flex gap-2">
                  <button className="rounded-md border border-indigo-200 bg-indigo-50 px-3 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-100">
                    Add new
                  </button>
                  <button className="rounded-md border border-green-200 bg-green-50 px-3 py-2 text-sm font-medium text-green-700 hover:bg-green-100">
                    Launch run
                  </button>
                </div>
              </div>

              <div className="p-6">
                <FileListing
                  items={resourceData[activeSection]}
                  config={resourceConfigs[activeSection]}
                  searchQuery={searchQuery}
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-white rounded-lg shadow-md p-5">
                <p className="text-sm uppercase text-gray-500">Environments</p>
                <h4 className="text-2xl font-bold text-gray-900 mt-2">prod / preprod / staging</h4>
                <p className="text-sm text-gray-600 mt-1">Config drift checks are enabled for live crews.</p>
              </div>
              <div className="bg-white rounded-lg shadow-md p-5">
                <p className="text-sm uppercase text-gray-500">Run Library</p>
                <h4 className="text-2xl font-bold text-gray-900 mt-2">Templates + Playbooks</h4>
                <p className="text-sm text-gray-600 mt-1">Reuse run presets per crew, toolset, or agent.</p>
              </div>
              <div className="bg-white rounded-lg shadow-md p-5">
                <p className="text-sm uppercase text-gray-500">Storage</p>
                <h4 className="text-2xl font-bold text-gray-900 mt-2">Backed by repo + GitHub Actions</h4>
                <p className="text-sm text-gray-600 mt-1">All assets remain versioned in the Knowledge Base.</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <footer className="bg-gray-800 text-white py-8 mt-12">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="mb-4 md:mb-0">
              <h3 className="text-xl font-bold">CrewAI Asset Manager</h3>
              <p className="text-gray-400 mt-1">Operate, store, and launch your crews with confidence.</p>
            </div>
            <div className="flex space-x-6">
              <a href="#" className="text-gray-300 hover:text-white transition duration-200">Documentation</a>
              <a href="#" className="text-gray-300 hover:text-white transition duration-200">GitHub</a>
              <a href="#" className="text-gray-300 hover:text-white transition duration-200">Support</a>
            </div>
          </div>
          <div className="border-t border-gray-700 mt-6 pt-6 text-center text-gray-400">
            <p>&copy; 2025 CrewAI Asset Manager. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
