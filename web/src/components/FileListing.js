const statusColors = {
  live: 'bg-green-100 text-green-800',
  ready: 'bg-indigo-100 text-indigo-800',
  maintenance: 'bg-amber-100 text-amber-800',
  default: 'bg-gray-100 text-gray-800',
};

const toneButtonStyles = {
  indigo: 'text-indigo-700 bg-indigo-50 hover:bg-indigo-100 border border-indigo-200',
  green: 'text-green-700 bg-green-50 hover:bg-green-100 border border-green-200',
};

const formatValue = (value) => {
  if (Array.isArray(value)) {
    return (
      <div className="flex flex-wrap gap-1">
        {value.map((entry) => (
          <span key={entry} className="rounded-full bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700">
            {entry}
          </span>
        ))}
      </div>
    );
  }

  if (typeof value === 'boolean') {
    return value ? 'Enabled' : 'Disabled';
  }

  return value || '—';
};

export default function FileListing({ items, config, searchQuery }) {
  const searchableFields = config?.searchFields || ['name'];
  const normalizedQuery = searchQuery.toLowerCase();

  const filteredItems = items.filter((item) =>
    searchableFields.some((field) =>
      String(item[field] || '')
        .toLowerCase()
        .includes(normalizedQuery)
    )
  );

  return (
    <div>
      {filteredItems.length === 0 ? (
        <div className="text-center py-12">
          <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <h3 className="mt-2 text-lg font-medium text-gray-900">No assets found</h3>
          <p className="mt-1 text-gray-500">Refine your search or add a new entry.</p>
        </div>
      ) : (
        <div className="overflow-hidden shadow ring-1 ring-black ring-opacity-5 rounded-lg">
          <table className="min-w-full divide-y divide-gray-300">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">
                  Name
                </th>
                {config?.columns?.map((column) => (
                  <th key={column.key} scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                    {column.label}
                  </th>
                ))}
                <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-6">
                  <span className="sr-only">Actions</span>
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 bg-white">
              {filteredItems.map((item) => (
                <tr key={item.name} className="hover:bg-gray-50">
                  <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-semibold text-gray-900 sm:pl-6">
                    {item.name}
                  </td>
                  {config?.columns?.map((column) => {
                    let value = item[column.key];

                    if (column.type === 'status') {
                      const color = statusColors[value] || statusColors.default;
                      value = (
                        <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${color}`}>
                          {value}
                        </span>
                      );
                    } else {
                      value = formatValue(value);
                    }

                    return (
                      <td key={column.key} className="whitespace-nowrap px-3 py-4 text-sm text-gray-700">
                        {value}
                      </td>
                    );
                  })}
                  <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                    <div className="flex flex-wrap justify-end gap-2">
                      {config?.actions?.map((action) => (
                        <button
                          key={action.label}
                          className={`rounded-md px-3 py-1 text-xs font-semibold transition duration-150 ${
                            toneButtonStyles[action.tone] || toneButtonStyles.indigo
                          }`}
                        >
                          {action.label}
                        </button>
                      ))}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
