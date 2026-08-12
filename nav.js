// ============================================================
// nav.js
// HEAVY HAUL COMMAND — SHARED GLOBAL NAVIGATION
// ============================================================

(function () {
'use strict';

const MAIN_NAV = [
  ['welcome.html',  'Welcome',       'welcome'],
  ['fleet.html',    'Fleet Command', 'fleet'],
  ['sourcing.html', 'Sourcing',      'sourcing'],
  ['board.html',    'Dispatch',      'dispatch']
];

const HUB_PAGES = {

welcome: ['welcome.html'],

dispatch: [
  'dispatch.html',
  'board.html',
  'newload.html',
  'loads.html',
  'workspace.html'
],

sourcing: [
  'sourcing.html',
  'opportunities.html',
  'call-queue.html',
  'portals.html',
  'load-emails.html',
  'inbox.html',
  'templates.html',
  'calculators.html',
  'manual.html',
  'field-manual.html',
  'testing.html'
],

fleet: [
  'fleet-command.html',
  'fleet.html',
  'route-planning.html',
  'states.html',
  'calendar.html'
]

};

function currentPage() {
  return (location.pathname.split('/').pop() || 'welcome.html');
}

function currentHub(page) {
  for (const [hub, pages] of Object.entries(HUB_PAGES)) {
    if (pages.includes(page)) {
      return hub;
    }
  }
  return 'welcome';
}

function setStyles(element, styles) {
  Object.assign(element.style, styles);
  return element;
}


async function buildNav(dbClient, title) {

const header =
  document.querySelector('header');

if (!header) {
  console.warn('nav.js: no <header> element on this page');
  return null;
}

const activeHub =
  currentHub(currentPage());

// --------------------------------------------------------
// RESET SHARED HEADER
// --------------------------------------------------------

header.innerHTML = '';

header.removeAttribute('style');

document.body.style.paddingLeft = '0';

setStyles(header, {
  width: '100%',
  display: 'block',
  visibility: 'visible',
  opacity: '1',
  background: '#ffffff',
  borderBottom: '1px solid #dddddd',
  position: 'relative',
  zIndex: '1000',
  boxSizing: 'border-box'
});

// --------------------------------------------------------
// BRAND ROW
// --------------------------------------------------------

const brandRow = setStyles(
  document.createElement('div'),
  {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    minHeight: '54px',
    padding: '0 26px',
    borderBottom: '1px solid #eeeeee',
    boxSizing: 'border-box'
  }
);

const brand = setStyles(
  document.createElement('a'),
  {
    color: '#222222',
    fontSize: '16px',
    fontWeight: '700',
    letterSpacing: '1.4px',
    textDecoration: 'none',
    whiteSpace: 'nowrap'
  }
);

brand.href = 'welcome.html';

brand.innerHTML = `
  <img
    src="images/hhlogo.png"
    alt="Heavy Haul Command"
    class="hh-header-logo"
  >
`;

// make the brand a flex row so the icon sits beside the text
brand.style.display = 'flex';
brand.style.alignItems = 'center';
brand.style.gap = '11px';

// --------------------------------------------------------
// TRUCK MARK
// --------------------------------------------------------

const truck =
  document.createElement('span');

truck.setAttribute('aria-hidden', 'true');

truck.style.cssText =
  'display:flex;align-items:center;flex-shrink:0;';

truck.innerHTML = `
<svg width="46" height="26" viewBox="0 0 92 52"
     fill="none" xmlns="http://www.w3.org/2000/svg">

  <!-- lowboy deck -->
  <path d="M30 34 H62 L66 28 H74"
        stroke="#3C3A4B" stroke-width="3"
        stroke-linecap="round" stroke-linejoin="round"/>

  <!-- gooseneck rise to tractor -->
  <path d="M30 34 L26 26 H22"
        stroke="#3C3A4B" stroke-width="3"
        stroke-linecap="round" stroke-linejoin="round"/>

  <!-- machine on the deck -->
  <path d="M36 34 V22 H52 V34"
        stroke="#B8B05D" stroke-width="3"
        stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M40 22 V16 H48 V22"
        stroke="#B8B05D" stroke-width="2.5"
        stroke-linecap="round" stroke-linejoin="round"/>

  <!-- tractor cab -->
  <path d="M22 26 V14 H12 L6 22 V34 H14"
        stroke="#3C3A4B" stroke-width="3"
        stroke-linecap="round" stroke-linejoin="round"/>

  <!-- cab window -->
  <path d="M12 18 H18 V23 H9 Z"
        fill="#C0656B" opacity="0.55"/>

  <!-- wheels -->
  <circle cx="18" cy="38" r="5"
          stroke="#3C3A4B" stroke-width="3" fill="none"/>
  <circle cx="58" cy="38" r="5"
          stroke="#3C3A4B" stroke-width="3" fill="none"/>
  <circle cx="70" cy="38" r="5"
          stroke="#3C3A4B" stroke-width="3" fill="none"/>

  <!-- ground line -->
  <path d="M2 44 H90"
        stroke="#B8B05D" stroke-width="2"
        stroke-linecap="round" opacity="0.5"/>

</svg>`;

brand.prepend(truck);

brandRow.appendChild(
  brand
);


  
header.appendChild(brandRow);

// --------------------------------------------------------
// MAIN HUB ROW
// --------------------------------------------------------

const navRow = setStyles(
  document.createElement('div'),
  {
    display: 'flex',
    alignItems: 'center',
    width: '100%',
    minHeight: '48px',
    padding: '0 26px',
    boxSizing: 'border-box',
    overflowX: 'auto',
    background: '#ffffff'
  }
);

const nav = setStyles(
  document.createElement('nav'),
  {
    display: 'flex',
    alignItems: 'center',
    flexShrink: '0'
  }
);

nav.setAttribute('aria-label', 'Main navigation');

MAIN_NAV.forEach(([href, label, hub]) => {

  const link = setStyles(
    document.createElement('a'),
    {
      display: 'flex',
      alignItems: 'center',
      minHeight: '48px',
      padding: '0 17px',
      textDecoration: 'none',
      fontSize: '13px',
      fontWeight: '600',
      whiteSpace: 'nowrap',
      borderBottom: '3px solid transparent',
      color: hub === activeHub ? '#111111' : '#666666'
    }
  );

  link.href = href;
  link.textContent = label;

  if (hub === activeHub) {
    link.style.borderBottomColor = '#6B92A5';
    link.setAttribute('aria-current', 'page');
  }

  nav.appendChild(link);
});

navRow.appendChild(nav);

// --------------------------------------------------------
// USER / SIGN OUT
// --------------------------------------------------------

const userArea = setStyles(
  document.createElement('div'),
  {
    marginLeft: 'auto',
    display: 'flex',
    alignItems: 'center',
    gap: '9px',
    paddingLeft: '18px',
    whiteSpace: 'nowrap'
  }
);

const who = setStyles(
  document.createElement('span'),
  {
    color: '#666666',
    fontSize: '12px'
  }
);

who.id = 'me';

const divider = setStyles(
  document.createElement('span'),
  {
    color: '#bbbbbb',
    fontSize: '12px'
  }
);

divider.textContent = '|';

const signOut = setStyles(
  document.createElement('button'),
  {
    padding: '0',
    margin: '0',
    border: '0',
    background: 'transparent',
    color: '#555555',
    fontSize: '12px',
    cursor: 'pointer',
    fontFamily: 'inherit'
  }
);

signOut.type = 'button';
signOut.textContent = 'Sign Out';

signOut.addEventListener('click', async () => {
  await dbClient.auth.signOut();
  location.href = 'index.html';
});

userArea.append(who, divider, signOut);

navRow.appendChild(userArea);
header.appendChild(navRow);

// --------------------------------------------------------
// GET LOGGED-IN USER
// --------------------------------------------------------

const userResult =
  await dbClient.auth.getUser();

const authId =
  userResult &&
  userResult.data &&
  userResult.data.user
    ? userResult.data.user.id
    : null;

if (!authId) {
  who.textContent = 'Not signed in';
  return null;
}

// --------------------------------------------------------
// GET APP PROFILE
// --------------------------------------------------------

let me =
  await dbClient
    .from('app_users')
    .select('full_name, role, tenant_id')
    .eq('auth_uid', authId)
    .maybeSingle();

// Fallback for existing single-profile setup.

if (!me.error && !me.data) {
  me =
    await dbClient
      .from('app_users')
      .select('full_name, role, tenant_id')
      .limit(1)
      .maybeSingle();
}

if (me.error) {
  who.textContent = 'Profile error';
  console.error(
    'nav.js: app_users query failed:',
    me.error.message
  );
  return null;
}

if (!me.data) {
  who.textContent = 'No profile linked';
  return null;
}

// --------------------------------------------------------
// DISPLAY USER
// --------------------------------------------------------

const fullName =
  me.data.full_name || 'User';

const role =
  me.data.role || 'User';

const formattedRole =
  role.charAt(0).toUpperCase() +
  role.slice(1);

who.textContent =
  `${fullName} (${formattedRole})`;

// --------------------------------------------------------
// TRAINING MODE BADGE
// --------------------------------------------------------

try {

  const ts =
    await dbClient.rpc('get_training_mode_status');

  if (
    !ts.error &&
    ts.data &&
    ts.data.active === true
  ) {

    const badge =
      document.createElement('span');

    badge.textContent = 'TRAINING';

    badge.title =
      ts.data.expires_at
        ? 'Training Mode active until ' +
          new Date(ts.data.expires_at).toLocaleString()
        : 'Training Mode active';

    badge.style.cssText =
      'background:#B8B05D;color:#3C3A4B;' +
      'font-family:Oswald,sans-serif;font-size:11px;' +
      'font-weight:600;letter-spacing:.8px;' +
      'padding:3px 9px;border-radius:3px;' +
      'text-transform:uppercase;white-space:nowrap;';

    userArea.insertBefore(badge, who);

  }

} catch (e) {

  // training mode unavailable — no badge

}

// --------------------------------------------------------
// RETURN TENANT
// --------------------------------------------------------

return (
  me.data.tenant_id
);

}

// ==========================================================
// MAKE buildNav AVAILABLE TO EVERY PAGE
// ==========================================================

window.buildNav = buildNav;

})();
