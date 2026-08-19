-- ============================================================================
-- Migration : répertoire des apiculteurs partenaires
-- À coller dans Supabase > SQL Editor > New query > Run, sur le projet
-- DÉJÀ EN LIGNE (ne pas relancer schema.sql en entier, juste ceci).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Table des apiculteurs partenaires
-- ----------------------------------------------------------------------------
CREATE TABLE public.beekeepers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  -- Rempli plus tard, quand un compte de connexion est créé pour cet
  -- apiculteur (prochaine étape, via l'espace admin).
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.beekeepers ENABLE ROW LEVEL SECURITY;

-- Le nom d'un apiculteur n'est pas une donnée sensible (contrairement au CA) :
-- lecture ouverte à tout compte connecté, pour alimenter le menu déroulant
-- du formulaire et permettre à un apiculteur de se reconnaître dans la liste.
CREATE POLICY "beekeepers_read_all" ON public.beekeepers
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "beekeepers_insert_admin" ON public.beekeepers
  FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "beekeepers_update_admin" ON public.beekeepers
  FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "beekeepers_delete_admin" ON public.beekeepers
  FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.beekeepers TO authenticated;
GRANT ALL ON public.beekeepers TO service_role;

-- Apiculteur par défaut pour Fareins (auto-rempli dans le formulaire).
INSERT INTO public.beekeepers (name) VALUES ('Dominique Parriaud')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. hives.beekeeper (texte libre) → hives.beekeeper_id (relation)
-- ----------------------------------------------------------------------------
ALTER TABLE public.hives ADD COLUMN beekeeper_id uuid REFERENCES public.beekeepers(id);
ALTER TABLE public.hives DROP COLUMN beekeeper;

CREATE INDEX idx_hives_beekeeper ON public.hives(beekeeper_id);

-- ----------------------------------------------------------------------------
-- 3. Vue sécurisée : on résout le nom de l'apiculteur au passage
-- ----------------------------------------------------------------------------
DROP VIEW public.v_hives;

CREATE VIEW public.v_hives AS
SELECT
  h.id,
  h.name,
  h.client,
  h.site,
  h.region,
  h.start_date,
  h.hive_count,
  h.placement,
  h.placement_detail,
  h.beekeeper_id,
  b.name AS beekeeper_name,
  h.share_role,
  h.host_hive_id,
  h.latitude,
  h.longitude,
  CASE WHEN public.has_role(auth.uid(), 'admin') THEN h.price ELSE NULL END AS price,
  CASE WHEN public.has_role(auth.uid(), 'admin') THEN h.hive_count * 1440 ELSE NULL END AS base_revenue,
  CASE
    WHEN h.start_date > CURRENT_DATE THEN 'pending'
    WHEN CURRENT_DATE >= (h.start_date + INTERVAL '3 years') THEN 'renewal'
    ELSE 'active'
  END AS status,
  EXTRACT(YEAR FROM h.start_date)::int AS start_year,
  h.created_at,
  h.updated_at
FROM public.hives h
LEFT JOIN public.beekeepers b ON b.id = h.beekeeper_id;

GRANT SELECT ON public.v_hives TO authenticated;

-- ============================================================================
-- Pour lier un apiculteur à un compte de connexion plus tard (quand son
-- accès sera créé) :
-- update public.beekeepers set user_id =
--   (select id from auth.users where email = '...')
-- where name = '...';
-- ============================================================================
