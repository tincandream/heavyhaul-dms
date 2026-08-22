// ============================================================
// nav.js
// HEAVY HAUL COMMAND — SHARED GLOBAL NAVIGATION
// ============================================================

(function () {
  'use strict';

  const MAIN_NAV = [
    ['welcome.html', 'Welcome', 'welcome'],
    ['board.html', 'Dispatch', 'dispatch'],
    ['sourcing.html', 'Sourcing', 'sourcing'],
    ['fleet-command.html', 'Fleet Command', 'fleet']
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
      'field-manual.html',
      'calculators.html'
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
    return location.pathname.split('/').pop() || 'welcome.html';
  }

  function currentHub(page) {
    for (const [hub, pages] of Object.entries(HUB_PAGES)) {
      if (pages.includes(page)) return hub;
    }

    return 'welcome';
  }

  function style(el, rules) {
    Object.assign(el.style, rules);
    return el;
  }

  async function buildNav(dbClient, title) {
    const header = document.querySelector('header');

    if (!header) {
      console.warn(
        'nav.js: no <header> element found on this page'
      );
      return null;
    }

    if (!dbClient || !dbClient.auth) {
      console.error(
        'nav.js: Supabase client was not supplied to buildNav().'
      );
      return null;
    }

    const page = currentPage();
    const activeHub = currentHub(page);

    header.innerHTML = '';
    header.removeAttribute('style');

    document.body.style.paddingLeft = '0';
    document.body.style.margin = '0';

    style(header, {
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

    // ========================================================
    // ROW 1 — BRAND
    // ========================================================

    const brandRow = style(
      document.createElement('div'),
      {
        display: 'flex',
        alignItems: 'center',
        minHeight: '54px',
        padding: '0 26px',
        borderBottom: '1px solid #eeeeee',
        boxSizing: 'border-box'
      }
    );

    const brand = style(
      document.createElement('a'),
      {
        color: '#222222',
        fontSize: '16px',
        fontWeight: '700',
        letterSpacing: '1.4px',
        textDecoration: 'none'
      }
    );

    brand.href = 'welcome.html';
    brand.textContent = 'HEAVY HAUL COMMAND';

    brandRow.appendChild(brand);
    header.appendChild(brandRow);

    // ========================================================
    // ROW 2 — HUBS + USER
    // ========================================================

    const navRow = style(
      document.createElement('div'),
      {
        display: 'flex',
        alignItems: 'center',
        width: '100%',
        minHeight: '48px',
        padding: '0 26px',
        gap: '20px',
        boxSizing: 'border-box',
        overflowX: 'auto'
      }
    );

    const nav = style(
      document.createElement('nav'),
      {
        display: 'flex',
        alignItems: 'center',
        gap: '0',
        flexShrink: '0'
      }
    );

    nav.setAttribute(
      'aria-label',
      'Main navigation'
    );

    MAIN_NAV.forEach(
      ([href, label, hub]) => {
        const link = style(
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
            borderBottom:
              '3px solid transparent',

            color:
              hub === activeHub
                ? '#111111'
                : '#666666'
          }
        );

        link.href = href;
        link.textContent = label;

        if (hub === activeHub) {
          link.style.borderBottomColor =
            '#6B92A5';

          link.setAttribute(
            'aria-current',
            'page'
          );
        }

        link.addEventListener(
          'mouseenter',
          () => {
            if (hub !== activeHub) {
              link.style.color =
                '#222222';
            }
          }
        );

        link.addEventListener(
          'mouseleave',
          () => {
            if (hub !== activeHub) {
              link.style.color =
                '#666666';
            }
          }
        );

        nav.appendChild(link);
      }
    );

    navRow.appendChild(nav);

    // ========================================================
    // USER AREA
    // ========================================================

    const userArea = style(
      document.createElement('div'),
      {
        marginLeft: 'auto',
        display: 'flex',
        alignItems: 'center',
        gap: '9px',
        whiteSpace: 'nowrap',
        paddingLeft: '18px'
      }
    );

    const who = style(
      document.createElement('span'),
      {
        color: '#666666',
        fontSize: '12px'
      }
    );

    who.id = 'me';
    who.textContent = '…';

    const divider = style(
      document.createElement('span'),
      {
        color: '#bbbbbb',
        fontSize: '12px'
      }
    );

    divider.textContent = '|';

    const signOut = style(
      document.createElement('button'),
      {
        padding: '0',
        margin: '0',
        background: 'transparent',
        border: '0',
        color: '#555555',
        fontSize: '12px',
        fontWeight: '400',
        cursor: 'pointer',
        fontFamily: 'inherit'
      }
    );

    signOut.type = 'button';
    signOut.textContent = 'Sign Out';

    signOut.addEventListener(
      'mouseenter',
      () => {
        signOut.style.color =
          '#111111';
      }
    );

    signOut.addEventListener(
      'mouseleave',
      () => {
        signOut.style.color =
          '#555555';
      }
    );

    signOut.addEventListener(
      'click',
      async () => {
        await dbClient.auth.signOut();

        location.href =
          'index.html';
      }
    );

    userArea.append(
      who,
      divider,
      signOut
    );

    navRow.appendChild(userArea);
    header.appendChild(navRow);

    // ========================================================
    // PROFILE / TENANT LOOKUP
    // ========================================================

    const userResult =
      await dbClient.auth.getUser();

    const authId =
      userResult?.data?.user?.id ||
      null;

    if (!authId) {
      who.textContent =
        'Not signed in';

      return null;
    }

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

    // Preserve the project's existing
    // fallback behavior.

    if (!me.error && !me.data) {
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

    return me.data.tenant_id;
  }

  // ========================================================
  // EXPOSE NAVIGATION TO EVERY PAGE
  // ========================================================

  window.buildNav = buildNav;

})();
