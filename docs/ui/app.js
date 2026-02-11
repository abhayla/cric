/* =====================================================
   CricApp Shared JavaScript — app.js
   Navigation, interactions, state, and sample data
   ===================================================== */

// ── Sample Cricket Data ──────────────────────────────────
const SAMPLE_DATA = {
  // Teams
  teams: [
    { id: 'team1', name: 'Mumbai Warriors', short: 'MW', initials: 'MW', ballType: 'Leather' },
    { id: 'team2', name: 'Delhi Strikers', short: 'DS', initials: 'DS', ballType: 'Leather' },
    { id: 'team3', name: 'Chennai Kings', short: 'CK', initials: 'CK', ballType: 'Tennis' },
    { id: 'team4', name: 'Bangalore Royals', short: 'BR', initials: 'BR', ballType: 'Leather' },
    { id: 'team5', name: 'Kolkata Thunder', short: 'KT', initials: 'KT', ballType: 'Tennis' },
  ],

  // Players for Mumbai Warriors (team1) — batting-heavy lineup
  team1Players: [
    { id: 'p1',  name: 'Arjun Mehta',       role: 'Batsman',       bat: 'Right', bowl: 'Right Medium' },
    { id: 'p2',  name: 'Vikram Sharma',      role: 'Batsman',       bat: 'Right', bowl: 'Off Break' },
    { id: 'p3',  name: 'Rohan Patel',        role: 'Batsman',       bat: 'Left',  bowl: '-' },
    { id: 'p4',  name: 'Karan Singh',        role: 'All-rounder',   bat: 'Right', bowl: 'Right Fast' },
    { id: 'p5',  name: 'Aditya Joshi',       role: 'All-rounder',   bat: 'Right', bowl: 'Left Spin' },
    { id: 'p6',  name: 'Nikhil Verma',       role: 'Wicketkeeper',  bat: 'Right', bowl: '-' },
    { id: 'p7',  name: 'Rajesh Kumar',       role: 'Bowler',        bat: 'Right', bowl: 'Right Fast' },
    { id: 'p8',  name: 'Sanjay Rao',         role: 'Bowler',        bat: 'Right', bowl: 'Right Medium' },
    { id: 'p9',  name: 'Deepak Nair',        role: 'Bowler',        bat: 'Left',  bowl: 'Left Spin' },
    { id: 'p10', name: 'Amit Tiwari',        role: 'Bowler',        bat: 'Right', bowl: 'Off Break' },
    { id: 'p11', name: 'Prashant Gupta',     role: 'Bowler',        bat: 'Right', bowl: 'Right Fast' },
  ],

  // Players for Delhi Strikers (team2) — balanced lineup
  team2Players: [
    { id: 'p12', name: 'Rahul Kapoor',       role: 'Batsman',       bat: 'Right', bowl: 'Off Break' },
    { id: 'p13', name: 'Suresh Reddy',       role: 'Batsman',       bat: 'Left',  bowl: '-' },
    { id: 'p14', name: 'Mahesh Desai',       role: 'Batsman',       bat: 'Right', bowl: '-' },
    { id: 'p15', name: 'Ankit Pandey',       role: 'All-rounder',   bat: 'Right', bowl: 'Right Medium' },
    { id: 'p16', name: 'Vivek Chauhan',      role: 'All-rounder',   bat: 'Left',  bowl: 'Left Spin' },
    { id: 'p17', name: 'Gaurav Saxena',      role: 'Wicketkeeper',  bat: 'Right', bowl: '-' },
    { id: 'p18', name: 'Harsh Mishra',       role: 'Bowler',        bat: 'Right', bowl: 'Right Fast' },
    { id: 'p19', name: 'Naveen Yadav',       role: 'Bowler',        bat: 'Right', bowl: 'Right Fast' },
    { id: 'p20', name: 'Sachin Kulkarni',    role: 'Bowler',        bat: 'Right', bowl: 'Off Break' },
    { id: 'p21', name: 'Ravi Malhotra',      role: 'Bowler',        bat: 'Right', bowl: 'Left Spin' },
    { id: 'p22', name: 'Tarun Bhatt',        role: 'Bowler',        bat: 'Left',  bowl: 'Right Medium' },
  ],

  // Sample completed match
  completedMatch: {
    id: 'm1',
    team1: 'Mumbai Warriors',
    team1Short: 'MW',
    team2: 'Delhi Strikers',
    team2Short: 'DS',
    team1Score: '187/6',
    team1Overs: '20.0',
    team2Score: '172/9',
    team2Overs: '20.0',
    result: 'Mumbai Warriors won by 15 runs',
    date: '8 Feb 2026',
    venue: 'Shivaji Park, Mumbai',
    status: 'completed',
    overs: 20,
  },

  // Sample live match
  liveMatch: {
    id: 'm2',
    team1: 'Chennai Kings',
    team1Short: 'CK',
    team2: 'Bangalore Royals',
    team2Short: 'BR',
    team1Score: '156/4',
    team1Overs: '18.2',
    team2Score: '',
    team2Overs: '',
    result: '',
    date: '10 Feb 2026',
    venue: 'Marina Ground, Chennai',
    status: 'live',
    overs: 20,
  },

  // Sample recent matches list
  recentMatches: [
    {
      id: 'm1',
      team1: 'Mumbai Warriors', team1Short: 'MW',
      team2: 'Delhi Strikers', team2Short: 'DS',
      team1Score: '187/6', team1Overs: '(20.0)',
      team2Score: '172/9', team2Overs: '(20.0)',
      result: 'Mumbai Warriors won by 15 runs',
      date: '8 Feb 2026', venue: 'Shivaji Park, Mumbai',
      status: 'completed',
    },
    {
      id: 'm2',
      team1: 'Chennai Kings', team1Short: 'CK',
      team2: 'Bangalore Royals', team2Short: 'BR',
      team1Score: '156/4', team1Overs: '(18.2)',
      team2Score: '', team2Overs: '',
      result: '',
      date: '10 Feb 2026', venue: 'Marina Ground',
      status: 'live',
    },
    {
      id: 'm3',
      team1: 'Kolkata Thunder', team1Short: 'KT',
      team2: 'Mumbai Warriors', team2Short: 'MW',
      team1Score: '142/10', team1Overs: '(19.3)',
      team2Score: '145/3', team2Overs: '(17.1)',
      result: 'Mumbai Warriors won by 7 wickets',
      date: '5 Feb 2026', venue: 'Eden Club Ground',
      status: 'completed',
    },
    {
      id: 'm4',
      team1: 'Delhi Strikers', team1Short: 'DS',
      team2: 'Chennai Kings', team2Short: 'CK',
      team1Score: '198/5', team1Overs: '(20.0)',
      team2Score: '199/4', team2Overs: '(19.4)',
      result: 'Chennai Kings won by 6 wickets',
      date: '2 Feb 2026', venue: 'Feroz Shah Kotla Club',
      status: 'completed',
    },
    {
      id: 'm5',
      team1: 'Bangalore Royals', team1Short: 'BR',
      team2: 'Kolkata Thunder', team2Short: 'KT',
      team1Score: '165/7', team1Overs: '(20.0)',
      team2Score: '130/10', team2Overs: '(18.1)',
      result: 'Bangalore Royals won by 35 runs',
      date: '30 Jan 2026', venue: 'Chinnaswamy Club Ground',
      status: 'completed',
    },
  ],

  // Sample batting scorecard for MW innings
  battingScorecard: [
    { name: 'Arjun Mehta',   dismissal: 'c Rahul b Harsh',     R: 54, B: 38, fours: 6, sixes: 2, SR: '142.10' },
    { name: 'Vikram Sharma',  dismissal: 'b Naveen',            R: 32, B: 28, fours: 3, sixes: 1, SR: '114.28' },
    { name: 'Rohan Patel',    dismissal: 'lbw b Sachin',        R: 12, B: 15, fours: 1, sixes: 0, SR: '80.00' },
    { name: 'Karan Singh',    dismissal: 'not out',             R: 48, B: 30, fours: 4, sixes: 3, SR: '160.00' },
    { name: 'Aditya Joshi',   dismissal: 'run out (Vivek)',     R: 18, B: 12, fours: 2, sixes: 0, SR: '150.00' },
    { name: 'Nikhil Verma',   dismissal: 'c Gaurav b Ravi',     R: 8,  B: 6,  fours: 1, sixes: 0, SR: '133.33' },
    { name: 'Rajesh Kumar',   dismissal: 'not out',             R: 5,  B: 3,  fours: 0, sixes: 1, SR: '166.66' },
  ],

  // Sample bowling figures for DS bowling
  bowlingScorecard: [
    { name: 'Harsh Mishra',   O: '4.0', M: 0, R: 38, W: 1, Ec: '9.50' },
    { name: 'Naveen Yadav',   O: '4.0', M: 0, R: 42, W: 1, Ec: '10.50' },
    { name: 'Ankit Pandey',   O: '4.0', M: 0, R: 35, W: 0, Ec: '8.75' },
    { name: 'Sachin Kulkarni',O: '4.0', M: 1, R: 28, W: 1, Ec: '7.00' },
    { name: 'Ravi Malhotra',  O: '4.0', M: 0, R: 44, W: 1, Ec: '11.00' },
  ],

  // Player career stats (for Arjun Mehta)
  playerStats: {
    name: 'Arjun Mehta',
    role: 'Batsman',
    team: 'Mumbai Warriors',
    batting: { matches: 28, innings: 27, runs: 892, HS: '98*', avg: '36.16', SR: '134.53', fifties: 7, hundreds: 0, fours: 96, sixes: 32 },
    bowling: { innings: 5, overs: 12, wickets: 2, best: '1/18', avg: '42.00', economy: '7.00', fiveW: 0 },
    fielding: { catches: 14, stumpings: 0, runOuts: 3, directHits: 1 },
  },

  // User profile
  user: {
    name: 'Abhay',
    phone: '+91 98765 43210',
    role: 'All-rounder',
    batStyle: 'Right Hand',
    bowlStyle: 'Right Medium',
  },
};

