-- ============================================================================
-- Migration : journal d'audit (traçabilité des créations/modifications/
-- suppressions) + validation serveur des photos de passage.
-- À coller dans Supabase > SQL Editor > New query > Run.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Table du journal
-- ----------------------------------------------------------------------------
CREATE TABLE public.audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  record_id uuid NOT NULL,
  action text NOT NULL CHECK (action IN ('insert', 'update', 'delete')),
  old_data jsonb,
  new_data jsonb,
  changed_by uuid REFERENCES auth.users(id),
  changed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_table_record ON public.audit_log(table_name, record_id, changed_at DESC);
CREATE INDEX idx_audit_changed_at ON public.audit_log(changed_at DESC);

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Lecture réservée aux admins. Aucune policy d'écriture pour les comptes
-- authentifiés : seule la fonction ci-dessous (security definer, déclenchée
-- par les triggers) peut y écrire — impossible de trafiquer le journal
-- depuis l'appli, même en admin.
CREATE POLICY "audit_admin_read" ON public.audit_log
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'));

GRANT SELECT ON public.audit_log TO authenticated;
GRANT ALL ON public.audit_log TO service_role;

-- ----------------------------------------------------------------------------
-- 2. Fonction générique de journalisation, branchée en trigger
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.log_audit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO public.audit_log(table_name, record_id, action, old_data, changed_by)
    VALUES (TG_TABLE_NAME, OLD.id, 'delete', to_jsonb(OLD), auth.uid());
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO public.audit_log(table_name, record_id, action, old_data, new_data, changed_by)
    VALUES (TG_TABLE_NAME, NEW.id, 'update', to_jsonb(OLD), to_jsonb(NEW), auth.uid());
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO public.audit_log(table_name, record_id, action, new_data, changed_by)
    VALUES (TG_TABLE_NAME, NEW.id, 'insert', to_jsonb(NEW), auth.uid());
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.log_audit() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER trg_audit_hives
AFTER INSERT OR UPDATE OR DELETE ON public.hives
FOR EACH ROW EXECUTE FUNCTION public.log_audit();

CREATE TRIGGER trg_audit_beekeepers
AFTER INSERT OR UPDATE OR DELETE ON public.beekeepers
FOR EACH ROW EXECUTE FUNCTION public.log_audit();

CREATE TRIGGER trg_audit_animations
AFTER INSERT OR UPDATE OR DELETE ON public.animations
FOR EACH ROW EXECUTE FUNCTION public.log_audit();

CREATE TRIGGER trg_audit_hive_visits
AFTER INSERT OR UPDATE OR DELETE ON public.hive_visits
FOR EACH ROW EXECUTE FUNCTION public.log_audit();

CREATE TRIGGER trg_audit_user_roles
AFTER INSERT OR UPDATE OR DELETE ON public.user_roles
FOR EACH ROW EXECUTE FUNCTION public.log_audit();

-- ----------------------------------------------------------------------------
-- 3. Vue admin : journal avec l'email de l'auteur résolu
-- ----------------------------------------------------------------------------
CREATE VIEW public.v_audit_log AS
SELECT a.*, u.email AS changed_by_email
FROM public.audit_log a
LEFT JOIN auth.users u ON u.id = a.changed_by
WHERE public.has_role(auth.uid(), 'admin');

GRANT SELECT ON public.v_audit_log TO authenticated;

-- ----------------------------------------------------------------------------
-- 4. Validation serveur des photos de passage (taille + type de fichier)
-- ----------------------------------------------------------------------------
-- Jusqu'ici seule une suggestion côté navigateur limitait ça — contournable.
-- Ceci est appliqué par Supabase Storage lui-même, impossible à contourner
-- depuis le navigateur : 8 Mo max, uniquement des formats image courants
-- (y compris HEIC/HEIF, le format par défaut des photos iPhone).
UPDATE storage.buckets
SET file_size_limit = 8388608,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
WHERE id = 'visit-photos';
