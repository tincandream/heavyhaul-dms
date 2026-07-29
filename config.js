const SUPABASE_URL = 'https://YOUR-PROJECT-ID.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGci...paste-your-anon-key-here';

const db = window.supabase.createClient(https://zyhdatteglxozsgnjhrm.supabase.co/rest/v1/, eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp5aGRhdHRlZ2x4b3pzZ25qaHJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyODEzMTAsImV4cCI6MjEwMDg1NzMxMH0.I4SlAWiqKk0oPv-0WRgVy_AAGnQ0NoT8-T8z62jIj7Y);

async function requireSession() {
  const { data } = await db.auth.getSession();
  if (!data.session) { window.location.href = 'index.html'; return null; }
  return data.session;
}

async function signOut() {
  await db.auth.signOut();
  window.location.href = 'index.html';
}
