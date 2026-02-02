# Dendreo Progression Dashboard

A modern React frontend application for tracking course progression and participant engagement in the Dendreo learning management system.

## Features

- **Dashboard Overview**: View statistics for all courses, participants, and overall progress
- **Course Management**: Browse and filter courses by completion status and other criteria  
- **Participant Tracking**: View detailed participant information for each course
- **Progress Visualization**: Interactive progress bars and completion indicators
- **Search & Filter**: Advanced filtering and sorting capabilities
- **Responsive Design**: Mobile-friendly interface built with Tailwind CSS
- **Internationalization**: Multi-language support with French as default language

## Screenshots

### Dashboard
- Overview statistics cards showing total courses, participants, and completion rates
- Course list with progress indicators and participant counts
- Filtering and sorting options

### Course Detail
- Course-specific participant list 
- Individual participant progress tracking
- Module completion status
- Search and filter participants

## Prerequisites

- Node.js (version 14 or higher)
- npm or yarn package manager
- Running Dendreo Progression API backend on port 8000

## Installation

1. Clone the repository and navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install --legacy-peer-deps
```

3. (Optional) Create a `.env` file to configure the API URL:
```bash
REACT_APP_API_URL=http://192.168.254.24:8000/api
```

## Running the Application

### Development Mode
```bash
npm start
```

The application will open in your browser at `http://192.168.254.24:3000`.

The page will reload when you make edits, and you'll see any lint errors in the console.

### Production Build
```bash
npm run build
```

Builds the app for production to the `build` folder. The build is minified and the filenames include hashes for optimal performance.

## API Integration

The frontend communicates with the FastAPI backend through these endpoints:

- `GET /api/courses/stats` - Dashboard statistics
- `GET /api/courses/courses` - List all courses  
- `GET /api/courses/courses/{id}/participants` - Course participants
- `GET /api/courses/participants/{id}` - Participant details

## Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── LoadingSpinner.js
│   ├── ProgressBar.js
│   └── StatCard.js
├── pages/              # Main page components
│   ├── Dashboard.js
│   └── CourseDetail.js
├── services/           # API service layer
│   └── api.js
├── App.js             # Main application component
├── index.js           # Application entry point
└── index.css          # Global styles
```

## Technologies Used

- **React 18** - UI framework
- **React Router** - Client-side routing
- **Axios** - HTTP client for API calls
- **Tailwind CSS** - Utility-first CSS framework
- **Lucide React** - Icon library
- **clsx** - Utility for conditional CSS classes
- **react-i18next** - Internationalization framework

## Available Scripts

- `npm start` - Runs the app in development mode
- `npm test` - Launches the test runner
- `npm run build` - Builds the app for production
- `npm run eject` - Ejects from Create React App (one-way operation)

## Customization

### Styling
The application uses Tailwind CSS for styling. You can customize the design by:
- Modifying the Tailwind configuration in `public/index.html`
- Adding custom CSS classes in `src/index.css`
- Adjusting component-specific styles

### API Configuration  
Update the API base URL in `src/services/api.js` or set the `REACT_APP_API_URL` environment variable.

### Language Support
The application supports multiple languages with French as the default:

- **French (fr)** - Default language
- **English (en)** - Secondary language

Users can switch languages using the language selector in the top-right corner of the dashboard. The language preference is saved in localStorage and persists across sessions.

#### Adding New Languages
To add a new language:

1. Create a new translation file in `src/i18n/locales/[language-code].json`
2. Add the language to the `languages` array in `src/components/LanguageSelector.js`
3. Update the i18n configuration in `src/i18n/index.js`

## Browser Support

This application supports all modern browsers including:
- Chrome (latest)
- Firefox (latest) 
- Safari (latest)
- Edge (latest)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is private and proprietary. 