// ============================================================
// AN CỰU GALLERIA HUẾ - ADMIN CORE
// Supabase + LocalStorage CMS Engine
// ============================================================

const SUPABASE_URL = 'https://vcakxvggqgnmhusihmmj.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjYWt4dmdncWdubWh1c2lobW1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwOTgwMjMsImV4cCI6MjA5NjY3NDAyM30.7i6wUek7E7i5uQkRtK-gjvDH13Bjo7Yv__yatrmQsgE';

// ─── AUTH ────────────────────────────────────────────────────

const ADMIN_EMAIL = 'tramy.minhvi@gmail.com';
const ADMIN_PASS_HASH = btoa('123456@6'); // simple obfuscation

const Auth = {
  /**
   * Login via Supabase Auth
   */
  async login(email, password) {
    try {
      const res = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_ANON_KEY
        },
        body: JSON.stringify({ email, password })
      });
      const data = await res.json();
      if (data.access_token) {
        localStorage.setItem('acg_admin_token', data.access_token);
        localStorage.setItem('acg_admin_refresh', data.refresh_token);
        localStorage.setItem('acg_admin_email', email);
        localStorage.setItem('acg_admin_user', JSON.stringify(data.user));
        localStorage.setItem('acg_admin_exp', Date.now() + (data.expires_in * 1000));
        return { success: true, user: data.user };
      }
      // Fallback local auth for demo
      if (email === ADMIN_EMAIL && btoa(password) === ADMIN_PASS_HASH) {
        const fakeToken = 'local_' + Date.now();
        localStorage.setItem('acg_admin_token', fakeToken);
        localStorage.setItem('acg_admin_email', email);
        localStorage.setItem('acg_admin_exp', Date.now() + 86400000);
        return { success: true, user: { email } };
      }
      return { success: false, error: data.error_description || 'Sai email hoặc mật khẩu' };
    } catch (e) {
      // Offline fallback
      if (email === ADMIN_EMAIL && btoa(password) === ADMIN_PASS_HASH) {
        localStorage.setItem('acg_admin_token', 'local_' + Date.now());
        localStorage.setItem('acg_admin_email', email);
        localStorage.setItem('acg_admin_exp', Date.now() + 86400000);
        return { success: true, user: { email } };
      }
      return { success: false, error: 'Kết nối thất bại. ' + e.message };
    }
  },

  logout() {
    ['acg_admin_token','acg_admin_refresh','acg_admin_email','acg_admin_user','acg_admin_exp']
      .forEach(k => localStorage.removeItem(k));
    window.location.href = '/admin/index.html';
  },

  isLoggedIn() {
    const token = localStorage.getItem('acg_admin_token');
    const exp = parseInt(localStorage.getItem('acg_admin_exp') || '0');
    return token && Date.now() < exp;
  },

  requireAuth() {
    if (!this.isLoggedIn()) {
      window.location.href = '/admin/index.html';
      return false;
    }
    return true;
  },

  getToken() { return localStorage.getItem('acg_admin_token'); },
  getEmail() { return localStorage.getItem('acg_admin_email') || 'Admin'; }
};

// ─── SUPABASE REST CLIENT ─────────────────────────────────────

const DB = {
  headers() {
    const token = Auth.getToken();
    return {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${token && !token.startsWith('local_') ? token : SUPABASE_ANON_KEY}`,
      'Prefer': 'return=representation'
    };
  },

  async select(table, query = '') {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${query}`, {
      headers: this.headers()
    });
    return res.json();
  },

  async insert(table, data) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
      method: 'POST',
      headers: this.headers(),
      body: JSON.stringify(data)
    });
    return res.json();
  },

  async update(table, id, data) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?id=eq.${id}`, {
      method: 'PATCH',
      headers: this.headers(),
      body: JSON.stringify(data)
    });
    return res.json();
  },

  async delete(table, id) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?id=eq.${id}`, {
      method: 'DELETE',
      headers: this.headers()
    });
    return res.ok;
  }
};

// ─── CMS STORAGE (localStorage fallback) ─────────────────────

