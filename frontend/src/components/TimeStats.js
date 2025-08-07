import React, { useState, useEffect } from 'react';
import { apiService } from '../services/api';
import { formatTimeSpent, formatTimeSpentCompact, formatTimeSpentInHours } from '../utils/timeUtils';
import LoadingSpinner from './LoadingSpinner';

const TimeStats = ({ courseId }) => {
  const [timeStats, setTimeStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchTimeStats = async () => {
      try {
        setLoading(true);
        const data = await apiService.getCourseTimeStats(courseId);
        setTimeStats(data);
        setError(null);
      } catch (err) {
        setError('Failed to load time statistics');
        console.error('Error fetching time stats:', err);
      } finally {
        setLoading(false);
      }
    };

    if (courseId) {
      fetchTimeStats();
    }
  }, [courseId]);

  if (loading) {
    return <LoadingSpinner />;
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4">
        <p className="text-red-600">{error}</p>
      </div>
    );
  }

  if (!timeStats) {
    return null;
  }

  const { course, time_statistics, participant_time_data } = timeStats;

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <h3 className="text-xl font-semibold text-gray-800 mb-4">
        Time Statistics - {course.intitule}
      </h3>

      {/* Summary Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-blue-50 rounded-lg p-4">
          <h4 className="text-sm font-medium text-blue-600">Total Modules</h4>
          <p className="text-2xl font-bold text-blue-800">{time_statistics.total_modules}</p>
        </div>
        
        <div className="bg-green-50 rounded-lg p-4">
          <h4 className="text-sm font-medium text-green-600">Total Time Spent</h4>
          <p className="text-2xl font-bold text-green-800">
            {formatTimeSpentInHours(time_statistics.total_time_spent)}
          </p>
          <p className="text-sm text-green-600">
            {formatTimeSpent(time_statistics.total_time_spent)}
          </p>
        </div>
        
        <div className="bg-purple-50 rounded-lg p-4">
          <h4 className="text-sm font-medium text-purple-600">Average Time</h4>
          <p className="text-2xl font-bold text-purple-800">
            {formatTimeSpentInHours(time_statistics.average_time_spent)}
          </p>
          <p className="text-sm text-purple-600">
            {formatTimeSpentCompact(time_statistics.average_time_spent)}
          </p>
        </div>
        
        <div className="bg-orange-50 rounded-lg p-4">
          <h4 className="text-sm font-medium text-orange-600">Active Participants</h4>
          <p className="text-2xl font-bold text-orange-800">
            {participant_time_data.filter(p => p.total_time_spent > 0).length}
          </p>
        </div>
      </div>

      {/* Participant Time Data */}
      <div className="mt-6">
        <h4 className="text-lg font-semibold text-gray-700 mb-4">Participant Time Details</h4>
        
        {participant_time_data.length === 0 ? (
          <p className="text-gray-500 text-center py-4">No time data available for participants</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Participant
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total Time Spent
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Avg. Progression
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Modules
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Started
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Completed
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {participant_time_data.map((data, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {data.participant_name}
                        </div>
                        <div className="text-sm text-gray-500">
                          {data.participant_email}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        {formatTimeSpentInHours(data.total_time_spent)}
                      </span>
                      <div className="text-xs text-gray-500 mt-1">
                        {formatTimeSpent(data.total_time_spent)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="w-16 bg-gray-200 rounded-full h-2 mr-2">
                          <div 
                            className="bg-blue-600 h-2 rounded-full" 
                            style={{ width: `${Math.min(data.average_progression, 100)}%` }}
                          ></div>
                        </div>
                        <span className="text-sm text-gray-900">{data.average_progression}%</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                        {data.modules_count} modules
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {data.started_at ? new Date(data.started_at).toLocaleDateString() : '-'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {data.completed_at ? new Date(data.completed_at).toLocaleDateString() : '-'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default TimeStats; 