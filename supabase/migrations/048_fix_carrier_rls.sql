policyname,cmd,roles,qual,with_check
carrier_tenant_insert,INSERT,{authenticated},null,"(EXISTS ( SELECT 1
   FROM app_users au
  WHERE ((au.auth_uid = auth.uid()) AND (au.tenant_id = carriers.tenant_id) AND (au.status = 'active'::text) AND (au.role = ANY (ARRAY['owner'::text, 'admin'::text, 'dispatcher'::text])))))"
carrier_tenant_read,SELECT,{authenticated},"(EXISTS ( SELECT 1
   FROM app_users au
  WHERE ((au.auth_uid = auth.uid()) AND (au.tenant_id = carriers.tenant_id) AND (au.status = 'active'::text))))",null
carrier_tenant_update,UPDATE,{authenticated},"(EXISTS ( SELECT 1
   FROM app_users au
  WHERE ((au.auth_uid = auth.uid()) AND (au.tenant_id = carriers.tenant_id) AND (au.status = 'active'::text) AND (au.role = ANY (ARRAY['owner'::text, 'admin'::text, 'dispatcher'::text])))))","(EXISTS ( SELECT 1
   FROM app_users au
  WHERE ((au.auth_uid = auth.uid()) AND (au.tenant_id = carriers.tenant_id) AND (au.status = 'active'::text) AND (au.role = ANY (ARRAY['owner'::text, 'admin'::text, 'dispatcher'::text])))))"
