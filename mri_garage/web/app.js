let state = {
  open: false,
  garageId: null,
  garages: {},
  vehicles: [],
  filter: ""
};

const app = document.getElementById('app');
const list = document.getElementById('list');
const search = document.getElementById('search');

function post(name, data){
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    body: JSON.stringify(data || {})
  });
}

function clamp(n, a, b){ return Math.max(a, Math.min(b, n)); }

function damagePercent(engine, body){
  engine = Number(engine ?? 1000);
  body   = Number(body ?? 1000);
  const avg = (engine + body)/2;
  const condition = clamp(avg/1000, 0, 1) * 100; // saúde
  const dmg = 100 - condition; // dano
  return Math.round(dmg);
}

function barColor(v){
  if (v >= 66) return 'var(--good)';
  if (v >= 33) return 'var(--warn)';
  return 'var(--bad)';
}

function render(){
  const q = state.filter.toLowerCase();
  const items = state.vehicles
    .slice()
    .sort((a,b)=> (b.favorite?1:0)-(a.favorite?1:0))
    .filter(v=>{
      const name = String(v.displayName || v.model || 'vehicle').toLowerCase();
      const plate = String(v.plate || '').toLowerCase();
      return name.includes(q) || plate.includes(q);
    });

  list.innerHTML = items.map((v, idx)=>{
    const isElectric = !!v.isElectric;
    const fuelLabel = isElectric ? 'BAT' : 'FUEL';
    const fuelVal = clamp(Number(v.fuel ?? 100), 0, 100);
    const dmg = damagePercent(v.engine, v.body);
    const condition = 100 - dmg;

    return `
      <div class="item" data-idx="${idx}" data-plate="${v.plate}">
        <div class="top">
          <div class="left">
            <div class="star" data-fav="${v.favorite ? 1 : 0}">${v.favorite ? '★' : '☆'}</div>
            <div class="name">${(v.displayName || v.model || 'VEHICLE')}</div>
          </div>
          <div class="tag">${v.tag || 'Vehicle'}</div>
        </div>

        <div class="details">
          <div class="bars">
            <div class="barRow">
              <div class="dot"></div>
              <div class="bar"><div class="fill" style="width:${condition}%;background:${barColor(condition)}"></div></div>
              <div class="val">${condition}</div>
            </div>
            <div class="barRow">
              <div class="dot"></div>
              <div class="bar"><div class="fill" style="width:${fuelVal}%;background:${barColor(fuelVal)}"></div></div>
              <div class="val">${fuelVal}</div>
            </div>
            <div style="display:flex;gap:10px;color:var(--muted);font-size:11px;">
              <div>COND</div>
              <div style="margin-left:auto">${fuelLabel}</div>
            </div>
          </div>

          <div class="plateBox">
            <div class="plate">${v.plate || '--------'}</div>
            <div class="actions">
              <button class="btn orange" data-action="take">RETIRAR</button>
              <button class="btn" data-action="track">TRACK</button>
            </div>
            <div class="actions">
              <button class="btn" data-action="transfer">TRANSFER</button>
              <button class="btn" data-action="fav">${v.favorite ? 'UNFAV' : 'FAV'}</button>
            </div>
          </div>
        </div>
      </div>
    `;
  }).join('');
}

window.addEventListener('message', (e)=>{
  const msg = e.data;
  if (msg.action === 'open'){
    state.open = true;
    state.garageId = msg.garageId;
    state.garages = msg.garages || {};
    state.vehicles = (msg.vehicles || []).map(v=>{
      const model = v.model;
      return {
        ...v,
        displayName: (v.vehicle && (v.vehicle.name || v.vehicle.label)) || model,
        isElectric: !!v.isElectric, // o client pode setar, mas se não vier fica false
      };
    });

    app.classList.remove('hidden');
    // garante que nenhum modal fique aberto por acidente
    try { closeTransferModal(); } catch (e) {}
    render();
  }

  if (msg.action === 'close'){
    // fecha também qualquer modal
    try { closeTransferModal(); } catch (e) {}
    app.classList.add('hidden');
    state.open = false;
  }
});

document.getElementById('btnClose').addEventListener('click', ()=> post('close'));
document.getElementById('btnStore').addEventListener('click', ()=> post('store'));

search.addEventListener('input', (e)=>{
  state.filter = e.target.value || '';
  render();
});

list.addEventListener('click', (e)=>{
  const item = e.target.closest('.item');
  if (!item) return;

  // toggle open card
  document.querySelectorAll('.item.active').forEach(x=>{ if (x!==item) x.classList.remove('active'); });
  item.classList.toggle('active');

  const plate = item.getAttribute('data-plate');

  const actionBtn = e.target.closest('button');
  if (!actionBtn) {
    // click na estrela também
    const star = e.target.closest('.star');
    if (star){
      const nowFav = star.getAttribute('data-fav') !== '1';
      post('setFavorite', { plate, favorite: nowFav });
      // otimista
      state.vehicles = state.vehicles.map(v=> v.plate===plate ? {...v, favorite: nowFav} : v);
      render();
    }
    return;
  }

  const action = actionBtn.getAttribute('data-action');

  if (action === 'take'){
    post('takeOut', { plate });
  } else if (action === 'fav'){
    const v = state.vehicles.find(x=>x.plate===plate);
    const nowFav = !(v && v.favorite);
    post('setFavorite', { plate, favorite: nowFav });
    state.vehicles = state.vehicles.map(x=> x.plate===plate ? {...x, favorite: nowFav} : x);
    render();
  } else if (action === 'transfer'){
    openTransferModal(plate);
  } else if (action === 'track'){
    // se quiser implementar tracking no client, pode mandar evento.
    // por enquanto só fecha e deixa livre.
    post('close');
  }
});

document.addEventListener('keydown', (e)=>{
  if (e.key === 'Escape'){
    post('close');
  }
});

// --- Transfer modal ---
let transferPlate = null;
const $ = (id)=>document.getElementById(id);

function showTransferError(msg){
  const el = $('transferError');
  if (!el) return;
  el.textContent = msg || '';
  el.classList.toggle('hidden', !msg);
}

function openTransferModal(plate){
  transferPlate = plate;
  showTransferError('');
  $('transferPlayerId').value = '';
  $('transferCitizenId').value = '';
  $('transferPrice').value = '0';
  $('transferModal').classList.remove('hidden');
  $('transferPlayerId').focus();
}

function closeTransferModal(){
  transferPlate = null;
  $('transferModal').classList.add('hidden');
  showTransferError('');
}

document.addEventListener('DOMContentLoaded', ()=>{
  // segurança: sempre iniciar com o modal fechado
  try { closeTransferModal(); } catch (e) {}
  if ($('btnTransferClose')) $('btnTransferClose').addEventListener('click', closeTransferModal);
  if ($('btnTransferCancel')) $('btnTransferCancel').addEventListener('click', closeTransferModal);

  if ($('btnTransferConfirm')) $('btnTransferConfirm').addEventListener('click', ()=>{
    if (!transferPlate) return;
    const playerId = Number(($('transferPlayerId').value || '').trim());
    const toCitizenId = ($('transferCitizenId').value || '').trim();
    const price = Number(($('transferPrice').value || '0').trim() || '0');

    if (!toCitizenId && (!playerId || Number.isNaN(playerId))) {
      showTransferError('Informe o ID do player (server) ou o CitizenID.');
      return;
    }

    if (toCitizenId){
      post('transfer', { plate: transferPlate, toCitizenId, price });
      closeTransferModal();
      return;
    }

    post('transferByPlayerId', { plate: transferPlate, playerId, price });
    closeTransferModal();
  });
});
