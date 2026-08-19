-- ============================================================================
-- Suivi des ruches IziGreen — schéma Supabase
-- À coller intégralement dans Supabase > SQL Editor > New query > Run.
--
-- Aligné sur le schéma réel que Lovable Cloud avait généré (mêmes noms de
-- tables/colonnes : hives, user_roles, has_role...), avec deux renforts de
-- sécurité que l'original n'avait pas :
--   1. Le CA/prix est masqué en base pour les comptes non-admin (pas juste
--      caché à l'écran).
--   2. La création d'une ruche est réservée aux admins côté base, pas
--      seulement côté interface.
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

-- security definer = peut lire user_roles même si la RLS ci-dessous
-- restreint l'accès direct (évite toute récursion de policy).
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
-- 2. RUCHERS (table "hives")
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
  beekeeper text NOT NULL DEFAULT '',

  -- Rucher partagé : hôte (accueille) ou hébergé (rattaché à un hôte existant)
  share_role text NOT NULL DEFAULT '' CHECK (share_role IN ('', 'hote', 'heberge')),
  host_hive_id uuid REFERENCES public.hives(id) ON DELETE SET NULL,

  latitude double precision,
  longitude double precision,
  -- Prix personnalisé — null = tarif de base (hive_count x 1440€ HT/an),
  -- calculé côté application.
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

-- Lecture directe de la table brute réservée aux admins (le prix y est en
-- clair). Les comptes standards passent par la vue masquée ci-dessous.
CREATE POLICY "hives_read_admin_only" ON public.hives
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- Création/modification/suppression réservées aux admins (renforcement :
-- l'original de Lovable autorisait n'importe quel compte connecté à créer
-- une ruche, ce qui contredit "les utilisateurs standards sont en lecture
-- seule").
CREATE POLICY "hives_insert_admin_only" ON public.hives
  FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "hives_update_admin_only" ON public.hives
  FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "hives_delete_admin_only" ON public.hives
  FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- ----------------------------------------------------------------------------
-- 3. VUE SÉCURISÉE — lecture pour tout le monde, CA masqué pour les non-admins
-- ----------------------------------------------------------------------------
-- Le statut (à installer / en cours / renouvellement) est calculé à la volée
-- depuis start_date : jamais stocké, jamais désynchronisé, aucune tâche
-- planifiée à maintenir.
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
  h.beekeeper,
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
FROM public.hives h;

GRANT SELECT ON public.v_hives TO authenticated;

-- ----------------------------------------------------------------------------
-- 4. TEMPS RÉEL
-- ----------------------------------------------------------------------------
-- Réservé aux admins par construction : Realtime s'abonne à la table brute
-- (jamais à une vue), qui est elle-même verrouillée aux admins ci-dessus —
-- le CA ne transite donc jamais en clair sur ce canal. Les comptes standards
-- se resynchronisent via la vue (au chargement, au focus, et à intervalle).
ALTER PUBLICATION supabase_realtime ADD TABLE public.hives;

-- ============================================================================
-- APRÈS EXÉCUTION :
-- 1. Authentication > Users > Add user, pour chacun des 50-60 comptes.
--    Un rôle "user" n'est PAS créé automatiquement ici (contrairement à la
--    version Lovable) — la gestion des accès se fera depuis l'espace admin
--    de l'appli (étape à venir). En attendant, tu peux insérer un rôle
--    manuellement :
--    insert into public.user_roles (user_id, role) values
--      ((select id from auth.users where email = '...'), 'user');
-- 2. Ton propre compte (ryad.bouchami@izigroup.fr) passe admin automatique-
--    ment via le trigger, à la création de ton compte auth.
-- 3. Vérification recommandée : connecte-toi avec un compte "user" et
--    confirme que price/base_revenue renvoient bien null via v_hives, et
--    qu'une requête directe sur public.hives renvoie 0 ligne pour ce compte.
-- ============================================================================
