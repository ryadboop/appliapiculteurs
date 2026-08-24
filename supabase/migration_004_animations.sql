-- ============================================================================
-- Migration : animations (interventions sur ou hors site), réservées admin
-- À coller dans Supabase > SQL Editor > New query > Run.
-- ============================================================================

CREATE TABLE public.animations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hive_id uuid NOT NULL REFERENCES public.hives(id) ON DELETE CASCADE,

  location_type text NOT NULL DEFAULT 'site' CHECK (location_type IN ('site', 'autre')),
  custom_address text NOT NULL DEFAULT '',

  animation_date date NOT NULL,

  -- Intervenant : soit un apiculteur partenaire existant, soit un nom libre
  -- (collègue izigreen, intervenant externe...).
  beekeeper_id uuid REFERENCES public.beekeepers(id),
  intervenant_name text NOT NULL DEFAULT '',

  comment text,

  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT chk_animation_adresse CHECK (
    location_type = 'site' OR length(trim(custom_address)) > 0
  ),
  CONSTRAINT chk_animation_intervenant CHECK (
    beekeeper_id IS NOT NULL OR length(trim(intervenant_name)) > 0
  )
);

CREATE INDEX idx_animations_date ON public.animations(animation_date);
CREATE INDEX idx_animations_hive ON public.animations(hive_id);

ALTER TABLE public.animations ENABLE ROW LEVEL SECURITY;

-- Entièrement réservé aux admins, lecture comme écriture.
CREATE POLICY "animations_admin_select" ON public.animations
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "animations_admin_insert" ON public.animations
  FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "animations_admin_delete" ON public.animations
  FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

GRANT SELECT, INSERT, DELETE ON public.animations TO authenticated;
GRANT ALL ON public.animations TO service_role;
