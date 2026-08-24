-- ============================================================================
-- Migration : passages mensuels des apiculteurs (date + photo + validation)
-- À coller dans Supabase > SQL Editor > New query > Run, sur le projet
-- déjà en ligne.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Table des passages
-- ----------------------------------------------------------------------------
CREATE TABLE public.hive_visits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hive_id uuid NOT NULL REFERENCES public.hives(id) ON DELETE CASCADE,
  beekeeper_id uuid REFERENCES public.beekeepers(id),
  visit_date date NOT NULL,
  photo_path text,
  note text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_visits_hive ON public.hive_visits(hive_id, visit_date DESC);

ALTER TABLE public.hive_visits ENABLE ROW LEVEL SECURITY;

-- Lecture ouverte à tout compte connecté (le dashboard doit pouvoir montrer
-- "dernier passage" sur n'importe quel rucher, y compris pour les admins).
CREATE POLICY "visits_read_all" ON public.hive_visits
  FOR SELECT TO authenticated USING (true);

-- Un apiculteur ne peut enregistrer un passage QUE sur un rucher où il est
-- nommé apiculteur ; un admin peut le faire pour n'importe quel rucher
-- (utile en cas de besoin/oubli).
CREATE POLICY "visits_insert_own_hive_or_admin" ON public.hive_visits
  FOR INSERT TO authenticated WITH CHECK (
    public.has_role(auth.uid(), 'admin')
    OR EXISTS (
      SELECT 1 FROM public.hives h
      JOIN public.beekeepers b ON b.id = h.beekeeper_id
      WHERE h.id = hive_visits.hive_id AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "visits_delete_admin_only" ON public.hive_visits
  FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

GRANT SELECT, INSERT ON public.hive_visits TO authenticated;
GRANT DELETE ON public.hive_visits TO authenticated;
GRANT ALL ON public.hive_visits TO service_role;

-- ----------------------------------------------------------------------------
-- 2. Stockage des photos de passage
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('visit-photos', 'visit-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "visit_photos_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'visit-photos');

CREATE POLICY "visit_photos_authenticated_upload" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'visit-photos');

-- ============================================================================
-- Rien d'autre à faire ici : la vue v_hives n'a pas besoin d'être modifiée,
-- les passages se lisent séparément depuis l'appli.
-- ============================================================================
