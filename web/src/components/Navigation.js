export default function Navigation({ activeSection, setActiveSection }) {
  const sections = [
    { id: 'agents', name: 'Agents', icon: 'M12 6v6m0 0v6m0-6h6m-6 0H6' },
    { id: 'tools', name: 'Tools', icon: 'M13 16h-1v-4h-1m4 0h3m-6 4H6m0 0V7a2 2 0 012-2h3m-5 11h.01' },
    { id: 'toolsets', name: 'Toolsets', icon: 'M7 8h10M7 12h10m-7 4h7' },
    { id: 'crews', name: 'Crews', icon: 'M17 20h5V4a2 2 0 00-2-2H6a2 2 0 00-2 2v16h5' },
    { id: 'crewConfigs', name: 'Crew Configs', icon: 'M9.75 3a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 009.75 21h4.5A2.25 2.25 0 0016.5 18.75V5.25A2.25 2.25 0 0014.25 3h-4.5z' },
  ];

  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      <div className="p-4 border-b border-gray-200">
        <h2 className="text-lg font-semibold text-gray-800">Asset Types</h2>
        <p className="text-sm text-gray-600 mt-1">Navigate through the CrewAI catalog.</p>
      </div>
      <nav>
        <ul>
          {sections.map((section) => (
            <li key={section.id}>
              <button
                onClick={() => setActiveSection(section.id)}
                className={`w-full text-left px-4 py-3 flex items-center transition duration-200 ${
                  activeSection === section.id
                    ? 'bg-indigo-100 text-indigo-700 border-l-4 border-indigo-700'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
              >
                <svg className="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d={section.icon}></path>
                </svg>
                {section.name}
              </button>
            </li>
          ))}
        </ul>
      </nav>
    </div>
  );
}
