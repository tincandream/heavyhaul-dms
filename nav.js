// ============================================================
// nav.js
// HEAVY HAUL COMMAND — GLOBAL APPLICATION HEADER
//
// ROW 1:
// HEAVY HAUL COMMAND
//
// ROW 2:
// Welcome | Dispatch | Sourcing | Fleet Command
//                         Dianna V. Mwaka (Owner) | Sign Out
//
// IMPORTANT:
// This file ONLY builds global navigation.
// Hub-specific navigation belongs inside each hub page.
// ============================================================


// ============================================================
// GLOBAL HUBS
// ============================================================

const MAIN_NAV = [
  ['welcome.html', 'Welcome'],
  ['dispatch.html', 'Dispatch'],
  ['sourcing.html', 'Sourcing'],
  ['fleet-command.html', 'Fleet Command']
];



// ============================================================
// PAGES THAT BELONG TO EACH HUB
//
// This lets the correct main tab stay highlighted even when
// the user is inside one of that hub's tools.
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

    if (
      HUB_PAGES[hub].includes(currentPage)
    ) {

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
    location.pathname
      .split('/')
      .pop() || 'welcome.html';


  const activeHub =
    getCurrentHub(here);


  const header =
    document.querySelector('header');


  if (!header) {

    console.warn(
      'nav.js: no <header> element found'
    );

    return null;

  }


  // Remove anything left over from older nav versions.

  header.innerHTML = '';

  header.removeAttribute('style');

  header.className =
    'hh-global-header';


  // IMPORTANT:
  // Undo the abandoned vertical sidebar.

  document.body.style.paddingLeft =
    '0';



  // ==========================================================
  // ROW 1 — BRAND
  // ==========================================================

  const brandRow =
    document.createElement('div');


  brandRow.className =
    'hh-brand-row';



  const brand =
    document.createElement('a');


  brand.href =
    'welcome.html';


  brand.className =
    'hh-global-brand';


  brand.textContent =
    'HEAVY HAUL COMMAND';


  brandRow.appendChild(
    brand
  );


  header.appendChild(
    brandRow
  );



  // ==========================================================
  // ROW 2 — HUBS + USER
  // ==========================================================

  const navRow =
    document.createElement('div');


  navRow.className =
    'hh-global-nav-row';



  // LEFT SIDE — HUB NAVIGATION

  const nav =
    document.createElement('nav');


  nav.className =
    'hh-global-nav';



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


      link.className =
        'hh-global-nav-link';


      if (
        href === activeHub
      ) {

        link.classList.add(
          'active'
        );

      }


      nav.appendChild(
        link
      );

  });


  navRow.appendChild(
    nav
  );



  // RIGHT SIDE — USER

  const userArea =
    document.createElement('div');


  userArea.className =
    'hh-global-user';



  const who =
    document.createElement('span');


  who.id =
    'me';


  who.className =
    'hh-global-user-name';


  who.textContent =
    '…';



  const divider =
    document.createElement('span');


  divider.className =
    'hh-global-divider';


  divider.textContent =
    '|';



  const signOut =
    document.createElement('button');


  signOut.type =
    'button';


  signOut.className =
    'hh-global-signout';


  signOut.textContent =
    'Sign Out';



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
  // USER PROFILE
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

      .select(
        'full_name, role, tenant_id'
      )

      .eq(
        'auth_uid',
        authId
      )

      .maybeSingle();



  // Preserve the fallback from the original working nav.js.

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



  // Use the full name and role exactly as requested.

  const fullName =
    me.data.full_name || 'User';


  const role =
    me.data.role || 'User';


  const displayRole =
    role.charAt(0).toUpperCase() +
    role.slice(1);


  who.textContent =
    fullName +
    ' (' +
    displayRole +
    ')';



  return me.data.tenant_id;

}
