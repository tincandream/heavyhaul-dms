// ============================================================
// nav.js
// HEAVY HAUL COMMAND — SAFE NAV RESTORE
// ============================================================

(function () {
  'use strict';

  async function buildNav(dbClient, title) {

    const header =
      document.querySelector('header');

    if (!header) {
      console.error(
        'nav.js: no <header> element found'
      );
      return null;
    }

    // --------------------------------------------------------
    // TOP BRAND BAR
    // --------------------------------------------------------

    header.innerHTML = `
      <div style="
        display:flex;
        align-items:center;
        width:100%;
        min-height:54px;
        padding:0 26px;
        box-sizing:border-box;
        background:#ffffff;
        border-bottom:1px solid #eeeeee;
      ">
        <a
          href="welcome.html"
          style="
            color:#222222;
            font-size:16px;
            font-weight:700;
            letter-spacing:1.4px;
            text-decoration:none;
            white-space:nowrap;
          "
        >
          HEAVY HAUL COMMAND
        </a>
      </div>

      <div style="
        display:flex;
        align-items:center;
        width:100%;
        min-height:48px;
        padding:0 26px;
        box-sizing:border-box;
        background:#ffffff;
        border-bottom:1px solid #dddddd;
        overflow-x:auto;
      ">

        <nav
          style="
            display:flex;
            align-items:center;
            flex-shrink:0;
          "
        >

          <a
            href="welcome.html"
            class="hh-main-nav"
          >
            Welcome
          </a>

          <a
            href="board.html"
            class="hh-main-nav"
          >
            Dispatch
          </a>

          <a
            href="sourcing.html"
            class="hh-main-nav"
          >
            Sourcing
          </a>

          <a
            href="fleet-command.html"
            class="hh-main-nav"
          >
            Fleet Command
          </a>

        </nav>

        <div
          style="
            margin-left:auto;
            display:flex;
            align-items:center;
            gap:9px;
            padding-left:18px;
            white-space:nowrap;
          "
        >

          <span
            id="me"
            style="
              color:#666666;
              font-size:12px;
            "
          >
            …
          </span>

          <span
            style="
              color:#bbbbbb;
              font-size:12px;
            "
          >
            |
          </span>

          <button
            id="sharedSignOut"
            type="button"
            style="
              padding:0;
              margin:0;
              border:0;
              background:transparent;
              color:#555555;
              font-size:12px;
              cursor:pointer;
              font-family:inherit;
            "
          >
            Sign Out
          </button>

        </div>

      </div>
    `;


    // --------------------------------------------------------
    // NAV STYLING
    // --------------------------------------------------------

    const style =
      document.createElement('style');

    style.textContent = `
      .hh-main-nav {
        display:flex;
        align-items:center;
        min-height:48px;
        padding:0 17px;
        color:#666666;
        text-decoration:none;
        font-size:13px;
        font-weight:600;
        white-space:nowrap;
        border-bottom:3px solid transparent;
      }

      .hh-main-nav:hover {
        color:#222222;
      }

      .hh-main-nav.active {
        color:#111111;
        border-bottom-color:#6B92A5;
      }
    `;

    document.head.appendChild(style);


    // --------------------------------------------------------
    // ACTIVE TAB
    // --------------------------------------------------------

    const page =
      location.pathname
        .split('/')
        .pop() ||
      'welcome.html';


    let activeHref =
      'welcome.html';


    if (
      [
        'dispatch.html',
        'board.html',
        'newload.html',
        'loads.html',
        'workspace.html'
      ].includes(page)
    ) {
      activeHref =
        'board.html';
    }


    else if (
      [
        'sourcing.html',
        'opportunities.html',
        'call-queue.html',
        'portals.html',
        'load-emails.html',
        'inbox.html',
        'templates.html',
        'calculators.html',
        'manual.html',
        'field-manual.html'
      ].includes(page)
    ) {
      activeHref =
        'sourcing.html';
    }


    else if (
      [
        'fleet-command.html',
        'fleet.html',
        'route-planning.html',
        'states.html',
        'calendar.html'
      ].includes(page)
    ) {
      activeHref =
        'fleet-command.html';
    }


    document
      .querySelectorAll('.hh-main-nav')
      .forEach(function (link) {

        if (
          link.getAttribute('href') ===
          activeHref
        ) {
          link.classList.add('active');
        }

      });


    // --------------------------------------------------------
    // SIGN OUT
    // --------------------------------------------------------

    const signOut =
      document.getElementById(
        'sharedSignOut'
      );


    signOut.addEventListener(
      'click',
      async function () {

        if (
          dbClient &&
          dbClient.auth
        ) {

          await dbClient.auth.signOut();

        }

        location.href =
          'index.html';

      }
    );


    // --------------------------------------------------------
    // USER DISPLAY
    // --------------------------------------------------------

    if (
      !dbClient ||
      !dbClient.auth
    ) {

      document
        .getElementById('me')
        .textContent =
        'User';

      return null;
    }


    try {

      const userResult =
        await dbClient.auth.getUser();


      const user =
        userResult &&
        userResult.data
          ? userResult.data.user
          : null;


      if (!user) {

        document
          .getElementById('me')
          .textContent =
          'Not signed in';

        return null;
      }


      const profileResult =
        await dbClient
          .from('app_users')
          .select(
            'full_name, role, tenant_id'
          )
          .eq(
            'auth_uid',
            user.id
          )
          .maybeSingle();


      if (
        profileResult.error ||
        !profileResult.data
      ) {

        document
          .getElementById('me')
          .textContent =
          user.email || 'User';

        return null;
      }


      const profile =
        profileResult.data;


      const role =
        profile.role
          ? profile.role
              .charAt(0)
              .toUpperCase() +
            profile.role.slice(1)
          : 'User';


      document
        .getElementById('me')
        .textContent =
        `${profile.full_name || 'User'} (${role})`;


      return profile.tenant_id;

    }

    catch (error) {

      console.error(
        'nav.js profile error:',
        error
      );


      document
        .getElementById('me')
        .textContent =
        'User';


      return null;

    }

  }


  window.buildNav =
    buildNav;

})();
