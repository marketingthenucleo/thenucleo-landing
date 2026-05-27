-- RPC work_set_my_theme(p_theme boolean)
-- Permite a un usuario admin work (allowlist 5 emails TheNucleo) actualizar
-- su propio bub_user.theme desde work.thenucleo.com.
-- Pareja inversa de work_current_user_profile() v3 (que devuelve theme).
-- El PATCH a Bubble lo gestiona la Edge Function sync_theme_to_bubble
-- invocada por el cliente JS justo después de esta RPC.
--
-- Applied via MCP supabase apply_migration 2026-05-27.

CREATE OR REPLACE FUNCTION public.work_set_my_theme(p_theme boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email   text := LOWER(COALESCE(auth.email(), ''));
  v_allowed text[] := ARRAY[
    'benjamin.sanchis@thenucleo.com',
    'alejandro.salgado@thenucleo.com',
    'maria.zorrilla@thenucleo.com',
    'rosa.escobar@thenucleo.com',
    'valentina.ramirez@thenucleo.com'
  ];
  v_bubble_id text;
BEGIN
  IF v_email = '' OR NOT (v_email = ANY(v_allowed)) THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;

  UPDATE public.bub_user
     SET theme = p_theme
   WHERE LOWER(email) = v_email
  RETURNING bubble_id INTO v_bubble_id;

  IF v_bubble_id IS NULL THEN
    RAISE EXCEPTION 'user_not_found' USING ERRCODE = 'P0002';
  END IF;

  RETURN jsonb_build_object(
    'ok',        true,
    'theme',     p_theme,
    'bubble_id', v_bubble_id
  );
END;
$$;

REVOKE ALL ON FUNCTION public.work_set_my_theme(boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.work_set_my_theme(boolean) TO authenticated;

COMMENT ON FUNCTION public.work_set_my_theme(boolean) IS
  'Allowlist 5 emails TheNucleo. Actualiza bub_user.theme del usuario autenticado. El sync con Bubble lo hace la EF sync_theme_to_bubble llamada por el cliente.';
