--
-- PostgreSQL database dump
--

\restrict WXGL5GaDfMaOD4qSjQHsYTssgBwvwflj5ms9dCcdjmuMCkRZJKdTlYn6tk0iOEr

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.11 (Ubuntu 17.11-1.pgdg24.04+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP POLICY IF EXISTS visits_read_all ON public.hive_visits;
DROP POLICY IF EXISTS visits_insert_own_hive_or_admin ON public.hive_visits;
DROP POLICY IF EXISTS visits_delete_admin_only ON public.hive_visits;
DROP POLICY IF EXISTS own_roles_readable ON public.user_roles;
DROP POLICY IF EXISTS hives_update_admin_only ON public.hives;
DROP POLICY IF EXISTS hives_read_admin_only ON public.hives;
DROP POLICY IF EXISTS hives_insert_admin_only ON public.hives;
DROP POLICY IF EXISTS hives_delete_admin_only ON public.hives;
DROP POLICY IF EXISTS beekeepers_update_admin ON public.beekeepers;
DROP POLICY IF EXISTS beekeepers_read_all ON public.beekeepers;
DROP POLICY IF EXISTS beekeepers_insert_admin ON public.beekeepers;
DROP POLICY IF EXISTS beekeepers_delete_admin ON public.beekeepers;
DROP POLICY IF EXISTS audit_admin_read ON public.audit_log;
DROP POLICY IF EXISTS animations_admin_select ON public.animations;
DROP POLICY IF EXISTS animations_admin_insert ON public.animations;
DROP POLICY IF EXISTS animations_admin_delete ON public.animations;
DROP POLICY IF EXISTS admins_read_all_roles ON public.user_roles;
ALTER TABLE IF EXISTS ONLY public.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.hives DROP CONSTRAINT IF EXISTS hives_host_hive_id_fkey;
ALTER TABLE IF EXISTS ONLY public.hives DROP CONSTRAINT IF EXISTS hives_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.hives DROP CONSTRAINT IF EXISTS hives_beekeeper_id_fkey;
ALTER TABLE IF EXISTS ONLY public.hive_visits DROP CONSTRAINT IF EXISTS hive_visits_hive_id_fkey;
ALTER TABLE IF EXISTS ONLY public.hive_visits DROP CONSTRAINT IF EXISTS hive_visits_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.hive_visits DROP CONSTRAINT IF EXISTS hive_visits_beekeeper_id_fkey;
ALTER TABLE IF EXISTS ONLY public.beekeepers DROP CONSTRAINT IF EXISTS beekeepers_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.audit_log DROP CONSTRAINT IF EXISTS audit_log_changed_by_fkey;
ALTER TABLE IF EXISTS ONLY public.animations DROP CONSTRAINT IF EXISTS animations_hive_id_fkey;
ALTER TABLE IF EXISTS ONLY public.animations DROP CONSTRAINT IF EXISTS animations_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.animations DROP CONSTRAINT IF EXISTS animations_beekeeper_id_fkey;
DROP TRIGGER IF EXISTS trg_hives_updated_at ON public.hives;
DROP TRIGGER IF EXISTS trg_audit_user_roles ON public.user_roles;
DROP TRIGGER IF EXISTS trg_audit_hives ON public.hives;
DROP TRIGGER IF EXISTS trg_audit_hive_visits ON public.hive_visits;
DROP TRIGGER IF EXISTS trg_audit_beekeepers ON public.beekeepers;
DROP TRIGGER IF EXISTS trg_audit_animations ON public.animations;
DROP INDEX IF EXISTS public.idx_visits_hive;
DROP INDEX IF EXISTS public.idx_hives_start_date;
DROP INDEX IF EXISTS public.idx_hives_host;
DROP INDEX IF EXISTS public.idx_hives_beekeeper;
DROP INDEX IF EXISTS public.idx_audit_table_record;
DROP INDEX IF EXISTS public.idx_audit_changed_at;
DROP INDEX IF EXISTS public.idx_animations_hive;
DROP INDEX IF EXISTS public.idx_animations_date;
ALTER TABLE IF EXISTS ONLY public.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_role_key;
ALTER TABLE IF EXISTS ONLY public.user_roles DROP CONSTRAINT IF EXISTS user_roles_pkey;
ALTER TABLE IF EXISTS ONLY public.hives DROP CONSTRAINT IF EXISTS hives_pkey;
ALTER TABLE IF EXISTS ONLY public.hive_visits DROP CONSTRAINT IF EXISTS hive_visits_pkey;
ALTER TABLE IF EXISTS ONLY public.beekeepers DROP CONSTRAINT IF EXISTS beekeepers_pkey;
ALTER TABLE IF EXISTS ONLY public.beekeepers DROP CONSTRAINT IF EXISTS beekeepers_name_key;
ALTER TABLE IF EXISTS ONLY public.audit_log DROP CONSTRAINT IF EXISTS audit_log_pkey;
ALTER TABLE IF EXISTS ONLY public.animations DROP CONSTRAINT IF EXISTS animations_pkey;
DROP VIEW IF EXISTS public.v_hives;
DROP VIEW IF EXISTS public.v_audit_log;
DROP TABLE IF EXISTS public.user_roles;
DROP TABLE IF EXISTS public.hives;
DROP TABLE IF EXISTS public.hive_visits;
DROP TABLE IF EXISTS public.beekeepers;
DROP TABLE IF EXISTS public.audit_log;
DROP TABLE IF EXISTS public.animations;
DROP FUNCTION IF EXISTS public.set_updated_at();
DROP FUNCTION IF EXISTS public.log_audit();
DROP FUNCTION IF EXISTS public.has_role(_user_id uuid, _role public.app_role);
DROP FUNCTION IF EXISTS public.grant_owner_admin();
DROP TYPE IF EXISTS public.app_role;
DROP SCHEMA IF EXISTS public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: app_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.app_role AS ENUM (
    'admin',
    'user'
);


--
-- Name: grant_owner_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.grant_owner_admin() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: has_role(uuid, public.app_role); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_role(_user_id uuid, _role public.app_role) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role
  )
