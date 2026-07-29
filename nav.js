// Shared header for every page. Include with:
//   <script src="nav.js"></script>
// after the Supabase client is created and after a <header> exists.

const NAV_LINKS = [
  ['board.html',   'Fleet Board'],
  ['newload.html', 'New Load'],
  ['fleet.html',   'Fleet Setup'],
  ['states.html',  'State Rules']
];

async function buildNav(dbClient, title) {
  const here = location.pathname.split('/').pop() || 'board.html';

  const header = document.querySelector('header');
  if (!header) return;
  header.innerHTML = '';

  const h1 = document.createElement('h1');
  h1.textContent = title || 'Dispatch';
  h1.style.cssText = 'font-size:16px;font-weight:600;margin:0';
  header.appendChild(h1);

  const stamp = document.createElement('span');
  stamp.id = 'stamp';
  stamp.style.cssText = 'font-size:11.5px;color:#73726c';
  header.appendChild(stamp);

  const right = document.createElement('span');
  right.style.cssText = 'margin-left:auto;font-size:13px;display:flex;' +
                        'align-items:center;gap:14px;flex-wrap:wrap';

  NAV_LINKS.forEach(function (l) {
    const a = document.createElement('a');
    a.href = l[0];
    a.textContent = l[1];
    a.style.cssText = 'text-decoration:none;color:' +
      (l[0] === here ? '#22221f;font-weight:600' : '#185fa5');
    right.appendChild(a);
  });

  const who = document.createElement('span');
  who.style.cssText = 'color:#73726c';
  who.textContent = '…';
  right.appendChild(who);

  const outBtn = document.createElement('button');
  outBtn.textContent = 'Sign out';
  outBtn.style.cssText = 'background:none;border:0;padding:0;color:#185fa5;' +
                         'font-size:13px;cursor:pointer;text-decoration:underline';
  outBtn.addEventListener('click', async function () {
    await dbClient.auth.signOut();
    location.href = 'index.html';
  });
  right.appendChild(outBtn);

  header.appendChild(right);

  const me = await dbClient.from('app_users').select('full_name, role, tenant_id');
  if (me.data && me.data.length) {
    who.textContent = me.data[0].full_name + ' (' + me.data[0].role + ')';
    return me.data[0].tenant_id;
  }
  who.textContent = 'no profile linked';
  return null;
}
