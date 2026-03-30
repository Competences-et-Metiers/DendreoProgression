import React from 'react';
import { clsx } from 'clsx';

const LoadingSpinner = ({ size = 'medium', className = '' }) => {
  const sizeClasses = {
    small: 'w-4 h-4',
    medium: 'w-8 h-8',
    large: 'w-12 h-12'
  };

  return (
    <div className={clsx('flex justify-center items-center', className)}>
      <div className={clsx(
        'animate-spin rounded-full border-2 border-gray-300 dark:border-slate-600 border-t-primary-500',
        sizeClasses[size]
      )} />
    </div>
  );
};

export default LoadingSpinner;