const CMS = {
  KEY: 'acg_cms_data',

  get() {
    try {
      return JSON.parse(localStorage.getItem(this.KEY) || '{}');
    } catch { return {}; }
  },

  set(data) {
    localStorage.setItem(this.KEY, JSON.stringify(data));
  },

  getSite() {
    return this.get().site || {
      name: 'An Cựu Galleria Huế',
      tagline: 'Bất Động Sản Cao Cấp Tại Huế',
      hotline: '0907272001',
      email: 'lienhe@ancuugalleriahue.vn',
      address: 'An Cựu, TP. Huế, Thừa Thiên Huế',
      hours: '08:00 – 20:00, 7 ngày/tuần',
      facebook: 'https://www.facebook.com/ancuugalleriahue',
      zalo: 'https://zalo.me/0907272001',
      agent_name: 'Nguyễn Minh Tuấn',
      agent_title: 'Chuyên Gia BDS Huế 8+ Năm',
      hero_title: 'Bất Động Sản Cao Cấp Tại Huế',
      hero_subtitle: 'Shophouse · Nhà Phố · Đất Nền · Căn Hộ',
      ga_id: '',
      pixel_id: ''
    };
  },

  saveSite(data) {
    const cms = this.get();
    cms.site = { ...(cms.site || {}), ...data };
    this.set(cms);
  },

  getProperties() {
    return this.get().properties || [
      {
        id: 1, title: 'Shophouse 3 tầng mặt tiền Trần Phú', type: 'shophouse',
        area: 'An Cựu', price: '6,8 tỷ', area_size: '85 m²', frontage: '5m',
        floors: 3, direction: 'Đông Nam', legal: 'Sổ đỏ', status: 'available',
        is_hot: true, is_featured: true,
        image: '/images/shophouse.png', description: 'Shophouse mặt tiền đường lớn trung tâm An Cựu.'
      },
      {
        id: 2, title: 'Đất nền An Vân Dương – Pháp lý hoàn chỉnh', type: 'dat-nen',
        area: 'An Vân Dương', price: '1,92 tỷ', area_size: '120 m²', frontage: '6m',
        floors: null, direction: 'Đông', legal: 'Sổ đỏ', status: 'available',
        is_hot: false, is_featured: true,
        image: '/images/land.png', description: 'Đất nền sổ đỏ chính chủ khu đô thị An Vân Dương.'
      },
      {
        id: 3, title: 'Căn hộ An Cựu Galleria 2PN View Sông Hương', type: 'can-ho',
        area: 'An Cựu', price: '2,85 tỷ', area_size: '72 m²', frontage: null,
        floors: null, direction: 'Bắc', legal: 'Hợp đồng', status: 'available',
        is_hot: true, is_featured: true,
        image: '/images/apartment.png', description: 'Căn hộ 2 phòng ngủ view sông Hương, tiện ích đầy đủ.'
      }
    ];
  },

  saveProperties(data) {
    const cms = this.get();
    cms.properties = data;
    this.set(cms);
  },

  getProjects() {
    return this.get().projects || [
      { id: 1, name: 'An Cựu Galleria', status: 'Đang mở bán', price: 'Từ 2,8 tỷ', location: 'An Cựu, Huế', units: 280, image: '/images/apartment.png' },
      { id: 2, name: 'Eco Garden Huế', status: 'Sắp mở bán', price: 'Từ 3,5 tỷ', location: 'Hương Thủy, Huế', units: 150, image: '/images/land.png' },
      { id: 3, name: 'Royal Park', status: 'Đang bán', price: 'Từ 1,2 tỷ', location: 'An Vân Dương, Huế', units: 400, image: '/images/shophouse.png' }
    ];
  },

  getLeads() {
    return this.get().leads || [];
  },

  addLead(lead) {
    const cms = this.get();
    const leads = cms.leads || [];
    leads.unshift({ ...lead, id: Date.now(), created_at: new Date().toISOString(), status: 'new' });
    cms.leads = leads;
    this.set(cms);
  },

  getStats() {
    const data = this.get();
    return {
      properties: (data.properties || []).length || 6,
      projects: (data.projects || []).length || 4,
      leads: (data.leads || []).length || 0,
      views: parseInt(data.views || 0)
    };
  }
};

