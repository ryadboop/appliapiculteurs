-- ============================================================================
-- Suivi des ruches IziGreen — schéma Supabase
-- À coller intégralement dans Supabase > SQL Editor > New query > Run.
-- Peut être exécuté une seule fois sur un projet neuf.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. PROFILS (rôle admin / utilisateur)
-- ----------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'user' check (role in ('admin', 'user')),
  full_name text,
  created_at timestamptz not null default now()
);

-- Crée automatiquement un profil (rôle "user" par défaut) à chaque nouvel
-- utilisateur créé dans Supabase Authentication. Passer un compte en admin
-- se fait ensuite avec : update public.profiles set role = 'admin' where id = '...';
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name)
  values (new.id, 'user', coalesce(new.raw_user_meta_data->>'full_name', new.email));
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Fonction utilitaire : l'utilisateur connecté est-il admin ?
-- security definer = peut lire "profiles" même si la RLS de "profiles"
-- restreint l'accès direct (évite toute récursion de policy).
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ----------------------------------------------------------------------------
-- 2. CLIENTS
-- ----------------------------------------------------------------------------
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 3. RUCHERS (table centrale)
-- ----------------------------------------------------------------------------
create table public.ruchers (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id),

  lieu_type text not null check (lieu_type in ('fareins', 'sur_site', 'rucher_partage')),
  adresse text,
  commune_ville text,
  region text,
  latitude numeric(9,6),
  longitude numeric(9,6),

  nombre_ruches integer not null default 1 check (nombre_ruches > 0),
  apiculteur text,

  -- Rucher partagé : hôte (accueille) ou hébergé (rattaché à un rucher hôte existant)
  rucher_partage_role text check (rucher_partage_role in ('hote', 'heberge')),
  rucher_hote_id uuid references public.ruchers(id),

  -- Tarif de base = nombre de ruches x 1440€ HT/an, calculé automatiquement.
  -- Le prix réellement facturé (prix_total) est pré-rempli avec ce montant
  -- côté formulaire mais reste modifiable pour appliquer une remise.
  prix_base numeric(10,2) generated always as (nombre_ruches * 1440) stored,
  prix_total numeric(10,2) not null,

  -- null ou date future = "à installer" (pas encore posée)
  date_installation date,

  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint chk_adresse_si_necessaire check (
    lieu_type = 'fareins' or (adresse is not null and length(trim(adresse)) > 0)
  ),
  constraint chk_role_partage_coherent check (
    lieu_type = 'rucher_partage' or (rucher_partage_role is null and rucher_hote_id is null)
  ),
  constraint chk_heberge_a_un_hote check (
    rucher_partage_role is distinct from 'heberge' or rucher_hote_id is not null
  )
);

create index idx_ruchers_client on public.ruchers(client_id);
create index idx_ruchers_date_installation on public.ruchers(date_installation);
create index idx_ruchers_hote on public.ruchers(rucher_hote_id);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_ruchers_updated_at
before update on public.ruchers
for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- 4. VUE SÉCURISÉE — un seul point d'accès en lecture pour tout le monde
-- ----------------------------------------------------------------------------
-- Le statut (à installer / en cours / renouvellement) est calculé à la volée
-- depuis la date d'installation : pas de tâche planifiée à maintenir, jamais
-- désynchronisé. Pareil pour l'année de saison, dérivée de la date — au
-- 1er janvier, "cette année" redevient naturellement vide.
--
-- Masquage du CA : prix_base et prix_total renvoient NULL pour tout compte
-- qui n'a pas le rôle admin, directement dans la requête SQL (donc même en
-- inspectant le réseau depuis le navigateur, un compte "user" ne reçoit
-- jamais la valeur réelle — ce n'est pas juste caché à l'affichage).
create view public.v_ruchers as
select
  r.id,
  r.client_id,
  c.nom as client_nom,
  r.lieu_type,
  r.adresse,
  r.commune_ville,
  r.region,
  r.latitude,
  r.longitude,
  r.nombre_ruches,
  r.apiculteur,
  r.rucher_partage_role,
  r.rucher_hote_id,
  case when public.is_admin() then r.prix_base else null end as prix_base,
  case when public.is_admin() then r.prix_total else null end as prix_total,
  r.date_installation,
  extract(year from r.date_installation)::int as annee_installation,
  case
    when r.date_installation is null or r.date_installation > current_date then 'a_installer'
    when current_date >= (r.date_installation + interval '3 years') then 'renouvellement'
    else 'en_cours'
  end as statut,
  r.created_at,
  r.updated_at
