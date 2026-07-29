const SUPABASE_URL = "https://zyhdatteglxozsgnjhrm.supabase.co/rest/v1/";

const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp5aGRhdHRlZ2x4b3pzZ25qaHJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyODEzMTAsImV4cCI6MjEwMDg1NzMxMH0.I4SlAWiqKk0oPv-0WRgVy_AAGnQ0NoT8-T8z62jIj7Y";

const db = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
