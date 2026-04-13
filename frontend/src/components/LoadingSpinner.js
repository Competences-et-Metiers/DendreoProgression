import React from 'react';
import { clsx } from 'clsx';
import { Loader2 } from 'lucide-react';

const LoadingSpinner = ({ size = 'medium', className = '', fullPage = true }) => {
  const iconSize = {
    small: 16,
    medium: 32,
    large: 48,
  };

  return (
    <div className={clsx(
      'flex justify-center items-center',
      fullPage && 'min-h-screen',
      className
    )}>
      <Loader2
        size={iconSize[size]}
        className="animate-spin text-primary-600 dark:text-primary-400"
      />
    </div>
  );
};

export default LoadingSpinner;
