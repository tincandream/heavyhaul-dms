// ============================================================
// dispatch-tabs.js
// Shared Dispatch workspace tabs
// ============================================================

function buildDispatchTabs(activePage) {

  const target =
    document.getElementById('dispatchTabs');

  if (!target) return;


  const tabs = [
    ['board.html', 'Fleet Board'],
    ['newload.html', 'New Load'],
    ['loads.html', 'All Loads']
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
