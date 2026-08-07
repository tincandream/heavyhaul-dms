// ============================================================
// nav.js — shared header for every page
//
// Include AFTER the Supabase CDN script and BEFORE the page's
// own script block:
//   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
//   <script src="nav.js"></script>
//   <script> ...page code... </script>
//
// Call from inside each page's start() function, after the
// session check:
//   const tenant = await buildNav(db, 'Fleet Board');
//
// Returns the tenant_id, or null if no app_users row is linked.
// buildNav clears and rebuilds whatever is inside <header>, so
// existing header markup does not need to be removed first.
// ============================================================

const NAV_LINKS = [
  ['board.html',         'Fleet Board'],
  ['loads.html',         'All Loads'],
  ['newload.html',       'New Load'],
  ['opportunities.html', 'Opportunities'],
  ['call-queue.html',    'Call Queue'],
  ['portals.html',       'Portals'],
  ['inbox.html',         'Load Emails'],
  ['fleet.html',         'Fleet Setup'],
  ['states.html',        'State Rules']
];

async function buildNav(dbClient, title) {
  const here = location.pathname.split('/').pop() || 'board.html';

  const header = document.querySelector('header');
  if (!header) {
    console.warn('nav.js: no <header> element found on this page');
    return null;
  }

  header.innerHTML = '';
  header.style.cssText =
    'background:#fff;border-bottom:1px solid #e2e0da;padding:12px 18px;' +
    'display:flex;align-items:center;gap:14px;flex-wrap:wrap';

  const h1 = document.createElement('h1');
  h1.textContent = title || 'Dispatch';
  h1.style.cssText = 'font-size:16px;font-weight:600;margin:0;color:#22221f';
  header.appendChild(h1);

  // Pages that show a "last updated" time write into this
  const stamp = document.createElement('span');
  stamp.id = 'stamp';
  stamp.style.cssText = 'font-size:11.5px;color:#73726c';
  header.appendChild(stamp);

  const right = document.createElement('span');
  right.style.cssText =
    'margin-left:auto;font-size:13px;display:flex;align-items:center;' +
    'gap:14px;flex-wrap:wrap';

  NAV_LINKS.forEach(function (link) {
    const a = document.createElement('a');
    a.href = link[0];
    a.textContent = link[1];
    a.style.cssText = 'text-decoration:none;' +
      (link[0] === here
        ? 'color:#22221f;font-weight:600'
        : 'color:#185fa5');
    right.appendChild(a);
  });

  const who = document.createElement('span');
  who.id = 'me';
  who.style.cssText = 'color:#73726c';
  who.textContent = '…';
  right.appendChild(who);

  const outBtn = document.createElement('button');
  outBtn.textContent = 'Sign out';
outBtn.style.cssText =
    'background:none;border:0;padding:0;margin:0;color:#185fa5;font-size:13px;' +
    'cursor:pointer;text-decoration:underline;font-family:inherit;' +
    'line-height:1;vertical-align:baseline';
  outBtn.addEventListener('click', async function () {
    await dbClient.auth.signOut();
    location.href = 'index.html';
  });
  right.appendChild(outBtn);

  header.appendChild(right);

 const sess = await dbClient.auth.getUser();
const me = await dbClient
    .from('app_users')
    .select('full_name, role, tenant_id');
  if (me.error) {
    who.textContent = 'profile error';
    console.error('nav.js: app_users query failed —', me.error.message);
    return null;
  }
  if (!me.data || !me.data.length) {
    who.textContent = 'no profile linked';
    return null;
  }
  who.textContent = me.data[0].full_name + ' (' + me.data[0].role + ')';
  return me.data[0].tenant_id;