// ─── IMAGE UPLOAD ─────────────────────────────────────────────

const Uploader = {
  async uploadToSupabase(file, bucket = 'property-images') {
    const token = Auth.getToken();
    if (token && !token.startsWith('local_')) {
      const ext = file.name.split('.').pop();
      const filename = `${Date.now()}-${Math.random().toString(36).substr(2,9)}.${ext}`;
      const res = await fetch(`${SUPABASE_URL}/storage/v1/object/${bucket}/${filename}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'apikey': SUPABASE_ANON_KEY,
          'Content-Type': file.type
        },
        body: file
      });
      if (res.ok) {
        return `${SUPABASE_URL}/storage/v1/object/public/${bucket}/${filename}`;
      }
    }
    // Fallback: base64 data URL
    return new Promise((resolve) => {
      const reader = new FileReader();
      reader.onload = e => resolve(e.target.result);
      reader.readAsDataURL(file);
    });
  }
};

// ─── TOAST NOTIFICATIONS ──────────────────────────────────────

function showToast(message, type = 'success') {
  const existing = document.getElementById('admin-toast');
  if (existing) existing.remove();
  
  const toast = document.createElement('div');
  toast.id = 'admin-toast';
  const colors = { success: '#22c55e', error: '#ef4444', warning: '#f59e0b', info: '#3b82f6' };
  const icons = { success: '✓', error: '✕', warning: '⚠', info: 'ℹ' };
  toast.style.cssText = `
    position:fixed; bottom:24px; right:24px; z-index:99999;
    background:#252B49; border:1px solid ${colors[type]};
    color:#fff; padding:14px 20px; border-radius:12px;
    font-family:'Inter',sans-serif; font-size:0.9rem;
    display:flex; align-items:center; gap:10px;
    box-shadow:0 8px 32px rgba(0,0,0,0.4);
    animation:slideInRight 0.3s ease;
    max-width:360px;
  `;
  toast.innerHTML = `<span style="color:${colors[type]};font-weight:700;font-size:1.1rem;">${icons[type]}</span><span>${message}</span>`;
  document.body.appendChild(toast);
  setTimeout(() => { toast.style.animation = 'slideOutRight 0.3s ease'; setTimeout(() => toast.remove(), 300); }, 3500);
}

// ─── MODAL HELPER ─────────────────────────────────────────────

function openModal(id) {
  const el = document.getElementById(id);
  if (el) { el.style.display = 'flex'; document.body.style.overflow = 'hidden'; }
}
function closeModal(id) {
  const el = document.getElementById(id);
  if (el) { el.style.display = 'none'; document.body.style.overflow = ''; }
}

// ─── CONFIRM DIALOG ──────────────────────────────────────────

function confirmAction(message, onConfirm) {
  const el = document.getElementById('confirm-modal');
  if (el) {
    document.getElementById('confirm-msg').textContent = message;
    document.getElementById('confirm-ok').onclick = () => { closeModal('confirm-modal'); onConfirm(); };
    openModal('confirm-modal');
  } else {
    if (confirm(message)) onConfirm();
  }
}

// ─── ACTIVE NAV ──────────────────────────────────────────────

function setActiveNav() {
  const path = window.location.pathname;
  document.querySelectorAll('.admin-nav-link').forEach(link => {
    if (link.getAttribute('href') && path.includes(link.getAttribute('href').replace('../', '').replace('.html', ''))) {
      link.classList.add('active');
    }
  });
}

// Export
window.Auth = Auth;
window.DB = DB;
window.CMS = CMS;
window.Uploader = Uploader;
window.showToast = showToast;
window.openModal = openModal;
window.closeModal = closeModal;
window.confirmAction = confirmAction;
window.setActiveNav = setActiveNav;
window.SUPABASE_URL = SUPABASE_URL;
window.SUPABASE_ANON_KEY = SUPABASE_ANON_KEY;
