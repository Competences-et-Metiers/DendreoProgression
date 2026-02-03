--
-- PostgreSQL database dump
--

\restrict wasvXAh5VhzXs2x23vlA7mA25lXFApg3PCOz0LSECaOlU3SA77tS1hRLVPeNoDP

-- Dumped from database version 15.15 (Debian 15.15-1.pgdg13+1)
-- Dumped by pg_dump version 15.15 (Debian 15.15-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: courses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.courses (
    id integer NOT NULL,
    id_action_formation character varying,
    id_lam character varying,
    intitule character varying,
    status character varying,
    total_modules integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    planned_duration_hours double precision DEFAULT 0.0
);


ALTER TABLE public.courses OWNER TO postgres;

--
-- Name: COLUMN courses.planned_duration_hours; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.courses.planned_duration_hours IS 'Planned duration in hours from duree_heures field in Dendreo API';


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.courses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.courses_id_seq OWNER TO postgres;

--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.courses_id_seq OWNED BY public.courses.id;


--
-- Name: modules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modules (
    id integer NOT NULL,
    id_lmp character varying,
    id_lam character varying,
    intitule character varying,
    course_id integer,
    participant_id integer NOT NULL,
    lms_progression double precision DEFAULT 0.0,
    lms_last_access_at timestamp with time zone,
    mode_organisation character varying(50) DEFAULT 'elearning_async'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    lms_time_spent integer DEFAULT 0,
    lms_started_at timestamp with time zone,
    lms_completed_at timestamp with time zone
);


ALTER TABLE public.modules OWNER TO postgres;

--
-- Name: COLUMN modules.lms_time_spent; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.modules.lms_time_spent IS 'Time spent in seconds by participant on this module';


--
-- Name: COLUMN modules.lms_started_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.modules.lms_started_at IS 'Timestamp when participant started this module';


--
-- Name: COLUMN modules.lms_completed_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.modules.lms_completed_at IS 'Timestamp when participant completed this module';


--
-- Name: modules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.modules_id_seq OWNER TO postgres;

--
-- Name: modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modules_id_seq OWNED BY public.modules.id;


--
-- Name: participant_courses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.participant_courses (
    id integer NOT NULL,
    participant_id integer,
    course_id integer,
    id_lap character varying,
    overall_progression double precision DEFAULT 0.0,
    activity_status character varying(20) DEFAULT 'inactive'::character varying,
    last_activity timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.participant_courses OWNER TO postgres;

--
-- Name: participant_courses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.participant_courses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.participant_courses_id_seq OWNER TO postgres;

--
-- Name: participant_courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.participant_courses_id_seq OWNED BY public.participant_courses.id;


--
-- Name: participant_hubspot_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.participant_hubspot_data (
    id integer NOT NULL,
    participant_id integer NOT NULL,
    id_action_formation character varying NOT NULL,
    id_lap character varying,
    c_url_transaction_hubspot character varying,
    c_id_transaction_hubspot character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.participant_hubspot_data OWNER TO postgres;

--
-- Name: participant_hubspot_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.participant_hubspot_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.participant_hubspot_data_id_seq OWNER TO postgres;

--
-- Name: participant_hubspot_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.participant_hubspot_data_id_seq OWNED BY public.participant_hubspot_data.id;


--
-- Name: participants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.participants (
    id integer NOT NULL,
    id_participant character varying,
    nom character varying,
    prenom character varying,
    email character varying,
    id_entreprise character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.participants OWNER TO postgres;

--
-- Name: participants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.participants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.participants_id_seq OWNER TO postgres;

--
-- Name: participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.participants_id_seq OWNED BY public.participants.id;


--
-- Name: sync_metadata; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sync_metadata (
    id integer NOT NULL,
    sync_type character varying NOT NULL,
    last_sync_at timestamp with time zone NOT NULL,
    status character varying NOT NULL,
    stats text,
    error_message text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.sync_metadata OWNER TO postgres;

--
-- Name: sync_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sync_metadata_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sync_metadata_id_seq OWNER TO postgres;

--
-- Name: sync_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sync_metadata_id_seq OWNED BY public.sync_metadata.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses ALTER COLUMN id SET DEFAULT nextval('public.courses_id_seq'::regclass);


--
-- Name: modules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules ALTER COLUMN id SET DEFAULT nextval('public.modules_id_seq'::regclass);


--
-- Name: participant_courses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participant_courses ALTER COLUMN id SET DEFAULT nextval('public.participant_courses_id_seq'::regclass);


--
-- Name: participant_hubspot_data id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participant_hubspot_data ALTER COLUMN id SET DEFAULT nextval('public.participant_hubspot_data_id_seq'::regclass);


--
-- Name: participants id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participants ALTER COLUMN id SET DEFAULT nextval('public.participants_id_seq'::regclass);


--
-- Name: sync_metadata id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sync_metadata ALTER COLUMN id SET DEFAULT nextval('public.sync_metadata_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.courses (id, id_action_formation, id_lam, intitule, status, total_modules, created_at, updated_at, planned_duration_hours) FROM stdin;
1	115	2285	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802835+01	2026-02-03 15:40:07.802838+01	0
2	115	2283	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.80284+01	2026-02-03 15:40:07.802841+01	0
3	115	2281	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802842+01	2026-02-03 15:40:07.802842+01	0
4	115	2282	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802843+01	2026-02-03 15:40:07.802844+01	0
5	115	2284	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802844+01	2026-02-03 15:40:07.802845+01	0
6	115	2286	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802845+01	2026-02-03 15:40:07.802846+01	0
7	119	195	Prise de parole en public : devenir un bon orateur (MARS - AOUT 2025)	6	0	2026-02-03 15:40:07.802846+01	2026-02-03 15:40:07.802847+01	0
8	119	196	Prise de parole en public : devenir un bon orateur (MARS - AOUT 2025)	6	0	2026-02-03 15:40:07.802848+01	2026-02-03 15:40:07.802848+01	0
9	119	197	Prise de parole en public : devenir un bon orateur (MARS - AOUT 2025)	6	0	2026-02-03 15:40:07.802849+01	2026-02-03 15:40:07.80285+01	0
10	124	204	Bilan de compétences - Démo	5	0	2026-02-03 15:40:07.80285+01	2026-02-03 15:40:07.802851+01	0
11	134	216	Bilan de compétences (6h) - DEFILS Valérie	6	0	2026-02-03 15:40:07.802851+01	2026-02-03 15:40:07.802852+01	0
12	140	237	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802852+01	2026-02-03 15:40:07.802853+01	0
13	140	238	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802853+01	2026-02-03 15:40:07.802854+01	0
14	140	239	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802854+01	2026-02-03 15:40:07.802855+01	0
15	140	240	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802855+01	2026-02-03 15:40:07.802856+01	0
16	140	241	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802856+01	2026-02-03 15:40:07.802857+01	0
17	140	443	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802857+01	2026-02-03 15:40:07.802858+01	0
18	140	242	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802858+01	2026-02-03 15:40:07.802859+01	0
19	140	243	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802859+01	2026-02-03 15:40:07.80286+01	0
20	140	244	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.80286+01	2026-02-03 15:40:07.802861+01	0
21	140	245	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802861+01	2026-02-03 15:40:07.802862+01	0
22	140	2357	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802862+01	2026-02-03 15:40:07.802863+01	0
23	140	1008	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802863+01	2026-02-03 15:40:07.802864+01	0
24	167	325	Bilan de compétences (10h)	6	0	2026-02-03 15:40:07.802864+01	2026-02-03 15:40:07.802865+01	0
25	168	326	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.802865+01	2026-02-03 15:40:07.802866+01	0
26	175	333	Management	6	0	2026-02-03 15:40:07.802866+01	2026-02-03 15:40:07.802867+01	0
27	175	558	Management	6	0	2026-02-03 15:40:07.802868+01	2026-02-03 15:40:07.802868+01	0
28	175	559	Management	6	0	2026-02-03 15:40:07.802869+01	2026-02-03 15:40:07.802869+01	0
29	175	560	Management	6	0	2026-02-03 15:40:07.802869+01	2026-02-03 15:40:07.80287+01	0
30	176	1605	[TP SC] Secrétaire Comptable	6	0	2026-02-03 15:40:07.80287+01	2026-02-03 15:40:07.802871+01	0
31	176	1606	[TP SC] Secrétaire Comptable	6	0	2026-02-03 15:40:07.802871+01	2026-02-03 15:40:07.802872+01	0
32	193	351	Bilan de compétences (10h)	6	0	2026-02-03 15:40:07.813698+01	2026-02-03 15:40:07.813701+01	0
33	194	1455	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.813702+01	2026-02-03 15:40:07.813702+01	0
34	194	1456	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.813703+01	2026-02-03 15:40:07.813703+01	0
35	210	369	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.813704+01	2026-02-03 15:40:07.813704+01	0
36	218	377	Bilan de compétences (12h)	6	0	2026-02-03 15:40:07.813705+01	2026-02-03 15:40:07.813705+01	0
37	221	380	Bilan de compétences (12h)	6	0	2026-02-03 15:40:07.813706+01	2026-02-03 15:40:07.813707+01	0
38	225	384	Bilan de compétences (6h)	6	0	2026-02-03 15:40:07.813707+01	2026-02-03 15:40:07.813708+01	0
39	226	1358	Espagnol (Catherine MOGNOLLE)	6	0	2026-02-03 15:40:07.813708+01	2026-02-03 15:40:07.813709+01	0
40	226	1359	Espagnol (Catherine MOGNOLLE)	6	0	2026-02-03 15:40:07.813709+01	2026-02-03 15:40:07.81371+01	0
41	233	444	Bilan de compétences (12h) - LEGASTELOIS Marine	6	0	2026-02-03 15:40:07.81371+01	2026-02-03 15:40:07.813711+01	0
42	237	1457	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.813711+01	2026-02-03 15:40:07.813712+01	0
43	237	1458	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.813712+01	2026-02-03 15:40:07.813713+01	0
44	242	455	Bilan de compétences (12h)	6	0	2026-02-03 15:40:07.813714+01	2026-02-03 15:40:07.813714+01	0
45	248	502	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831661+01	2026-02-03 15:40:07.831665+01	0
46	248	503	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831666+01	2026-02-03 15:40:07.831666+01	0
47	248	504	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831667+01	2026-02-03 15:40:07.831667+01	0
48	248	505	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831668+01	2026-02-03 15:40:07.831668+01	0
49	248	506	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831669+01	2026-02-03 15:40:07.831669+01	0
50	248	507	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.83167+01	2026-02-03 15:40:07.83167+01	0
51	248	508	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831671+01	2026-02-03 15:40:07.831671+01	0
52	248	509	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831672+01	2026-02-03 15:40:07.831672+01	0
53	248	510	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831673+01	2026-02-03 15:40:07.831673+01	0
54	248	511	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831674+01	2026-02-03 15:40:07.831674+01	0
55	248	512	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831675+01	2026-02-03 15:40:07.831675+01	0
56	248	518	Réaliser les opérations comptables courantes d'une TPE (MARS SEPT 2025)	6	0	2026-02-03 15:40:07.831676+01	2026-02-03 15:40:07.831677+01	0
57	256	530	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831677+01	2026-02-03 15:40:07.831678+01	0
58	256	531	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831678+01	2026-02-03 15:40:07.831679+01	0
59	256	532	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831679+01	2026-02-03 15:40:07.83168+01	0
60	256	533	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.83168+01	2026-02-03 15:40:07.831681+01	0
61	256	535	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831681+01	2026-02-03 15:40:07.831682+01	0
62	256	534	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831682+01	2026-02-03 15:40:07.831683+01	0
63	256	536	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831684+01	2026-02-03 15:40:07.831684+01	0
64	256	537	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831685+01	2026-02-03 15:40:07.831685+01	0
65	257	538	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.831686+01	2026-02-03 15:40:07.831686+01	0
66	266	548	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831687+01	2026-02-03 15:40:07.831687+01	0
67	266	550	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831688+01	2026-02-03 15:40:07.831688+01	0
68	266	551	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831689+01	2026-02-03 15:40:07.831689+01	0
69	266	552	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.83169+01	2026-02-03 15:40:07.83169+01	0
70	266	1862	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831691+01	2026-02-03 15:40:07.831692+01	0
71	266	549	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831692+01	2026-02-03 15:40:07.831693+01	0
72	266	557	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831693+01	2026-02-03 15:40:07.831694+01	0
73	272	563	Bilan de compétences (12h)	6	0	2026-02-03 15:40:07.831694+01	2026-02-03 15:40:07.831695+01	0
74	275	566	Bilan de compétences (10h)	6	0	2026-02-03 15:40:07.831695+01	2026-02-03 15:40:07.831696+01	0
75	288	1459	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.831696+01	2026-02-03 15:40:07.831697+01	0
76	288	1460	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.831697+01	2026-02-03 15:40:07.831698+01	0
77	303	648	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873739+01	2026-02-03 15:40:07.873742+01	0
78	303	649	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873743+01	2026-02-03 15:40:07.873744+01	0
79	303	2856	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873744+01	2026-02-03 15:40:07.873745+01	0
80	303	2857	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873745+01	2026-02-03 15:40:07.873746+01	0
81	303	2858	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873746+01	2026-02-03 15:40:07.873747+01	0
82	303	2859	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873747+01	2026-02-03 15:40:07.873748+01	0
83	306	1012	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873748+01	2026-02-03 15:40:07.873749+01	0
84	306	656	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873749+01	2026-02-03 15:40:07.87375+01	0
85	306	657	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.87375+01	2026-02-03 15:40:07.873751+01	0
86	306	658	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873751+01	2026-02-03 15:40:07.873752+01	0
87	306	659	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873753+01	2026-02-03 15:40:07.873753+01	0
88	306	660	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873754+01	2026-02-03 15:40:07.873754+01	0
89	306	661	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873755+01	2026-02-03 15:40:07.873755+01	0
90	306	662	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873756+01	2026-02-03 15:40:07.873756+01	0
91	306	663	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873757+01	2026-02-03 15:40:07.873757+01	0
92	306	664	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873758+01	2026-02-03 15:40:07.873758+01	0
93	306	665	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873759+01	2026-02-03 15:40:07.873759+01	0
94	306	666	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.87376+01	2026-02-03 15:40:07.87376+01	0
95	306	667	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873761+01	2026-02-03 15:40:07.873761+01	0
96	306	668	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873762+01	2026-02-03 15:40:07.873762+01	0
97	306	669	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873763+01	2026-02-03 15:40:07.873763+01	0
98	306	670	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873764+01	2026-02-03 15:40:07.873764+01	0
99	306	1013	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873765+01	2026-02-03 15:40:07.873765+01	0
100	306	1014	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873766+01	2026-02-03 15:40:07.873766+01	0
101	306	1015	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873767+01	2026-02-03 15:40:07.873767+01	0
102	306	1016	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873768+01	2026-02-03 15:40:07.873768+01	0
103	306	1017	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873769+01	2026-02-03 15:40:07.87377+01	0
104	307	1440	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.87377+01	2026-02-03 15:40:07.873771+01	0
105	307	1441	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.873771+01	2026-02-03 15:40:07.873772+01	0
106	313	682	CréActifs - Formation Création d'Entreprise MAI-JUIN25	6	0	2026-02-03 15:40:07.873772+01	2026-02-03 15:40:07.873773+01	0
107	313	683	CréActifs - Formation Création d'Entreprise MAI-JUIN25	6	0	2026-02-03 15:40:07.873773+01	2026-02-03 15:40:07.873774+01	0
108	313	684	CréActifs - Formation Création d'Entreprise MAI-JUIN25	6	0	2026-02-03 15:40:07.873774+01	2026-02-03 15:40:07.873775+01	0
109	313	685	CréActifs - Formation Création d'Entreprise MAI-JUIN25	6	0	2026-02-03 15:40:07.873775+01	2026-02-03 15:40:07.873776+01	0
110	323	693	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.873776+01	2026-02-03 15:40:07.873777+01	0
111	326	696	Bilan de compétences (8h) - ESPUNA Manon	6	0	2026-02-03 15:40:07.873777+01	2026-02-03 15:40:07.873778+01	0
112	327	697	Bilan de compétences (10h)	6	0	2026-02-03 15:40:07.873778+01	2026-02-03 15:40:07.873779+01	0
113	328	698	Bilan de compétences (6h)	6	0	2026-02-03 15:40:07.873781+01	2026-02-03 15:40:07.873781+01	0
114	356	752	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873782+01	2026-02-03 15:40:07.873782+01	0
115	356	749	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873783+01	2026-02-03 15:40:07.873783+01	0
116	356	1020	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873784+01	2026-02-03 15:40:07.873784+01	0
117	356	750	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873785+01	2026-02-03 15:40:07.873785+01	0
118	356	1151	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873786+01	2026-02-03 15:40:07.873786+01	0
119	356	751	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873787+01	2026-02-03 15:40:07.873787+01	0
120	356	758	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873788+01	2026-02-03 15:40:07.873788+01	0
121	356	759	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873789+01	2026-02-03 15:40:07.873789+01	0
122	356	760	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.87379+01	2026-02-03 15:40:07.87379+01	0
123	356	764	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873791+01	2026-02-03 15:40:07.873791+01	0
124	356	765	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873792+01	2026-02-03 15:40:07.873793+01	0
125	356	771	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873793+01	2026-02-03 15:40:07.873794+01	0
126	356	772	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873794+01	2026-02-03 15:40:07.873795+01	0
127	356	774	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873795+01	2026-02-03 15:40:07.873796+01	0
128	356	775	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873796+01	2026-02-03 15:40:07.873797+01	0
129	356	776	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873797+01	2026-02-03 15:40:07.873798+01	0
130	356	778	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873798+01	2026-02-03 15:40:07.873799+01	0
131	356	781	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873799+01	2026-02-03 15:40:07.8738+01	0
132	356	782	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873801+01	2026-02-03 15:40:07.873801+01	0
133	356	753	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873802+01	2026-02-03 15:40:07.873802+01	0
134	356	754	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873803+01	2026-02-03 15:40:07.873803+01	0
135	356	755	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873804+01	2026-02-03 15:40:07.873804+01	0
136	356	756	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873805+01	2026-02-03 15:40:07.873805+01	0
137	356	757	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873806+01	2026-02-03 15:40:07.873806+01	0
138	356	761	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873807+01	2026-02-03 15:40:07.873807+01	0
139	356	763	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873808+01	2026-02-03 15:40:07.873808+01	0
140	356	762	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873809+01	2026-02-03 15:40:07.873809+01	0
141	356	766	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.87381+01	2026-02-03 15:40:07.87381+01	0
142	356	767	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873811+01	2026-02-03 15:40:07.873811+01	0
143	356	768	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873812+01	2026-02-03 15:40:07.873812+01	0
144	356	769	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873813+01	2026-02-03 15:40:07.873813+01	0
145	356	770	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873814+01	2026-02-03 15:40:07.873814+01	0
146	356	773	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873815+01	2026-02-03 15:40:07.873815+01	0
147	356	1898	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873816+01	2026-02-03 15:40:07.873816+01	0
148	356	1899	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873817+01	2026-02-03 15:40:07.873817+01	0
149	356	1900	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873818+01	2026-02-03 15:40:07.873818+01	0
150	356	1901	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873819+01	2026-02-03 15:40:07.873819+01	0
151	356	1902	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.87382+01	2026-02-03 15:40:07.87382+01	0
152	356	779	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873821+01	2026-02-03 15:40:07.873821+01	0
153	356	777	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873822+01	2026-02-03 15:40:07.873822+01	0
154	356	780	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873823+01	2026-02-03 15:40:07.873823+01	0
155	358	784	Bilan de compétences (10h) - LE BRETON Magali	6	0	2026-02-03 15:40:07.873824+01	2026-02-03 15:40:07.87383+01	0
156	363	789	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969798+01	2026-02-03 15:40:07.969801+01	0
157	363	794	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969802+01	2026-02-03 15:40:07.969803+01	0
158	363	798	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969803+01	2026-02-03 15:40:07.969804+01	0
159	363	804	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969804+01	2026-02-03 15:40:07.969805+01	0
160	363	809	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969805+01	2026-02-03 15:40:07.969806+01	0
161	363	810	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969807+01	2026-02-03 15:40:07.969807+01	0
162	363	811	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969808+01	2026-02-03 15:40:07.969808+01	0
163	363	791	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969809+01	2026-02-03 15:40:07.969809+01	0
164	363	799	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96981+01	2026-02-03 15:40:07.96981+01	0
165	363	800	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969811+01	2026-02-03 15:40:07.969811+01	0
166	363	801	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969812+01	2026-02-03 15:40:07.969812+01	0
167	363	805	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969813+01	2026-02-03 15:40:07.969813+01	0
168	363	806	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969814+01	2026-02-03 15:40:07.969814+01	0
169	363	812	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969815+01	2026-02-03 15:40:07.969815+01	0
170	363	813	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969816+01	2026-02-03 15:40:07.969816+01	0
171	363	815	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969817+01	2026-02-03 15:40:07.969817+01	0
172	363	816	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969818+01	2026-02-03 15:40:07.969818+01	0
173	363	818	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969819+01	2026-02-03 15:40:07.969819+01	0
174	363	820	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96982+01	2026-02-03 15:40:07.96982+01	0
175	363	822	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969821+01	2026-02-03 15:40:07.969821+01	0
176	363	823	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969822+01	2026-02-03 15:40:07.969822+01	0
177	363	790	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969823+01	2026-02-03 15:40:07.969824+01	0
178	363	792	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969826+01	2026-02-03 15:40:07.969826+01	0
179	363	802	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969827+01	2026-02-03 15:40:07.969827+01	0
180	363	807	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969828+01	2026-02-03 15:40:07.969828+01	0
181	363	814	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969829+01	2026-02-03 15:40:07.969829+01	0
182	363	817	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96983+01	2026-02-03 15:40:07.96983+01	0
183	363	819	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969831+01	2026-02-03 15:40:07.969832+01	0
184	363	821	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969832+01	2026-02-03 15:40:07.969833+01	0
185	363	793	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969833+01	2026-02-03 15:40:07.969834+01	0
186	363	808	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969834+01	2026-02-03 15:40:07.969835+01	0
187	363	795	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969835+01	2026-02-03 15:40:07.969836+01	0
188	363	796	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969836+01	2026-02-03 15:40:07.969837+01	0
189	363	797	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969837+01	2026-02-03 15:40:07.969838+01	0
190	363	803	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969838+01	2026-02-03 15:40:07.969839+01	0
191	364	824	Formation Excel	6	0	2026-02-03 15:40:07.969839+01	2026-02-03 15:40:07.96984+01	0
192	364	825	Formation Excel	6	0	2026-02-03 15:40:07.96984+01	2026-02-03 15:40:07.969841+01	0
193	372	836	Bilan de compétences (6h)	6	0	2026-02-03 15:40:07.969841+01	2026-02-03 15:40:07.969842+01	0
194	373	837	Wordpress	6	0	2026-02-03 15:40:07.969843+01	2026-02-03 15:40:07.969843+01	0
195	373	2355	Wordpress	6	0	2026-02-03 15:40:07.969844+01	2026-02-03 15:40:07.969844+01	0
196	374	838	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.969845+01	2026-02-03 15:40:07.969845+01	0
197	377	841	Bilan de compétences (12h)	6	0	2026-02-03 15:40:07.969846+01	2026-02-03 15:40:07.969846+01	0
198	381	879	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969847+01	2026-02-03 15:40:07.969847+01	0
199	381	880	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969848+01	2026-02-03 15:40:07.969848+01	0
200	381	881	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969849+01	2026-02-03 15:40:07.969849+01	0
201	381	882	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.96985+01	2026-02-03 15:40:07.96985+01	0
202	381	883	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969851+01	2026-02-03 15:40:07.969851+01	0
203	381	884	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969852+01	2026-02-03 15:40:07.969852+01	0
204	381	885	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969853+01	2026-02-03 15:40:07.969853+01	0
205	381	886	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969854+01	2026-02-03 15:40:07.969855+01	0
206	381	887	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969855+01	2026-02-03 15:40:07.969856+01	0
207	381	888	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969856+01	2026-02-03 15:40:07.969857+01	0
208	381	889	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969857+01	2026-02-03 15:40:07.969858+01	0
209	381	890	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969858+01	2026-02-03 15:40:07.969859+01	0
210	381	891	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969859+01	2026-02-03 15:40:07.96986+01	0
211	381	892	[TP SAMS] - Secrétaire Assistant Médico-Social JUIN-AOUT 2025 (Classes COLLECTIVES)	6	0	2026-02-03 15:40:07.969861+01	2026-02-03 15:40:07.969861+01	0
212	384	1040	[TP SAMS] Classes Virtuelles Individuelles 6h (BEAUMET Sibylle)	6	0	2026-02-03 15:40:07.969862+01	2026-02-03 15:40:07.969862+01	0
213	384	1041	[TP SAMS] Classes Virtuelles Individuelles 6h (BEAUMET Sibylle)	6	0	2026-02-03 15:40:07.969863+01	2026-02-03 15:40:07.969863+01	0
214	384	1042	[TP SAMS] Classes Virtuelles Individuelles 6h (BEAUMET Sibylle)	6	0	2026-02-03 15:40:07.969864+01	2026-02-03 15:40:07.969864+01	0
215	384	1043	[TP SAMS] Classes Virtuelles Individuelles 6h (BEAUMET Sibylle)	6	0	2026-02-03 15:40:07.969865+01	2026-02-03 15:40:07.969865+01	0
216	384	1044	[TP SAMS] Classes Virtuelles Individuelles 6h (BEAUMET Sibylle)	6	0	2026-02-03 15:40:07.969866+01	2026-02-03 15:40:07.969866+01	0
217	384	1045	[TP SAMS] Classes Virtuelles Individuelles 6h (BEAUMET Sibylle)	6	0	2026-02-03 15:40:07.969867+01	2026-02-03 15:40:07.969867+01	0
218	384	896	[TP SAMS] Classes Virtuelles Individuelles 6h (BEAUMET Sibylle)	6	0	2026-02-03 15:40:07.969868+01	2026-02-03 15:40:07.969868+01	0
219	386	898	Bilan de compétences (16h)	6	0	2026-02-03 15:40:07.969869+01	2026-02-03 15:40:07.969869+01	0
220	387	899	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969871+01	2026-02-03 15:40:07.969871+01	0
221	387	901	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969872+01	2026-02-03 15:40:07.969872+01	0
222	387	909	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969873+01	2026-02-03 15:40:07.969873+01	0
223	387	910	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969874+01	2026-02-03 15:40:07.969874+01	0
224	387	911	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969875+01	2026-02-03 15:40:07.969875+01	0
225	387	915	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969876+01	2026-02-03 15:40:07.969876+01	0
226	387	916	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969877+01	2026-02-03 15:40:07.969877+01	0
227	387	922	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969878+01	2026-02-03 15:40:07.969878+01	0
228	387	923	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969879+01	2026-02-03 15:40:07.969879+01	0
229	387	925	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96988+01	2026-02-03 15:40:07.96988+01	0
230	387	926	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969881+01	2026-02-03 15:40:07.969881+01	0
231	387	928	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969882+01	2026-02-03 15:40:07.969882+01	0
232	387	930	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969883+01	2026-02-03 15:40:07.969883+01	0
233	387	932	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969884+01	2026-02-03 15:40:07.969884+01	0
234	387	933	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969885+01	2026-02-03 15:40:07.969885+01	0
235	387	900	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969886+01	2026-02-03 15:40:07.969886+01	0
236	387	902	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969887+01	2026-02-03 15:40:07.969887+01	0
237	387	912	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969888+01	2026-02-03 15:40:07.969888+01	0
333	396	2356	Wordpress	6	0	2026-02-03 15:40:07.969989+01	2026-02-03 15:40:07.969989+01	0
238	387	917	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969889+01	2026-02-03 15:40:07.969889+01	0
239	387	924	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96989+01	2026-02-03 15:40:07.96989+01	0
240	387	927	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969891+01	2026-02-03 15:40:07.969891+01	0
241	387	929	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969892+01	2026-02-03 15:40:07.969892+01	0
242	387	931	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969893+01	2026-02-03 15:40:07.969893+01	0
243	387	903	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969894+01	2026-02-03 15:40:07.969894+01	0
244	387	918	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969895+01	2026-02-03 15:40:07.969895+01	0
245	387	904	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969896+01	2026-02-03 15:40:07.969896+01	0
246	387	919	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969897+01	2026-02-03 15:40:07.969897+01	0
247	387	905	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969898+01	2026-02-03 15:40:07.969898+01	0
248	387	920	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969899+01	2026-02-03 15:40:07.969899+01	0
249	387	906	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.9699+01	2026-02-03 15:40:07.9699+01	0
250	387	921	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969901+01	2026-02-03 15:40:07.969901+01	0
251	387	907	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969902+01	2026-02-03 15:40:07.969902+01	0
252	387	908	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969903+01	2026-02-03 15:40:07.969903+01	0
253	387	913	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969904+01	2026-02-03 15:40:07.969905+01	0
254	387	914	Session 2 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969905+01	2026-02-03 15:40:07.969906+01	0
255	388	934	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969906+01	2026-02-03 15:40:07.969907+01	0
256	388	936	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969907+01	2026-02-03 15:40:07.969908+01	0
257	388	944	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969908+01	2026-02-03 15:40:07.969909+01	0
258	388	945	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969909+01	2026-02-03 15:40:07.96991+01	0
259	388	946	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96991+01	2026-02-03 15:40:07.969911+01	0
260	388	950	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969911+01	2026-02-03 15:40:07.969912+01	0
261	388	951	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969913+01	2026-02-03 15:40:07.969913+01	0
262	388	957	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969914+01	2026-02-03 15:40:07.969915+01	0
263	388	958	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969916+01	2026-02-03 15:40:07.969916+01	0
264	388	960	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969917+01	2026-02-03 15:40:07.969917+01	0
265	388	961	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969918+01	2026-02-03 15:40:07.969918+01	0
266	388	963	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969919+01	2026-02-03 15:40:07.969919+01	0
267	388	965	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96992+01	2026-02-03 15:40:07.96992+01	0
268	388	967	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969921+01	2026-02-03 15:40:07.969921+01	0
269	388	968	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969922+01	2026-02-03 15:40:07.969922+01	0
270	388	935	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969923+01	2026-02-03 15:40:07.969923+01	0
271	388	2423	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969924+01	2026-02-03 15:40:07.969924+01	0
272	388	2424	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969925+01	2026-02-03 15:40:07.969925+01	0
273	388	2425	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969926+01	2026-02-03 15:40:07.969926+01	0
274	388	2426	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969927+01	2026-02-03 15:40:07.969927+01	0
275	388	2427	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969928+01	2026-02-03 15:40:07.969928+01	0
276	388	937	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969929+01	2026-02-03 15:40:07.96993+01	0
277	388	947	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96993+01	2026-02-03 15:40:07.969931+01	0
278	388	952	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969931+01	2026-02-03 15:40:07.969932+01	0
279	388	959	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969932+01	2026-02-03 15:40:07.969933+01	0
280	388	962	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969933+01	2026-02-03 15:40:07.969934+01	0
281	388	964	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969934+01	2026-02-03 15:40:07.969935+01	0
282	388	966	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969935+01	2026-02-03 15:40:07.969936+01	0
283	388	938	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969936+01	2026-02-03 15:40:07.969937+01	0
284	388	953	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969937+01	2026-02-03 15:40:07.969938+01	0
285	388	939	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969938+01	2026-02-03 15:40:07.969939+01	0
286	388	954	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96994+01	2026-02-03 15:40:07.96994+01	0
287	388	940	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969941+01	2026-02-03 15:40:07.969941+01	0
288	388	955	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969942+01	2026-02-03 15:40:07.969942+01	0
289	388	941	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969943+01	2026-02-03 15:40:07.969943+01	0
290	388	956	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969944+01	2026-02-03 15:40:07.969944+01	0
291	388	942	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969945+01	2026-02-03 15:40:07.969945+01	0
292	388	943	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969946+01	2026-02-03 15:40:07.969946+01	0
293	388	948	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969947+01	2026-02-03 15:40:07.969947+01	0
294	388	949	Session 3 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969948+01	2026-02-03 15:40:07.969948+01	0
295	389	969	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969949+01	2026-02-03 15:40:07.969949+01	0
296	389	971	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96995+01	2026-02-03 15:40:07.96995+01	0
297	389	979	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969951+01	2026-02-03 15:40:07.969951+01	0
298	389	980	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969952+01	2026-02-03 15:40:07.969952+01	0
299	389	981	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969953+01	2026-02-03 15:40:07.969953+01	0
300	389	985	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969954+01	2026-02-03 15:40:07.969954+01	0
301	389	986	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969955+01	2026-02-03 15:40:07.969955+01	0
302	389	992	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969956+01	2026-02-03 15:40:07.969957+01	0
303	389	993	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969957+01	2026-02-03 15:40:07.969958+01	0
304	389	995	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969958+01	2026-02-03 15:40:07.969959+01	0
305	389	996	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96996+01	2026-02-03 15:40:07.969961+01	0
306	389	998	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969961+01	2026-02-03 15:40:07.969962+01	0
307	389	1000	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969962+01	2026-02-03 15:40:07.969963+01	0
308	389	1002	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969963+01	2026-02-03 15:40:07.969964+01	0
309	389	1003	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969964+01	2026-02-03 15:40:07.969965+01	0
310	389	970	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969965+01	2026-02-03 15:40:07.969966+01	0
311	389	972	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969966+01	2026-02-03 15:40:07.969967+01	0
312	389	982	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969967+01	2026-02-03 15:40:07.969968+01	0
313	389	987	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969968+01	2026-02-03 15:40:07.969969+01	0
314	389	994	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969969+01	2026-02-03 15:40:07.96997+01	0
315	389	997	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96997+01	2026-02-03 15:40:07.969971+01	0
316	389	999	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969971+01	2026-02-03 15:40:07.969972+01	0
317	389	1001	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969972+01	2026-02-03 15:40:07.969973+01	0
318	389	973	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969973+01	2026-02-03 15:40:07.969974+01	0
319	389	988	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969974+01	2026-02-03 15:40:07.969975+01	0
320	389	974	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969975+01	2026-02-03 15:40:07.969976+01	0
321	389	989	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969976+01	2026-02-03 15:40:07.969977+01	0
322	389	975	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969977+01	2026-02-03 15:40:07.969978+01	0
323	389	990	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969978+01	2026-02-03 15:40:07.969979+01	0
324	389	976	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969979+01	2026-02-03 15:40:07.96998+01	0
325	389	991	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96998+01	2026-02-03 15:40:07.969981+01	0
326	389	977	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969981+01	2026-02-03 15:40:07.969982+01	0
327	389	978	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969982+01	2026-02-03 15:40:07.969983+01	0
328	389	983	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969984+01	2026-02-03 15:40:07.969984+01	0
329	389	984	Session 4 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969985+01	2026-02-03 15:40:07.969985+01	0
330	394	1113	[TP EAA] Employé administratif et d'accueil (Expert)	6	0	2026-02-03 15:40:07.969986+01	2026-02-03 15:40:07.969986+01	0
331	394	1114	[TP EAA] Employé administratif et d'accueil (Expert)	6	0	2026-02-03 15:40:07.969987+01	2026-02-03 15:40:07.969987+01	0
332	396	1018	Wordpress	6	0	2026-02-03 15:40:07.969988+01	2026-02-03 15:40:07.969988+01	0
334	400	1023	Bilan de compétences (6h)	6	0	2026-02-03 15:40:07.96999+01	2026-02-03 15:40:07.96999+01	0
335	401	1024	Microsoft Excel Niveau Standard	6	0	2026-02-03 15:40:07.969991+01	2026-02-03 15:40:07.969991+01	0
336	405	1028	Management (M. EBRING James)	6	0	2026-02-03 15:40:07.969992+01	2026-02-03 15:40:07.969992+01	0
337	405	1029	Management (M. EBRING James)	6	0	2026-02-03 15:40:07.969993+01	2026-02-03 15:40:07.969993+01	0
338	405	1030	Management (M. EBRING James)	6	0	2026-02-03 15:40:07.969994+01	2026-02-03 15:40:07.969994+01	0
339	405	1031	Management (M. EBRING James)	6	0	2026-02-03 15:40:07.969995+01	2026-02-03 15:40:07.969995+01	0
340	407	1033	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.969996+01	2026-02-03 15:40:07.969996+01	0
341	413	1047	[TP SAMS] Classes Virtuelles Individuelles 6h (Alison Roger)	6	0	2026-02-03 15:40:07.969997+01	2026-02-03 15:40:07.969997+01	0
342	413	1048	[TP SAMS] Classes Virtuelles Individuelles 6h (Alison Roger)	6	0	2026-02-03 15:40:07.969998+01	2026-02-03 15:40:07.969998+01	0
343	413	1049	[TP SAMS] Classes Virtuelles Individuelles 6h (Alison Roger)	6	0	2026-02-03 15:40:07.969999+01	2026-02-03 15:40:07.969999+01	0
344	413	1050	[TP SAMS] Classes Virtuelles Individuelles 6h (Alison Roger)	6	0	2026-02-03 15:40:07.97+01	2026-02-03 15:40:07.97+01	0
345	413	1051	[TP SAMS] Classes Virtuelles Individuelles 6h (Alison Roger)	6	0	2026-02-03 15:40:07.970001+01	2026-02-03 15:40:07.970002+01	0
346	413	1052	[TP SAMS] Classes Virtuelles Individuelles 6h (Alison Roger)	6	0	2026-02-03 15:40:07.970002+01	2026-02-03 15:40:07.970003+01	0
347	413	1046	[TP SAMS] Classes Virtuelles Individuelles 6h (Alison Roger)	6	0	2026-02-03 15:40:07.970003+01	2026-02-03 15:40:07.970004+01	0
348	415	1115	[TP EAA] Employé administratif et d'accueil (Expert)	6	0	2026-02-03 15:40:07.970005+01	2026-02-03 15:40:07.970006+01	0
349	415	1116	[TP EAA] Employé administratif et d'accueil (Expert)	6	0	2026-02-03 15:40:07.970006+01	2026-02-03 15:40:07.970007+01	0
350	421	1061	[TP SAMS] Classes Virtuelles Individuelles 6h (Celine Cocagne)	6	0	2026-02-03 15:40:08.009087+01	2026-02-03 15:40:08.00909+01	0
351	421	1062	[TP SAMS] Classes Virtuelles Individuelles 6h (Celine Cocagne)	6	0	2026-02-03 15:40:08.009091+01	2026-02-03 15:40:08.009105+01	0
352	421	1063	[TP SAMS] Classes Virtuelles Individuelles 6h (Celine Cocagne)	6	0	2026-02-03 15:40:08.009106+01	2026-02-03 15:40:08.009106+01	0
353	421	1064	[TP SAMS] Classes Virtuelles Individuelles 6h (Celine Cocagne)	6	0	2026-02-03 15:40:08.009107+01	2026-02-03 15:40:08.009108+01	0
354	421	1065	[TP SAMS] Classes Virtuelles Individuelles 6h (Celine Cocagne)	6	0	2026-02-03 15:40:08.009108+01	2026-02-03 15:40:08.009109+01	0
355	421	1066	[TP SAMS] Classes Virtuelles Individuelles 6h (Celine Cocagne)	6	0	2026-02-03 15:40:08.00911+01	2026-02-03 15:40:08.009111+01	0
356	421	1060	[TP SAMS] Classes Virtuelles Individuelles 6h (Celine Cocagne)	6	0	2026-02-03 15:40:08.009112+01	2026-02-03 15:40:08.009113+01	0
357	422	1067	Bilan de compétences (12h) - NOGARA Juliana	6	0	2026-02-03 15:40:08.009113+01	2026-02-03 15:40:08.009114+01	0
358	424	1072	[TP SAMS] Classes Virtuelles Individuelles 2h (Solange RIVET)	6	0	2026-02-03 15:40:08.009115+01	2026-02-03 15:40:08.009115+01	0
359	424	1073	[TP SAMS] Classes Virtuelles Individuelles 2h (Solange RIVET)	6	0	2026-02-03 15:40:08.009116+01	2026-02-03 15:40:08.009117+01	0
360	424	1074	[TP SAMS] Classes Virtuelles Individuelles 2h (Solange RIVET)	6	0	2026-02-03 15:40:08.009118+01	2026-02-03 15:40:08.009118+01	0
361	424	1075	[TP SAMS] Classes Virtuelles Individuelles 2h (Solange RIVET)	6	0	2026-02-03 15:40:08.009119+01	2026-02-03 15:40:08.00912+01	0
362	424	1076	[TP SAMS] Classes Virtuelles Individuelles 2h (Solange RIVET)	6	0	2026-02-03 15:40:08.009121+01	2026-02-03 15:40:08.009122+01	0
363	424	1070	[TP SAMS] Classes Virtuelles Individuelles 2h (Solange RIVET)	6	0	2026-02-03 15:40:08.009123+01	2026-02-03 15:40:08.009124+01	0
364	424	1071	[TP SAMS] Classes Virtuelles Individuelles 2h (Solange RIVET)	6	0	2026-02-03 15:40:08.009125+01	2026-02-03 15:40:08.009125+01	0
365	426	1080	[TP SAMS] Classes Virtuelles Individuelles 2h (Laura LANGLOIS)	6	0	2026-02-03 15:40:08.009126+01	2026-02-03 15:40:08.009127+01	0
366	426	1081	[TP SAMS] Classes Virtuelles Individuelles 2h (Laura LANGLOIS)	6	0	2026-02-03 15:40:08.009128+01	2026-02-03 15:40:08.009129+01	0
367	426	1082	[TP SAMS] Classes Virtuelles Individuelles 2h (Laura LANGLOIS)	6	0	2026-02-03 15:40:08.009129+01	2026-02-03 15:40:08.00913+01	0
368	426	1083	[TP SAMS] Classes Virtuelles Individuelles 2h (Laura LANGLOIS)	6	0	2026-02-03 15:40:08.009131+01	2026-02-03 15:40:08.009131+01	0
369	426	1078	[TP SAMS] Classes Virtuelles Individuelles 2h (Laura LANGLOIS)	6	0	2026-02-03 15:40:08.009132+01	2026-02-03 15:40:08.009133+01	0
370	426	1079	[TP SAMS] Classes Virtuelles Individuelles 2h (Laura LANGLOIS)	6	0	2026-02-03 15:40:08.009134+01	2026-02-03 15:40:08.009135+01	0
371	426	1084	[TP SAMS] Classes Virtuelles Individuelles 2h (Laura LANGLOIS)	6	0	2026-02-03 15:40:08.009136+01	2026-02-03 15:40:08.009137+01	0
372	433	1097	[TP SAMS] Classes Virtuelles Individuelles 2h (Brigitte Vanwierst)	6	0	2026-02-03 15:40:08.009138+01	2026-02-03 15:40:08.009138+01	0
373	433	1091	[TP SAMS] Classes Virtuelles Individuelles 2h (Brigitte Vanwierst)	6	0	2026-02-03 15:40:08.009139+01	2026-02-03 15:40:08.00914+01	0
374	433	1092	[TP SAMS] Classes Virtuelles Individuelles 2h (Brigitte Vanwierst)	6	0	2026-02-03 15:40:08.009141+01	2026-02-03 15:40:08.009142+01	0
375	433	1093	[TP SAMS] Classes Virtuelles Individuelles 2h (Brigitte Vanwierst)	6	0	2026-02-03 15:40:08.009143+01	2026-02-03 15:40:08.009144+01	0
376	433	1094	[TP SAMS] Classes Virtuelles Individuelles 2h (Brigitte Vanwierst)	6	0	2026-02-03 15:40:08.009145+01	2026-02-03 15:40:08.009145+01	0
377	433	1095	[TP SAMS] Classes Virtuelles Individuelles 2h (Brigitte Vanwierst)	6	0	2026-02-03 15:40:08.009146+01	2026-02-03 15:40:08.009147+01	0
378	433	1096	[TP SAMS] Classes Virtuelles Individuelles 2h (Brigitte Vanwierst)	6	0	2026-02-03 15:40:08.009148+01	2026-02-03 15:40:08.009149+01	0
379	439	1103	[TP SAMS] Classes Virtuelles Individuelles 2h (Anne-Sophie FERREIRA)	6	0	2026-02-03 15:40:08.00915+01	2026-02-03 15:40:08.00915+01	0
380	439	1104	[TP SAMS] Classes Virtuelles Individuelles 2h (Anne-Sophie FERREIRA)	6	0	2026-02-03 15:40:08.009152+01	2026-02-03 15:40:08.009152+01	0
381	439	1105	[TP SAMS] Classes Virtuelles Individuelles 2h (Anne-Sophie FERREIRA)	6	0	2026-02-03 15:40:08.009153+01	2026-02-03 15:40:08.009154+01	0
382	439	1106	[TP SAMS] Classes Virtuelles Individuelles 2h (Anne-Sophie FERREIRA)	6	0	2026-02-03 15:40:08.009155+01	2026-02-03 15:40:08.009156+01	0
383	439	1107	[TP SAMS] Classes Virtuelles Individuelles 2h (Anne-Sophie FERREIRA)	6	0	2026-02-03 15:40:08.009157+01	2026-02-03 15:40:08.009158+01	0
384	439	1108	[TP SAMS] Classes Virtuelles Individuelles 2h (Anne-Sophie FERREIRA)	6	0	2026-02-03 15:40:08.009158+01	2026-02-03 15:40:08.009159+01	0
385	439	1109	[TP SAMS] Classes Virtuelles Individuelles 2h (Anne-Sophie FERREIRA)	6	0	2026-02-03 15:40:08.009159+01	2026-02-03 15:40:08.00916+01	0
386	442	1117	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.00916+01	2026-02-03 15:40:08.009161+01	0
387	442	1118	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.009161+01	2026-02-03 15:40:08.009162+01	0
388	443	1119	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.009162+01	2026-02-03 15:40:08.009163+01	0
389	443	1120	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.009164+01	2026-02-03 15:40:08.009164+01	0
390	444	1121	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.009165+01	2026-02-03 15:40:08.009165+01	0
391	444	1122	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.009166+01	2026-02-03 15:40:08.009166+01	0
392	446	1124	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.009167+01	2026-02-03 15:40:08.009167+01	0
393	452	1137	Allemand - CLOE (Expert)	6	0	2026-02-03 15:40:08.009168+01	2026-02-03 15:40:08.00917+01	0
394	452	1138	Allemand - CLOE (Expert)	6	0	2026-02-03 15:40:08.009171+01	2026-02-03 15:40:08.009172+01	0
395	453	1139	Bilan de compétences (10h) - CURTAT Ludivine	5	0	2026-02-03 15:40:08.009173+01	2026-02-03 15:40:08.009176+01	0
396	454	1140	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.009177+01	2026-02-03 15:40:08.009178+01	0
397	455	1141	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.009179+01	2026-02-03 15:40:08.009179+01	0
398	458	1144	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.00918+01	2026-02-03 15:40:08.00918+01	0
399	461	1147	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.009181+01	2026-02-03 15:40:08.009181+01	0
400	464	1488	[TP SC] Secrétaire Comptable (Amanda Haize)	6	0	2026-02-03 15:40:08.009182+01	2026-02-03 15:40:08.009182+01	0
401	464	1489	[TP SC] Secrétaire Comptable (Amanda Haize)	6	0	2026-02-03 15:40:08.009183+01	2026-02-03 15:40:08.009183+01	0
402	467	1154	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.009184+01	2026-02-03 15:40:08.009184+01	0
403	469	1162	[TP SAMS] Classes Virtuelles Individuelles 12h (FRAMMERY Sylvette)	6	0	2026-02-03 15:40:08.009185+01	2026-02-03 15:40:08.009186+01	0
404	469	1156	[TP SAMS] Classes Virtuelles Individuelles 12h (FRAMMERY Sylvette)	6	0	2026-02-03 15:40:08.009186+01	2026-02-03 15:40:08.009187+01	0
405	469	1157	[TP SAMS] Classes Virtuelles Individuelles 12h (FRAMMERY Sylvette)	6	0	2026-02-03 15:40:08.009187+01	2026-02-03 15:40:08.009188+01	0
406	469	1158	[TP SAMS] Classes Virtuelles Individuelles 12h (FRAMMERY Sylvette)	6	0	2026-02-03 15:40:08.009188+01	2026-02-03 15:40:08.009189+01	0
407	469	1159	[TP SAMS] Classes Virtuelles Individuelles 12h (FRAMMERY Sylvette)	6	0	2026-02-03 15:40:08.009189+01	2026-02-03 15:40:08.00919+01	0
408	469	1160	[TP SAMS] Classes Virtuelles Individuelles 12h (FRAMMERY Sylvette)	6	0	2026-02-03 15:40:08.00919+01	2026-02-03 15:40:08.009191+01	0
409	469	1161	[TP SAMS] Classes Virtuelles Individuelles 12h (FRAMMERY Sylvette)	6	0	2026-02-03 15:40:08.009191+01	2026-02-03 15:40:08.009192+01	0
410	470	1163	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.027696+01	2026-02-03 15:40:08.027699+01	0
411	471	1170	[TP SAMS] Classes Virtuelles Individuelles 2h (PERRAULT LERAY Mélanie)	6	0	2026-02-03 15:40:08.0277+01	2026-02-03 15:40:08.027701+01	0
412	471	1165	[TP SAMS] Classes Virtuelles Individuelles 2h (PERRAULT LERAY Mélanie)	6	0	2026-02-03 15:40:08.027701+01	2026-02-03 15:40:08.027702+01	0
413	472	1177	[TP SAMS] Classes Virtuelles Individuelles 12h (GOUTORBE Sandrine)	6	0	2026-02-03 15:40:08.027702+01	2026-02-03 15:40:08.027703+01	0
414	472	1171	[TP SAMS] Classes Virtuelles Individuelles 12h (GOUTORBE Sandrine)	6	0	2026-02-03 15:40:08.027704+01	2026-02-03 15:40:08.027704+01	0
415	474	1179	Bilan de compétences (12h) (MATINDA Gregory)	6	0	2026-02-03 15:40:08.027705+01	2026-02-03 15:40:08.027705+01	0
416	475	1180	Bilan de compétences (12h) (MELI Anne-Laure)	6	0	2026-02-03 15:40:08.027706+01	2026-02-03 15:40:08.027706+01	0
417	476	1181	Bilan de compétences (10h) (PANZARELLA Celine)	6	0	2026-02-03 15:40:08.027707+01	2026-02-03 15:40:08.027707+01	0
418	477	1182	Bilan de compétences (16h)	6	0	2026-02-03 15:40:08.027708+01	2026-02-03 15:40:08.027708+01	0
419	478	1183	Bilan de compétences (12h) (PHILIP Catherine)	6	0	2026-02-03 15:40:08.027709+01	2026-02-03 15:40:08.02771+01	0
420	479	1184	Bilan de compétences (16h) (COMBAROPOULOS Yannis)	6	0	2026-02-03 15:40:08.02771+01	2026-02-03 15:40:08.027711+01	0
421	485	1190	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.027711+01	2026-02-03 15:40:08.027712+01	0
422	488	1193	Bilan de compétences (12h) - FERRIC Kelly	6	0	2026-02-03 15:40:08.027712+01	2026-02-03 15:40:08.027713+01	0
423	489	1194	Bilan de compétences (6h) - GUANNEL Erik	6	0	2026-02-03 15:40:08.027713+01	2026-02-03 15:40:08.027714+01	0
424	496	1201	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.027714+01	2026-02-03 15:40:08.027715+01	0
425	500	1207	[TP SAMS] Classes Virtuelles Individuelles 4h (Pamela GOURIOU)	6	0	2026-02-03 15:40:08.027715+01	2026-02-03 15:40:08.027716+01	0
426	500	1208	[TP SAMS] Classes Virtuelles Individuelles 4h (Pamela GOURIOU)	6	0	2026-02-03 15:40:08.027716+01	2026-02-03 15:40:08.027717+01	0
427	500	1209	[TP SAMS] Classes Virtuelles Individuelles 4h (Pamela GOURIOU)	6	0	2026-02-03 15:40:08.027717+01	2026-02-03 15:40:08.027718+01	0
428	500	1210	[TP SAMS] Classes Virtuelles Individuelles 4h (Pamela GOURIOU)	6	0	2026-02-03 15:40:08.027719+01	2026-02-03 15:40:08.027719+01	0
429	500	1205	[TP SAMS] Classes Virtuelles Individuelles 4h (Pamela GOURIOU)	6	0	2026-02-03 15:40:08.02772+01	2026-02-03 15:40:08.02772+01	0
430	500	1206	[TP SAMS] Classes Virtuelles Individuelles 4h (Pamela GOURIOU)	6	0	2026-02-03 15:40:08.027721+01	2026-02-03 15:40:08.027721+01	0
431	500	1211	[TP SAMS] Classes Virtuelles Individuelles 4h (Pamela GOURIOU)	6	0	2026-02-03 15:40:08.027722+01	2026-02-03 15:40:08.027722+01	0
432	506	1219	Anglais - CLOE (Expert)	6	0	2026-02-03 15:40:08.027723+01	2026-02-03 15:40:08.027723+01	0
433	506	1220	Anglais - CLOE (Expert)	6	0	2026-02-03 15:40:08.027724+01	2026-02-03 15:40:08.027724+01	0
434	509	1224	Bilan de compétences (8h) - METRAL Anthony	6	0	2026-02-03 15:40:08.027725+01	2026-02-03 15:40:08.027726+01	0
435	513	1228	Bilan de compétences (6h)	6	0	2026-02-03 15:40:08.027726+01	2026-02-03 15:40:08.027727+01	0
436	514	1229	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.027727+01	2026-02-03 15:40:08.027728+01	0
437	516	1231	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.027728+01	2026-02-03 15:40:08.027729+01	0
438	517	1232	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.027729+01	2026-02-03 15:40:08.02773+01	0
439	533	1252	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.039903+01	2026-02-03 15:40:08.039906+01	0
440	533	1249	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.039907+01	2026-02-03 15:40:08.039907+01	0
441	533	1251	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.039908+01	2026-02-03 15:40:08.039908+01	0
442	533	1250	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.039909+01	2026-02-03 15:40:08.039909+01	0
443	533	2606	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.03991+01	2026-02-03 15:40:08.03991+01	0
444	533	2659	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.039911+01	2026-02-03 15:40:08.039911+01	0
445	533	2660	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.039912+01	2026-02-03 15:40:08.039912+01	0
446	533	2612	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.039913+01	2026-02-03 15:40:08.039913+01	0
447	533	2661	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.039914+01	2026-02-03 15:40:08.039914+01	0
448	533	2742	CréActif - Formation Création d'Entreprise JUILL-NOV25	6	0	2026-02-03 15:40:08.039915+01	2026-02-03 15:40:08.039915+01	0
449	536	1255	Bilan de compétences (14h)	6	0	2026-02-03 15:40:08.039916+01	2026-02-03 15:40:08.039917+01	0
450	543	1262	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.039917+01	2026-02-03 15:40:08.039918+01	0
451	544	1263	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.039918+01	2026-02-03 15:40:08.039919+01	0
452	549	1268	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.039919+01	2026-02-03 15:40:08.03992+01	0
453	558	1280	Allemand - CLOE (Avancé) - Patricia Vassaux	6	0	2026-02-03 15:40:08.03992+01	2026-02-03 15:40:08.039921+01	0
454	558	1281	Allemand - CLOE (Avancé) - Patricia Vassaux	6	0	2026-02-03 15:40:08.039921+01	2026-02-03 15:40:08.039922+01	0
455	562	1288	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.039922+01	2026-02-03 15:40:08.039923+01	0
456	566	1297	[TP ARH] - Assitant Ressources Humaines	6	0	2026-02-03 15:40:08.039923+01	2026-02-03 15:40:08.039924+01	0
457	566	1298	[TP ARH] - Assitant Ressources Humaines	6	0	2026-02-03 15:40:08.039924+01	2026-02-03 15:40:08.039925+01	0
458	569	1301	Microsoft Excel Niveau Standard	6	0	2026-02-03 15:40:08.039925+01	2026-02-03 15:40:08.039926+01	0
459	580	1313	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.071435+01	2026-02-03 15:40:08.071438+01	0
460	583	1316	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.071439+01	2026-02-03 15:40:08.071439+01	0
461	583	1322	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.07144+01	2026-02-03 15:40:08.07144+01	0
462	583	1321	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.071441+01	2026-02-03 15:40:08.071441+01	0
463	583	1323	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.071442+01	2026-02-03 15:40:08.071442+01	0
464	583	1324	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.071443+01	2026-02-03 15:40:08.071444+01	0
465	583	1317	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.071444+01	2026-02-03 15:40:08.071445+01	0
466	583	1318	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.071445+01	2026-02-03 15:40:08.071446+01	0
467	583	1319	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.071446+01	2026-02-03 15:40:08.071447+01	0
468	583	1320	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.071447+01	2026-02-03 15:40:08.071448+01	0
469	583	1326	Formation Intelligence Artificielle (IA Générative) JUIN-DEC25	6	0	2026-02-03 15:40:08.071448+01	2026-02-03 15:40:08.071449+01	0
470	586	1328	Bilan de compétences (14h)	6	0	2026-02-03 15:40:08.071449+01	2026-02-03 15:40:08.07145+01	0
471	595	1340	Bilan de compétences (6h) - MANGEVAUD Sylvain	6	0	2026-02-03 15:40:08.07145+01	2026-02-03 15:40:08.071451+01	0
472	599	1345	Italien - CLOE (Expert)	6	0	2026-02-03 15:40:08.071452+01	2026-02-03 15:40:08.071452+01	0
473	599	1346	Italien - CLOE (Expert)	6	0	2026-02-03 15:40:08.071453+01	2026-02-03 15:40:08.071453+01	0
474	603	1350	Bilan de compétences (12h) - SPIESS John	6	0	2026-02-03 15:40:08.071454+01	2026-02-03 15:40:08.071454+01	0
475	604	1351	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.071455+01	2026-02-03 15:40:08.071455+01	0
476	606	1353	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.071456+01	2026-02-03 15:40:08.071456+01	0
477	607	1354	[TP EAA] Employé administratif et d'accueil (Expert)	6	0	2026-02-03 15:40:08.071457+01	2026-02-03 15:40:08.071457+01	0
478	607	1355	[TP EAA] Employé administratif et d'accueil (Expert)	6	0	2026-02-03 15:40:08.071458+01	2026-02-03 15:40:08.071459+01	0
479	610	1360	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.071459+01	2026-02-03 15:40:08.07146+01	0
480	611	1361	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.07146+01	2026-02-03 15:40:08.071461+01	0
481	619	1370	Anglais - CLOE (Standard) Bendjebour Bilel	6	0	2026-02-03 15:40:08.071461+01	2026-02-03 15:40:08.071462+01	0
482	619	1371	Anglais - CLOE (Standard) Bendjebour Bilel	6	0	2026-02-03 15:40:08.071462+01	2026-02-03 15:40:08.071463+01	0
483	620	1372	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.071464+01	2026-02-03 15:40:08.071464+01	0
484	623	1375	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.071465+01	2026-02-03 15:40:08.071465+01	0
485	624	1377	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071466+01	2026-02-03 15:40:08.071466+01	0
486	624	1379	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071467+01	2026-02-03 15:40:08.071467+01	0
487	624	1380	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071468+01	2026-02-03 15:40:08.071468+01	0
488	624	1376	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071469+01	2026-02-03 15:40:08.071469+01	0
489	624	1381	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.07147+01	2026-02-03 15:40:08.07147+01	0
490	624	1382	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071471+01	2026-02-03 15:40:08.071471+01	0
491	624	1383	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071472+01	2026-02-03 15:40:08.071472+01	0
492	624	1384	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071473+01	2026-02-03 15:40:08.071474+01	0
493	624	1385	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071474+01	2026-02-03 15:40:08.071475+01	0
494	624	1389	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071475+01	2026-02-03 15:40:08.071476+01	0
495	624	1390	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071476+01	2026-02-03 15:40:08.071477+01	0
496	624	1391	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071477+01	2026-02-03 15:40:08.071478+01	0
497	624	1378	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071478+01	2026-02-03 15:40:08.071479+01	0
498	624	1399	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071479+01	2026-02-03 15:40:08.07148+01	0
499	624	1400	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.07148+01	2026-02-03 15:40:08.071481+01	0
500	624	1402	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071481+01	2026-02-03 15:40:08.071482+01	0
501	624	1403	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071482+01	2026-02-03 15:40:08.071483+01	0
502	624	1394	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071483+01	2026-02-03 15:40:08.071484+01	0
503	624	1395	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071484+01	2026-02-03 15:40:08.071485+01	0
504	624	1396	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071485+01	2026-02-03 15:40:08.071486+01	0
505	624	1397	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071486+01	2026-02-03 15:40:08.071487+01	0
506	624	1386	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071487+01	2026-02-03 15:40:08.071488+01	0
507	624	1387	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071488+01	2026-02-03 15:40:08.071489+01	0
508	624	1388	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.07149+01	2026-02-03 15:40:08.07149+01	0
509	624	1398	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071491+01	2026-02-03 15:40:08.071491+01	0
510	624	1401	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071492+01	2026-02-03 15:40:08.071492+01	0
511	624	1392	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071493+01	2026-02-03 15:40:08.071493+01	0
512	624	1393	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071494+01	2026-02-03 15:40:08.071495+01	0
513	624	1406	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071495+01	2026-02-03 15:40:08.071496+01	0
514	624	1408	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071496+01	2026-02-03 15:40:08.071497+01	0
515	624	1404	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071497+01	2026-02-03 15:40:08.071498+01	0
516	624	1405	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071498+01	2026-02-03 15:40:08.071499+01	0
517	624	1407	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071499+01	2026-02-03 15:40:08.0715+01	0
518	624	1409	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.0715+01	2026-02-03 15:40:08.071501+01	0
519	624	1410	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071501+01	2026-02-03 15:40:08.071502+01	0
520	624	1411	SESSION 7 - Chef de projet en Rénovation énergétique	5	0	2026-02-03 15:40:08.071502+01	2026-02-03 15:40:08.071503+01	0
521	625	1412	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.071504+01	2026-02-03 15:40:08.071504+01	0
522	631	1418	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.121811+01	2026-02-03 15:40:08.121814+01	0
523	634	1422	Espagnol - CLOE (Avancé)	6	0	2026-02-03 15:40:08.121815+01	2026-02-03 15:40:08.121816+01	0
524	634	1423	Espagnol - CLOE (Avancé)	6	0	2026-02-03 15:40:08.121817+01	2026-02-03 15:40:08.121817+01	0
525	635	1453	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.121818+01	2026-02-03 15:40:08.121818+01	0
526	635	1454	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.121819+01	2026-02-03 15:40:08.121819+01	0
527	636	1461	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.12182+01	2026-02-03 15:40:08.12182+01	0
528	636	1462	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.121821+01	2026-02-03 15:40:08.121821+01	0
529	637	1464	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.121822+01	2026-02-03 15:40:08.121822+01	0
530	637	1465	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.121823+01	2026-02-03 15:40:08.121823+01	0
531	640	1470	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.121824+01	2026-02-03 15:40:08.121824+01	0
532	640	1471	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.121825+01	2026-02-03 15:40:08.121825+01	0
533	641	1472	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.121826+01	2026-02-03 15:40:08.121826+01	0
534	641	1473	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:08.121827+01	2026-02-03 15:40:08.121827+01	0
535	643	1432	Bilan de compétences (6h)	6	0	2026-02-03 15:40:08.121828+01	2026-02-03 15:40:08.121828+01	0
536	645	1434	[TP SC] - Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121829+01	2026-02-03 15:40:08.12183+01	0
537	645	1435	[TP SC] - Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.12183+01	2026-02-03 15:40:08.121831+01	0
538	646	1436	[TP SC] - Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.121831+01	2026-02-03 15:40:08.121832+01	0
539	646	1437	[TP SC] - Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.121832+01	2026-02-03 15:40:08.121833+01	0
540	647	1438	[TP SC] - Secrétaire Comptable (Confirmé)	6	0	2026-02-03 15:40:08.121833+01	2026-02-03 15:40:08.121834+01	0
541	647	1439	[TP SC] - Secrétaire Comptable (Confirmé)	6	0	2026-02-03 15:40:08.121834+01	2026-02-03 15:40:08.121835+01	0
542	648	1442	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.121835+01	2026-02-03 15:40:08.121836+01	0
543	648	1443	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.121836+01	2026-02-03 15:40:08.121837+01	0
544	649	1444	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.121837+01	2026-02-03 15:40:08.121838+01	0
545	649	1445	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.121838+01	2026-02-03 15:40:08.121839+01	0
546	651	1447	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121839+01	2026-02-03 15:40:08.12184+01	0
547	651	1448	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.12184+01	2026-02-03 15:40:08.121841+01	0
548	654	1474	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121841+01	2026-02-03 15:40:08.121842+01	0
549	654	1475	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121842+01	2026-02-03 15:40:08.121843+01	0
550	655	1476	[TP SC] Secrétaire Comptable (Expert)	6	0	2026-02-03 15:40:08.121843+01	2026-02-03 15:40:08.121844+01	0
551	655	1477	[TP SC] Secrétaire Comptable (Expert)	6	0	2026-02-03 15:40:08.121844+01	2026-02-03 15:40:08.121845+01	0
552	656	1478	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121846+01	2026-02-03 15:40:08.121846+01	0
553	656	1479	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121847+01	2026-02-03 15:40:08.121847+01	0
554	657	1480	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121848+01	2026-02-03 15:40:08.121848+01	0
555	657	1481	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121849+01	2026-02-03 15:40:08.121849+01	0
556	659	1484	[TP SC] Secrétaire Comptable (Expert)	6	0	2026-02-03 15:40:08.12185+01	2026-02-03 15:40:08.12185+01	0
557	659	1485	[TP SC] Secrétaire Comptable (Expert)	6	0	2026-02-03 15:40:08.121851+01	2026-02-03 15:40:08.121851+01	0
558	660	1486	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121852+01	2026-02-03 15:40:08.121852+01	0
559	660	1487	[TP SC] Secrétaire Comptable (Avancé)	6	0	2026-02-03 15:40:08.121853+01	2026-02-03 15:40:08.121853+01	0
560	661	1490	Espagnol - CLOE (Expert) - Bernard Beaupuy	6	0	2026-02-03 15:40:08.121854+01	2026-02-03 15:40:08.121854+01	0
561	661	1491	Espagnol - CLOE (Expert) - Bernard Beaupuy	6	0	2026-02-03 15:40:08.121855+01	2026-02-03 15:40:08.121855+01	0
562	664	1500	[TP SAMS] Classes Virtuelles Individuelles 8h (TELLA Emilie)	6	0	2026-02-03 15:40:08.121856+01	2026-02-03 15:40:08.121856+01	0
563	664	1494	[TP SAMS] Classes Virtuelles Individuelles 8h (TELLA Emilie)	6	0	2026-02-03 15:40:08.121857+01	2026-02-03 15:40:08.121857+01	0
564	664	1495	[TP SAMS] Classes Virtuelles Individuelles 8h (TELLA Emilie)	6	0	2026-02-03 15:40:08.121858+01	2026-02-03 15:40:08.121859+01	0
565	664	1496	[TP SAMS] Classes Virtuelles Individuelles 8h (TELLA Emilie)	6	0	2026-02-03 15:40:08.121859+01	2026-02-03 15:40:08.12186+01	0
566	664	1497	[TP SAMS] Classes Virtuelles Individuelles 8h (TELLA Emilie)	6	0	2026-02-03 15:40:08.12186+01	2026-02-03 15:40:08.121861+01	0
567	664	1498	[TP SAMS] Classes Virtuelles Individuelles 8h (TELLA Emilie)	6	0	2026-02-03 15:40:08.121861+01	2026-02-03 15:40:08.121862+01	0
568	664	1499	[TP SAMS] Classes Virtuelles Individuelles 8h (TELLA Emilie)	6	0	2026-02-03 15:40:08.121862+01	2026-02-03 15:40:08.121863+01	0
569	666	2238	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121863+01	2026-02-03 15:40:08.121864+01	0
570	666	1690	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121864+01	2026-02-03 15:40:08.121865+01	0
571	666	1723	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121865+01	2026-02-03 15:40:08.121866+01	0
572	666	1724	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121866+01	2026-02-03 15:40:08.121867+01	0
573	666	1689	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121867+01	2026-02-03 15:40:08.121868+01	0
574	666	1691	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121868+01	2026-02-03 15:40:08.121869+01	0
575	666	1692	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121869+01	2026-02-03 15:40:08.12187+01	0
576	666	1693	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.12187+01	2026-02-03 15:40:08.121871+01	0
577	666	1694	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121871+01	2026-02-03 15:40:08.121872+01	0
578	666	1695	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121872+01	2026-02-03 15:40:08.121873+01	0
579	666	1696	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121873+01	2026-02-03 15:40:08.121874+01	0
580	666	1726	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121875+01	2026-02-03 15:40:08.121875+01	0
581	666	1718	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121876+01	2026-02-03 15:40:08.121876+01	0
582	666	1719	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121877+01	2026-02-03 15:40:08.121877+01	0
583	666	1720	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121878+01	2026-02-03 15:40:08.121878+01	0
584	666	1721	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121879+01	2026-02-03 15:40:08.121879+01	0
585	666	1722	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.12188+01	2026-02-03 15:40:08.12188+01	0
586	666	1697	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121881+01	2026-02-03 15:40:08.121881+01	0
587	666	1725	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121882+01	2026-02-03 15:40:08.121882+01	0
588	666	1678	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121883+01	2026-02-03 15:40:08.121883+01	0
589	666	1679	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121884+01	2026-02-03 15:40:08.121884+01	0
590	666	1680	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121885+01	2026-02-03 15:40:08.121885+01	0
591	666	1681	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121886+01	2026-02-03 15:40:08.121886+01	0
592	666	1682	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121887+01	2026-02-03 15:40:08.121887+01	0
593	666	1683	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121888+01	2026-02-03 15:40:08.121888+01	0
594	666	1684	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121889+01	2026-02-03 15:40:08.121889+01	0
595	666	1698	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.12189+01	2026-02-03 15:40:08.12189+01	0
596	666	1685	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121891+01	2026-02-03 15:40:08.121891+01	0
597	666	1686	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121892+01	2026-02-03 15:40:08.121892+01	0
598	666	1687	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121893+01	2026-02-03 15:40:08.121893+01	0
599	666	1688	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121894+01	2026-02-03 15:40:08.121894+01	0
600	666	1699	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121895+01	2026-02-03 15:40:08.121895+01	0
601	666	1700	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121896+01	2026-02-03 15:40:08.121896+01	0
602	666	1701	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121897+01	2026-02-03 15:40:08.121898+01	0
603	666	1702	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121898+01	2026-02-03 15:40:08.121899+01	0
604	666	1703	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121899+01	2026-02-03 15:40:08.1219+01	0
605	666	1704	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.1219+01	2026-02-03 15:40:08.121901+01	0
606	666	1705	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121901+01	2026-02-03 15:40:08.121902+01	0
607	666	1706	SESSION 8 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.121902+01	2026-02-03 15:40:08.121903+01	0
608	668	1599	[TP SC] Secrétaire Comptable (Confirmé)	6	0	2026-02-03 15:40:08.121903+01	2026-02-03 15:40:08.121904+01	0
609	668	1600	[TP SC] Secrétaire Comptable (Confirmé)	6	0	2026-02-03 15:40:08.121904+01	2026-02-03 15:40:08.121905+01	0
610	669	1603	[TP SC] Secrétaire Comptable (Expert)	6	0	2026-02-03 15:40:08.121905+01	2026-02-03 15:40:08.121906+01	0
611	669	1604	[TP SC] Secrétaire Comptable (Expert)	6	0	2026-02-03 15:40:08.121906+01	2026-02-03 15:40:08.121907+01	0
612	676	1613	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.121907+01	2026-02-03 15:40:08.121908+01	0
613	676	1614	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.121908+01	2026-02-03 15:40:08.121909+01	0
614	686	1728	[TP SAMS] Classes Virtuelles Individuelles 4h	6	0	2026-02-03 15:40:08.137284+01	2026-02-03 15:40:08.137287+01	0
615	687	1729	[TP SAMS] Classes Virtuelles Individuelles 4h	6	0	2026-02-03 15:40:08.137288+01	2026-02-03 15:40:08.137288+01	0
616	688	1730	[TP SAMS] Classes Virtuelles Individuelles 2h	6	0	2026-02-03 15:40:08.137289+01	2026-02-03 15:40:08.137289+01	0
617	689	1731	[TP SAMS] Classes Virtuelles Individuelles 2h	6	0	2026-02-03 15:40:08.13729+01	2026-02-03 15:40:08.13729+01	0
618	690	1732	[TP SAMS] Classes Virtuelles Individuelles 8h	6	0	2026-02-03 15:40:08.137291+01	2026-02-03 15:40:08.137291+01	0
619	692	1734	[TP SAMS] Classes Virtuelles Individuelles 4h	6	0	2026-02-03 15:40:08.137292+01	2026-02-03 15:40:08.137293+01	0
620	693	1735	[TP SAMS] Classes Virtuelles Individuelles 4h	6	0	2026-02-03 15:40:08.137293+01	2026-02-03 15:40:08.137294+01	0
621	694	1736	[TP SAMS] Classes Virtuelles Individuelles 2h	6	0	2026-02-03 15:40:08.137294+01	2026-02-03 15:40:08.137295+01	0
622	695	1737	Microsoft Excel Niveau Avancé	6	0	2026-02-03 15:40:08.137295+01	2026-02-03 15:40:08.137296+01	0
623	696	1738	[EXCEL] Cours Particuliers	6	0	2026-02-03 15:40:08.137296+01	2026-02-03 15:40:08.137297+01	0
624	699	1741	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.137297+01	2026-02-03 15:40:08.137298+01	0
625	699	1742	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.137298+01	2026-02-03 15:40:08.137299+01	0
626	700	1743	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.1373+01	2026-02-03 15:40:08.1373+01	0
627	706	1759	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.137301+01	2026-02-03 15:40:08.137301+01	0
628	708	1772	TP - Secrétaire Assistant Médico-Social - LEDOUX Sonia	6	0	2026-02-03 15:40:08.137302+01	2026-02-03 15:40:08.137302+01	0
629	715	1779	[TP SC] Classes Virtuelles (Standard)	6	0	2026-02-03 15:40:08.137303+01	2026-02-03 15:40:08.137303+01	0
630	718	1782	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.137304+01	2026-02-03 15:40:08.137304+01	0
631	724	1788	[TP EAA] Employé administratif et d'accueil (Expert)	5	0	2026-02-03 15:40:08.137305+01	2026-02-03 15:40:08.137305+01	0
632	724	1789	[TP EAA] Employé administratif et d'accueil (Expert)	5	0	2026-02-03 15:40:08.137306+01	2026-02-03 15:40:08.137306+01	0
633	735	1800	[TP SAMS] -  CV 14 : Les relations avec les partenaires externes et les autorités compétentes (assurance maladie, tutelles, etc.)	6	0	2026-02-03 15:40:08.137307+01	2026-02-03 15:40:08.137307+01	0
634	737	1805	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.160628+01	2026-02-03 15:40:08.160631+01	0
635	751	1821	[TP SAMS] Classes Virtuelles Individuelles 2h (Johanna PIOU)	6	0	2026-02-03 15:40:08.160632+01	2026-02-03 15:40:08.160633+01	0
636	751	1822	[TP SAMS] Classes Virtuelles Individuelles 2h (Johanna PIOU)	6	0	2026-02-03 15:40:08.160633+01	2026-02-03 15:40:08.160634+01	0
637	751	1823	[TP SAMS] Classes Virtuelles Individuelles 2h (Johanna PIOU)	6	0	2026-02-03 15:40:08.160634+01	2026-02-03 15:40:08.160635+01	0
638	751	1824	[TP SAMS] Classes Virtuelles Individuelles 2h (Johanna PIOU)	6	0	2026-02-03 15:40:08.160635+01	2026-02-03 15:40:08.160636+01	0
639	751	1819	[TP SAMS] Classes Virtuelles Individuelles 2h (Johanna PIOU)	6	0	2026-02-03 15:40:08.160636+01	2026-02-03 15:40:08.160637+01	0
640	751	1820	[TP SAMS] Classes Virtuelles Individuelles 2h (Johanna PIOU)	6	0	2026-02-03 15:40:08.160637+01	2026-02-03 15:40:08.160638+01	0
641	751	1825	[TP SAMS] Classes Virtuelles Individuelles 2h (Johanna PIOU)	6	0	2026-02-03 15:40:08.160638+01	2026-02-03 15:40:08.160639+01	0
642	753	1827	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.160639+01	2026-02-03 15:40:08.16064+01	0
643	757	1834	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.16064+01	2026-02-03 15:40:08.160641+01	0
644	763	1840	Bilan de compétences (8h) - PASSAT Mattéo	6	0	2026-02-03 15:40:08.160641+01	2026-02-03 15:40:08.160642+01	0
645	768	1846	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.160642+01	2026-02-03 15:40:08.160643+01	0
646	769	1847	Bilan de compétences (10h)	6	0	2026-02-03 15:40:08.160644+01	2026-02-03 15:40:08.160644+01	0
647	770	1848	Bilan de compétences (8h)	6	0	2026-02-03 15:40:08.160645+01	2026-02-03 15:40:08.160645+01	0
648	773	1852	[TP SAMS] Classes Virtuelles Individuelles (Odile GRENETIER)	6	0	2026-02-03 15:40:08.160646+01	2026-02-03 15:40:08.160646+01	0
649	773	1853	[TP SAMS] Classes Virtuelles Individuelles (Odile GRENETIER)	6	0	2026-02-03 15:40:08.160647+01	2026-02-03 15:40:08.160647+01	0
650	773	1854	[TP SAMS] Classes Virtuelles Individuelles (Odile GRENETIER)	6	0	2026-02-03 15:40:08.160648+01	2026-02-03 15:40:08.160648+01	0
651	773	1855	[TP SAMS] Classes Virtuelles Individuelles (Odile GRENETIER)	6	0	2026-02-03 15:40:08.160649+01	2026-02-03 15:40:08.160649+01	0
652	773	1856	[TP SAMS] Classes Virtuelles Individuelles (Odile GRENETIER)	6	0	2026-02-03 15:40:08.16065+01	2026-02-03 15:40:08.16065+01	0
653	773	1857	[TP SAMS] Classes Virtuelles Individuelles (Odile GRENETIER)	6	0	2026-02-03 15:40:08.160651+01	2026-02-03 15:40:08.160651+01	0
654	773	1851	[TP SAMS] Classes Virtuelles Individuelles (Odile GRENETIER)	6	0	2026-02-03 15:40:08.160652+01	2026-02-03 15:40:08.160653+01	0
655	783	1869	[TP SAMS] Classes Virtuelles Individuelles 2h (Laetitia DESPINOY)	6	0	2026-02-03 15:40:08.160653+01	2026-02-03 15:40:08.160654+01	0
656	783	1870	[TP SAMS] Classes Virtuelles Individuelles 2h (Laetitia DESPINOY)	6	0	2026-02-03 15:40:08.160654+01	2026-02-03 15:40:08.160655+01	0
657	783	1871	[TP SAMS] Classes Virtuelles Individuelles 2h (Laetitia DESPINOY)	6	0	2026-02-03 15:40:08.160655+01	2026-02-03 15:40:08.160656+01	0
658	783	1872	[TP SAMS] Classes Virtuelles Individuelles 2h (Laetitia DESPINOY)	6	0	2026-02-03 15:40:08.160656+01	2026-02-03 15:40:08.160657+01	0
659	783	1873	[TP SAMS] Classes Virtuelles Individuelles 2h (Laetitia DESPINOY)	6	0	2026-02-03 15:40:08.160657+01	2026-02-03 15:40:08.160658+01	0
660	783	1874	[TP SAMS] Classes Virtuelles Individuelles 2h (Laetitia DESPINOY)	6	0	2026-02-03 15:40:08.160658+01	2026-02-03 15:40:08.160659+01	0
661	783	1875	[TP SAMS] Classes Virtuelles Individuelles 2h (Laetitia DESPINOY)	6	0	2026-02-03 15:40:08.160659+01	2026-02-03 15:40:08.16066+01	0
662	786	1881	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.16066+01	2026-02-03 15:40:08.160661+01	0
663	786	1882	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.160661+01	2026-02-03 15:40:08.160662+01	0
664	786	1883	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.160662+01	2026-02-03 15:40:08.160663+01	0
665	786	1884	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.160663+01	2026-02-03 15:40:08.160664+01	0
666	786	1885	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.160664+01	2026-02-03 15:40:08.160665+01	0
667	786	1886	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.160665+01	2026-02-03 15:40:08.160666+01	0
668	786	1887	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.160666+01	2026-02-03 15:40:08.160667+01	0
669	786	1888	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.160667+01	2026-02-03 15:40:08.160668+01	0
670	786	1889	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.160669+01	2026-02-03 15:40:08.160669+01	0
671	786	1890	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.16067+01	2026-02-03 15:40:08.16067+01	0
672	786	1891	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.160671+01	2026-02-03 15:40:08.160671+01	0
673	790	1909	[TP SAMS] Classes Virtuelles Individuelles 8h (Adelaide Morandat)	6	0	2026-02-03 15:40:08.160672+01	2026-02-03 15:40:08.160672+01	0
674	790	1910	[TP SAMS] Classes Virtuelles Individuelles 8h (Adelaide Morandat)	6	0	2026-02-03 15:40:08.160673+01	2026-02-03 15:40:08.160673+01	0
675	790	1911	[TP SAMS] Classes Virtuelles Individuelles 8h (Adelaide Morandat)	6	0	2026-02-03 15:40:08.160674+01	2026-02-03 15:40:08.160674+01	0
676	790	1912	[TP SAMS] Classes Virtuelles Individuelles 8h (Adelaide Morandat)	6	0	2026-02-03 15:40:08.160675+01	2026-02-03 15:40:08.160675+01	0
677	790	1913	[TP SAMS] Classes Virtuelles Individuelles 8h (Adelaide Morandat)	6	0	2026-02-03 15:40:08.160676+01	2026-02-03 15:40:08.160676+01	0
678	790	1914	[TP SAMS] Classes Virtuelles Individuelles 8h (Adelaide Morandat)	6	0	2026-02-03 15:40:08.160677+01	2026-02-03 15:40:08.160677+01	0
679	790	1915	[TP SAMS] Classes Virtuelles Individuelles 8h (Adelaide Morandat)	6	0	2026-02-03 15:40:08.160678+01	2026-02-03 15:40:08.160678+01	0
680	794	1930	Réaliser les opérations comptables courantes d'une TPE (OCT 2025 - FEVR 2026)	6	0	2026-02-03 15:40:08.180353+01	2026-02-03 15:40:08.180356+01	0
681	794	2305	Réaliser les opérations comptables courantes d'une TPE (OCT 2025 - FEVR 2026)	6	0	2026-02-03 15:40:08.180357+01	2026-02-03 15:40:08.180357+01	0
682	794	2306	Réaliser les opérations comptables courantes d'une TPE (OCT 2025 - FEVR 2026)	6	0	2026-02-03 15:40:08.180358+01	2026-02-03 15:40:08.180358+01	0
683	794	2307	Réaliser les opérations comptables courantes d'une TPE (OCT 2025 - FEVR 2026)	6	0	2026-02-03 15:40:08.180359+01	2026-02-03 15:40:08.180359+01	0
684	794	2308	Réaliser les opérations comptables courantes d'une TPE (OCT 2025 - FEVR 2026)	6	0	2026-02-03 15:40:08.18036+01	2026-02-03 15:40:08.18036+01	0
685	794	2309	Réaliser les opérations comptables courantes d'une TPE (OCT 2025 - FEVR 2026)	6	0	2026-02-03 15:40:08.180361+01	2026-02-03 15:40:08.180361+01	0
686	794	2310	Réaliser les opérations comptables courantes d'une TPE (OCT 2025 - FEVR 2026)	6	0	2026-02-03 15:40:08.180362+01	2026-02-03 15:40:08.180362+01	0
687	794	2315	Réaliser les opérations comptables courantes d'une TPE (OCT 2025 - FEVR 2026)	6	0	2026-02-03 15:40:08.180363+01	2026-02-03 15:40:08.180363+01	0
688	794	2528	Réaliser les opérations comptables courantes d'une TPE (OCT 2025 - FEVR 2026)	6	0	2026-02-03 15:40:08.180364+01	2026-02-03 15:40:08.180365+01	0
689	800	1942	[TP SAMS] Classes Virtuelles Individuelles 6h (Karen Vidra Podwojny)	6	0	2026-02-03 15:40:08.180365+01	2026-02-03 15:40:08.180366+01	0
690	800	1943	[TP SAMS] Classes Virtuelles Individuelles 6h (Karen Vidra Podwojny)	6	0	2026-02-03 15:40:08.180366+01	2026-02-03 15:40:08.180367+01	0
691	800	1944	[TP SAMS] Classes Virtuelles Individuelles 6h (Karen Vidra Podwojny)	6	0	2026-02-03 15:40:08.180368+01	2026-02-03 15:40:08.180368+01	0
692	800	1945	[TP SAMS] Classes Virtuelles Individuelles 6h (Karen Vidra Podwojny)	6	0	2026-02-03 15:40:08.180369+01	2026-02-03 15:40:08.180369+01	0
693	800	1946	[TP SAMS] Classes Virtuelles Individuelles 6h (Karen Vidra Podwojny)	6	0	2026-02-03 15:40:08.18037+01	2026-02-03 15:40:08.18037+01	0
694	800	1947	[TP SAMS] Classes Virtuelles Individuelles 6h (Karen Vidra Podwojny)	6	0	2026-02-03 15:40:08.180371+01	2026-02-03 15:40:08.180371+01	0
695	800	1948	[TP SAMS] Classes Virtuelles Individuelles 6h (Karen Vidra Podwojny)	6	0	2026-02-03 15:40:08.180372+01	2026-02-03 15:40:08.180372+01	0
696	801	1949	[TP SAMS] Classes Virtuelles Individuelles 8h	6	0	2026-02-03 15:40:08.180373+01	2026-02-03 15:40:08.180373+01	0
697	801	1950	[TP SAMS] Classes Virtuelles Individuelles 8h	6	0	2026-02-03 15:40:08.180374+01	2026-02-03 15:40:08.180374+01	0
698	801	1951	[TP SAMS] Classes Virtuelles Individuelles 8h	6	0	2026-02-03 15:40:08.180375+01	2026-02-03 15:40:08.180375+01	0
699	801	1952	[TP SAMS] Classes Virtuelles Individuelles 8h	6	0	2026-02-03 15:40:08.180376+01	2026-02-03 15:40:08.180376+01	0
700	801	1953	[TP SAMS] Classes Virtuelles Individuelles 8h	6	0	2026-02-03 15:40:08.180377+01	2026-02-03 15:40:08.180377+01	0
701	801	1954	[TP SAMS] Classes Virtuelles Individuelles 8h	6	0	2026-02-03 15:40:08.180378+01	2026-02-03 15:40:08.180378+01	0
702	801	1955	[TP SAMS] Classes Virtuelles Individuelles 8h	6	0	2026-02-03 15:40:08.180379+01	2026-02-03 15:40:08.180379+01	0
703	811	1965	[TP EAA] Employé administratif et d'accueil (Julie Lenz)	6	0	2026-02-03 15:40:08.18038+01	2026-02-03 15:40:08.18038+01	0
704	811	1966	[TP EAA] Employé administratif et d'accueil (Julie Lenz)	6	0	2026-02-03 15:40:08.180381+01	2026-02-03 15:40:08.180382+01	0
705	822	1980	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.180382+01	2026-02-03 15:40:08.180383+01	0
706	824	1982	Prise de parole en public : devenir un bon orateur (AOUT - DEC 2025)	6	0	2026-02-03 15:40:08.180383+01	2026-02-03 15:40:08.180384+01	0
707	824	1983	Prise de parole en public : devenir un bon orateur (AOUT - DEC 2025)	6	0	2026-02-03 15:40:08.180384+01	2026-02-03 15:40:08.180385+01	0
708	824	1984	Prise de parole en public : devenir un bon orateur (AOUT - DEC 2025)	6	0	2026-02-03 15:40:08.180385+01	2026-02-03 15:40:08.180386+01	0
709	831	2000	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.180386+01	2026-02-03 15:40:08.180387+01	0
710	833	2003	[TP ARH] Assitant Ressources Humaines - CLAEYS Géraldine	6	0	2026-02-03 15:40:08.180388+01	2026-02-03 15:40:08.180388+01	0
711	833	2002	[TP ARH] Assitant Ressources Humaines - CLAEYS Géraldine	6	0	2026-02-03 15:40:08.180389+01	2026-02-03 15:40:08.180389+01	0
712	842	2015	Test Audit energie	6	0	2026-02-03 15:40:08.18039+01	2026-02-03 15:40:08.18039+01	0
713	843	2016	Bilan de compétences (15h) - BLANGIS Eléonore	6	0	2026-02-03 15:40:08.180391+01	2026-02-03 15:40:08.180391+01	0
714	845	2018	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.180392+01	2026-02-03 15:40:08.180392+01	0
715	855	2028	Bilan de compétences (18h)	6	0	2026-02-03 15:40:08.188296+01	2026-02-03 15:40:08.188299+01	0
716	860	2033	Bilan de compétences (9h)	6	0	2026-02-03 15:40:08.1883+01	2026-02-03 15:40:08.188301+01	0
717	861	2034	[TP SAMS] Classes Virtuelles Individuelles 8h	6	0	2026-02-03 15:40:08.188301+01	2026-02-03 15:40:08.188302+01	0
718	865	2038	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.188302+01	2026-02-03 15:40:08.188303+01	0
719	869	2042	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.188303+01	2026-02-03 15:40:08.188304+01	0
720	878	2057	Bilan de compétences (15h)	6	0	2026-02-03 15:40:08.188304+01	2026-02-03 15:40:08.188305+01	0
721	889	2067	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.188305+01	2026-02-03 15:40:08.188306+01	0
722	890	2068	Bilan de compétences (15h) LAFARGUE Baptiste	6	0	2026-02-03 15:40:08.188306+01	2026-02-03 15:40:08.188307+01	0
723	900	2078	Bilan de compétences (15h)	6	0	2026-02-03 15:40:08.188308+01	2026-02-03 15:40:08.188308+01	0
724	901	2079	Bilan de compétences (16h)	6	0	2026-02-03 15:40:08.188309+01	2026-02-03 15:40:08.188309+01	0
725	907	2133	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249905+01	2026-02-03 15:40:08.249908+01	0
726	907	2134	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249909+01	2026-02-03 15:40:08.24991+01	0
727	907	2135	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.24991+01	2026-02-03 15:40:08.249911+01	0
728	907	2136	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249911+01	2026-02-03 15:40:08.249912+01	0
729	907	2137	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249912+01	2026-02-03 15:40:08.249913+01	0
730	907	2138	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249913+01	2026-02-03 15:40:08.249914+01	0
731	907	2139	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249914+01	2026-02-03 15:40:08.249915+01	0
732	907	2140	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249916+01	2026-02-03 15:40:08.249916+01	0
733	907	2151	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249917+01	2026-02-03 15:40:08.249917+01	0
734	907	2152	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249918+01	2026-02-03 15:40:08.249918+01	0
735	907	2153	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249919+01	2026-02-03 15:40:08.249919+01	0
736	907	2154	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.24992+01	2026-02-03 15:40:08.24992+01	0
737	907	2155	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249921+01	2026-02-03 15:40:08.249921+01	0
738	907	2141	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249922+01	2026-02-03 15:40:08.249922+01	0
739	907	2158	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249923+01	2026-02-03 15:40:08.249923+01	0
740	907	2159	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249924+01	2026-02-03 15:40:08.249924+01	0
741	907	2465	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249925+01	2026-02-03 15:40:08.249925+01	0
742	907	2122	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249926+01	2026-02-03 15:40:08.249927+01	0
743	907	2123	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249927+01	2026-02-03 15:40:08.249928+01	0
744	907	2124	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249928+01	2026-02-03 15:40:08.249929+01	0
745	907	2125	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249929+01	2026-02-03 15:40:08.24993+01	0
746	907	2126	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.24993+01	2026-02-03 15:40:08.249931+01	0
747	907	2127	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249931+01	2026-02-03 15:40:08.249932+01	0
748	907	2128	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249932+01	2026-02-03 15:40:08.249933+01	0
749	907	2142	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249933+01	2026-02-03 15:40:08.249934+01	0
750	907	2129	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249934+01	2026-02-03 15:40:08.249935+01	0
751	907	2130	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249935+01	2026-02-03 15:40:08.249936+01	0
752	907	2131	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249936+01	2026-02-03 15:40:08.249937+01	0
753	907	2132	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249937+01	2026-02-03 15:40:08.249938+01	0
754	907	2468	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249938+01	2026-02-03 15:40:08.249939+01	0
755	907	2143	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.24994+01	2026-02-03 15:40:08.24994+01	0
756	907	2144	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249941+01	2026-02-03 15:40:08.249941+01	0
757	907	2145	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249942+01	2026-02-03 15:40:08.249942+01	0
758	907	2146	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249943+01	2026-02-03 15:40:08.249943+01	0
759	907	2147	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249944+01	2026-02-03 15:40:08.249944+01	0
760	907	2148	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249945+01	2026-02-03 15:40:08.249946+01	0
761	907	2149	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249946+01	2026-02-03 15:40:08.249947+01	0
762	907	2150	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249947+01	2026-02-03 15:40:08.249948+01	0
763	907	2156	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249948+01	2026-02-03 15:40:08.249949+01	0
764	907	2157	SESSION 10 - Chef de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.249949+01	2026-02-03 15:40:08.24995+01	0
765	908	2171	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.24995+01	2026-02-03 15:40:08.249951+01	0
766	908	2172	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249951+01	2026-02-03 15:40:08.249952+01	0
767	908	2173	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249952+01	2026-02-03 15:40:08.249953+01	0
768	908	2174	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249953+01	2026-02-03 15:40:08.249954+01	0
769	908	2175	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249954+01	2026-02-03 15:40:08.249955+01	0
770	908	2176	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249955+01	2026-02-03 15:40:08.249956+01	0
771	908	2177	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249956+01	2026-02-03 15:40:08.249957+01	0
772	908	2178	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249957+01	2026-02-03 15:40:08.249958+01	0
773	908	2189	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249958+01	2026-02-03 15:40:08.249959+01	0
774	908	2190	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249959+01	2026-02-03 15:40:08.24996+01	0
775	908	2191	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.24996+01	2026-02-03 15:40:08.249961+01	0
776	908	2192	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249962+01	2026-02-03 15:40:08.249962+01	0
777	908	2193	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249963+01	2026-02-03 15:40:08.249963+01	0
778	908	2917	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249964+01	2026-02-03 15:40:08.249964+01	0
779	908	2179	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249965+01	2026-02-03 15:40:08.249965+01	0
780	908	2196	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249966+01	2026-02-03 15:40:08.249966+01	0
781	908	2160	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249967+01	2026-02-03 15:40:08.249967+01	0
844	931	2265	Bilan de compétences (15h)	6	0	2026-02-03 15:40:08.250048+01	2026-02-03 15:40:08.250049+01	0
782	908	2197	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249968+01	2026-02-03 15:40:08.249968+01	0
783	908	2161	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249969+01	2026-02-03 15:40:08.249969+01	0
784	908	2162	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.24997+01	2026-02-03 15:40:08.24997+01	0
785	908	2163	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249971+01	2026-02-03 15:40:08.249971+01	0
786	908	2164	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249972+01	2026-02-03 15:40:08.249972+01	0
787	908	2165	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249973+01	2026-02-03 15:40:08.249973+01	0
788	908	2180	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249974+01	2026-02-03 15:40:08.249974+01	0
789	908	2166	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249975+01	2026-02-03 15:40:08.249975+01	0
790	908	2924	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249976+01	2026-02-03 15:40:08.249976+01	0
791	908	2167	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249977+01	2026-02-03 15:40:08.249977+01	0
792	908	2168	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249978+01	2026-02-03 15:40:08.249978+01	0
793	908	2169	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249979+01	2026-02-03 15:40:08.249979+01	0
794	908	2170	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.24998+01	2026-02-03 15:40:08.24998+01	0
795	908	2181	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249981+01	2026-02-03 15:40:08.249981+01	0
796	908	2182	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249982+01	2026-02-03 15:40:08.249983+01	0
797	908	2183	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249983+01	2026-02-03 15:40:08.249984+01	0
798	908	2184	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249984+01	2026-02-03 15:40:08.249985+01	0
799	908	2185	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249985+01	2026-02-03 15:40:08.249986+01	0
800	908	2186	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249986+01	2026-02-03 15:40:08.249987+01	0
801	908	2187	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249987+01	2026-02-03 15:40:08.249988+01	0
802	908	2188	SESSION 11 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249988+01	2026-02-03 15:40:08.249989+01	0
803	909	2209	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249989+01	2026-02-03 15:40:08.24999+01	0
804	909	2210	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.24999+01	2026-02-03 15:40:08.249991+01	0
805	909	2211	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249991+01	2026-02-03 15:40:08.249992+01	0
806	909	2212	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249992+01	2026-02-03 15:40:08.249993+01	0
807	909	2213	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249993+01	2026-02-03 15:40:08.249994+01	0
808	909	2214	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249995+01	2026-02-03 15:40:08.249995+01	0
809	909	2215	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249996+01	2026-02-03 15:40:08.249996+01	0
810	909	2216	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249997+01	2026-02-03 15:40:08.249997+01	0
811	909	2227	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249998+01	2026-02-03 15:40:08.249998+01	0
812	909	2228	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.249999+01	2026-02-03 15:40:08.249999+01	0
813	909	2229	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.25+01	2026-02-03 15:40:08.25+01	0
814	909	2230	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250001+01	2026-02-03 15:40:08.250001+01	0
815	909	2231	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250002+01	2026-02-03 15:40:08.250002+01	0
816	909	2217	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250003+01	2026-02-03 15:40:08.250003+01	0
817	909	2234	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250004+01	2026-02-03 15:40:08.250005+01	0
818	909	2923	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250005+01	2026-02-03 15:40:08.250006+01	0
819	909	2235	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250006+01	2026-02-03 15:40:08.250007+01	0
820	909	2198	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250007+01	2026-02-03 15:40:08.250008+01	0
821	909	2199	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250008+01	2026-02-03 15:40:08.250009+01	0
822	909	2200	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250009+01	2026-02-03 15:40:08.25001+01	0
823	909	2201	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.25001+01	2026-02-03 15:40:08.250011+01	0
824	909	2202	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250011+01	2026-02-03 15:40:08.250012+01	0
825	909	2203	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250012+01	2026-02-03 15:40:08.250013+01	0
826	909	2204	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250013+01	2026-02-03 15:40:08.250014+01	0
827	909	2218	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250014+01	2026-02-03 15:40:08.250015+01	0
828	909	2205	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250015+01	2026-02-03 15:40:08.250016+01	0
829	909	2206	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250016+01	2026-02-03 15:40:08.250017+01	0
830	909	2207	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250017+01	2026-02-03 15:40:08.250018+01	0
831	909	2208	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250019+01	2026-02-03 15:40:08.25002+01	0
832	909	2219	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.25002+01	2026-02-03 15:40:08.250021+01	0
833	909	2220	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250022+01	2026-02-03 15:40:08.250022+01	0
834	909	2221	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250023+01	2026-02-03 15:40:08.250024+01	0
835	909	2222	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250025+01	2026-02-03 15:40:08.250026+01	0
836	909	2223	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250027+01	2026-02-03 15:40:08.250027+01	0
837	909	2224	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250028+01	2026-02-03 15:40:08.250029+01	0
838	909	2225	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.25003+01	2026-02-03 15:40:08.25003+01	0
839	909	2226	SESSION 12 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.250031+01	2026-02-03 15:40:08.250032+01	0
840	915	2243	Bilan de compétences (15h)	6	0	2026-02-03 15:40:08.250033+01	2026-02-03 15:40:08.250034+01	0
841	919	2247	Bilan de compétences (6h)	6	0	2026-02-03 15:40:08.250035+01	2026-02-03 15:40:08.250035+01	0
842	930	2263	[TP ARH] Assitant Ressources Humaines	6	0	2026-02-03 15:40:08.250036+01	2026-02-03 15:40:08.250037+01	0
843	930	2264	[TP ARH] Assitant Ressources Humaines	6	0	2026-02-03 15:40:08.250046+01	2026-02-03 15:40:08.250047+01	0
845	932	2266	Anglais - Société AU VERT ET PLUS (Fleuriste)	6	0	2026-02-03 15:40:08.250049+01	2026-02-03 15:40:08.25005+01	0
846	934	2268	Bilan de compétences (9h)	6	0	2026-02-03 15:40:08.25005+01	2026-02-03 15:40:08.250051+01	0
847	938	2272	Bilan de compétences (15h)	6	0	2026-02-03 15:40:08.250051+01	2026-02-03 15:40:08.250052+01	0
848	943	2278	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.250052+01	2026-02-03 15:40:08.250053+01	0
849	947	2294	[TP ARH] Assitant Ressources Humaines	6	0	2026-02-03 15:40:08.250053+01	2026-02-03 15:40:08.250054+01	0
850	947	2295	[TP ARH] Assitant Ressources Humaines	6	0	2026-02-03 15:40:08.250055+01	2026-02-03 15:40:08.250055+01	0
851	955	2303	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.250056+01	2026-02-03 15:40:08.250058+01	0
852	958	2312	Test énergies	5	0	2026-02-03 15:40:08.29103+01	2026-02-03 15:40:08.291033+01	0
853	973	2328	[TP EAA] Employé administratif et d'accueil (Avancé)	6	0	2026-02-03 15:40:08.291034+01	2026-02-03 15:40:08.291034+01	0
854	973	2329	[TP EAA] Employé administratif et d'accueil (Avancé)	6	0	2026-02-03 15:40:08.291035+01	2026-02-03 15:40:08.291035+01	0
855	974	2330	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.291036+01	2026-02-03 15:40:08.291037+01	0
856	977	2333	Bilan de compétences (6h)	6	0	2026-02-03 15:40:08.291037+01	2026-02-03 15:40:08.291038+01	0
857	978	2334	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.291038+01	2026-02-03 15:40:08.291039+01	0
858	980	2336	BDC - Ateliers collectifs (NOV-DEC25)	6	0	2026-02-03 15:40:08.291039+01	2026-02-03 15:40:08.29104+01	0
859	980	2337	BDC - Ateliers collectifs (NOV-DEC25)	6	0	2026-02-03 15:40:08.29104+01	2026-02-03 15:40:08.291041+01	0
860	980	2338	BDC - Ateliers collectifs (NOV-DEC25)	6	0	2026-02-03 15:40:08.291041+01	2026-02-03 15:40:08.291042+01	0
861	980	2339	BDC - Ateliers collectifs (NOV-DEC25)	6	0	2026-02-03 15:40:08.291042+01	2026-02-03 15:40:08.291043+01	0
862	982	2341	[TP SC] Secrétaire Comptable (Expert)	6	0	2026-02-03 15:40:08.291043+01	2026-02-03 15:40:08.291044+01	0
863	982	2342	[TP SC] Secrétaire Comptable (Expert)	6	0	2026-02-03 15:40:08.291044+01	2026-02-03 15:40:08.291045+01	0
864	983	2343	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.291045+01	2026-02-03 15:40:08.291046+01	0
865	989	2349	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.291046+01	2026-02-03 15:40:08.291047+01	0
866	991	2351	[TP ARH] Assitant Ressources Humaines	6	0	2026-02-03 15:40:08.291047+01	2026-02-03 15:40:08.291048+01	0
867	991	2352	[TP ARH] Assitant Ressources Humaines	6	0	2026-02-03 15:40:08.291048+01	2026-02-03 15:40:08.291049+01	0
868	992	2353	Bilan de compétences (9h)	6	0	2026-02-03 15:40:08.291049+01	2026-02-03 15:40:08.29105+01	0
869	994	2359	Wordpress - Standard (MARSAUX Etienne 2e formation)	6	0	2026-02-03 15:40:08.29105+01	2026-02-03 15:40:08.291051+01	0
870	994	2360	Wordpress - Standard (MARSAUX Etienne 2e formation)	6	0	2026-02-03 15:40:08.291051+01	2026-02-03 15:40:08.291052+01	0
871	995	2361	Wordpress - Avancé	6	0	2026-02-03 15:40:08.291053+01	2026-02-03 15:40:08.291053+01	0
872	995	2362	Wordpress - Avancé	6	0	2026-02-03 15:40:08.291054+01	2026-02-03 15:40:08.291054+01	0
873	996	2363	Wordpress - Avancé	6	0	2026-02-03 15:40:08.291055+01	2026-02-03 15:40:08.291055+01	0
874	996	2364	Wordpress - Avancé	6	0	2026-02-03 15:40:08.291056+01	2026-02-03 15:40:08.291056+01	0
875	1001	2369	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.291057+01	2026-02-03 15:40:08.291057+01	0
876	1001	2370	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.291058+01	2026-02-03 15:40:08.291058+01	0
877	1002	2371	Anglais - CLOE (Avancé)	6	0	2026-02-03 15:40:08.291059+01	2026-02-03 15:40:08.291059+01	0
878	1003	2372	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.29106+01	2026-02-03 15:40:08.291061+01	0
879	1004	2373	Bilan de compétences (6h)	6	0	2026-02-03 15:40:08.291061+01	2026-02-03 15:40:08.291062+01	0
880	1005	2374	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291062+01	2026-02-03 15:40:08.291063+01	0
881	1005	2376	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291063+01	2026-02-03 15:40:08.291064+01	0
882	1005	2375	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291064+01	2026-02-03 15:40:08.291065+01	0
883	1005	2398	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291065+01	2026-02-03 15:40:08.291066+01	0
884	1005	2400	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291066+01	2026-02-03 15:40:08.291067+01	0
885	1005	2401	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291067+01	2026-02-03 15:40:08.291068+01	0
886	1005	2402	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291068+01	2026-02-03 15:40:08.291069+01	0
887	1005	2377	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291069+01	2026-02-03 15:40:08.29107+01	0
888	1005	2406	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.29107+01	2026-02-03 15:40:08.291071+01	0
889	1005	2405	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291072+01	2026-02-03 15:40:08.291072+01	0
890	1005	2441	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291073+01	2026-02-03 15:40:08.291073+01	0
891	1005	2454	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291074+01	2026-02-03 15:40:08.291074+01	0
892	1005	2382	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291075+01	2026-02-03 15:40:08.291075+01	0
893	1005	2380	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291076+01	2026-02-03 15:40:08.291076+01	0
894	1005	2384	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291077+01	2026-02-03 15:40:08.291077+01	0
895	1005	2386	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291078+01	2026-02-03 15:40:08.291078+01	0
896	1005	2388	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291079+01	2026-02-03 15:40:08.29108+01	0
897	1005	2378	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.29108+01	2026-02-03 15:40:08.291081+01	0
898	1005	2379	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291081+01	2026-02-03 15:40:08.291082+01	0
899	1005	2792	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291082+01	2026-02-03 15:40:08.291083+01	0
900	1005	2793	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291083+01	2026-02-03 15:40:08.291084+01	0
901	1005	2794	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291084+01	2026-02-03 15:40:08.291085+01	0
902	1005	2795	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291085+01	2026-02-03 15:40:08.291086+01	0
903	1005	2390	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291086+01	2026-02-03 15:40:08.291087+01	0
904	1005	2392	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291087+01	2026-02-03 15:40:08.291088+01	0
905	1005	2860	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291088+01	2026-02-03 15:40:08.291089+01	0
906	1005	2861	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291089+01	2026-02-03 15:40:08.29109+01	0
907	1005	2620	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.29109+01	2026-02-03 15:40:08.291091+01	0
908	1005	2429	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291091+01	2026-02-03 15:40:08.291092+01	0
909	1005	2791	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291092+01	2026-02-03 15:40:08.291093+01	0
910	1005	2790	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291093+01	2026-02-03 15:40:08.291094+01	0
911	1005	2796	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291094+01	2026-02-03 15:40:08.291095+01	0
912	1005	2381	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291096+01	2026-02-03 15:40:08.291096+01	0
913	1005	3654	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291097+01	2026-02-03 15:40:08.291097+01	0
914	1005	2383	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291098+01	2026-02-03 15:40:08.291098+01	0
915	1005	2385	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291099+01	2026-02-03 15:40:08.291099+01	0
916	1005	3687	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.2911+01	2026-02-03 15:40:08.2911+01	0
917	1005	3688	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291101+01	2026-02-03 15:40:08.291101+01	0
918	1005	2387	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291102+01	2026-02-03 15:40:08.291102+01	0
919	1005	2389	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291103+01	2026-02-03 15:40:08.291103+01	0
920	1005	2391	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291104+01	2026-02-03 15:40:08.291104+01	0
921	1005	2393	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291105+01	2026-02-03 15:40:08.291105+01	0
922	1005	2394	S1 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.291106+01	2026-02-03 15:40:08.291106+01	0
923	1006	2395	Bilan de compétences (12h) - RIVIERE Graziella	6	0	2026-02-03 15:40:08.291107+01	2026-02-03 15:40:08.291107+01	0
924	1009	2403	Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.309189+01	2026-02-03 15:40:08.309193+01	0
925	1014	2410	BDC - Ateliers collectifs TEST	6	0	2026-02-03 15:40:08.309193+01	2026-02-03 15:40:08.309194+01	0
926	1014	2411	BDC - Ateliers collectifs TEST	6	0	2026-02-03 15:40:08.309195+01	2026-02-03 15:40:08.309195+01	0
927	1014	2412	BDC - Ateliers collectifs TEST	6	0	2026-02-03 15:40:08.309196+01	2026-02-03 15:40:08.309196+01	0
928	1014	2413	BDC - Ateliers collectifs TEST	6	0	2026-02-03 15:40:08.309197+01	2026-02-03 15:40:08.309197+01	0
929	1015	2417	Réaliser les opérations comptables courantes d'une TPE (DEC MARS 2026)	6	0	2026-02-03 15:40:08.309198+01	2026-02-03 15:40:08.309198+01	0
930	1015	2414	Réaliser les opérations comptables courantes d'une TPE (DEC MARS 2026)	6	0	2026-02-03 15:40:08.309199+01	2026-02-03 15:40:08.309199+01	0
931	1015	2415	Réaliser les opérations comptables courantes d'une TPE (DEC MARS 2026)	6	0	2026-02-03 15:40:08.3092+01	2026-02-03 15:40:08.3092+01	0
932	1015	2416	Réaliser les opérations comptables courantes d'une TPE (DEC MARS 2026)	6	0	2026-02-03 15:40:08.309201+01	2026-02-03 15:40:08.309202+01	0
933	1015	2419	Réaliser les opérations comptables courantes d'une TPE (DEC MARS 2026)	6	0	2026-02-03 15:40:08.309202+01	2026-02-03 15:40:08.309203+01	0
934	1015	2418	Réaliser les opérations comptables courantes d'une TPE (DEC MARS 2026)	6	0	2026-02-03 15:40:08.309203+01	2026-02-03 15:40:08.309204+01	0
935	1017	2421	[TP EAA] Employé administratif et d'accueil (Avancé)	6	0	2026-02-03 15:40:08.309204+01	2026-02-03 15:40:08.309205+01	0
936	1017	2422	[TP EAA] Employé administratif et d'accueil (Avancé)	6	0	2026-02-03 15:40:08.309205+01	2026-02-03 15:40:08.309206+01	0
937	1027	2438	Bilan de compétences (12h) Axelle MARY	6	0	2026-02-03 15:40:08.309206+01	2026-02-03 15:40:08.309207+01	0
938	1031	2443	Bilan de compétences (8h) Emilie ROY	6	0	2026-02-03 15:40:08.309207+01	2026-02-03 15:40:08.309208+01	0
939	1035	2447	Bilan de compétences (6h) Apolline AGARD	6	0	2026-02-03 15:40:08.309209+01	2026-02-03 15:40:08.309209+01	0
940	1037	2449	Bilan de compétences (9h) Matthieu VAUZELLE	6	0	2026-02-03 15:40:08.30921+01	2026-02-03 15:40:08.30921+01	0
941	1039	2451	Bilan de compétences (15h) Fanny CARRE	6	0	2026-02-03 15:40:08.309211+01	2026-02-03 15:40:08.309211+01	0
942	1040	2452	Bilan de compétences (15h)	6	0	2026-02-03 15:40:08.309212+01	2026-02-03 15:40:08.309212+01	0
943	1042	2455	Bilan de compétences (9h) - VERRIER Marie-Laure	6	0	2026-02-03 15:40:08.309213+01	2026-02-03 15:40:08.309213+01	0
944	1044	2457	Bilan de compétences (12h) - LEBOUC Vincent	6	0	2026-02-03 15:40:08.309214+01	2026-02-03 15:40:08.309214+01	0
945	1045	2458	Bilan de compétences (12h) - MARGERIN Chloe	6	0	2026-02-03 15:40:08.309215+01	2026-02-03 15:40:08.309215+01	0
946	1046	2459	Test de positionnement - Diagnostiqueur(euse) Immobilier	6	0	2026-02-03 15:40:08.309216+01	2026-02-03 15:40:08.309216+01	0
947	1047	2460	Test de positionnement - Chef(fe) de Projet en Rénovation Énergétique	6	0	2026-02-03 15:40:08.309217+01	2026-02-03 15:40:08.309217+01	0
948	1049	2462	TP - Secrétaire Assistant Médico-Social - Ameline RINGOT	6	0	2026-02-03 15:40:08.309218+01	2026-02-03 15:40:08.309218+01	0
949	1050	2463	TP - Secrétaire Assistant Médico-Social - Aurélie RIDET	6	0	2026-02-03 15:40:08.309219+01	2026-02-03 15:40:08.309219+01	0
950	1051	2464	TP - Secrétaire Assistant Médico-Social - Anne TREBUTIEN	6	0	2026-02-03 15:40:08.30922+01	2026-02-03 15:40:08.30922+01	0
951	1052	2466	Bilan de compétences (15h) Ludovic SANCEY RICHARD	6	0	2026-02-03 15:40:08.309221+01	2026-02-03 15:40:08.309222+01	0
952	1062	2514	Bilan de compétences (12h) Audrey PICOUET	6	0	2026-02-03 15:40:08.354121+01	2026-02-03 15:40:08.354124+01	0
953	1063	2515	Bilan de compétences (12h) Thomas ALARD	6	0	2026-02-03 15:40:08.354125+01	2026-02-03 15:40:08.354125+01	0
954	1064	3274	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.354126+01	2026-02-03 15:40:08.354126+01	0
955	1064	2845	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.354127+01	2026-02-03 15:40:08.354127+01	0
956	1064	3275	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.354128+01	2026-02-03 15:40:08.354128+01	0
957	1064	3276	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.354129+01	2026-02-03 15:40:08.35413+01	0
958	1064	3325	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.35413+01	2026-02-03 15:40:08.354131+01	0
959	1064	2846	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.354131+01	2026-02-03 15:40:08.354132+01	0
960	1064	3521	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.354132+01	2026-02-03 15:40:08.354133+01	0
961	1064	3653	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.35414+01	2026-02-03 15:40:08.35414+01	0
962	1064	3655	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.354141+01	2026-02-03 15:40:08.354141+01	0
963	1064	3684	Formation Consultant Bilan de compétences JAN-JUIN26	6	0	2026-02-03 15:40:08.354142+01	2026-02-03 15:40:08.354143+01	0
964	1066	2518	Bilan de compétences (12h) Stéphanie VALLESPIR	6	0	2026-02-03 15:40:08.354143+01	2026-02-03 15:40:08.354144+01	0
965	1071	2524	Bilan de compétences (15h) - DESPLANCHES Elsa	6	0	2026-02-03 15:40:08.354144+01	2026-02-03 15:40:08.354145+01	0
966	1076	2530	Bilan de compétences (6h) - MARTIN Justine	6	0	2026-02-03 15:40:08.354145+01	2026-02-03 15:40:08.354146+01	0
967	1078	2532	Bilan de compétences (9h) - SIMON Camille	6	0	2026-02-03 15:40:08.354146+01	2026-02-03 15:40:08.354147+01	0
968	1079	2533	Bilan de compétences (9h) Marie CHARENTUS	6	0	2026-02-03 15:40:08.354147+01	2026-02-03 15:40:08.354148+01	0
969	1080	2534	Bilan de compétences (12h) - TOCHON Guillaume	6	0	2026-02-03 15:40:08.354148+01	2026-02-03 15:40:08.354149+01	0
970	1081	2535	Bilan de compétences (15h) Doryan GICQUELAIS	6	0	2026-02-03 15:40:08.354149+01	2026-02-03 15:40:08.35415+01	0
971	1084	2538	Bilan de compétences (6h) Johan LEFEBVRE	6	0	2026-02-03 15:40:08.35415+01	2026-02-03 15:40:08.354151+01	0
972	1088	2542	Bilan de compétences (12h) Caroline LAMOTHE	6	0	2026-02-03 15:40:08.354151+01	2026-02-03 15:40:08.354152+01	0
973	1089	2615	CP - DPE SM/AM - Novembre 2025	6	0	2026-02-03 15:40:08.354152+01	2026-02-03 15:40:08.354153+01	0
974	1089	2616	CP - DPE SM/AM - Novembre 2025	6	0	2026-02-03 15:40:08.354153+01	2026-02-03 15:40:08.354154+01	0
975	1089	2663	CP - DPE SM/AM - Novembre 2025	6	0	2026-02-03 15:40:08.354154+01	2026-02-03 15:40:08.354155+01	0
976	1089	2543	CP - DPE SM/AM - Novembre 2025	6	0	2026-02-03 15:40:08.354155+01	2026-02-03 15:40:08.354156+01	0
977	1089	2544	CP - DPE SM/AM - Novembre 2025	6	0	2026-02-03 15:40:08.354156+01	2026-02-03 15:40:08.354157+01	0
978	1090	2545	(ABANDON Consultante Sandra) BDC (9h) Bénédicte PONTENAY FONTETTE	6	0	2026-02-03 15:40:08.354157+01	2026-02-03 15:40:08.354158+01	0
979	1094	2549	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.354158+01	2026-02-03 15:40:08.354159+01	0
980	1094	2550	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.35416+01	2026-02-03 15:40:08.35416+01	0
981	1097	2553	Wordpress - Standard	6	0	2026-02-03 15:40:08.354161+01	2026-02-03 15:40:08.354161+01	0
982	1097	2554	Wordpress - Standard	6	0	2026-02-03 15:40:08.354162+01	2026-02-03 15:40:08.354162+01	0
983	1098	2555	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.354163+01	2026-02-03 15:40:08.354163+01	0
984	1098	2556	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.354164+01	2026-02-03 15:40:08.354164+01	0
985	1098	2557	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.354165+01	2026-02-03 15:40:08.354165+01	0
986	1098	2558	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.354166+01	2026-02-03 15:40:08.354166+01	0
987	1098	2559	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.354167+01	2026-02-03 15:40:08.354167+01	0
988	1098	2560	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.354168+01	2026-02-03 15:40:08.354168+01	0
989	1099	2561	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354169+01	2026-02-03 15:40:08.354169+01	0
990	1099	2562	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.35417+01	2026-02-03 15:40:08.35417+01	0
991	1099	2563	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354171+01	2026-02-03 15:40:08.354171+01	0
992	1099	2564	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354172+01	2026-02-03 15:40:08.354173+01	0
993	1099	2565	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354173+01	2026-02-03 15:40:08.354174+01	0
994	1099	2566	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354174+01	2026-02-03 15:40:08.354175+01	0
995	1099	2567	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354175+01	2026-02-03 15:40:08.354176+01	0
996	1099	2568	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354176+01	2026-02-03 15:40:08.354177+01	0
997	1099	2569	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354177+01	2026-02-03 15:40:08.354178+01	0
998	1099	2570	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354178+01	2026-02-03 15:40:08.354179+01	0
999	1099	2571	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354179+01	2026-02-03 15:40:08.35418+01	0
1000	1099	2572	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.35418+01	2026-02-03 15:40:08.354181+01	0
1001	1099	2573	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354181+01	2026-02-03 15:40:08.354182+01	0
1002	1099	2574	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354183+01	2026-02-03 15:40:08.354183+01	0
1003	1099	2575	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354184+01	2026-02-03 15:40:08.354184+01	0
1004	1099	2576	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354185+01	2026-02-03 15:40:08.354185+01	0
1005	1099	2577	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354186+01	2026-02-03 15:40:08.354186+01	0
1006	1099	2578	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354187+01	2026-02-03 15:40:08.354187+01	0
1007	1099	2579	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354188+01	2026-02-03 15:40:08.354188+01	0
1008	1099	2580	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354189+01	2026-02-03 15:40:08.354189+01	0
1009	1099	2581	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.35419+01	2026-02-03 15:40:08.354191+01	0
1010	1099	2582	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354191+01	2026-02-03 15:40:08.354192+01	0
1011	1099	2583	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354192+01	2026-02-03 15:40:08.354193+01	0
1012	1099	2584	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354193+01	2026-02-03 15:40:08.354194+01	0
1013	1099	2585	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354194+01	2026-02-03 15:40:08.354195+01	0
1014	1099	2586	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354195+01	2026-02-03 15:40:08.354196+01	0
1015	1099	2587	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354196+01	2026-02-03 15:40:08.354197+01	0
1016	1099	2588	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354198+01	2026-02-03 15:40:08.354198+01	0
1017	1099	2589	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354199+01	2026-02-03 15:40:08.354199+01	0
1018	1099	2590	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.3542+01	2026-02-03 15:40:08.3542+01	0
1019	1099	2591	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354201+01	2026-02-03 15:40:08.354201+01	0
1020	1099	2592	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354202+01	2026-02-03 15:40:08.354202+01	0
1021	1099	2593	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354203+01	2026-02-03 15:40:08.354204+01	0
1022	1099	2594	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354204+01	2026-02-03 15:40:08.354205+01	0
1023	1099	2595	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354205+01	2026-02-03 15:40:08.354206+01	0
1024	1099	2596	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354206+01	2026-02-03 15:40:08.354207+01	0
1025	1099	2597	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354207+01	2026-02-03 15:40:08.354208+01	0
1026	1099	2598	Chef de projet en Rénovation énergétique - Complet	6	0	2026-02-03 15:40:08.354208+01	2026-02-03 15:40:08.354209+01	0
1027	1100	2599	TP - Secrétaire Assistant Médico-Social Virginie HOCQ	6	0	2026-02-03 15:40:08.354209+01	2026-02-03 15:40:08.35421+01	0
1028	1101	2600	Bilan de compétences (10h) Patricia DAURIS	6	0	2026-02-03 15:40:08.35421+01	2026-02-03 15:40:08.354211+01	0
1029	1102	2601	[TP FPA] E-learning Raphael COUDRAY	6	0	2026-02-03 15:40:08.354211+01	2026-02-03 15:40:08.354212+01	0
1030	1103	2602	[TP FPA] E-learning COUDRAY Raphael	6	0	2026-02-03 15:40:08.354212+01	2026-02-03 15:40:08.354213+01	0
1031	1106	2607	Bilan de compétences (15h) - MANOURY Solange	6	0	2026-02-03 15:40:08.354214+01	2026-02-03 15:40:08.354214+01	0
1032	1107	2608	Bilan de compétences (12h) Laetitia LOPEZ	6	0	2026-02-03 15:40:08.354215+01	2026-02-03 15:40:08.354215+01	0
1033	1108	2609	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.354216+01	2026-02-03 15:40:08.354219+01	0
1034	1108	2610	[TP SC] Secrétaire Comptable (Standard)	6	0	2026-02-03 15:40:08.354219+01	2026-02-03 15:40:08.35422+01	0
1035	1111	2614	Bilan de compétences (15h) Julie DANET BUREAU	6	0	2026-02-03 15:40:08.393378+01	2026-02-03 15:40:08.393381+01	0
1036	1115	2621	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393382+01	2026-02-03 15:40:08.393383+01	0
1037	1115	2623	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393383+01	2026-02-03 15:40:08.393384+01	0
1038	1115	2642	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393384+01	2026-02-03 15:40:08.393385+01	0
1039	1115	2646	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393385+01	2026-02-03 15:40:08.393386+01	0
1040	1115	2647	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393386+01	2026-02-03 15:40:08.393387+01	0
1041	1115	2629	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393387+01	2026-02-03 15:40:08.393388+01	0
1042	1115	2650	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393389+01	2026-02-03 15:40:08.393389+01	0
1043	1115	2627	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.39339+01	2026-02-03 15:40:08.39339+01	0
1044	1115	2631	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393391+01	2026-02-03 15:40:08.393391+01	0
1045	1115	2633	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393392+01	2026-02-03 15:40:08.393392+01	0
1046	1115	2635	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393393+01	2026-02-03 15:40:08.393393+01	0
1047	1115	2639	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393394+01	2026-02-03 15:40:08.393394+01	0
1048	1115	2637	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393395+01	2026-02-03 15:40:08.393395+01	0
1049	1115	2625	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393396+01	2026-02-03 15:40:08.393396+01	0
1050	1115	2626	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393397+01	2026-02-03 15:40:08.393397+01	0
1051	1115	2667	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393398+01	2026-02-03 15:40:08.393398+01	0
1052	1115	2669	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393399+01	2026-02-03 15:40:08.393399+01	0
1053	1115	2671	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.3934+01	2026-02-03 15:40:08.393401+01	0
1054	1115	2673	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393401+01	2026-02-03 15:40:08.393402+01	0
1055	1115	2622	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393402+01	2026-02-03 15:40:08.393403+01	0
1056	1115	2643	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393403+01	2026-02-03 15:40:08.393404+01	0
1057	1115	2644	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393404+01	2026-02-03 15:40:08.393405+01	0
1058	1115	2645	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393405+01	2026-02-03 15:40:08.393406+01	0
1059	1115	2624	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393406+01	2026-02-03 15:40:08.393407+01	0
1060	1115	2651	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393407+01	2026-02-03 15:40:08.393408+01	0
1061	1115	2648	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393408+01	2026-02-03 15:40:08.393409+01	0
1062	1115	2641	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393409+01	2026-02-03 15:40:08.39341+01	0
1063	1115	2628	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.39341+01	2026-02-03 15:40:08.393411+01	0
1064	1115	2668	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393411+01	2026-02-03 15:40:08.393412+01	0
1065	1115	2670	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393413+01	2026-02-03 15:40:08.393413+01	0
1066	1115	2630	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393414+01	2026-02-03 15:40:08.393414+01	0
1067	1115	2632	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393415+01	2026-02-03 15:40:08.393415+01	0
1068	1115	2672	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393416+01	2026-02-03 15:40:08.393416+01	0
1069	1115	2634	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393417+01	2026-02-03 15:40:08.393417+01	0
1070	1115	2636	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393418+01	2026-02-03 15:40:08.393418+01	0
1071	1115	2638	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.393419+01	2026-02-03 15:40:08.393419+01	0
1072	1115	2640	S2 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.39342+01	2026-02-03 15:40:08.39342+01	0
1073	1117	2653	Bilan de compétences (15h) Sarah ZORNINGER	6	0	2026-02-03 15:40:08.393421+01	2026-02-03 15:40:08.393421+01	0
1074	1118	2654	BDC (15h) Amandine LOPEZ-GUIA (ABANDON Consultante Sandra)	6	0	2026-02-03 15:40:08.393422+01	2026-02-03 15:40:08.393422+01	0
1075	1121	2657	Bilan de compétences (9h) Emilien TESSARO	6	0	2026-02-03 15:40:08.393423+01	2026-02-03 15:40:08.393423+01	0
1076	1122	2658	Bilan de compétences (12h) Clotilde BERTRAN	6	0	2026-02-03 15:40:08.393424+01	2026-02-03 15:40:08.393425+01	0
1077	1125	2665	Bilan de compétences (12h) Yann LELOU PELLERIN	6	0	2026-02-03 15:40:08.393425+01	2026-02-03 15:40:08.393426+01	0
1078	1127	2674	Bilan de compétences (12h) Frédéric ROBERT	6	0	2026-02-03 15:40:08.393426+01	2026-02-03 15:40:08.393427+01	0
1079	1129	2679	CréActif - Formation Création d'Entreprise JAN-AVR26	6	0	2026-02-03 15:40:08.393427+01	2026-02-03 15:40:08.393428+01	0
1080	1129	2676	CréActif - Formation Création d'Entreprise JAN-AVR26	6	0	2026-02-03 15:40:08.393428+01	2026-02-03 15:40:08.393429+01	0
1081	1129	2677	CréActif - Formation Création d'Entreprise JAN-AVR26	6	0	2026-02-03 15:40:08.393429+01	2026-02-03 15:40:08.39343+01	0
1082	1129	2678	CréActif - Formation Création d'Entreprise JAN-AVR26	6	0	2026-02-03 15:40:08.39343+01	2026-02-03 15:40:08.393431+01	0
1083	1129	2680	CréActif - Formation Création d'Entreprise JAN-AVR26	6	0	2026-02-03 15:40:08.393432+01	2026-02-03 15:40:08.393432+01	0
1084	1129	2682	CréActif - Formation Création d'Entreprise JAN-AVR26	6	0	2026-02-03 15:40:08.393433+01	2026-02-03 15:40:08.393433+01	0
1085	1129	2683	CréActif - Formation Création d'Entreprise JAN-AVR26	6	0	2026-02-03 15:40:08.393434+01	2026-02-03 15:40:08.393434+01	0
1086	1129	2681	CréActif - Formation Création d'Entreprise JAN-AVR26	6	0	2026-02-03 15:40:08.393435+01	2026-02-03 15:40:08.393435+01	0
1087	1129	2684	CréActif - Formation Création d'Entreprise JAN-AVR26	6	0	2026-02-03 15:40:08.393436+01	2026-02-03 15:40:08.393436+01	0
1088	1132	2687	Bilan de compétences (9h) - BERNARD Coralie	6	0	2026-02-03 15:40:08.393437+01	2026-02-03 15:40:08.393437+01	0
1089	1133	2688	Bilan de compétences (12h) - PELISSIER Stephane	6	0	2026-02-03 15:40:08.393438+01	2026-02-03 15:40:08.393439+01	0
1090	1138	2693	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.393439+01	2026-02-03 15:40:08.39344+01	0
1091	1138	2694	[TP EAA] Employé administratif et d'accueil (Standard)	6	0	2026-02-03 15:40:08.39344+01	2026-02-03 15:40:08.393441+01	0
1092	1140	2696	Bilan de compétences (12h) Erina LEFILIATRE	6	0	2026-02-03 15:40:08.393441+01	2026-02-03 15:40:08.393442+01	0
1093	1144	2700	[TP EAA] Employé administratif et d'accueil (Expert)	6	0	2026-02-03 15:40:08.393442+01	2026-02-03 15:40:08.393443+01	0
1094	1144	2701	[TP EAA] Employé administratif et d'accueil (Expert)	6	0	2026-02-03 15:40:08.393443+01	2026-02-03 15:40:08.393444+01	0
1095	1152	2714	Bilan de compétences (9h) Uhaina HOAREAU	6	0	2026-02-03 15:40:08.393444+01	2026-02-03 15:40:08.393445+01	0
1096	1154	2716	[TP FPA] Formateur professionnel d'adultes (Standard)	6	0	2026-02-03 15:40:08.393445+01	2026-02-03 15:40:08.393446+01	0
1097	1154	2717	[TP FPA] Formateur professionnel d'adultes (Standard)	6	0	2026-02-03 15:40:08.393446+01	2026-02-03 15:40:08.393447+01	0
1098	1155	2718	[TP FPA] Formateur professionnel d'adultes (Standard)	6	0	2026-02-03 15:40:08.393447+01	2026-02-03 15:40:08.393448+01	0
1099	1155	2719	[TP FPA] Formateur professionnel d'adultes (Standard)	6	0	2026-02-03 15:40:08.393449+01	2026-02-03 15:40:08.393449+01	0
1100	1159	2723	[TP FPA] Formateur professionnel d'adultes (Avancé) - BERGOUGNOUX Michael	6	0	2026-02-03 15:40:08.39345+01	2026-02-03 15:40:08.39345+01	0
1101	1159	2724	[TP FPA] Formateur professionnel d'adultes (Avancé) - BERGOUGNOUX Michael	6	0	2026-02-03 15:40:08.393451+01	2026-02-03 15:40:08.393451+01	0
1102	1160	2725	Bilan de compétences (12h) Gilian COULON	6	0	2026-02-03 15:40:08.393452+01	2026-02-03 15:40:08.393452+01	0
1103	1161	2726	Bilan de compétences (9h) Etienne ILLIONET	6	0	2026-02-03 15:40:08.393453+01	2026-02-03 15:40:08.393454+01	0
1104	1164	2729	Bilan de compétences (15h) Stéphanie PAYET	6	0	2026-02-03 15:40:08.393454+01	2026-02-03 15:40:08.393455+01	0
1105	1165	2730	Bilan de compétences (12h) Cyrille GOUVENOT	6	0	2026-02-03 15:40:08.393455+01	2026-02-03 15:40:08.393456+01	0
1106	1167	2732	Bilan de compétences (12h) ROFFIN Kevin	6	0	2026-02-03 15:40:08.393456+01	2026-02-03 15:40:08.393457+01	0
1107	1168	2733	Bilan de compétences (12h) Morgane GUILLERM	6	0	2026-02-03 15:40:08.435542+01	2026-02-03 15:40:08.435545+01	0
1108	1169	2734	CP - DPE SM - Diag immo - Février 2026	5	0	2026-02-03 15:40:08.435546+01	2026-02-03 15:40:08.435547+01	0
1109	1169	2735	CP - DPE SM - Diag immo - Février 2026	5	0	2026-02-03 15:40:08.435547+01	2026-02-03 15:40:08.435548+01	0
1110	1170	2736	Bilan de compétences (15h) Annie DERUNES	6	0	2026-02-03 15:40:08.435548+01	2026-02-03 15:40:08.435549+01	0
1111	1171	2737	[TP GP] Gestionnaire de paie	6	0	2026-02-03 15:40:08.435549+01	2026-02-03 15:40:08.43555+01	0
1112	1171	2738	[TP GP] Gestionnaire de paie	6	0	2026-02-03 15:40:08.43555+01	2026-02-03 15:40:08.435551+01	0
1113	1173	2741	Bilan de compétences (12h) - BOULZE Ana Maria	6	0	2026-02-03 15:40:08.435552+01	2026-02-03 15:40:08.435552+01	0
1114	1174	2743	Bilan de compétences (9h) - JUNGER Hugo	6	0	2026-02-03 15:40:08.435553+01	2026-02-03 15:40:08.435553+01	0
1115	1178	2747	Bilan de compétences (9h) - GENOUX Angélique	6	0	2026-02-03 15:40:08.435554+01	2026-02-03 15:40:08.435554+01	0
1116	1179	2748	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.435555+01	2026-02-03 15:40:08.435555+01	0
1117	1179	2749	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.435556+01	2026-02-03 15:40:08.435556+01	0
1118	1179	2750	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.435557+01	2026-02-03 15:40:08.435557+01	0
1119	1179	2751	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.435558+01	2026-02-03 15:40:08.435558+01	0
1120	1179	2752	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.435559+01	2026-02-03 15:40:08.435559+01	0
1121	1179	2753	Réaliser les opérations comptables courantes d'une TPE	6	0	2026-02-03 15:40:08.43556+01	2026-02-03 15:40:08.43556+01	0
1122	1181	2755	Bilan de compétences (9h) - VINET Glwadys	6	0	2026-02-03 15:40:08.435561+01	2026-02-03 15:40:08.435561+01	0
1123	1182	2756	Bilan de compétences (12h) - BONNEFOND Christelle	6	0	2026-02-03 15:40:08.435562+01	2026-02-03 15:40:08.435562+01	0
1124	1184	2759	Bilan de compétences (12h) - KINET Nicolas	6	0	2026-02-03 15:40:08.435563+01	2026-02-03 15:40:08.435563+01	0
1125	1190	2797	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435564+01	2026-02-03 15:40:08.435564+01	0
1126	1190	2798	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435565+01	2026-02-03 15:40:08.435565+01	0
1127	1190	2799	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435566+01	2026-02-03 15:40:08.435566+01	0
1128	1190	2818	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435567+01	2026-02-03 15:40:08.435568+01	0
1129	1190	3627	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435568+01	2026-02-03 15:40:08.435569+01	0
1130	1190	2800	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435569+01	2026-02-03 15:40:08.43557+01	0
1131	1190	2823	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.43557+01	2026-02-03 15:40:08.435571+01	0
1132	1190	2822	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435571+01	2026-02-03 15:40:08.435572+01	0
1133	1190	2827	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435572+01	2026-02-03 15:40:08.435573+01	0
1134	1190	2829	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435573+01	2026-02-03 15:40:08.435574+01	0
1135	1190	2831	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435574+01	2026-02-03 15:40:08.435575+01	0
1136	1190	2833	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435575+01	2026-02-03 15:40:08.435576+01	0
1137	1190	2805	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435576+01	2026-02-03 15:40:08.435577+01	0
1138	1190	2825	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435577+01	2026-02-03 15:40:08.435578+01	0
1139	1190	2801	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435578+01	2026-02-03 15:40:08.435579+01	0
1140	1190	2802	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435579+01	2026-02-03 15:40:08.43558+01	0
1141	1190	2819	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.43558+01	2026-02-03 15:40:08.435581+01	0
1142	1190	2820	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435581+01	2026-02-03 15:40:08.435582+01	0
1143	1190	2821	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435582+01	2026-02-03 15:40:08.435583+01	0
1144	1190	2817	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435583+01	2026-02-03 15:40:08.435584+01	0
1145	1190	2803	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435584+01	2026-02-03 15:40:08.435585+01	0
1146	1190	2807	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435585+01	2026-02-03 15:40:08.435586+01	0
1147	1190	2809	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435586+01	2026-02-03 15:40:08.435587+01	0
1148	1190	2811	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435587+01	2026-02-03 15:40:08.435588+01	0
1149	1190	2815	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435588+01	2026-02-03 15:40:08.435589+01	0
1150	1190	2824	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435589+01	2026-02-03 15:40:08.43559+01	0
1151	1190	2813	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435591+01	2026-02-03 15:40:08.435591+01	0
1152	1190	2826	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435592+01	2026-02-03 15:40:08.435592+01	0
1153	1190	2828	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435593+01	2026-02-03 15:40:08.435593+01	0
1154	1190	2830	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435594+01	2026-02-03 15:40:08.435594+01	0
1155	1190	2832	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435595+01	2026-02-03 15:40:08.435595+01	0
1156	1190	2804	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435596+01	2026-02-03 15:40:08.435596+01	0
1157	1190	2806	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435597+01	2026-02-03 15:40:08.435597+01	0
1158	1190	2808	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435598+01	2026-02-03 15:40:08.435598+01	0
1159	1190	2810	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435599+01	2026-02-03 15:40:08.4356+01	0
1160	1190	2812	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.4356+01	2026-02-03 15:40:08.435601+01	0
1161	1190	2814	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435601+01	2026-02-03 15:40:08.435602+01	0
1162	1190	2816	S3 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.435602+01	2026-02-03 15:40:08.435603+01	0
1163	1191	2834	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.435603+01	2026-02-03 15:40:08.435604+01	0
1164	1191	2835	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.435604+01	2026-02-03 15:40:08.435605+01	0
1165	1194	2838	Bilan de compétences (12h) FLEURY Anne-Clémentine	6	0	2026-02-03 15:40:08.435605+01	2026-02-03 15:40:08.435606+01	0
1166	1195	2839	Bilan de compétences (15h) - OUAIRY Virginie	6	0	2026-02-03 15:40:08.435606+01	2026-02-03 15:40:08.435607+01	0
1167	1197	2841	Bilan de compétences (14h) GUILLEMIN Pierre Marie	6	0	2026-02-03 15:40:08.435608+01	2026-02-03 15:40:08.435608+01	0
1168	1198	2842	Bilan de compétences (9h) BRARD Emilie	6	0	2026-02-03 15:40:08.435609+01	2026-02-03 15:40:08.435609+01	0
1169	1201	2848	Bilan de compétences (12h) - Angelique TSIKA	6	0	2026-02-03 15:40:08.43561+01	2026-02-03 15:40:08.435611+01	0
1170	1202	2855	Bilan de compétences (15h) HERRERO Mickael	6	0	2026-02-03 15:40:08.435611+01	2026-02-03 15:40:08.435612+01	0
1171	1203	2862	Bilan de compétences (15h) - SALINAS Melissa	6	0	2026-02-03 15:40:08.435612+01	2026-02-03 15:40:08.435613+01	0
1172	1204	2863	Bilan de compétences (15h) - BERTRAND Alexis	6	0	2026-02-03 15:40:08.435613+01	2026-02-03 15:40:08.435614+01	0
1173	1206	2865	Bilan de compétences (9h) REQUENA Clemence	6	0	2026-02-03 15:40:08.435614+01	2026-02-03 15:40:08.435615+01	0
1174	1208	2867	Bilan de compétences (15h) SOBCZAK Jimmy	6	0	2026-02-03 15:40:08.435615+01	2026-02-03 15:40:08.435616+01	0
1175	1209	2868	Bilan de compétences (12h) OYHARÇABAL Xavier	6	0	2026-02-03 15:40:08.435616+01	2026-02-03 15:40:08.435617+01	0
1176	1210	2869	Bilan de compétences (12h) BONNOUVRIER Kévin	6	0	2026-02-03 15:40:08.435617+01	2026-02-03 15:40:08.435618+01	0
1177	1211	2870	Bilan de compétences (15h) CLAIRE Deborah	6	0	2026-02-03 15:40:08.435618+01	2026-02-03 15:40:08.435619+01	0
1178	1213	2872	Bilan de compétences (12h) VALOUR Joris	6	0	2026-02-03 15:40:08.435619+01	2026-02-03 15:40:08.43562+01	0
1179	1214	2873	Bilan de compétences (9h) CAMUS Laurent	6	0	2026-02-03 15:40:08.43562+01	2026-02-03 15:40:08.435621+01	0
1180	1219	2878	Bilan de compétences (6h) LOTTIAUX David	6	0	2026-02-03 15:40:08.435621+01	2026-02-03 15:40:08.435622+01	0
1181	1221	2880	Bilan de compétences (15h) MANCINI Michelle	6	0	2026-02-03 15:40:08.435622+01	2026-02-03 15:40:08.435623+01	0
1182	1222	2881	Bilan de compétences (15h) MOURATIAN Annie	6	0	2026-02-03 15:40:08.435623+01	2026-02-03 15:40:08.435624+01	0
1183	1223	2882	BDC - Ateliers collectifs (JAN-FEV26)	6	0	2026-02-03 15:40:08.435624+01	2026-02-03 15:40:08.435625+01	0
1184	1223	2883	BDC - Ateliers collectifs (JAN-FEV26)	6	0	2026-02-03 15:40:08.435625+01	2026-02-03 15:40:08.435626+01	0
1185	1223	2884	BDC - Ateliers collectifs (JAN-FEV26)	6	0	2026-02-03 15:40:08.435626+01	2026-02-03 15:40:08.435627+01	0
1186	1223	2885	BDC - Ateliers collectifs (JAN-FEV26)	6	0	2026-02-03 15:40:08.435628+01	2026-02-03 15:40:08.435628+01	0
1187	1227	2904	Bilan de compétences (6h) - MARTINS Lucinda	6	0	2026-02-03 15:40:08.485571+01	2026-02-03 15:40:08.485575+01	0
1188	1230	2913	Bilan de compétences (15h) MARCHAND Marina	6	0	2026-02-03 15:40:08.485576+01	2026-02-03 15:40:08.485576+01	0
1189	1231	2914	Bilan de compétences (9h) LELEUX Hemye	6	0	2026-02-03 15:40:08.485577+01	2026-02-03 15:40:08.485577+01	0
1190	1232	2915	Bilan de compétences (9h) MEUNIER Valentin	6	0	2026-02-03 15:40:08.485578+01	2026-02-03 15:40:08.485578+01	0
1191	1234	2918	Bilan de compétences (9h) AVERY Thomas	6	0	2026-02-03 15:40:08.485579+01	2026-02-03 15:40:08.485579+01	0
1192	1235	2919	Bilan de compétences (15h) SALABERT Michael	6	0	2026-02-03 15:40:08.48558+01	2026-02-03 15:40:08.48558+01	0
1193	1237	2921	Bilan de compétences (15h) DEGOT Alizée	6	0	2026-02-03 15:40:08.485581+01	2026-02-03 15:40:08.485581+01	0
1194	1238	2922	Bilan de compétences (12h) TEICHE Margaux	6	0	2026-02-03 15:40:08.485582+01	2026-02-03 15:40:08.485582+01	0
1195	1239	2925	Bilan de compétences (6h) DEMAREST Cloé	6	0	2026-02-03 15:40:08.485583+01	2026-02-03 15:40:08.485583+01	0
1196	1240	2960	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485584+01	2026-02-03 15:40:08.485584+01	0
1197	1240	2961	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485585+01	2026-02-03 15:40:08.485585+01	0
1198	1240	2937	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485586+01	2026-02-03 15:40:08.485587+01	0
1199	1240	2938	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485587+01	2026-02-03 15:40:08.485588+01	0
1200	1240	2939	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485588+01	2026-02-03 15:40:08.485589+01	0
1201	1240	2940	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485589+01	2026-02-03 15:40:08.48559+01	0
1202	1240	2941	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.48559+01	2026-02-03 15:40:08.485591+01	0
1203	1240	2942	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485591+01	2026-02-03 15:40:08.485592+01	0
1204	1240	2943	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485592+01	2026-02-03 15:40:08.485593+01	0
1205	1240	2944	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485593+01	2026-02-03 15:40:08.485594+01	0
1206	1240	2955	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485594+01	2026-02-03 15:40:08.485595+01	0
1207	1240	2956	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485595+01	2026-02-03 15:40:08.485596+01	0
1208	1240	2957	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485596+01	2026-02-03 15:40:08.485597+01	0
1209	1240	2958	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485597+01	2026-02-03 15:40:08.485598+01	0
1210	1240	2959	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485598+01	2026-02-03 15:40:08.485599+01	0
1211	1240	2945	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485599+01	2026-02-03 15:40:08.4856+01	0
1212	1240	2962	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.4856+01	2026-02-03 15:40:08.485601+01	0
1213	1240	2926	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485601+01	2026-02-03 15:40:08.485602+01	0
1214	1240	2927	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485602+01	2026-02-03 15:40:08.485603+01	0
1215	1240	2928	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485604+01	2026-02-03 15:40:08.485604+01	0
1216	1240	2929	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485605+01	2026-02-03 15:40:08.485605+01	0
1217	1240	2930	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485606+01	2026-02-03 15:40:08.485606+01	0
1218	1240	2963	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485607+01	2026-02-03 15:40:08.485607+01	0
1219	1240	2964	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485608+01	2026-02-03 15:40:08.485608+01	0
1220	1240	2965	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485609+01	2026-02-03 15:40:08.485609+01	0
1221	1240	2931	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.48561+01	2026-02-03 15:40:08.48561+01	0
1222	1240	2946	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485611+01	2026-02-03 15:40:08.485611+01	0
1223	1240	2932	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485612+01	2026-02-03 15:40:08.485612+01	0
1224	1240	2933	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485613+01	2026-02-03 15:40:08.485613+01	0
1225	1240	2934	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485614+01	2026-02-03 15:40:08.485614+01	0
1226	1240	2935	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485615+01	2026-02-03 15:40:08.485616+01	0
1227	1240	2936	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485616+01	2026-02-03 15:40:08.485617+01	0
1228	1240	2947	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485617+01	2026-02-03 15:40:08.485618+01	0
1229	1240	2948	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485618+01	2026-02-03 15:40:08.485619+01	0
1230	1240	2949	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485619+01	2026-02-03 15:40:08.48562+01	0
1231	1240	2950	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.48562+01	2026-02-03 15:40:08.485621+01	0
1232	1240	2951	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485621+01	2026-02-03 15:40:08.485622+01	0
1233	1240	2952	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485622+01	2026-02-03 15:40:08.485623+01	0
1234	1240	2953	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485623+01	2026-02-03 15:40:08.485624+01	0
1235	1240	2954	SESSION 13 - Chef de Projet en Rénovation Énergétique	5	0	2026-02-03 15:40:08.485624+01	2026-02-03 15:40:08.485625+01	0
1236	1244	3010	Bilan de compétences (12h) COLLIGNON Julien	6	0	2026-02-03 15:40:08.485626+01	2026-02-03 15:40:08.485626+01	0
1237	1245	3011	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485627+01	2026-02-03 15:40:08.485627+01	0
1238	1245	3012	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485628+01	2026-02-03 15:40:08.485628+01	0
1239	1245	3013	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485629+01	2026-02-03 15:40:08.485629+01	0
1240	1245	3032	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.48563+01	2026-02-03 15:40:08.48563+01	0
1241	1245	3014	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485631+01	2026-02-03 15:40:08.485631+01	0
1242	1245	3037	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485632+01	2026-02-03 15:40:08.485632+01	0
1243	1245	3036	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485633+01	2026-02-03 15:40:08.485633+01	0
1244	1245	3041	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485634+01	2026-02-03 15:40:08.485634+01	0
1245	1245	3043	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485635+01	2026-02-03 15:40:08.485635+01	0
1246	1245	3045	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485636+01	2026-02-03 15:40:08.485637+01	0
1247	1245	3047	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485637+01	2026-02-03 15:40:08.485638+01	0
1248	1245	3019	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485638+01	2026-02-03 15:40:08.485639+01	0
1249	1245	3039	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485639+01	2026-02-03 15:40:08.48564+01	0
1250	1245	3015	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.48564+01	2026-02-03 15:40:08.485641+01	0
1251	1245	3016	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485641+01	2026-02-03 15:40:08.485642+01	0
1252	1245	3033	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485642+01	2026-02-03 15:40:08.485643+01	0
1253	1245	3034	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485643+01	2026-02-03 15:40:08.485644+01	0
1254	1245	3035	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485644+01	2026-02-03 15:40:08.485645+01	0
1255	1245	3031	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485645+01	2026-02-03 15:40:08.485646+01	0
1256	1245	3017	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485646+01	2026-02-03 15:40:08.485647+01	0
1257	1245	3021	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485647+01	2026-02-03 15:40:08.485648+01	0
1258	1245	3025	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485648+01	2026-02-03 15:40:08.485649+01	0
1259	1245	3023	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485649+01	2026-02-03 15:40:08.48565+01	0
1260	1245	3038	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.48565+01	2026-02-03 15:40:08.485651+01	0
1261	1245	3029	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485651+01	2026-02-03 15:40:08.485652+01	0
1262	1245	3027	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485652+01	2026-02-03 15:40:08.485653+01	0
1263	1245	3040	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485653+01	2026-02-03 15:40:08.485654+01	0
1264	1245	3042	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485654+01	2026-02-03 15:40:08.485655+01	0
1265	1245	3044	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485655+01	2026-02-03 15:40:08.485656+01	0
1266	1245	3046	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485656+01	2026-02-03 15:40:08.485657+01	0
1267	1245	3018	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485657+01	2026-02-03 15:40:08.485658+01	0
1268	1245	3020	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485659+01	2026-02-03 15:40:08.485659+01	0
1269	1245	3022	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.48566+01	2026-02-03 15:40:08.48566+01	0
1270	1245	3024	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485661+01	2026-02-03 15:40:08.485661+01	0
1271	1245	3026	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485662+01	2026-02-03 15:40:08.485662+01	0
1272	1245	3028	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485663+01	2026-02-03 15:40:08.485663+01	0
1273	1245	3030	S4 - Cursus Diagnostiqueur(euse) Immobilier RNCP38933	5	0	2026-02-03 15:40:08.485664+01	2026-02-03 15:40:08.485664+01	0
1274	1252	3100	Bilan de compétences (9h) BONNET Marion	6	0	2026-02-03 15:40:08.485665+01	2026-02-03 15:40:08.485665+01	0
1275	1253	3101	Bilan de compétences (12h) VENUTOLO BOUET Corinne	6	0	2026-02-03 15:40:08.485666+01	2026-02-03 15:40:08.485666+01	0
1276	1255	3104	Bilan de compétences (6h) FREGARD Eric	6	0	2026-02-03 15:40:08.485667+01	2026-02-03 15:40:08.485667+01	0
1277	1265	3123	Bilan de compétences (12h) PONCET Marion	6	0	2026-02-03 15:40:08.485668+01	2026-02-03 15:40:08.485668+01	0
1278	1273	3132	Bilan de compétences (9h) FREYDOZ Antonin	6	0	2026-02-03 15:40:08.485669+01	2026-02-03 15:40:08.485669+01	0
1279	1276	3135	Bilan de compétences (12h) DIA Kady	6	0	2026-02-03 15:40:08.48567+01	2026-02-03 15:40:08.48567+01	0
1280	1279	3138	Bilan de compétences (9h) JABOUILLE Hugues	6	0	2026-02-03 15:40:08.485671+01	2026-02-03 15:40:08.485671+01	0
1281	1285	3144	Bilan de compétences (6h) GATTO Emma	6	0	2026-02-03 15:40:08.485672+01	2026-02-03 15:40:08.485672+01	0
1282	1294	3164	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.51138+01	2026-02-03 15:40:08.511384+01	0
1283	1294	3165	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.511385+01	2026-02-03 15:40:08.511386+01	0
1284	1300	3177	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.511386+01	2026-02-03 15:40:08.511387+01	0
1285	1300	3178	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.511387+01	2026-02-03 15:40:08.511388+01	0
1286	1313	3203	Bilan de compétences (9h) MOUSSAOUI Coraline	6	0	2026-02-03 15:40:08.511388+01	2026-02-03 15:40:08.511389+01	0
1287	1315	3206	Bilan de compétences (9h) LEQUEUX Guillaume	6	0	2026-02-03 15:40:08.511389+01	2026-02-03 15:40:08.51139+01	0
1288	1316	3207	Bilan de compétences (15h) TALARICO Hélène	6	0	2026-02-03 15:40:08.51139+01	2026-02-03 15:40:08.511391+01	0
1289	1317	3208	Bilan de compétences (9h) MENDY Marie	6	0	2026-02-03 15:40:08.511391+01	2026-02-03 15:40:08.511392+01	0
1290	1318	3209	Bilan de compétences (15h) BOUVIER Maelle	6	0	2026-02-03 15:40:08.511393+01	2026-02-03 15:40:08.511393+01	0
1291	1319	3210	Bilan de compétences (9h) PIOLIN Charlène	6	0	2026-02-03 15:40:08.511394+01	2026-02-03 15:40:08.511394+01	0
1292	1320	3211	Réaliser les opérations comptables courantes d'une TPE (C&M ROVELLA Fanny)	6	0	2026-02-03 15:40:08.511395+01	2026-02-03 15:40:08.511395+01	0
1293	1320	3212	Réaliser les opérations comptables courantes d'une TPE (C&M ROVELLA Fanny)	6	0	2026-02-03 15:40:08.511396+01	2026-02-03 15:40:08.511396+01	0
1294	1320	3213	Réaliser les opérations comptables courantes d'une TPE (C&M ROVELLA Fanny)	6	0	2026-02-03 15:40:08.511397+01	2026-02-03 15:40:08.511397+01	0
1295	1320	3214	Réaliser les opérations comptables courantes d'une TPE (C&M ROVELLA Fanny)	6	0	2026-02-03 15:40:08.511398+01	2026-02-03 15:40:08.511398+01	0
1296	1320	3215	Réaliser les opérations comptables courantes d'une TPE (C&M ROVELLA Fanny)	6	0	2026-02-03 15:40:08.511399+01	2026-02-03 15:40:08.511399+01	0
1297	1320	3216	Réaliser les opérations comptables courantes d'une TPE (C&M ROVELLA Fanny)	6	0	2026-02-03 15:40:08.5114+01	2026-02-03 15:40:08.5114+01	0
1298	1321	3220	Bilan de compétences (15h) - DESNOUEL LAVOISIER Veronique	6	0	2026-02-03 15:40:08.511401+01	2026-02-03 15:40:08.511401+01	0
1299	1322	3221	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.511402+01	2026-02-03 15:40:08.511402+01	0
1300	1322	3222	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.511403+01	2026-02-03 15:40:08.511403+01	0
1301	1323	3223	Bilan de compétences (9h) SANZONE Maxime	6	0	2026-02-03 15:40:08.511404+01	2026-02-03 15:40:08.511404+01	0
1302	1324	3224	Bilan de compétences (15h) GUIBERT Eva	6	0	2026-02-03 15:40:08.511405+01	2026-02-03 15:40:08.511405+01	0
1303	1326	3226	Bilan de compétences (6h) LE BLANC HUGON Loys	6	0	2026-02-03 15:40:08.511406+01	2026-02-03 15:40:08.511406+01	0
1304	1328	3264	Bilan de compétences (9h) BOUCHON Laure	6	0	2026-02-03 15:40:08.511407+01	2026-02-03 15:40:08.511408+01	0
1305	1329	3265	Bilan de compétences (12h) ETANCELIN Steves	6	0	2026-02-03 15:40:08.511408+01	2026-02-03 15:40:08.511409+01	0
1306	1330	3266	Bilan de compétences (15h) PAIN Barbara	6	0	2026-02-03 15:40:08.511409+01	2026-02-03 15:40:08.51141+01	0
1307	1331	3267	Bilan de compétences (6h) RAMOS David	6	0	2026-02-03 15:40:08.51141+01	2026-02-03 15:40:08.511411+01	0
1308	1332	3269	Bilan de compétences (12h) ZIOUKA Yvon	6	0	2026-02-03 15:40:08.511411+01	2026-02-03 15:40:08.511412+01	0
1309	1334	3272	Bilan de compétences (6h) Vladislav HERGUIER	6	0	2026-02-03 15:40:08.511412+01	2026-02-03 15:40:08.511413+01	0
1310	1335	3273	Bilan de compétences (9h) JOULLIE Jean Charles	6	0	2026-02-03 15:40:08.511413+01	2026-02-03 15:40:08.511414+01	0
1311	1336	3277	Bilan de compétences (9h) JOLY Antoine	6	0	2026-02-03 15:40:08.511414+01	2026-02-03 15:40:08.511415+01	0
1312	1337	3278	Bilan de compétences (12h) DENIS Thomas-Venceslas	6	0	2026-02-03 15:40:08.511415+01	2026-02-03 15:40:08.511416+01	0
1313	1338	3279	Bilan de compétences (12h) LEHOUX Stéphanie	6	0	2026-02-03 15:40:08.511416+01	2026-02-03 15:40:08.511417+01	0
1314	1339	3280	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.511417+01	2026-02-03 15:40:08.511418+01	0
1315	1339	3281	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.511418+01	2026-02-03 15:40:08.511419+01	0
1316	1340	3282	Bilan de compétences (12h) LEOGAL Magali	6	0	2026-02-03 15:40:08.511419+01	2026-02-03 15:40:08.51142+01	0
1317	1341	3283	Bilan de compétences (9h) EBIABOUA Jeanine	6	0	2026-02-03 15:40:08.511421+01	2026-02-03 15:40:08.511421+01	0
1318	1342	3284	Bilan de compétences (9h) GOUDE Delphine	6	0	2026-02-03 15:40:08.511422+01	2026-02-03 15:40:08.511422+01	0
1319	1344	3286	Bilan de compétences (15h) DEBEAUVOIS Amandine	6	0	2026-02-03 15:40:08.511423+01	2026-02-03 15:40:08.511423+01	0
1320	1345	3287	Bilan de compétences (9h) DESCOUTS Laura	6	0	2026-02-03 15:40:08.511424+01	2026-02-03 15:40:08.511424+01	0
1321	1346	3288	Bilan de compétences (15h) NIFFENEGER Loic	6	0	2026-02-03 15:40:08.511425+01	2026-02-03 15:40:08.511425+01	0
1322	1348	3290	Bilan de compétences (9h) JACQUOT Alexandra	6	0	2026-02-03 15:40:08.524318+01	2026-02-03 15:40:08.524321+01	0
1323	1349	3291	Bilan de compétences (9h) CHABBI Habib	6	0	2026-02-03 15:40:08.524322+01	2026-02-03 15:40:08.524323+01	0
1324	1350	3292	Bilan de compétences (9h) NICOLLE Clara	6	0	2026-02-03 15:40:08.524323+01	2026-02-03 15:40:08.524324+01	0
1325	1351	3293	Bilan de compétences (12h) VALPRADOS Sylvie	6	0	2026-02-03 15:40:08.524324+01	2026-02-03 15:40:08.524325+01	0
1326	1353	3295	Bilan de compétences (12h) LUCAS Alyssa	6	0	2026-02-03 15:40:08.524325+01	2026-02-03 15:40:08.524326+01	0
1327	1354	3296	Bilan de compétences (6h) DJABRI Ilyes	6	0	2026-02-03 15:40:08.524326+01	2026-02-03 15:40:08.524327+01	0
1328	1355	3297	Bilan de compétences (6h) FREIYHET Delphine	6	0	2026-02-03 15:40:08.524327+01	2026-02-03 15:40:08.524328+01	0
1329	1356	3298	Bilan de compétences (12h) WATTIEZ Justine	6	0	2026-02-03 15:40:08.524328+01	2026-02-03 15:40:08.524329+01	0
1330	1357	3299	Bilan de compétences (9h) COMBE Laurent	6	0	2026-02-03 15:40:08.524329+01	2026-02-03 15:40:08.52433+01	0
1331	1358	3300	Bilan de compétences (15h) CARLIEZ Florence	6	0	2026-02-03 15:40:08.52433+01	2026-02-03 15:40:08.524331+01	0
1332	1359	3301	Bilan de compétences (9h) BIGOT Stéphanie	6	0	2026-02-03 15:40:08.524331+01	2026-02-03 15:40:08.524332+01	0
1333	1364	3307	Bilan de compétences (9h) BARBIER Clémence	6	0	2026-02-03 15:40:08.524332+01	2026-02-03 15:40:08.524333+01	0
1334	1365	3308	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.524333+01	2026-02-03 15:40:08.524334+01	0
1335	1365	3309	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.524334+01	2026-02-03 15:40:08.524335+01	0
1336	1373	3318	Bilan de compétences (15h) BOSSE Morgane	6	0	2026-02-03 15:40:08.524335+01	2026-02-03 15:40:08.524336+01	0
1337	1379	3328	Bilan de compétences (15h) COQUELET Nelly	6	0	2026-02-03 15:40:08.524337+01	2026-02-03 15:40:08.524337+01	0
1338	1417	3383	Bilan de compétences (9h) GARNIER Matthieu	6	0	2026-02-03 15:40:08.524338+01	2026-02-03 15:40:08.524338+01	0
1339	1424	3391	Bilan de compétences (12h) ROBERT Lucas	6	0	2026-02-03 15:40:08.524339+01	2026-02-03 15:40:08.524339+01	0
1340	1431	3399	Bilan de compétences (12h) CLAIRET Lucie	6	0	2026-02-03 15:40:08.531369+01	2026-02-03 15:40:08.531372+01	0
1341	1437	3405	Bilan de compétences (9h) TOLLET Alice	6	0	2026-02-03 15:40:08.531373+01	2026-02-03 15:40:08.531373+01	0
1342	1441	3413	Bilan de compétences (9h) DURAND Emilie	6	0	2026-02-03 15:40:08.531374+01	2026-02-03 15:40:08.531375+01	0
1343	1444	3416	Bilan de compétences (9h) MERABET Sarah	6	0	2026-02-03 15:40:08.531375+01	2026-02-03 15:40:08.531376+01	0
1344	1459	3436	Bilan de compétences (9h) CARIVENC Mélanie	6	0	2026-02-03 15:40:08.531376+01	2026-02-03 15:40:08.531377+01	0
1345	1460	3437	Bilan de compétences (9h) CORBIN Jérome	6	0	2026-02-03 15:40:08.531377+01	2026-02-03 15:40:08.531378+01	0
1346	1462	3439	Bilan de compétences (12h) NICOLET Solene	6	0	2026-02-03 15:40:08.531378+01	2026-02-03 15:40:08.531379+01	0
1347	1463	3440	Bilan de compétences (12h) LOUBERE Aurélien	6	0	2026-02-03 15:40:08.531379+01	2026-02-03 15:40:08.53138+01	0
1348	1466	3448	Bilan de compétences (12h) BIGNON Thibault	6	0	2026-02-03 15:40:08.53138+01	2026-02-03 15:40:08.531381+01	0
1349	1483	3470	Bilan de compétences (12h) BROYER Emilie	6	0	2026-02-03 15:40:08.531381+01	2026-02-03 15:40:08.531382+01	0
1350	1504	3492	Bilan de compétences (12h) DELEUZE Matthieu	6	0	2026-02-03 15:40:08.539929+01	2026-02-03 15:40:08.539932+01	0
1351	1513	3506	Bilan de compétences (15h) MALASSAGNE Jonathan	6	0	2026-02-03 15:40:08.539932+01	2026-02-03 15:40:08.539933+01	0
1352	1516	3509	Bilan de compétences (9h) TROTIGNON Bruno	6	0	2026-02-03 15:40:08.539934+01	2026-02-03 15:40:08.539934+01	0
1353	1518	3511	Bilan de compétences (12h) DUGRAND Magalie	6	0	2026-02-03 15:40:08.539935+01	2026-02-03 15:40:08.539935+01	0
1354	1521	3617	VAE - Formule Essentiel (12h) - Helène ZEIDENBERG	5	0	2026-02-03 15:40:08.539936+01	2026-02-03 15:40:08.539936+01	0
1355	1522	3516	Bilan de compétences (12h) THAUVIN Sébastien	6	0	2026-02-03 15:40:08.539937+01	2026-02-03 15:40:08.539937+01	0
1356	1523	3517	Bilan de compétences (12h) DELEUZE Matthieu	6	0	2026-02-03 15:40:08.539938+01	2026-02-03 15:40:08.539938+01	0
1357	1524	3518	Bilan de compétences (9h) LONDE MPASSI Sarah	6	0	2026-02-03 15:40:08.539939+01	2026-02-03 15:40:08.53994+01	0
1358	1525	3519	Bilan de compétences (9h) JOLIVET Manon	6	0	2026-02-03 15:40:08.53994+01	2026-02-03 15:40:08.539941+01	0
1359	1526	3520	Bilan de compétences (15h) BLED Francois	6	0	2026-02-03 15:40:08.539941+01	2026-02-03 15:40:08.539942+01	0
1360	1527	3522	[TP GP] Gestionnaire de paie - Jasmine TROVATO (ADJADJ)	6	0	2026-02-03 15:40:08.539942+01	2026-02-03 15:40:08.539943+01	0
1361	1527	3523	[TP GP] Gestionnaire de paie - Jasmine TROVATO (ADJADJ)	6	0	2026-02-03 15:40:08.539943+01	2026-02-03 15:40:08.539944+01	0
1362	1532	3529	Bilan de compétences (15h) OPIZZI Jérome	6	0	2026-02-03 15:40:08.539944+01	2026-02-03 15:40:08.539945+01	0
1363	1539	3542	Bilan de compétences (12h) BARRIER Alain	6	0	2026-02-03 15:40:08.539945+01	2026-02-03 15:40:08.539946+01	0
1364	1546	3553	Bilan de compétences (15h) ADAM Francis	6	0	2026-02-03 15:40:08.547243+01	2026-02-03 15:40:08.547246+01	0
1365	1548	3555	Bilan de compétences (9h) MOUTINHO CORREIA Mathilde	6	0	2026-02-03 15:40:08.547247+01	2026-02-03 15:40:08.547247+01	0
1366	1558	3565	Bilan de compétences (15h) NOURRY Coralie	6	0	2026-02-03 15:40:08.547248+01	2026-02-03 15:40:08.547248+01	0
1367	1583	3596	Bilan de compétences (6h) CAZAY Christopher	6	0	2026-02-03 15:40:08.547249+01	2026-02-03 15:40:08.547249+01	0
1368	1584	3597	Bilan de compétences (12h) ROBERT Grégoire	6	0	2026-02-03 15:40:08.54725+01	2026-02-03 15:40:08.547251+01	0
1369	1585	3598	Bilan de compétences (12h) PARCE Alicia	6	0	2026-02-03 15:40:08.547251+01	2026-02-03 15:40:08.547252+01	0
1370	1590	3604	Bilan de compétences (6h) JUNG Nicolas	6	0	2026-02-03 15:40:08.547252+01	2026-02-03 15:40:08.547253+01	0
1371	1591	3605	Bilan de compétences (10h) PONS Loic	6	0	2026-02-03 15:40:08.547253+01	2026-02-03 15:40:08.547254+01	0
1372	1592	3606	Bilan de compétences (15h) DAUVILLAIRE Fabrice	6	0	2026-02-03 15:40:08.547254+01	2026-02-03 15:40:08.547255+01	0
1373	1593	3607	Bilan de compétences (8h) - GILLET (LE FLOCH) Emilie	6	0	2026-02-03 15:40:08.547255+01	2026-02-03 15:40:08.547256+01	0
1374	1594	3608	Bilan de compétences (9h) CHERICI Laura	6	0	2026-02-03 15:40:08.547257+01	2026-02-03 15:40:08.547257+01	0
1375	1601	3616	Bilan de compétences (9h) NDJOCK Yolande	6	0	2026-02-03 15:40:08.560666+01	2026-02-03 15:40:08.560669+01	0
1376	1602	3618	Bilan de compétences (6h) MARTIN Suzanne	6	0	2026-02-03 15:40:08.560669+01	2026-02-03 15:40:08.56067+01	0
1377	1603	3619	Bilan de compétences (9h) BRUGNON Nicolas	6	0	2026-02-03 15:40:08.560671+01	2026-02-03 15:40:08.560671+01	0
1378	1604	3620	Bilan de compétences (9h) Sylvain SILLY	6	0	2026-02-03 15:40:08.560672+01	2026-02-03 15:40:08.560672+01	0
1379	1605	3621	Bilan de compétences (12h) GASQUET Julie	6	0	2026-02-03 15:40:08.560673+01	2026-02-03 15:40:08.560673+01	0
1380	1606	3622	Bilan de compétences (12h) PARENT Suzy	6	0	2026-02-03 15:40:08.560674+01	2026-02-03 15:40:08.560674+01	0
1381	1607	3623	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.560675+01	2026-02-03 15:40:08.560675+01	0
1382	1607	3624	[TP FPA] Formateur professionnel d'adultes (Avancé)	6	0	2026-02-03 15:40:08.560676+01	2026-02-03 15:40:08.560676+01	0
1383	1608	3625	Formation Sécrétaire Médical(e) - TP SAMA (6h)	6	0	2026-02-03 15:40:08.560677+01	2026-02-03 15:40:08.560677+01	0
1384	1608	3626	Formation Sécrétaire Médical(e) - TP SAMA (6h)	6	0	2026-02-03 15:40:08.560678+01	2026-02-03 15:40:08.560678+01	0
1385	1609	3628	Bilan de compétences (15h) RUAU Alexia	6	0	2026-02-03 15:40:08.560679+01	2026-02-03 15:40:08.560679+01	0
1386	1614	3633	Bilan de compétences (9h) FERRON Cyril	6	0	2026-02-03 15:40:08.56068+01	2026-02-03 15:40:08.56068+01	0
1387	1632	3656	Bilan de compétences (12h) DAUSSIN Sophie	6	0	2026-02-03 15:40:08.560681+01	2026-02-03 15:40:08.560681+01	0
1388	1633	3657	Bilan de compétences (9h) CARON Ludivine	6	0	2026-02-03 15:40:08.560682+01	2026-02-03 15:40:08.560682+01	0
1389	1634	3658	Bilan de compétences (9h) CHIROL Vincent	6	0	2026-02-03 15:40:08.560683+01	2026-02-03 15:40:08.560683+01	0
1390	1635	3659	Bilan de compétences (12h) VERDON Solenne	6	0	2026-02-03 15:40:08.560684+01	2026-02-03 15:40:08.560684+01	0
1391	1636	3660	Bilan de compétences (12h) PESENTI Anne	6	0	2026-02-03 15:40:08.560685+01	2026-02-03 15:40:08.560685+01	0
1392	1637	3661	Bilan de compétences (9h) MARGERIN Thibaud	6	0	2026-02-03 15:40:08.560686+01	2026-02-03 15:40:08.560686+01	0
1393	1638	3662	Bilan de compétences (12h) SILBERBERG Noémie	6	0	2026-02-03 15:40:08.560687+01	2026-02-03 15:40:08.560687+01	0
1394	1645	3669	Bilan de compétences (9h) PONTENAY FONTETTE Bénédicte	6	0	2026-02-03 15:40:08.560688+01	2026-02-03 15:40:08.560689+01	0
1395	1646	3670	Bilan de compétences (15h) LOPEZ-GUIA Amandine	6	0	2026-02-03 15:40:08.560689+01	2026-02-03 15:40:08.56069+01	0
1396	1648	3673	Bilan de compétences (15h) DEFLANDRE Thomas	6	0	2026-02-03 15:40:08.56069+01	2026-02-03 15:40:08.560691+01	0
1397	1649	3674	Bilan de compétences (9h) TOLLET Alice	6	0	2026-02-03 15:40:08.560691+01	2026-02-03 15:40:08.560692+01	0
1398	1650	3675	Bilan de compétences (15h) LOPEZ Stéphane	6	0	2026-02-03 15:40:08.560692+01	2026-02-03 15:40:08.560693+01	0
1399	1652	3677	Bilan de compétences (12h) SEOANE Mégane	6	0	2026-02-03 15:40:08.569928+01	2026-02-03 15:40:08.569932+01	0
1400	1654	3679	Bilan de compétences (12h) HOFFEURT Héloïse	6	0	2026-02-03 15:40:08.569933+01	2026-02-03 15:40:08.569934+01	0
1401	1655	3680	Bilan de compétences (9h) TUTALA Stéphanie	6	0	2026-02-03 15:40:08.569934+01	2026-02-03 15:40:08.569935+01	0
1402	1656	3681	Bilan de compétences (6h) DUCHASSIN Laetitia	6	0	2026-02-03 15:40:08.569935+01	2026-02-03 15:40:08.569936+01	0
1403	1658	3683	Bilan de compétences (9h) WURTZ Anne-Sophie	6	0	2026-02-03 15:40:08.569936+01	2026-02-03 15:40:08.569937+01	0
1404	1659	3685	Bilan de compétences (15h) CARRE Fanny	6	0	2026-02-03 15:40:08.569938+01	2026-02-03 15:40:08.569938+01	0
1405	1660	3686	Bilan de compétences (12h) GAUDIN Baptiste	6	0	2026-02-03 15:40:08.569939+01	2026-02-03 15:40:08.569939+01	0
1406	1661	3689	Camille BERNAT_Bilan de compétences (9h)	6	0	2026-02-03 15:40:08.56994+01	2026-02-03 15:40:08.56994+01	0
1407	1662	3690	MERLO Etienne_Bilan de compétences (12h)	6	0	2026-02-03 15:40:08.569941+01	2026-02-03 15:40:08.569941+01	0
1408	1664	3692	[TP GP] Gestionnaire de paie	6	0	2026-02-03 15:40:08.569942+01	2026-02-03 15:40:08.569942+01	0
1409	1664	3693	[TP GP] Gestionnaire de paie	6	0	2026-02-03 15:40:08.569943+01	2026-02-03 15:40:08.569943+01	0
\.


--
-- Data for Name: modules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modules (id, id_lmp, id_lam, intitule, course_id, participant_id, lms_progression, lms_last_access_at, mode_organisation, created_at, updated_at, lms_time_spent, lms_started_at, lms_completed_at) FROM stdin;
\.


--
-- Data for Name: participant_courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.participant_courses (id, participant_id, course_id, id_lap, overall_progression, activity_status, last_activity, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: participant_hubspot_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.participant_hubspot_data (id, participant_id, id_action_formation, id_lap, c_url_transaction_hubspot, c_id_transaction_hubspot, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: participants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.participants (id, id_participant, nom, prenom, email, id_entreprise, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sync_metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sync_metadata (id, sync_type, last_sync_at, status, stats, error_message, created_at, updated_at) FROM stdin;
2	table_setup_test	2026-02-03 11:15:01.621093+01	success	{"message": "Table setup verification"}	\N	2026-02-03 12:15:01.622652+01	2026-02-03 12:15:01.622658+01
3	table_setup_test	2026-02-03 11:15:03.008283+01	success	{"message": "Table setup verification"}	\N	2026-02-03 12:15:03.009223+01	2026-02-03 12:15:03.009226+01
1	sync_all	2026-02-03 12:14:46.883692+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:14:46.884875+01	2026-02-03 12:15:16.99845+01
5	sync_all	2026-02-03 12:15:18.827325+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:15:18.828475+01	2026-02-03 12:15:48.943001+01
6	sync_all	2026-02-03 12:15:50.708366+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:15:50.709524+01	2026-02-03 12:16:20.81778+01
7	sync_all	2026-02-03 12:16:22.513357+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:16:22.51455+01	2026-02-03 12:16:52.615631+01
8	sync_all	2026-02-03 12:16:54.383119+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:16:54.384275+01	2026-02-03 12:17:24.499631+01
9	sync_all	2026-02-03 12:17:26.282609+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:17:26.283868+01	2026-02-03 12:17:56.39745+01
10	sync_all	2026-02-03 12:17:58.137956+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:17:58.139205+01	2026-02-03 12:18:28.249689+01
11	sync_all	2026-02-03 12:18:30.02556+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:18:30.026746+01	2026-02-03 12:19:00.144882+01
12	sync_all	2026-02-03 12:19:01.87541+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:19:01.87655+01	2026-02-03 12:19:31.998624+01
13	sync_all	2026-02-03 12:19:33.768649+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:19:33.769739+01	2026-02-03 12:20:03.873283+01
4	sync_all	2026-02-03 12:15:03.898425+01	error	\N	Sync process was interrupted or timed out after 0:05:01.819913	2026-02-03 12:15:03.899582+01	2026-02-03 12:20:05.71714+01
14	sync_all	2026-02-03 12:20:05.732194+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:20:05.734614+01	2026-02-03 12:20:35.838274+01
15	sync_all	2026-02-03 12:20:37.578107+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:20:37.579319+01	2026-02-03 12:21:07.68179+01
16	sync_all	2026-02-03 12:21:09.332056+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:21:09.333215+01	2026-02-03 12:21:39.43424+01
17	sync_all	2026-02-03 12:21:41.255178+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:21:41.256371+01	2026-02-03 12:22:11.363773+01
20	table_setup_test	2026-02-03 11:25:17.347832+01	success	{"message": "Table setup verification"}	\N	2026-02-03 12:25:17.348895+01	2026-02-03 12:25:17.348898+01
21	table_setup_test	2026-02-03 11:25:18.676179+01	success	{"message": "Table setup verification"}	\N	2026-02-03 12:25:18.677112+01	2026-02-03 12:25:18.677114+01
19	sync_all	2026-02-03 12:25:02.594591+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:25:02.595795+01	2026-02-03 12:25:32.714589+01
23	sync_all	2026-02-03 12:25:34.542988+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:25:34.544149+01	2026-02-03 12:26:04.639973+01
24	sync_all	2026-02-03 12:26:06.433039+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:26:06.434305+01	2026-02-03 12:26:36.54496+01
25	sync_all	2026-02-03 12:26:38.264554+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:26:38.265769+01	2026-02-03 12:27:08.382258+01
26	sync_all	2026-02-03 12:27:10.155191+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:27:10.156519+01	2026-02-03 12:27:40.27436+01
18	sync_all	2026-02-03 12:22:13.110391+01	error	\N	Sync process was interrupted or timed out after 0:05:28.868079	2026-02-03 12:22:13.111546+01	2026-02-03 12:27:41.977383+01
27	sync_all	2026-02-03 12:27:41.992434+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:27:41.994808+01	2026-02-03 12:28:12.099277+01
28	sync_all	2026-02-03 12:28:13.893247+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:28:13.894499+01	2026-02-03 12:28:44.017486+01
29	sync_all	2026-02-03 12:28:45.751336+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:28:45.752531+01	2026-02-03 12:29:15.837798+01
30	sync_all	2026-02-03 12:29:17.564861+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:29:17.566088+01	2026-02-03 12:29:47.670636+01
31	sync_all	2026-02-03 12:29:49.454603+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:29:49.455802+01	2026-02-03 12:30:19.572716+01
22	sync_all	2026-02-03 12:25:19.566171+01	error	\N	Sync process was interrupted or timed out after 0:05:01.716173	2026-02-03 12:25:19.567318+01	2026-02-03 12:30:21.281248+01
32	sync_all	2026-02-03 12:30:21.293629+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:30:21.294883+01	2026-02-03 12:30:51.369496+01
33	sync_all	2026-02-03 12:30:53.13004+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:30:53.131214+01	2026-02-03 12:31:23.245043+01
34	sync_all	2026-02-03 12:31:25.001845+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:31:25.003002+01	2026-02-03 12:31:55.107822+01
35	sync_all	2026-02-03 12:31:56.858364+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:31:56.859519+01	2026-02-03 12:32:26.965955+01
36	sync_all	2026-02-03 12:32:28.730692+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:32:28.73187+01	2026-02-03 12:32:58.845375+01
37	sync_all	2026-02-03 12:33:00.57671+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:33:00.577832+01	2026-02-03 12:33:30.695867+01
38	sync_all	2026-02-03 12:33:32.487521+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:33:32.488636+01	2026-02-03 12:34:02.581425+01
39	sync_all	2026-02-03 12:34:04.305154+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:34:04.306302+01	2026-02-03 12:34:34.419494+01
40	sync_all	2026-02-03 12:34:36.123881+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:34:36.125075+01	2026-02-03 12:35:06.240242+01
41	sync_all	2026-02-03 12:35:07.991922+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:35:07.993114+01	2026-02-03 12:35:38.106833+01
42	sync_all	2026-02-03 12:35:39.8571+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:35:39.858257+01	2026-02-03 12:36:09.97356+01
43	sync_all	2026-02-03 12:36:11.740947+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:36:11.742128+01	2026-02-03 12:36:41.843967+01
44	sync_all	2026-02-03 12:36:43.555281+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:36:43.556487+01	2026-02-03 12:37:13.637625+01
45	sync_all	2026-02-03 12:37:15.356478+01	error	\N	Request timed out: https://pro.dendreo.com/competences_et_metiers/api/lmps.php	2026-02-03 12:37:15.357739+01	2026-02-03 12:37:45.473184+01
46	sync_all	2026-02-03 12:37:47.253636+01	error	\N	Automatically cleaned up stuck sync record	2026-02-03 12:37:47.25479+01	2026-02-03 14:10:28.54826+01
48	table_setup_test	2026-02-03 13:10:42.840404+01	success	{"message": "Table setup verification"}	\N	2026-02-03 14:10:42.841503+01	2026-02-03 14:10:42.841506+01
49	table_setup_test	2026-02-03 13:10:44.19702+01	success	{"message": "Table setup verification"}	\N	2026-02-03 14:10:44.197958+01	2026-02-03 14:10:44.197961+01
47	sync_all	2026-02-03 14:10:28.557915+01	error	\N	Force cleaned up sync record	2026-02-03 14:10:28.559091+01	2026-02-03 14:10:45.602564+01
50	sync_all	2026-02-03 14:10:45.617776+01	error	\N	Force cleaned up sync record	2026-02-03 14:10:45.620068+01	2026-02-03 14:13:29.580713+01
52	table_setup_test	2026-02-03 13:13:43.853422+01	success	{"message": "Table setup verification"}	\N	2026-02-03 14:13:43.854626+01	2026-02-03 14:13:43.854629+01
53	table_setup_test	2026-02-03 13:13:45.18064+01	success	{"message": "Table setup verification"}	\N	2026-02-03 14:13:45.181575+01	2026-02-03 14:13:45.181578+01
51	sync_all	2026-02-03 14:13:29.590242+01	error	\N	Force cleaned up sync record	2026-02-03 14:13:29.591443+01	2026-02-03 14:13:46.561465+01
54	sync_all	2026-02-03 14:13:46.574346+01	error	\N	Force cleaned up sync record	2026-02-03 14:13:46.57546+01	2026-02-03 14:14:02.030864+01
55	sync_all	2026-02-03 14:14:02.043667+01	error	\N	Force cleaned up sync record	2026-02-03 14:14:02.044855+01	2026-02-03 14:14:34.410387+01
73	sync_all	2026-02-03 14:23:11.639436+01	error	\N	Force cleaned up sync record	2026-02-03 14:23:11.640688+01	2026-02-03 14:23:43.942655+01
56	sync_all	2026-02-03 14:14:34.423443+01	error	\N	Force cleaned up sync record	2026-02-03 14:14:34.42466+01	2026-02-03 14:15:06.740247+01
57	sync_all	2026-02-03 14:15:06.753087+01	error	\N	Force cleaned up sync record	2026-02-03 14:15:06.754225+01	2026-02-03 14:15:38.998556+01
74	sync_all	2026-02-03 14:23:43.958107+01	error	\N	Force cleaned up sync record	2026-02-03 14:23:43.960328+01	2026-02-03 14:24:16.293151+01
58	sync_all	2026-02-03 14:15:39.01162+01	error	\N	Force cleaned up sync record	2026-02-03 14:15:39.012824+01	2026-02-03 14:16:11.309+01
59	sync_all	2026-02-03 14:16:11.321857+01	error	\N	Force cleaned up sync record	2026-02-03 14:16:11.322977+01	2026-02-03 14:16:43.612725+01
75	sync_all	2026-02-03 14:24:16.309442+01	error	\N	Force cleaned up sync record	2026-02-03 14:24:16.31183+01	2026-02-03 14:24:48.666728+01
60	sync_all	2026-02-03 14:16:43.625436+01	error	\N	Force cleaned up sync record	2026-02-03 14:16:43.626545+01	2026-02-03 14:17:15.935715+01
61	sync_all	2026-02-03 14:17:15.94865+01	error	\N	Force cleaned up sync record	2026-02-03 14:17:15.949724+01	2026-02-03 14:17:48.285913+01
76	sync_all	2026-02-03 14:24:48.673442+01	error	\N	Force cleaned up sync record	2026-02-03 14:24:48.674564+01	2026-02-03 14:25:21.019131+01
62	sync_all	2026-02-03 14:17:48.301881+01	error	\N	Force cleaned up sync record	2026-02-03 14:17:48.304351+01	2026-02-03 14:18:20.673543+01
63	sync_all	2026-02-03 14:18:20.688964+01	error	\N	Force cleaned up sync record	2026-02-03 14:18:20.691044+01	2026-02-03 14:18:53.007919+01
77	sync_all	2026-02-03 14:25:21.035294+01	error	\N	Force cleaned up sync record	2026-02-03 14:25:21.037703+01	2026-02-03 14:25:53.354192+01
64	sync_all	2026-02-03 14:18:53.023844+01	error	\N	Force cleaned up sync record	2026-02-03 14:18:53.026214+01	2026-02-03 14:19:25.342781+01
65	sync_all	2026-02-03 14:19:25.358514+01	error	\N	Force cleaned up sync record	2026-02-03 14:19:25.360925+01	2026-02-03 14:19:57.59783+01
78	sync_all	2026-02-03 14:25:53.369453+01	error	\N	Force cleaned up sync record	2026-02-03 14:25:53.371572+01	2026-02-03 14:26:25.718503+01
66	sync_all	2026-02-03 14:19:57.612653+01	error	\N	Force cleaned up sync record	2026-02-03 14:19:57.614709+01	2026-02-03 14:20:29.923396+01
67	sync_all	2026-02-03 14:20:29.936277+01	error	\N	Force cleaned up sync record	2026-02-03 14:20:29.937435+01	2026-02-03 14:21:02.21456+01
79	sync_all	2026-02-03 14:26:25.734667+01	error	\N	Force cleaned up sync record	2026-02-03 14:26:25.737093+01	2026-02-03 14:26:57.987946+01
68	sync_all	2026-02-03 14:21:02.227543+01	error	\N	Force cleaned up sync record	2026-02-03 14:21:02.228738+01	2026-02-03 14:21:34.550732+01
69	sync_all	2026-02-03 14:21:34.567212+01	error	\N	Force cleaned up sync record	2026-02-03 14:21:34.570418+01	2026-02-03 14:22:06.951425+01
80	sync_all	2026-02-03 14:26:58.00377+01	error	\N	Force cleaned up sync record	2026-02-03 14:26:58.006153+01	2026-02-03 14:27:30.302811+01
70	sync_all	2026-02-03 14:22:06.967215+01	error	\N	Force cleaned up sync record	2026-02-03 14:22:06.969649+01	2026-02-03 14:22:38.071343+01
71	sync_all	2026-02-03 14:22:38.084944+01	error	\N	Force cleaned up sync record	2026-02-03 14:22:38.086269+01	2026-02-03 14:22:39.323742+01
81	sync_all	2026-02-03 14:27:30.317838+01	error	\N	Force cleaned up sync record	2026-02-03 14:27:30.320082+01	2026-02-03 14:28:02.583003+01
72	sync_all	2026-02-03 14:22:39.339061+01	error	\N	Force cleaned up sync record	2026-02-03 14:22:39.341473+01	2026-02-03 14:23:11.626317+01
82	sync_all	2026-02-03 14:28:02.596084+01	error	\N	Force cleaned up sync record	2026-02-03 14:28:02.59732+01	2026-02-03 14:28:34.869314+01
83	sync_all	2026-02-03 14:28:34.882108+01	error	\N	Force cleaned up sync record	2026-02-03 14:28:34.883223+01	2026-02-03 14:29:07.221607+01
84	sync_all	2026-02-03 14:29:07.237864+01	error	\N	Force cleaned up sync record	2026-02-03 14:29:07.240297+01	2026-02-03 14:29:39.614507+01
85	sync_all	2026-02-03 14:29:39.63048+01	error	\N	Force cleaned up sync record	2026-02-03 14:29:39.632896+01	2026-02-03 14:30:12.007425+01
86	sync_all	2026-02-03 14:30:12.022712+01	error	\N	Force cleaned up sync record	2026-02-03 14:30:12.024836+01	2026-02-03 14:30:44.340681+01
87	sync_all	2026-02-03 14:30:44.356876+01	error	\N	Force cleaned up sync record	2026-02-03 14:30:44.359255+01	2026-02-03 14:31:16.685976+01
88	sync_all	2026-02-03 14:31:16.701765+01	error	\N	Force cleaned up sync record	2026-02-03 14:31:16.704163+01	2026-02-03 14:31:49.06261+01
89	sync_all	2026-02-03 14:31:49.075568+01	error	\N	Force cleaned up sync record	2026-02-03 14:31:49.076742+01	2026-02-03 14:32:21.380894+01
90	sync_all	2026-02-03 14:32:21.396913+01	error	\N	Force cleaned up sync record	2026-02-03 14:32:21.399306+01	2026-02-03 14:32:53.695242+01
91	sync_all	2026-02-03 14:32:53.708318+01	error	\N	Force cleaned up sync record	2026-02-03 14:32:53.709478+01	2026-02-03 14:33:25.962236+01
92	sync_all	2026-02-03 14:33:25.978014+01	error	\N	Force cleaned up sync record	2026-02-03 14:33:25.980423+01	2026-02-03 14:33:58.278516+01
93	sync_all	2026-02-03 14:33:58.294223+01	error	\N	Force cleaned up sync record	2026-02-03 14:33:58.296575+01	2026-02-03 14:34:30.664306+01
94	sync_all	2026-02-03 14:34:30.677571+01	error	\N	Force cleaned up sync record	2026-02-03 14:34:30.678716+01	2026-02-03 14:35:02.976773+01
95	sync_all	2026-02-03 14:35:02.989632+01	error	\N	Force cleaned up sync record	2026-02-03 14:35:02.99072+01	2026-02-03 14:35:35.314626+01
96	sync_all	2026-02-03 14:35:35.327676+01	error	\N	Force cleaned up sync record	2026-02-03 14:35:35.3289+01	2026-02-03 14:36:07.611742+01
97	sync_all	2026-02-03 14:36:07.626398+01	error	\N	Force cleaned up sync record	2026-02-03 14:36:07.628533+01	2026-02-03 14:36:39.930737+01
98	sync_all	2026-02-03 14:36:39.943673+01	error	\N	Force cleaned up sync record	2026-02-03 14:36:39.944834+01	2026-02-03 14:37:12.275185+01
99	sync_all	2026-02-03 14:37:12.287553+01	error	\N	Force cleaned up sync record	2026-02-03 14:37:12.288644+01	2026-02-03 14:37:44.530902+01
100	sync_all	2026-02-03 14:37:44.546213+01	error	\N	Force cleaned up sync record	2026-02-03 14:37:44.548409+01	2026-02-03 14:38:16.884701+01
101	sync_all	2026-02-03 14:38:16.900303+01	error	\N	Force cleaned up sync record	2026-02-03 14:38:16.902627+01	2026-02-03 14:38:49.237593+01
102	sync_all	2026-02-03 14:38:49.250351+01	error	\N	Force cleaned up sync record	2026-02-03 14:38:49.251557+01	2026-02-03 14:39:21.577446+01
103	sync_all	2026-02-03 14:39:21.590399+01	error	\N	Force cleaned up sync record	2026-02-03 14:39:21.591515+01	2026-02-03 14:39:53.870976+01
104	sync_all	2026-02-03 14:39:53.877764+01	error	\N	Force cleaned up sync record	2026-02-03 14:39:53.878824+01	2026-02-03 14:40:26.160138+01
105	sync_all	2026-02-03 14:40:26.175227+01	error	\N	Force cleaned up sync record	2026-02-03 14:40:26.177285+01	2026-02-03 14:40:58.497085+01
106	sync_all	2026-02-03 14:40:58.510398+01	error	\N	Force cleaned up sync record	2026-02-03 14:40:58.51201+01	2026-02-03 14:41:30.812318+01
107	sync_all	2026-02-03 14:41:30.827827+01	error	\N	Force cleaned up sync record	2026-02-03 14:41:30.830276+01	2026-02-03 14:42:03.112445+01
108	sync_all	2026-02-03 14:42:03.127895+01	error	\N	Force cleaned up sync record	2026-02-03 14:42:03.130077+01	2026-02-03 14:42:35.431502+01
109	sync_all	2026-02-03 14:42:35.446877+01	error	\N	Force cleaned up sync record	2026-02-03 14:42:35.448949+01	2026-02-03 14:43:07.7664+01
110	sync_all	2026-02-03 14:43:07.782273+01	error	\N	Force cleaned up sync record	2026-02-03 14:43:07.7847+01	2026-02-03 14:43:40.126407+01
111	sync_all	2026-02-03 14:43:40.1395+01	error	\N	Force cleaned up sync record	2026-02-03 14:43:40.140691+01	2026-02-03 14:44:12.369975+01
112	sync_all	2026-02-03 14:44:12.385525+01	error	\N	Force cleaned up sync record	2026-02-03 14:44:12.387603+01	2026-02-03 14:44:44.664877+01
113	sync_all	2026-02-03 14:44:44.677917+01	error	\N	Force cleaned up sync record	2026-02-03 14:44:44.679064+01	2026-02-03 14:45:16.943261+01
114	sync_all	2026-02-03 14:45:16.956167+01	error	\N	Force cleaned up sync record	2026-02-03 14:45:16.957357+01	2026-02-03 14:45:49.256836+01
115	sync_all	2026-02-03 14:45:49.272293+01	error	\N	Force cleaned up sync record	2026-02-03 14:45:49.274651+01	2026-02-03 14:46:21.581466+01
116	sync_all	2026-02-03 14:46:21.594362+01	error	\N	Force cleaned up sync record	2026-02-03 14:46:21.595662+01	2026-02-03 14:46:53.898181+01
117	sync_all	2026-02-03 14:46:53.914651+01	error	\N	Force cleaned up sync record	2026-02-03 14:46:53.917089+01	2026-02-03 14:47:26.185936+01
118	sync_all	2026-02-03 14:47:26.202096+01	error	\N	Force cleaned up sync record	2026-02-03 14:47:26.204537+01	2026-02-03 14:47:58.562059+01
119	sync_all	2026-02-03 14:47:58.577951+01	error	\N	Force cleaned up sync record	2026-02-03 14:47:58.580395+01	2026-02-03 14:48:30.856997+01
120	sync_all	2026-02-03 14:48:30.872772+01	error	\N	Force cleaned up sync record	2026-02-03 14:48:30.875125+01	2026-02-03 14:49:03.199082+01
121	sync_all	2026-02-03 14:49:03.214835+01	error	\N	Force cleaned up sync record	2026-02-03 14:49:03.217346+01	2026-02-03 14:49:35.412485+01
122	sync_all	2026-02-03 14:49:35.428533+01	error	\N	Force cleaned up sync record	2026-02-03 14:49:35.430821+01	2026-02-03 14:50:07.745765+01
123	sync_all	2026-02-03 14:50:07.76111+01	error	\N	Force cleaned up sync record	2026-02-03 14:50:07.763436+01	2026-02-03 14:50:40.003416+01
124	sync_all	2026-02-03 14:50:40.019373+01	error	\N	Force cleaned up sync record	2026-02-03 14:50:40.021815+01	2026-02-03 14:51:12.318836+01
125	sync_all	2026-02-03 14:51:12.334936+01	error	\N	Force cleaned up sync record	2026-02-03 14:51:12.337349+01	2026-02-03 14:51:44.618098+01
126	sync_all	2026-02-03 14:51:44.631127+01	error	\N	Force cleaned up sync record	2026-02-03 14:51:44.63228+01	2026-02-03 14:52:17.023635+01
127	sync_all	2026-02-03 14:52:17.039729+01	error	\N	Force cleaned up sync record	2026-02-03 14:52:17.042156+01	2026-02-03 14:52:49.380728+01
147	sync_all	2026-02-03 15:03:03.321672+01	error	\N	Force cleaned up sync record	2026-02-03 15:03:03.324065+01	2026-02-03 15:03:35.67005+01
128	sync_all	2026-02-03 14:52:49.393992+01	error	\N	Force cleaned up sync record	2026-02-03 14:52:49.39519+01	2026-02-03 14:53:21.675862+01
148	sync_all	2026-02-03 15:03:35.685463+01	error	\N	Force cleaned up sync record	2026-02-03 15:03:35.687533+01	2026-02-03 15:04:08.037018+01
129	sync_all	2026-02-03 14:53:21.690726+01	error	\N	Force cleaned up sync record	2026-02-03 14:53:21.692861+01	2026-02-03 14:53:53.96028+01
130	sync_all	2026-02-03 14:53:53.967043+01	error	\N	Force cleaned up sync record	2026-02-03 14:53:53.968195+01	2026-02-03 14:54:26.292569+01
149	sync_all	2026-02-03 15:04:08.049817+01	error	\N	Force cleaned up sync record	2026-02-03 15:04:08.05092+01	2026-02-03 15:04:40.37457+01
131	sync_all	2026-02-03 14:54:26.307399+01	error	\N	Force cleaned up sync record	2026-02-03 14:54:26.309331+01	2026-02-03 14:54:58.59651+01
150	sync_all	2026-02-03 15:04:40.390581+01	error	\N	Force cleaned up sync record	2026-02-03 15:04:40.392993+01	2026-02-03 15:05:12.715609+01
132	sync_all	2026-02-03 14:54:58.611556+01	error	\N	Force cleaned up sync record	2026-02-03 14:54:58.613509+01	2026-02-03 14:55:30.894378+01
133	sync_all	2026-02-03 14:55:30.910261+01	error	\N	Force cleaned up sync record	2026-02-03 14:55:30.912673+01	2026-02-03 14:56:03.225187+01
151	sync_all	2026-02-03 15:05:12.731388+01	error	\N	Force cleaned up sync record	2026-02-03 15:05:12.733788+01	2026-02-03 15:05:45.009213+01
134	sync_all	2026-02-03 14:56:03.238938+01	error	\N	Force cleaned up sync record	2026-02-03 14:56:03.2401+01	2026-02-03 14:56:35.535761+01
152	sync_all	2026-02-03 15:05:45.024443+01	error	\N	Force cleaned up sync record	2026-02-03 15:05:45.026517+01	2026-02-03 15:06:17.320623+01
135	sync_all	2026-02-03 14:56:35.54859+01	error	\N	Force cleaned up sync record	2026-02-03 14:56:35.549685+01	2026-02-03 14:57:07.822772+01
136	sync_all	2026-02-03 14:57:07.838656+01	error	\N	Force cleaned up sync record	2026-02-03 14:57:07.841057+01	2026-02-03 14:57:40.127747+01
153	sync_all	2026-02-03 15:06:17.336706+01	error	\N	Force cleaned up sync record	2026-02-03 15:06:17.339118+01	2026-02-03 15:06:49.666831+01
137	sync_all	2026-02-03 14:57:40.143224+01	error	\N	Force cleaned up sync record	2026-02-03 14:57:40.145596+01	2026-02-03 14:58:12.42767+01
154	sync_all	2026-02-03 15:06:49.682831+01	error	\N	Force cleaned up sync record	2026-02-03 15:06:49.685264+01	2026-02-03 15:07:21.959421+01
138	sync_all	2026-02-03 14:58:12.440999+01	error	\N	Force cleaned up sync record	2026-02-03 14:58:12.442209+01	2026-02-03 14:58:44.718448+01
139	sync_all	2026-02-03 14:58:44.734726+01	error	\N	Force cleaned up sync record	2026-02-03 14:58:44.737154+01	2026-02-03 14:59:17.015423+01
155	sync_all	2026-02-03 15:07:21.975238+01	error	\N	Force cleaned up sync record	2026-02-03 15:07:21.977632+01	2026-02-03 15:07:54.289139+01
140	sync_all	2026-02-03 14:59:17.031031+01	error	\N	Force cleaned up sync record	2026-02-03 14:59:17.033466+01	2026-02-03 14:59:49.406015+01
156	sync_all	2026-02-03 15:07:54.301989+01	error	\N	Force cleaned up sync record	2026-02-03 15:07:54.303146+01	2026-02-03 15:08:26.588591+01
141	sync_all	2026-02-03 14:59:49.42116+01	error	\N	Force cleaned up sync record	2026-02-03 14:59:49.423301+01	2026-02-03 15:00:21.742807+01
142	sync_all	2026-02-03 15:00:21.755812+01	error	\N	Force cleaned up sync record	2026-02-03 15:00:21.756962+01	2026-02-03 15:00:54.006659+01
157	sync_all	2026-02-03 15:08:26.603926+01	error	\N	Force cleaned up sync record	2026-02-03 15:08:26.606174+01	2026-02-03 15:08:58.941619+01
143	sync_all	2026-02-03 15:00:54.022853+01	error	\N	Force cleaned up sync record	2026-02-03 15:00:54.025271+01	2026-02-03 15:01:26.34865+01
158	sync_all	2026-02-03 15:08:58.954592+01	error	\N	Force cleaned up sync record	2026-02-03 15:08:58.95578+01	2026-02-03 15:09:31.203954+01
144	sync_all	2026-02-03 15:01:26.364172+01	error	\N	Force cleaned up sync record	2026-02-03 15:01:26.366535+01	2026-02-03 15:01:58.690484+01
145	sync_all	2026-02-03 15:01:58.703519+01	error	\N	Force cleaned up sync record	2026-02-03 15:01:58.70471+01	2026-02-03 15:02:31.054184+01
159	sync_all	2026-02-03 15:09:31.219761+01	error	\N	Force cleaned up sync record	2026-02-03 15:09:31.222189+01	2026-02-03 15:10:03.442574+01
146	sync_all	2026-02-03 15:02:31.069438+01	error	\N	Force cleaned up sync record	2026-02-03 15:02:31.07149+01	2026-02-03 15:03:03.305699+01
160	sync_all	2026-02-03 15:10:03.455527+01	error	\N	Force cleaned up sync record	2026-02-03 15:10:03.456717+01	2026-02-03 15:10:35.734083+01
161	sync_all	2026-02-03 15:10:35.749766+01	error	\N	Force cleaned up sync record	2026-02-03 15:10:35.752097+01	2026-02-03 15:11:08.120117+01
162	sync_all	2026-02-03 15:11:08.135603+01	error	\N	Force cleaned up sync record	2026-02-03 15:11:08.137928+01	2026-02-03 15:11:40.442278+01
163	sync_all	2026-02-03 15:11:40.457451+01	error	\N	Force cleaned up sync record	2026-02-03 15:11:40.459545+01	2026-02-03 15:12:12.731638+01
164	sync_all	2026-02-03 15:12:12.744451+01	error	\N	Force cleaned up sync record	2026-02-03 15:12:12.74565+01	2026-02-03 15:12:45.072801+01
165	sync_all	2026-02-03 15:12:45.088968+01	error	\N	Force cleaned up sync record	2026-02-03 15:12:45.091349+01	2026-02-03 15:13:17.367779+01
166	sync_all	2026-02-03 15:13:17.383898+01	error	\N	Force cleaned up sync record	2026-02-03 15:13:17.386328+01	2026-02-03 15:13:49.707131+01
167	sync_all	2026-02-03 15:13:49.720343+01	error	\N	Force cleaned up sync record	2026-02-03 15:13:49.72147+01	2026-02-03 15:14:22.026345+01
168	sync_all	2026-02-03 15:14:22.042242+01	error	\N	Force cleaned up sync record	2026-02-03 15:14:22.044639+01	2026-02-03 15:14:54.345421+01
169	sync_all	2026-02-03 15:14:54.360941+01	error	\N	Force cleaned up sync record	2026-02-03 15:14:54.363201+01	2026-02-03 15:15:26.650838+01
170	sync_all	2026-02-03 15:15:26.666815+01	error	\N	Force cleaned up sync record	2026-02-03 15:15:26.669214+01	2026-02-03 15:15:58.966495+01
171	sync_all	2026-02-03 15:15:58.982014+01	error	\N	Force cleaned up sync record	2026-02-03 15:15:58.984438+01	2026-02-03 15:16:31.27237+01
172	sync_all	2026-02-03 15:16:31.288154+01	error	\N	Force cleaned up sync record	2026-02-03 15:16:31.290514+01	2026-02-03 15:17:03.645658+01
173	sync_all	2026-02-03 15:17:03.660813+01	error	\N	Force cleaned up sync record	2026-02-03 15:17:03.662925+01	2026-02-03 15:17:35.889399+01
174	sync_all	2026-02-03 15:17:35.904936+01	error	\N	Force cleaned up sync record	2026-02-03 15:17:35.907371+01	2026-02-03 15:18:08.207614+01
175	sync_all	2026-02-03 15:18:08.223272+01	error	\N	Force cleaned up sync record	2026-02-03 15:18:08.225624+01	2026-02-03 15:18:40.522611+01
176	sync_all	2026-02-03 15:18:40.537774+01	error	\N	Force cleaned up sync record	2026-02-03 15:18:40.539877+01	2026-02-03 15:19:12.870388+01
177	sync_all	2026-02-03 15:19:12.88577+01	error	\N	Force cleaned up sync record	2026-02-03 15:19:12.888068+01	2026-02-03 15:19:45.155026+01
178	sync_all	2026-02-03 15:19:45.171374+01	error	\N	Force cleaned up sync record	2026-02-03 15:19:45.173756+01	2026-02-03 15:20:17.479918+01
179	sync_all	2026-02-03 15:20:17.495945+01	error	\N	Force cleaned up sync record	2026-02-03 15:20:17.498386+01	2026-02-03 15:20:49.770092+01
180	sync_all	2026-02-03 15:20:49.783088+01	error	\N	Force cleaned up sync record	2026-02-03 15:20:49.784264+01	2026-02-03 15:21:22.161485+01
181	sync_all	2026-02-03 15:21:22.17667+01	error	\N	Force cleaned up sync record	2026-02-03 15:21:22.178759+01	2026-02-03 15:21:54.473572+01
182	sync_all	2026-02-03 15:21:54.4896+01	error	\N	Force cleaned up sync record	2026-02-03 15:21:54.491946+01	2026-02-03 15:22:26.875665+01
183	sync_all	2026-02-03 15:22:26.891138+01	error	\N	Force cleaned up sync record	2026-02-03 15:22:26.893681+01	2026-02-03 15:22:59.140421+01
184	sync_all	2026-02-03 15:22:59.155987+01	error	\N	Force cleaned up sync record	2026-02-03 15:22:59.15794+01	2026-02-03 15:23:31.484143+01
185	sync_all	2026-02-03 15:23:31.499618+01	error	\N	Force cleaned up sync record	2026-02-03 15:23:31.501929+01	2026-02-03 15:24:03.816738+01
186	sync_all	2026-02-03 15:24:03.829716+01	error	\N	Force cleaned up sync record	2026-02-03 15:24:03.830831+01	2026-02-03 15:24:36.118815+01
187	sync_all	2026-02-03 15:24:36.135126+01	error	\N	Force cleaned up sync record	2026-02-03 15:24:36.137598+01	2026-02-03 15:25:08.458721+01
188	sync_all	2026-02-03 15:25:08.471904+01	error	\N	Force cleaned up sync record	2026-02-03 15:25:08.473035+01	2026-02-03 15:25:40.71342+01
189	sync_all	2026-02-03 15:25:40.728897+01	error	\N	Force cleaned up sync record	2026-02-03 15:25:40.73114+01	2026-02-03 15:26:13.09123+01
190	sync_all	2026-02-03 15:26:13.106733+01	error	\N	Force cleaned up sync record	2026-02-03 15:26:13.108846+01	2026-02-03 15:26:45.436122+01
191	sync_all	2026-02-03 15:26:45.451991+01	error	\N	Force cleaned up sync record	2026-02-03 15:26:45.45418+01	2026-02-03 15:27:17.762759+01
192	sync_all	2026-02-03 15:27:17.778527+01	error	\N	Force cleaned up sync record	2026-02-03 15:27:17.780949+01	2026-02-03 15:27:50.140662+01
193	sync_all	2026-02-03 15:27:50.15688+01	error	\N	Force cleaned up sync record	2026-02-03 15:27:50.15969+01	2026-02-03 15:28:22.491391+01
194	sync_all	2026-02-03 15:28:22.506403+01	error	\N	Force cleaned up sync record	2026-02-03 15:28:22.5086+01	2026-02-03 15:28:54.770411+01
195	sync_all	2026-02-03 15:28:54.786638+01	error	\N	Force cleaned up sync record	2026-02-03 15:28:54.789074+01	2026-02-03 15:29:27.107266+01
196	sync_all	2026-02-03 15:29:27.12292+01	error	\N	Force cleaned up sync record	2026-02-03 15:29:27.125402+01	2026-02-03 15:29:59.427581+01
197	sync_all	2026-02-03 15:29:59.44301+01	error	\N	Force cleaned up sync record	2026-02-03 15:29:59.445251+01	2026-02-03 15:30:31.824105+01
198	sync_all	2026-02-03 15:30:31.840016+01	error	\N	Force cleaned up sync record	2026-02-03 15:30:31.84221+01	2026-02-03 15:31:04.158402+01
199	sync_all	2026-02-03 15:31:04.17172+01	error	\N	Force cleaned up sync record	2026-02-03 15:31:04.172928+01	2026-02-03 15:31:36.680611+01
200	sync_all	2026-02-03 15:31:36.693682+01	error	\N	Force cleaned up sync record	2026-02-03 15:31:36.694789+01	2026-02-03 15:32:09.081919+01
201	sync_all	2026-02-03 15:32:09.097461+01	error	\N	Force cleaned up sync record	2026-02-03 15:32:09.099622+01	2026-02-03 15:32:41.454407+01
202	sync_all	2026-02-03 15:32:41.467747+01	error	\N	Force cleaned up sync record	2026-02-03 15:32:41.468894+01	2026-02-03 15:33:13.900262+01
203	sync_all	2026-02-03 15:33:13.916348+01	error	\N	Force cleaned up sync record	2026-02-03 15:33:13.918767+01	2026-02-03 15:33:46.296955+01
204	sync_all	2026-02-03 15:33:46.31257+01	error	\N	Force cleaned up sync record	2026-02-03 15:33:46.314867+01	2026-02-03 15:34:18.613907+01
205	sync_all	2026-02-03 15:34:18.629556+01	error	\N	Force cleaned up sync record	2026-02-03 15:34:18.631821+01	2026-02-03 15:34:50.999967+01
206	sync_all	2026-02-03 15:34:51.015907+01	error	\N	Force cleaned up sync record	2026-02-03 15:34:51.018431+01	2026-02-03 15:35:23.324869+01
207	sync_all	2026-02-03 15:35:23.337925+01	error	\N	Force cleaned up sync record	2026-02-03 15:35:23.339092+01	2026-02-03 15:35:55.670381+01
208	sync_all	2026-02-03 15:35:55.683604+01	error	\N	Force cleaned up sync record	2026-02-03 15:35:55.684806+01	2026-02-03 15:36:27.929901+01
209	sync_all	2026-02-03 15:36:27.943023+01	error	\N	Force cleaned up sync record	2026-02-03 15:36:27.944206+01	2026-02-03 15:37:00.24306+01
210	sync_all	2026-02-03 15:37:00.258978+01	error	\N	Force cleaned up sync record	2026-02-03 15:37:00.261408+01	2026-02-03 15:37:32.56805+01
211	sync_all	2026-02-03 15:37:32.583791+01	error	\N	Force cleaned up sync record	2026-02-03 15:37:32.586229+01	2026-02-03 15:40:05.526581+01
213	table_setup_test	2026-02-03 14:40:19.801263+01	success	{"message": "Table setup verification"}	\N	2026-02-03 15:40:19.802341+01	2026-02-03 15:40:19.802344+01
214	table_setup_test	2026-02-03 14:40:21.174046+01	success	{"message": "Table setup verification"}	\N	2026-02-03 15:40:21.175101+01	2026-02-03 15:40:21.175104+01
212	sync_all	2026-02-03 15:40:05.538151+01	error	\N	Force cleaned up sync record	2026-02-03 15:40:05.539361+01	2026-02-03 15:40:22.565999+01
215	sync_all	2026-02-03 15:40:22.583314+01	error	\N	Force cleaned up sync record	2026-02-03 15:40:22.585228+01	2026-02-03 15:42:02.146721+01
216	sync_all	2026-02-03 15:42:02.159909+01	error	\N	Force cleaned up sync record	2026-02-03 15:42:02.161076+01	2026-02-03 15:45:05.896283+01
217	sync_all	2026-02-03 15:45:05.909187+01	error	\N	Force cleaned up sync record	2026-02-03 15:45:05.910356+01	2026-02-03 15:51:07.855295+01
219	table_setup_test	2026-02-03 14:51:22.178396+01	success	{"message": "Table setup verification"}	\N	2026-02-03 15:51:22.179457+01	2026-02-03 15:51:22.17946+01
220	table_setup_test	2026-02-03 14:51:23.501346+01	success	{"message": "Table setup verification"}	\N	2026-02-03 15:51:23.502373+01	2026-02-03 15:51:23.502376+01
218	sync_all	2026-02-03 15:51:07.865215+01	error	\N	Force cleaned up sync record	2026-02-03 15:51:07.866441+01	2026-02-03 15:51:24.887741+01
221	sync_all	2026-02-03 15:51:24.900468+01	error	\N	Force cleaned up sync record	2026-02-03 15:51:24.901562+01	2026-02-03 16:00:23.905375+01
222	sync_all	2026-02-03 16:00:23.918337+01	in_progress	\N	\N	2026-02-03 16:00:23.919576+01	2026-02-03 16:00:23.919578+01
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, hashed_password, is_active, created_at, updated_at) FROM stdin;
1	admin	$2b$12$wsWHM4SiCtCZmOf6q8maiORf1G78FywfeThIpqOZytsY3aQ5dpa32	t	2026-02-03 14:15:20.930107+01	2026-02-03 14:15:20.930111+01
\.


--
-- Name: courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.courses_id_seq', 1409, true);


--
-- Name: modules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.modules_id_seq', 1, false);


--
-- Name: participant_courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.participant_courses_id_seq', 1, false);


--
-- Name: participant_hubspot_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.participant_hubspot_data_id_seq', 1, false);


--
-- Name: participants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.participants_id_seq', 1, false);


--
-- Name: sync_metadata_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sync_metadata_id_seq', 222, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);


--
-- Name: courses _adf_lam_uc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT _adf_lam_uc UNIQUE (id_action_formation, id_lam);


--
-- Name: modules _lmp_participant_uc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT _lmp_participant_uc UNIQUE (id_lmp, participant_id);


--
-- Name: participant_hubspot_data _participant_adf_uc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participant_hubspot_data
    ADD CONSTRAINT _participant_adf_uc UNIQUE (participant_id, id_action_formation);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (id);


--
-- Name: participant_courses participant_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participant_courses
    ADD CONSTRAINT participant_courses_pkey PRIMARY KEY (id);


--
-- Name: participant_hubspot_data participant_hubspot_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participant_hubspot_data
    ADD CONSTRAINT participant_hubspot_data_pkey PRIMARY KEY (id);


--
-- Name: participants participants_id_participant_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT participants_id_participant_key UNIQUE (id_participant);


--
-- Name: participants participants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT participants_pkey PRIMARY KEY (id);


--
-- Name: sync_metadata sync_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sync_metadata
    ADD CONSTRAINT sync_metadata_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_courses_id_action_formation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_id_action_formation ON public.courses USING btree (id_action_formation);


--
-- Name: idx_courses_id_lam; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courses_id_lam ON public.courses USING btree (id_lam);


--
-- Name: idx_modules_course_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_modules_course_id ON public.modules USING btree (course_id);


--
-- Name: idx_modules_id_lmp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_modules_id_lmp ON public.modules USING btree (id_lmp);


--
-- Name: idx_modules_lms_completed_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_modules_lms_completed_at ON public.modules USING btree (lms_completed_at);


--
-- Name: idx_modules_lms_started_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_modules_lms_started_at ON public.modules USING btree (lms_started_at);


--
-- Name: idx_modules_lms_time_spent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_modules_lms_time_spent ON public.modules USING btree (lms_time_spent);


--
-- Name: idx_modules_participant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_modules_participant_id ON public.modules USING btree (participant_id);


--
-- Name: idx_participant_courses_course_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_participant_courses_course_id ON public.participant_courses USING btree (course_id);


--
-- Name: idx_participant_courses_participant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_participant_courses_participant_id ON public.participant_courses USING btree (participant_id);


--
-- Name: idx_participant_hubspot_data_participant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_participant_hubspot_data_participant_id ON public.participant_hubspot_data USING btree (participant_id);


--
-- Name: idx_participants_id_participant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_participants_id_participant ON public.participants USING btree (id_participant);


--
-- Name: idx_sync_metadata_last_sync_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sync_metadata_last_sync_at ON public.sync_metadata USING btree (last_sync_at);


--
-- Name: idx_sync_metadata_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sync_metadata_status ON public.sync_metadata USING btree (status);


--
-- Name: idx_sync_metadata_sync_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sync_metadata_sync_type ON public.sync_metadata USING btree (sync_type);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- Name: courses update_courses_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON public.courses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: modules update_modules_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_modules_updated_at BEFORE UPDATE ON public.modules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: participant_courses update_participant_courses_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_participant_courses_updated_at BEFORE UPDATE ON public.participant_courses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: participant_hubspot_data update_participant_hubspot_data_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_participant_hubspot_data_updated_at BEFORE UPDATE ON public.participant_hubspot_data FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: participants update_participants_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_participants_updated_at BEFORE UPDATE ON public.participants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: sync_metadata update_sync_metadata_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_sync_metadata_updated_at BEFORE UPDATE ON public.sync_metadata FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: modules modules_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: modules modules_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modules
    ADD CONSTRAINT modules_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id);


--
-- Name: participant_courses participant_courses_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participant_courses
    ADD CONSTRAINT participant_courses_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: participant_courses participant_courses_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participant_courses
    ADD CONSTRAINT participant_courses_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id);


--
-- Name: participant_hubspot_data participant_hubspot_data_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participant_hubspot_data
    ADD CONSTRAINT participant_hubspot_data_participant_id_fkey FOREIGN KEY (participant_id) REFERENCES public.participants(id);


--
-- PostgreSQL database dump complete
--

\unrestrict wasvXAh5VhzXs2x23vlA7mA25lXFApg3PCOz0LSECaOlU3SA77tS1hRLVPeNoDP

