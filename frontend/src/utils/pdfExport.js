import jsPDF from 'jspdf';
import 'jspdf-autotable';

/**
 * Generate a PDF inactivity report from filtered participant data.
 *
 * @param {Object} params
 * @param {Array} params.participants - Already filtered and sorted participant array
 * @param {Object} params.stats - { total, active, at_risk, inactive }
 * @param {string[]} params.activeFilters - Descriptions of active filters
 * @param {Function} params.t - i18next translation function
 * @param {string} params.lang - Current language code ('fr' or 'en')
 */
export const generateInactivityReport = ({ participants, stats, activeFilters, t, lang }) => {
  const doc = new jsPDF({
    orientation: 'landscape',
    unit: 'mm',
    format: 'a4',
  });

  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();
  const margin = 14;
  let yPos = 15;

  // --- HEADER ---
  doc.setFontSize(18);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(17, 24, 39);
  doc.text(t('inactiveManagement.pdf.title'), margin, yPos);

  yPos += 7;
  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(107, 114, 128);
  doc.text(t('inactiveManagement.pdf.subtitle'), margin, yPos);

  // Date - right aligned
  const dateStr = `${t('inactiveManagement.pdf.generatedOn')} ${new Date().toLocaleDateString(
    lang === 'fr' ? 'fr-FR' : 'en-US',
    { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' }
  )}`;
  doc.setFontSize(9);
  doc.setTextColor(107, 114, 128);
  doc.text(dateStr, pageWidth - margin, 15, { align: 'right' });

  // Separator line
  yPos += 5;
  doc.setDrawColor(229, 231, 235);
  doc.setLineWidth(0.5);
  doc.line(margin, yPos, pageWidth - margin, yPos);

  // --- STATS ---
  yPos += 8;
  const statsData = [
    { label: t('inactiveManagement.stats.total'), value: stats.total, bgColor: [243, 244, 246], textColor: [17, 24, 39] },
    { label: t('inactiveManagement.stats.active'), value: stats.active, bgColor: [220, 252, 231], textColor: [22, 163, 74] },
    { label: t('inactiveManagement.stats.atRisk'), value: stats.at_risk, bgColor: [254, 249, 195], textColor: [202, 138, 4] },
    { label: t('inactiveManagement.stats.inactive'), value: stats.inactive, bgColor: [254, 226, 226], textColor: [220, 38, 38] },
    { label: t('inactiveManagement.stats.neverStarted'), value: stats.never_started, bgColor: [243, 232, 255], textColor: [147, 51, 234] },
  ];

  const boxWidth = (pageWidth - 2 * margin - (statsData.length - 1) * 6) / statsData.length;
  statsData.forEach((stat, i) => {
    const x = margin + i * (boxWidth + 6);
    doc.setFillColor(...stat.bgColor);
    doc.roundedRect(x, yPos, boxWidth, 18, 2, 2, 'F');

    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(...stat.textColor);
    doc.text(stat.label, x + boxWidth / 2, yPos + 7, { align: 'center' });

    doc.setFontSize(16);
    doc.setFont('helvetica', 'bold');
    doc.text(String(stat.value), x + boxWidth / 2, yPos + 15, { align: 'center' });
  });

  yPos += 24;

  // --- ACTIVE FILTERS ---
  if (activeFilters && activeFilters.length > 0) {
    doc.setFontSize(8);
    doc.setFont('helvetica', 'italic');
    doc.setTextColor(107, 114, 128);
    doc.text(
      `${t('inactiveManagement.pdf.appliedFilters')}: ${activeFilters.join(', ')}`,
      margin,
      yPos
    );
    yPos += 6;
  }

  // --- TABLE ---
  const statusLabels = {
    active: t('inactiveManagement.status.active'),
    at_risk: t('inactiveManagement.status.atRisk'),
    inactive: t('inactiveManagement.status.inactive'),
    never_started: t('inactiveManagement.status.neverStarted'),
  };

  const statusColors = {
    active: [22, 163, 74],
    at_risk: [202, 138, 4],
    inactive: [220, 38, 38],
    never_started: [147, 51, 234],
  };

  const tableHeaders = [
    t('inactiveManagement.pdf.colName'),
    t('inactiveManagement.pdf.colCourse'),
    t('inactiveManagement.pdf.colStatus'),
    t('inactiveManagement.pdf.colDaysInactive'),
    t('inactiveManagement.pdf.colProgression'),
    t('inactiveManagement.pdf.colEmail'),
  ];

  const tableBody = participants.map((p) => [
    `${p.nom} ${p.prenom}`,
    p.course_title || '',
    statusLabels[p.inactivity_status] || p.inactivity_status,
    String(p.days_inactive || 0),
    `${(p.current_progression || p.overall_progression || 0).toFixed(1)}%`,
    p.email || '',
  ]);

  doc.autoTable({
    startY: yPos,
    head: [tableHeaders],
    body: tableBody,
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
    alternateRowStyles: {
      fillColor: [249, 250, 251],
    },
    columnStyles: {
      0: { cellWidth: 50 },
      1: { cellWidth: 75 },
      2: { cellWidth: 28, halign: 'center' },
      3: { cellWidth: 28, halign: 'center' },
      4: { cellWidth: 28, halign: 'center' },
      5: { cellWidth: 55 },
    },
    didParseCell: (data) => {
      if (data.section === 'body' && data.column.index === 2) {
        const status = participants[data.row.index]?.inactivity_status;
        if (status && statusColors[status]) {
          data.cell.styles.textColor = statusColors[status];
          data.cell.styles.fontStyle = 'bold';
        }
      }
    },
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

  // --- SAVE ---
  const today = new Date().toISOString().split('T')[0];
  const filename = lang === 'fr'
    ? `rapport-inactivite-${today}.pdf`
    : `inactivity-report-${today}.pdf`;
  doc.save(filename);
};
