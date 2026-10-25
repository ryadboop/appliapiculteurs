--
-- PostgreSQL database dump
--

\restrict cSAlEHZLAU5P8T5nW4zUyCRFWZRz6P00JaaQPbx6zbaKVF2l6wqNmiuvskivWBg

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
    visited_at timestamp with time zone DEFAULT now() NOT NULL,
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
0f8400b8-7d45-4a33-b8f3-7795d03c9e8d	hives	b7efb417-f146-4329-8e6d-4ddc64e202f7	insert	\N	{"id": "b7efb417-f146-4329-8e6d-4ddc64e202f7", "name": "ADELAC", "site": "74350", "price": null, "client": "ADELAC", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-09-23T10:15:51.309035+00:00", "created_by": "a7a0b9a8-fd4e-46ba-b254-f65194ef22cd", "hive_count": 4, "share_role": "", "start_date": "2024-11-30", "updated_at": "2026-09-23T10:15:51.309035+00:00", "beekeeper_id": null, "host_hive_id": null, "placement_detail": "P8 du tunnel du Mont Sion"}	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-09-23 10:15:51.309035+00
49de4daa-b383-425f-9a46-41f726785b36	user_roles	2a7f65df-b124-4532-9810-292e3954cc29	insert	\N	{"id": "2a7f65df-b124-4532-9810-292e3954cc29", "role": "admin", "user_id": "22775f65-ad5a-4033-b608-ed9f97b7b294", "created_at": "2026-10-19T12:13:18.441702+00:00"}	\N	2026-10-19 12:13:18.441702+00
ab2d6d62-aadf-4260-918d-ed10f3943b6b	hives	2ae2aba7-cb2a-449d-ba64-92f8b982b990	insert	\N	{"id": "2ae2aba7-cb2a-449d-ba64-92f8b982b990", "name": "BB partners", "site": "Fareins (01)", "price": null, "client": "BB partners", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "friche", "created_at": "2026-10-19T12:48:54.077549+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 2, "share_role": "", "start_date": "2026-06-26", "updated_at": "2026-10-19T12:48:54.077549+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": ""}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 12:48:54.077549+00
7be6391d-a7de-4b97-a3c0-4fc2fdde5838	hives	d16a8c18-4700-4583-a4a2-e52ccc88d9fe	insert	\N	{"id": "d16a8c18-4700-4583-a4a2-e52ccc88d9fe", "name": "Achaintre", "site": "ТАРОNAS", "price": 1050, "client": "Achaintre", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-19T13:01:45.230912+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2020-04-02", "updated_at": "2026-10-19T13:01:45.230912+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "149 route de Champagne 69220"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:01:45.230912+00
e13cba95-cab8-4c36-8e8c-5b768a960e48	hives	9e2963c0-a5aa-49e7-a6fb-e9f7be171a50	update	{"id": "9e2963c0-a5aa-49e7-a6fb-e9f7be171a50", "name": "Fareins", "site": "Fareins (01)", "price": 1440, "client": "Metagenics", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "friche", "created_at": "2026-08-26T14:06:41.267291+00:00", "created_by": "a7a0b9a8-fd4e-46ba-b254-f65194ef22cd", "hive_count": 1, "share_role": "", "start_date": "2026-08-26", "updated_at": "2026-08-26T14:06:41.267291+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": ""}	{"id": "9e2963c0-a5aa-49e7-a6fb-e9f7be171a50", "name": "Fareins", "site": "Fareins (01)", "price": 1440, "client": "Metagenics", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "friche", "created_at": "2026-08-26T14:06:41.267291+00:00", "created_by": "a7a0b9a8-fd4e-46ba-b254-f65194ef22cd", "hive_count": 1, "share_role": "", "start_date": "2026-08-26", "updated_at": "2026-10-19T13:21:57.296693+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": ""}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:21:57.296693+00
f69424b5-71fb-4281-afae-2d0470aa039f	hives	b7efb417-f146-4329-8e6d-4ddc64e202f7	update	{"id": "b7efb417-f146-4329-8e6d-4ddc64e202f7", "name": "ADELAC", "site": "74350", "price": null, "client": "ADELAC", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-09-23T10:15:51.309035+00:00", "created_by": "a7a0b9a8-fd4e-46ba-b254-f65194ef22cd", "hive_count": 4, "share_role": "", "start_date": "2024-11-30", "updated_at": "2026-09-23T10:15:51.309035+00:00", "beekeeper_id": null, "host_hive_id": null, "placement_detail": "P8 du tunnel du Mont Sion"}	{"id": "b7efb417-f146-4329-8e6d-4ddc64e202f7", "name": "ADELAC", "site": "74350", "price": 4200, "client": "ADELAC", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-09-23T10:15:51.309035+00:00", "created_by": "a7a0b9a8-fd4e-46ba-b254-f65194ef22cd", "hive_count": 4, "share_role": "", "start_date": "2024-11-30", "updated_at": "2026-10-19T13:24:58.872829+00:00", "beekeeper_id": null, "host_hive_id": null, "placement_detail": "P8 du tunnel du Mont Sion"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:24:58.872829+00
ff5d206c-3809-45c7-9668-e0243980f272	hives	57ff97eb-2ea9-46d3-9c84-aacc89b1a0d4	insert	\N	{"id": "57ff97eb-2ea9-46d3-9c84-aacc89b1a0d4", "name": "ACRT", "site": "69220 TAPONAS.", "price": 1050, "client": "ACRT", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-19T13:30:08.645185+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2020-02-27", "updated_at": "2026-10-19T13:30:08.645185+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "149 route de Champagne"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:30:08.645185+00
68851b10-c3e5-4720-aaf0-937709556d88	hives	11bac3fb-ac5b-4650-8f66-1a98978132e1	insert	\N	{"id": "11bac3fb-ac5b-4650-8f66-1a98978132e1", "name": "ADB DECORATION", "site": "69400 Gleizé", "price": 1100, "client": "ADB DECORATION", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-19T13:33:58.296317+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2021-03-26", "updated_at": "2026-10-19T13:33:58.296317+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "22 Rue de l'Ancienne Distillerie"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:33:58.296317+00
c7035cf6-3417-49a9-aed2-929cddc8d236	hives	366233dc-ed36-4725-8792-2257b1b0c017	insert	\N	{"id": "366233dc-ed36-4725-8792-2257b1b0c017", "name": "AFIGEC", "site": "14100 Lisieux", "price": 10150, "client": "AFIGEC", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-19T13:36:53.105457+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 4, "share_role": "", "start_date": "2021-06-07", "updated_at": "2026-10-19T13:36:53.105457+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "sis 51 boulevard Sainte-Anne"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:36:53.105457+00
57484665-b239-4186-8365-a05e022f412a	hives	fd599340-15b8-4f75-8792-e7866814d8d9	insert	\N	{"id": "fd599340-15b8-4f75-8792-e7866814d8d9", "name": "AI2B", "site": "69210 Fleurieux-sur-l'Arbresle.", "price": 3100, "client": "AI2B", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-19T13:39:49.683606+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 3, "share_role": "", "start_date": "2021-03-08", "updated_at": "2026-10-19T13:39:49.683606+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "105 rue de Montepy"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:39:49.683606+00
754f66a7-c9d7-493a-baef-1dcf13b506bb	hives	51b9d4d5-b07b-41e8-84a0-2b042687292c	insert	\N	{"id": "51b9d4d5-b07b-41e8-84a0-2b042687292c", "name": "ALPM", "site": "71 850 Charnay les Mâcon", "price": 1050, "client": "ALPM", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-19T14:08:39.458641+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2019-07-19", "updated_at": "2026-10-19T14:08:39.458641+00:00", "beekeeper_id": null, "host_hive_id": null, "placement_detail": "50 chemin du Bois d'Alier"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 14:08:39.458641+00
f33db462-27f1-4c66-9c41-ad08486d2bc2	hives	87cd058c-ca7a-4e7b-8e4f-88d071f6a022	insert	\N	{"id": "87cd058c-ca7a-4e7b-8e4f-88d071f6a022", "name": "AUTOMATISME INDUSTRIE", "site": "02110 Fresnoy-le-Grand", "price": 1050, "client": "AUTOMATISME INDUSTRIE", "region": "Grand Est", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-19T14:46:44.357605+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2018-05-22", "updated_at": "2026-10-19T14:46:44.357605+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "294 Rue Jean Baptiste Charlet"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 14:46:44.357605+00
e1db8fa2-e5e3-4cb5-8907-a1f8a233bf91	hives	0405b4fe-4f75-44a6-8d6b-c734d3f43095	insert	\N	{"id": "0405b4fe-4f75-44a6-8d6b-c734d3f43095", "name": "AVIZEO", "site": "Fareins (01)", "price": 1050, "client": "AVIZEO", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "friche", "created_at": "2026-10-19T14:51:44.003314+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2020-04-23", "updated_at": "2026-10-19T14:51:44.003314+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": ""}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 14:51:44.003314+00
e9e9b7d7-b2d3-496c-919a-17698bdf7c23	hives	c42c08df-026a-4572-a773-bb6d93b8b4ee	insert	\N	{"id": "c42c08df-026a-4572-a773-bb6d93b8b4ee", "name": "BALAS", "site": "69490 Saint-Romain-de-Popey", "price": 1150, "client": "BALAS", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-19T15:03:08.275057+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2022-08-01", "updated_at": "2026-10-19T15:03:08.275057+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "1 Imp. du Pré Rond"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 15:03:08.275057+00
820d9ffa-92e5-4973-bac4-fede13c3edd7	hives	9499f654-5791-4ea1-ad76-10392a85c7ac	insert	\N	{"id": "9499f654-5791-4ea1-ad76-10392a85c7ac", "name": "BARLERIN", "site": "69490 Saint-Romain-de-Popey", "price": 1150, "client": "BARLERIN", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T07:33:06.90149+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2022-07-01", "updated_at": "2026-10-20T07:33:06.90149+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "1 Imp. du Pré Rond"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 07:33:06.90149+00
e027fc5f-b8ba-403d-ba3a-0181de34de4c	hives	0e6f5d64-a768-43cd-b431-d82e2b42237a	insert	\N	{"id": "0e6f5d64-a768-43cd-b431-d82e2b42237a", "name": "ATTILA (ORICAMI)", "site": "69400 Limas", "price": 1050, "client": "ATTILA (ORICAMI)", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T07:37:37.750153+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2020-07-06", "updated_at": "2026-10-20T07:37:37.750153+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "94 Allée de Riottier"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 07:37:37.750153+00
0472f60b-c4ff-4ea7-9191-2db42539c8a9	hives	1082ac24-289b-472e-b00c-7d2c1ce852b4	insert	\N	{"id": "1082ac24-289b-472e-b00c-7d2c1ce852b4", "name": "BIOPROTEC", "site": "69800 Saint Priest", "price": 1000, "client": "BIOPROTEC", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T07:42:52.102511+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2019-03-20", "updated_at": "2026-10-20T07:42:52.102511+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "sis 160 cours 3ème Millenaire"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 07:42:52.102511+00
ec018c9f-50bc-446b-b627-aa1ea0526adb	hives	58f71c80-d690-4351-8a82-02fcc478b65a	insert	\N	{"id": "58f71c80-d690-4351-8a82-02fcc478b65a", "name": "Capital Culturel Européen (CCE)", "site": "71 850 Charnay les Mâcon,", "price": 1050, "client": "Capital Culturel Européen (CCE)", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T07:56:46.059393+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2019-07-23", "updated_at": "2026-10-20T07:56:46.059393+00:00", "beekeeper_id": null, "host_hive_id": null, "placement_detail": "50 chemin du Bois d'Alier"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 07:56:46.059393+00
9961b46f-d486-4a55-b66d-ccd371b212f3	hives	56e27886-ff70-472d-aba1-39e614f3e4b2	insert	\N	{"id": "56e27886-ff70-472d-aba1-39e614f3e4b2", "name": "CNSE", "site": "69220 Taponas", "price": 1150, "client": "CNSE", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:04:27.809579+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2021-06-15", "updated_at": "2026-10-20T08:04:27.809579+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "34 route de Champagne"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:04:27.809579+00
68a27b90-043b-4687-aa3a-5b8a247e59ef	hives	7f2f68c7-36f0-4413-8820-9c5e031e93cf	insert	\N	{"id": "7f2f68c7-36f0-4413-8820-9c5e031e93cf", "name": "COHESIONS STRATEGIQUES", "site": "02500 HIRSON", "price": 1050, "client": "COHESIONS STRATEGIQUES", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:07:56.448498+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2015-05-11", "updated_at": "2026-10-20T08:07:56.448498+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "ZI La Rotonde"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:07:56.448498+00
5c16a277-4e79-4d7b-b03f-1fa6765c5ccf	hives	dd9b37cc-3a70-4aab-9cc9-6a39d3f43759	insert	\N	{"id": "dd9b37cc-3a70-4aab-9cc9-6a39d3f43759", "name": "CROECRA - CONSEIL DE L'ORDRE DES EXPERTS COMPTABLES RA", "site": "69451 LYON", "price": 2100, "client": "CROECRA - CONSEIL DE L'ORDRE DES EXPERTS COMPTABLES RA", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:13:09.4305+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 2, "share_role": "", "start_date": "2018-02-15", "updated_at": "2026-10-20T08:13:09.4305+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "51 Rue Montgolfier"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:13:09.4305+00
45bda90d-67c9-40c2-bc75-129662dc4844	hives	ee4ab536-d6a6-4299-b868-6c0ba0517801	insert	\N	{"id": "ee4ab536-d6a6-4299-b868-6c0ba0517801", "name": "CRMN", "site": "69822 BELLEVILLE", "price": 1050, "client": "CRMN", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:22:56.070139+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2020-01-17", "updated_at": "2026-10-20T08:22:56.070139+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "45, rue Pasteur -"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:22:56.070139+00
e6f29c5e-5a79-40d1-94ac-08e05f1489b1	hives	fbf957d6-e73a-4c8a-92fb-2102ce2ef2e1	insert	\N	{"id": "fbf957d6-e73a-4c8a-92fb-2102ce2ef2e1", "name": "LE BOURGET", "site": "02230 FRESNOY-LE-GRAND", "price": 1050, "client": "LE BOURGET", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:25:52.86653+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2018-05-03", "updated_at": "2026-10-20T08:25:52.86653+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "68 rue Henri Matisse"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:25:52.86653+00
5ec67df3-5dc5-4e06-bab1-9c4107ab4ab6	hives	039a8375-3521-4d6e-b686-7a1bda7354b1	insert	\N	{"id": "039a8375-3521-4d6e-b686-7a1bda7354b1", "name": "DECATHLON", "site": "38070 Saint-Quentin-Fallavier", "price": 4200, "client": "DECATHLON", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:29:11.842294+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 4, "share_role": "", "start_date": "2015-07-21", "updated_at": "2026-10-20T08:29:11.842294+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "210 D1006"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:29:11.842294+00
07cc8459-b28e-4259-aab4-371ad86b31a8	hives	7e8f5fd4-2c84-4807-bd2c-0c9845943f5a	insert	\N	{"id": "7e8f5fd4-2c84-4807-bd2c-0c9845943f5a", "name": "DESSENNE", "site": "59258 Les Rues-des-Vignes", "price": 1050, "client": "DESSENNE", "region": "Grand Est", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:32:17.136578+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2016-05-19", "updated_at": "2026-10-20T08:32:17.136578+00:00", "beekeeper_id": null, "host_hive_id": null, "placement_detail": "Abbaye de Vaucelles - Ham. de Vaucelles"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:32:17.136578+00
5758d6d9-f8bf-4e7d-82c6-5a3e3b0e3647	hives	c46cfb8b-583c-4675-94f2-9d0ff51d77d7	insert	\N	{"id": "c46cfb8b-583c-4675-94f2-9d0ff51d77d7", "name": "DGC Fret", "site": "69 730 Genay", "price": 2100, "client": "DGC Fret", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:34:07.792312+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 2, "share_role": "", "start_date": "2020-03-11", "updated_at": "2026-10-20T08:34:07.792312+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "Passage Emile Guimet, rue Jacquart"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:34:07.792312+00
0ed08b21-2a98-4db8-9702-217b27a0a7b4	hives	09f59784-0a46-4a4c-972a-4e7729c4ac0c	insert	\N	{"id": "09f59784-0a46-4a4c-972a-4e7729c4ac0c", "name": "DOUBLE TREE by HILTON", "site": "69800 Saint Priest", "price": 1050, "client": "DOUBLE TREE by HILTON", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:36:08.66917+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2019-03-20", "updated_at": "2026-10-20T08:36:08.66917+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "160 cours 3ème Millénaire"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:36:08.66917+00
1cc63549-832c-440e-8912-a042f30429de	hives	d479c997-d1a9-4523-9cbe-c13c8a30d535	insert	\N	{"id": "d479c997-d1a9-4523-9cbe-c13c8a30d535", "name": "DUMONT CLEAN SERVICES", "site": "38440 Saint-Jean-de-Bournay", "price": 1050, "client": "DUMONT CLEAN SERVICES", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:44:54.186588+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2020-11-12", "updated_at": "2026-10-20T08:44:54.186588+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "311 Rue des Écharrières"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:44:54.186588+00
b2d4ebda-d600-4eee-879a-f54d05706782	hives	89b54a00-dac7-4753-8301-73f5891d287b	insert	\N	{"id": "89b54a00-dac7-4753-8301-73f5891d287b", "name": "DYNAMIC RH", "site": "69007 Lyon", "price": 1050, "client": "DYNAMIC RH", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:47:29.830871+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2019-03-29", "updated_at": "2026-10-20T08:47:29.830871+00:00", "beekeeper_id": null, "host_hive_id": null, "placement_detail": "\\"ruche est installée sur un rucher partagé à proximité du site du client.\\""}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:47:29.830871+00
080c79b1-b935-43b1-bbd3-801ea00e231d	hives	41e07f5a-2b26-464f-8f84-ff3090d47f7d	insert	\N	{"id": "41e07f5a-2b26-464f-8f84-ff3090d47f7d", "name": "L'ECOLE des GRANDS", "site": "69220 ТАPONAS.", "price": 1050, "client": "L'ECOLE des GRANDS", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:53:59.249936+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 1, "share_role": "", "start_date": "2020-03-11", "updated_at": "2026-10-20T08:53:59.249936+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "149 route de Champagne"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:53:59.249936+00
d932a43f-2c1a-4bcb-a13a-2edec03beabc	hives	b3e4cd2e-5337-40b8-bede-6e4acf34d8ff	insert	\N	{"id": "b3e4cd2e-5337-40b8-bede-6e4acf34d8ff", "name": "EKLYA", "site": "69130 ECULLY", "price": 3450, "client": "EKLYA", "region": "Auvergne-Rhône-Alpes", "latitude": null, "longitude": null, "placement": "site", "created_at": "2026-10-20T08:55:48.242499+00:00", "created_by": "22775f65-ad5a-4033-b608-ed9f97b7b294", "hive_count": 3, "share_role": "", "start_date": "2023-05-17", "updated_at": "2026-10-20T08:55:48.242499+00:00", "beekeeper_id": "2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c", "host_hive_id": null, "placement_detail": "11 chemin du petit bois"}	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:55:48.242499+00
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

COPY public.hive_visits (id, hive_id, beekeeper_id, visited_at, photo_path, note, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: hives; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.hives (id, name, client, site, region, start_date, hive_count, placement, placement_detail, share_role, host_hive_id, latitude, longitude, price, created_by, created_at, updated_at, beekeeper_id) FROM stdin;
2ae2aba7-cb2a-449d-ba64-92f8b982b990	BB partners	BB partners	Fareins (01)	Auvergne-Rhône-Alpes	2026-06-26	2	friche			\N	\N	\N	\N	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 12:48:54.077549+00	2026-10-19 12:48:54.077549+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
d16a8c18-4700-4583-a4a2-e52ccc88d9fe	Achaintre	Achaintre	ТАРОNAS	Auvergne-Rhône-Alpes	2020-04-02	1	site	149 route de Champagne 69220		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:01:45.230912+00	2026-10-19 13:01:45.230912+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
9e2963c0-a5aa-49e7-a6fb-e9f7be171a50	Fareins	Metagenics	Fareins (01)	Auvergne-Rhône-Alpes	2026-08-26	1	friche			\N	\N	\N	1440	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-08-26 14:06:41.267291+00	2026-10-19 13:21:57.296693+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
b7efb417-f146-4329-8e6d-4ddc64e202f7	ADELAC	ADELAC	74350	Auvergne-Rhône-Alpes	2024-11-30	4	site	P8 du tunnel du Mont Sion		\N	\N	\N	4200	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	2026-09-23 10:15:51.309035+00	2026-10-19 13:24:58.872829+00	\N
57ff97eb-2ea9-46d3-9c84-aacc89b1a0d4	ACRT	ACRT	69220 TAPONAS.	Auvergne-Rhône-Alpes	2020-02-27	1	site	149 route de Champagne		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:30:08.645185+00	2026-10-19 13:30:08.645185+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
11bac3fb-ac5b-4650-8f66-1a98978132e1	ADB DECORATION	ADB DECORATION	69400 Gleizé	Auvergne-Rhône-Alpes	2021-03-26	1	site	22 Rue de l'Ancienne Distillerie		\N	\N	\N	1100	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:33:58.296317+00	2026-10-19 13:33:58.296317+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
366233dc-ed36-4725-8792-2257b1b0c017	AFIGEC	AFIGEC	14100 Lisieux	Auvergne-Rhône-Alpes	2021-06-07	4	site	sis 51 boulevard Sainte-Anne		\N	\N	\N	10150	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:36:53.105457+00	2026-10-19 13:36:53.105457+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
fd599340-15b8-4f75-8792-e7866814d8d9	AI2B	AI2B	69210 Fleurieux-sur-l'Arbresle.	Auvergne-Rhône-Alpes	2021-03-08	3	site	105 rue de Montepy		\N	\N	\N	3100	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 13:39:49.683606+00	2026-10-19 13:39:49.683606+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
51b9d4d5-b07b-41e8-84a0-2b042687292c	ALPM	ALPM	71 850 Charnay les Mâcon	Auvergne-Rhône-Alpes	2019-07-19	1	site	50 chemin du Bois d'Alier		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 14:08:39.458641+00	2026-10-19 14:08:39.458641+00	\N
87cd058c-ca7a-4e7b-8e4f-88d071f6a022	AUTOMATISME INDUSTRIE	AUTOMATISME INDUSTRIE	02110 Fresnoy-le-Grand	Grand Est	2018-05-22	1	site	294 Rue Jean Baptiste Charlet		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 14:46:44.357605+00	2026-10-19 14:46:44.357605+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
0405b4fe-4f75-44a6-8d6b-c734d3f43095	AVIZEO	AVIZEO	Fareins (01)	Auvergne-Rhône-Alpes	2020-04-23	1	friche			\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 14:51:44.003314+00	2026-10-19 14:51:44.003314+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
c42c08df-026a-4572-a773-bb6d93b8b4ee	BALAS	BALAS	69490 Saint-Romain-de-Popey	Auvergne-Rhône-Alpes	2022-08-01	1	site	1 Imp. du Pré Rond		\N	\N	\N	1150	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-19 15:03:08.275057+00	2026-10-19 15:03:08.275057+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
9499f654-5791-4ea1-ad76-10392a85c7ac	BARLERIN	BARLERIN	69490 Saint-Romain-de-Popey	Auvergne-Rhône-Alpes	2022-07-01	1	site	1 Imp. du Pré Rond		\N	\N	\N	1150	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 07:33:06.90149+00	2026-10-20 07:33:06.90149+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
0e6f5d64-a768-43cd-b431-d82e2b42237a	ATTILA (ORICAMI)	ATTILA (ORICAMI)	69400 Limas	Auvergne-Rhône-Alpes	2020-07-06	1	site	94 Allée de Riottier		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 07:37:37.750153+00	2026-10-20 07:37:37.750153+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
1082ac24-289b-472e-b00c-7d2c1ce852b4	BIOPROTEC	BIOPROTEC	69800 Saint Priest	Auvergne-Rhône-Alpes	2019-03-20	1	site	sis 160 cours 3ème Millenaire		\N	\N	\N	1000	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 07:42:52.102511+00	2026-10-20 07:42:52.102511+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
58f71c80-d690-4351-8a82-02fcc478b65a	Capital Culturel Européen (CCE)	Capital Culturel Européen (CCE)	71 850 Charnay les Mâcon,	Auvergne-Rhône-Alpes	2019-07-23	1	site	50 chemin du Bois d'Alier		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 07:56:46.059393+00	2026-10-20 07:56:46.059393+00	\N
56e27886-ff70-472d-aba1-39e614f3e4b2	CNSE	CNSE	69220 Taponas	Auvergne-Rhône-Alpes	2021-06-15	1	site	34 route de Champagne		\N	\N	\N	1150	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:04:27.809579+00	2026-10-20 08:04:27.809579+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
7f2f68c7-36f0-4413-8820-9c5e031e93cf	COHESIONS STRATEGIQUES	COHESIONS STRATEGIQUES	02500 HIRSON	Auvergne-Rhône-Alpes	2015-05-11	1	site	ZI La Rotonde		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:07:56.448498+00	2026-10-20 08:07:56.448498+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
dd9b37cc-3a70-4aab-9cc9-6a39d3f43759	CROECRA - CONSEIL DE L'ORDRE DES EXPERTS COMPTABLES RA	CROECRA - CONSEIL DE L'ORDRE DES EXPERTS COMPTABLES RA	69451 LYON	Auvergne-Rhône-Alpes	2018-02-15	2	site	51 Rue Montgolfier		\N	\N	\N	2100	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:13:09.4305+00	2026-10-20 08:13:09.4305+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
ee4ab536-d6a6-4299-b868-6c0ba0517801	CRMN	CRMN	69822 BELLEVILLE	Auvergne-Rhône-Alpes	2020-01-17	1	site	45, rue Pasteur -		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:22:56.070139+00	2026-10-20 08:22:56.070139+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
fbf957d6-e73a-4c8a-92fb-2102ce2ef2e1	LE BOURGET	LE BOURGET	02230 FRESNOY-LE-GRAND	Auvergne-Rhône-Alpes	2018-05-03	1	site	68 rue Henri Matisse		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:25:52.86653+00	2026-10-20 08:25:52.86653+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
039a8375-3521-4d6e-b686-7a1bda7354b1	DECATHLON	DECATHLON	38070 Saint-Quentin-Fallavier	Auvergne-Rhône-Alpes	2015-07-21	4	site	210 D1006		\N	\N	\N	4200	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:29:11.842294+00	2026-10-20 08:29:11.842294+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
7e8f5fd4-2c84-4807-bd2c-0c9845943f5a	DESSENNE	DESSENNE	59258 Les Rues-des-Vignes	Grand Est	2016-05-19	1	site	Abbaye de Vaucelles - Ham. de Vaucelles		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:32:17.136578+00	2026-10-20 08:32:17.136578+00	\N
c46cfb8b-583c-4675-94f2-9d0ff51d77d7	DGC Fret	DGC Fret	69 730 Genay	Auvergne-Rhône-Alpes	2020-03-11	2	site	Passage Emile Guimet, rue Jacquart		\N	\N	\N	2100	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:34:07.792312+00	2026-10-20 08:34:07.792312+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
09f59784-0a46-4a4c-972a-4e7729c4ac0c	DOUBLE TREE by HILTON	DOUBLE TREE by HILTON	69800 Saint Priest	Auvergne-Rhône-Alpes	2019-03-20	1	site	160 cours 3ème Millénaire		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:36:08.66917+00	2026-10-20 08:36:08.66917+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
d479c997-d1a9-4523-9cbe-c13c8a30d535	DUMONT CLEAN SERVICES	DUMONT CLEAN SERVICES	38440 Saint-Jean-de-Bournay	Auvergne-Rhône-Alpes	2020-11-12	1	site	311 Rue des Écharrières		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:44:54.186588+00	2026-10-20 08:44:54.186588+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
89b54a00-dac7-4753-8301-73f5891d287b	DYNAMIC RH	DYNAMIC RH	69007 Lyon	Auvergne-Rhône-Alpes	2019-03-29	1	site	"ruche est installée sur un rucher partagé à proximité du site du client."		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:47:29.830871+00	2026-10-20 08:47:29.830871+00	\N
41e07f5a-2b26-464f-8f84-ff3090d47f7d	L'ECOLE des GRANDS	L'ECOLE des GRANDS	69220 ТАPONAS.	Auvergne-Rhône-Alpes	2020-03-11	1	site	149 route de Champagne		\N	\N	\N	1050	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:53:59.249936+00	2026-10-20 08:53:59.249936+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
b3e4cd2e-5337-40b8-bede-6e4acf34d8ff	EKLYA	EKLYA	69130 ECULLY	Auvergne-Rhône-Alpes	2023-05-17	3	site	11 chemin du petit bois		\N	\N	\N	3450	22775f65-ad5a-4033-b608-ed9f97b7b294	2026-10-20 08:55:48.242499+00	2026-10-20 08:55:48.242499+00	2cf1bb2e-a783-4e10-b936-2cba9ce3fd6c
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_roles (id, user_id, role, created_at) FROM stdin;
58f55db7-b945-43af-b05e-ce30594743f1	a7a0b9a8-fd4e-46ba-b254-f65194ef22cd	admin	2026-08-19 07:30:45.491504+00
d99b61da-1dc1-4c62-a384-c8332da4b79a	d5a8783c-de9f-41ac-bd4c-87691cd7c33d	admin	2026-08-24 09:34:58.619425+00
2a7f65df-b124-4532-9810-292e3954cc29	22775f65-ad5a-4033-b608-ed9f97b7b294	admin	2026-10-19 12:13:18.441702+00
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

CREATE INDEX idx_visits_hive ON public.hive_visits USING btree (hive_id, visited_at DESC);


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

\unrestrict cSAlEHZLAU5P8T5nW4zUyCRFWZRz6P00JaaQPbx6zbaKVF2l6wqNmiuvskivWBg

