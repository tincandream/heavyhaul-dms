// ============================================================
// nav.js — shared Heavy Haul Command header
//
// Include AFTER the Supabase CDN script and BEFORE the page's
// own script block:
//
//   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
//   <script src="nav.js"></script>
//   <script> ...page code... </script>
//
// Call from each page:
//   const tenant = await buildNav(db, 'Fleet Board');
//
// Returns tenant_id, or null if no app_users row is linked.
// ============================================================


// ============================================================
// NAVIGATION STRUCTURE
// ============================================================

const NAV_HUBS = [

  {
    label: 'Welcome',
    href: 'welcome.html',
    pages: [
      'welcome.html'
    ]
  },

  {
    label: 'Dispatch',
    pages: [
      'board.html',
      'newload.html',
      'loads.html',
      'workspace.html'
    ],
    items: [
      ['board.html', 'Fleet Board'],
      ['newload.html', 'New Load'],
      ['loads.html', 'All Loads']
    ]
  },

  {
    label: 'Sourcing',
    pages: [
      'sourcing.html',
      'opportunities.html',
      'call-queue.html',
      'portals.html',
      'load-emails.html',
      'templates.html',
      'field-manual.html',
      'calculators.html'
    ],
    items: [
      ['opportunities.html', 'Opportunities'],
      ['call-queue.html', 'Call Queue'],
      ['portals.html', 'Portals'],
      ['load-emails.html', 'Load Emails'],
      ['templates.html', 'Templates'],
      ['field-manual.html', 'Field Manual'],
      ['calculators.html', 'Calculators']
    ]
  },

  {
    label: 'Fleet Command',
    pages: [
      'fleet.html',
      'route-planning.html',
      'states.html',
      'calendar.html'
    ],
    items: [
      ['fleet.html', 'Fleet Setup'],
      ['route-planning.html', 'Route Planning'],
      ['states.html', 'State Rules'],
      ['calendar.html', 'Calendar']
    ]
  }

];


// ============================================================
// BUILD NAV
// ============================================================

async function buildNav(dbClient, title) {

  const here =
    location.pathname.split('/').pop() || 'welcome.html';

  const header =
    document.querySelector('header');


  if (!header) {

    console.warn(
      'nav.js: no <header> element found on this page'
    );

    return null;

  }


  header.innerHTML = '';

  header.className =
    'hh-header';


  // ==========================================================
  // BRAND / PAGE TITLE
  // ==========================================================

  const brand =
    document.createElement('div');

  brand.className =
    'hh-header-brand';


  const brandName =
    document.createElement('div');

  brandName.className =
    'hh-brand-name';

  brandName.textContent =
    'HEAVY HAUL COMMAND';


  const pageTitle =
    document.createElement('div');

  pageTitle.className =
    'hh-page-title';

  pageTitle.textContent =
    title || 'Command Center';


  brand.appendChild(
    brandName
  );

  brand.appendChild(
    pageTitle
  );

  header.appendChild(
    brand
  );


  // ==========================================================
  // MAIN HUB NAV
  // ==========================================================

  const nav =
    document.createElement('nav');

  nav.className =
    'hh-main-nav';


  NAV_HUBS.forEach(
    function (hub) {


      const hubWrap =
        document.createElement('div');

      hubWrap.className =
        'hh-nav-hub';


      const isActive =
        hub.pages.includes(here);


      // --------------------------------------------------------
      // SIMPLE LINK: WELCOME
      // --------------------------------------------------------

      if (!hub.items) {

        const a =
          document.createElement('a');

        a.href =
          hub.href;

        a.textContent =
          hub.label;

        a.className =
          'hh-nav-link' +
          (isActive ? ' active' : '');

        hubWrap.appendChild(
          a
        );

      }


      // --------------------------------------------------------
      // HUB WITH MENU
      // --------------------------------------------------------

      else {

        const button =
          document.createElement('button');

        button.type =
          'button';

        button.className =
          'hh-nav-link hh-hub-button' +
          (isActive ? ' active' : '');

        button.textContent =
          hub.label;


        const arrow =
          document.createElement('span');

        arrow.className =
          'hh-nav-arrow';

        arrow.textContent =
          '▾';


        button.appendChild(
          arrow
        );


        const menu =
          document.createElement('div');

        menu.className =
          'hh-hub-menu';


        hub.items.forEach(
          function (item) {

            const a =
              document.createElement('a');

            a.href =
              item[0];

            a.textContent =
              item[1];

            if (
              item[0] === here
            ) {

              a.className =
                'current';

            }

            menu.appendChild(
              a
            );

          }
        );


        hubWrap.appendChild(
          button
        );

        hubWrap.appendChild(
          menu
        );


        // click toggle for smaller screens
        button.addEventListener(
          'click',
          function (e) {

            e.stopPropagation();

            document
              .querySelectorAll(
                '.hh-nav-hub.open'
              )
              .forEach(
                function (other) {

                  if (
                    other !== hubWrap
                  ) {

                    other.classList.remove(
                      'open'
                    );

                  }

                }
              );

            hubWrap.classList.toggle(
              'open'
            );

          }
        );

      }


      nav.appendChild(
        hubWrap
      );

    }
  );


  header.appendChild(
    nav
  );


  // ==========================================================
  // USER / SIGN OUT
  // ==========================================================

  const userArea =
    document.createElement('div');

  userArea.className =
    'hh-user-area';


  const who =
    document.createElement('span');

  who.id =
    'me';

  who.className =
    'hh-user-name';

  who.textContent =
    '…';


  const outBtn =
    document.createElement('button');

  outBtn.type =
    'button';

  outBtn.className =
    'hh-signout';

  outBtn.textContent =
    'Sign out';


  outBtn.addEventListener(
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
    outBtn
  );

  header.appendChild(
    userArea
  );


  // ==========================================================
  // CLOSE MENUS WHEN CLICKING ELSEWHERE
  // ==========================================================

  document.addEventListener(
    'click',
    function () {

      document
        .querySelectorAll(
          '.hh-nav-hub.open'
        )
        .forEach(
          function (hub) {

            hub.classList.remove(
              'open'
            );

          }
        );

    }
  );


  // ==========================================================
  // PROFILE LOOKUP
  // ==========================================================

  const sess =
    await dbClient.auth.getUser();


  const authId =
    sess.data &&
    sess.data.user
      ? sess.data.user.id
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


  // fallback
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
      'profile error';

    console.error(
      'nav.js: app_users query failed —',
      me.error.message
    );

    return null;

  }


  if (!me.data) {

    who.textContent =
      'no profile linked';

    return null;

  }


  who.textContent =
    me.data.full_name;


  return me.data.tenant_id;

}