// ── SVG Icons ────────────────────────────────────────────
const ICONS = {
  home: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>',
  matches: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>',
  teams: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
  profile: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>',
  back: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>',
  search: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>',
  plus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>',
  close: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>',
  check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>',
  undo: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg>',
  menu: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="1"/><circle cx="12" cy="5" r="1"/><circle cx="12" cy="19" r="1"/></svg>',
  camera: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>',
  trophy: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/></svg>',
  swap: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="17 1 21 5 17 9"/><path d="M3 11V9a4 4 0 0 1 4-4h14"/><polyline points="7 23 3 19 7 15"/><path d="M21 13v2a4 4 0 0 1-4 4H3"/></svg>',
  edit: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="m18.5 2.5 3 3L12 15l-4 1 1-4z"/></svg>',
  trash: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
  filter: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>',
  chevronRight: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>',
  settings: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>',
  leaderboard: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="12" width="5" height="9" rx="1"/><rect x="10" y="3" width="5" height="18" rx="1"/><rect x="17" y="8" width="5" height="13" rx="1"/></svg>',
  chat_bubble_outline: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>',
};

// ── Utility Functions ────────────────────────────────────

/** Navigate to another page */
function navigateTo(page) {
  window.location.href = page;
}

/** Get the current page filename */
function getCurrentPage() {
  const path = window.location.pathname;
  return path.substring(path.lastIndexOf('/') + 1) || 'index.html';
}

