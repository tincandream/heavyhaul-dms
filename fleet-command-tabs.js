// ============================================================
// FLEET COMMAND SHARED NAVIGATION
// Used by:
// fleet.html
// route-planning.html
// states.html
// calendar.html
// ============================================================

function buildFleetCommandTabs(activePage) {

  const target =
    document.getElementById(
      'fleetCommandTabs'
    );

  if (!target) return;


  const tabs = [
    ['fleet.html', 'Fleet Setup'],
    ['route-planning.html', 'Route Planning'],
    ['states.html', 'State Rules'],
    ['calendar.html', 'Calendar']
  ];


  target.innerHTML = '';


  // Exact Route Planning look
  target.style.cssText = `
    display:flex;
    align-items:center;
    gap:26px;

    width:min(1450px,100%);
    min-height:46px;

    margin:0 auto 6px;
    padding:0 24px;

    background:transparent;

    border:0;
    border-bottom:1px solid #E2E5DD;

    box-shadow:none;
    border-radius:0;

    overflow-x:auto;
  `;


  tabs.forEach(function(tab) {

    const href =
      tab[0];

    const label =
      tab[1];

    const isActive =
      href === activePage;


    const link =
      document.createElement('a');


    link.href =
      href;

    link.textContent =
      label;


    link.style.cssText = `
      display:flex;
      align-items:center;

      min-height:44px;

      padding:0 0 10px;

      background:transparent;

      color:${
        isActive
          ? '#7F9138'
          : '#737A75'
      };

      border:0;
      border-radius:0;

      box-shadow:none;

      text-decoration:none;

      font-size:13px;
      font-weight:600;

      white-space:nowrap;
    `;


    target.appendChild(
      link
    );

  });

}


// Make available to every page
window.buildFleetCommandTabs =
  buildFleetCommandTabs;
