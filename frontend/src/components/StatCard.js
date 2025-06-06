import React from 'react';
import { clsx } from 'clsx';

const StatCard = ({ title, value, icon: Icon, color = 'blue', trend }) => {
  const colorClasses = {
    blue: 'bg-blue-50 text-blue-600 border-blue-200',
    green: 'bg-green-50 text-green-600 border-green-200',
    yellow: 'bg-yellow-50 text-yellow-600 border-yellow-200',
    red: 'bg-red-50 text-red-600 border-red-200',
    purple: 'bg-purple-50 text-purple-600 border-purple-200',
    indigo: 'bg-indigo-50 text-indigo-600 border-indigo-200'
  };

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6 card-hover">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
          {trend && (
            <p className={clsx(
              'text-sm mt-1',
              trend.isPositive ? 'text-green-600' : 'text-red-600'
            )}>
              {trend.isPositive ? '↗' : '↘'} {trend.value}
            </p>
          )}
        </div>
        <div className={clsx(
          'p-3 rounded-full border',
          colorClasses[color]
        )}>
          <Icon size={24} />
        </div>
      </div>
    </div>
  );
};

export default StatCard; 