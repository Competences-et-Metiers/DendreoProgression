import React from 'react';
import { clsx } from 'clsx';

const ProgressBar = ({
  percentage,
  className = '',
  showPercentage = true,
  size = 'medium',
  color = 'primary'
}) => {
  const sizeClasses = {
    small: 'h-2',
    medium: 'h-3',
    large: 'h-4'
  };

  const colorClasses = {
    primary: 'bg-blue-500',
    green: 'bg-green-500',
    yellow: 'bg-yellow-500',
    red: 'bg-red-500',
    blue: 'bg-blue-500'
  };

  const getProgressColor = (percentage) => {
    if (percentage >= 100) return 'green';
    if (percentage >= 75) return 'blue';
    if (percentage >= 50) return 'yellow';
    return 'red';
  };

  const progressColor = color === 'primary' ? getProgressColor(percentage) : color;

  return (
    <div className={clsx('w-full', className)}>
      <div className={clsx(
        'bg-gray-200 dark:bg-slate-700 rounded-full overflow-hidden',
        sizeClasses[size]
      )}>
        <div
          className={clsx(
            'progress-bar rounded-full h-full transition-all duration-300',
            colorClasses[progressColor]
          )}
          style={{ width: `${Math.min(percentage, 100)}%` }}
        />
      </div>
      {showPercentage && (
        <div className="flex justify-between items-center mt-1">
          <span className="text-xs text-gray-600 dark:text-gray-400">
            {percentage.toFixed(1)}%
          </span>
          {percentage >= 100 && (
            <span className="text-xs text-green-600 dark:text-green-400 font-medium">
              Completed
            </span>
          )}
        </div>
      )}
    </div>
  );
};

export default ProgressBar;
