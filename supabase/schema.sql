-- ============================================================================
-- Suivi des ruches IziGreen — schéma Supabase
-- À coller intégralement dans Supabase > SQL Editor > New query > Run.
-- Pour un projet NEUF uniquement. Si ton projet existe déjà (tables créées
-- via une version précédente de ce script), utilise plutôt le fichier de
-- migration correspondant dans ce dossier.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. RÔLES (admin / user)
-- ----------------------------------------------------------------------------
CREATE TYPE public.app_role AS ENUM ('admin', 'user');

CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL DEFAULT 'user',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role
  )
$$;

CREATE POLICY "own_roles_readable" ON public.user_roles
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "admins_read_all_roles" ON public.user_roles
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- Passe automatiquement ton propre compte en admin à la création — pense à
-- changer l'email ci-dessous si besoin avant d'exécuter ce script.
CREATE OR REPLACE FUNCTION public.grant_owner_admin()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF lower(NEW.email) = 'ryad.bouchami@izigroup.fr' THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'admin')
    ON CONFLICT (user_id, role) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created_grant_owner_admin
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.grant_owner_admin();

REVOKE ALL ON FUNCTION public.grant_owner_admin() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, service_role;
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;

-- ----------------------------------------------------------------------------
-- 2. APICULTEURS PARTENAIRES
-- ----------------------------------------------------------------------------
CREATE TABLE public.beekeepers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  -- Rempli quand un compte de connexion est créé pour cet apiculteur,
  -- depuis l'espace admin — permet de faire remonter ses propres ruchers
  -- en premier sur son dashboard.
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.beekeepers ENABLE ROW LEVEL SECURITY;

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

INSERT INTO public.beekeepers (name) VALUES ('Dominique Parriaud')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. RUCHERS (table "hives")
-- ----------------------------------------------------------------------------
CREATE TABLE public.hives (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  client text NOT NULL DEFAULT '',
  site text NOT NULL DEFAULT '',
  region text NOT NULL DEFAULT '',
  start_date date NOT NULL,
  hive_count integer NOT NULL DEFAULT 1 CHECK (hive_count > 0),

  placement text NOT NULL DEFAULT 'site' CHECK (placement IN ('friche', 'site', 'partage')),
  placement_detail text NOT NULL DEFAULT '',
  beekeeper_id uuid REFERENCES public.beekeepers(id),

  share_role text NOT NULL DEFAULT '' CHECK (share_role IN ('', 'hote', 'heberge')),
  host_hive_id uuid REFERENCES public.hives(id) ON DELETE SET NULL,

  latitude double precision,
  longitude double precision,
  price integer,

  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_adresse_si_necessaire CHECK (
    placement = 'friche' OR length(trim(placement_detail)) > 0
  ),
  CONSTRAINT chk_heberge_a_un_hote CHECK (
    share_role <> 'heberge' OR host_hive_id IS NOT NULL
  )
);

CREATE INDEX idx_hives_start_date ON public.hives(start_date);
CREATE INDEX idx_hives_host ON public.hives(host_hive_id);
CREATE INDEX idx_hives_beekeeper ON public.hives(beekeeper_id);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_hives_updated_at
BEFORE UPDATE ON public.hives
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.hives ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hives_read_admin_only" ON public.hives
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "hives_insert_admin_only" ON public.hives
  FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "hives_update_admin_only" ON public.hives
  FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "hives_delete_admin_only" ON public.hives
  FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- ----------------------------------------------------------------------------
-- 4. VUE SÉCURISÉE — lecture pour tout le monde, CA masqué pour les non-admins
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- 5. TEMPS RÉEL
-- ----------------------------------------------------------------------------
ALTER PUBLICATION supabase_realtime ADD TABLE public.hives;

-- ============================================================================
-- APRÈS EXÉCUTION :
-- 1. Authentication > Users > Add user, pour chacun des comptes (équipe +
--    apiculteurs). Un rôle "user" n'est pas créé automatiquement — la
--    gestion des accès se fera depuis l'espace admin de l'appli.
-- 2. Ton propre compte (ryad.bouchami@izigroup.fr) passe admin automatique-
--    ment via le trigger.
-- 3. Pour lier un apiculteur à son compte de connexion une fois créé :
--    update public.beekeepers set user_id =
--      (select id from auth.users where email = '...')
--    where name = '...';
-- ============================================================================