$$;


--
-- Name: log_audit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_audit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: animations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.animations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    hive_id uuid NOT NULL,
    location_type text DEFAULT 'site'::text NOT NULL,
    custom_address text DEFAULT ''::text NOT NULL,
    animation_date date NOT NULL,
    beekeeper_id uuid,
    intervenant_name text DEFAULT ''::text NOT NULL,
    comment text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT animations_location_type_check CHECK ((location_type = ANY (ARRAY['site'::text, 'autre'::text]))),
    CONSTRAINT chk_animation_adresse CHECK (((location_type = 'site'::text) OR (length(TRIM(BOTH FROM custom_address)) > 0))),
    CONSTRAINT chk_animation_intervenant CHECK (((beekeeper_id IS NOT NULL) OR (length(TRIM(BOTH FROM intervenant_name)) > 0)))
);


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    table_name text NOT NULL,
    record_id uuid NOT NULL,
    action text NOT NULL,
    old_data jsonb,
    new_data jsonb,
    changed_by uuid,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT audit_log_action_check CHECK ((action = ANY (ARRAY['insert'::text, 'update'::text, 'delete'::text])))
);


--
-- Name: beekeepers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beekeepers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: hive_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hive_visits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    hive_id uuid NOT NULL,
    beekeeper_id uuid,
    visit_date date NOT NULL,
    photo_path text,
    note text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: hives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    client text DEFAULT ''::text NOT NULL,
    site text DEFAULT ''::text NOT NULL,
    region text DEFAULT ''::text NOT NULL,
    start_date date NOT NULL,
    hive_count integer DEFAULT 1 NOT NULL,
    placement text DEFAULT 'site'::text NOT NULL,
    placement_detail text DEFAULT ''::text NOT NULL,
    share_role text DEFAULT ''::text NOT NULL,
    host_hive_id uuid,
    latitude double precision,
    longitude double precision,
    price integer,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    beekeeper_id uuid,
    CONSTRAINT chk_adresse_si_necessaire CHECK (((placement = 'friche'::text) OR (length(TRIM(BOTH FROM placement_detail)) > 0))),
    CONSTRAINT chk_heberge_a_un_hote CHECK (((share_role <> 'heberge'::text) OR (host_hive_id IS NOT NULL))),
    CONSTRAINT hives_hive_count_check CHECK ((hive_count > 0)),
    CONSTRAINT hives_placement_check CHECK ((placement = ANY (ARRAY['friche'::text, 'site'::text, 'partage'::text]))),
    CONSTRAINT hives_share_role_check CHECK ((share_role = ANY (ARRAY[''::text, 'hote'::text, 'heberge'::text])))
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role public.app_role DEFAULT 'user'::public.app_role NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: v_audit_log; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_audit_log AS
 SELECT a.id,
    a.table_name,
    a.record_id,
    a.action,
    a.old_data,
    a.new_data,
    a.changed_by,
    a.changed_at,
    u.email AS changed_by_email
   FROM (public.audit_log a
     LEFT JOIN auth.users u ON ((u.id = a.changed_by)))
  WHERE public.has_role(auth.uid(), 'admin'::public.app_role);


