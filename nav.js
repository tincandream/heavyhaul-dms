// ============================================================
// nav.js
// HEAVY HAUL COMMAND — GLOBAL NAVIGATION
//
// ROW 1:
// HEAVY HAUL COMMAND
//
// ROW 2:
// Welcome | Dispatch | Sourcing | Fleet Command
//                  Dianna V. Mwaka (Owner) | Sign Out
//
// Hub-specific tools DO NOT belong here.
// ============================================================


// ============================================================
// GLOBAL HUBS
// ============================================================

const MAIN_NAV = [
  ['welcome.html', 'Welcome'],
  ['board.html', 'Dispatch'],
  ['sourcing.html', 'Sourcing'],
  ['fleet-command.html', 'Fleet Command']
];


// ============================================================
// PAGES THAT BELONG TO EACH HUB
// Used only to keep the correct hub highlighted.
// ============================================================

const HUB_PAGES = {

  'welcome.html': [
    'welcome.html'
  ],

  'dispatch.html': [
    'dispatch.html',
    'board.html',
    'newload.html',
    'loads.html',
    'workspace.html'
  ],

  'sourcing.html': [
    'sourcing.html',
    'opportunities.html',
    'call-queue.html',
    'portals.html',
    'load-emails.html',
    'templates.html',
    'field-manual.html',
    'calculators.html'
  ],

  'fleet-command.html': [
    'fleet-command.html',
    'fleet.html',
    'route-planning.html',
    'states.html',
    'calendar.html'
  ]

};


// ============================================================
// FIND CURRENT HUB
// ============================================================

function getCurrentHub(currentPage) {

  for (const hub in HUB_PAGES) {

    if (HUB_PAGES[hub].includes(currentPage)) {
      return hub;
    }

  }

  return 'welcome.html';
}


// ============================================================
// BUILD NAV
// ============================================================