from public.ruchers r
left join public.clients c on c.id = r.client_id;

-- ----------------------------------------------------------------------------
-- 5. SÉCURITÉ (Row Level Security)
-- ----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.clients enable row level security;
alter table public.ruchers enable row level security;

-- profiles : chacun voit son propre profil, les admins voient tout le monde
create policy "Voir son profil ou tout si admin" on public.profiles
  for select using (auth.uid() = id or public.is_admin());

-- clients : accès direct à la table réservé aux admins.
-- Les utilisateurs standards passent uniquement par v_ruchers (client_nom),
-- jamais par la table brute.
create policy "Clients: lecture admin uniquement" on public.clients
  for select using (public.is_admin());
create policy "Clients: écriture admin uniquement" on public.clients
  for insert with check (public.is_admin());
create policy "Clients: modif admin uniquement" on public.clients
  for update using (public.is_admin()) with check (public.is_admin());

-- ruchers : même logique — accès direct réservé aux admins, tout le monde
-- passe par v_ruchers en lecture (qui masque le CA pour les non-admins).
create policy "Ruchers: lecture admin uniquement" on public.ruchers
  for select using (public.is_admin());
create policy "Ruchers: création admin uniquement" on public.ruchers
  for insert with check (public.is_admin());
create policy "Ruchers: modif admin uniquement" on public.ruchers
  for update using (public.is_admin()) with check (public.is_admin());
create policy "Ruchers: suppression admin uniquement" on public.ruchers
  for delete using (public.is_admin());

-- Autorise tout le monde à lire la vue sécurisée (elle applique elle-même
-- le masquage du CA ligne par ligne selon le rôle de l'appelant).
grant select on public.v_ruchers to authenticated;
grant select, insert, update, delete on public.ruchers to authenticated;
grant select, insert, update on public.clients to authenticated;
grant select on public.profiles to authenticated;

-- ----------------------------------------------------------------------------
-- 6. TEMPS RÉEL
-- ----------------------------------------------------------------------------
-- Permet aux comptes admin de recevoir les mises à jour instantanément
-- (insertion/modif/suppression d'un rucher) sans recharger la page.
-- Note : Supabase Realtime s'abonne à la table brute (pas à une vue), donc
-- ce canal respecte la policy "Ruchers: lecture admin uniquement" ci-dessus
-- — un compte standard n'y a pas accès, ce qui est volontaire pour ne
-- jamais transmettre le CA en clair sur le réseau, même dans un message
-- realtime. Les comptes standards se resynchronisent via un rafraîchissement
-- de la vue (au chargement, après une action, et à intervalle régulier).
alter publication supabase_realtime add table public.ruchers;

-- ============================================================================
-- APRÈS EXÉCUTION :
-- 1. Authentication > Users > Add user, pour chacun des 50-60 comptes
--    (email + mot de passe, ou lien magique — un profil "user" est créé
--    automatiquement par le trigger ci-dessus).
-- 2. Pour te passer admin (et tes futurs admins) :
--    update public.profiles set role = 'admin' where id =
--      (select id from auth.users where email = 'ton.email@izigreen.fr');
-- 3. Vérification recommandée : connecte-toi avec un compte "user" et
--    confirme que prix_base/prix_total renvoient bien null via v_ruchers.
-- ============================================================================