--
-- Name: v_hives; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_hives AS
 SELECT h.id,
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
        CASE
            WHEN public.has_role(auth.uid(), 'admin'::public.app_role) THEN h.price
            ELSE NULL::integer
        END AS price,
        CASE
            WHEN public.has_role(auth.uid(), 'admin'::public.app_role) THEN (h.hive_count * 1440)
            ELSE NULL::integer
        END AS base_revenue,
        CASE
            WHEN (h.start_date > CURRENT_DATE) THEN 'pending'::text
            WHEN (CURRENT_DATE >= (h.start_date + '3 years'::interval)) THEN 'renewal'::text
            ELSE 'active'::text
        END AS status,
    (EXTRACT(year FROM h.start_date))::integer AS start_year,
    h.created_at,
    h.updated_at
   FROM (public.hives h
     LEFT JOIN public.beekeepers b ON ((b.id = h.beekeeper_id)));


--
-- Data for Name: animations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.animations (id, hive_id, location_type, custom_address, animation_date, beekeeper_id, intervenant_name, comment, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, table_name, record_id, action, old_data, new_data, changed_by, changed_at) FROM stdin;
6f84e0b3-11b2-4c79-a6be-e14e184b2932	beekeepers	4a559211-90bf-4990-99fd-17a4f4e1e477	insert	\N	{"id": "4a559211-90bf-4990-99fd-17a4f4e1e477", "name": "Jean-Pierre Demailly", "user_id": null, "created_at": "2026-08-26T13:55:38.840735+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:55:38.840735+00
43f0b37f-d6db-4dd9-bbda-dd10d7a67a7b	beekeepers	653ae3b3-e496-4542-9229-f2a91ede6d16	insert	\N	{"id": "653ae3b3-e496-4542-9229-f2a91ede6d16", "name": "Nicolas Chardon", "user_id": null, "created_at": "2026-08-26T13:55:53.551284+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:55:53.551284+00
8c3ad5da-0bbc-4f2f-8193-e03a90e8ef01	beekeepers	b1bd66c6-cc99-4103-89a5-86710f4dd0d5	insert	\N	{"id": "b1bd66c6-cc99-4103-89a5-86710f4dd0d5", "name": "Lotfi Labidi", "user_id": null, "created_at": "2026-08-26T13:56:03.44819+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:56:03.44819+00
2a724636-16c1-4424-a272-10bf784013a3	beekeepers	98ed518e-3c3e-4d7f-910a-16a19eb35783	insert	\N	{"id": "98ed518e-3c3e-4d7f-910a-16a19eb35783", "name": "Stéphane Rique", "user_id": null, "created_at": "2026-08-26T13:56:11.750101+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:56:11.750101+00
9ec9fcab-7ca6-4959-9393-7ef469d5e2f2	beekeepers	16bb131f-3051-4dae-8f4f-0ad47a50e3bf	insert	\N	{"id": "16bb131f-3051-4dae-8f4f-0ad47a50e3bf", "name": "Marion Wierzbicki", "user_id": null, "created_at": "2026-08-26T13:56:28.161124+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:56:28.161124+00
b7acac03-0717-4608-807f-65c6f565c5dd	beekeepers	7bfd5dfe-416a-4575-9b97-edb404d114ef	insert	\N	{"id": "7bfd5dfe-416a-4575-9b97-edb404d114ef", "name": "Cédric Levannier", "user_id": null, "created_at": "2026-08-26T13:56:51.520963+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:56:51.520963+00
453f11be-bb23-400b-b0f6-5ad87116f08b	beekeepers	c533f95a-7604-4480-86cc-447f530b5b3c	insert	\N	{"id": "c533f95a-7604-4480-86cc-447f530b5b3c", "name": "Stéphane Gireme", "user_id": null, "created_at": "2026-08-26T13:56:58.854575+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:56:58.854575+00
79b85dc4-f10d-4b6c-ba60-011ffaa0d90c	beekeepers	251c898a-6daf-45df-bc80-4a85393ec3f3	insert	\N	{"id": "251c898a-6daf-45df-bc80-4a85393ec3f3", "name": "Stéphane Boussoualim", "user_id": null, "created_at": "2026-08-26T13:57:08.51918+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:57:08.51918+00
f73f70ec-1383-4b98-9329-3e448fc41b64	beekeepers	bc4a0c87-7b29-4b10-8967-e69e906ac069	insert	\N	{"id": "bc4a0c87-7b29-4b10-8967-e69e906ac069", "name": "Marc Reynol", "user_id": null, "created_at": "2026-08-26T13:57:30.636442+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:57:30.636442+00
a81fa455-d676-4911-bc2f-30aa0a73e7c8	beekeepers	f592c712-935c-4276-8491-6d7baf0f2922	insert	\N	{"id": "f592c712-935c-4276-8491-6d7baf0f2922", "name": "Christian Laroussie", "user_id": null, "created_at": "2026-08-26T13:57:40.729318+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:57:40.729318+00
79957027-2465-4af1-80f0-1f79d00432ec	beekeepers	60e16e1a-a0dc-4d5a-a2cd-88bebc597b2d	insert	\N	{"id": "60e16e1a-a0dc-4d5a-a2cd-88bebc597b2d", "name": "Samuel Jaffre", "user_id": null, "created_at": "2026-08-26T13:57:52.637654+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:57:52.637654+00
096ef1cf-7422-41c4-9b46-edba57db030c	beekeepers	c25bbd74-faeb-40a2-aa06-bdfef74b870a	insert	\N	{"id": "c25bbd74-faeb-40a2-aa06-bdfef74b870a", "name": "Michel Bertoni", "user_id": null, "created_at": "2026-08-26T13:57:59.713758+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:57:59.713758+00
17d8c727-78a9-40d9-991c-9a9ee4a807c5	beekeepers	9994060b-0b8f-45e9-b7a5-ac72ab5fda7c	insert	\N	{"id": "9994060b-0b8f-45e9-b7a5-ac72ab5fda7c", "name": "Christelle Lansard", "user_id": null, "created_at": "2026-08-26T13:58:08.280649+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:58:08.280649+00
6af04fc7-a27e-4602-9bfe-77490e1a6588	beekeepers	ed32415d-956e-42ec-ae5d-862f17d79136	insert	\N	{"id": "ed32415d-956e-42ec-ae5d-862f17d79136", "name": "Anthony Martin", "user_id": null, "created_at": "2026-08-26T13:58:17.680594+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:58:17.680594+00
c8cb693d-7359-4bcc-ab60-6958af4560db	beekeepers	3e040b42-f813-413c-8f0b-5cdfd4357e05	insert	\N	{"id": "3e040b42-f813-413c-8f0b-5cdfd4357e05", "name": "Dominique Alsberghe", "user_id": null, "created_at": "2026-08-26T13:58:36.090124+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:58:36.090124+00
4eaa86dd-aa2b-4dd5-94da-38d36f553145	beekeepers	01779d34-0c6c-4a2f-b9ca-c5c4ddef050b	insert	\N	{"id": "01779d34-0c6c-4a2f-b9ca-c5c4ddef050b", "name": "Laurence Legrand", "user_id": null, "created_at": "2026-08-26T13:58:45.244797+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:58:45.244797+00
e048d625-00d8-40d1-bf10-33a4fe442fd8	beekeepers	e36e91d5-b4cd-4450-8e20-b0f2b56b447e	insert	\N	{"id": "e36e91d5-b4cd-4450-8e20-b0f2b56b447e", "name": "Patrice Roche", "user_id": null, "created_at": "2026-08-26T13:58:51.121583+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:58:51.121583+00
5b0c6e20-1d45-471c-b2e7-4532ed7c3ca9	beekeepers	f3297aec-53a8-43f4-ab0e-7d7d10ef4295	insert	\N	{"id": "f3297aec-53a8-43f4-ab0e-7d7d10ef4295", "name": "Laurent Heckel", "user_id": null, "created_at": "2026-08-26T13:58:58.613081+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:58:58.613081+00
fa89c9d3-adb3-4007-b090-141609dc5ff1	beekeepers	f7e430f6-3333-4e80-9048-e0594c3926fb	insert	\N	{"id": "f7e430f6-3333-4e80-9048-e0594c3926fb", "name": "Jérôme Minot", "user_id": null, "created_at": "2026-08-26T13:59:08.073894+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:59:08.073894+00
9f07e2a0-491f-4410-ae3a-fe7fcd58de11	beekeepers	4e5310ae-149a-4ce6-b211-5cc26744a3e8	insert	\N	{"id": "4e5310ae-149a-4ce6-b211-5cc26744a3e8", "name": "Thierry Parmentier", "user_id": null, "created_at": "2026-08-26T13:59:16.167764+00:00"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 13:59:16.167764+00
ef8b4c1c-6033-47de-a584-93a34b3fbb07	hives	9e2963c0-a5aa-49e7-a6fb-e9f7be171a50	insert	\N	{"id": "9e2963c0-a5aa-49e7-a6fb-e9f7be171a50", "name": "Fareins", "site": "Fareins (01)", "price": 1440, "client": "Metagenics", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "friche", "created_at": "2026-08-26T14:06:41.267291+00:00", "created_by": "a7a0b9a8-fd4e-46ba-b254-f65194ef22cd", "hive_count": 1, "share_role": "", "start_date": "2026-08-26", "updated_at": "2026-08-26T14:06:41.267291+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": ""}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 14:06:41.267291+00
\.


--
-- Data for Name: beekeepers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.beekeepers (id, name, user_id, created_at) FROM stdin;
2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c	Dominique Parriaud	\N	2026-08-19 08:49:54.450287+00
4a559211-90bf-4990-99fd-17a4f4e1e477	Jean-Pierre Demailly	\N	2026-08-26 13:55:38.840735+00
653ae3b3-e496-4542-9229-f2a91ede6d16	Nicolas Chardon	\N	2026-08-26 13:55:53.551284+00
b1bd66c6-cc99-4103-89a5-86710f4dd0d5	Lotfi Labidi	\N	2026-08-26 13:56:03.44819+00
98ed518e-3c3e-4d7f-910a-16a19eb35783	Stéphane Rique	\N	2026-08-26 13:56:11.750101+00
16bb131f-3051-4dae-8f4f-0ad47a50e3bf	Marion Wierzbicki	\N	2026-08-26 13:56:28.161124+00
7bfd5dfe-416a-4575-9b97-edb404d114ef	Cédric Levannier	\N	2026-08-26 13:56:51.520963+00
c533f95a-7604-4480-86cc-447f530b5b3c	Stéphane Gireme	\N	2026-08-26 13:56:58.854575+00
251c898a-6daf-45df-bc80-4a85393ec3f3	Stéphane Boussoualim	\N	2026-08-26 13:57:08.51918+00
bc4a0c87-7b29-4b10-8967-e69e906ac069	Marc Reynol	\N	2026-08-26 13:57:30.636442+00
f592c712-935c-4276-8491-6d7baf0f2922	Christian Laroussie	\N	2026-08-26 13:57:40.729318+00
60e16e1a-a0dc-4d5a-a2cd-88bebc597b2d	Samuel Jaffre	\N	2026-08-26 13:57:52.637654+00
c25bbd74-faeb-40a2-aa06-bdfef74b870a	Michel Bertoni	\N	2026-08-26 13:57:59.713758+00
9994060b-0b8f-45e9-b7a5-ac72ab5fda7c	Christelle Lansard	\N	2026-08-26 13:58:08.280649+00
ed32415d-956e-42ec-ae5d-862f17d79136	Anthony Martin	\N	2026-08-26 13:58:17.680594+00
3e040b42-f813-413c-8f0b-5cdfd4357e05	Dominique Alsberghe	\N	2026-08-26 13:58:36.090124+00
01779d34-0c6c-4a2f-b9ca-c5c4ddef050b	Laurence Legrand	\N	2026-08-26 13:58:45.244797+00
e36e91d5-b4cd-4450-8e20-b0f2b56b447e	Patrice Roche	\N	2026-08-26 13:58:51.121583+00
f3297aec-53a8-43f4-ab0e-7d7d10ef4295	Laurent Heckel	\N	2026-08-26 13:58:58.613081+00
f7e430f6-3333-4e80-9048-e0594c3926fb	Jérôme Minot	\N	2026-08-26 13:59:08.073894+00
4e5310ae-149a-4ce6-b211-5cc26744a3e8	Thierry Parmentier	\N	2026-08-26 13:59:16.167764+00
\.


--
-- Data for Name: hive_visits; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.hive_visits (id, hive_id, beekeeper_id, visit_date, photo_path, note, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: hives; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.hives (id, name, client, site, region, start_date, hive_count, placement, placement_detail, share_role, host_hive_id, latitude, longitude, price, created_by, created_at, updated_at, beekeeper_id) FROM stdin;
9e2963c0-a5aa-49e7-a6fb-e9f7be171a50	Fareins	Metagenics	Fareins (01)	Auvergne-Rhône-Alpes	2026-08-26	1	friche			\N	\N	\N	1440	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 14:06:41.267291+00	2026-08-26 14:06:41.267291+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_roles (id, user_id, role, created_at) FROM stdin;
58f55db7-b945-43af-b05e-ce30594743f1	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	admin	2026-08-19 07:30:45.491504+00
d99b61da-1dc1-4c62-a384-c8332da4b79a	d5a8783c-de9f-41ac-bd4c-87691cd7c33d	admin	2026-08-24 09:34:58.619425+00
\.


--
-- Name: animations animations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animations
    ADD CONSTRAINT animations_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: beekeepers beekeepers_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beekeepers
    ADD CONSTRAINT beekeepers_name_key UNIQUE (name);


--
-- Name: beekeepers beekeepers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beekeepers
    ADD CONSTRAINT beekeepers_pkey PRIMARY KEY (id);


--
-- Name: hive_visits hive_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hive_visits
    ADD CONSTRAINT hive_visits_pkey PRIMARY KEY (id);


--
-- Name: hives hives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hives
    ADD CONSTRAINT hives_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_key UNIQUE (user_id, role);


--
-- Name: idx_animations_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_animations_date ON public.animations USING btree (animation_date);


--
-- Name: idx_animations_hive; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_animations_hive ON public.animations USING btree (hive_id);


--
-- Name: idx_audit_changed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_changed_at ON public.audit_log USING btree (changed_at DESC);


--
-- Name: idx_audit_table_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_table_record ON public.audit_log USING btree (table_name, record_id, changed_at DESC);


--
-- Name: idx_hives_beekeeper; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hives_beekeeper ON public.hives USING btree (beekeeper_id);


--
-- Name: idx_hives_host; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hives_host ON public.hives USING btree (host_hive_id);


--
-- Name: idx_hives_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hives_start_date ON public.hives USING btree (start_date);


--
-- Name: idx_visits_hive; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visits_hive ON public.hive_visits USING btree (hive_id, visit_date DESC);


--
-- Name: animations trg_audit_animations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_animations AFTER INSERT OR DELETE OR UPDATE ON public.animations FOR EACH ROW EXECUTE FUNCTION public.log_audit();


--
-- Name: beekeepers trg_audit_beekeepers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_beekeepers AFTER INSERT OR DELETE OR UPDATE ON public.beekeepers FOR EACH ROW EXECUTE FUNCTION public.log_audit();


--
-- Name: hive_visits trg_audit_hive_visits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_hive_visits AFTER INSERT OR DELETE OR UPDATE ON public.hive_visits FOR EACH ROW EXECUTE FUNCTION public.log_audit();


--
-- Name: hives trg_audit_hives; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_hives AFTER INSERT OR DELETE OR UPDATE ON public.hives FOR EACH ROW EXECUTE FUNCTION public.log_audit();


--
-- Name: user_roles trg_audit_user_roles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_user_roles AFTER INSERT OR DELETE OR UPDATE ON public.user_roles FOR EACH ROW EXECUTE FUNCTION public.log_audit();


--
-- Name: hives trg_hives_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_hives_updated_at BEFORE UPDATE ON public.hives FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: animations animations_beekeeper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animations
    ADD CONSTRAINT animations_beekeeper_id_fkey FOREIGN KEY (beekeeper_id) REFERENCES public.beekeepers(id);


--
-- Name: animations animations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animations
    ADD CONSTRAINT animations_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: animations animations_hive_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.animations
    ADD CONSTRAINT animations_hive_id_fkey FOREIGN KEY (hive_id) REFERENCES public.hives(id) ON DELETE CASCADE;


--
-- Name: audit_log audit_log_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES auth.users(id);


--
-- Name: beekeepers beekeepers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beekeepers
    ADD CONSTRAINT beekeepers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: hive_visits hive_visits_beekeeper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hive_visits
    ADD CONSTRAINT hive_visits_beekeeper_id_fkey FOREIGN KEY (beekeeper_id) REFERENCES public.beekeepers(id);


--
-- Name: hive_visits hive_visits_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hive_visits
    ADD CONSTRAINT hive_visits_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: hive_visits hive_visits_hive_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hive_visits
    ADD CONSTRAINT hive_visits_hive_id_fkey FOREIGN KEY (hive_id) REFERENCES public.hives(id) ON DELETE CASCADE;


--
-- Name: hives hives_beekeeper_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hives
    ADD CONSTRAINT hives_beekeeper_id_fkey FOREIGN KEY (beekeeper_id) REFERENCES public.beekeepers(id);


--
-- Name: hives hives_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hives
    ADD CONSTRAINT hives_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: hives hives_host_hive_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hives
    ADD CONSTRAINT hives_host_hive_id_fkey FOREIGN KEY (host_hive_id) REFERENCES public.hives(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_roles admins_read_all_roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY admins_read_all_roles ON public.user_roles FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: animations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.animations ENABLE ROW LEVEL SECURITY;

--
-- Name: animations animations_admin_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animations_admin_delete ON public.animations FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: animations animations_admin_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animations_admin_insert ON public.animations FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: animations animations_admin_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY animations_admin_select ON public.animations FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: audit_log audit_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY audit_admin_read ON public.audit_log FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: audit_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

--
-- Name: beekeepers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.beekeepers ENABLE ROW LEVEL SECURITY;

--
-- Name: beekeepers beekeepers_delete_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY beekeepers_delete_admin ON public.beekeepers FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: beekeepers beekeepers_insert_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY beekeepers_insert_admin ON public.beekeepers FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: beekeepers beekeepers_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY beekeepers_read_all ON public.beekeepers FOR SELECT TO authenticated USING (true);


--
-- Name: beekeepers beekeepers_update_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY beekeepers_update_admin ON public.beekeepers FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hive_visits; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hive_visits ENABLE ROW LEVEL SECURITY;

--
-- Name: hives; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hives ENABLE ROW LEVEL SECURITY;

--
-- Name: hives hives_delete_admin_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY hives_delete_admin_only ON public.hives FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hives hives_insert_admin_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY hives_insert_admin_only ON public.hives FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hives hives_read_admin_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY hives_read_admin_only ON public.hives FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hives hives_update_admin_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY hives_update_admin_only ON public.hives FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles own_roles_readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY own_roles_readable ON public.user_roles FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: user_roles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

--
-- Name: hive_visits visits_delete_admin_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY visits_delete_admin_only ON public.hive_visits FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hive_visits visits_insert_own_hive_or_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY visits_insert_own_hive_or_admin ON public.hive_visits FOR INSERT TO authenticated WITH CHECK ((public.has_role(auth.uid(), 'admin'::public.app_role) OR (EXISTS ( SELECT 1
   FROM (public.hives h
     JOIN public.beekeepers b ON ((b.id = h.beekeeper_id)))
  WHERE ((h.id = hive_visits.hive_id) AND (b.user_id = auth.uid()))))));


--
-- Name: hive_visits visits_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY visits_read_all ON public.hive_visits FOR SELECT TO authenticated USING (true);


--
-- PostgreSQL database dump complete
--

\unrestrict WXGL5GaDfMaOD4qSjQHsYTssgBwvwflj5ms9dCcdjmuMCkRZJKdTlYn6tk0iOEr

