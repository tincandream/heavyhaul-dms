// ============================================================
// nav.js
// HEAVY HAUL COMMAND — SHARED GLOBAL NAVIGATION
// ============================================================

(function () {
'use strict';


// ============================================================
// MAIN NAVIGATION
// ============================================================

const MAIN_NAV = [
  ['welcome.html',  '★ Welcome',     'welcome'],
  ['fleet.html',    'Fleet Command', 'fleet'],
  ['sourcing.html', 'Sourcing',      'sourcing'],
  ['board.html',    'Dispatch',      'dispatch']
];


// ============================================================
// HUB PAGE GROUPS
// Used to determine which main navigation tab is active.
// ============================================================

const HUB_PAGES = {

  welcome: [
    'welcome.html'
  ],

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


// ============================================================
// SOURCING SUB NAVIGATION
// ============================================================

const SOURCING_NAV = [
  ['sourcing.html',     'Opportunities'],
  ['call-queue.html',   'Call Queue'],
  ['portals.html',      'Portals'],
  ['load-emails.html',  'Load Emails'],
  ['templates.html',    'Templates'],
  ['calculators.html',  'Calculators'],
  ['field-manual.html', 'Field Manual']
];


// ============================================================
// FLEET COMMAND SUB NAVIGATION
// ============================================================

const FLEET_NAV = [
  ['fleet.html',          'Fleet Setup'],
  ['route-planning.html', 'Route Planning'],
  ['states.html',         'State Rules'],
  ['calendar.html',       'Calendar']
];


// ============================================================
// DISPATCH SUB NAVIGATION
// ============================================================

const DISPATCH_NAV = [
  ['board.html',   'Fleet Board'],
  ['newload.html', 'New Load'],
  ['loads.html',   'All Loads']
];


// ============================================================
// PAGE HELPERS
// ============================================================

function currentPage() {
  return (
    location.pathname.split('/').pop() ||
    'welcome.html'
  );
}


function currentHub(page) {

  for (
    const [hub, pages]
    of Object.entries(HUB_PAGES)
  ) {

    if (pages.includes(page)) {
      return hub;
    }

  }

  return 'welcome';
}


function setStyles(element, styles) {

  Object.assign(
    element.style,
    styles
  );

  return element;
}


// ============================================================
// BUILD SUB NAVIGATION
// ============================================================

function buildSubNav(
  items,
  activePage,
  ariaLabel
) {

  const row = setStyles(
    document.createElement('div'),
    {
      display: 'flex',
      alignItems: 'center',
      width: '100%',
      minHeight: '44px',
      padding: '0 26px',
      boxSizing: 'border-box',
      overflowX: 'auto',
      background: '#ffffff',
      borderTop: '1px solid #f2f2f2'
    }
  );


  const nav = setStyles(
    document.createElement('nav'),
    {
      display: 'flex',
      alignItems: 'center',
      gap: '24px',
      flexShrink: '0'
    }
  );


  nav.setAttribute(
    'aria-label',
    ariaLabel
  );


  items.forEach(
    ([href, label]) => {

      const link = setStyles(
        document.createElement('a'),
        {
          display: 'flex',
          alignItems: 'center',
          minHeight: '44px',
          padding: '0 0 8px',
          textDecoration: 'none',
          fontSize: '12.5px',
          fontWeight: '600',
          whiteSpace: 'nowrap',
          borderBottom:
            '3px solid transparent',

          color:
            href === activePage
              ? '#111111'
              : '#73726c'
        }
      );


      link.href = href;
      link.textContent = label;


      if (href === activePage) {

        link.style.borderBottomColor =
          '#B8C34A';

        link.setAttribute(
          'aria-current',
          'page'
        );

      }


      nav.appendChild(link);

    }
  );


  row.appendChild(nav);

  return row;
}


// ============================================================
// BUILD GLOBAL NAVIGATION
// ============================================================

async function buildNav(
  dbClient,
  title
) {

  const header =
    document.querySelector('header');


  if (!header) {

    console.warn(
      'nav.js: no <header> element on this page'
    );

    return null;

  }


  const page =
    currentPage();


  const activeHub =
    currentHub(page);


  // --------------------------------------------------------
  // RESET SHARED HEADER
  // --------------------------------------------------------

  header.innerHTML = '';

  header.removeAttribute('style');

  document.body.style.paddingLeft =
    '0';


  setStyles(
    header,
    {
      width: '100%',
      display: 'block',
      visibility: 'visible',
      opacity: '1',
      background: '#ffffff',
      borderBottom:
        '1px solid #dddddd',
      position: 'relative',
      zIndex: '1000',
      boxSizing: 'border-box'
    }
  );


  // ========================================================
  // BRAND ROW
  // ========================================================

  const brandRow = setStyles(
    document.createElement('div'),
    {
      display: 'flex',
      alignItems: 'center',
      justifyContent:
        'space-between',

      minHeight: '54px',

      padding:
        '0 26px',

      borderBottom:
        '1px solid #eeeeee',

      boxSizing:
        'border-box'
    }
  );


  const brand = setStyles(
    document.createElement('a'),
    {
      display: 'flex',
      alignItems: 'center',
      justifyContent:
        'flex-start',

      width: '100%',

      color: '#222222',

      textDecoration:
        'none'
    }
  );


  brand.href =
    'welcome.html';


  brand.innerHTML = `
    <img
      src="images/hhlogo.png"
      alt="Heavy Haul Command"
      style="
        display:block;
        width:auto;
        height:auto;
        max-width:900px;
        max-height:90px;
        object-fit:contain;
      "
    >
  `;


  brandRow.appendChild(
    brand
  );


  header.appendChild(
    brandRow
  );


  // ========================================================
  // MAIN HUB NAVIGATION
  // ========================================================

  const navRow = setStyles(
    document.createElement('div'),
    {
      display: 'flex',
      alignItems: 'center',
      width: '100%',

      minHeight: '48px',

      padding:
        '0 26px',

      boxSizing:
        'border-box',

      overflowX:
        'auto',

      background:
        '#ffffff'
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


  nav.setAttribute(
    'aria-label',
    'Main navigation'
  );


  MAIN_NAV.forEach(
    ([href, label, hub]) => {

      const link = setStyles(
        document.createElement('a'),
        {
          display: 'flex',
          alignItems: 'center',

          minHeight:
            '48px',

          padding:
            '0 17px',

          textDecoration:
            'none',

          fontSize:
            '13px',

          fontWeight:
            '600',

          whiteSpace:
            'nowrap',

          borderBottom:
            '3px solid transparent',

          color:
            hub === activeHub
              ? '#111111'
              : '#666666'
        }
      );


      link.href =
        href;


      link.textContent =
        label;


      if (
        hub === activeHub
      ) {

        link.style
          .borderBottomColor =
          '#6B92A5';


        link.setAttribute(
          'aria-current',
          'page'
        );

      }


      nav.appendChild(
        link
      );

    }
  );


  navRow.appendChild(
    nav
  );


  // ========================================================
  // USER / SIGN OUT
  // ========================================================

  const userArea = setStyles(
    document.createElement('div'),
    {
      marginLeft: 'auto',

      display: 'flex',

      alignItems:
        'center',

      gap: '9px',

      paddingLeft:
        '18px',

      whiteSpace:
        'nowrap'
    }
  );


  const who = setStyles(
    document.createElement('span'),
    {
      color:
        '#666666',

      fontSize:
        '12px'
    }
  );


  who.id =
    'me';


  const divider = setStyles(
    document.createElement('span'),
    {
      color:
        '#bbbbbb',

      fontSize:
        '12px'
    }
  );


  divider.textContent =
    '|';


  const signOut = setStyles(
    document.createElement('button'),
    {
      padding: '0',
      margin: '0',
      border: '0',

      background:
        'transparent',

      color:
        '#555555',

      fontSize:
        '12px',

      cursor:
        'pointer',

      fontFamily:
        'inherit'
    }
  );


  signOut.type =
    'button';


  signOut.textContent =
    'Sign Out';


  signOut.addEventListener(
    'click',

    async () => {

      await dbClient
        .auth
        .signOut();


      location.href =
        'index.html';

    }
  );


  userArea.append(
    who,
    divider,
    signOut
  );


  navRow.appendChild(
    userArea
  );


  header.appendChild(
    navRow
  );


  // ========================================================
  // SECONDARY / SUB NAVIGATION
  // ========================================================

  if (
    activeHub === 'sourcing'
  ) {

    header.appendChild(
      buildSubNav(
        SOURCING_NAV,
        page,
        'Sourcing navigation'
      )
    );

  }


  if (
    activeHub === 'fleet'
  ) {

    header.appendChild(
      buildSubNav(
        FLEET_NAV,
        page,
        'Fleet Command navigation'
      )
    );

  }


  if (
    activeHub === 'dispatch'
  ) {

    header.appendChild(
      buildSubNav(
        DISPATCH_NAV,
        page,
        'Dispatch navigation'
      )
    );

  }


  // ========================================================
  // GET LOGGED-IN USER
  // ========================================================

  const userResult =
    await dbClient
      .auth
      .getUser();


  const authId =
    userResult &&
    userResult.data &&
    userResult.data.user

      ? userResult.data.user.id

      : null;


  if (!authId) {

    who.textContent =
      'Not signed in';

    return null;

  }


  // ========================================================
  // GET APP PROFILE
  // ========================================================

  let me =
    await dbClient

      .from('app_users')

      .select(
        'full_name, role, tenant_id'
      )

      .eq(
        'auth_uid',
        authId
      )

      .maybeSingle();


  // --------------------------------------------------------
  // FALLBACK FOR EXISTING SINGLE-PROFILE SETUP
  // --------------------------------------------------------

  if (
    !me.error &&
    !me.data
  ) {

    me =
      await dbClient

        .from('app_users')

        .select(
          'full_name, role, tenant_id'
        )

        .limit(1)

        .maybeSingle();

  }


  if (me.error) {

    who.textContent =
      'Profile error';


    console.error(
      'nav.js: app_users query failed:',
      me.error.message
    );


    return null;

  }


  if (!me.data) {

    who.textContent =
      'No profile linked';

    return null;

  }


  // ========================================================
  // DISPLAY USER
  // ========================================================

  const fullName =
    me.data.full_name ||
    'User';


  const role =
    me.data.role ||
    'User';


  const formattedRole =
    role.charAt(0).toUpperCase() +
    role.slice(1);


  who.textContent =
    `${fullName} (${formattedRole})`;


  // ========================================================
  // TRAINING MODE BADGE
  // ========================================================

  try {

    const ts =
      await dbClient.rpc(
        'get_training_mode_status'
      );


    if (
      !ts.error &&
      ts.data &&
      ts.data.active === true
    ) {

      const badge =
        document.createElement(
          'span'
        );


      badge.textContent =
        'TRAINING';


      badge.title =
        ts.data.expires_at

          ? 'Training Mode active until ' +
            new Date(
              ts.data.expires_at
            ).toLocaleString()

          : 'Training Mode active';


      badge.style.cssText =
        'background:#B8B05D;' +
        'color:#3C3A4B;' +
        'font-family:Oswald,sans-serif;' +
        'font-size:11px;' +
        'font-weight:600;' +
        'letter-spacing:.8px;' +
        'padding:3px 9px;' +
        'border-radius:3px;' +
        'text-transform:uppercase;' +
        'white-space:nowrap;';


      userArea.insertBefore(
        badge,
        who
      );

    }

  } catch (e) {

    // Training mode unavailable.
    // Navigation continues normally.

  }


  // ========================================================
  // RETURN TENANT ID
  // ========================================================

  return (
    me.data.tenant_id
  );

}


// ============================================================
// MAKE buildNav AVAILABLE TO EVERY PAGE
// ============================================================

window.buildNav =
  buildNav;


})();
