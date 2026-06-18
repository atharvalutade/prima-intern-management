-- Update handle_new_user trigger to grant admin role when valid signup code
-- is passed via raw_user_meta_data.admin_code at signup time.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  v_code text;
  v_is_admin boolean := false;
begin
  insert into public.profiles (id, email, name, mobile)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'mobile', '')
  );

  v_code := new.raw_user_meta_data->>'admin_code';
  if v_code is not null and v_code <> '' then
    select exists (
      select 1 from public.admin_settings where id = 1 and signup_code = v_code
    ) into v_is_admin;
  end if;

  if v_is_admin then
    insert into public.user_roles (user_id, role) values (new.id, 'admin');
    update public.profiles set onboarding_step = 4 where id = new.id;
  else
    insert into public.user_roles (user_id, role) values (new.id, 'intern');
  end if;

  return new;
end;
$function$;