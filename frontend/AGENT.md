# Frontend Agent Guide

This document provides guidelines for AI agents working on the Dendreo Progression frontend.

## Tech Stack

- **React 18** - UI framework
- **React Router 6** - Client-side routing
- **React Query (@tanstack/react-query v5)** - Data fetching and caching
- **i18next / react-i18next** - Internationalization (French default)
- **Tailwind CSS** - Utility-first styling
- **Axios** - HTTP client
- **Lucide React** - Icon library

## Directory Structure

```
frontend/src/
├── components/       # Reusable UI components
│   ├── Layout.js     # Main layout wrapper with sidebar
│   ├── Sidebar.js    # Navigation sidebar
│   ├── ProgressBar.js
│   ├── Pagination.js
│   └── ...
├── hooks/            # Custom React hooks
│   ├── useQuery.js   # React Query hooks for all data fetching
│   └── useLanguageEffect.js
├── i18n/             # Internationalization
│   ├── index.js      # i18n configuration
│   └── locales/
│       ├── fr.json   # French translations (default)
│       └── en.json   # English translations
├── pages/            # Page components (one per route)
│   ├── Dashboard.js
│   ├── Participants.js
│   ├── ParticipantDetail.js
│   ├── CourseDetail.js
│   ├── Account.js      # Account management with password change
│   ├── InactiveManagement.js  # Inactive participants tracking & management
│   └── Settings.js     # Placeholder
├── services/
│   └── api.js        # Axios API service layer
├── utils/
│   └── timeUtils.js  # Utility functions
├── App.js            # Routes and app structure
├── queryClient.js    # React Query configuration and query keys
└── index.js          # Entry point
```

## Key Patterns

### Data Fetching with React Query

All API calls go through React Query hooks defined in `hooks/useQuery.js`.

```javascript
// Using a hook in a component
import { useParticipants, usePrefetchQueries } from '../hooks/useQuery';

const { data, isLoading, error, refetch, isFetching } = useParticipants(page, pageSize, searchTerm);
```

**Query keys** are centralized in `queryClient.js`:
```javascript
export const queryKeys = {
  dashboardStats: ['dashboard', 'stats'],
  courses: ['courses'],
  participants: ['participants'],
  participantDetails: (id) => ['participants', id],
  // ...
};
```

**Adding a new API endpoint:**
1. Add the API call in `services/api.js`
2. Create a hook in `hooks/useQuery.js`
3. Add query key in `queryClient.js`

### State Persistence with localStorage

UI state that should persist across sessions is stored in localStorage:

```javascript
const [sidebarCollapsed, setSidebarCollapsed] = useState(() => {
  const cached = localStorage.getItem('sidebarCollapsed');
  return cached ? JSON.parse(cached) : false;
});

useEffect(() => {
  localStorage.setItem('sidebarCollapsed', JSON.stringify(sidebarCollapsed));
}, [sidebarCollapsed]);
```

Common persisted states:
- `sidebarCollapsed` - Sidebar expanded/collapsed
- `participantSortDirection` - Sort direction (asc/desc)
- `participantStatusFilters` - Status filter checkboxes
- `participantInactivityDays` - Inactivity filter days
- `inactiveManagement.*` - InactiveManagement page filters and settings:
  - `groupByCourse` - Group by ADF toggle
  - `sortBy` / `sortDirection` - Sort preferences
  - `statusFilter` - Status filter checkboxes (at_risk, stalled, long_inactive)
  - `showActiveOnly` / `activeDaysThreshold` - Active users filter
  - `selectedADFs` - Selected formation (ADF) filter
- `i18nextLng` - Selected language

### Internationalization (i18n)

All user-facing text must use translation keys. French is the default language.

```javascript
import { useTranslation } from 'react-i18next';

const { t } = useTranslation();

// Simple translation
<h1>{t('dashboard.title')}</h1>

// With interpolation
<p>{t('pagination.showing', { start: 1, end: 10, total: 100 })}</p>
```

