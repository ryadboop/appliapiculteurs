-- ============================================================================
-- Migration 006 : date ET heure automatiques pour les passages mensuels
-- À coller dans Supabase > SQL Editor > New query > Run, sur le projet
-- déjà en ligne (après les migrations 002 à 005).
--
-- Contexte : jusqu'ici, un passage n'enregistrait qu'une date (saisie
-- manuellement par l'apiculteur/l'admin). Désormais la date ET l'heure sont
-- posées automatiquement par la base au moment de la validation du
-- passage (colonne "visited_at", type timestamptz, défaut now()) — le
-- client ne les transmet plus jamais lui-même.
-- ============================================================================

-- 1. On recrée l'index qui référence l'ancienne colonne avant de la modifier.
DROP INDEX IF EXISTS public.idx_visits_hive;

-- 2. Conversion de la colonne "visit_date" (date) en "visited_at"
--    (timestamptz). Les passages déjà enregistrés gardent leur date
--    d'origine, à minuit (l'heure exacte n'était pas connue avant cette
--    migration) ; seuls les nouveaux passages auront une heure réelle.
ALTER TABLE public.hive_visits
  ALTER COLUMN visit_date TYPE timestamptz USING visit_date::timestamptz;

ALTER TABLE public.hive_visits
  RENAME COLUMN visit_date TO visited_at;

ALTER TABLE public.hive_visits
  ALTER COLUMN visited_at SET DEFAULT now();

CREATE INDEX idx_visits_hive ON public.hive_visits(hive_id, visited_at DESC);

-- ============================================================================
-- Rien d'autre à faire : les politiques RLS existantes (visits_read_all,
-- visits_insert_own_hive_or_admin, visits_delete_admin_only) ne référencent
-- pas cette colonne par son nom et restent valables sans modification.
--
-- Côté application : la photo et le commentaire sont désormais obligatoires
-- pour valider un passage (contrôle fait côté interface ; les passages déjà
-- enregistrés sans photo/commentaire restent visibles tels quels dans
-- l'historique, rien n'est supprimé).
-- ============================================================================
