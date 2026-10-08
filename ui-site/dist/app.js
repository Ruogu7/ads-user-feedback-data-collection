(() => {
  const panels = [...document.querySelectorAll('.section-panel')];
  const stepButtons = [...document.querySelectorAll('#stepList button')];
  const progressFill = document.querySelector('#progressFill');
  const progressText = document.querySelector('#progressText');
  const mobileStep = document.querySelector('#mobileStep');
  const mobilePct = document.querySelector('#mobilePct');
  const prevBtn = document.querySelector('#prevBtn');
  const nextBtn = document.querySelector('#nextBtn');
  const saveState = document.querySelector('#saveState');
  const toast = document.querySelector('#toast');
  let step = 0;

  function render() {
    panels.forEach((panel, index) => panel.classList.toggle('active', index === step));
    stepButtons.forEach((button, index) => button.classList.toggle('active', index === step));
    const pct = Math.round(((step + 1) / panels.length) * 100);
    const answered = Math.min(61, Math.round(61 * pct / 100));
    progressFill.style.width = `${pct}%`;
    progressText.textContent = `已完成 ${answered} / 61 题`;
    mobileStep.textContent = `第 ${step + 1} 部分 · ${panels[step].dataset.title}`;
    mobilePct.textContent = `${pct}%`;
    prevBtn.disabled = step === 0;
    prevBtn.style.opacity = step === 0 ? '.45' : '1';
    nextBtn.textContent = step === panels.length - 1 ? '提交问卷' : '保存并继续';
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function pulseSaved() {
    saveState.textContent = '保存中…';
    window.setTimeout(() => { saveState.textContent = '✓ 已自动保存到本机'; }, 420);
  }

  nextBtn.addEventListener('click', () => {
    pulseSaved();
    if (step < panels.length - 1) { step += 1; render(); return; }
    toast.classList.add('show');
    window.setTimeout(() => toast.classList.remove('show'), 2200);
  });

  prevBtn.addEventListener('click', () => { if (step > 0) { step -= 1; render(); } });
  stepButtons.forEach((button) => button.addEventListener('click', () => { step = Number(button.dataset.step); render(); }));
  document.querySelector('#surveyForm').addEventListener('change', pulseSaved);
  render();
})();
