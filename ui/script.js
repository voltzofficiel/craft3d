const app = document.getElementById('app');
const recipesContainer = document.getElementById('recipes');
const craftBtn = document.getElementById('craft');
const closeBtn = document.getElementById('close');
const panelTitle = document.getElementById('panel-title');
const progressBox = document.getElementById('progress');
const progressFill = document.getElementById('progress-fill');
const progressLabel = document.getElementById('progress-label');

let recipes = [];
let selected = 0;
let progressTimer;

function post(event, payload = {}) {
    fetch(`https://craft3d/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload),
    });
}

function setActive(index) {
    if (!recipes.length) return;
    selected = Math.max(0, Math.min(index, recipes.length - 1));
    Array.from(recipesContainer.children).forEach((node, idx) => {
        node.classList.toggle('active', idx === selected);
    });
}

function renderRecipes(items = []) {
    recipesContainer.innerHTML = '';

    items.forEach((recipe, idx) => {
        const row = document.createElement('div');
        row.className = 'recipe';

        const title = document.createElement('div');
        title.className = 'recipe__title';
        title.textContent = recipe.label;

        const reqs = document.createElement('div');
        reqs.className = 'recipe__reqs';
        reqs.textContent = (recipe.requirements || [])
            .map((req) => `${req.count}x ${req.item}`)
            .join(' · ');

        row.appendChild(title);
        row.appendChild(reqs);

        row.addEventListener('click', () => {
            setActive(idx);
            post('craft3d:select', { index: idx + 1 });
        });

        recipesContainer.appendChild(row);
    });
}

function openUI(data) {
    recipes = data.recipes || [];
    panelTitle.textContent = data.title || 'Établi de craft';
    renderRecipes(recipes);
    setActive(Math.max(0, (data.selected || 1) - 1));
    app.classList.remove('hidden');
}

function closeUI() {
    app.classList.add('hidden');
}

function startProgress(label, duration) {
    progressBox.classList.remove('hidden');
    progressFill.style.width = '0%';
    progressLabel.textContent = label || 'Fabrication...';

    const total = Math.max(1, duration || 0);
    const start = performance.now();
    clearInterval(progressTimer);

    progressTimer = setInterval(() => {
        const elapsed = performance.now() - start;
        const percent = Math.min(100, (elapsed / total) * 100);
        progressFill.style.width = `${percent}%`;

        if (percent >= 100) {
            clearInterval(progressTimer);
            setTimeout(() => progressBox.classList.add('hidden'), 200);
        }
    }, 50);
}

function finishProgress() {
    clearInterval(progressTimer);
    progressFill.style.width = '100%';
    setTimeout(() => progressBox.classList.add('hidden'), 150);
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') {
        openUI(data);
    } else if (data.action === 'close') {
        closeUI();
    } else if (data.action === 'progress') {
        startProgress(data.label, data.duration || 0);
    } else if (data.action === 'progress-finish') {
        finishProgress();
    }
});

window.addEventListener('keydown', (event) => {
    if (app.classList.contains('hidden')) return;
    if (!recipes.length) return;

    switch (event.key) {
        case 'Escape':
        case 'Backspace':
            post('craft3d:close');
            break;
        case 'ArrowUp':
            setActive((selected - 1 + recipes.length) % recipes.length);
            post('craft3d:select', { index: selected + 1 });
            break;
        case 'ArrowDown':
            setActive((selected + 1) % recipes.length);
            post('craft3d:select', { index: selected + 1 });
            break;
        case 'Enter':
        case ' ':
            post('craft3d:start', { index: selected + 1 });
            break;
    }
});

craftBtn.addEventListener('click', () => post('craft3d:start', { index: selected + 1 }));
closeBtn.addEventListener('click', () => post('craft3d:close'));
