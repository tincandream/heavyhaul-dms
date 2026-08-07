// ============================================================
// dispatch-shell.js
// Shared shell for every Dispatch page
//
// Fleet Board | New Load | All Loads
// ============================================================

function buildDispatchShell(activePage) {

  const target =
    document.getElementById('dispatchShell');

  if (!target) return;


  const tabs = [
    ['board.html', 'Fleet Board'],
    ['newload.html', 'New Load'],
    ['loads.html', 'All Loads']
  ];


  const links =
    tabs.map(function (tab) {

      const href = tab[0];
      const label = tab[1];

      return (
        '<a href="' + href + '"' +
        (href === activePage
          ? ' class="active"'
          : '') +
        '>' +
        label +
        '</a>'
      );

    }).join('');


  target.innerHTML = `

    <section class="dispatch-page-header">

      <h1>DISPATCH</h1>

      <p>
        Manage loads and daily dispatch activity.
      </p>

    </section>


    <nav class="dispatch-tabs">

      ${links}

    </nav>

  `;

}
