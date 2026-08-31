import jsPDF from 'jspdf';
import 'jspdf-autotable';
import * as XLSX from 'xlsx';
import { MODULE_EXPORT_COLUMNS } from './moduleExportColumns';

const formatDate = (iso, lang, fallback = '-') => {
  if (!iso) return fallback;
  return new Date(iso).toLocaleDateString(lang === 'fr' ? 'fr-FR' : 'en-US', {
    day: '2-digit', month: '2-digit', year: 'numeric',
  });
};

// Re-exported so existing importers keep working; prefer importing from
// './moduleExportColumns' directly to avoid pulling in jspdf/xlsx.
export { MODULE_EXPORT_COLUMNS };

const getCellValue = (item, key, lang) => {
  const neverLabel = lang === 'fr' ? 'Jamais' : 'Never';
  switch (key) {
    case 'name': return `${item.prenom || ''} ${item.nom || ''}`.trim();
    case 'email': return item.email || '';
    case 'course': return item.course_title || '';
    case 'module': return item.module_intitule || '';
    case 'deadline': return formatDate(item.date_fin, lang);
    case 'last_access': return formatDate(item.last_access, lang, neverLabel);
    case 'progression': return `${(item.progression || 0).toFixed(1)}%`;
    default: return '';
  }
};

// Excel-friendly values: Date objects and numbers stay typed so Excel can sort/filter properly
const getExcelCellValue = (item, key, lang) => {
  const neverLabel = lang === 'fr' ? 'Jamais' : 'Never';
  switch (key) {
    case 'deadline': return item.date_fin ? new Date(item.date_fin) : '';
    case 'last_access': return item.last_access ? new Date(item.last_access) : neverLabel;
    case 'progression': return Number((item.progression || 0).toFixed(1)) / 100;
    default: return getCellValue(item, key, lang);
  }
};

// Shared column resolution: drop collapsible columns whose values are all identical
const resolveColumns = (columns, items, lang) => {
  const requested = columns
    .map((key) => MODULE_EXPORT_COLUMNS.find((c) => c.key === key))
    .filter(Boolean);
  const resolved = [];
  for (const col of requested) {
    if (col.collapsible && items.length >= 2) {
      const firstValue = getCellValue(items[0], col.key, lang);
      const allSame = firstValue && firstValue !== '-' &&
        items.every((it) => getCellValue(it, col.key, lang) === firstValue);
      if (allSame) continue;
    }
    resolved.push(col);
  }
  return resolved;
};

/**
 * Generate a PDF module report from filtered data.
 *
 * @param {Object} params
 * @param {Array}    params.items         Filtered module-participant rows
 * @param {string[]} params.columns       Ordered column keys to include (from MODULE_EXPORT_COLUMNS.key)
 * @param {string[]} params.activeFilters Human-readable descriptions of active filters
 * @param {Function} params.t             i18next translation function
 * @param {string}   params.lang          Current language code ('fr' or 'en')
 */
export const generateModuleReport = ({ items, columns, activeFilters, t, lang }) => {
  const doc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });
  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();
  const margin = 14;
  let yPos = 15;

  // Header
  doc.setFontSize(18);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(17, 24, 39);
  doc.text(t('moduleManagement.pdf.title'), margin, yPos);

  yPos += 7;
  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(107, 114, 128);
  doc.text(t('moduleManagement.pdf.subtitle'), margin, yPos);

  const dateStr = `${t('moduleManagement.pdf.generatedOn')} ${new Date().toLocaleDateString(
    lang === 'fr' ? 'fr-FR' : 'en-US',
    { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' }
  )}`;
  doc.setFontSize(9);
  doc.text(dateStr, pageWidth - margin, 15, { align: 'right' });

  yPos += 5;
  doc.setDrawColor(229, 231, 235);
  doc.setLineWidth(0.5);
  doc.line(margin, yPos, pageWidth - margin, yPos);

  // Totals box
  yPos += 8;
  doc.setFillColor(243, 244, 246);
  doc.roundedRect(margin, yPos, 60, 16, 2, 2, 'F');
  doc.setFontSize(9);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(107, 114, 128);
  doc.text(t('moduleManagement.pdf.totalRows'), margin + 30, yPos + 6, { align: 'center' });
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(17, 24, 39);
  doc.text(String(items.length), margin + 30, yPos + 13, { align: 'center' });
  yPos += 22;

  const selectedColumns = resolveColumns(columns, items, lang);

  // Active filters
  if (activeFilters && activeFilters.length > 0) {
    doc.setFontSize(8);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(107, 114, 128);
    doc.text(`${t('moduleManagement.pdf.appliedFilters')}:`, margin, yPos);
    yPos += 4;

    const maxTextWidth = pageWidth - 2 * margin;
    doc.setFont('helvetica', 'italic');
    activeFilters.forEach((filter) => {
      const lines = doc.splitTextToSize(`• ${filter}`, maxTextWidth);
      doc.text(lines, margin + 2, yPos);
      yPos += lines.length * 3.5;
    });
    yPos += 2;
  }

  // Distribute column widths proportionally across the available page width
  const availableWidth = pageWidth - 2 * margin;
  const totalWeight = selectedColumns.reduce((sum, c) => sum + (c.weight || 1), 0) || 1;

  const headers = selectedColumns.map((c) => t(`moduleManagement.pdf.col_${c.key}`));
  const body = items.map((item) => selectedColumns.map((c) => getCellValue(item, c.key, lang)));
  const columnStyles = {};
  selectedColumns.forEach((c, i) => {
    columnStyles[i] = { cellWidth: ((c.weight || 1) / totalWeight) * availableWidth };
    if (c.align) columnStyles[i].halign = c.align;
  });

  doc.autoTable({
    startY: yPos,
    head: [headers],
    body,
    margin: { left: margin, right: margin },
    styles: {
      fontSize: 8,
      cellPadding: 3,
      overflow: 'ellipsize',
      lineColor: [229, 231, 235],
      lineWidth: 0.2,
    },
    headStyles: {
      fillColor: [31, 41, 55],
      textColor: [255, 255, 255],
      fontSize: 9,
      fontStyle: 'bold',
    },
    alternateRowStyles: { fillColor: [249, 250, 251] },
    columnStyles,
    didDrawPage: (data) => {
      const pageCount = doc.internal.getNumberOfPages();
      doc.setFontSize(8);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(156, 163, 175);
      doc.text(
        `Page ${data.pageNumber} / ${pageCount}`,
        pageWidth - margin,
        pageHeight - 8,
        { align: 'right' }
      );
    },
  });

  const today = new Date().toISOString().split('T')[0];
  const filename = lang === 'fr'
    ? `rapport-modules-${today}.pdf`
    : `module-report-${today}.pdf`;
  doc.save(filename);
};

