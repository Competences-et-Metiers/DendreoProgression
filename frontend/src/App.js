import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { queryClient } from './queryClient';
import Dashboard from './pages/Dashboard';
import CourseDetail from './pages/CourseDetail';
import Participants from './pages/Participants';
import ParticipantDetail from './pages/ParticipantDetail';

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <div className="App">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/courses/:courseId" element={<CourseDetail />} />
            <Route path="/participants" element={<Participants />} />
            <Route path="/participants/:participantId" element={<ParticipantDetail />} />
          </Routes>
        </div>
      </Router>
      {/* React Query DevTools - only shows in development */}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}

export default App; 