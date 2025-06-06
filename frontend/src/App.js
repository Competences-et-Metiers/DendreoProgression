import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import CourseDetail from './pages/CourseDetail';

function App() {
  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/courses/:courseId" element={<CourseDetail />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App; 