**Adding translations:**
1. Add key to both `i18n/locales/fr.json` and `i18n/locales/en.json`
2. Group keys by feature/page (e.g., `dashboard.*`, `participants.*`, `sidebar.*`)

**Translation structure:**
```json
{
  "common": { "error": "Erreur", "loading": "Chargement..." },
  "dashboard": { "title": "Tableau de bord", ... },
  "participants": { "title": "Participants", ... },
  "sidebar": { "dashboard": "Tableau de bord", ... }
}
```

### Component Structure

**Pages** handle:
- Data fetching via hooks
- Local state management
- Business logic
- Layout structure

**Components** are:
- Reusable UI elements
- Receive data via props
- Minimal internal state

### Routing

Routes are defined in `App.js` wrapped by `Layout`:

```javascript
<Layout>
  <Routes>
    <Route path="/" element={<Dashboard />} />
    <Route path="/courses/:courseId" element={<CourseDetail />} />
    <Route path="/participants" element={<Participants />} />
    <Route path="/participants/:participantId" element={<ParticipantDetail />} />
    // ...
  </Routes>
</Layout>
```

**Adding a new route:**
1. Create page component in `pages/`
2. Add route in `App.js`
3. Add sidebar navigation item in `components/Sidebar.js` (set `active: true` when ready)
4. Add translations for the page

### Styling with Tailwind CSS

Use Tailwind utility classes directly in JSX:

```javascript
<div className="min-h-screen bg-gray-50">
  <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
```

Common patterns:
- `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8` - Centered container
- `bg-white rounded-lg border border-gray-200` - Card styling
- `text-gray-900` / `text-gray-600` - Text hierarchy
- `hover:bg-gray-50` - Hover states
- `transition-colors` / `transition-all duration-300` - Transitions
- `primary-500`, `primary-600` - Brand colors (defined in Tailwind config)

## API Integration

API service in `services/api.js`:

```javascript
export const apiService = {
  async getAllParticipants(page, pageSize, searchTerm) {
    const response = await api.get('/participants/', { params: { skip, limit, search } });
    return response.data;
  },
  // ...
};
```

Backend API base URL: `REACT_APP_API_URL` env variable or `http://localhost:8000/api`

## Common Patterns

### Loading States
```javascript
if (loading) {
  return <LoadingSpinner size="large" />;
}
```

### Error Handling
```javascript
if (error) {
  return (
    <div className="text-red-500">
      {t('common.error')}: {error.message}
    </div>
  );
}
```

### Refresh Button
```javascript
<button onClick={refetch} disabled={isFetching}>
  <RefreshCw className={isFetching ? 'animate-spin' : ''} />
  {isFetching ? t('common.refreshing') : t('common.refresh')}
</button>
```

### Filtering and Sorting
Components typically use local state for filters and compute filtered/sorted data:

```javascript
const [sortBy, setSortBy] = useState('progression');
const [sortDirection, setSortDirection] = useState('desc');

const getFilteredAndSortedData = () => {
  let filtered = data;
  // Apply filters...
  const sortMultiplier = sortDirection === 'asc' ? 1 : -1;
  return filtered.sort((a, b) => comparison * sortMultiplier);
};
```

## Placeholder Pages

Pages marked as "coming soon" use a standard placeholder template:

```javascript
const PlaceholderPage = () => {
  const { t } = useTranslation();
  return (
    <div className="bg-white rounded-lg border p-12 text-center">
      <Construction size={64} className="mx-auto text-gray-400 mb-4" />
      <h2>{t('common.comingSoon')}</h2>
      <p>{t('pageName.placeholder')}</p>
    </div>
  );
};
```

## Development Commands

```bash
npm start          # Start development server (port 3000)
npm run build      # Production build
npm test           # Run tests
npm install --legacy-peer-deps  # Install dependencies
```
