// ============================================================
// fleet-command-tabs.js
// Shared Fleet Command workspace tabs
// ============================================================

function buildFleetCommandTabs(activePage) {

  const target =
    document.getElementById('fleetCommandTabs');

  if (!target) return;


  const tabs = [
    ['fleet.html', 'Fleet Setup'],
    ['route-planning.html', 'Route Planning'],
    ['states.html', 'State Rules'],
    ['calendar.html', 'Calendar']
  ];


  target.innerHTML =
    tabs.map(function (tab) {

      const href =
        tab[0];

      const label =
        tab[1];

      const active =
        href === activePage
          ? ' class="active"'
          : '';


      return (
        '<a href="' +
        href +
        '"' +
        active +
        '>' +
        label +
        '</a>'
      );

    }).join('');
}
