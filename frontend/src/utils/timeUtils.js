/**
 * Utility functions for time formatting and calculations
 */

/**
 * Format seconds into a human-readable time string
 * @param {number} seconds - Time in seconds
 * @returns {string} Formatted time string (e.g., "2h 30m" or "45m" or "30s")
 */
export const formatTimeSpent = (seconds) => {
  if (!seconds || seconds === 0) {
    return '0s';
  }

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = seconds % 60;

  let result = '';
  
  if (hours > 0) {
    result += `${hours}h `;
  }
  
  if (minutes > 0 || hours > 0) {
    result += `${minutes}m `;
  }
  
  if (remainingSeconds > 0 && hours === 0 && minutes === 0) {
    result += `${remainingSeconds}s`;
  }

  return result.trim();
};

/**
 * Format time spent for display in a more compact way
 * @param {number} seconds - Time in seconds
 * @returns {string} Compact formatted time string
 */
export const formatTimeSpentCompact = (seconds) => {
  if (!seconds || seconds === 0) {
    return '0s';
  }

  if (seconds < 60) {
    return `${seconds}s`;
  }

  if (seconds < 3600) {
    const minutes = Math.floor(seconds / 60);
    return `${minutes}m`;
  }

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  
  if (minutes === 0) {
    return `${hours}h`;
  }
  
  return `${hours}h ${minutes}m`;
};

/**
 * Calculate average time spent from an array of time values
 * @param {number[]} timeValues - Array of time values in seconds
 * @returns {number} Average time in seconds
 */
export const calculateAverageTime = (timeValues) => {
  if (!timeValues || timeValues.length === 0) {
    return 0;
  }

  const validTimes = timeValues.filter(time => time && time > 0);
  if (validTimes.length === 0) {
    return 0;
  }

  return Math.round(validTimes.reduce((sum, time) => sum + time, 0) / validTimes.length);
};

/**
 * Get the total time spent from an array of time values
 * @param {number[]} timeValues - Array of time values in seconds
 * @returns {number} Total time in seconds
 */
export const calculateTotalTime = (timeValues) => {
  if (!timeValues || timeValues.length === 0) {
    return 0;
  }

  return timeValues.reduce((sum, time) => sum + (time || 0), 0);
};

/**
 * Format seconds into a verbose "Xh Ymin" string suitable for hover tooltips.
 * @param {number} seconds - Time in seconds
 * @returns {string} e.g. "1h 30min", "12h", "30min", "0min"
 */
export const formatHoursMinutes = (seconds) => {
  const total = Math.max(0, Math.round(seconds || 0));
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  if (hours === 0) return `${minutes}min`;
  if (minutes === 0) return `${hours}h`;
  return `${hours}h ${minutes}min`;
};

/**
 * Format seconds into hours with decimal places
 * @param {number} seconds - Time in seconds
 * @returns {string} Formatted time string (e.g., "14.4h" or "2.5h")
 */
export const formatTimeSpentInHours = (seconds) => {
  if (!seconds || seconds === 0) {
    return '0h';
  }

  const hours = seconds / 3600;
  
  // If less than 1 hour, show in minutes
  if (hours < 1) {
    const minutes = Math.floor(seconds / 60);
    return minutes > 0 ? `${minutes}m` : `${seconds}s`;
  }
  
  // If more than 10 hours, show whole hours
  if (hours >= 10) {
    return `${Math.round(hours)}h`;
  }
  
  // For 1-10 hours, show one decimal place
  return `${hours.toFixed(1)}h`;
}; 