/** Inject an SVG icon into an element */
function setIcon(element, iconName) {
  if (ICONS[iconName]) {
    element.innerHTML = ICONS[iconName];
  }
}

/** Initialize all elements with data-icon attribute */
function initIcons() {
  document.querySelectorAll('[data-icon]').forEach(el => {
    setIcon(el, el.dataset.icon);
  });
}

// ── Bottom Navigation ────────────────────────────────────

/** Build the bottom navigation bar HTML */
function buildBottomNav(activePage) {
  const navItems = [
    { id: 'home',        label: 'Home',     icon: 'home',    page: '05-home.html' },
    { id: 'matches',     label: 'Matches',  icon: 'matches', page: '18-match-history.html' },
    { id: 'tournaments', label: 'Tourneys',  icon: 'trophy',  page: '19-tournaments-list.html' },
    { id: 'teams',       label: 'Teams',    icon: 'teams',   page: '06-teams-list.html' },
    { id: 'profile',     label: 'Profile',  icon: 'profile', page: '17-player-profile.html' },
  ];

  return navItems.map(item => {
    const isActive = item.id === activePage ? ' active' : '';
    return `<a href="${item.page}" class="nav-item${isActive}" onclick="event.preventDefault(); navigateTo('${item.page}');">
      <span class="nav-icon">${ICONS[item.icon]}</span>
      <span>${item.label}</span>
    </a>`;
  }).join('');
}

