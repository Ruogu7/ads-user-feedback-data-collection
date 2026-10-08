(() => {
  const backdrop = document.querySelector('#drawerBackdrop');
  const toast = document.querySelector('#adminToast');
  const rows = [...document.querySelectorAll('#recordBody tr')];
  const showToast = (message) => {
    toast.textContent = message;
    toast.classList.add('show');
    window.setTimeout(() => toast.classList.remove('show'), 2200);
  };
  document.querySelectorAll('.view-record').forEach((button) => button.addEventListener('click', () => backdrop.classList.add('open')));
  document.querySelector('#closeDrawer').addEventListener('click', () => backdrop.classList.remove('open'));
  backdrop.addEventListener('click', (event) => { if (event.target === backdrop) backdrop.classList.remove('open'); });
  document.querySelector('#saveReview').addEventListener('click', () => { backdrop.classList.remove('open'); showToast('复核备注已保存（原型示意）'); });
  document.querySelector('#exportBtn').addEventListener('click', () => showToast('已创建脱敏导出任务（原型示意）'));
  document.querySelector('#fieldBtn').addEventListener('click', () => showToast('字段编辑器：可启用 5 个预留字符字段'));
  document.querySelector('#searchInput').addEventListener('input', (event) => {
    const query = event.target.value.trim().toLowerCase();
    rows.forEach((row) => { row.hidden = query && !row.textContent.toLowerCase().includes(query); });
  });
  document.addEventListener('keydown', (event) => { if (event.key === 'Escape') backdrop.classList.remove('open'); });
})();