/**
 * Generate an .xlsx Excel workbook from filtered data.
 *
 * @param {Object} params
 * @param {Array}    params.items         Filtered module-participant rows
 * @param {string[]} params.columns       Ordered column keys to include
 * @param {string[]} params.activeFilters Human-readable descriptions of active filters
 * @param {Function} params.t             i18next translation function
 * @param {string}   params.lang          Current language code ('fr' or 'en')
 */
export const generateModuleExcel = ({ items, columns, activeFilters, t, lang }) => {
  const selectedColumns = resolveColumns(columns, items, lang);
  const headers = selectedColumns.map((c) => t(`moduleManagement.pdf.col_${c.key}`));

  const generatedOn = `${t('moduleManagement.pdf.generatedOn')} ${new Date().toLocaleDateString(
    lang === 'fr' ? 'fr-FR' : 'en-US',
    { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' }
  )}`;

  // Assemble sheet as array-of-arrays: title, date, blank, filters block, blank, headers, data
  const aoa = [];
  aoa.push([t('moduleManagement.pdf.title')]);
  aoa.push([generatedOn]);
  aoa.push([]);
  if (activeFilters && activeFilters.length > 0) {
    aoa.push([`${t('moduleManagement.pdf.appliedFilters')}:`]);
    activeFilters.forEach((f) => aoa.push([`• ${f}`]));
    aoa.push([]);
  }
  const headerRowIndex = aoa.length;
  aoa.push(headers);
  items.forEach((item) => {
    aoa.push(selectedColumns.map((c) => getExcelCellValue(item, c.key, lang)));
  });

  const ws = XLSX.utils.aoa_to_sheet(aoa);

  // Column widths
  ws['!cols'] = selectedColumns.map((c) => ({ wch: c.excelWidth || 18 }));

  // Apply cell number formats for dates and percentages
  const range = XLSX.utils.decode_range(ws['!ref']);
  for (let R = headerRowIndex + 1; R <= range.e.r; R += 1) {
    selectedColumns.forEach((col, colIdx) => {
      const ref = XLSX.utils.encode_cell({ r: R, c: colIdx });
      const cell = ws[ref];
      if (!cell) return;
      if ((col.key === 'deadline' || col.key === 'last_access') && cell.v instanceof Date) {
        cell.t = 'd';
        cell.z = 'dd/mm/yyyy';
      } else if (col.key === 'progression' && typeof cell.v === 'number') {
        cell.t = 'n';
        cell.z = '0.0%';
      }
    });
  }

  // Freeze header row for easier scrolling
  ws['!freeze'] = { xSplit: 0, ySplit: headerRowIndex + 1 };

  const wb = XLSX.utils.book_new();
  const sheetName = lang === 'fr' ? 'Modules' : 'Modules';
  XLSX.utils.book_append_sheet(wb, ws, sheetName);

  const today = new Date().toISOString().split('T')[0];
  const filename = lang === 'fr'
    ? `rapport-modules-${today}.xlsx`
    : `module-report-${today}.xlsx`;
  XLSX.writeFile(wb, filename);
};