async function buildNav(dbClient, title) {

  const here =
    location.pathname.split('/').pop() || 'welcome.html';

  const activeHub =
    getCurrentHub(here);

  const header =
    document.querySelector('header');


  if (!header) {

    console.warn(
      'nav.js: no <header> element found on this page'
    );

    return null;
  }


  // ==========================================================
  // REMOVE OLD SIDEBAR BEHAVIOR
  // ==========================================================

  header.innerHTML = '';
  header.removeAttribute('style');

  document.body.style.paddingLeft = '0';
  document.body.style.margin = '0';


  // ==========================================================
  // BASIC HEADER
  // ==========================================================

  header.style.width = '100%';
  header.style.background = '#ffffff';
  header.style.borderBottom = '1px solid #dddddd';
  header.style.position = 'relative';
  header.style.zIndex = '1000';


  // ==========================================================
  // ROW 1 — HEAVY HAUL COMMAND
  // ==========================================================

  const brandRow =
    document.createElement('div');

  brandRow.style.display = 'flex';
  brandRow.style.alignItems = 'center';
  brandRow.style.minHeight = '54px';
  brandRow.style.padding = '0 26px';
  brandRow.style.borderBottom = '1px solid #eeeeee';


  const brand =
    document.createElement('a');

  brand.href =
    'welcome.html';

  brand.textContent =
    'HEAVY HAUL COMMAND';

  brand.style.color =
    '#222222';

  brand.style.fontSize =
    '16px';

  brand.style.fontWeight =
    '700';

  brand.style.letterSpacing =
    '1.4px';

  brand.style.textDecoration =
    'none';


  brandRow.appendChild(
    brand
  );

  header.appendChild(
    brandRow
  );


  // ==========================================================
  // ROW 2 — HUBS + USER + SIGN OUT
  // ==========================================================

  const navRow =
    document.createElement('div');

  navRow.style.display =
    'flex';

  navRow.style.alignItems =
    'center';

  navRow.style.width =
    '100%';

  navRow.style.minHeight =
    '48px';

  navRow.style.padding =
    '0 26px';

  navRow.style.gap =
    '20px';

  navRow.style.boxSizing =
    'border-box';


  // ==========================================================
  // HUB LINKS
  // ==========================================================

  const nav =
    document.createElement('nav');

  nav.style.display =
    'flex';

  nav.style.alignItems =
    'center';

  nav.style.gap =
    '0';

  nav.style.flexShrink =
    '0';


  MAIN_NAV.forEach(
    function (item) {

      const href =
        item[0];

      const label =
        item[1];


      const link =
        document.createElement('a');

      link.href =
        href;

      link.textContent =
        label;


      link.style.display =
        'flex';

      link.style.alignItems =
        'center';

      link.style.minHeight =
        '48px';

      link.style.padding =
        '0 17px';

      link.style.textDecoration =
        'none';

      link.style.fontSize =
        '13px';

      link.style.fontWeight =
        '600';

      link.style.whiteSpace =
        'nowrap';

      link.style.borderBottom =
        '3px solid transparent';


      if (href === activeHub) {

        link.style.color =
          '#111111';

        link.style.borderBottomColor =
          '#555555';

      }

      else {

        link.style.color =
          '#666666';

      }


      link.addEventListener(
        'mouseenter',
        function () {

          if (href !== activeHub) {
            link.style.color = '#222222';
          }

        }
      );


      link.addEventListener(
        'mouseleave',
        function () {

          if (href !== activeHub) {
            link.style.color = '#666666';
          }

        }
      );


      nav.appendChild(
        link
      );

    }
  );


  navRow.appendChild(
    nav
  );


  // ==========================================================
  // USER AREA — SAME LINE
  // ==========================================================

  const userArea =
    document.createElement('div');

  userArea.style.marginLeft =
    'auto';

  userArea.style.display =
    'flex';

  userArea.style.alignItems =
    'center';

  userArea.style.gap =
    '9px';

  userArea.style.whiteSpace =
    'nowrap';


  const who =
    document.createElement('span');

  who.id =
    'me';

  who.textContent =
    '…';

  who.style.color =
    '#666666';

  who.style.fontSize =
    '12px';


  const divider =
    document.createElement('span');

  divider.textContent =
    '|';

  divider.style.color =
    '#bbbbbb';

  divider.style.fontSize =
    '12px';


  const signOut =
    document.createElement('button');

  signOut.type =
    'button';

  signOut.textContent =
    'Sign Out';

  signOut.style.padding =
    '0';

  signOut.style.margin =
    '0';

  signOut.style.background =
    'transparent';

  signOut.style.border =
    '0';

  signOut.style.color =
    '#555555';

  signOut.style.fontSize =
    '12px';

  signOut.style.fontWeight =
    '400';

  signOut.style.cursor =
    'pointer';

  signOut.style.fontFamily =
    'inherit';


  signOut.addEventListener(
    'mouseenter',
    function () {

      signOut.style.color =
        '#111111';

    }
  );


  signOut.addEventListener(
    'mouseleave',
    function () {

      signOut.style.color =
        '#555555';

    }
  );


  signOut.addEventListener(
    'click',
    async function () {

      await dbClient.auth.signOut();

      location.href =
        'index.html';

    }
  );


  userArea.appendChild(
    who
  );

  userArea.appendChild(
    divider
  );

  userArea.appendChild(
    signOut
  );


  navRow.appendChild(
    userArea
  );


  header.appendChild(
    navRow
  );


  // ==========================================================
  // PROFILE LOOKUP
  // ==========================================================

  const session =
    await dbClient.auth.getUser();


  const authId =
    session.data &&
    session.data.user
      ? session.data.user.id
      : null;


  let me =
    await dbClient
      .from('app_users')
      .select('full_name, role, tenant_id')
      .eq('auth_uid', authId)
      .maybeSingle();


  // Preserve original fallback.

  if (
    !me.error &&
    !me.data
  ) {

    me =
      await dbClient
        .from('app_users')
        .select('full_name, role, tenant_id')
        .limit(1)
        .maybeSingle();

  }


  if (me.error) {

    who.textContent =
      'Profile error';

    console.error(
      'nav.js: app_users query failed —',
      me.error.message
    );

    return null;
  }


  if (!me.data) {

    who.textContent =
      'No profile linked';

    return null;
  }


  // ==========================================================
  // NAME + ROLE
  // ==========================================================

  const fullName =
    me.data.full_name || 'User';


  const role =
    me.data.role || 'User';


  const formattedRole =
    role.charAt(0).toUpperCase() +
    role.slice(1);


  who.textContent =
    fullName +
    ' (' +
    formattedRole +
    ')';


  return me.data.tenant_id;
}