/** Initialize the bottom navigation in the current page */
function initBottomNav(activePage) {
  const nav = document.querySelector('.bottom-nav');
  if (nav) {
    nav.innerHTML = buildBottomNav(activePage);
  }
}

// ── Tab Switching ────────────────────────────────────────

/** Initialize tab switching behavior */
function initTabs() {
  document.querySelectorAll('.tabs').forEach(tabBar => {
    const tabs = tabBar.querySelectorAll('.tab');
    const container = tabBar.parentElement;
    const panels = container.querySelectorAll('.tab-panel');

    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        const target = tab.dataset.tab;

        // Update tab active state
        tabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        // Update panel visibility
        panels.forEach(panel => {
          panel.classList.toggle('active', panel.dataset.panel === target);
        });
      });
    });
  });
}

// ── Modal / Bottom Sheet ─────────────────────────────────

/** Open a modal by ID */
function openModal(modalId) {
  const overlay = document.getElementById(modalId);
  if (overlay) {
    overlay.classList.add('active');
    document.body.style.overflow = 'hidden';
  }
}

/** Close a modal by ID */
function closeModal(modalId) {
  const overlay = document.getElementById(modalId);
  if (overlay) {
    overlay.classList.remove('active');
    document.body.style.overflow = '';
  }
}

/** Close modal when clicking on overlay background */
function initModalCloseOnOverlay() {
  document.querySelectorAll('.modal-overlay, .bottom-sheet-overlay').forEach(overlay => {
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        overlay.classList.remove('active');
        document.body.style.overflow = '';
      }
    });
  });
}

// ── Chip Selection ───────────────────────────────────────

/** Initialize chip group selection (single-select) */
function initChipGroups() {
  document.querySelectorAll('.chip-group').forEach(group => {
    const chips = group.querySelectorAll('.chip');
    chips.forEach(chip => {
      chip.addEventListener('click', () => {
        chips.forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        // Dispatch custom event
        group.dispatchEvent(new CustomEvent('chip-change', { detail: { value: chip.dataset.value } }));
      });
    });
  });
}

// ── Toggle Groups ────────────────────────────────────────

/** Initialize toggle groups */
function initToggleGroups() {
  document.querySelectorAll('.toggle-group').forEach(group => {
    const options = group.querySelectorAll('.toggle-option');
    options.forEach(option => {
      option.addEventListener('click', () => {
        options.forEach(o => o.classList.remove('active'));
        option.classList.add('active');
        group.dispatchEvent(new CustomEvent('toggle-change', { detail: { value: option.dataset.value } }));
      });
    });
  });
}

// ── Selection Cards ──────────────────────────────────────

/** Initialize selection cards (within a group) */
function initSelectionCards() {
  document.querySelectorAll('[data-selection-group]').forEach(group => {
    const cards = group.querySelectorAll('.selection-card');
    cards.forEach(card => {
      card.addEventListener('click', () => {
        cards.forEach(c => c.classList.remove('selected'));
        card.classList.add('selected');
        group.dispatchEvent(new CustomEvent('selection-change', { detail: { value: card.dataset.value } }));
      });
    });
  });
}

// ── Form Validation ──────────────────────────────────────

/** Validate a phone number (10 digits) */
function validatePhone(value) {
  return /^[6-9]\d{9}$/.test(value.replace(/\s/g, ''));
}

/** Validate that a field is not empty */
function validateRequired(value) {
  return value.trim().length > 0;
}

/** Validate overs (1-50) */
function validateOvers(value) {
  const num = parseInt(value);
  return num >= 1 && num <= 50;
}

/** Show error on an input */
function showInputError(inputEl, message) {
  inputEl.classList.add('error');
  const errorEl = inputEl.parentElement.querySelector('.input-error');
  if (errorEl) errorEl.textContent = message;
}

/** Clear error on an input */
function clearInputError(inputEl) {
  inputEl.classList.remove('error');
  const errorEl = inputEl.parentElement.querySelector('.input-error');
  if (errorEl) errorEl.textContent = '';
}

// ── OTP Input ────────────────────────────────────────────

