(() => {
  const toast = document.querySelector('#adminToast');
  const showToast = (message) => { toast.textContent = message; toast.classList.add('show'); window.setTimeout(() => toast.classList.remove('show'), 2200); };
  const now = new Date();
  const time = document.querySelector('#currentTime');
  if (time) time.textContent = now.toLocaleString('zh-CN', { hour12: false }).replace(/\//g, '-');
  document.querySelectorAll('.admin-nav button').forEach((button) => button.addEventListener('click', () => { document.querySelectorAll('.admin-nav button').forEach((item) => item.classList.remove('active')); button.classList.add('active'); document.querySelectorAll('.admin-section').forEach((section) => section.classList.toggle('active', section.id === button.dataset.section)); }));
  const body = document.querySelector('#recordBody');
  const filter = () => { const query = (document.querySelector('#searchInput')?.value || '').trim().toLowerCase(); const status = document.querySelector('#statusFilter')?.value || ''; [...body.rows].forEach((row) => { row.hidden = (query && !row.textContent.toLowerCase().includes(query)) || (status && row.dataset.status !== status); }); };
  document.querySelector('#searchInput')?.addEventListener('input', filter); document.querySelector('#statusFilter')?.addEventListener('change', filter); document.querySelector('#clearFilterBtn')?.addEventListener('click', () => { document.querySelector('#searchInput').value = ''; document.querySelector('#statusFilter').value = ''; filter(); });
  document.querySelectorAll('#exportBtn,#exportTopBtn').forEach((button) => button.addEventListener('click', () => { const rows = [...body.querySelectorAll('tr:not([hidden])')].map((row) => [...row.cells].slice(0, 11).map((cell) => `"${cell.textContent.trim().replace(/"/g, '""')}"`).join(',')); const csv = ['问卷编号,提交时间,地区,汽车品牌,风险事件,状态,预留字段1,预留字段2,预留字段3,预留字段4,预留字段5', ...rows].join('\n'); const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' }); const link = document.createElement('a'); link.href = URL.createObjectURL(blob); link.download = 'survey-records.csv'; link.click(); URL.revokeObjectURL(link.href); showToast('数据导出已生成'); }));
  document.querySelector('#addRecordBtn')?.addEventListener('click', () => showToast('新增记录表单已预留，可接入后端接口')); body.addEventListener('click', (event) => { const row = event.target.closest('tr'); if (!row) return; if (event.target.closest('.delete-record')) { row.remove(); showToast('记录已删除'); } if (event.target.closest('.edit-record')) showToast('已打开记录编辑状态'); });
})();
