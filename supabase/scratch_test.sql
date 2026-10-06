DO $$
DECLARE
  v_user auth.users%ROWTYPE;
BEGIN
  SELECT * INTO v_user FROM auth.users WHERE email = 'sasmithakrishnamkorthy007@gmail.com';
  INSERT INTO profiles (id, email, full_name, institution, academic_level)
  VALUES (
    v_user.id,
    v_user.email,
    COALESCE(v_user.raw_user_meta_data->>'full_name', split_part(v_user.email, '@', 1)),
    NULLIF(v_user.raw_user_meta_data->>'institution', ''),
    COALESCE(
      (v_user.raw_user_meta_data->>'academic_level')::academic_level,
      'undergraduate'::academic_level
    )
  );
END $$;
