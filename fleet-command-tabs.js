// ============================================================
// fleet-command-tabs.js
// Shared Fleet Command workspace tabs
// Airy Americana palette
// ============================================================

function buildFleetCommandTabs(activePage) {

  const target =
    document.getElementById(
      'fleetCommandTabs'
    );

  if (!target) {
    return;
  }


  const tabs = [
    ['fleet.html', 'Fleet Setup'],
    ['route-planning.html', 'Route Planning'],
    ['states.html', 'State Rules'],
    ['calendar.html', 'Calendar']
  ];


  // ----------------------------------------------------------
  // FLEET COMMAND BAR
  // ----------------------------------------------------------

  target.style.cssText = `
    display:flex;
    align-items:center;
    gap:26px;

    width:100%;
    min-height:46px;

    margin:0 0 26px;
    padding:0;

    background:transparent;

    border:0;
    border-bottom:1px solid #D9DEE1;

    border-radius:0;
    box-shadow:none;

    overflow-x:auto;
  `;


  target.innerHTML = '';


  // ----------------------------------------------------------
  // TABS
  // ----------------------------------------------------------

  tabs.forEach(function (tab) {

    const href =
      tab[0];

    const label =
      tab[1];

    const isActive =
      href === activePage;


    const link =
      document.createElement(
        'a'
      );


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
    : '#6F777B'
};

border-bottom:3px solid ${
  isActive
    ? '#AEBC39'
    : 'transparent'
};

      border-radius:0;

      box-shadow:none;

      text-decoration:none;

      font-family:"Oswald", Arial, sans-serif;
      font-size:13px;
      font-weight:500;
      letter-spacing:.8px;

      white-space:nowrap;
    `;


    link.addEventListener(
      'mouseenter',
      function () {

        if (!isActive) {
          link.style.color =
            '#link.style.color =
 '#7F9138';
        }

      }
    );


    link.addEventListener(
      'mouseleave',
      function () {

        if (!isActive) {
          link.style.color =
            '#6F777B';
        }

      }
    );


    target.appendChild(
      link
    );

  });

}
