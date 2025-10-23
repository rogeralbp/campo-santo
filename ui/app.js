const gridEl = document.querySelector('#grid');

const sampleRows = [
  {
    row: 'Fila A',
    plots: [
      { id: 'A-01', status: 'available', holder: null },
      { id: 'A-02', status: 'reserved', holder: 'Familia Ortega' },
      { id: 'A-03', status: 'occupied', holder: 'Familia Díaz' },
    ],
  },
  {
    row: 'Fila B',
    plots: [
      { id: 'B-01', status: 'available', holder: null },
      { id: 'B-02', status: 'occupied', holder: 'Familia Méndez' },
      { id: 'B-03', status: 'reserved', holder: 'Familia Silva' },
    ],
  },
  {
    row: 'Fila C',
    plots: [
      { id: 'C-01', status: 'reserved', holder: 'Familia Guerrero' },
      { id: 'C-02', status: 'available', holder: null },
      { id: 'C-03', status: 'occupied', holder: 'Familia Rosas' },
    ],
  },
  {
    row: 'Fila D',
    plots: [
      { id: 'D-01', status: 'available', holder: null },
      { id: 'D-02', status: 'available', holder: null },
      { id: 'D-03', status: 'reserved', holder: 'Familia Nuñez' },
    ],
  },
];

const statusLabels = {
  available: 'Disponible',
  reserved: 'Reservado',
  occupied: 'Ocupado',
};

function renderGrid(rows) {
  const fragment = document.createDocumentFragment();

  rows.forEach((row) => {
    row.plots.forEach((plot) => {
      const cell = document.createElement('div');
      cell.classList.add('cell', `cell--${plot.status}`);

      const rowEl = document.createElement('span');
      rowEl.classList.add('cell__row');
      rowEl.textContent = `${row.row} · ${plot.id}`;

      const statusEl = document.createElement('span');
      statusEl.classList.add('cell__status');
      statusEl.textContent = statusLabels[plot.status];

      const holderEl = document.createElement('span');
      holderEl.classList.add('cell__holder');
      holderEl.textContent = plot.holder ?? 'Disponible para asignar';
      holderEl.style.color = plot.holder ? 'var(--text-muted)' : 'var(--accent)';

      cell.append(rowEl, statusEl, holderEl);
      fragment.appendChild(cell);
    });
  });

  gridEl.appendChild(fragment);
}

if (gridEl) {
  renderGrid(sampleRows);
}

// Future enhancement placeholder for integrating StarkNet data
const feedbackCta = document.querySelector('.btn-primary');
if (feedbackCta) {
  feedbackCta.addEventListener('click', () => {
    alert(
      'Gracias por tu interés. En la siguiente iteración conectaremos este flujo con la red de pruebas de StarkNet.'
    );
  });
}
