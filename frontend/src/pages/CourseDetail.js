import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { apiService } from '../services/api';
import LoadingSpinner from '../components/LoadingSpinner';
import ProgressBar from '../components/ProgressBar';
import { 
  ArrowLeft, 
  Users, 
  BookOpen, 
  Target, 
  Calendar,
  Mail,
  User,
  CheckCircle,
  Clock,
  Filter,
  Search
} from 'lucide-react';

const CourseDetail = () => {
  const { courseId } = useParams();
  const navigate = useNavigate();
  const [courseData, setCourseData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('progression');
  const [filterBy, setFilterBy] = useState('all');

  useEffect(() => {
    loadCourseData();
  }, [courseId]);

  const loadCourseData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const data = await apiService.getCourseParticipants(courseId);
      setCourseData(data);
    } catch (err) {
      setError('Failed to load course data: ' + err.message);
      console.error('Course detail error:', err);
    } finally {
      setLoading(false);
    }
  };

  const getFilteredAndSortedParticipants = () => {
    if (!courseData?.participants) return [];
    
    let filtered = courseData.participants;
    
    // Filter by search term
    if (searchTerm) {
      const search = searchTerm.toLowerCase();
      filtered = filtered.filter(participant => 
        participant.nom.toLowerCase().includes(search) ||
        participant.prenom.toLowerCase().includes(search) ||
        participant.email.toLowerCase().includes(search)
      );
    }
    
    // Filter by status
    if (filterBy === 'completed') {
      filtered = filtered.filter(p => p.overall_progression >= 100);
    } else if (filterBy === 'in-progress') {
      filtered = filtered.filter(p => p.overall_progression > 0 && p.overall_progression < 100);
    } else if (filterBy === 'not-started') {
      filtered = filtered.filter(p => p.overall_progression === 0);
    }
    
    // Sort participants
    return filtered.sort((a, b) => {
      switch (sortBy) {
        case 'progression':
          return b.overall_progression - a.overall_progression;
        case 'name':
          return `${a.nom} ${a.prenom}`.localeCompare(`${b.nom} ${b.prenom}`);
        case 'modules':
          return b.completed_modules - a.completed_modules;
        case 'activity':
          if (!a.last_activity && !b.last_activity) return 0;
          if (!a.last_activity) return 1;
          if (!b.last_activity) return -1;
          return new Date(b.last_activity) - new Date(a.last_activity);
        default:
          return 0;
      }
    });
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'Never';
    return new Date(dateString).toLocaleDateString();
  };

  const getProgressBadge = (progression) => {
    if (progression >= 100) {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
        <CheckCircle size={12} className="mr-1" />
        Completed
      </span>;
    } else if (progression > 0) {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
        <Clock size={12} className="mr-1" />
        In Progress
      </span>;
    } else {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
        <Clock size={12} className="mr-1" />
        Not Started
      </span>;
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="large" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-500 text-xl mb-4">⚠️ Error</div>
          <p className="text-gray-600 mb-4">{error}</p>
          <button 
            onClick={loadCourseData}
            className="bg-primary-500 text-white px-4 py-2 rounded-lg hover:bg-primary-600 mr-2"
          >
            Retry
          </button>
          <button 
            onClick={() => navigate('/')}
            className="bg-gray-500 text-white px-4 py-2 rounded-lg hover:bg-gray-600"
          >
            Back to Dashboard
          </button>
        </div>
      </div>
    );
  }

  const filteredParticipants = getFilteredAndSortedParticipants();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <button
                onClick={() => navigate('/')}
                className="mr-4 p-2 text-gray-400 hover:text-gray-600"
              >
                <ArrowLeft size={20} />
              </button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  {courseData?.course?.intitule}
                </h1>
                <p className="text-gray-600 mt-1">Course participants and progress</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Course Summary */}
        {courseData?.summary && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div className="bg-white rounded-lg border border-gray-200 p-6">
              <div className="flex items-center">
                <div className="p-3 rounded-full bg-blue-50 text-blue-600 border border-blue-200">
                  <Users size={24} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Total Participants</p>
                  <p className="text-2xl font-bold text-gray-900">{courseData.summary.total_participants}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white rounded-lg border border-gray-200 p-6">
              <div className="flex items-center">
                <div className="p-3 rounded-full bg-green-50 text-green-600 border border-green-200">
                  <CheckCircle size={24} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Completed</p>
                  <p className="text-2xl font-bold text-gray-900">{courseData.summary.completed_participants}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white rounded-lg border border-gray-200 p-6">
              <div className="flex items-center">
                <div className="p-3 rounded-full bg-purple-50 text-purple-600 border border-purple-200">
                  <Target size={24} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Average Progress</p>
                  <p className="text-2xl font-bold text-gray-900">
                    {courseData.summary.average_progression.toFixed(1)}%
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Participants Section */}
        <div className="bg-white rounded-lg border border-gray-200">
          {/* Participants Header */}
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">Participants</h2>
                <p className="text-sm text-gray-600">
                  {filteredParticipants.length} of {courseData?.participants?.length || 0} participants
                </p>
              </div>
              
              {/* Search and Filters */}
              <div className="flex flex-col sm:flex-row items-start sm:items-center space-y-2 sm:space-y-0 sm:space-x-4 mt-4 lg:mt-0">
                {/* Search */}
                <div className="relative">
                  <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                  <input
                    type="text"
                    placeholder="Search participants..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10 pr-4 py-2 border border-gray-300 rounded-md text-sm w-64"
                  />
                </div>
                
                {/* Filter */}
                <div className="flex items-center space-x-2">
                  <Filter size={16} className="text-gray-500" />
                  <select
                    value={filterBy}
                    onChange={(e) => setFilterBy(e.target.value)}
                    className="border border-gray-300 rounded-md px-3 py-2 text-sm"
                  >
                    <option value="all">All Status</option>
                    <option value="completed">Completed</option>
                    <option value="in-progress">In Progress</option>
                    <option value="not-started">Not Started</option>
                  </select>
                </div>
                
                {/* Sort */}
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                  className="border border-gray-300 rounded-md px-3 py-2 text-sm"
                >
                  <option value="progression">Sort by Progress</option>
                  <option value="name">Sort by Name</option>
                  <option value="modules">Sort by Modules</option>
                  <option value="activity">Sort by Activity</option>
                </select>
              </div>
            </div>
          </div>

          {/* Participants List */}
          <div className="divide-y divide-gray-200">
            {filteredParticipants.length === 0 ? (
              <div className="px-6 py-12 text-center">
                <Users size={48} className="mx-auto text-gray-400 mb-4" />
                <p className="text-gray-500">
                  {searchTerm || filterBy !== 'all' 
                    ? 'No participants found matching your criteria'
                    : 'No participants in this course'
                  }
                </p>
              </div>
            ) : (
              filteredParticipants.map((participant) => (
                <div key={participant.id} className="px-6 py-4 hover:bg-gray-50">
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      {/* Participant Info */}
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center">
                          <div className="flex-shrink-0">
                            <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
                              <User size={16} className="text-primary-600" />
                            </div>
                          </div>
                          <div className="ml-3">
                            <h3 className="text-sm font-medium text-gray-900">
                              {participant.prenom} {participant.nom}
                            </h3>
                            <div className="flex items-center text-sm text-gray-600">
                              <Mail size={12} className="mr-1" />
                              {participant.email}
                            </div>
                          </div>
                        </div>
                        {getProgressBadge(participant.overall_progression)}
                      </div>
                      
                      {/* Stats Row */}
                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-3">
                        <div className="flex items-center text-sm text-gray-600">
                          <BookOpen size={14} className="mr-1" />
                          {participant.completed_modules}/{participant.total_modules} modules completed
                        </div>
                        <div className="flex items-center text-sm text-gray-600">
                          <Target size={14} className="mr-1" />
                          {participant.overall_progression.toFixed(1)}% progress
                        </div>
                        <div className="flex items-center text-sm text-gray-600">
                          <Calendar size={14} className="mr-1" />
                          Last activity: {formatDate(participant.last_activity)}
                        </div>
                      </div>
                      
                      {/* Progress Bar */}
                      <ProgressBar 
                        percentage={participant.overall_progression} 
                        size="small"
                        className="max-w-md"
                      />
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default CourseDetail; 