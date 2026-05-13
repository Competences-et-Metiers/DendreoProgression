import React, { useEffect } from 'react';
import { X } from 'lucide-react';

const NoteDetailModal = ({ text, title, onClose }) => {
  useEffect(() => {
    const onKey = (e) => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('keydown', onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = prev;
    };
  }, [onClose]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center" onClick={(e) => e.stopPropagation()}>
      <div className="fixed inset-0 bg-black/50" onClick={onClose} />
      <div className="relative bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-gray-200 dark:border-slate-700 max-w-2xl w-full mx-4 max-h-[85vh] flex flex-col">
        <div className="flex items-center justify-between p-3 border-b border-gray-200 dark:border-slate-700">
          {title ? (
            <span className="text-sm font-semibold text-gray-700 dark:text-gray-200">{title}</span>
          ) : <span />}
          <button
            type="button"
            onClick={onClose}
            className="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
          >
            <X size={16} />
          </button>
        </div>
        <div className="p-4 overflow-y-auto">
          <p className="text-sm text-gray-700 dark:text-gray-200 whitespace-pre-line break-words">
            {text}
          </p>
        </div>
      </div>
    </div>
  );
};

export default NoteDetailModal;