/** Initialize OTP input auto-advance behavior */
function initOtpInputs() {
  const otpInputs = document.querySelectorAll('.otp-input');
  if (otpInputs.length === 0) return;

  otpInputs.forEach((input, index) => {
    input.addEventListener('input', (e) => {
      const value = e.target.value;
      if (value.length === 1 && index < otpInputs.length - 1) {
        otpInputs[index + 1].focus();
      }
      // Check if all filled
      const allFilled = Array.from(otpInputs).every(inp => inp.value.length === 1);
      if (allFilled) {
        document.dispatchEvent(new CustomEvent('otp-complete', {
          detail: { otp: Array.from(otpInputs).map(inp => inp.value).join('') }
        }));
      }
    });

    input.addEventListener('keydown', (e) => {
      if (e.key === 'Backspace' && !input.value && index > 0) {
        otpInputs[index - 1].focus();
      }
    });

    // Allow only single digit
    input.addEventListener('beforeinput', (e) => {
      if (e.data && !/^\d$/.test(e.data)) {
        e.preventDefault();
      }
    });
  });
}

// ── Countdown Timer ──────────────────────────────────────

/** Start a countdown timer */
function startCountdown(elementId, seconds, onComplete) {
  const el = document.getElementById(elementId);
  if (!el) return;

  let remaining = seconds;
  const update = () => {
    const mins = Math.floor(remaining / 60);
    const secs = remaining % 60;
    el.textContent = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

    if (remaining <= 0) {
      clearInterval(timer);
      if (onComplete) onComplete();
    }
    remaining--;
  };

  update();
  const timer = setInterval(update, 1000);
  return timer;
}

// ── Scoring State (for scoring page) ─────────────────────

class ScoringState {
  constructor() {
    this.team1 = 'Mumbai Warriors';
    this.team2 = 'Delhi Strikers';
    this.totalOvers = 20;
    this.currentInnings = 1;
    this.runs = 87;
    this.wickets = 3;
    this.overs = 12;
    this.balls = 4;
    this.target = null;

    // Current batsmen
    this.striker = { name: 'Karan Singh', R: 34, B: 22, fours: 3, sixes: 2 };
    this.nonStriker = { name: 'Aditya Joshi', R: 12, B: 8, fours: 1, sixes: 0 };

    // Current bowler
    this.bowler = { name: 'Sachin Kulkarni', O: 2.4, M: 1, R: 14, W: 1 };

    // Current over balls
    this.currentOverBalls = [
      { type: 'dot', display: '0' },
      { type: 'runs', display: '1' },
      { type: 'four', display: '4' },
      { type: 'dot', display: '0' },
    ];

    // Delivery history (for undo)
    this.history = [];

    // State flags
    this.isFreeHit = false;

    // Listeners
    this.listeners = [];
  }

  subscribe(fn) {
    this.listeners.push(fn);
  }

  notify() {
    this.listeners.forEach(fn => fn(this));
  }

  get currentRunRate() {
    const totalBalls = this.overs * 6 + this.balls;
    if (totalBalls === 0) return '0.00';
    return ((this.runs / totalBalls) * 6).toFixed(2);
  }

  get requiredRunRate() {
    if (!this.target || this.currentInnings !== 2) return null;
    const remainingRuns = this.target - this.runs;
    const remainingBalls = (this.totalOvers * 6) - (this.overs * 6 + this.balls);
    if (remainingBalls <= 0) return '-.--';
    return ((remainingRuns / remainingBalls) * 6).toFixed(2);
  }

  get oversDisplay() {
    return `${this.overs}.${this.balls}`;
  }

  get strikerSR() {
    return this.striker.B > 0 ? ((this.striker.R / this.striker.B) * 100).toFixed(1) : '0.0';
  }

  get nonStrikerSR() {
    return this.nonStriker.B > 0 ? ((this.nonStriker.R / this.nonStriker.B) * 100).toFixed(1) : '0.0';
  }

  get bowlerEconomy() {
    const bowlerOvers = Math.floor(this.bowler.O) + (this.bowler.O % 1) * 10 / 6;
    return bowlerOvers > 0 ? (this.bowler.R / bowlerOvers).toFixed(2) : '0.00';
  }

