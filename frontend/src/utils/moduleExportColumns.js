// Column metadata for the module export modal.
//
// Kept in its own module (free of jspdf/xlsx imports) so the modal can render its
// column picker without pulling ~800KB of PDF/Excel libraries into the main bundle.
// The generators in moduleExport.js are loaded on demand when the user exports.
export const MODULE_EXPORT_COLUMNS = [
  { key: 'name', weight: 1.6, excelWidth: 26, default: true },
  { key: 'email', weight: 2.2, excelWidth: 30, default: false },
  { key: 'course', weight: 2.0, excelWidth: 32, default: false, collapsible: true },
  { key: 'module', weight: 2.0, excelWidth: 32, default: false, collapsible: true },
  { key: 'deadline', weight: 1.0, excelWidth: 14, default: false, align: 'center' },
  { key: 'last_access', weight: 1.1, excelWidth: 18, default: true, align: 'center' },
  { key: 'progression', weight: 0.9, excelWidth: 14, default: true, align: 'center' },
];