  addRuns(runs) {
    // Save state for undo
    this.saveState();

    // Update score
    this.runs += runs;
    this.striker.R += runs;
    this.striker.B += 1;
    this.bowler.R += runs;

    if (runs === 4) this.striker.fours += 1;
    if (runs === 6) this.striker.sixes += 1;

    // Ball indicator
    let type = 'dot';
    if (runs === 4) type = 'four';
    else if (runs === 6) type = 'six';
    else if (runs > 0) type = 'runs';
    this.currentOverBalls.push({ type, display: runs.toString() });

    // Advance ball count
    this.advanceBall();

    // Rotate strike on odd runs
    if (runs % 2 === 1) this.rotateStrike();

    // Clear free hit
    this.isFreeHit = false;

    this.notify();
  }

  addWide(additionalRuns) {
    this.saveState();
    const totalRuns = 1 + (additionalRuns || 0);
    this.runs += totalRuns;
    this.bowler.R += totalRuns;
    // Wide doesn't count as a ball faced
    this.currentOverBalls.push({ type: 'wide', display: `Wd${additionalRuns > 0 ? '+' + additionalRuns : ''}` });
    // No ball advance (wide is not legal)
    if (additionalRuns % 2 === 1) this.rotateStrike();
    this.notify();
  }

  addNoBall(additionalRuns) {
    this.saveState();
    const totalRuns = 1 + (additionalRuns || 0);
    this.runs += totalRuns;
    this.striker.R += (additionalRuns || 0);
    this.striker.B += 1;
    this.bowler.R += totalRuns;
    this.currentOverBalls.push({ type: 'noball', display: `NB${additionalRuns > 0 ? '+' + additionalRuns : ''}` });
    // No ball advance; next ball is free hit
    this.isFreeHit = true;
    if (additionalRuns % 2 === 1) this.rotateStrike();
    this.notify();
  }

  addBye(runs) {
    this.saveState();
    this.runs += runs;
    this.striker.B += 1;
    // Byes don't count against bowler
    this.currentOverBalls.push({ type: 'runs', display: `B${runs}` });
    this.advanceBall();
    if (runs % 2 === 1) this.rotateStrike();
    this.isFreeHit = false;
    this.notify();
  }

  addLegBye(runs) {
    this.saveState();
    this.runs += runs;
    this.striker.B += 1;
    this.currentOverBalls.push({ type: 'runs', display: `LB${runs}` });
    this.advanceBall();
    if (runs % 2 === 1) this.rotateStrike();
    this.isFreeHit = false;
    this.notify();
  }

  addWicket() {
    this.saveState();
    this.wickets += 1;
    this.striker.B += 1;
    this.bowler.W += 1;
    this.currentOverBalls.push({ type: 'wicket', display: 'W' });
    this.advanceBall();
    this.isFreeHit = false;
    this.notify();
  }

  advanceBall() {
    this.balls += 1;
    // Update bowler overs
    const bowlerBalls = Math.round((this.bowler.O % 1) * 10) + 1;
    if (bowlerBalls >= 6) {
      this.bowler.O = Math.floor(this.bowler.O) + 1;
    } else {
      this.bowler.O = Math.floor(this.bowler.O) + bowlerBalls / 10;
    }

    if (this.balls >= 6) {
      this.overs += 1;
      this.balls = 0;
      this.currentOverBalls = [];
      // Rotate strike at end of over
      this.rotateStrike();
    }
  }

  rotateStrike() {
    const temp = this.striker;
    this.striker = this.nonStriker;
    this.nonStriker = temp;
  }

  saveState() {
    this.history.push(JSON.stringify({
      runs: this.runs, wickets: this.wickets, overs: this.overs, balls: this.balls,
      striker: { ...this.striker }, nonStriker: { ...this.nonStriker },
      bowler: { ...this.bowler }, currentOverBalls: [...this.currentOverBalls],
      isFreeHit: this.isFreeHit,
    }));
  }

  undo() {
    if (this.history.length === 0) return;
    const prev = JSON.parse(this.history.pop());
    Object.assign(this, prev);
    this.notify();
  }
}

// ── Initialization ───────────────────────────────────────

/** Main initialization — call on every page DOMContentLoaded */
function initApp() {
  initIcons();
  initTabs();
  initModalCloseOnOverlay();
  initChipGroups();
  initToggleGroups();
  initSelectionCards();
  initOtpInputs();
}

// Auto-init on DOMContentLoaded
document.addEventListener('DOMContentLoaded', initApp);
