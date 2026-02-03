--
-- PostgreSQL database dump
--

\restrict 3K0WtdklrFdozh4dpO2D1b4WqoLLVjxS7drS2TPIYROnXzr8rs6WVcJ19zbvSgx

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
8	119	196	Prise de parole en public : devenir un bon orateur (MARS - AOUT 2025)	6	0	2026-02-03 15:40:07.802848+01	2026-02-03 15:40:07.802848+01	0
9	119	197	Prise de parole en public : devenir un bon orateur (MARS - AOUT 2025)	6	0	2026-02-03 15:40:07.802849+01	2026-02-03 15:40:07.80285+01	0
10	124	204	Bilan de compétences - Démo	5	0	2026-02-03 15:40:07.80285+01	2026-02-03 15:40:07.802851+01	0
11	134	216	Bilan de compétences (6h) - DEFILS Valérie	6	0	2026-02-03 15:40:07.802851+01	2026-02-03 15:40:07.802852+01	0
17	140	443	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802857+01	2026-02-03 15:40:07.802858+01	0
18	140	242	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802858+01	2026-02-03 15:40:07.802859+01	0
19	140	243	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802859+01	2026-02-03 15:40:07.80286+01	0
20	140	244	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.80286+01	2026-02-03 15:40:07.802861+01	0
21	140	245	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802861+01	2026-02-03 15:40:07.802862+01	0
22	140	2357	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802862+01	2026-02-03 15:40:07.802863+01	0
23	140	1008	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802863+01	2026-02-03 15:40:07.802864+01	0
24	167	325	Bilan de compétences (10h)	6	0	2026-02-03 15:40:07.802864+01	2026-02-03 15:40:07.802865+01	0
25	168	326	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.802865+01	2026-02-03 15:40:07.802866+01	0
27	175	558	Management	6	0	2026-02-03 15:40:07.802868+01	2026-02-03 15:40:07.802868+01	0
28	175	559	Management	6	0	2026-02-03 15:40:07.802869+01	2026-02-03 15:40:07.802869+01	0
29	175	560	Management	6	0	2026-02-03 15:40:07.802869+01	2026-02-03 15:40:07.80287+01	0
31	176	1606	[TP SC] Secrétaire Comptable	6	0	2026-02-03 15:40:07.802871+01	2026-02-03 15:40:07.802872+01	0
32	193	351	Bilan de compétences (10h)	6	0	2026-02-03 15:40:07.813698+01	2026-02-03 15:40:07.813701+01	0
34	194	1456	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.813703+01	2026-02-03 15:40:07.813703+01	0
35	210	369	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.813704+01	2026-02-03 15:40:07.813704+01	0
36	218	377	Bilan de compétences (12h)	6	0	2026-02-03 15:40:07.813705+01	2026-02-03 15:40:07.813705+01	0
37	221	380	Bilan de compétences (12h)	6	0	2026-02-03 15:40:07.813706+01	2026-02-03 15:40:07.813707+01	0
38	225	384	Bilan de compétences (6h)	6	0	2026-02-03 15:40:07.813707+01	2026-02-03 15:40:07.813708+01	0
39	226	1358	Espagnol (Catherine MOGNOLLE)	6	0	2026-02-03 15:40:07.813708+01	2026-02-03 15:40:07.813709+01	0
40	226	1359	Espagnol (Catherine MOGNOLLE)	6	0	2026-02-03 15:40:07.813709+01	2026-02-03 15:40:07.81371+01	0
41	233	444	Bilan de compétences (12h) - LEGASTELOIS Marine	6	0	2026-02-03 15:40:07.81371+01	2026-02-03 15:40:07.813711+01	0
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
63	256	536	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831684+01	2026-02-03 15:40:07.831684+01	0
64	256	537	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831685+01	2026-02-03 15:40:07.831685+01	0
65	257	538	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.831686+01	2026-02-03 15:40:07.831686+01	0
66	266	548	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831687+01	2026-02-03 15:40:07.831687+01	0
67	266	550	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831688+01	2026-02-03 15:40:07.831688+01	0
68	266	551	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831689+01	2026-02-03 15:40:07.831689+01	0
7	119	195	Prise de parole en public : devenir un bon orateur (MARS - AOUT 2025)	6	0	2026-02-03 15:40:07.802846+01	2026-02-03 16:23:56.555101+01	12
12	140	237	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802852+01	2026-02-03 16:23:58.687032+01	2
13	140	238	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802853+01	2026-02-03 16:23:58.687032+01	3
14	140	239	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802854+01	2026-02-03 16:23:58.687032+01	2
15	140	240	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802855+01	2026-02-03 16:23:58.687032+01	2
26	175	333	Management	6	0	2026-02-03 15:40:07.802866+01	2026-02-03 16:24:02.133999+01	24
30	176	1605	[TP SC] Secrétaire Comptable	6	0	2026-02-03 15:40:07.80287+01	2026-02-03 16:24:03.275291+01	400
33	194	1455	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.813702+01	2026-02-03 16:24:04.134643+01	400
42	237	1457	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.813711+01	2026-02-03 16:24:06.948761+01	400
57	256	530	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831677+01	2026-02-03 16:24:10.083304+01	4
58	256	531	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831678+01	2026-02-03 16:24:10.083304+01	23
59	256	532	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831679+01	2026-02-03 16:24:10.083304+01	1.25
60	256	533	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.83168+01	2026-02-03 16:24:10.083304+01	2.25
61	256	535	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831681+01	2026-02-03 16:24:10.083304+01	4
62	256	534	Audit Énergétique en maison individuelle	6	0	2026-02-03 15:40:07.831682+01	2026-02-03 16:24:10.083304+01	1
69	266	552	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.83169+01	2026-02-03 15:40:07.83169+01	0
70	266	1862	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831691+01	2026-02-03 15:40:07.831692+01	0
71	266	549	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831692+01	2026-02-03 15:40:07.831693+01	0
72	266	557	Chef de projet en rénovation énergétique	6	0	2026-02-03 15:40:07.831693+01	2026-02-03 15:40:07.831694+01	0
73	272	563	Bilan de compétences (12h)	6	0	2026-02-03 15:40:07.831694+01	2026-02-03 15:40:07.831695+01	0
74	275	566	Bilan de compétences (10h)	6	0	2026-02-03 15:40:07.831695+01	2026-02-03 15:40:07.831696+01	0
76	288	1460	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.831697+01	2026-02-03 15:40:07.831698+01	0
78	303	649	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873743+01	2026-02-03 15:40:07.873744+01	0
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
105	307	1441	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.873771+01	2026-02-03 15:40:07.873772+01	0
107	313	683	CréActifs - Formation Création d'Entreprise MAI-JUIN25	6	0	2026-02-03 15:40:07.873773+01	2026-02-03 15:40:07.873774+01	0
108	313	684	CréActifs - Formation Création d'Entreprise MAI-JUIN25	6	0	2026-02-03 15:40:07.873774+01	2026-02-03 15:40:07.873775+01	0
109	313	685	CréActifs - Formation Création d'Entreprise MAI-JUIN25	6	0	2026-02-03 15:40:07.873775+01	2026-02-03 15:40:07.873776+01	0
110	323	693	Bilan de compétences (8h)	6	0	2026-02-03 15:40:07.873776+01	2026-02-03 15:40:07.873777+01	0
111	326	696	Bilan de compétences (8h) - ESPUNA Manon	6	0	2026-02-03 15:40:07.873777+01	2026-02-03 15:40:07.873778+01	0
112	327	697	Bilan de compétences (10h)	6	0	2026-02-03 15:40:07.873778+01	2026-02-03 15:40:07.873779+01	0
113	328	698	Bilan de compétences (6h)	6	0	2026-02-03 15:40:07.873781+01	2026-02-03 15:40:07.873781+01	0
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
99	306	1013	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873765+01	2026-02-03 16:24:34.124712+01	100
104	307	1440	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.87377+01	2026-02-03 16:24:35.053902+01	400
106	313	682	CréActifs - Formation Création d'Entreprise MAI-JUIN25	6	0	2026-02-03 15:40:07.873772+01	2026-02-03 16:24:35.430516+01	14
114	356	752	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873782+01	2026-02-03 16:24:39.457948+01	3.3
115	356	749	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873783+01	2026-02-03 16:24:39.457948+01	3.2
116	356	1020	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873784+01	2026-02-03 16:24:39.457948+01	17.5
77	303	648	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873739+01	2026-02-03 16:24:33.432741+01	35
79	303	2856	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873744+01	2026-02-03 16:24:33.432741+01	4
83	306	1012	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873748+01	2026-02-03 16:24:34.124712+01	100
117	356	750	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873785+01	2026-02-03 16:24:39.457948+01	2.3
118	356	1151	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873786+01	2026-02-03 16:24:39.457948+01	3.07
131	356	781	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873799+01	2026-02-03 15:40:07.8738+01	0
132	356	782	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873801+01	2026-02-03 15:40:07.873801+01	0
155	358	784	Bilan de compétences (10h) - LE BRETON Magali	6	0	2026-02-03 15:40:07.873824+01	2026-02-03 15:40:07.87383+01	0
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
156	363	789	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969798+01	2026-02-03 16:24:39.033919+01	3.2
157	363	794	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969802+01	2026-02-03 16:24:39.033919+01	8.5
158	363	798	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969803+01	2026-02-03 16:24:39.033919+01	3.5
159	363	804	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969804+01	2026-02-03 16:24:39.033919+01	14
160	363	809	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969805+01	2026-02-03 16:24:39.033919+01	2.25
161	363	810	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969807+01	2026-02-03 16:24:39.033919+01	1
162	363	811	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969808+01	2026-02-03 16:24:39.033919+01	4
177	363	790	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969823+01	2026-02-03 16:24:39.033919+01	2.3
178	363	792	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969826+01	2026-02-03 16:24:39.033919+01	3.3
179	363	802	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969827+01	2026-02-03 16:24:39.033919+01	35
180	363	807	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969828+01	2026-02-03 16:24:39.033919+01	4
181	363	814	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969829+01	2026-02-03 16:24:39.033919+01	12
182	363	817	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.96983+01	2026-02-03 16:24:39.033919+01	12.45
183	363	819	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969831+01	2026-02-03 16:24:39.033919+01	14
184	363	821	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969832+01	2026-02-03 16:24:39.033919+01	11.5
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
1	115	2285	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802835+01	2026-02-03 16:23:56.137306+01	2.75
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
2	115	2283	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.80284+01	2026-02-03 16:23:56.137306+01	2.5
3	115	2281	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802842+01	2026-02-03 16:23:56.137306+01	3.25
4	115	2282	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802843+01	2026-02-03 16:23:56.137306+01	2.25
5	115	2284	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802844+01	2026-02-03 16:23:56.137306+01	2.25
6	115	2286	Test Parcour DOKEOS	5	0	2026-02-03 15:40:07.802845+01	2026-02-03 16:23:56.137306+01	12.25
16	140	241	Formation Intelligence Artificielle Générative FEV-MAI25	6	0	2026-02-03 15:40:07.802856+01	2026-02-03 16:23:58.687032+01	2
80	303	2857	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873745+01	2026-02-03 16:24:33.432741+01	1.25
100	306	1014	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873766+01	2026-02-03 16:24:34.124712+01	100
101	306	1015	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873767+01	2026-02-03 16:24:34.124712+01	5
133	356	753	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873802+01	2026-02-03 16:24:39.457948+01	8.5
134	356	754	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873803+01	2026-02-03 16:24:39.457948+01	15.5
135	356	755	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873804+01	2026-02-03 16:24:39.457948+01	0.65
75	288	1459	[TP FPA] Formateur professionnel d'adultes	6	0	2026-02-03 15:40:07.831696+01	2026-02-03 16:24:33.003299+01	400
81	303	2858	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873746+01	2026-02-03 16:24:33.432741+01	2.25
82	303	2859	DPE - Sans Mention	6	0	2026-02-03 15:40:07.873747+01	2026-02-03 16:24:33.432741+01	1
102	306	1016	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873768+01	2026-02-03 16:24:34.124712+01	35
103	306	1017	[TP SAMS] - Secrétaire Assistant Médico-Social (e-learning + classes individuelles)	6	0	2026-02-03 15:40:07.873769+01	2026-02-03 16:24:34.124712+01	3
185	363	793	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969833+01	2026-02-03 16:24:39.033919+01	3.07
186	363	808	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969834+01	2026-02-03 16:24:39.033919+01	1.25
187	363	795	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969835+01	2026-02-03 16:24:39.033919+01	15.5
188	363	796	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969836+01	2026-02-03 16:24:39.033919+01	0.65
189	363	797	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969837+01	2026-02-03 16:24:39.033919+01	7.2
190	363	803	Session 1 - Chef de projet en Rénovation énergétique - SESSION DE RATTRAPAGE DES EMARGEMENTS	5	0	2026-02-03 15:40:07.969838+01	2026-02-03 16:24:39.033919+01	23
136	356	756	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873805+01	2026-02-03 16:24:39.457948+01	7.2
137	356	757	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873806+01	2026-02-03 16:24:39.457948+01	3.5
138	356	761	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873807+01	2026-02-03 16:24:39.457948+01	35
139	356	763	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873808+01	2026-02-03 16:24:39.457948+01	14
140	356	762	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873809+01	2026-02-03 16:24:39.457948+01	23
141	356	766	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.87381+01	2026-02-03 16:24:39.457948+01	4
142	356	767	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873811+01	2026-02-03 16:24:39.457948+01	1.25
143	356	768	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873812+01	2026-02-03 16:24:39.457948+01	2.25
144	356	769	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873813+01	2026-02-03 16:24:39.457948+01	1
145	356	770	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873814+01	2026-02-03 16:24:39.457948+01	4
146	356	773	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873815+01	2026-02-03 16:24:39.457948+01	12
147	356	1898	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873816+01	2026-02-03 16:24:39.457948+01	14.5
148	356	1899	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873817+01	2026-02-03 16:24:39.457948+01	20
149	356	1900	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873818+01	2026-02-03 16:24:39.457948+01	3
150	356	1901	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873819+01	2026-02-03 16:24:39.457948+01	1
151	356	1902	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.87382+01	2026-02-03 16:24:39.457948+01	0.5
152	356	779	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873821+01	2026-02-03 16:24:39.457948+01	12.45
153	356	777	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873822+01	2026-02-03 16:24:39.457948+01	14
154	356	780	Session 6 Chef de projet en Rénovation énergétique	6	0	2026-02-03 15:40:07.873823+01	2026-02-03 16:24:39.457948+01	11.5
\.


--
-- Data for Name: modules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modules (id, id_lmp, id_lam, intitule, course_id, participant_id, lms_progression, lms_last_access_at, mode_organisation, created_at, updated_at, lms_time_spent, lms_started_at, lms_completed_at) FROM stdin;
7	610	195	Prise de parole en publique - Devenir un bon orateur	7	2	95	2025-07-03 19:54:26+02	elearning_async	2026-02-03 16:23:56.737708+01	2026-02-03 16:24:13.805176+01	87988	2025-04-02 14:07:31+02	\N
8	614	195	Prise de parole en publique - Devenir un bon orateur	7	3	100	2025-03-22 10:01:31+01	elearning_async	2026-02-03 16:23:56.942857+01	2026-02-03 16:24:14.053132+01	51780	2025-02-24 11:09:33+01	2025-03-22 10:20:03+01
9	618	195	Prise de parole en publique - Devenir un bon orateur	7	4	0	\N	elearning_async	2026-02-03 16:23:57.195584+01	2026-02-03 16:24:14.288829+01	0	\N	\N
10	731	195	Prise de parole en publique - Devenir un bon orateur	7	5	100	2025-07-04 18:01:31+02	elearning_async	2026-02-03 16:23:57.389104+01	2026-02-03 16:24:14.531892+01	41254	2025-03-25 19:58:25+01	2025-07-04 18:29:30+02
11	5717	195	Prise de parole en publique - Devenir un bon orateur	7	6	100	2025-10-13 13:59:41+02	elearning_async	2026-02-03 16:23:57.591118+01	2026-02-03 16:24:14.758399+01	56282	2025-05-26 13:14:09+02	2025-10-13 13:59:33+02
12	686	237	IA - Module 1 : Introduction au monde de l'intelligence artificielle (IA)	12	9	0	\N	elearning_async	2026-02-03 16:23:58.953214+01	2026-02-03 16:24:15.911647+01	0	\N	\N
13	691	238	IA - Module 2 : Les concepts, modèles d’IA, et l'ingénierie de l'invite	13	9	0	\N	elearning_async	2026-02-03 16:23:58.953227+01	2026-02-03 16:24:15.911647+01	0	\N	\N
14	696	239	IA - Module 3 : La génération d’images et les données au cœur de l’IA générative	14	9	0	\N	elearning_async	2026-02-03 16:23:58.953231+01	2026-02-03 16:24:15.911647+01	0	\N	\N
15	701	240	IA - Module 4 : Confidentialité et Sécurité dans l’Utilisation de l’IA Générative	15	9	0	\N	elearning_async	2026-02-03 16:23:58.953235+01	2026-02-03 16:24:15.911647+01	0	\N	\N
16	706	241	IA - Module 5 : Réglementations (IA Act, RGPD) et Éthique	16	9	0	\N	elearning_async	2026-02-03 16:23:58.953239+01	2026-02-03 16:24:15.911647+01	0	\N	\N
17	687	237	IA - Module 1 : Introduction au monde de l'intelligence artificielle (IA)	12	10	100	2025-03-29 16:42:17+01	elearning_async	2026-02-03 16:23:59.251717+01	2026-02-03 16:24:16.179527+01	1468	2025-03-29 16:14:20+01	2025-03-29 16:41:21+01
18	692	238	IA - Module 2 : Les concepts, modèles d’IA, et l'ingénierie de l'invite	13	10	100	2025-05-10 23:52:47+02	elearning_async	2026-02-03 16:23:59.25173+01	2026-02-03 16:24:16.179527+01	14280	2025-03-29 16:42:57+01	2025-05-10 23:51:46+02
19	697	239	IA - Module 3 : La génération d’images et les données au cœur de l’IA générative	14	10	100	2025-05-11 01:25:21+02	elearning_async	2026-02-03 16:23:59.251734+01	2026-02-03 16:24:16.179527+01	4910	2025-05-10 23:52:47+02	2025-05-11 01:27:35+02
20	702	240	IA - Module 4 : Confidentialité et Sécurité dans l’Utilisation de l’IA Générative	15	10	100	2025-05-23 18:44:07+02	elearning_async	2026-02-03 16:23:59.251739+01	2026-02-03 16:24:16.179527+01	1928	2025-05-23 18:03:52+02	2025-05-23 18:44:04+02
21	707	241	IA - Module 5 : Réglementations (IA Act, RGPD) et Éthique	16	10	100	2025-05-23 19:06:26+02	elearning_async	2026-02-03 16:23:59.251742+01	2026-02-03 16:24:16.179527+01	814	2025-05-23 18:45:40+02	2025-05-23 19:06:22+02
22	688	237	IA - Module 1 : Introduction au monde de l'intelligence artificielle (IA)	12	11	100	2025-05-20 21:30:18+02	elearning_async	2026-02-03 16:23:59.550727+01	2026-02-03 16:24:16.465705+01	4982	2025-04-13 17:02:55+02	2025-05-20 20:53:17+02
23	693	238	IA - Module 2 : Les concepts, modèles d’IA, et l'ingénierie de l'invite	13	11	100	2025-05-23 11:50:08+02	elearning_async	2026-02-03 16:23:59.55074+01	2026-02-03 16:24:16.465705+01	22200	2025-04-13 17:52:41+02	2025-05-14 20:53:16+02
24	698	239	IA - Module 3 : La génération d’images et les données au cœur de l’IA générative	14	11	17	2025-05-14 20:55:01+02	elearning_async	2026-02-03 16:23:59.550744+01	2026-02-03 16:24:16.465705+01	3780	2025-05-14 20:55:01+02	\N
25	703	240	IA - Module 4 : Confidentialité et Sécurité dans l’Utilisation de l’IA Générative	15	11	100	2025-05-15 14:19:51+02	elearning_async	2026-02-03 16:23:59.550747+01	2026-02-03 16:24:16.465705+01	2048	2025-05-14 22:00:59+02	2025-05-15 14:19:46+02
27	689	237	IA - Module 1 : Introduction au monde de l'intelligence artificielle (IA)	12	12	100	2025-04-15 15:10:07+02	elearning_async	2026-02-03 16:23:59.852446+01	2026-02-03 16:24:16.76722+01	5962	2025-04-11 15:26:34+02	2025-04-15 15:09:57+02
28	694	238	IA - Module 2 : Les concepts, modèles d’IA, et l'ingénierie de l'invite	13	12	100	2025-05-17 11:00:47+02	elearning_async	2026-02-03 16:23:59.852458+01	2026-02-03 16:24:16.76722+01	18420	2025-04-17 14:10:11+02	2025-05-17 11:00:29+02
29	699	239	IA - Module 3 : La génération d’images et les données au cœur de l’IA générative	14	12	100	2025-05-17 19:55:19+02	elearning_async	2026-02-03 16:23:59.852462+01	2026-02-03 16:24:16.76722+01	13340	2025-05-17 16:12:01+02	2025-05-17 20:00:43+02
30	704	240	IA - Module 4 : Confidentialité et Sécurité dans l’Utilisation de l’IA Générative	15	12	100	2025-05-19 14:31:29+02	elearning_async	2026-02-03 16:23:59.852466+01	2026-02-03 16:24:16.76722+01	3474	2025-05-19 10:33:52+02	2025-05-19 14:31:26+02
31	709	241	IA - Module 5 : Réglementations (IA Act, RGPD) et Éthique	16	12	100	2025-05-19 15:46:38+02	elearning_async	2026-02-03 16:23:59.85247+01	2026-02-03 16:24:16.76722+01	3198	2025-05-19 14:36:32+02	2025-05-19 15:46:35+02
32	690	237	IA - Module 1 : Introduction au monde de l'intelligence artificielle (IA)	12	13	100	2025-04-08 15:07:44+02	elearning_async	2026-02-03 16:24:00.157278+01	2026-02-03 16:24:17.064569+01	13424	2025-03-28 10:07:47+01	2025-04-01 16:50:05+02
33	695	238	IA - Module 2 : Les concepts, modèles d’IA, et l'ingénierie de l'invite	13	13	100	2025-04-25 08:33:15+02	elearning_async	2026-02-03 16:24:00.157291+01	2026-02-03 16:24:17.064569+01	22980	2025-04-01 17:42:21+02	2025-04-24 19:26:51+02
34	700	239	IA - Module 3 : La génération d’images et les données au cœur de l’IA générative	14	13	7	2025-04-25 08:33:15+02	elearning_async	2026-02-03 16:24:00.157295+01	2026-02-03 16:24:17.064569+01	12160	2025-04-25 08:33:15+02	\N
35	705	240	IA - Module 4 : Confidentialité et Sécurité dans l’Utilisation de l’IA Générative	15	13	0	\N	elearning_async	2026-02-03 16:24:00.157299+01	2026-02-03 16:24:17.064569+01	0	\N	\N
36	710	241	IA - Module 5 : Réglementations (IA Act, RGPD) et Éthique	16	13	0	\N	elearning_async	2026-02-03 16:24:00.157303+01	2026-02-03 16:24:17.064569+01	0	\N	\N
37	1933	237	IA - Module 1 : Introduction au monde de l'intelligence artificielle (IA)	12	14	100	2025-05-10 13:37:41+02	elearning_async	2026-02-03 16:24:00.46011+01	2026-02-03 16:24:17.384123+01	3984	2025-05-09 10:27:39+02	2025-05-10 13:36:43+02
38	1934	238	IA - Module 2 : Les concepts, modèles d’IA, et l'ingénierie de l'invite	13	14	0	\N	elearning_async	2026-02-03 16:24:00.460122+01	2026-02-03 16:24:17.384123+01	0	\N	\N
39	1935	239	IA - Module 3 : La génération d’images et les données au cœur de l’IA générative	14	14	0	\N	elearning_async	2026-02-03 16:24:00.460125+01	2026-02-03 16:24:17.384123+01	0	\N	\N
40	1936	240	IA - Module 4 : Confidentialité et Sécurité dans l’Utilisation de l’IA Générative	15	14	0	\N	elearning_async	2026-02-03 16:24:00.460129+01	2026-02-03 16:24:17.384123+01	0	\N	\N
41	1937	241	IA - Module 5 : Réglementations (IA Act, RGPD) et Éthique	16	14	0	\N	elearning_async	2026-02-03 16:24:00.460132+01	2026-02-03 16:24:17.384123+01	0	\N	\N
42	2959	237	IA - Module 1 : Introduction au monde de l'intelligence artificielle (IA)	12	15	100	2025-05-16 09:27:54+02	elearning_async	2026-02-03 16:24:00.780039+01	2026-02-03 16:24:17.644701+01	3546	2025-05-16 08:27:56+02	2025-05-16 09:27:46+02
43	2960	238	IA - Module 2 : Les concepts, modèles d’IA, et l'ingénierie de l'invite	13	15	100	2025-05-20 14:13:17+02	elearning_async	2026-02-03 16:24:00.780051+01	2026-02-03 16:24:17.644701+01	25080	2025-05-16 09:32:05+02	2025-05-18 10:11:27+02
47	6065	237	IA - Module 1 : Introduction au monde de l'intelligence artificielle (IA)	12	16	100	2025-06-06 16:29:08+02	elearning_async	2026-02-03 16:24:01.104212+01	2026-02-03 16:24:17.949245+01	2894	2025-06-06 15:25:23+02	2025-06-06 16:27:48+02
48	6066	238	IA - Module 2 : Les concepts, modèles d’IA, et l'ingénierie de l'invite	13	16	100	2025-06-11 07:23:07+02	elearning_async	2026-02-03 16:24:01.104224+01	2026-02-03 16:24:17.949245+01	11160	2025-06-06 16:31:51+02	2025-06-11 07:22:58+02
49	6067	239	IA - Module 3 : La génération d’images et les données au cœur de l’IA générative	14	16	3	2025-06-11 07:27:59+02	elearning_async	2026-02-03 16:24:01.104228+01	2026-02-03 16:24:17.949245+01	1662	2025-06-11 07:27:59+02	\N
52	1085	333	Management	26	19	96	2025-10-07 14:29:49+02	elearning_async	2026-02-03 16:24:02.388223+01	2026-02-03 16:24:19.210292+01	43726	2025-05-03 10:54:36+02	\N
53	1089	333	Management	26	20	100	2025-07-10 15:15:58+02	elearning_async	2026-02-03 16:24:02.624427+01	2026-02-03 16:24:19.435035+01	81276	2025-04-14 12:21:54+02	2025-05-28 20:56:13+02
54	1880	333	Management	26	21	3	2025-05-02 16:47:02+02	elearning_async	2026-02-03 16:24:02.846065+01	2026-02-03 16:24:19.655151+01	98	2025-05-02 16:47:01+02	\N
55	2831	333	Management	26	22	90	2025-05-28 09:49:45+02	elearning_async	2026-02-03 16:24:03.056508+01	2026-02-03 16:24:19.882+01	16602	2025-05-07 18:51:50+02	\N
56	16934	1605	[TP SC] E-learning	30	23	0	\N	elearning_async	2026-02-03 16:24:03.488342+01	2026-02-03 16:24:20.360592+01	0	\N	\N
57	16740	1455	[TP FPA] E-learning	33	25	0	\N	elearning_async	2026-02-03 16:24:04.326176+01	2026-02-03 16:24:21.09989+01	0	\N	\N
58	16303	1358	Espagnol - CLOE (e-learning)	39	30	0	\N	elearning_async	2026-02-03 16:24:06.420232+01	2026-02-03 16:24:22.927733+01	0	\N	\N
59	16742	1457	[TP FPA] E-learning	42	32	0	\N	elearning_async	2026-02-03 16:24:07.125486+01	2026-02-03 16:24:23.682236+01	0	\N	\N
60	1507	502	TPE Créactifs Module 1.1 : De la facture au règlement	45	34	100	2025-04-16 16:38:23+02	elearning_async	2026-02-03 16:24:07.91895+01	2026-02-03 16:24:24.553461+01	7800	2025-04-14 16:32:23+02	2025-04-16 16:34:24+02
61	1508	503	TPE Créactifs Module 1.2 : La TVA	46	34	100	2025-04-22 16:47:49+02	elearning_async	2026-02-03 16:24:07.918955+01	2026-02-03 16:24:24.553461+01	12540	2025-04-16 16:43:47+02	2025-04-22 16:40:27+02
62	1509	504	TPE Créactifs Module 1.3 : Typologie de revenus	47	34	100	2025-04-25 17:18:23+02	elearning_async	2026-02-03 16:24:07.918956+01	2026-02-03 16:24:24.553461+01	10440	2025-04-22 16:49:23+02	2025-04-25 17:03:08+02
63	1510	505	TPE Créactifs Module 1.4 : Calcul et liquidation de l'IS	48	34	100	2025-04-28 17:02:45+02	elearning_async	2026-02-03 16:24:07.918957+01	2026-02-03 16:24:24.553461+01	2340	2025-04-25 17:23:05+02	2025-04-28 17:00:30+02
64	1511	506	TPE Créactifs Module 1.5 : Social	49	34	100	2025-04-29 12:51:08+02	elearning_async	2026-02-03 16:24:07.918958+01	2026-02-03 16:24:24.553461+01	7380	2025-04-28 17:03:54+02	2025-04-29 12:50:25+02
67	1515	510	TPE Créactifs Module 5 : Les écritures d’inventaire	53	34	0	\N	elearning_async	2026-02-03 16:24:07.918962+01	2026-02-03 16:24:24.553461+01	0	\N	\N
71	1919	502	TPE Créactifs Module 1.1 : De la facture au règlement	45	35	100	2025-07-16 20:15:33+02	elearning_async	2026-02-03 16:24:08.193484+01	2026-02-03 16:24:24.846333+01	53080	2025-05-12 13:40:26+02	2025-07-16 20:14:48+02
72	1920	503	TPE Créactifs Module 1.2 : La TVA	46	35	100	2025-07-23 12:13:21+02	elearning_async	2026-02-03 16:24:08.19349+01	2026-02-03 16:24:24.846333+01	9600	2025-07-16 21:16:47+02	2025-07-23 12:11:03+02
73	1921	504	TPE Créactifs Module 1.3 : Typologie de revenus	47	35	20	2025-07-23 12:38:19+02	elearning_async	2026-02-03 16:24:08.193491+01	2026-02-03 16:24:24.846333+01	1320	2025-07-23 12:15:18+02	\N
74	1922	505	TPE Créactifs Module 1.4 : Calcul et liquidation de l'IS	48	35	0	\N	elearning_async	2026-02-03 16:24:08.193493+01	2026-02-03 16:24:24.846333+01	0	\N	\N
75	1923	506	TPE Créactifs Module 1.5 : Social	49	35	0	\N	elearning_async	2026-02-03 16:24:08.193494+01	2026-02-03 16:24:24.846333+01	0	\N	\N
76	1924	507	TPE Créactifs Module 2 : Les outils d’analyse financière	50	35	0	\N	elearning_async	2026-02-03 16:24:08.193495+01	2026-02-03 16:24:24.846333+01	0	\N	\N
77	1925	508	TPE Créactifs Module 3 : Les  outils de l’analyse prévisionnelle	51	35	0	\N	elearning_async	2026-02-03 16:24:08.193496+01	2026-02-03 16:24:24.846333+01	0	\N	\N
78	1927	510	TPE Créactifs Module 5 : Les écritures d’inventaire	53	35	0	\N	elearning_async	2026-02-03 16:24:08.193497+01	2026-02-03 16:24:24.846333+01	0	\N	\N
79	1928	511	TPE Créactifs Module 6 : Les écarts entre le prévisionnel et le réalisé	54	35	0	\N	elearning_async	2026-02-03 16:24:08.193498+01	2026-02-03 16:24:24.846333+01	0	\N	\N
80	1929	512	TPE Créactifs Module 7 : Devenir un communicant	55	35	0	\N	elearning_async	2026-02-03 16:24:08.193499+01	2026-02-03 16:24:24.846333+01	0	\N	\N
81	1930	518	Altercampus	56	35	0	\N	elearning_async	2026-02-03 16:24:08.1935+01	2026-02-03 16:24:24.846333+01	0	\N	\N
82	2873	502	TPE Créactifs Module 1.1 : De la facture au règlement	45	36	50	2025-06-25 22:29:42+02	elearning_async	2026-02-03 16:24:08.467662+01	2026-02-03 16:24:25.218345+01	60480	2025-05-24 18:12:33+02	\N
83	2874	503	TPE Créactifs Module 1.2 : La TVA	46	36	0	\N	elearning_async	2026-02-03 16:24:08.467668+01	2026-02-03 16:24:25.218345+01	0	\N	\N
84	2875	504	TPE Créactifs Module 1.3 : Typologie de revenus	47	36	0	\N	elearning_async	2026-02-03 16:24:08.46767+01	2026-02-03 16:24:25.218345+01	0	\N	\N
85	2876	505	TPE Créactifs Module 1.4 : Calcul et liquidation de l'IS	48	36	0	\N	elearning_async	2026-02-03 16:24:08.467672+01	2026-02-03 16:24:25.218345+01	0	\N	\N
86	2877	506	TPE Créactifs Module 1.5 : Social	49	36	0	\N	elearning_async	2026-02-03 16:24:08.467674+01	2026-02-03 16:24:25.218345+01	0	\N	\N
87	2878	507	TPE Créactifs Module 2 : Les outils d’analyse financière	50	36	0	\N	elearning_async	2026-02-03 16:24:08.467676+01	2026-02-03 16:24:25.218345+01	0	\N	\N
88	2879	508	TPE Créactifs Module 3 : Les  outils de l’analyse prévisionnelle	51	36	0	\N	elearning_async	2026-02-03 16:24:08.467678+01	2026-02-03 16:24:25.218345+01	0	\N	\N
89	2881	510	TPE Créactifs Module 5 : Les écritures d’inventaire	53	36	0	\N	elearning_async	2026-02-03 16:24:08.467679+01	2026-02-03 16:24:25.218345+01	0	\N	\N
90	2882	511	TPE Créactifs Module 6 : Les écarts entre le prévisionnel et le réalisé	54	36	0	\N	elearning_async	2026-02-03 16:24:08.467681+01	2026-02-03 16:24:25.218345+01	0	\N	\N
91	2883	512	TPE Créactifs Module 7 : Devenir un communicant	55	36	0	\N	elearning_async	2026-02-03 16:24:08.467683+01	2026-02-03 16:24:25.218345+01	0	\N	\N
92	2884	518	Altercampus	56	36	0	\N	elearning_async	2026-02-03 16:24:08.467685+01	2026-02-03 16:24:25.218345+01	0	\N	\N
104	14343	502	TPE Créactifs Module 1.1 : De la facture au règlement	45	38	100	2025-07-01 08:04:10+02	elearning_async	2026-02-03 16:24:08.946324+01	2026-02-03 16:24:25.853758+01	18858	2025-06-27 17:46:26+02	2025-07-01 08:00:06+02
105	14344	503	TPE Créactifs Module 1.2 : La TVA	46	38	100	2025-09-12 19:27:05+02	elearning_async	2026-02-03 16:24:08.946329+01	2026-02-03 16:24:25.853758+01	26700	2025-07-01 08:04:09+02	2025-09-11 06:58:44+02
106	14345	504	TPE Créactifs Module 1.3 : Typologie de revenus	47	38	80	2025-10-12 07:01:02+02	elearning_async	2026-02-03 16:24:08.94633+01	2026-02-03 16:24:25.853758+01	11460	2025-09-12 19:27:04+02	\N
107	14346	505	TPE Créactifs Module 1.4 : Calcul et liquidation de l'IS	48	38	100	2025-09-23 08:52:34+02	elearning_async	2026-02-03 16:24:08.946331+01	2026-02-03 16:24:25.853758+01	3420	2025-09-22 08:47:56+02	2025-09-23 08:40:20+02
108	14347	506	TPE Créactifs Module 1.5 : Social	49	38	100	2025-09-08 19:14:46+02	elearning_async	2026-02-03 16:24:08.946332+01	2026-02-03 16:24:25.853758+01	7980	2025-09-07 09:10:07+02	2025-09-08 19:13:04+02
109	14348	507	TPE Créactifs Module 2 : Les outils d’analyse financière	50	38	100	2025-10-05 11:19:14+02	elearning_async	2026-02-03 16:24:08.946333+01	2026-02-03 16:24:25.853758+01	32347	2025-07-10 15:08:00+02	2025-10-05 11:18:41+02
110	14349	508	TPE Créactifs Module 3 : Les  outils de l’analyse prévisionnelle	51	38	100	2025-10-05 11:28:17+02	elearning_async	2026-02-03 16:24:08.946334+01	2026-02-03 16:24:25.853758+01	26940	2025-07-13 08:35:33+02	2025-10-05 11:28:09+02
111	14351	510	TPE Créactifs Module 5 : Les écritures d’inventaire	53	38	28	2025-10-12 07:20:55+02	elearning_async	2026-02-03 16:24:08.946335+01	2026-02-03 16:24:25.853758+01	6360	2025-07-28 08:24:21+02	\N
112	14352	511	TPE Créactifs Module 6 : Les écarts entre le prévisionnel et le réalisé	54	38	100	2025-10-12 09:01:29+02	elearning_async	2026-02-03 16:24:08.946336+01	2026-02-03 16:24:25.853758+01	16260	2025-09-30 18:34:04+02	2025-10-12 09:01:17+02
115	15917	502	TPE Créactifs Module 1.1 : De la facture au règlement	45	39	100	2025-07-07 18:37:11+02	elearning_async	2026-02-03 16:24:09.177002+01	2026-02-03 16:24:26.152688+01	8904	2025-06-20 19:23:05+02	2025-06-30 19:31:48+02
116	15918	503	TPE Créactifs Module 1.2 : La TVA	46	39	100	2025-07-07 19:11:38+02	elearning_async	2026-02-03 16:24:09.177006+01	2026-02-03 16:24:26.152688+01	4140	2025-06-30 19:36:53+02	2025-07-07 19:08:37+02
117	15919	504	TPE Créactifs Module 1.3 : Typologie de revenus	47	39	80	2025-07-29 18:36:05+02	elearning_async	2026-02-03 16:24:09.177007+01	2026-02-03 16:24:26.152688+01	6552	2025-06-28 10:10:37+02	\N
118	15920	505	TPE Créactifs Module 1.4 : Calcul et liquidation de l'IS	48	39	0	\N	elearning_async	2026-02-03 16:24:09.177008+01	2026-02-03 16:24:26.152688+01	0	\N	\N
119	15921	506	TPE Créactifs Module 1.5 : Social	49	39	0	\N	elearning_async	2026-02-03 16:24:09.177009+01	2026-02-03 16:24:26.152688+01	0	\N	\N
120	15922	507	TPE Créactifs Module 2 : Les outils d’analyse financière	50	39	100	2025-07-29 21:00:53+02	elearning_async	2026-02-03 16:24:09.17701+01	2026-02-03 16:24:26.152688+01	5924	2025-06-29 12:52:15+02	2025-07-27 07:48:18+02
121	15923	508	TPE Créactifs Module 3 : Les  outils de l’analyse prévisionnelle	51	39	100	2025-08-09 12:58:46+02	elearning_async	2026-02-03 16:24:09.177011+01	2026-02-03 16:24:26.152688+01	3240	2025-07-28 21:03:07+02	2025-07-29 21:03:42+02
122	15925	510	TPE Créactifs Module 5 : Les écritures d’inventaire	53	39	85	2025-08-23 08:15:57+02	elearning_async	2026-02-03 16:24:09.177012+01	2026-02-03 16:24:26.152688+01	10560	2025-08-05 18:30:19+02	\N
123	15926	511	TPE Créactifs Module 6 : Les écarts entre le prévisionnel et le réalisé	54	39	0	\N	elearning_async	2026-02-03 16:24:09.177014+01	2026-02-03 16:24:26.152688+01	0	\N	\N
124	15927	512	TPE Créactifs Module 7 : Devenir un communicant	55	39	0	\N	elearning_async	2026-02-03 16:24:09.177015+01	2026-02-03 16:24:26.152688+01	0	\N	\N
125	15928	518	Altercampus	56	39	0	\N	elearning_async	2026-02-03 16:24:09.177016+01	2026-02-03 16:24:26.152688+01	0	\N	\N
137	16936	502	TPE Créactifs Module 1.1 : De la facture au règlement	45	41	100	2025-09-17 12:44:31+02	elearning_async	2026-02-03 16:24:09.696487+01	2026-02-03 16:24:26.768127+01	6240	2025-06-25 10:28:50+02	2025-06-30 16:37:14+02
138	16937	503	TPE Créactifs Module 1.2 : La TVA	46	41	100	2025-07-02 10:38:17+02	elearning_async	2026-02-03 16:24:09.696491+01	2026-02-03 16:24:26.768127+01	4074	2025-06-26 11:15:14+02	2025-07-02 10:37:11+02
139	16938	504	TPE Créactifs Module 1.3 : Typologie de revenus	47	41	100	2025-10-27 16:17:17+01	elearning_async	2026-02-03 16:24:09.696492+01	2026-02-03 16:24:26.768127+01	5220	2025-07-02 10:41:13+02	2025-07-08 19:11:36+02
140	16939	505	TPE Créactifs Module 1.4 : Calcul et liquidation de l'IS	48	41	100	2025-10-06 21:24:21+02	elearning_async	2026-02-03 16:24:09.696493+01	2026-02-03 16:24:26.768127+01	2400	2025-10-06 20:39:15+02	2025-10-06 21:16:38+02
1	20189	2281	TPE - Module 1 : De la facture au règlement	3	1	0	\N	elearning_async	2026-02-03 16:23:56.386509+01	2026-02-03 16:24:13.325043+01	0	\N	\N
2	20190	2282	TPE - Module 2 : Les outils d'analyse financière	4	1	0	\N	elearning_async	2026-02-03 16:23:56.386513+01	2026-02-03 16:24:13.325043+01	0	\N	\N
3	20191	2283	TPE - Module 3 : Les outils de l’analyse prévisionnelle	2	1	0	\N	elearning_async	2026-02-03 16:23:56.386514+01	2026-02-03 16:24:13.325043+01	0	\N	\N
4	20192	2284	TPE - Module 4 : Les écarts entre le prévisionnel et le réalisé	5	1	0	\N	elearning_async	2026-02-03 16:23:56.386515+01	2026-02-03 16:24:13.325043+01	0	\N	\N
5	20193	2285	TPE - Module 5 : Devenir un communicant	1	1	0	\N	elearning_async	2026-02-03 16:23:56.386517+01	2026-02-03 16:24:13.325043+01	0	\N	\N
6	20194	2286	TPE - Module 6 : Contenus complémentaires	6	1	0	\N	elearning_async	2026-02-03 16:23:56.386518+01	2026-02-03 16:24:13.325043+01	0	\N	\N
148	21902	502	TPE Créactifs Module 1.1 : De la facture au règlement	45	42	0	\N	elearning_async	2026-02-03 16:24:09.922042+01	2026-02-03 16:24:27.114408+01	0	\N	\N
149	21903	503	TPE Créactifs Module 1.2 : La TVA	46	42	0	\N	elearning_async	2026-02-03 16:24:09.922046+01	2026-02-03 16:24:27.114408+01	0	\N	\N
150	21904	504	TPE Créactifs Module 1.3 : Typologie de revenus	47	42	0	\N	elearning_async	2026-02-03 16:24:09.922047+01	2026-02-03 16:24:27.114408+01	0	\N	\N
151	21905	505	TPE Créactifs Module 1.4 : Calcul et liquidation de l'IS	48	42	0	\N	elearning_async	2026-02-03 16:24:09.922048+01	2026-02-03 16:24:27.114408+01	0	\N	\N
152	21906	506	TPE Créactifs Module 1.5 : Social	49	42	0	\N	elearning_async	2026-02-03 16:24:09.922049+01	2026-02-03 16:24:27.114408+01	0	\N	\N
153	21907	507	TPE Créactifs Module 2 : Les outils d’analyse financière	50	42	0	\N	elearning_async	2026-02-03 16:24:09.92205+01	2026-02-03 16:24:27.114408+01	0	\N	\N
154	21908	508	TPE Créactifs Module 3 : Les  outils de l’analyse prévisionnelle	51	42	0	\N	elearning_async	2026-02-03 16:24:09.922051+01	2026-02-03 16:24:27.114408+01	0	\N	\N
159	2836	530	[AE MI] Partie 1 : Méthodologie & Données d'entrée	57	43	100	2025-06-06 17:43:53+02	elearning_async	2026-02-03 16:24:10.377266+01	2026-02-03 16:24:27.62677+01	25316	2025-05-05 13:42:10+02	2025-05-11 15:08:19+02
160	2839	531	[AE] Guide du DPE	58	43	100	2025-06-06 23:26:45+02	elearning_async	2026-02-03 16:24:10.377276+01	2026-02-03 16:24:27.62677+01	61122	2025-05-11 18:44:18+02	2025-05-27 14:46:19+02
161	2840	532	[AE MI] Partie 2 : Contraintes et Pathologies	59	43	100	2025-05-11 18:41:39+02	elearning_async	2026-02-03 16:24:10.37728+01	2026-02-03 16:24:27.62677+01	4688	2025-05-11 15:12:11+02	2025-05-11 18:40:27+02
162	2841	533	[AE MI] Partie 3 : Conception de scénarios	60	43	100	2025-05-31 10:45:14+02	elearning_async	2026-02-03 16:24:10.377283+01	2026-02-03 16:24:27.62677+01	7172	2025-05-24 14:10:44+02	2025-05-26 12:44:47+02
163	2842	534	[AE MI] Partie 4 : Le rapport	62	43	100	2025-05-31 10:42:55+02	elearning_async	2026-02-03 16:24:10.377287+01	2026-02-03 16:24:27.62677+01	2472	2025-05-26 14:38:28+02	2025-05-26 15:06:04+02
164	2843	535	[AE MI] Cas Pratique	61	43	100	2025-05-31 10:44:10+02	elearning_async	2026-02-03 16:24:10.377291+01	2026-02-03 16:24:27.62677+01	5686	2025-05-26 13:18:15+02	2025-05-26 14:32:26+02
165	2844	530	[AE MI] Partie 1 : Méthodologie & Données d'entrée	57	44	100	2025-05-09 10:58:41+02	elearning_async	2026-02-03 16:24:10.60812+01	2026-02-03 16:24:27.89812+01	29316	2025-05-06 15:17:21+02	2025-05-09 10:57:51+02
166	2847	531	[AE] Guide du DPE	58	44	56	2025-05-21 00:01:54+02	elearning_async	2026-02-03 16:24:10.608133+01	2026-02-03 16:24:27.89812+01	42514	2025-05-09 11:00:24+02	\N
167	2848	532	[AE MI] Partie 2 : Contraintes et Pathologies	59	44	0	\N	elearning_async	2026-02-03 16:24:10.608137+01	2026-02-03 16:24:27.89812+01	0	\N	\N
168	2849	533	[AE MI] Partie 3 : Conception de scénarios	60	44	0	\N	elearning_async	2026-02-03 16:24:10.608141+01	2026-02-03 16:24:27.89812+01	0	\N	\N
169	2850	534	[AE MI] Partie 4 : Le rapport	62	44	0	\N	elearning_async	2026-02-03 16:24:10.608144+01	2026-02-03 16:24:27.89812+01	0	\N	\N
170	2851	535	[AE MI] Cas Pratique	61	44	0	\N	elearning_async	2026-02-03 16:24:10.608148+01	2026-02-03 16:24:27.89812+01	0	\N	\N
171	14195	530	[AE MI] Partie 1 : Méthodologie & Données d'entrée	57	45	0	\N	elearning_async	2026-02-03 16:24:10.878215+01	2026-02-03 16:24:28.168911+01	0	\N	\N
172	14196	531	[AE] Guide du DPE	58	45	0	\N	elearning_async	2026-02-03 16:24:10.878228+01	2026-02-03 16:24:28.168911+01	0	\N	\N
173	14197	532	[AE MI] Partie 2 : Contraintes et Pathologies	59	45	0	\N	elearning_async	2026-02-03 16:24:10.878232+01	2026-02-03 16:24:28.168911+01	0	\N	\N
174	14198	533	[AE MI] Partie 3 : Conception de scénarios	60	45	0	\N	elearning_async	2026-02-03 16:24:10.878235+01	2026-02-03 16:24:28.168911+01	0	\N	\N
175	14199	535	[AE MI] Cas Pratique	61	45	0	\N	elearning_async	2026-02-03 16:24:10.878239+01	2026-02-03 16:24:28.168911+01	0	\N	\N
176	14200	534	[AE MI] Partie 4 : Le rapport	62	45	0	\N	elearning_async	2026-02-03 16:24:10.878243+01	2026-02-03 16:24:28.168911+01	0	\N	\N
177	14271	530	[AE MI] Partie 1 : Méthodologie & Données d'entrée	57	46	0	\N	elearning_async	2026-02-03 16:24:11.141128+01	2026-02-03 16:24:28.413021+01	0	\N	\N
178	14272	531	[AE] Guide du DPE	58	46	0	\N	elearning_async	2026-02-03 16:24:11.141141+01	2026-02-03 16:24:28.413021+01	0	\N	\N
179	14273	532	[AE MI] Partie 2 : Contraintes et Pathologies	59	46	0	\N	elearning_async	2026-02-03 16:24:11.141145+01	2026-02-03 16:24:28.413021+01	0	\N	\N
180	14274	533	[AE MI] Partie 3 : Conception de scénarios	60	46	0	\N	elearning_async	2026-02-03 16:24:11.141149+01	2026-02-03 16:24:28.413021+01	0	\N	\N
181	14275	535	[AE MI] Cas Pratique	61	46	0	\N	elearning_async	2026-02-03 16:24:11.141153+01	2026-02-03 16:24:28.413021+01	0	\N	\N
182	14276	534	[AE MI] Partie 4 : Le rapport	62	46	0	\N	elearning_async	2026-02-03 16:24:11.141157+01	2026-02-03 16:24:28.413021+01	0	\N	\N
183	16744	1459	[TP FPA] E-learning	75	63	0	\N	elearning_async	2026-02-03 16:24:15.612957+01	2026-02-03 16:24:33.003299+01	0	\N	\N
184	2756	648	DPE - Sans Mention	77	64	100	2025-12-10 09:12:19+01	elearning_async	2026-02-03 16:24:16.068439+01	2026-02-03 16:24:33.432741+01	225962	2025-05-07 14:23:22+02	2025-09-02 13:36:53+02
185	27027	2856	[AE MI] Partie 1 : Méthodologie & Données d'entrée	79	64	0	\N	elearning_async	2026-02-03 16:24:16.068451+01	2026-02-03 16:24:33.432741+01	0	\N	\N
288	3369	777	Audit énergétique - BCT	153	85	0	\N	elearning_async	2026-02-03 16:24:23.42898+01	2026-02-03 16:24:40.482223+01	0	\N	\N
189	17447	648	DPE - Sans Mention	77	65	47	2025-12-09 15:00:40+01	elearning_async	2026-02-03 16:24:16.288876+01	2026-02-03 16:24:33.672361+01	54880	2025-07-29 12:56:36+02	\N
190	27028	2856	[AE MI] Partie 1 : Méthodologie & Données d'entrée	79	65	0	\N	elearning_async	2026-02-03 16:24:16.288887+01	2026-02-03 16:24:33.672361+01	0	\N	\N
191	27031	2857	[AE MI] Partie 2 : Contraintes et Pathologies	80	65	0	\N	elearning_async	2026-02-03 16:24:16.28889+01	2026-02-03 16:24:33.672361+01	0	\N	\N
194	14313	1012	[TP SAMS] - Module 1 : Assister une équipe dans la communication des informations	83	66	100	2025-10-28 21:47:36+01	elearning_async	2026-02-03 16:24:16.780403+01	2026-02-03 16:24:34.124712+01	50444	2025-06-08 21:25:25+02	2025-07-06 22:18:56+02
195	14315	1013	[TP SAMS] - Module 2 : Assurer l'accueil et la prise en charge administrative du patient ou de l'usager	99	66	100	2025-10-28 21:45:50+01	elearning_async	2026-02-03 16:24:16.780409+01	2026-02-03 16:24:34.124712+01	41532	2025-07-06 22:29:29+02	2025-08-10 15:29:06+02
196	14317	1014	[TP SAMS] - Module 3 : Traiter les dossiers et coordonner les opérations liées au parcours du patient ou de l'usager	100	66	100	2025-10-28 22:03:45+01	elearning_async	2026-02-03 16:24:16.780411+01	2026-02-03 16:24:34.124712+01	33652	2025-08-10 15:31:23+02	2025-08-21 21:41:53+02
200	14314	1012	[TP SAMS] - Module 1 : Assister une équipe dans la communication des informations	83	67	60	2025-06-18 23:29:54+02	elearning_async	2026-02-03 16:24:17.09733+01	2026-02-03 16:24:34.40916+01	15818	2025-06-18 16:05:10+02	\N
201	14316	1013	[TP SAMS] - Module 2 : Assurer l'accueil et la prise en charge administrative du patient ou de l'usager	99	67	100	2025-06-08 16:52:23+02	elearning_async	2026-02-03 16:24:17.097337+01	2026-02-03 16:24:34.40916+01	40816	2025-06-02 16:43:39+02	2025-06-08 00:43:02+02
202	14318	1014	[TP SAMS] - Module 3 : Traiter les dossiers et coordonner les opérations liées au parcours du patient ou de l'usager	100	67	0	\N	elearning_async	2026-02-03 16:24:17.097339+01	2026-02-03 16:24:34.40916+01	0	\N	\N
203	14320	1015	[TP SAMS] - Module 4 : Dossier Professionnel pour la Certification	101	67	0	\N	elearning_async	2026-02-03 16:24:17.097341+01	2026-02-03 16:24:34.40916+01	0	\N	\N
204	14322	1016	[TP SAMS] - Module 5 : Transversal	102	67	0	\N	elearning_async	2026-02-03 16:24:17.097343+01	2026-02-03 16:24:34.40916+01	0	\N	\N
205	14324	1017	[TP SAMS] - Module 6 : Evaluations	103	67	0	\N	elearning_async	2026-02-03 16:24:17.097345+01	2026-02-03 16:24:34.40916+01	0	\N	\N
206	16725	1440	[TP FPA] E-learning	104	68	0	\N	elearning_async	2026-02-03 16:24:17.514175+01	2026-02-03 16:24:35.053902+01	0	\N	\N
207	2863	682	CréActifs - Formation Création d'Entreprise	106	69	13	2025-05-19 21:09:31+02	elearning_async	2026-02-03 16:24:17.961054+01	2026-02-03 16:24:35.430516+01	6448	2025-05-19 20:30:57+02	\N
208	2864	682	CréActifs - Formation Création d'Entreprise	106	70	82	2025-06-22 18:04:25+02	elearning_async	2026-02-03 16:24:18.195818+01	2026-02-03 16:24:35.629924+01	48234	2025-05-02 20:51:36+02	\N
209	14368	682	CréActifs - Formation Création d'Entreprise	106	71	100	2025-07-29 10:28:58+02	elearning_async	2026-02-03 16:24:18.432191+01	2026-02-03 16:24:35.833122+01	37970	2025-06-11 19:49:26+02	2025-07-29 10:41:32+02
210	14672	682	CréActifs - Formation Création d'Entreprise	106	72	81	2025-12-26 11:35:11+01	elearning_async	2026-02-03 16:24:18.671889+01	2026-02-03 16:24:36.081689+01	24600	2025-06-10 17:01:35+02	\N
211	15794	682	CréActifs - Formation Création d'Entreprise	106	73	0	\N	elearning_async	2026-02-03 16:24:18.895463+01	2026-02-03 16:24:36.256049+01	0	\N	\N
212	15853	682	CréActifs - Formation Création d'Entreprise	106	74	100	2025-08-19 09:09:15+02	elearning_async	2026-02-03 16:24:19.112167+01	2026-02-03 16:24:36.523343+01	10755	2025-08-07 14:07:43+02	2025-08-19 09:35:43+02
213	15857	682	CréActifs - Formation Création d'Entreprise	106	75	61	2025-06-26 10:12:29+02	elearning_async	2026-02-03 16:24:19.327098+01	2026-02-03 16:24:36.715923+01	23466	2025-06-23 11:16:39+02	\N
214	15932	682	CréActifs - Formation Création d'Entreprise	106	76	0	\N	elearning_async	2026-02-03 16:24:19.575161+01	2026-02-03 16:24:36.91791+01	0	\N	\N
215	16271	682	CréActifs - Formation Création d'Entreprise	106	77	0	\N	elearning_async	2026-02-03 16:24:19.785109+01	2026-02-03 16:24:37.119694+01	0	\N	\N
216	17737	682	CréActifs - Formation Création d'Entreprise	106	78	0	\N	elearning_async	2026-02-03 16:24:20.001587+01	2026-02-03 16:24:37.320796+01	0	\N	\N
217	3249	749	Chef de projet en rénovation énergétique - Bienvenue	115	83	100	2025-05-22 10:48:23+02	elearning_async	2026-02-03 16:24:22.430602+01	2026-02-03 16:24:39.457948+01	10716	2025-05-17 10:34:02+02	2025-05-20 22:18:07+02
218	3264	750	Blocs 1 et 2 - Bienvenue !	117	83	0	\N	elearning_async	2026-02-03 16:24:22.430605+01	2026-02-03 16:24:39.457948+01	0	\N	\N
219	3265	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	83	100	2025-06-23 08:53:35+02	elearning_async	2026-02-03 16:24:22.430606+01	2026-02-03 16:24:39.457948+01	15732	2025-06-05 12:27:49+02	2025-06-23 08:57:36+02
220	3266	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	83	57	2025-10-08 21:33:23+02	elearning_async	2026-02-03 16:24:22.430607+01	2026-02-03 16:24:39.457948+01	26799	2025-08-13 19:28:47+02	\N
221	3267	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	83	0	\N	elearning_async	2026-02-03 16:24:22.430609+01	2026-02-03 16:24:39.457948+01	0	\N	\N
222	3268	756	Eco-conseiller - Module 4 : Aides et subventions	136	83	0	\N	elearning_async	2026-02-03 16:24:22.43061+01	2026-02-03 16:24:39.457948+01	0	\N	\N
223	3269	757	Eco-conseiller - Module 5 : La relation client	137	83	0	\N	elearning_async	2026-02-03 16:24:22.430611+01	2026-02-03 16:24:39.457948+01	0	\N	\N
26	708	241	IA - Module 5 : Réglementations (IA Act, RGPD) et Éthique	16	11	100	2025-05-15 14:50:44+02	elearning_async	2026-02-03 16:23:59.550751+01	2026-02-03 16:24:16.465705+01	1436	2025-05-15 14:22:21+02	2025-05-15 14:50:40+02
44	2961	239	IA - Module 3 : La génération d’images et les données au cœur de l’IA générative	14	15	100	2025-05-20 16:47:07+02	elearning_async	2026-02-03 16:24:00.780055+01	2026-02-03 16:24:17.644701+01	9202	2025-05-20 14:13:15+02	2025-05-20 16:49:52+02
45	2962	240	IA - Module 4 : Confidentialité et Sécurité dans l’Utilisation de l’IA Générative	15	15	100	2025-05-27 19:03:39+02	elearning_async	2026-02-03 16:24:00.780058+01	2026-02-03 16:24:17.644701+01	2072	2025-05-27 18:22:17+02	2025-05-27 19:03:35+02
46	2963	241	IA - Module 5 : Réglementations (IA Act, RGPD) et Éthique	16	15	100	2025-06-09 19:41:25+02	elearning_async	2026-02-03 16:24:00.780062+01	2026-02-03 16:24:17.644701+01	1894	2025-06-09 19:04:26+02	2025-06-09 19:37:30+02
50	6068	240	IA - Module 4 : Confidentialité et Sécurité dans l’Utilisation de l’IA Générative	15	16	100	2025-06-11 08:22:32+02	elearning_async	2026-02-03 16:24:01.104231+01	2026-02-03 16:24:17.949245+01	642	2025-06-11 08:08:19+02	2025-06-11 08:22:31+02
51	6069	241	IA - Module 5 : Réglementations (IA Act, RGPD) et Éthique	16	16	100	2025-06-11 08:36:58+02	elearning_async	2026-02-03 16:24:01.104235+01	2026-02-03 16:24:17.949245+01	618	2025-06-11 08:24:10+02	2025-06-11 08:36:54+02
65	1512	507	TPE Créactifs Module 2 : Les outils d’analyse financière	50	34	50	2025-04-29 17:45:57+02	elearning_async	2026-02-03 16:24:07.918959+01	2026-02-03 16:24:24.553461+01	8460	2025-04-29 15:23:08+02	\N
66	1513	508	TPE Créactifs Module 3 : Les  outils de l’analyse prévisionnelle	51	34	100	2025-08-01 14:44:31+02	elearning_async	2026-02-03 16:24:07.918961+01	2026-02-03 16:24:24.553461+01	10980	2025-06-24 11:51:15+02	2025-08-01 14:44:10+02
68	1516	511	TPE Créactifs Module 6 : Les écarts entre le prévisionnel et le réalisé	54	34	0	\N	elearning_async	2026-02-03 16:24:07.918963+01	2026-02-03 16:24:24.553461+01	0	\N	\N
69	1517	512	TPE Créactifs Module 7 : Devenir un communicant	55	34	0	\N	elearning_async	2026-02-03 16:24:07.918964+01	2026-02-03 16:24:24.553461+01	0	\N	\N
70	1525	518	Altercampus	56	34	0	\N	elearning_async	2026-02-03 16:24:07.918965+01	2026-02-03 16:24:24.553461+01	0	\N	\N
93	3236	502	TPE Créactifs Module 1.1 : De la facture au règlement	45	37	100	2025-06-23 16:00:46+02	elearning_async	2026-02-03 16:24:08.700845+01	2026-02-03 16:24:25.535538+01	23280	2025-06-10 13:19:45+02	2025-06-23 15:47:39+02
94	3237	503	TPE Créactifs Module 1.2 : La TVA	46	37	83	2025-07-09 18:59:06+02	elearning_async	2026-02-03 16:24:08.700849+01	2026-02-03 16:24:25.535538+01	4140	2025-06-23 16:00:45+02	\N
95	3238	504	TPE Créactifs Module 1.3 : Typologie de revenus	47	37	0	\N	elearning_async	2026-02-03 16:24:08.70085+01	2026-02-03 16:24:25.535538+01	0	\N	\N
96	3239	505	TPE Créactifs Module 1.4 : Calcul et liquidation de l'IS	48	37	0	\N	elearning_async	2026-02-03 16:24:08.700851+01	2026-02-03 16:24:25.535538+01	0	\N	\N
97	3240	506	TPE Créactifs Module 1.5 : Social	49	37	0	\N	elearning_async	2026-02-03 16:24:08.700852+01	2026-02-03 16:24:25.535538+01	0	\N	\N
98	3241	507	TPE Créactifs Module 2 : Les outils d’analyse financière	50	37	0	\N	elearning_async	2026-02-03 16:24:08.700853+01	2026-02-03 16:24:25.535538+01	0	\N	\N
99	3242	508	TPE Créactifs Module 3 : Les  outils de l’analyse prévisionnelle	51	37	0	\N	elearning_async	2026-02-03 16:24:08.700854+01	2026-02-03 16:24:25.535538+01	0	\N	\N
100	3244	510	TPE Créactifs Module 5 : Les écritures d’inventaire	53	37	0	\N	elearning_async	2026-02-03 16:24:08.700856+01	2026-02-03 16:24:25.535538+01	0	\N	\N
101	3245	511	TPE Créactifs Module 6 : Les écarts entre le prévisionnel et le réalisé	54	37	0	\N	elearning_async	2026-02-03 16:24:08.700857+01	2026-02-03 16:24:25.535538+01	0	\N	\N
102	3246	512	TPE Créactifs Module 7 : Devenir un communicant	55	37	0	\N	elearning_async	2026-02-03 16:24:08.700858+01	2026-02-03 16:24:25.535538+01	0	\N	\N
103	3247	518	Altercampus	56	37	0	\N	elearning_async	2026-02-03 16:24:08.700859+01	2026-02-03 16:24:25.535538+01	0	\N	\N
113	14353	512	TPE Créactifs Module 7 : Devenir un communicant	55	38	0	\N	elearning_async	2026-02-03 16:24:08.946337+01	2026-02-03 16:24:25.853758+01	0	\N	\N
114	14354	518	Altercampus	56	38	0	\N	elearning_async	2026-02-03 16:24:08.946338+01	2026-02-03 16:24:25.853758+01	0	\N	\N
126	16335	502	TPE Créactifs Module 1.1 : De la facture au règlement	45	40	100	2025-08-18 16:23:02+02	elearning_async	2026-02-03 16:24:09.428112+01	2026-02-03 16:24:26.468276+01	35040	2025-06-23 17:38:33+02	2025-08-18 16:05:16+02
127	16336	503	TPE Créactifs Module 1.2 : La TVA	46	40	100	2025-09-15 15:22:40+02	elearning_async	2026-02-03 16:24:09.428116+01	2026-02-03 16:24:26.468276+01	8809	2025-07-01 14:57:19+02	2025-08-19 16:19:44+02
128	16337	504	TPE Créactifs Module 1.3 : Typologie de revenus	47	40	100	2025-09-16 15:43:57+02	elearning_async	2026-02-03 16:24:09.428118+01	2026-02-03 16:24:26.468276+01	9741	2025-09-15 15:22:38+02	2025-09-16 15:42:34+02
129	16338	505	TPE Créactifs Module 1.4 : Calcul et liquidation de l'IS	48	40	100	2025-10-07 14:19:36+02	elearning_async	2026-02-03 16:24:09.428119+01	2026-02-03 16:24:26.468276+01	3960	2025-09-16 15:45:35+02	2025-09-18 22:30:45+02
130	16339	506	TPE Créactifs Module 1.5 : Social	49	40	100	2025-10-07 16:00:59+02	elearning_async	2026-02-03 16:24:09.42812+01	2026-02-03 16:24:26.468276+01	5700	2025-10-07 14:19:34+02	2025-10-07 15:56:24+02
131	16340	507	TPE Créactifs Module 2 : Les outils d’analyse financière	50	40	100	2025-10-09 15:44:44+02	elearning_async	2026-02-03 16:24:09.428121+01	2026-02-03 16:24:26.468276+01	11340	2025-07-02 20:02:50+02	2025-10-09 15:34:32+02
132	16341	508	TPE Créactifs Module 3 : Les  outils de l’analyse prévisionnelle	51	40	100	2025-10-12 21:42:32+02	elearning_async	2026-02-03 16:24:09.428122+01	2026-02-03 16:24:26.468276+01	13800	2025-10-09 15:44:41+02	2025-10-11 16:59:30+02
133	16343	510	TPE Créactifs Module 5 : Les écritures d’inventaire	53	40	100	2025-10-23 15:57:37+02	elearning_async	2026-02-03 16:24:09.428123+01	2026-02-03 16:24:26.468276+01	17160	2025-10-12 21:42:28+02	2025-10-23 15:52:38+02
134	16344	511	TPE Créactifs Module 6 : Les écarts entre le prévisionnel et le réalisé	54	40	100	2025-10-23 22:26:28+02	elearning_async	2026-02-03 16:24:09.428124+01	2026-02-03 16:24:26.468276+01	4800	2025-10-23 21:04:02+02	2025-10-23 22:26:12+02
135	16345	512	TPE Créactifs Module 7 : Devenir un communicant	55	40	100	2025-10-24 16:08:17+02	elearning_async	2026-02-03 16:24:09.428125+01	2026-02-03 16:24:26.468276+01	15428	2025-06-30 15:36:53+02	2025-10-24 16:08:09+02
136	16346	518	Altercampus	56	40	0	\N	elearning_async	2026-02-03 16:24:09.428126+01	2026-02-03 16:24:26.468276+01	0	\N	\N
141	16940	506	TPE Créactifs Module 1.5 : Social	49	41	100	2025-10-27 16:29:53+01	elearning_async	2026-02-03 16:24:09.696494+01	2026-02-03 16:24:26.768127+01	3300	2025-10-14 18:45:40+02	2025-10-14 21:20:31+02
142	16941	507	TPE Créactifs Module 2 : Les outils d’analyse financière	50	41	100	2025-10-27 16:37:30+01	elearning_async	2026-02-03 16:24:09.696495+01	2026-02-03 16:24:26.768127+01	16860	2025-07-08 09:14:14+02	2025-09-23 18:24:51+02
143	16942	508	TPE Créactifs Module 3 : Les  outils de l’analyse prévisionnelle	51	41	100	2025-10-14 21:39:43+02	elearning_async	2026-02-03 16:24:09.696496+01	2026-02-03 16:24:26.768127+01	3980	2025-09-09 16:14:08+02	2025-10-14 21:39:34+02
144	16944	510	TPE Créactifs Module 5 : Les écritures d’inventaire	53	41	100	2025-10-05 22:27:29+02	elearning_async	2026-02-03 16:24:09.696497+01	2026-02-03 16:24:26.768127+01	6720	2025-10-05 20:31:10+02	2025-10-05 22:25:54+02
145	16945	511	TPE Créactifs Module 6 : Les écarts entre le prévisionnel et le réalisé	54	41	100	2025-10-07 16:45:14+02	elearning_async	2026-02-03 16:24:09.696498+01	2026-02-03 16:24:26.768127+01	2220	2025-10-06 21:24:20+02	2025-10-07 16:44:28+02
146	16946	512	TPE Créactifs Module 7 : Devenir un communicant	55	41	50	2025-10-27 14:42:41+01	elearning_async	2026-02-03 16:24:09.6965+01	2026-02-03 16:24:26.768127+01	6558	2025-09-02 20:31:15+02	\N
147	16947	518	Altercampus	56	41	0	\N	elearning_async	2026-02-03 16:24:09.696501+01	2026-02-03 16:24:26.768127+01	0	\N	\N
155	21910	510	TPE Créactifs Module 5 : Les écritures d’inventaire	53	42	0	\N	elearning_async	2026-02-03 16:24:09.922052+01	2026-02-03 16:24:27.114408+01	0	\N	\N
156	21911	511	TPE Créactifs Module 6 : Les écarts entre le prévisionnel et le réalisé	54	42	0	\N	elearning_async	2026-02-03 16:24:09.922054+01	2026-02-03 16:24:27.114408+01	0	\N	\N
157	21912	512	TPE Créactifs Module 7 : Devenir un communicant	55	42	0	\N	elearning_async	2026-02-03 16:24:09.922055+01	2026-02-03 16:24:27.114408+01	0	\N	\N
158	21913	518	Altercampus	56	42	0	\N	elearning_async	2026-02-03 16:24:09.922056+01	2026-02-03 16:24:27.114408+01	0	\N	\N
186	27030	2857	[AE MI] Partie 2 : Contraintes et Pathologies	80	64	0	\N	elearning_async	2026-02-03 16:24:16.068456+01	2026-02-03 16:24:33.432741+01	0	\N	\N
244	3304	749	Chef de projet en rénovation énergétique - Bienvenue	115	84	100	2025-06-10 09:27:14+02	elearning_async	2026-02-03 16:24:22.945946+01	2026-02-03 16:24:39.953101+01	8520	2025-06-07 16:06:18+02	2025-06-10 10:08:27+02
245	3305	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	84	0	\N	elearning_async	2026-02-03 16:24:22.94595+01	2026-02-03 16:24:39.953101+01	0	\N	\N
246	3306	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	84	0	\N	elearning_async	2026-02-03 16:24:22.945951+01	2026-02-03 16:24:39.953101+01	0	\N	\N
247	3307	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	84	0	\N	elearning_async	2026-02-03 16:24:22.945952+01	2026-02-03 16:24:39.953101+01	0	\N	\N
248	3308	756	Eco-conseiller - Module 4 : Aides et subventions	136	84	0	\N	elearning_async	2026-02-03 16:24:22.945953+01	2026-02-03 16:24:39.953101+01	0	\N	\N
249	3309	757	Eco-conseiller - Module 5 : La relation client	137	84	0	\N	elearning_async	2026-02-03 16:24:22.945954+01	2026-02-03 16:24:39.953101+01	0	\N	\N
250	3310	752	Projet tutoré	114	84	18	2025-06-10 10:22:46+02	elearning_async	2026-02-03 16:24:22.945955+01	2026-02-03 16:24:39.953101+01	29550	2025-06-10 10:20:31+02	\N
251	3311	762	[AE] Guide du DPE	140	84	0	\N	elearning_async	2026-02-03 16:24:22.945956+01	2026-02-03 16:24:39.953101+01	0	\N	\N
271	3338	749	Chef de projet en rénovation énergétique - Bienvenue	115	85	100	2025-05-21 13:24:40+02	elearning_async	2026-02-03 16:24:23.428957+01	2026-02-03 16:24:40.482223+01	8102	2025-05-21 10:33:42+02	2025-05-21 13:54:33+02
272	3339	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	85	100	2025-06-21 19:07:11+02	elearning_async	2026-02-03 16:24:23.428962+01	2026-02-03 16:24:40.482223+01	13524	2025-06-21 11:06:30+02	2025-06-21 19:00:25+02
273	3340	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	85	100	2025-08-07 10:15:41+02	elearning_async	2026-02-03 16:24:23.428963+01	2026-02-03 16:24:40.482223+01	55680	2025-06-21 20:23:34+02	2025-08-07 10:25:41+02
274	3341	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	85	100	2025-08-07 10:26:51+02	elearning_async	2026-02-03 16:24:23.428964+01	2026-02-03 16:24:40.482223+01	2030	2025-08-07 10:26:49+02	2025-08-07 11:00:37+02
275	3342	756	Eco-conseiller - Module 4 : Aides et subventions	136	85	43	2025-08-07 11:43:29+02	elearning_async	2026-02-03 16:24:23.428965+01	2026-02-03 16:24:40.482223+01	4036	2025-08-07 11:01:22+02	\N
276	3343	757	Eco-conseiller - Module 5 : La relation client	137	85	0	\N	elearning_async	2026-02-03 16:24:23.428966+01	2026-02-03 16:24:40.482223+01	0	\N	\N
277	3344	752	Projet tutoré	114	85	15	2025-10-10 14:29:27+02	elearning_async	2026-02-03 16:24:23.428967+01	2026-02-03 16:24:40.482223+01	14040	2025-06-21 11:07:43+02	\N
278	3345	762	[AE] Guide du DPE	140	85	14	2025-07-11 15:34:09+02	elearning_async	2026-02-03 16:24:23.428968+01	2026-02-03 16:24:40.482223+01	10940	2025-07-04 16:14:08+02	\N
279	3346	761	DPE - Sans Mention	138	85	61	2025-07-29 14:03:41+02	elearning_async	2026-02-03 16:24:23.42897+01	2026-02-03 16:24:40.482223+01	22245	2025-07-11 15:42:19+02	\N
280	3347	763	DPE - Avec Mention	139	85	15	2025-10-10 14:29:24+02	elearning_async	2026-02-03 16:24:23.428971+01	2026-02-03 16:24:40.482223+01	16038	2025-09-16 10:52:54+02	\N
281	3362	750	Blocs 1 et 2 - Bienvenue !	117	85	0	\N	elearning_async	2026-02-03 16:24:23.428972+01	2026-02-03 16:24:40.482223+01	0	\N	\N
282	3363	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	85	0	\N	elearning_async	2026-02-03 16:24:23.428973+01	2026-02-03 16:24:40.482223+01	0	\N	\N
283	3364	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	85	0	\N	elearning_async	2026-02-03 16:24:23.428974+01	2026-02-03 16:24:40.482223+01	0	\N	\N
284	3365	768	[AE MI] Partie 3 : Conception de scénarios	143	85	0	\N	elearning_async	2026-02-03 16:24:23.428975+01	2026-02-03 16:24:40.482223+01	0	\N	\N
285	3366	769	[AE MI] Partie 4 : Le rapport	144	85	0	\N	elearning_async	2026-02-03 16:24:23.428976+01	2026-02-03 16:24:40.482223+01	0	\N	\N
286	3367	770	[AE MI] Cas Pratique	145	85	0	\N	elearning_async	2026-02-03 16:24:23.428977+01	2026-02-03 16:24:40.482223+01	0	\N	\N
287	3368	773	Mon Accompagnateur Rénov'	146	85	0	\N	elearning_async	2026-02-03 16:24:23.428979+01	2026-02-03 16:24:40.482223+01	0	\N	\N
298	5724	749	Chef de projet en rénovation énergétique - Bienvenue	115	86	67	2025-06-06 18:30:50+02	elearning_async	2026-02-03 16:24:23.912244+01	2026-02-03 16:24:40.876491+01	3610	2025-06-06 17:12:48+02	\N
299	5725	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	86	0	\N	elearning_async	2026-02-03 16:24:23.912249+01	2026-02-03 16:24:40.876491+01	0	\N	\N
300	5726	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	86	0	\N	elearning_async	2026-02-03 16:24:23.91225+01	2026-02-03 16:24:40.876491+01	0	\N	\N
301	5727	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	86	0	\N	elearning_async	2026-02-03 16:24:23.912251+01	2026-02-03 16:24:40.876491+01	0	\N	\N
302	5728	756	Eco-conseiller - Module 4 : Aides et subventions	136	86	0	\N	elearning_async	2026-02-03 16:24:23.912252+01	2026-02-03 16:24:40.876491+01	0	\N	\N
303	5729	757	Eco-conseiller - Module 5 : La relation client	137	86	0	\N	elearning_async	2026-02-03 16:24:23.912253+01	2026-02-03 16:24:40.876491+01	0	\N	\N
304	5730	752	Projet tutoré	114	86	0	\N	elearning_async	2026-02-03 16:24:23.912254+01	2026-02-03 16:24:40.876491+01	0	\N	\N
305	5731	762	[AE] Guide du DPE	140	86	0	\N	elearning_async	2026-02-03 16:24:23.912255+01	2026-02-03 16:24:40.876491+01	0	\N	\N
325	5758	749	Chef de projet en rénovation énergétique - Bienvenue	115	87	0	\N	elearning_async	2026-02-03 16:24:24.381549+01	2026-02-03 16:24:41.338863+01	0	\N	\N
326	5759	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	87	100	2025-05-29 10:01:15+02	elearning_async	2026-02-03 16:24:24.381553+01	2026-02-03 16:24:41.338863+01	16152	2025-05-21 08:29:01+02	2025-05-29 09:50:38+02
327	5760	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	87	80	2025-06-04 08:15:36+02	elearning_async	2026-02-03 16:24:24.381554+01	2026-02-03 16:24:41.338863+01	33564	2025-05-29 10:01:16+02	\N
328	5761	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	87	0	\N	elearning_async	2026-02-03 16:24:24.381555+01	2026-02-03 16:24:41.338863+01	0	\N	\N
329	5762	756	Eco-conseiller - Module 4 : Aides et subventions	136	87	0	\N	elearning_async	2026-02-03 16:24:24.381556+01	2026-02-03 16:24:41.338863+01	0	\N	\N
330	5763	757	Eco-conseiller - Module 5 : La relation client	137	87	0	\N	elearning_async	2026-02-03 16:24:24.381557+01	2026-02-03 16:24:41.338863+01	0	\N	\N
331	5764	752	Projet tutoré	114	87	0	\N	elearning_async	2026-02-03 16:24:24.381558+01	2026-02-03 16:24:41.338863+01	0	\N	\N
332	5765	762	[AE] Guide du DPE	140	87	0	\N	elearning_async	2026-02-03 16:24:24.38156+01	2026-02-03 16:24:41.338863+01	0	\N	\N
333	5766	761	DPE - Sans Mention	138	87	0	\N	elearning_async	2026-02-03 16:24:24.381561+01	2026-02-03 16:24:41.338863+01	0	\N	\N
334	5767	763	DPE - Avec Mention	139	87	0	\N	elearning_async	2026-02-03 16:24:24.381562+01	2026-02-03 16:24:41.338863+01	0	\N	\N
335	5782	750	Blocs 1 et 2 - Bienvenue !	117	87	0	\N	elearning_async	2026-02-03 16:24:24.381563+01	2026-02-03 16:24:41.338863+01	0	\N	\N
336	5783	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	87	0	\N	elearning_async	2026-02-03 16:24:24.381564+01	2026-02-03 16:24:41.338863+01	0	\N	\N
337	5784	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	87	0	\N	elearning_async	2026-02-03 16:24:24.381565+01	2026-02-03 16:24:41.338863+01	0	\N	\N
338	5785	768	[AE MI] Partie 3 : Conception de scénarios	143	87	0	\N	elearning_async	2026-02-03 16:24:24.381566+01	2026-02-03 16:24:41.338863+01	0	\N	\N
339	5786	769	[AE MI] Partie 4 : Le rapport	144	87	0	\N	elearning_async	2026-02-03 16:24:24.381567+01	2026-02-03 16:24:41.338863+01	0	\N	\N
340	5787	770	[AE MI] Cas Pratique	145	87	0	\N	elearning_async	2026-02-03 16:24:24.381568+01	2026-02-03 16:24:41.338863+01	0	\N	\N
341	5788	773	Mon Accompagnateur Rénov'	146	87	0	\N	elearning_async	2026-02-03 16:24:24.381569+01	2026-02-03 16:24:41.338863+01	0	\N	\N
342	5789	777	Audit énergétique - BCT	153	87	0	\N	elearning_async	2026-02-03 16:24:24.38157+01	2026-02-03 16:24:41.338863+01	0	\N	\N
379	5826	749	Chef de projet en rénovation énergétique - Bienvenue	115	89	100	2025-05-30 13:12:44+02	elearning_async	2026-02-03 16:24:25.351855+01	2026-02-03 16:24:25.351859+01	152350	2025-05-20 18:57:58+02	2025-05-30 13:35:35+02
380	5827	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	89	100	2025-06-30 14:26:24+02	elearning_async	2026-02-03 16:24:25.35186+01	2026-02-03 16:24:25.35186+01	319976	2025-05-30 13:41:59+02	2025-06-30 14:40:58+02
381	5828	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	89	23	2025-06-30 14:45:47+02	elearning_async	2026-02-03 16:24:25.351861+01	2026-02-03 16:24:25.351862+01	60060	2025-06-30 14:45:47+02	\N
382	5829	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	89	0	\N	elearning_async	2026-02-03 16:24:25.351862+01	2026-02-03 16:24:25.351863+01	0	\N	\N
383	5830	756	Eco-conseiller - Module 4 : Aides et subventions	136	89	0	\N	elearning_async	2026-02-03 16:24:25.351863+01	2026-02-03 16:24:25.351864+01	0	\N	\N
384	5831	757	Eco-conseiller - Module 5 : La relation client	137	89	0	\N	elearning_async	2026-02-03 16:24:25.351864+01	2026-02-03 16:24:25.351865+01	0	\N	\N
385	5832	752	Projet tutoré	114	89	90	2025-10-02 13:17:50+02	elearning_async	2026-02-03 16:24:25.351865+01	2026-02-03 16:24:25.351866+01	258300	2025-06-11 08:24:33+02	\N
386	5833	762	[AE] Guide du DPE	140	89	100	2025-10-01 13:14:06+02	elearning_async	2026-02-03 16:24:25.351866+01	2026-02-03 16:24:25.351867+01	223542	2025-07-02 15:42:07+02	2025-10-01 13:14:21+02
387	5834	761	DPE - Sans Mention	138	89	100	2025-10-02 13:04:37+02	elearning_async	2026-02-03 16:24:25.351867+01	2026-02-03 16:24:25.351868+01	248626	2025-07-09 22:04:00+02	2025-07-18 19:27:43+02
388	5835	763	DPE - Avec Mention	139	89	8	2025-07-31 11:45:28+02	elearning_async	2026-02-03 16:24:25.351868+01	2026-02-03 16:24:25.351869+01	64504	2025-07-19 15:26:14+02	\N
389	5850	750	Blocs 1 et 2 - Bienvenue !	117	89	0	\N	elearning_async	2026-02-03 16:24:25.351869+01	2026-02-03 16:24:25.35187+01	0	\N	\N
390	5851	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	89	100	2025-08-09 13:56:55+02	elearning_async	2026-02-03 16:24:25.35187+01	2026-02-03 16:24:25.351871+01	141844	2025-08-01 18:25:06+02	2025-08-09 15:02:51+02
391	5852	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	89	100	2025-08-11 11:46:28+02	elearning_async	2026-02-03 16:24:25.351871+01	2026-02-03 16:24:25.351872+01	31132	2025-08-09 17:08:52+02	2025-08-11 11:40:51+02
392	5853	768	[AE MI] Partie 3 : Conception de scénarios	143	89	100	2025-08-20 12:45:01+02	elearning_async	2026-02-03 16:24:25.351872+01	2026-02-03 16:24:25.351873+01	104962	2025-08-11 12:05:33+02	2025-08-20 13:12:18+02
393	5854	769	[AE MI] Partie 4 : Le rapport	144	89	100	2025-08-24 17:46:17+02	elearning_async	2026-02-03 16:24:25.351873+01	2026-02-03 16:24:25.351874+01	68076	2025-08-20 13:17:48+02	2025-08-24 18:03:06+02
352	5792	749	Chef de projet en rénovation énergétique - Bienvenue	115	88	0	\N	elearning_async	2026-02-03 16:24:24.879536+01	2026-02-03 16:24:41.775772+01	0	\N	\N
353	5793	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	88	100	2025-06-20 08:50:55+02	elearning_async	2026-02-03 16:24:24.87954+01	2026-02-03 16:24:41.775772+01	21468	2025-06-06 09:28:01+02	2025-06-12 15:08:36+02
354	5794	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	88	100	2025-06-20 10:18:01+02	elearning_async	2026-02-03 16:24:24.879541+01	2026-02-03 16:24:41.775772+01	32070	2025-06-12 11:10:34+02	2025-06-19 09:47:19+02
355	5795	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	88	100	2025-06-19 09:48:12+02	elearning_async	2026-02-03 16:24:24.879543+01	2026-02-03 16:24:41.775772+01	112	2025-06-19 09:48:10+02	2025-06-19 09:49:57+02
356	5796	756	Eco-conseiller - Module 4 : Aides et subventions	136	88	100	2025-06-20 09:23:52+02	elearning_async	2026-02-03 16:24:24.879544+01	2026-02-03 16:24:41.775772+01	3848	2025-06-19 09:51:02+02	2025-07-02 15:55:45+02
357	5797	757	Eco-conseiller - Module 5 : La relation client	137	88	100	2025-06-26 16:45:59+02	elearning_async	2026-02-03 16:24:24.879545+01	2026-02-03 16:24:41.775772+01	172	2025-06-19 09:52:26+02	2025-06-19 14:51:17+02
358	5798	752	Projet tutoré	114	88	0	\N	elearning_async	2026-02-03 16:24:24.879546+01	2026-02-03 16:24:41.775772+01	0	\N	\N
359	5799	762	[AE] Guide du DPE	140	88	100	2025-08-05 09:23:52+02	elearning_async	2026-02-03 16:24:24.879547+01	2026-02-03 16:24:41.775772+01	59896	2025-06-19 10:00:25+02	2025-08-05 09:24:03+02
394	5855	770	[AE MI] Cas Pratique	145	89	0	\N	elearning_async	2026-02-03 16:24:25.351874+01	2026-02-03 16:24:25.351875+01	0	\N	\N
395	5856	773	Mon Accompagnateur Rénov'	146	89	0	\N	elearning_async	2026-02-03 16:24:25.351875+01	2026-02-03 16:24:25.351876+01	0	\N	\N
396	5857	777	Audit énergétique - BCT	153	89	20	2025-12-14 08:01:52+01	elearning_async	2026-02-03 16:24:25.351876+01	2026-02-03 16:24:25.351877+01	462164	2025-10-09 12:49:48+02	\N
397	5858	779	Management, Communication, Handicap	152	89	13	2025-12-24 16:17:30+01	elearning_async	2026-02-03 16:24:25.351877+01	2026-02-03 16:24:25.351878+01	172807	2025-12-14 08:01:55+01	\N
398	5859	780	Ordonnancement, Pilotage, et Coordination	154	89	0	\N	elearning_async	2026-02-03 16:24:25.351878+01	2026-02-03 16:24:25.351879+01	0	\N	\N
399	14333	1020	DPE avec mention	116	89	5	2025-07-20 17:56:37+02	elearning_async	2026-02-03 16:24:25.351879+01	2026-02-03 16:24:25.35188+01	15724	2025-07-19 15:26:14+02	\N
400	15091	1151	Point tutoré - BC01 02	118	89	0	\N	elearning_async	2026-02-03 16:24:25.35188+01	2026-02-03 16:24:25.351881+01	0	\N	\N
401	18035	1898	MAR (C&M) - Module 1 : Les prérequis	147	89	95	2025-09-23 17:47:56+02	elearning_async	2026-02-03 16:24:25.351881+01	2026-02-03 16:24:25.351882+01	755986	2025-08-24 19:40:30+02	\N
402	18068	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	89	0	\N	elearning_async	2026-02-03 16:24:25.351882+01	2026-02-03 16:24:25.351883+01	0	\N	\N
403	18101	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	89	0	\N	elearning_async	2026-02-03 16:24:25.351883+01	2026-02-03 16:24:25.351884+01	0	\N	\N
404	18134	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	89	0	\N	elearning_async	2026-02-03 16:24:25.351884+01	2026-02-03 16:24:25.351885+01	0	\N	\N
405	18167	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	89	0	\N	elearning_async	2026-02-03 16:24:25.351885+01	2026-02-03 16:24:25.351886+01	0	\N	\N
406	5860	749	Chef de projet en rénovation énergétique - Bienvenue	115	90	100	2025-05-27 10:02:01+02	elearning_async	2026-02-03 16:24:25.855138+01	2026-02-03 16:24:25.855141+01	13596	2025-05-26 09:05:20+02	2025-05-27 10:04:14+02
407	5861	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	90	100	2025-06-04 16:06:39+02	elearning_async	2026-02-03 16:24:25.855143+01	2026-02-03 16:24:25.855144+01	36166	2025-05-27 10:34:18+02	2025-06-04 14:34:45+02
408	5862	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	90	100	2025-06-19 10:12:59+02	elearning_async	2026-02-03 16:24:25.855145+01	2026-02-03 16:24:25.855146+01	54898	2025-06-04 16:43:11+02	2025-06-19 12:29:27+02
409	5863	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	90	100	2026-01-25 15:23:40+01	elearning_async	2026-02-03 16:24:25.855147+01	2026-02-03 16:24:25.855147+01	8054	2025-06-20 08:26:10+02	2025-06-20 10:20:59+02
410	5864	756	Eco-conseiller - Module 4 : Aides et subventions	136	90	100	2025-06-21 08:34:38+02	elearning_async	2026-02-03 16:24:25.855148+01	2026-02-03 16:24:25.855149+01	23698	2025-06-20 10:33:31+02	2025-06-20 16:40:21+02
411	5865	757	Eco-conseiller - Module 5 : La relation client	137	90	100	2025-06-21 09:15:30+02	elearning_async	2026-02-03 16:24:25.85515+01	2026-02-03 16:24:25.855151+01	544	2025-06-21 08:34:53+02	2025-06-21 09:15:34+02
412	5866	752	Projet tutoré	114	90	100	2025-06-09 09:37:57+02	elearning_async	2026-02-03 16:24:25.855152+01	2026-02-03 16:24:25.855152+01	20526	2025-06-06 09:19:52+02	2025-06-10 16:36:39+02
413	5867	762	[AE] Guide du DPE	140	90	100	2025-09-19 09:13:54+02	elearning_async	2026-02-03 16:24:25.855153+01	2026-02-03 16:24:25.855154+01	83800	2025-06-21 09:25:01+02	2025-08-01 18:28:44+02
414	5868	761	DPE - Sans Mention	138	90	100	2025-12-15 11:32:23+01	elearning_async	2026-02-03 16:24:25.855155+01	2026-02-03 16:24:25.855156+01	78054	2025-06-25 16:14:39+02	2025-07-15 17:30:40+02
415	5869	763	DPE - Avec Mention	139	90	100	2025-09-14 10:13:13+02	elearning_async	2026-02-03 16:24:25.855157+01	2026-02-03 16:24:25.855158+01	43472	2025-07-15 17:39:01+02	2025-09-14 10:25:54+02
416	5884	750	Blocs 1 et 2 - Bienvenue !	117	90	0	\N	elearning_async	2026-02-03 16:24:25.855159+01	2026-02-03 16:24:25.855159+01	0	\N	\N
417	5885	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	90	100	2025-08-06 15:10:19+02	elearning_async	2026-02-03 16:24:25.85516+01	2026-02-03 16:24:25.855161+01	18526	2025-07-25 22:08:02+02	2025-08-02 15:34:10+02
418	5886	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	90	100	2025-08-02 17:52:05+02	elearning_async	2026-02-03 16:24:25.855162+01	2026-02-03 16:24:25.855163+01	4774	2025-08-02 15:36:59+02	2025-08-02 18:01:15+02
419	5887	768	[AE MI] Partie 3 : Conception de scénarios	143	90	100	2026-01-12 09:23:03+01	elearning_async	2026-02-03 16:24:25.855164+01	2026-02-03 16:24:25.855164+01	7802	2025-08-02 18:10:46+02	2025-08-03 12:53:32+02
420	5888	769	[AE MI] Partie 4 : Le rapport	144	90	100	2025-08-03 13:51:33+02	elearning_async	2026-02-03 16:24:25.855165+01	2026-02-03 16:24:25.855166+01	3238	2025-08-03 12:55:10+02	2025-08-03 13:50:39+02
421	5889	770	[AE MI] Cas Pratique	145	90	100	2025-08-06 21:26:30+02	elearning_async	2026-02-03 16:24:25.855167+01	2026-02-03 16:24:25.855168+01	13970	2025-07-31 14:16:04+02	2025-08-06 13:43:12+02
422	5890	773	Mon Accompagnateur Rénov'	146	90	0	\N	elearning_async	2026-02-03 16:24:25.855169+01	2026-02-03 16:24:25.855169+01	0	\N	\N
423	5891	777	Audit énergétique - BCT	153	90	100	2026-01-12 09:21:50+01	elearning_async	2026-02-03 16:24:25.85517+01	2026-02-03 16:24:25.855171+01	51802	2025-08-11 09:50:43+02	2025-08-30 19:26:47+02
424	5892	779	Management, Communication, Handicap	152	90	25	2025-10-20 15:42:07+02	elearning_async	2026-02-03 16:24:25.855172+01	2026-02-03 16:24:25.855173+01	9129	2025-08-06 15:09:12+02	\N
425	5893	780	Ordonnancement, Pilotage, et Coordination	154	90	0	\N	elearning_async	2026-02-03 16:24:25.855173+01	2026-02-03 16:24:25.855174+01	0	\N	\N
426	14334	1020	DPE avec mention	116	90	100	2025-09-14 10:25:58+02	elearning_async	2026-02-03 16:24:25.855175+01	2026-02-03 16:24:25.855176+01	43472	2025-07-15 17:39:01+02	2025-09-14 10:25:54+02
427	15092	1151	Point tutoré - BC01 02	118	90	0	\N	elearning_async	2026-02-03 16:24:25.855177+01	2026-02-03 16:24:25.855178+01	0	\N	\N
428	18036	1898	MAR (C&M) - Module 1 : Les prérequis	147	90	100	2025-09-04 11:53:04+02	elearning_async	2026-02-03 16:24:25.855178+01	2026-02-03 16:24:25.85518+01	46356	2025-08-30 19:29:09+02	2025-09-04 15:58:44+02
429	18069	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	90	100	2025-09-13 11:23:10+02	elearning_async	2026-02-03 16:24:25.855181+01	2026-02-03 16:24:25.855182+01	48804	2025-09-02 16:53:09+02	2025-09-11 09:07:23+02
430	18102	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	90	100	2025-09-12 14:00:09+02	elearning_async	2026-02-03 16:24:25.855183+01	2026-02-03 16:24:25.855183+01	9198	2025-09-11 09:11:37+02	2025-09-11 10:09:46+02
431	18135	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	90	100	2025-09-13 09:13:15+02	elearning_async	2026-02-03 16:24:25.855184+01	2026-02-03 16:24:25.855185+01	8200	2025-09-11 14:57:42+02	2025-09-13 10:18:33+02
432	18168	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	90	100	2025-09-13 11:20:11+02	elearning_async	2026-02-03 16:24:25.855186+01	2026-02-03 16:24:25.855187+01	1774	2025-09-12 09:00:47+02	2025-09-12 09:00:47+02
433	5894	749	Chef de projet en rénovation énergétique - Bienvenue	115	91	100	2025-06-06 14:11:41+02	elearning_async	2026-02-03 16:24:26.314079+01	2026-02-03 16:24:26.314082+01	17680	2025-06-06 09:09:27+02	2025-06-06 13:49:51+02
434	5895	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	91	23	2025-06-24 17:27:03+02	elearning_async	2026-02-03 16:24:26.314083+01	2026-02-03 16:24:26.314084+01	36968	2025-06-10 12:59:24+02	\N
435	5896	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	91	0	\N	elearning_async	2026-02-03 16:24:26.314084+01	2026-02-03 16:24:26.314085+01	0	\N	\N
436	5897	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	91	0	\N	elearning_async	2026-02-03 16:24:26.314085+01	2026-02-03 16:24:26.314086+01	0	\N	\N
437	5898	756	Eco-conseiller - Module 4 : Aides et subventions	136	91	0	\N	elearning_async	2026-02-03 16:24:26.314086+01	2026-02-03 16:24:26.314087+01	0	\N	\N
438	5899	757	Eco-conseiller - Module 5 : La relation client	137	91	0	\N	elearning_async	2026-02-03 16:24:26.314087+01	2026-02-03 16:24:26.314088+01	0	\N	\N
439	5900	752	Projet tutoré	114	91	0	\N	elearning_async	2026-02-03 16:24:26.314088+01	2026-02-03 16:24:26.314089+01	0	\N	\N
440	5901	762	[AE] Guide du DPE	140	91	0	\N	elearning_async	2026-02-03 16:24:26.314089+01	2026-02-03 16:24:26.31409+01	0	\N	\N
441	5902	761	DPE - Sans Mention	138	91	0	\N	elearning_async	2026-02-03 16:24:26.31409+01	2026-02-03 16:24:26.314091+01	0	\N	\N
442	5903	763	DPE - Avec Mention	139	91	0	\N	elearning_async	2026-02-03 16:24:26.314091+01	2026-02-03 16:24:26.314092+01	0	\N	\N
443	5918	750	Blocs 1 et 2 - Bienvenue !	117	91	0	\N	elearning_async	2026-02-03 16:24:26.314092+01	2026-02-03 16:24:26.314093+01	0	\N	\N
444	5919	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	91	0	\N	elearning_async	2026-02-03 16:24:26.314093+01	2026-02-03 16:24:26.314094+01	0	\N	\N
445	5920	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	91	0	\N	elearning_async	2026-02-03 16:24:26.314094+01	2026-02-03 16:24:26.314095+01	0	\N	\N
446	5921	768	[AE MI] Partie 3 : Conception de scénarios	143	91	0	\N	elearning_async	2026-02-03 16:24:26.314095+01	2026-02-03 16:24:26.314096+01	0	\N	\N
447	5922	769	[AE MI] Partie 4 : Le rapport	144	91	0	\N	elearning_async	2026-02-03 16:24:26.314096+01	2026-02-03 16:24:26.314097+01	0	\N	\N
448	5923	770	[AE MI] Cas Pratique	145	91	0	\N	elearning_async	2026-02-03 16:24:26.314097+01	2026-02-03 16:24:26.314098+01	0	\N	\N
449	5924	773	Mon Accompagnateur Rénov'	146	91	0	\N	elearning_async	2026-02-03 16:24:26.314099+01	2026-02-03 16:24:26.314099+01	0	\N	\N
450	5925	777	Audit énergétique - BCT	153	91	0	\N	elearning_async	2026-02-03 16:24:26.3141+01	2026-02-03 16:24:26.3141+01	0	\N	\N
451	5926	779	Management, Communication, Handicap	152	91	0	\N	elearning_async	2026-02-03 16:24:26.314101+01	2026-02-03 16:24:26.314101+01	0	\N	\N
452	5927	780	Ordonnancement, Pilotage, et Coordination	154	91	0	\N	elearning_async	2026-02-03 16:24:26.314102+01	2026-02-03 16:24:26.314102+01	0	\N	\N
453	14335	1020	DPE avec mention	116	91	0	\N	elearning_async	2026-02-03 16:24:26.314103+01	2026-02-03 16:24:26.314103+01	0	\N	\N
454	15093	1151	Point tutoré - BC01 02	118	91	0	\N	elearning_async	2026-02-03 16:24:26.314104+01	2026-02-03 16:24:26.314104+01	0	\N	\N
455	18037	1898	MAR (C&M) - Module 1 : Les prérequis	147	91	0	\N	elearning_async	2026-02-03 16:24:26.314105+01	2026-02-03 16:24:26.314105+01	0	\N	\N
456	18070	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	91	0	\N	elearning_async	2026-02-03 16:24:26.314106+01	2026-02-03 16:24:26.314106+01	0	\N	\N
457	18103	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	91	0	\N	elearning_async	2026-02-03 16:24:26.314107+01	2026-02-03 16:24:26.314107+01	0	\N	\N
458	18136	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	91	0	\N	elearning_async	2026-02-03 16:24:26.314108+01	2026-02-03 16:24:26.314108+01	0	\N	\N
459	18169	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	91	0	\N	elearning_async	2026-02-03 16:24:26.314109+01	2026-02-03 16:24:26.314109+01	0	\N	\N
460	5928	749	Chef de projet en rénovation énergétique - Bienvenue	115	92	100	2025-06-11 08:16:21+02	elearning_async	2026-02-03 16:24:26.802047+01	2026-02-03 16:24:26.80205+01	13740	2025-05-30 14:55:38+02	2025-06-10 20:44:45+02
461	5929	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	92	27	2025-10-23 14:07:04+02	elearning_async	2026-02-03 16:24:26.802051+01	2026-02-03 16:24:26.802052+01	10644	2025-06-22 18:08:17+02	\N
462	5930	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	92	0	\N	elearning_async	2026-02-03 16:24:26.802052+01	2026-02-03 16:24:26.802053+01	0	\N	\N
463	5931	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	92	0	\N	elearning_async	2026-02-03 16:24:26.802054+01	2026-02-03 16:24:26.802054+01	0	\N	\N
464	5932	756	Eco-conseiller - Module 4 : Aides et subventions	136	92	0	\N	elearning_async	2026-02-03 16:24:26.802055+01	2026-02-03 16:24:26.802055+01	0	\N	\N
465	5933	757	Eco-conseiller - Module 5 : La relation client	137	92	0	\N	elearning_async	2026-02-03 16:24:26.802056+01	2026-02-03 16:24:26.802056+01	0	\N	\N
466	5934	752	Projet tutoré	114	92	100	2025-10-24 10:39:42+02	elearning_async	2026-02-03 16:24:26.802057+01	2026-02-03 16:24:26.802057+01	17198	2025-06-18 19:49:57+02	2025-06-22 18:00:16+02
467	5935	762	[AE] Guide du DPE	140	92	82	2025-09-03 15:33:04+02	elearning_async	2026-02-03 16:24:26.802058+01	2026-02-03 16:24:26.802058+01	82136	2025-07-04 10:42:15+02	\N
468	5936	761	DPE - Sans Mention	138	92	37	2025-10-24 10:39:24+02	elearning_async	2026-02-03 16:24:26.802059+01	2026-02-03 16:24:26.80206+01	78648	2025-07-05 21:52:57+02	\N
469	5937	763	DPE - Avec Mention	139	92	0	\N	elearning_async	2026-02-03 16:24:26.80206+01	2026-02-03 16:24:26.802061+01	0	\N	\N
470	5952	750	Blocs 1 et 2 - Bienvenue !	117	92	0	\N	elearning_async	2026-02-03 16:24:26.802061+01	2026-02-03 16:24:26.802062+01	0	\N	\N
471	5953	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	92	0	\N	elearning_async	2026-02-03 16:24:26.802062+01	2026-02-03 16:24:26.802063+01	0	\N	\N
472	5954	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	92	0	\N	elearning_async	2026-02-03 16:24:26.802063+01	2026-02-03 16:24:26.802064+01	0	\N	\N
473	5955	768	[AE MI] Partie 3 : Conception de scénarios	143	92	0	\N	elearning_async	2026-02-03 16:24:26.802065+01	2026-02-03 16:24:26.802065+01	0	\N	\N
474	5956	769	[AE MI] Partie 4 : Le rapport	144	92	0	\N	elearning_async	2026-02-03 16:24:26.802066+01	2026-02-03 16:24:26.802066+01	0	\N	\N
475	5957	770	[AE MI] Cas Pratique	145	92	0	\N	elearning_async	2026-02-03 16:24:26.802067+01	2026-02-03 16:24:26.802067+01	0	\N	\N
476	5958	773	Mon Accompagnateur Rénov'	146	92	0	\N	elearning_async	2026-02-03 16:24:26.802068+01	2026-02-03 16:24:26.802069+01	0	\N	\N
477	5959	777	Audit énergétique - BCT	153	92	70	2025-10-04 11:34:02+02	elearning_async	2026-02-03 16:24:26.802069+01	2026-02-03 16:24:26.80207+01	18138	2025-09-14 10:52:06+02	\N
478	5960	779	Management, Communication, Handicap	152	92	0	\N	elearning_async	2026-02-03 16:24:26.80207+01	2026-02-03 16:24:26.802071+01	0	\N	\N
479	5961	780	Ordonnancement, Pilotage, et Coordination	154	92	0	\N	elearning_async	2026-02-03 16:24:26.802071+01	2026-02-03 16:24:26.802072+01	0	\N	\N
480	14336	1020	DPE avec mention	116	92	0	\N	elearning_async	2026-02-03 16:24:26.802072+01	2026-02-03 16:24:26.802073+01	0	\N	\N
481	15094	1151	Point tutoré - BC01 02	118	92	0	\N	elearning_async	2026-02-03 16:24:26.802073+01	2026-02-03 16:24:26.802074+01	0	\N	\N
482	18038	1898	MAR (C&M) - Module 1 : Les prérequis	147	92	0	\N	elearning_async	2026-02-03 16:24:26.802075+01	2026-02-03 16:24:26.802075+01	0	\N	\N
483	18071	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	92	0	\N	elearning_async	2026-02-03 16:24:26.802076+01	2026-02-03 16:24:26.802076+01	0	\N	\N
484	18104	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	92	0	\N	elearning_async	2026-02-03 16:24:26.802077+01	2026-02-03 16:24:26.802077+01	0	\N	\N
485	18137	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	92	0	\N	elearning_async	2026-02-03 16:24:26.802078+01	2026-02-03 16:24:26.802078+01	0	\N	\N
486	18170	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	92	0	\N	elearning_async	2026-02-03 16:24:26.802079+01	2026-02-03 16:24:26.802079+01	0	\N	\N
487	5962	749	Chef de projet en rénovation énergétique - Bienvenue	115	93	67	2025-06-06 09:12:17+02	elearning_async	2026-02-03 16:24:27.262063+01	2026-02-03 16:24:27.262067+01	660	2025-06-05 23:45:23+02	\N
488	5963	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	93	0	\N	elearning_async	2026-02-03 16:24:27.262068+01	2026-02-03 16:24:27.262068+01	0	\N	\N
489	5964	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	93	0	\N	elearning_async	2026-02-03 16:24:27.262069+01	2026-02-03 16:24:27.262069+01	0	\N	\N
490	5965	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	93	0	\N	elearning_async	2026-02-03 16:24:27.26207+01	2026-02-03 16:24:27.262071+01	0	\N	\N
491	5966	756	Eco-conseiller - Module 4 : Aides et subventions	136	93	0	\N	elearning_async	2026-02-03 16:24:27.262071+01	2026-02-03 16:24:27.262072+01	0	\N	\N
492	5967	757	Eco-conseiller - Module 5 : La relation client	137	93	0	\N	elearning_async	2026-02-03 16:24:27.262072+01	2026-02-03 16:24:27.262073+01	0	\N	\N
493	5968	752	Projet tutoré	114	93	0	\N	elearning_async	2026-02-03 16:24:27.262073+01	2026-02-03 16:24:27.262074+01	0	\N	\N
494	5969	762	[AE] Guide du DPE	140	93	0	\N	elearning_async	2026-02-03 16:24:27.262074+01	2026-02-03 16:24:27.262075+01	0	\N	\N
495	5970	761	DPE - Sans Mention	138	93	0	\N	elearning_async	2026-02-03 16:24:27.262076+01	2026-02-03 16:24:27.262076+01	0	\N	\N
496	5971	763	DPE - Avec Mention	139	93	0	\N	elearning_async	2026-02-03 16:24:27.262077+01	2026-02-03 16:24:27.262077+01	0	\N	\N
497	5986	750	Blocs 1 et 2 - Bienvenue !	117	93	0	\N	elearning_async	2026-02-03 16:24:27.262078+01	2026-02-03 16:24:27.262078+01	0	\N	\N
603	14287	761	DPE - Sans Mention	138	46	0	\N	elearning_async	2026-02-03 16:24:28.995224+01	2026-02-03 16:24:28.995225+01	0	\N	\N
498	5987	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	93	0	\N	elearning_async	2026-02-03 16:24:27.262079+01	2026-02-03 16:24:27.262079+01	0	\N	\N
499	5988	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	93	0	\N	elearning_async	2026-02-03 16:24:27.26208+01	2026-02-03 16:24:27.262081+01	0	\N	\N
500	5989	768	[AE MI] Partie 3 : Conception de scénarios	143	93	0	\N	elearning_async	2026-02-03 16:24:27.262081+01	2026-02-03 16:24:27.262082+01	0	\N	\N
501	5990	769	[AE MI] Partie 4 : Le rapport	144	93	0	\N	elearning_async	2026-02-03 16:24:27.262082+01	2026-02-03 16:24:27.262083+01	0	\N	\N
502	5991	770	[AE MI] Cas Pratique	145	93	0	\N	elearning_async	2026-02-03 16:24:27.262084+01	2026-02-03 16:24:27.262084+01	0	\N	\N
503	5992	773	Mon Accompagnateur Rénov'	146	93	0	\N	elearning_async	2026-02-03 16:24:27.262085+01	2026-02-03 16:24:27.262085+01	0	\N	\N
504	5993	777	Audit énergétique - BCT	153	93	0	\N	elearning_async	2026-02-03 16:24:27.262086+01	2026-02-03 16:24:27.262086+01	0	\N	\N
505	5994	779	Management, Communication, Handicap	152	93	0	\N	elearning_async	2026-02-03 16:24:27.262087+01	2026-02-03 16:24:27.262087+01	0	\N	\N
506	5995	780	Ordonnancement, Pilotage, et Coordination	154	93	0	\N	elearning_async	2026-02-03 16:24:27.262088+01	2026-02-03 16:24:27.262089+01	0	\N	\N
507	14337	1020	DPE avec mention	116	93	0	\N	elearning_async	2026-02-03 16:24:27.262089+01	2026-02-03 16:24:27.26209+01	0	\N	\N
508	15095	1151	Point tutoré - BC01 02	118	93	0	\N	elearning_async	2026-02-03 16:24:27.26209+01	2026-02-03 16:24:27.262091+01	0	\N	\N
509	18039	1898	MAR (C&M) - Module 1 : Les prérequis	147	93	0	\N	elearning_async	2026-02-03 16:24:27.262091+01	2026-02-03 16:24:27.262092+01	0	\N	\N
510	18072	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	93	0	\N	elearning_async	2026-02-03 16:24:27.262093+01	2026-02-03 16:24:27.262093+01	0	\N	\N
511	18105	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	93	0	\N	elearning_async	2026-02-03 16:24:27.262094+01	2026-02-03 16:24:27.262094+01	0	\N	\N
512	18138	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	93	0	\N	elearning_async	2026-02-03 16:24:27.262095+01	2026-02-03 16:24:27.262096+01	0	\N	\N
513	18171	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	93	0	\N	elearning_async	2026-02-03 16:24:27.262096+01	2026-02-03 16:24:27.262097+01	0	\N	\N
514	5996	749	Chef de projet en rénovation énergétique - Bienvenue	115	94	100	2025-06-06 10:47:00+02	elearning_async	2026-02-03 16:24:27.711342+01	2026-02-03 16:24:27.711346+01	33434	2025-05-20 17:18:23+02	2025-06-06 11:26:29+02
515	5997	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	94	38	2025-10-03 08:47:48+02	elearning_async	2026-02-03 16:24:27.711347+01	2026-02-03 16:24:27.711348+01	44435	2025-06-06 11:36:53+02	\N
516	5998	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	94	3	2025-05-26 10:48:49+02	elearning_async	2026-02-03 16:24:27.711348+01	2026-02-03 16:24:27.711349+01	5530	2025-05-26 10:48:49+02	\N
517	5999	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	94	0	\N	elearning_async	2026-02-03 16:24:27.711349+01	2026-02-03 16:24:27.71135+01	0	\N	\N
518	6000	756	Eco-conseiller - Module 4 : Aides et subventions	136	94	0	\N	elearning_async	2026-02-03 16:24:27.711351+01	2026-02-03 16:24:27.711351+01	0	\N	\N
519	6001	757	Eco-conseiller - Module 5 : La relation client	137	94	0	\N	elearning_async	2026-02-03 16:24:27.711352+01	2026-02-03 16:24:27.711352+01	0	\N	\N
520	6002	752	Projet tutoré	114	94	3	2025-10-22 11:06:43+02	elearning_async	2026-02-03 16:24:27.711353+01	2026-02-03 16:24:27.711353+01	25680	2025-06-19 09:59:04+02	\N
521	6003	762	[AE] Guide du DPE	140	94	99	2025-10-02 21:58:29+02	elearning_async	2026-02-03 16:24:27.711354+01	2026-02-03 16:24:27.711355+01	71488	2025-07-09 14:04:48+02	2025-07-20 15:56:26+02
522	6004	761	DPE - Sans Mention	138	94	39	2025-08-06 09:52:05+02	elearning_async	2026-02-03 16:24:27.711355+01	2026-02-03 16:24:27.711356+01	94132	2025-07-03 09:45:56+02	\N
523	6005	763	DPE - Avec Mention	139	94	8	2025-08-12 12:05:13+02	elearning_async	2026-02-03 16:24:27.711356+01	2026-02-03 16:24:27.711357+01	10624	2025-07-02 13:06:15+02	\N
524	6020	750	Blocs 1 et 2 - Bienvenue !	117	94	0	\N	elearning_async	2026-02-03 16:24:27.711358+01	2026-02-03 16:24:27.711358+01	0	\N	\N
525	6021	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	94	0	\N	elearning_async	2026-02-03 16:24:27.711359+01	2026-02-03 16:24:27.711359+01	0	\N	\N
526	6022	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	94	0	\N	elearning_async	2026-02-03 16:24:27.71136+01	2026-02-03 16:24:27.711361+01	0	\N	\N
527	6023	768	[AE MI] Partie 3 : Conception de scénarios	143	94	0	\N	elearning_async	2026-02-03 16:24:27.711361+01	2026-02-03 16:24:27.711362+01	0	\N	\N
528	6024	769	[AE MI] Partie 4 : Le rapport	144	94	33	2025-08-12 12:00:25+02	elearning_async	2026-02-03 16:24:27.711362+01	2026-02-03 16:24:27.711363+01	358	2025-08-12 11:56:27+02	\N
529	6025	770	[AE MI] Cas Pratique	145	94	50	2025-08-06 13:23:49+02	elearning_async	2026-02-03 16:24:27.711364+01	2026-02-03 16:24:27.711364+01	7970	2025-08-06 09:52:58+02	\N
530	6026	773	Mon Accompagnateur Rénov'	146	94	0	\N	elearning_async	2026-02-03 16:24:27.711365+01	2026-02-03 16:24:27.711365+01	0	\N	\N
531	6027	777	Audit énergétique - BCT	153	94	0	\N	elearning_async	2026-02-03 16:24:27.711366+01	2026-02-03 16:24:27.711366+01	0	\N	\N
532	6028	779	Management, Communication, Handicap	152	94	0	\N	elearning_async	2026-02-03 16:24:27.711367+01	2026-02-03 16:24:27.711368+01	0	\N	\N
533	6029	780	Ordonnancement, Pilotage, et Coordination	154	94	0	\N	elearning_async	2026-02-03 16:24:27.711368+01	2026-02-03 16:24:27.711369+01	0	\N	\N
534	14338	1020	DPE avec mention	116	94	5	2025-08-12 12:05:47+02	elearning_async	2026-02-03 16:24:27.71137+01	2026-02-03 16:24:27.71137+01	10624	2025-07-02 13:06:15+02	\N
535	15096	1151	Point tutoré - BC01 02	118	94	0	\N	elearning_async	2026-02-03 16:24:27.711371+01	2026-02-03 16:24:27.711371+01	0	\N	\N
536	18040	1898	MAR (C&M) - Module 1 : Les prérequis	147	94	0	\N	elearning_async	2026-02-03 16:24:27.711372+01	2026-02-03 16:24:27.711373+01	0	\N	\N
537	18073	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	94	0	\N	elearning_async	2026-02-03 16:24:27.711373+01	2026-02-03 16:24:27.711374+01	0	\N	\N
538	18106	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	94	0	\N	elearning_async	2026-02-03 16:24:27.711374+01	2026-02-03 16:24:27.711375+01	0	\N	\N
539	18139	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	94	0	\N	elearning_async	2026-02-03 16:24:27.711376+01	2026-02-03 16:24:27.711376+01	0	\N	\N
540	18172	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	94	0	\N	elearning_async	2026-02-03 16:24:27.711377+01	2026-02-03 16:24:27.711377+01	0	\N	\N
541	6030	749	Chef de projet en rénovation énergétique - Bienvenue	115	95	67	2025-06-09 18:46:40+02	elearning_async	2026-02-03 16:24:28.09543+01	2026-02-03 16:24:28.095434+01	8058	2025-06-08 10:29:16+02	\N
542	6031	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	95	100	2025-06-26 10:19:37+02	elearning_async	2026-02-03 16:24:28.095435+01	2026-02-03 16:24:28.095435+01	28254	2025-06-18 17:00:20+02	2025-06-26 10:58:43+02
543	6032	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	95	57	2025-06-27 12:28:12+02	elearning_async	2026-02-03 16:24:28.095436+01	2026-02-03 16:24:28.095437+01	13686	2025-06-26 11:02:31+02	\N
544	6033	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	95	0	\N	elearning_async	2026-02-03 16:24:28.095437+01	2026-02-03 16:24:28.095438+01	0	\N	\N
545	6034	756	Eco-conseiller - Module 4 : Aides et subventions	136	95	0	\N	elearning_async	2026-02-03 16:24:28.095438+01	2026-02-03 16:24:28.095439+01	0	\N	\N
546	6035	757	Eco-conseiller - Module 5 : La relation client	137	95	0	\N	elearning_async	2026-02-03 16:24:28.09544+01	2026-02-03 16:24:28.09544+01	0	\N	\N
547	6036	752	Projet tutoré	114	95	0	\N	elearning_async	2026-02-03 16:24:28.095441+01	2026-02-03 16:24:28.095441+01	0	\N	\N
548	6037	762	[AE] Guide du DPE	140	95	0	2025-07-09 19:37:20+02	elearning_async	2026-02-03 16:24:28.095442+01	2026-02-03 16:24:28.095442+01	2778	2025-07-03 09:44:08+02	\N
549	6038	761	DPE - Sans Mention	138	95	0	\N	elearning_async	2026-02-03 16:24:28.095443+01	2026-02-03 16:24:28.095444+01	0	\N	\N
550	6039	763	DPE - Avec Mention	139	95	0	2025-06-18 17:00:17+02	elearning_async	2026-02-03 16:24:28.095444+01	2026-02-03 16:24:28.095445+01	2962	2025-06-16 08:37:03+02	\N
551	6054	750	Blocs 1 et 2 - Bienvenue !	117	95	0	\N	elearning_async	2026-02-03 16:24:28.095445+01	2026-02-03 16:24:28.095446+01	0	\N	\N
552	6055	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	95	0	\N	elearning_async	2026-02-03 16:24:28.095447+01	2026-02-03 16:24:28.095447+01	0	\N	\N
553	6056	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	95	0	\N	elearning_async	2026-02-03 16:24:28.095448+01	2026-02-03 16:24:28.095448+01	0	\N	\N
554	6057	768	[AE MI] Partie 3 : Conception de scénarios	143	95	0	\N	elearning_async	2026-02-03 16:24:28.095449+01	2026-02-03 16:24:28.095449+01	0	\N	\N
555	6058	769	[AE MI] Partie 4 : Le rapport	144	95	0	\N	elearning_async	2026-02-03 16:24:28.09545+01	2026-02-03 16:24:28.095451+01	0	\N	\N
556	6059	770	[AE MI] Cas Pratique	145	95	0	\N	elearning_async	2026-02-03 16:24:28.095451+01	2026-02-03 16:24:28.095452+01	0	\N	\N
557	6060	773	Mon Accompagnateur Rénov'	146	95	0	\N	elearning_async	2026-02-03 16:24:28.095452+01	2026-02-03 16:24:28.095453+01	0	\N	\N
558	6061	777	Audit énergétique - BCT	153	95	0	\N	elearning_async	2026-02-03 16:24:28.095453+01	2026-02-03 16:24:28.095454+01	0	\N	\N
559	6062	779	Management, Communication, Handicap	152	95	0	\N	elearning_async	2026-02-03 16:24:28.095454+01	2026-02-03 16:24:28.095455+01	0	\N	\N
560	6063	780	Ordonnancement, Pilotage, et Coordination	154	95	0	\N	elearning_async	2026-02-03 16:24:28.095456+01	2026-02-03 16:24:28.095456+01	0	\N	\N
561	14339	1020	DPE avec mention	116	95	0	\N	elearning_async	2026-02-03 16:24:28.095457+01	2026-02-03 16:24:28.095457+01	0	\N	\N
562	15097	1151	Point tutoré - BC01 02	118	95	0	\N	elearning_async	2026-02-03 16:24:28.095458+01	2026-02-03 16:24:28.095458+01	0	\N	\N
563	18041	1898	MAR (C&M) - Module 1 : Les prérequis	147	95	0	\N	elearning_async	2026-02-03 16:24:28.095459+01	2026-02-03 16:24:28.09546+01	0	\N	\N
564	18074	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	95	0	\N	elearning_async	2026-02-03 16:24:28.09546+01	2026-02-03 16:24:28.095461+01	0	\N	\N
565	18107	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	95	0	\N	elearning_async	2026-02-03 16:24:28.095462+01	2026-02-03 16:24:28.095462+01	0	\N	\N
566	18140	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	95	0	\N	elearning_async	2026-02-03 16:24:28.095463+01	2026-02-03 16:24:28.095463+01	0	\N	\N
567	18173	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	95	0	\N	elearning_async	2026-02-03 16:24:28.095464+01	2026-02-03 16:24:28.095464+01	0	\N	\N
568	6077	749	Chef de projet en rénovation énergétique - Bienvenue	115	96	100	2025-05-26 12:35:08+02	elearning_async	2026-02-03 16:24:28.593156+01	2026-02-03 16:24:28.593159+01	8580	2025-05-26 10:28:55+02	2025-05-26 13:12:25+02
569	6078	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	96	100	2025-06-06 09:53:24+02	elearning_async	2026-02-03 16:24:28.59316+01	2026-02-03 16:24:28.593161+01	29184	2025-06-04 09:38:09+02	2025-06-06 10:19:34+02
570	6079	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	96	100	2025-06-16 14:58:22+02	elearning_async	2026-02-03 16:24:28.593161+01	2026-02-03 16:24:28.593162+01	51914	2025-06-06 10:22:12+02	2025-06-16 16:12:05+02
571	6080	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	96	100	2025-06-16 16:41:00+02	elearning_async	2026-02-03 16:24:28.593162+01	2026-02-03 16:24:28.593163+01	2654	2025-06-16 16:41:00+02	2025-06-16 17:24:53+02
572	6081	756	Eco-conseiller - Module 4 : Aides et subventions	136	96	100	2025-06-17 20:09:12+02	elearning_async	2026-02-03 16:24:28.593163+01	2026-02-03 16:24:28.593164+01	23222	2025-06-17 10:15:05+02	2025-06-17 20:09:11+02
573	6082	757	Eco-conseiller - Module 5 : La relation client	137	96	100	2025-06-18 09:48:47+02	elearning_async	2026-02-03 16:24:28.593164+01	2026-02-03 16:24:28.593165+01	9436	2025-06-18 09:48:46+02	2025-06-18 12:20:05+02
574	6083	752	Projet tutoré	114	96	100	2025-06-11 14:25:50+02	elearning_async	2026-02-03 16:24:28.593165+01	2026-02-03 16:24:28.593166+01	9912	2025-06-06 10:45:32+02	2025-06-11 14:25:50+02
575	6084	762	[AE] Guide du DPE	140	96	65	2025-07-17 21:06:18+02	elearning_async	2026-02-03 16:24:28.593166+01	2026-02-03 16:24:28.593167+01	43124	2025-06-23 09:05:56+02	\N
576	6085	761	DPE - Sans Mention	138	96	100	2025-07-17 15:29:05+02	elearning_async	2026-02-03 16:24:28.593167+01	2026-02-03 16:24:28.593168+01	54846	2025-07-03 10:12:30+02	2025-07-17 15:10:56+02
577	6086	763	DPE - Avec Mention	139	96	20	2025-09-03 13:21:19+02	elearning_async	2026-02-03 16:24:28.593168+01	2026-02-03 16:24:28.593169+01	8540	2025-09-03 11:44:48+02	\N
578	6101	750	Blocs 1 et 2 - Bienvenue !	117	96	0	\N	elearning_async	2026-02-03 16:24:28.593169+01	2026-02-03 16:24:28.59317+01	0	\N	\N
579	6102	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	96	0	\N	elearning_async	2026-02-03 16:24:28.59317+01	2026-02-03 16:24:28.593171+01	0	\N	\N
580	6103	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	96	0	\N	elearning_async	2026-02-03 16:24:28.593171+01	2026-02-03 16:24:28.593172+01	0	\N	\N
581	6104	768	[AE MI] Partie 3 : Conception de scénarios	143	96	0	\N	elearning_async	2026-02-03 16:24:28.593172+01	2026-02-03 16:24:28.593173+01	0	\N	\N
582	6105	769	[AE MI] Partie 4 : Le rapport	144	96	0	\N	elearning_async	2026-02-03 16:24:28.593173+01	2026-02-03 16:24:28.593174+01	0	\N	\N
583	6106	770	[AE MI] Cas Pratique	145	96	0	\N	elearning_async	2026-02-03 16:24:28.593174+01	2026-02-03 16:24:28.593175+01	0	\N	\N
584	6107	773	Mon Accompagnateur Rénov'	146	96	0	\N	elearning_async	2026-02-03 16:24:28.593175+01	2026-02-03 16:24:28.593176+01	0	\N	\N
585	6108	777	Audit énergétique - BCT	153	96	0	\N	elearning_async	2026-02-03 16:24:28.593176+01	2026-02-03 16:24:28.593177+01	0	\N	\N
586	6109	779	Management, Communication, Handicap	152	96	0	\N	elearning_async	2026-02-03 16:24:28.593177+01	2026-02-03 16:24:28.593178+01	0	\N	\N
587	6110	780	Ordonnancement, Pilotage, et Coordination	154	96	0	\N	elearning_async	2026-02-03 16:24:28.593178+01	2026-02-03 16:24:28.593179+01	0	\N	\N
588	14340	1020	DPE avec mention	116	96	20	2025-09-03 14:11:24+02	elearning_async	2026-02-03 16:24:28.593179+01	2026-02-03 16:24:28.59318+01	8540	2025-09-03 11:44:48+02	\N
589	15098	1151	Point tutoré - BC01 02	118	96	0	\N	elearning_async	2026-02-03 16:24:28.59318+01	2026-02-03 16:24:28.593181+01	0	\N	\N
590	18042	1898	MAR (C&M) - Module 1 : Les prérequis	147	96	0	\N	elearning_async	2026-02-03 16:24:28.593181+01	2026-02-03 16:24:28.593182+01	0	\N	\N
591	18075	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	96	0	\N	elearning_async	2026-02-03 16:24:28.593182+01	2026-02-03 16:24:28.593183+01	0	\N	\N
592	18108	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	96	0	\N	elearning_async	2026-02-03 16:24:28.593183+01	2026-02-03 16:24:28.593184+01	0	\N	\N
593	18141	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	96	0	\N	elearning_async	2026-02-03 16:24:28.593184+01	2026-02-03 16:24:28.593185+01	0	\N	\N
594	18174	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	96	0	\N	elearning_async	2026-02-03 16:24:28.593185+01	2026-02-03 16:24:28.593186+01	0	\N	\N
595	14279	749	Chef de projet en rénovation énergétique - Bienvenue	115	46	0	\N	elearning_async	2026-02-03 16:24:28.995207+01	2026-02-03 16:24:28.995212+01	0	\N	\N
596	14280	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	46	0	\N	elearning_async	2026-02-03 16:24:28.995213+01	2026-02-03 16:24:28.995214+01	0	\N	\N
597	14281	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	46	0	\N	elearning_async	2026-02-03 16:24:28.995215+01	2026-02-03 16:24:28.995216+01	0	\N	\N
598	14282	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	46	0	\N	elearning_async	2026-02-03 16:24:28.995217+01	2026-02-03 16:24:28.995217+01	0	\N	\N
599	14283	756	Eco-conseiller - Module 4 : Aides et subventions	136	46	0	\N	elearning_async	2026-02-03 16:24:28.995218+01	2026-02-03 16:24:28.995219+01	0	\N	\N
600	14284	757	Eco-conseiller - Module 5 : La relation client	137	46	0	\N	elearning_async	2026-02-03 16:24:28.99522+01	2026-02-03 16:24:28.99522+01	0	\N	\N
601	14285	752	Projet tutoré	114	46	0	\N	elearning_async	2026-02-03 16:24:28.995221+01	2026-02-03 16:24:28.995222+01	0	\N	\N
602	14286	762	[AE] Guide du DPE	140	46	0	\N	elearning_async	2026-02-03 16:24:28.995222+01	2026-02-03 16:24:28.995223+01	0	\N	\N
604	14288	763	DPE - Avec Mention	139	46	0	\N	elearning_async	2026-02-03 16:24:28.995226+01	2026-02-03 16:24:28.995227+01	0	\N	\N
605	14303	750	Blocs 1 et 2 - Bienvenue !	117	46	0	\N	elearning_async	2026-02-03 16:24:28.995228+01	2026-02-03 16:24:28.995228+01	0	\N	\N
606	14304	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	46	0	\N	elearning_async	2026-02-03 16:24:28.995229+01	2026-02-03 16:24:28.99523+01	0	\N	\N
607	14305	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	46	0	\N	elearning_async	2026-02-03 16:24:28.995231+01	2026-02-03 16:24:28.995232+01	0	\N	\N
608	14306	768	[AE MI] Partie 3 : Conception de scénarios	143	46	0	\N	elearning_async	2026-02-03 16:24:28.995233+01	2026-02-03 16:24:28.995234+01	0	\N	\N
609	14307	769	[AE MI] Partie 4 : Le rapport	144	46	0	\N	elearning_async	2026-02-03 16:24:28.995235+01	2026-02-03 16:24:28.995236+01	0	\N	\N
610	14308	770	[AE MI] Cas Pratique	145	46	0	\N	elearning_async	2026-02-03 16:24:28.995237+01	2026-02-03 16:24:28.995238+01	0	\N	\N
611	14309	773	Mon Accompagnateur Rénov'	146	46	0	\N	elearning_async	2026-02-03 16:24:28.995239+01	2026-02-03 16:24:28.99524+01	0	\N	\N
612	14310	777	Audit énergétique - BCT	153	46	0	\N	elearning_async	2026-02-03 16:24:28.995241+01	2026-02-03 16:24:28.995241+01	0	\N	\N
613	14311	779	Management, Communication, Handicap	152	46	0	\N	elearning_async	2026-02-03 16:24:28.995242+01	2026-02-03 16:24:28.995243+01	0	\N	\N
614	14312	780	Ordonnancement, Pilotage, et Coordination	154	46	0	\N	elearning_async	2026-02-03 16:24:28.995244+01	2026-02-03 16:24:28.995245+01	0	\N	\N
615	14341	1020	DPE avec mention	116	46	0	\N	elearning_async	2026-02-03 16:24:28.995246+01	2026-02-03 16:24:28.995247+01	0	\N	\N
616	15099	1151	Point tutoré - BC01 02	118	46	0	\N	elearning_async	2026-02-03 16:24:28.995248+01	2026-02-03 16:24:28.995249+01	0	\N	\N
617	18043	1898	MAR (C&M) - Module 1 : Les prérequis	147	46	0	\N	elearning_async	2026-02-03 16:24:28.99525+01	2026-02-03 16:24:28.995251+01	0	\N	\N
618	18076	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	46	0	\N	elearning_async	2026-02-03 16:24:28.995252+01	2026-02-03 16:24:28.995253+01	0	\N	\N
619	18109	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	46	0	\N	elearning_async	2026-02-03 16:24:28.995254+01	2026-02-03 16:24:28.995255+01	0	\N	\N
620	18142	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	46	0	\N	elearning_async	2026-02-03 16:24:28.995256+01	2026-02-03 16:24:28.995257+01	0	\N	\N
621	18175	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	46	0	\N	elearning_async	2026-02-03 16:24:28.995258+01	2026-02-03 16:24:28.995258+01	0	\N	\N
622	14590	749	Chef de projet en rénovation énergétique - Bienvenue	115	97	33	2025-06-10 20:33:07+02	elearning_async	2026-02-03 16:24:29.485229+01	2026-02-03 16:24:29.485233+01	1958	2025-06-10 12:57:01+02	\N
623	14591	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	97	15	2025-06-15 20:27:29+02	elearning_async	2026-02-03 16:24:29.485234+01	2026-02-03 16:24:29.485235+01	1074	2025-06-15 20:27:29+02	\N
624	14592	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	97	0	\N	elearning_async	2026-02-03 16:24:29.485235+01	2026-02-03 16:24:29.485236+01	0	\N	\N
625	14593	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	97	0	\N	elearning_async	2026-02-03 16:24:29.485237+01	2026-02-03 16:24:29.485237+01	0	\N	\N
626	14594	756	Eco-conseiller - Module 4 : Aides et subventions	136	97	0	\N	elearning_async	2026-02-03 16:24:29.485238+01	2026-02-03 16:24:29.485238+01	0	\N	\N
627	14595	757	Eco-conseiller - Module 5 : La relation client	137	97	0	\N	elearning_async	2026-02-03 16:24:29.485239+01	2026-02-03 16:24:29.48524+01	0	\N	\N
628	14596	752	Projet tutoré	114	97	0	\N	elearning_async	2026-02-03 16:24:29.48524+01	2026-02-03 16:24:29.485241+01	0	\N	\N
629	14597	762	[AE] Guide du DPE	140	97	0	\N	elearning_async	2026-02-03 16:24:29.485241+01	2026-02-03 16:24:29.485242+01	0	\N	\N
630	14598	761	DPE - Sans Mention	138	97	0	\N	elearning_async	2026-02-03 16:24:29.485243+01	2026-02-03 16:24:29.485243+01	0	\N	\N
631	14599	1020	DPE avec mention	116	97	0	\N	elearning_async	2026-02-03 16:24:29.485244+01	2026-02-03 16:24:29.485244+01	0	\N	\N
632	14600	763	DPE - Avec Mention	139	97	0	\N	elearning_async	2026-02-03 16:24:29.485245+01	2026-02-03 16:24:29.485246+01	0	\N	\N
633	14615	750	Blocs 1 et 2 - Bienvenue !	117	97	0	\N	elearning_async	2026-02-03 16:24:29.485246+01	2026-02-03 16:24:29.485247+01	0	\N	\N
634	14616	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	97	0	\N	elearning_async	2026-02-03 16:24:29.485247+01	2026-02-03 16:24:29.485248+01	0	\N	\N
635	14617	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	97	0	\N	elearning_async	2026-02-03 16:24:29.485248+01	2026-02-03 16:24:29.485249+01	0	\N	\N
636	14618	768	[AE MI] Partie 3 : Conception de scénarios	143	97	0	\N	elearning_async	2026-02-03 16:24:29.485249+01	2026-02-03 16:24:29.48525+01	0	\N	\N
637	14619	769	[AE MI] Partie 4 : Le rapport	144	97	0	\N	elearning_async	2026-02-03 16:24:29.48525+01	2026-02-03 16:24:29.485251+01	0	\N	\N
638	14620	770	[AE MI] Cas Pratique	145	97	0	\N	elearning_async	2026-02-03 16:24:29.485251+01	2026-02-03 16:24:29.485252+01	0	\N	\N
639	14621	773	Mon Accompagnateur Rénov'	146	97	0	\N	elearning_async	2026-02-03 16:24:29.485253+01	2026-02-03 16:24:29.485253+01	0	\N	\N
640	14622	777	Audit énergétique - BCT	153	97	0	\N	elearning_async	2026-02-03 16:24:29.485254+01	2026-02-03 16:24:29.485254+01	0	\N	\N
641	14623	779	Management, Communication, Handicap	152	97	0	\N	elearning_async	2026-02-03 16:24:29.485255+01	2026-02-03 16:24:29.485255+01	0	\N	\N
642	14624	780	Ordonnancement, Pilotage, et Coordination	154	97	0	\N	elearning_async	2026-02-03 16:24:29.485256+01	2026-02-03 16:24:29.485256+01	0	\N	\N
643	15101	1151	Point tutoré - BC01 02	118	97	0	\N	elearning_async	2026-02-03 16:24:29.485257+01	2026-02-03 16:24:29.485257+01	0	\N	\N
644	18044	1898	MAR (C&M) - Module 1 : Les prérequis	147	97	0	\N	elearning_async	2026-02-03 16:24:29.485258+01	2026-02-03 16:24:29.485258+01	0	\N	\N
645	18077	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	97	0	\N	elearning_async	2026-02-03 16:24:29.485259+01	2026-02-03 16:24:29.485259+01	0	\N	\N
646	18110	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	97	0	\N	elearning_async	2026-02-03 16:24:29.48526+01	2026-02-03 16:24:29.485261+01	0	\N	\N
647	18143	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	97	0	\N	elearning_async	2026-02-03 16:24:29.485261+01	2026-02-03 16:24:29.485262+01	0	\N	\N
648	18176	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	97	0	\N	elearning_async	2026-02-03 16:24:29.485262+01	2026-02-03 16:24:29.485263+01	0	\N	\N
649	14828	749	Chef de projet en rénovation énergétique - Bienvenue	115	98	0	\N	elearning_async	2026-02-03 16:24:29.999388+01	2026-02-03 16:24:29.999392+01	0	\N	\N
650	14829	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	98	100	2025-06-26 16:40:25+02	elearning_async	2026-02-03 16:24:29.999393+01	2026-02-03 16:24:29.999393+01	13904	2025-06-20 13:49:45+02	2025-06-26 17:05:14+02
651	14830	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	98	57	2025-07-28 12:07:47+02	elearning_async	2026-02-03 16:24:29.999394+01	2026-02-03 16:24:29.999394+01	25442	2025-07-02 10:59:15+02	\N
652	14831	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	98	0	\N	elearning_async	2026-02-03 16:24:29.999395+01	2026-02-03 16:24:29.999395+01	0	\N	\N
653	14832	756	Eco-conseiller - Module 4 : Aides et subventions	136	98	0	\N	elearning_async	2026-02-03 16:24:29.999396+01	2026-02-03 16:24:29.999397+01	0	\N	\N
654	14833	757	Eco-conseiller - Module 5 : La relation client	137	98	0	\N	elearning_async	2026-02-03 16:24:29.999397+01	2026-02-03 16:24:29.999398+01	0	\N	\N
655	14834	752	Projet tutoré	114	98	100	2025-06-16 15:35:23+02	elearning_async	2026-02-03 16:24:29.999398+01	2026-02-03 16:24:29.999399+01	630	2025-06-16 10:37:01+02	2025-06-16 15:42:22+02
656	14835	762	[AE] Guide du DPE	140	98	99	2025-07-15 15:49:09+02	elearning_async	2026-02-03 16:24:29.999399+01	2026-02-03 16:24:29.9994+01	82526	2025-07-02 17:52:04+02	2025-07-15 15:57:19+02
657	14836	761	DPE - Sans Mention	138	98	100	2025-09-09 10:20:09+02	elearning_async	2026-02-03 16:24:29.9994+01	2026-02-03 16:24:29.999401+01	44904	2025-07-16 15:02:23+02	2025-09-09 10:16:02+02
658	14837	1020	DPE avec mention	116	98	0	\N	elearning_async	2026-02-03 16:24:29.999401+01	2026-02-03 16:24:29.999402+01	0	\N	\N
659	14838	763	DPE - Avec Mention	139	98	0	\N	elearning_async	2026-02-03 16:24:29.999402+01	2026-02-03 16:24:29.999403+01	0	\N	\N
660	14853	750	Blocs 1 et 2 - Bienvenue !	117	98	100	2025-06-11 17:24:58+02	elearning_async	2026-02-03 16:24:29.999404+01	2026-02-03 16:24:29.999404+01	6486	2025-06-11 13:49:05+02	2025-06-11 17:55:01+02
661	14854	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	98	0	\N	elearning_async	2026-02-03 16:24:29.999405+01	2026-02-03 16:24:29.999405+01	0	\N	\N
662	14855	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	98	0	\N	elearning_async	2026-02-03 16:24:29.999406+01	2026-02-03 16:24:29.999406+01	0	\N	\N
663	14856	768	[AE MI] Partie 3 : Conception de scénarios	143	98	0	\N	elearning_async	2026-02-03 16:24:29.999407+01	2026-02-03 16:24:29.999407+01	0	\N	\N
664	14857	769	[AE MI] Partie 4 : Le rapport	144	98	0	\N	elearning_async	2026-02-03 16:24:29.999408+01	2026-02-03 16:24:29.999408+01	0	\N	\N
665	14858	770	[AE MI] Cas Pratique	145	98	0	\N	elearning_async	2026-02-03 16:24:29.999409+01	2026-02-03 16:24:29.999409+01	0	\N	\N
666	14859	773	Mon Accompagnateur Rénov'	146	98	0	\N	elearning_async	2026-02-03 16:24:29.99941+01	2026-02-03 16:24:29.99941+01	0	\N	\N
667	14860	777	Audit énergétique - BCT	153	98	0	\N	elearning_async	2026-02-03 16:24:29.999411+01	2026-02-03 16:24:29.999411+01	0	\N	\N
668	14861	779	Management, Communication, Handicap	152	98	0	\N	elearning_async	2026-02-03 16:24:29.999412+01	2026-02-03 16:24:29.999412+01	0	\N	\N
669	14862	780	Ordonnancement, Pilotage, et Coordination	154	98	0	\N	elearning_async	2026-02-03 16:24:29.999413+01	2026-02-03 16:24:29.999414+01	0	\N	\N
670	15103	1151	Point tutoré - BC01 02	118	98	100	2025-06-16 10:33:27+02	elearning_async	2026-02-03 16:24:29.999414+01	2026-02-03 16:24:29.999415+01	12918	2025-06-13 14:12:58+02	2025-06-16 10:34:15+02
671	18046	1898	MAR (C&M) - Module 1 : Les prérequis	147	98	0	\N	elearning_async	2026-02-03 16:24:29.999415+01	2026-02-03 16:24:29.999416+01	0	\N	\N
672	18079	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	98	0	\N	elearning_async	2026-02-03 16:24:29.999416+01	2026-02-03 16:24:29.999417+01	0	\N	\N
673	18112	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	98	0	\N	elearning_async	2026-02-03 16:24:29.999417+01	2026-02-03 16:24:29.999418+01	0	\N	\N
674	18145	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	98	0	\N	elearning_async	2026-02-03 16:24:29.999418+01	2026-02-03 16:24:29.999419+01	0	\N	\N
675	18178	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	98	0	\N	elearning_async	2026-02-03 16:24:29.999419+01	2026-02-03 16:24:29.99942+01	0	\N	\N
676	14863	749	Chef de projet en rénovation énergétique - Bienvenue	115	99	100	2025-06-10 21:28:23+02	elearning_async	2026-02-03 16:24:30.512146+01	2026-02-03 16:24:30.512149+01	20468	2025-06-09 11:43:33+02	2025-06-10 22:07:44+02
677	14864	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	99	100	2025-06-23 08:53:51+02	elearning_async	2026-02-03 16:24:30.51215+01	2026-02-03 16:24:30.512151+01	14724	2025-06-20 22:21:49+02	2025-06-23 08:55:00+02
678	14865	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	99	0	\N	elearning_async	2026-02-03 16:24:30.512151+01	2026-02-03 16:24:30.512152+01	0	\N	\N
679	14866	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	99	0	\N	elearning_async	2026-02-03 16:24:30.512152+01	2026-02-03 16:24:30.512153+01	0	\N	\N
680	14867	756	Eco-conseiller - Module 4 : Aides et subventions	136	99	0	\N	elearning_async	2026-02-03 16:24:30.512154+01	2026-02-03 16:24:30.512154+01	0	\N	\N
681	14868	757	Eco-conseiller - Module 5 : La relation client	137	99	0	\N	elearning_async	2026-02-03 16:24:30.512155+01	2026-02-03 16:24:30.512155+01	0	\N	\N
682	14869	752	Projet tutoré	114	99	3	2025-06-10 22:17:13+02	elearning_async	2026-02-03 16:24:30.512156+01	2026-02-03 16:24:30.512157+01	1320	2025-06-10 22:17:13+02	\N
683	14870	762	[AE] Guide du DPE	140	99	6	2025-07-09 10:57:41+02	elearning_async	2026-02-03 16:24:30.512157+01	2026-02-03 16:24:30.512158+01	7410	2025-07-04 15:36:07+02	\N
684	14871	761	DPE - Sans Mention	138	99	0	\N	elearning_async	2026-02-03 16:24:30.512158+01	2026-02-03 16:24:30.512159+01	0	\N	\N
685	14872	1020	DPE avec mention	116	99	0	\N	elearning_async	2026-02-03 16:24:30.512159+01	2026-02-03 16:24:30.51216+01	0	\N	\N
686	14873	763	DPE - Avec Mention	139	99	0	\N	elearning_async	2026-02-03 16:24:30.51216+01	2026-02-03 16:24:30.512161+01	0	\N	\N
687	14888	750	Blocs 1 et 2 - Bienvenue !	117	99	0	\N	elearning_async	2026-02-03 16:24:30.512161+01	2026-02-03 16:24:30.512162+01	0	\N	\N
688	14889	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	99	0	\N	elearning_async	2026-02-03 16:24:30.512163+01	2026-02-03 16:24:30.512163+01	0	\N	\N
689	14890	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	99	0	\N	elearning_async	2026-02-03 16:24:30.512164+01	2026-02-03 16:24:30.512164+01	0	\N	\N
690	14891	768	[AE MI] Partie 3 : Conception de scénarios	143	99	0	\N	elearning_async	2026-02-03 16:24:30.512165+01	2026-02-03 16:24:30.512165+01	0	\N	\N
691	14892	769	[AE MI] Partie 4 : Le rapport	144	99	0	\N	elearning_async	2026-02-03 16:24:30.512166+01	2026-02-03 16:24:30.512166+01	0	\N	\N
692	14893	770	[AE MI] Cas Pratique	145	99	0	\N	elearning_async	2026-02-03 16:24:30.512167+01	2026-02-03 16:24:30.512167+01	0	\N	\N
693	14894	773	Mon Accompagnateur Rénov'	146	99	0	\N	elearning_async	2026-02-03 16:24:30.512168+01	2026-02-03 16:24:30.512168+01	0	\N	\N
694	14895	777	Audit énergétique - BCT	153	99	0	\N	elearning_async	2026-02-03 16:24:30.512169+01	2026-02-03 16:24:30.512169+01	0	\N	\N
695	14896	779	Management, Communication, Handicap	152	99	0	\N	elearning_async	2026-02-03 16:24:30.51217+01	2026-02-03 16:24:30.512171+01	0	\N	\N
696	14897	780	Ordonnancement, Pilotage, et Coordination	154	99	0	\N	elearning_async	2026-02-03 16:24:30.512171+01	2026-02-03 16:24:30.512172+01	0	\N	\N
697	15104	1151	Point tutoré - BC01 02	118	99	0	\N	elearning_async	2026-02-03 16:24:30.512172+01	2026-02-03 16:24:30.512173+01	0	\N	\N
698	18047	1898	MAR (C&M) - Module 1 : Les prérequis	147	99	0	\N	elearning_async	2026-02-03 16:24:30.512173+01	2026-02-03 16:24:30.512174+01	0	\N	\N
699	18080	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	99	0	\N	elearning_async	2026-02-03 16:24:30.512174+01	2026-02-03 16:24:30.512175+01	0	\N	\N
700	18113	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	99	0	\N	elearning_async	2026-02-03 16:24:30.512175+01	2026-02-03 16:24:30.512176+01	0	\N	\N
701	18146	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	99	0	\N	elearning_async	2026-02-03 16:24:30.512176+01	2026-02-03 16:24:30.512177+01	0	\N	\N
702	18179	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	99	0	\N	elearning_async	2026-02-03 16:24:30.512178+01	2026-02-03 16:24:30.512178+01	0	\N	\N
703	14898	749	Chef de projet en rénovation énergétique - Bienvenue	115	100	0	\N	elearning_async	2026-02-03 16:24:30.988543+01	2026-02-03 16:24:30.988547+01	0	\N	\N
704	14899	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	100	100	2025-06-16 14:17:52+02	elearning_async	2026-02-03 16:24:30.988548+01	2026-02-03 16:24:30.988548+01	15776	2025-06-06 18:28:57+02	2025-06-16 14:45:23+02
705	14900	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	100	57	2025-07-03 14:07:11+02	elearning_async	2026-02-03 16:24:30.988549+01	2026-02-03 16:24:30.988549+01	18944	2025-06-16 14:51:04+02	\N
706	14901	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	100	0	\N	elearning_async	2026-02-03 16:24:30.98855+01	2026-02-03 16:24:30.988551+01	0	\N	\N
707	14902	756	Eco-conseiller - Module 4 : Aides et subventions	136	100	0	\N	elearning_async	2026-02-03 16:24:30.988551+01	2026-02-03 16:24:30.988552+01	0	\N	\N
708	14903	757	Eco-conseiller - Module 5 : La relation client	137	100	0	\N	elearning_async	2026-02-03 16:24:30.988552+01	2026-02-03 16:24:30.988553+01	0	\N	\N
709	14904	752	Projet tutoré	114	100	0	\N	elearning_async	2026-02-03 16:24:30.988553+01	2026-02-03 16:24:30.988554+01	0	\N	\N
710	14905	762	[AE] Guide du DPE	140	100	47	2025-08-04 10:38:05+02	elearning_async	2026-02-03 16:24:30.988554+01	2026-02-03 16:24:30.988555+01	62648	2025-06-10 17:25:49+02	\N
711	14906	761	DPE - Sans Mention	138	100	0	\N	elearning_async	2026-02-03 16:24:30.988555+01	2026-02-03 16:24:30.988556+01	0	\N	\N
712	14907	1020	DPE avec mention	116	100	0	\N	elearning_async	2026-02-03 16:24:30.988556+01	2026-02-03 16:24:30.988557+01	0	\N	\N
713	14908	763	DPE - Avec Mention	139	100	0	\N	elearning_async	2026-02-03 16:24:30.988557+01	2026-02-03 16:24:30.988558+01	0	\N	\N
714	14923	750	Blocs 1 et 2 - Bienvenue !	117	100	0	\N	elearning_async	2026-02-03 16:24:30.988558+01	2026-02-03 16:24:30.988559+01	0	\N	\N
715	14924	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	100	0	\N	elearning_async	2026-02-03 16:24:30.988559+01	2026-02-03 16:24:30.98856+01	0	\N	\N
716	14925	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	100	0	\N	elearning_async	2026-02-03 16:24:30.98856+01	2026-02-03 16:24:30.988561+01	0	\N	\N
717	14926	768	[AE MI] Partie 3 : Conception de scénarios	143	100	0	\N	elearning_async	2026-02-03 16:24:30.988561+01	2026-02-03 16:24:30.988562+01	0	\N	\N
718	14927	769	[AE MI] Partie 4 : Le rapport	144	100	0	\N	elearning_async	2026-02-03 16:24:30.988562+01	2026-02-03 16:24:30.988563+01	0	\N	\N
719	14928	770	[AE MI] Cas Pratique	145	100	0	\N	elearning_async	2026-02-03 16:24:30.988564+01	2026-02-03 16:24:30.988564+01	0	\N	\N
720	14929	773	Mon Accompagnateur Rénov'	146	100	0	\N	elearning_async	2026-02-03 16:24:30.988565+01	2026-02-03 16:24:30.988565+01	0	\N	\N
721	14930	777	Audit énergétique - BCT	153	100	0	\N	elearning_async	2026-02-03 16:24:30.988566+01	2026-02-03 16:24:30.988566+01	0	\N	\N
722	14931	779	Management, Communication, Handicap	152	100	0	\N	elearning_async	2026-02-03 16:24:30.988567+01	2026-02-03 16:24:30.988567+01	0	\N	\N
723	14932	780	Ordonnancement, Pilotage, et Coordination	154	100	0	\N	elearning_async	2026-02-03 16:24:30.988568+01	2026-02-03 16:24:30.988568+01	0	\N	\N
724	15105	1151	Point tutoré - BC01 02	118	100	0	\N	elearning_async	2026-02-03 16:24:30.988569+01	2026-02-03 16:24:30.988569+01	0	\N	\N
725	18048	1898	MAR (C&M) - Module 1 : Les prérequis	147	100	0	\N	elearning_async	2026-02-03 16:24:30.98857+01	2026-02-03 16:24:30.98857+01	0	\N	\N
726	18081	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	100	0	\N	elearning_async	2026-02-03 16:24:30.988571+01	2026-02-03 16:24:30.988571+01	0	\N	\N
727	18114	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	100	0	\N	elearning_async	2026-02-03 16:24:30.988572+01	2026-02-03 16:24:30.988572+01	0	\N	\N
728	18147	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	100	0	\N	elearning_async	2026-02-03 16:24:30.988573+01	2026-02-03 16:24:30.988573+01	0	\N	\N
729	18180	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	100	0	\N	elearning_async	2026-02-03 16:24:30.988574+01	2026-02-03 16:24:30.988574+01	0	\N	\N
730	14933	749	Chef de projet en rénovation énergétique - Bienvenue	115	101	100	2025-06-10 14:40:23+02	elearning_async	2026-02-03 16:24:31.46809+01	2026-02-03 16:24:31.468094+01	16778	2025-06-06 15:21:38+02	2025-06-06 21:15:37+02
731	14934	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	101	100	2025-06-19 15:53:06+02	elearning_async	2026-02-03 16:24:31.468095+01	2026-02-03 16:24:31.468095+01	17562	2025-06-17 13:05:38+02	2025-06-18 16:09:48+02
732	14935	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	101	100	2025-06-26 09:31:18+02	elearning_async	2026-02-03 16:24:31.468096+01	2026-02-03 16:24:31.468097+01	39190	2025-06-19 10:26:11+02	2025-06-28 15:50:30+02
733	14936	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	101	100	2025-06-29 13:57:24+02	elearning_async	2026-02-03 16:24:31.468097+01	2026-02-03 16:24:31.468098+01	1990	2025-06-29 11:09:15+02	2025-06-29 11:40:21+02
734	14937	756	Eco-conseiller - Module 4 : Aides et subventions	136	101	100	2025-07-01 09:56:13+02	elearning_async	2026-02-03 16:24:31.468098+01	2026-02-03 16:24:31.468099+01	13130	2025-06-29 11:45:28+02	2025-06-30 18:55:15+02
735	14938	757	Eco-conseiller - Module 5 : La relation client	137	101	100	2025-07-02 10:18:25+02	elearning_async	2026-02-03 16:24:31.4681+01	2026-02-03 16:24:31.4681+01	856	2025-07-01 09:59:50+02	2025-07-01 10:01:02+02
736	14939	752	Projet tutoré	114	101	100	2025-07-03 07:35:52+02	elearning_async	2026-02-03 16:24:31.468101+01	2026-02-03 16:24:31.468101+01	18232	2025-06-07 09:37:58+02	2025-06-16 22:18:42+02
737	14940	762	[AE] Guide du DPE	140	101	100	2025-09-12 18:31:27+02	elearning_async	2026-02-03 16:24:31.468102+01	2026-02-03 16:24:31.468103+01	80336	2025-07-03 07:40:55+02	2025-09-09 12:58:02+02
738	14941	761	DPE - Sans Mention	138	101	100	2025-09-12 18:43:47+02	elearning_async	2026-02-03 16:24:31.468103+01	2026-02-03 16:24:31.468104+01	28270	2025-07-10 10:26:47+02	2025-07-21 13:38:29+02
739	14942	1020	DPE avec mention	116	101	100	2025-09-12 15:44:10+02	elearning_async	2026-02-03 16:24:31.468104+01	2026-02-03 16:24:31.468105+01	30306	2025-07-12 16:27:23+02	2025-07-31 09:55:12+02
740	14943	763	DPE - Avec Mention	139	101	100	2025-09-12 15:43:44+02	elearning_async	2026-02-03 16:24:31.468105+01	2026-02-03 16:24:31.468106+01	30306	2025-07-12 16:27:23+02	2025-07-31 09:55:12+02
741	14958	750	Blocs 1 et 2 - Bienvenue !	117	101	0	\N	elearning_async	2026-02-03 16:24:31.468107+01	2026-02-03 16:24:31.468107+01	0	\N	\N
742	14959	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	101	100	2025-08-05 10:37:58+02	elearning_async	2026-02-03 16:24:31.468108+01	2026-02-03 16:24:31.468109+01	5210	2025-07-29 15:59:23+02	2025-08-05 10:41:20+02
743	14960	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	101	100	2025-08-12 12:42:32+02	elearning_async	2026-02-03 16:24:31.468109+01	2026-02-03 16:24:31.46811+01	1264	2025-08-11 14:12:20+02	2025-08-12 12:47:31+02
744	14961	768	[AE MI] Partie 3 : Conception de scénarios	143	101	100	2025-08-14 13:02:43+02	elearning_async	2026-02-03 16:24:31.46811+01	2026-02-03 16:24:31.468111+01	2410	2025-08-12 12:50:15+02	2025-08-14 13:04:40+02
745	14962	769	[AE MI] Partie 4 : Le rapport	144	101	100	2025-08-14 13:09:51+02	elearning_async	2026-02-03 16:24:31.468112+01	2026-02-03 16:24:31.468112+01	372	2025-08-14 13:05:22+02	2025-08-14 13:12:30+02
746	14963	770	[AE MI] Cas Pratique	145	101	0	\N	elearning_async	2026-02-03 16:24:31.468113+01	2026-02-03 16:24:31.468113+01	0	\N	\N
747	14964	773	Mon Accompagnateur Rénov'	146	101	0	\N	elearning_async	2026-02-03 16:24:31.468114+01	2026-02-03 16:24:31.468115+01	0	\N	\N
748	14965	777	Audit énergétique - BCT	153	101	100	2025-08-26 08:37:18+02	elearning_async	2026-02-03 16:24:31.468115+01	2026-02-03 16:24:31.468116+01	26312	2025-08-14 13:14:47+02	2025-08-26 09:21:10+02
749	14966	779	Management, Communication, Handicap	152	101	100	2025-07-02 10:12:13+02	elearning_async	2026-02-03 16:24:31.468116+01	2026-02-03 16:24:31.468117+01	10706	2025-07-01 10:18:16+02	2025-07-02 10:12:11+02
750	14967	780	Ordonnancement, Pilotage, et Coordination	154	101	100	2025-09-08 14:46:29+02	elearning_async	2026-02-03 16:24:31.468117+01	2026-02-03 16:24:31.468118+01	19138	2025-08-29 19:15:37+02	2025-09-08 15:16:37+02
751	15106	1151	Point tutoré - BC01 02	118	101	0	\N	elearning_async	2026-02-03 16:24:31.468118+01	2026-02-03 16:24:31.468119+01	0	\N	\N
752	18049	1898	MAR (C&M) - Module 1 : Les prérequis	147	101	100	2025-08-27 12:26:26+02	elearning_async	2026-02-03 16:24:31.46812+01	2026-02-03 16:24:31.46812+01	11772	2025-08-26 09:23:22+02	2025-08-27 12:31:18+02
753	18082	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	101	100	2025-08-29 14:55:51+02	elearning_async	2026-02-03 16:24:31.468121+01	2026-02-03 16:24:31.468121+01	6358	2025-08-28 08:25:43+02	2025-08-29 14:55:48+02
754	18115	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	101	100	2025-08-29 14:56:46+02	elearning_async	2026-02-03 16:24:31.468122+01	2026-02-03 16:24:31.468122+01	210	2025-08-29 14:56:42+02	2025-08-29 14:59:40+02
755	18148	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	101	100	2025-08-29 16:55:41+02	elearning_async	2026-02-03 16:24:31.468123+01	2026-02-03 16:24:31.468123+01	2766	2025-08-29 16:55:39+02	2025-09-01 15:45:57+02
756	18181	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	101	100	2025-09-09 13:00:29+02	elearning_async	2026-02-03 16:24:31.468124+01	2026-02-03 16:24:31.468124+01	324	2025-09-02 08:15:56+02	2025-09-02 08:15:56+02
757	14968	749	Chef de projet en rénovation énergétique - Bienvenue	115	102	100	2025-06-10 23:06:55+02	elearning_async	2026-02-03 16:24:31.934867+01	2026-02-03 16:24:31.934871+01	4372	2025-06-10 22:11:56+02	2025-06-10 23:08:53+02
758	14969	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	102	100	2025-10-28 16:00:01+01	elearning_async	2026-02-03 16:24:31.934872+01	2026-02-03 16:24:31.934872+01	27426	2025-06-17 21:38:00+02	2025-06-20 19:13:51+02
759	14970	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	102	57	2025-07-02 09:44:15+02	elearning_async	2026-02-03 16:24:31.934873+01	2026-02-03 16:24:31.934873+01	27164	2025-06-21 15:13:18+02	\N
760	14971	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	102	0	\N	elearning_async	2026-02-03 16:24:31.934874+01	2026-02-03 16:24:31.934874+01	0	\N	\N
761	14972	756	Eco-conseiller - Module 4 : Aides et subventions	136	102	0	\N	elearning_async	2026-02-03 16:24:31.934875+01	2026-02-03 16:24:31.934876+01	0	\N	\N
762	14973	757	Eco-conseiller - Module 5 : La relation client	137	102	0	\N	elearning_async	2026-02-03 16:24:31.934876+01	2026-02-03 16:24:31.934877+01	0	\N	\N
763	14974	752	Projet tutoré	114	102	100	2025-06-14 00:29:18+02	elearning_async	2026-02-03 16:24:31.934877+01	2026-02-03 16:24:31.934878+01	10864	2025-06-13 21:29:03+02	2025-06-14 00:30:28+02
764	14975	762	[AE] Guide du DPE	140	102	99	2025-07-16 19:24:00+02	elearning_async	2026-02-03 16:24:31.934878+01	2026-02-03 16:24:31.934879+01	68476	2025-07-03 18:31:00+02	2025-07-16 19:30:40+02
765	14976	761	DPE - Sans Mention	138	102	100	2025-11-05 16:28:58+01	elearning_async	2026-02-03 16:24:31.93488+01	2026-02-03 16:24:31.93488+01	81824	2025-07-16 19:59:46+02	2025-07-18 14:10:36+02
766	14977	1020	DPE avec mention	116	102	0	\N	elearning_async	2026-02-03 16:24:31.934881+01	2026-02-03 16:24:31.934881+01	0	\N	\N
767	14978	763	DPE - Avec Mention	139	102	100	2025-11-09 22:13:30+01	elearning_async	2026-02-03 16:24:31.934882+01	2026-02-03 16:24:31.934882+01	42760	2025-07-18 16:32:58+02	2025-07-20 14:19:25+02
768	14993	750	Blocs 1 et 2 - Bienvenue !	117	102	0	\N	elearning_async	2026-02-03 16:24:31.934883+01	2026-02-03 16:24:31.934883+01	0	\N	\N
769	14994	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	102	38	2025-10-28 16:00:03+01	elearning_async	2026-02-03 16:24:31.934884+01	2026-02-03 16:24:31.934884+01	122	2025-08-06 16:15:10+02	\N
770	14995	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	102	0	\N	elearning_async	2026-02-03 16:24:31.934885+01	2026-02-03 16:24:31.934886+01	0	\N	\N
771	14996	768	[AE MI] Partie 3 : Conception de scénarios	143	102	0	\N	elearning_async	2026-02-03 16:24:31.934886+01	2026-02-03 16:24:31.934887+01	0	\N	\N
772	14997	769	[AE MI] Partie 4 : Le rapport	144	102	0	\N	elearning_async	2026-02-03 16:24:31.934887+01	2026-02-03 16:24:31.934888+01	0	\N	\N
773	14998	770	[AE MI] Cas Pratique	145	102	0	\N	elearning_async	2026-02-03 16:24:31.934888+01	2026-02-03 16:24:31.934889+01	0	\N	\N
774	14999	773	Mon Accompagnateur Rénov'	146	102	0	\N	elearning_async	2026-02-03 16:24:31.93489+01	2026-02-03 16:24:31.93489+01	0	\N	\N
775	15000	777	Audit énergétique - BCT	153	102	0	\N	elearning_async	2026-02-03 16:24:31.934891+01	2026-02-03 16:24:31.934891+01	0	\N	\N
776	15001	779	Management, Communication, Handicap	152	102	0	\N	elearning_async	2026-02-03 16:24:31.934892+01	2026-02-03 16:24:31.934892+01	0	\N	\N
777	15002	780	Ordonnancement, Pilotage, et Coordination	154	102	0	\N	elearning_async	2026-02-03 16:24:31.934893+01	2026-02-03 16:24:31.934894+01	0	\N	\N
778	15107	1151	Point tutoré - BC01 02	118	102	0	\N	elearning_async	2026-02-03 16:24:31.934894+01	2026-02-03 16:24:31.934895+01	0	\N	\N
779	18050	1898	MAR (C&M) - Module 1 : Les prérequis	147	102	0	\N	elearning_async	2026-02-03 16:24:31.934895+01	2026-02-03 16:24:31.934896+01	0	\N	\N
780	18083	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	102	0	\N	elearning_async	2026-02-03 16:24:31.934897+01	2026-02-03 16:24:31.934897+01	0	\N	\N
781	18116	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	102	0	\N	elearning_async	2026-02-03 16:24:31.934898+01	2026-02-03 16:24:31.934898+01	0	\N	\N
782	18149	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	102	0	\N	elearning_async	2026-02-03 16:24:31.934899+01	2026-02-03 16:24:31.934899+01	0	\N	\N
783	18182	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	102	0	\N	elearning_async	2026-02-03 16:24:31.9349+01	2026-02-03 16:24:31.934901+01	0	\N	\N
784	15003	749	Chef de projet en rénovation énergétique - Bienvenue	115	103	0	\N	elearning_async	2026-02-03 16:24:32.379155+01	2026-02-03 16:24:32.379158+01	0	\N	\N
785	15004	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	103	0	\N	elearning_async	2026-02-03 16:24:32.379159+01	2026-02-03 16:24:32.37916+01	0	\N	\N
786	15005	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	103	0	\N	elearning_async	2026-02-03 16:24:32.37916+01	2026-02-03 16:24:32.379161+01	0	\N	\N
787	15006	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	103	0	\N	elearning_async	2026-02-03 16:24:32.379161+01	2026-02-03 16:24:32.379162+01	0	\N	\N
788	15007	756	Eco-conseiller - Module 4 : Aides et subventions	136	103	0	\N	elearning_async	2026-02-03 16:24:32.379162+01	2026-02-03 16:24:32.379163+01	0	\N	\N
789	15008	757	Eco-conseiller - Module 5 : La relation client	137	103	0	\N	elearning_async	2026-02-03 16:24:32.379163+01	2026-02-03 16:24:32.379164+01	0	\N	\N
790	15009	752	Projet tutoré	114	103	0	\N	elearning_async	2026-02-03 16:24:32.379164+01	2026-02-03 16:24:32.379165+01	0	\N	\N
791	15010	762	[AE] Guide du DPE	140	103	0	\N	elearning_async	2026-02-03 16:24:32.379165+01	2026-02-03 16:24:32.379166+01	0	\N	\N
792	15011	761	DPE - Sans Mention	138	103	0	\N	elearning_async	2026-02-03 16:24:32.379166+01	2026-02-03 16:24:32.379167+01	0	\N	\N
793	15012	1020	DPE avec mention	116	103	0	\N	elearning_async	2026-02-03 16:24:32.379167+01	2026-02-03 16:24:32.379168+01	0	\N	\N
794	15013	763	DPE - Avec Mention	139	103	0	\N	elearning_async	2026-02-03 16:24:32.379169+01	2026-02-03 16:24:32.379169+01	0	\N	\N
795	15028	750	Blocs 1 et 2 - Bienvenue !	117	103	0	\N	elearning_async	2026-02-03 16:24:32.37917+01	2026-02-03 16:24:32.37917+01	0	\N	\N
796	15029	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	103	0	\N	elearning_async	2026-02-03 16:24:32.379171+01	2026-02-03 16:24:32.379171+01	0	\N	\N
797	15030	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	103	0	\N	elearning_async	2026-02-03 16:24:32.379172+01	2026-02-03 16:24:32.379172+01	0	\N	\N
798	15031	768	[AE MI] Partie 3 : Conception de scénarios	143	103	0	\N	elearning_async	2026-02-03 16:24:32.379173+01	2026-02-03 16:24:32.379173+01	0	\N	\N
799	15032	769	[AE MI] Partie 4 : Le rapport	144	103	0	\N	elearning_async	2026-02-03 16:24:32.379174+01	2026-02-03 16:24:32.379174+01	0	\N	\N
800	15033	770	[AE MI] Cas Pratique	145	103	0	\N	elearning_async	2026-02-03 16:24:32.379175+01	2026-02-03 16:24:32.379175+01	0	\N	\N
801	15034	773	Mon Accompagnateur Rénov'	146	103	0	\N	elearning_async	2026-02-03 16:24:32.379176+01	2026-02-03 16:24:32.379176+01	0	\N	\N
802	15035	777	Audit énergétique - BCT	153	103	0	\N	elearning_async	2026-02-03 16:24:32.379177+01	2026-02-03 16:24:32.379177+01	0	\N	\N
803	15036	779	Management, Communication, Handicap	152	103	0	\N	elearning_async	2026-02-03 16:24:32.379178+01	2026-02-03 16:24:32.379178+01	0	\N	\N
804	15037	780	Ordonnancement, Pilotage, et Coordination	154	103	0	\N	elearning_async	2026-02-03 16:24:32.379179+01	2026-02-03 16:24:32.37918+01	0	\N	\N
805	15108	1151	Point tutoré - BC01 02	118	103	0	\N	elearning_async	2026-02-03 16:24:32.37918+01	2026-02-03 16:24:32.379181+01	0	\N	\N
806	18051	1898	MAR (C&M) - Module 1 : Les prérequis	147	103	0	\N	elearning_async	2026-02-03 16:24:32.379181+01	2026-02-03 16:24:32.379182+01	0	\N	\N
807	18084	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	103	0	\N	elearning_async	2026-02-03 16:24:32.379182+01	2026-02-03 16:24:32.379183+01	0	\N	\N
808	18117	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	103	0	\N	elearning_async	2026-02-03 16:24:32.379183+01	2026-02-03 16:24:32.379184+01	0	\N	\N
809	18150	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	103	0	\N	elearning_async	2026-02-03 16:24:32.379184+01	2026-02-03 16:24:32.379185+01	0	\N	\N
810	18183	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	103	0	\N	elearning_async	2026-02-03 16:24:32.379185+01	2026-02-03 16:24:32.379186+01	0	\N	\N
811	15038	749	Chef de projet en rénovation énergétique - Bienvenue	115	104	0	\N	elearning_async	2026-02-03 16:24:32.791988+01	2026-02-03 16:24:32.791992+01	0	\N	\N
812	15039	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	104	0	\N	elearning_async	2026-02-03 16:24:32.791993+01	2026-02-03 16:24:32.791993+01	0	\N	\N
813	15040	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	104	0	\N	elearning_async	2026-02-03 16:24:32.791994+01	2026-02-03 16:24:32.791994+01	0	\N	\N
814	15041	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	104	0	\N	elearning_async	2026-02-03 16:24:32.791995+01	2026-02-03 16:24:32.791995+01	0	\N	\N
815	15042	756	Eco-conseiller - Module 4 : Aides et subventions	136	104	0	\N	elearning_async	2026-02-03 16:24:32.791996+01	2026-02-03 16:24:32.791996+01	0	\N	\N
816	15043	757	Eco-conseiller - Module 5 : La relation client	137	104	0	\N	elearning_async	2026-02-03 16:24:32.791997+01	2026-02-03 16:24:32.791997+01	0	\N	\N
817	15044	752	Projet tutoré	114	104	0	\N	elearning_async	2026-02-03 16:24:32.791998+01	2026-02-03 16:24:32.791998+01	0	\N	\N
818	15045	762	[AE] Guide du DPE	140	104	0	\N	elearning_async	2026-02-03 16:24:32.791999+01	2026-02-03 16:24:32.791999+01	0	\N	\N
819	15046	761	DPE - Sans Mention	138	104	0	\N	elearning_async	2026-02-03 16:24:32.792+01	2026-02-03 16:24:32.792+01	0	\N	\N
820	15047	1020	DPE avec mention	116	104	0	\N	elearning_async	2026-02-03 16:24:32.792001+01	2026-02-03 16:24:32.792001+01	0	\N	\N
821	15048	763	DPE - Avec Mention	139	104	0	\N	elearning_async	2026-02-03 16:24:32.792002+01	2026-02-03 16:24:32.792002+01	0	\N	\N
822	15063	750	Blocs 1 et 2 - Bienvenue !	117	104	0	\N	elearning_async	2026-02-03 16:24:32.792003+01	2026-02-03 16:24:32.792003+01	0	\N	\N
823	15064	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	104	0	\N	elearning_async	2026-02-03 16:24:32.792004+01	2026-02-03 16:24:32.792004+01	0	\N	\N
824	15065	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	104	0	\N	elearning_async	2026-02-03 16:24:32.792005+01	2026-02-03 16:24:32.792005+01	0	\N	\N
825	15066	768	[AE MI] Partie 3 : Conception de scénarios	143	104	0	\N	elearning_async	2026-02-03 16:24:32.792006+01	2026-02-03 16:24:32.792007+01	0	\N	\N
826	15067	769	[AE MI] Partie 4 : Le rapport	144	104	0	\N	elearning_async	2026-02-03 16:24:32.792007+01	2026-02-03 16:24:32.792008+01	0	\N	\N
827	15068	770	[AE MI] Cas Pratique	145	104	0	\N	elearning_async	2026-02-03 16:24:32.792008+01	2026-02-03 16:24:32.792009+01	0	\N	\N
828	15069	773	Mon Accompagnateur Rénov'	146	104	0	\N	elearning_async	2026-02-03 16:24:32.792009+01	2026-02-03 16:24:32.79201+01	0	\N	\N
829	15070	777	Audit énergétique - BCT	153	104	0	\N	elearning_async	2026-02-03 16:24:32.79201+01	2026-02-03 16:24:32.792011+01	0	\N	\N
830	15071	779	Management, Communication, Handicap	152	104	0	\N	elearning_async	2026-02-03 16:24:32.792011+01	2026-02-03 16:24:32.792012+01	0	\N	\N
831	15072	780	Ordonnancement, Pilotage, et Coordination	154	104	0	\N	elearning_async	2026-02-03 16:24:32.792012+01	2026-02-03 16:24:32.792013+01	0	\N	\N
832	15109	1151	Point tutoré - BC01 02	118	104	0	\N	elearning_async	2026-02-03 16:24:32.792013+01	2026-02-03 16:24:32.792014+01	0	\N	\N
833	18052	1898	MAR (C&M) - Module 1 : Les prérequis	147	104	0	\N	elearning_async	2026-02-03 16:24:32.792014+01	2026-02-03 16:24:32.792015+01	0	\N	\N
834	18085	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	104	0	\N	elearning_async	2026-02-03 16:24:32.792015+01	2026-02-03 16:24:32.792016+01	0	\N	\N
835	18118	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	104	0	\N	elearning_async	2026-02-03 16:24:32.792016+01	2026-02-03 16:24:32.792017+01	0	\N	\N
836	18151	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	104	0	\N	elearning_async	2026-02-03 16:24:32.792017+01	2026-02-03 16:24:32.792018+01	0	\N	\N
837	18184	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	104	0	\N	elearning_async	2026-02-03 16:24:32.792018+01	2026-02-03 16:24:32.792019+01	0	\N	\N
838	15153	749	Chef de projet en rénovation énergétique - Bienvenue	115	105	100	2025-06-10 22:35:38+02	elearning_async	2026-02-03 16:24:33.278453+01	2026-02-03 16:24:33.278456+01	8238	2025-06-06 17:18:00+02	2025-06-10 12:50:11+02
839	15154	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	105	100	2025-12-08 09:30:37+01	elearning_async	2026-02-03 16:24:33.278457+01	2026-02-03 16:24:33.278457+01	22916	2025-06-09 00:32:44+02	2025-12-08 09:32:25+01
840	15155	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	105	37	2025-11-20 15:53:01+01	elearning_async	2026-02-03 16:24:33.278458+01	2026-02-03 16:24:33.278458+01	11460	2025-11-20 15:53:01+01	\N
841	15156	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	105	0	\N	elearning_async	2026-02-03 16:24:33.278459+01	2026-02-03 16:24:33.27846+01	0	\N	\N
842	15157	756	Eco-conseiller - Module 4 : Aides et subventions	136	105	0	\N	elearning_async	2026-02-03 16:24:33.27846+01	2026-02-03 16:24:33.278461+01	0	\N	\N
843	15158	757	Eco-conseiller - Module 5 : La relation client	137	105	0	\N	elearning_async	2026-02-03 16:24:33.278461+01	2026-02-03 16:24:33.278462+01	0	\N	\N
844	15159	752	Projet tutoré	114	105	100	2025-09-26 11:31:14+02	elearning_async	2026-02-03 16:24:33.278462+01	2026-02-03 16:24:33.278463+01	16702	2025-06-10 22:35:43+02	2025-09-26 11:19:21+02
845	15160	762	[AE] Guide du DPE	140	105	0	\N	elearning_async	2026-02-03 16:24:33.278463+01	2026-02-03 16:24:33.278464+01	0	\N	\N
846	15161	761	DPE - Sans Mention	138	105	100	2025-07-21 18:58:11+02	elearning_async	2026-02-03 16:24:33.278464+01	2026-02-03 16:24:33.278465+01	60654	2025-07-02 11:50:26+02	2025-07-20 01:35:41+02
847	15162	1020	DPE avec mention	116	105	100	2025-11-20 09:22:38+01	elearning_async	2026-02-03 16:24:33.278465+01	2026-02-03 16:24:33.278466+01	33558	2025-06-09 00:47:30+02	2025-11-20 09:22:38+01
848	15163	763	DPE - Avec Mention	139	105	100	2025-11-20 09:10:40+01	elearning_async	2026-02-03 16:24:33.278466+01	2026-02-03 16:24:33.278467+01	33558	2025-06-09 00:47:30+02	2025-11-20 09:22:38+01
849	15164	1151	Point tutoré - BC01 02	118	105	100	2025-06-09 02:43:34+02	elearning_async	2026-02-03 16:24:33.278467+01	2026-02-03 16:24:33.278468+01	11343	2025-06-08 15:16:40+02	2025-11-20 11:41:57+01
850	15179	750	Blocs 1 et 2 - Bienvenue !	117	105	0	\N	elearning_async	2026-02-03 16:24:33.278469+01	2026-02-03 16:24:33.278469+01	0	\N	\N
851	15180	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	105	38	2026-01-24 22:25:08+01	elearning_async	2026-02-03 16:24:33.27847+01	2026-02-03 16:24:33.27847+01	21818	2025-07-31 00:42:17+02	\N
852	15181	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	105	0	\N	elearning_async	2026-02-03 16:24:33.278471+01	2026-02-03 16:24:33.278471+01	0	\N	\N
853	15182	768	[AE MI] Partie 3 : Conception de scénarios	143	105	0	\N	elearning_async	2026-02-03 16:24:33.278472+01	2026-02-03 16:24:33.278472+01	0	\N	\N
854	15183	769	[AE MI] Partie 4 : Le rapport	144	105	0	\N	elearning_async	2026-02-03 16:24:33.278473+01	2026-02-03 16:24:33.278473+01	0	\N	\N
855	15184	770	[AE MI] Cas Pratique	145	105	0	\N	elearning_async	2026-02-03 16:24:33.278474+01	2026-02-03 16:24:33.278474+01	0	\N	\N
856	15185	773	Mon Accompagnateur Rénov'	146	105	0	\N	elearning_async	2026-02-03 16:24:33.278475+01	2026-02-03 16:24:33.278475+01	0	\N	\N
857	15186	777	Audit énergétique - BCT	153	105	0	\N	elearning_async	2026-02-03 16:24:33.278476+01	2026-02-03 16:24:33.278476+01	0	\N	\N
858	15187	779	Management, Communication, Handicap	152	105	0	\N	elearning_async	2026-02-03 16:24:33.278477+01	2026-02-03 16:24:33.278477+01	0	\N	\N
859	15188	780	Ordonnancement, Pilotage, et Coordination	154	105	0	\N	elearning_async	2026-02-03 16:24:33.278478+01	2026-02-03 16:24:33.278478+01	0	\N	\N
860	18053	1898	MAR (C&M) - Module 1 : Les prérequis	147	105	0	\N	elearning_async	2026-02-03 16:24:33.278479+01	2026-02-03 16:24:33.278479+01	0	\N	\N
861	18086	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	105	0	\N	elearning_async	2026-02-03 16:24:33.27848+01	2026-02-03 16:24:33.27848+01	0	\N	\N
862	18119	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	105	0	\N	elearning_async	2026-02-03 16:24:33.278481+01	2026-02-03 16:24:33.278481+01	0	\N	\N
863	18152	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	105	0	\N	elearning_async	2026-02-03 16:24:33.278482+01	2026-02-03 16:24:33.278482+01	0	\N	\N
864	18185	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	105	0	\N	elearning_async	2026-02-03 16:24:33.278483+01	2026-02-03 16:24:33.278483+01	0	\N	\N
865	15222	749	Chef de projet en rénovation énergétique - Bienvenue	115	106	100	2025-06-09 09:12:44+02	elearning_async	2026-02-03 16:24:33.732782+01	2026-02-03 16:24:33.732786+01	11458	2025-06-06 12:48:03+02	2025-06-09 10:06:21+02
187	27033	2858	[AE MI] Partie 3 : Conception de scénarios	81	64	0	\N	elearning_async	2026-02-03 16:24:16.06846+01	2026-02-03 16:24:33.432741+01	0	\N	\N
188	27036	2859	[AE MI] Partie 4 : Le rapport	82	64	0	\N	elearning_async	2026-02-03 16:24:16.068465+01	2026-02-03 16:24:33.432741+01	0	\N	\N
192	27034	2858	[AE MI] Partie 3 : Conception de scénarios	81	65	0	\N	elearning_async	2026-02-03 16:24:16.288893+01	2026-02-03 16:24:33.672361+01	0	\N	\N
193	27037	2859	[AE MI] Partie 4 : Le rapport	82	65	0	\N	elearning_async	2026-02-03 16:24:16.288897+01	2026-02-03 16:24:33.672361+01	0	\N	\N
197	14319	1015	[TP SAMS] - Module 4 : Dossier Professionnel pour la Certification	101	66	100	2025-08-21 21:45:16+02	elearning_async	2026-02-03 16:24:16.780413+01	2026-02-03 16:24:34.124712+01	120	2025-08-21 21:43:03+02	2025-08-21 21:43:55+02
198	14321	1016	[TP SAMS] - Module 5 : Transversal	102	66	100	2025-10-28 22:10:03+01	elearning_async	2026-02-03 16:24:16.780415+01	2026-02-03 16:24:34.124712+01	49810	2025-08-21 21:46:07+02	2025-09-03 22:56:29+02
199	14323	1017	[TP SAMS] - Module 6 : Evaluations	103	66	100	2025-09-12 21:24:04+02	elearning_async	2026-02-03 16:24:16.780416+01	2026-02-03 16:24:34.124712+01	22636	2025-09-03 22:58:13+02	2025-09-12 21:20:08+02
224	3270	752	Projet tutoré	114	83	100	2025-06-17 11:13:07+02	elearning_async	2026-02-03 16:24:22.430612+01	2026-02-03 16:24:39.457948+01	32702	2025-06-06 11:06:37+02	2025-06-17 11:13:37+02
225	3271	762	[AE] Guide du DPE	140	83	100	2025-08-13 18:53:33+02	elearning_async	2026-02-03 16:24:22.430613+01	2026-02-03 16:24:39.457948+01	86838	2025-06-30 21:32:32+02	2025-08-13 19:11:54+02
226	3272	761	DPE - Sans Mention	138	83	100	2025-07-17 10:58:38+02	elearning_async	2026-02-03 16:24:22.430614+01	2026-02-03 16:24:39.457948+01	52638	2025-07-10 18:30:58+02	2025-07-17 10:24:07+02
227	3273	763	DPE - Avec Mention	139	83	100	2025-09-03 17:15:30+02	elearning_async	2026-02-03 16:24:22.430615+01	2026-02-03 16:24:39.457948+01	43482	2025-07-17 10:58:38+02	2025-09-03 18:03:56+02
228	3274	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	83	0	\N	elearning_async	2026-02-03 16:24:22.430617+01	2026-02-03 16:24:39.457948+01	0	\N	\N
229	3275	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	83	0	\N	elearning_async	2026-02-03 16:24:22.430618+01	2026-02-03 16:24:39.457948+01	0	\N	\N
230	3276	768	[AE MI] Partie 3 : Conception de scénarios	143	83	0	\N	elearning_async	2026-02-03 16:24:22.430619+01	2026-02-03 16:24:39.457948+01	0	\N	\N
231	3277	769	[AE MI] Partie 4 : Le rapport	144	83	0	\N	elearning_async	2026-02-03 16:24:22.43062+01	2026-02-03 16:24:39.457948+01	0	\N	\N
232	3278	770	[AE MI] Cas Pratique	145	83	0	\N	elearning_async	2026-02-03 16:24:22.430621+01	2026-02-03 16:24:39.457948+01	0	\N	\N
233	3279	773	Mon Accompagnateur Rénov'	146	83	0	\N	elearning_async	2026-02-03 16:24:22.430622+01	2026-02-03 16:24:39.457948+01	0	\N	\N
234	3280	777	Audit énergétique - BCT	153	83	0	\N	elearning_async	2026-02-03 16:24:22.430624+01	2026-02-03 16:24:39.457948+01	0	\N	\N
235	3281	779	Management, Communication, Handicap	152	83	0	\N	elearning_async	2026-02-03 16:24:22.430625+01	2026-02-03 16:24:39.457948+01	0	\N	\N
236	3282	780	Ordonnancement, Pilotage, et Coordination	154	83	0	\N	elearning_async	2026-02-03 16:24:22.430626+01	2026-02-03 16:24:39.457948+01	0	\N	\N
237	14327	1020	DPE avec mention	116	83	100	2025-09-03 18:04:01+02	elearning_async	2026-02-03 16:24:22.430627+01	2026-02-03 16:24:39.457948+01	43482	2025-07-17 10:58:38+02	2025-09-03 18:03:56+02
238	15085	1151	Point tutoré - BC01 02	118	83	0	\N	elearning_async	2026-02-03 16:24:22.430628+01	2026-02-03 16:24:39.457948+01	0	\N	\N
239	18029	1898	MAR (C&M) - Module 1 : Les prérequis	147	83	0	\N	elearning_async	2026-02-03 16:24:22.430629+01	2026-02-03 16:24:39.457948+01	0	\N	\N
240	18062	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	83	0	\N	elearning_async	2026-02-03 16:24:22.430631+01	2026-02-03 16:24:39.457948+01	0	\N	\N
241	18095	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	83	0	\N	elearning_async	2026-02-03 16:24:22.430632+01	2026-02-03 16:24:39.457948+01	0	\N	\N
242	18128	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	83	0	\N	elearning_async	2026-02-03 16:24:22.430633+01	2026-02-03 16:24:39.457948+01	0	\N	\N
243	18161	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	83	0	\N	elearning_async	2026-02-03 16:24:22.430634+01	2026-02-03 16:24:39.457948+01	0	\N	\N
252	3312	761	DPE - Sans Mention	138	84	0	\N	elearning_async	2026-02-03 16:24:22.945957+01	2026-02-03 16:24:39.953101+01	0	\N	\N
253	3313	763	DPE - Avec Mention	139	84	0	\N	elearning_async	2026-02-03 16:24:22.945958+01	2026-02-03 16:24:39.953101+01	0	\N	\N
254	3328	750	Blocs 1 et 2 - Bienvenue !	117	84	0	\N	elearning_async	2026-02-03 16:24:22.945959+01	2026-02-03 16:24:39.953101+01	0	\N	\N
255	3329	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	84	0	\N	elearning_async	2026-02-03 16:24:22.94596+01	2026-02-03 16:24:39.953101+01	0	\N	\N
256	3330	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	84	0	\N	elearning_async	2026-02-03 16:24:22.945961+01	2026-02-03 16:24:39.953101+01	0	\N	\N
257	3331	768	[AE MI] Partie 3 : Conception de scénarios	143	84	0	\N	elearning_async	2026-02-03 16:24:22.945963+01	2026-02-03 16:24:39.953101+01	0	\N	\N
258	3332	769	[AE MI] Partie 4 : Le rapport	144	84	0	\N	elearning_async	2026-02-03 16:24:22.945964+01	2026-02-03 16:24:39.953101+01	0	\N	\N
259	3333	770	[AE MI] Cas Pratique	145	84	0	\N	elearning_async	2026-02-03 16:24:22.945965+01	2026-02-03 16:24:39.953101+01	0	\N	\N
260	3334	773	Mon Accompagnateur Rénov'	146	84	0	\N	elearning_async	2026-02-03 16:24:22.945966+01	2026-02-03 16:24:39.953101+01	0	\N	\N
261	3335	777	Audit énergétique - BCT	153	84	0	\N	elearning_async	2026-02-03 16:24:22.945967+01	2026-02-03 16:24:39.953101+01	0	\N	\N
262	3336	779	Management, Communication, Handicap	152	84	0	\N	elearning_async	2026-02-03 16:24:22.945968+01	2026-02-03 16:24:39.953101+01	0	\N	\N
263	3337	780	Ordonnancement, Pilotage, et Coordination	154	84	0	\N	elearning_async	2026-02-03 16:24:22.945969+01	2026-02-03 16:24:39.953101+01	0	\N	\N
264	14328	1020	DPE avec mention	116	84	0	\N	elearning_async	2026-02-03 16:24:22.94597+01	2026-02-03 16:24:39.953101+01	0	\N	\N
265	15086	1151	Point tutoré - BC01 02	118	84	0	\N	elearning_async	2026-02-03 16:24:22.945971+01	2026-02-03 16:24:39.953101+01	0	\N	\N
266	18030	1898	MAR (C&M) - Module 1 : Les prérequis	147	84	0	\N	elearning_async	2026-02-03 16:24:22.945972+01	2026-02-03 16:24:39.953101+01	0	\N	\N
267	18063	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	84	0	\N	elearning_async	2026-02-03 16:24:22.945973+01	2026-02-03 16:24:39.953101+01	0	\N	\N
268	18096	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	84	0	\N	elearning_async	2026-02-03 16:24:22.945974+01	2026-02-03 16:24:39.953101+01	0	\N	\N
269	18129	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	84	0	\N	elearning_async	2026-02-03 16:24:22.945975+01	2026-02-03 16:24:39.953101+01	0	\N	\N
270	18162	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	84	0	\N	elearning_async	2026-02-03 16:24:22.945976+01	2026-02-03 16:24:39.953101+01	0	\N	\N
289	3370	779	Management, Communication, Handicap	152	85	0	\N	elearning_async	2026-02-03 16:24:23.428981+01	2026-02-03 16:24:40.482223+01	0	\N	\N
290	3371	780	Ordonnancement, Pilotage, et Coordination	154	85	0	\N	elearning_async	2026-02-03 16:24:23.428982+01	2026-02-03 16:24:40.482223+01	0	\N	\N
291	14329	1020	DPE avec mention	116	85	15	2025-09-16 10:55:14+02	elearning_async	2026-02-03 16:24:23.428983+01	2026-02-03 16:24:40.482223+01	102	2025-09-16 10:52:54+02	\N
292	15087	1151	Point tutoré - BC01 02	118	85	0	\N	elearning_async	2026-02-03 16:24:23.428984+01	2026-02-03 16:24:40.482223+01	0	\N	\N
293	18031	1898	MAR (C&M) - Module 1 : Les prérequis	147	85	0	\N	elearning_async	2026-02-03 16:24:23.428985+01	2026-02-03 16:24:40.482223+01	0	\N	\N
294	18064	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	85	0	\N	elearning_async	2026-02-03 16:24:23.428986+01	2026-02-03 16:24:40.482223+01	0	\N	\N
295	18097	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	85	0	\N	elearning_async	2026-02-03 16:24:23.428987+01	2026-02-03 16:24:40.482223+01	0	\N	\N
296	18130	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	85	0	\N	elearning_async	2026-02-03 16:24:23.428989+01	2026-02-03 16:24:40.482223+01	0	\N	\N
866	15223	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	106	100	2025-06-25 22:42:56+02	elearning_async	2026-02-03 16:24:33.732787+01	2026-02-03 16:24:33.732787+01	42498	2025-06-09 10:16:53+02	2025-06-24 22:00:10+02
867	15224	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	106	100	2025-08-09 10:04:54+02	elearning_async	2026-02-03 16:24:33.732788+01	2026-02-03 16:24:33.732788+01	56394	2025-06-25 22:43:49+02	2025-08-09 10:35:52+02
868	15225	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	106	100	2025-08-26 08:29:19+02	elearning_async	2026-02-03 16:24:33.732789+01	2026-02-03 16:24:33.732789+01	3430	2025-08-09 16:08:26+02	2025-08-09 17:02:18+02
869	15226	756	Eco-conseiller - Module 4 : Aides et subventions	136	106	100	2025-08-14 07:51:48+02	elearning_async	2026-02-03 16:24:33.73279+01	2026-02-03 16:24:33.73279+01	5682	2025-08-09 17:07:58+02	2025-08-13 14:19:03+02
870	15227	757	Eco-conseiller - Module 5 : La relation client	137	106	100	2025-08-18 10:40:05+02	elearning_async	2026-02-03 16:24:33.732791+01	2026-02-03 16:24:33.732791+01	2600	2025-08-13 15:00:58+02	2025-08-14 07:51:49+02
871	15228	752	Projet tutoré	114	106	100	2025-10-07 07:08:02+02	elearning_async	2026-02-03 16:24:33.732792+01	2026-02-03 16:24:33.732792+01	20268	2025-06-12 16:26:32+02	2025-10-07 07:15:33+02
872	15229	762	[AE] Guide du DPE	140	106	100	2025-09-11 19:51:43+02	elearning_async	2026-02-03 16:24:33.732793+01	2026-02-03 16:24:33.732793+01	91468	2025-07-03 14:25:14+02	2025-09-11 19:02:25+02
873	15230	761	DPE - Sans Mention	138	106	100	2025-10-12 23:39:54+02	elearning_async	2026-02-03 16:24:33.732794+01	2026-02-03 16:24:33.732794+01	91006	2025-07-14 13:11:01+02	2025-07-20 18:02:05+02
874	15231	1020	DPE avec mention	116	106	100	2025-09-13 21:55:17+02	elearning_async	2026-02-03 16:24:33.732795+01	2026-02-03 16:24:33.732795+01	34452	2025-07-16 20:28:21+02	2025-08-21 16:33:09+02
875	15232	763	DPE - Avec Mention	139	106	100	2025-08-21 16:19:17+02	elearning_async	2026-02-03 16:24:33.732796+01	2026-02-03 16:24:33.732796+01	34452	2025-07-16 20:28:21+02	2025-08-21 16:33:09+02
876	15233	1151	Point tutoré - BC01 02	118	106	0	\N	elearning_async	2026-02-03 16:24:33.732797+01	2026-02-03 16:24:33.732798+01	0	\N	\N
877	15248	750	Blocs 1 et 2 - Bienvenue !	117	106	0	\N	elearning_async	2026-02-03 16:24:33.732798+01	2026-02-03 16:24:33.732799+01	0	\N	\N
878	15249	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	106	100	2025-08-12 10:42:04+02	elearning_async	2026-02-03 16:24:33.732799+01	2026-02-03 16:24:33.7328+01	17276	2025-08-06 07:49:29+02	2025-08-08 10:02:45+02
879	15250	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	106	100	2025-08-22 14:25:28+02	elearning_async	2026-02-03 16:24:33.7328+01	2026-02-03 16:24:33.732801+01	2966	2025-08-21 16:57:01+02	2025-08-22 14:10:30+02
880	15251	768	[AE MI] Partie 3 : Conception de scénarios	143	106	100	2025-08-27 07:09:35+02	elearning_async	2026-02-03 16:24:33.732801+01	2026-02-03 16:24:33.732802+01	11148	2025-08-22 14:25:37+02	2025-08-26 08:15:35+02
881	15252	769	[AE MI] Partie 4 : Le rapport	144	106	100	2025-08-27 07:46:25+02	elearning_async	2026-02-03 16:24:33.732802+01	2026-02-03 16:24:33.732803+01	2694	2025-08-27 07:09:36+02	2025-08-27 07:55:23+02
882	15253	770	[AE MI] Cas Pratique	145	106	0	\N	elearning_async	2026-02-03 16:24:33.732803+01	2026-02-03 16:24:33.732804+01	0	\N	\N
883	15254	773	Mon Accompagnateur Rénov'	146	106	0	\N	elearning_async	2026-02-03 16:24:33.732804+01	2026-02-03 16:24:33.732805+01	0	\N	\N
884	15255	777	Audit énergétique - BCT	153	106	100	2025-10-09 07:01:56+02	elearning_async	2026-02-03 16:24:33.732805+01	2026-02-03 16:24:33.732806+01	26250	2025-09-15 20:15:18+02	2025-10-09 07:13:40+02
885	15256	779	Management, Communication, Handicap	152	106	3	2025-10-30 06:41:09+01	elearning_async	2026-02-03 16:24:33.732806+01	2026-02-03 16:24:33.732807+01	360	2025-10-30 06:41:09+01	\N
886	15257	780	Ordonnancement, Pilotage, et Coordination	154	106	62	2025-11-26 14:56:36+01	elearning_async	2026-02-03 16:24:33.732807+01	2026-02-03 16:24:33.732808+01	16230	2025-10-30 06:39:49+01	\N
887	18054	1898	MAR (C&M) - Module 1 : Les prérequis	147	106	100	2025-10-07 06:45:12+02	elearning_async	2026-02-03 16:24:33.732808+01	2026-02-03 16:24:33.732809+01	36188	2025-08-28 07:40:19+02	2025-10-07 07:04:34+02
888	18087	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	106	16	2025-11-12 00:17:39+01	elearning_async	2026-02-03 16:24:33.732809+01	2026-02-03 16:24:33.73281+01	17002	2025-10-10 08:00:41+02	\N
889	18120	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	106	100	2025-10-23 07:05:36+02	elearning_async	2026-02-03 16:24:33.73281+01	2026-02-03 16:24:33.732811+01	2392	2025-10-12 23:44:23+02	2025-10-18 06:21:53+02
890	18153	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	106	50	2025-11-09 21:34:07+01	elearning_async	2026-02-03 16:24:33.732811+01	2026-02-03 16:24:33.732812+01	158	2025-11-09 21:34:05+01	\N
891	18186	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	106	0	\N	elearning_async	2026-02-03 16:24:33.732812+01	2026-02-03 16:24:33.732813+01	0	\N	\N
892	15684	749	Chef de projet en rénovation énergétique - Bienvenue	115	107	100	2025-10-17 14:30:27+02	elearning_async	2026-02-03 16:24:34.197393+01	2026-02-03 16:24:34.197397+01	28206	2025-06-07 22:31:59+02	2025-06-10 16:12:02+02
893	15685	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	107	100	2025-10-23 20:10:40+02	elearning_async	2026-02-03 16:24:34.197398+01	2026-02-03 16:24:34.197399+01	45609	2025-06-13 12:09:57+02	2025-10-23 00:29:32+02
894	15686	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	107	3	2025-08-22 16:28:06+02	elearning_async	2026-02-03 16:24:34.1974+01	2026-02-03 16:24:34.1974+01	7800	2025-08-22 16:28:06+02	\N
895	15687	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	107	100	2025-10-07 15:19:29+02	elearning_async	2026-02-03 16:24:34.197401+01	2026-02-03 16:24:34.197402+01	5256	2025-10-06 12:50:36+02	2025-10-07 15:25:34+02
896	15688	756	Eco-conseiller - Module 4 : Aides et subventions	136	107	0	\N	elearning_async	2026-02-03 16:24:34.197402+01	2026-02-03 16:24:34.197403+01	0	\N	\N
897	15689	757	Eco-conseiller - Module 5 : La relation client	137	107	0	\N	elearning_async	2026-02-03 16:24:34.197404+01	2026-02-03 16:24:34.197405+01	0	\N	\N
898	15690	752	Projet tutoré	114	107	15	2025-10-02 16:53:47+02	elearning_async	2026-02-03 16:24:34.197405+01	2026-02-03 16:24:34.197406+01	86340	2025-06-10 23:33:34+02	\N
899	15691	762	[AE] Guide du DPE	140	107	97	2025-10-24 00:14:20+02	elearning_async	2026-02-03 16:24:34.197407+01	2026-02-03 16:24:34.197408+01	153602	2025-06-27 09:35:47+02	\N
900	15692	761	DPE - Sans Mention	138	107	70	2025-10-27 14:05:33+01	elearning_async	2026-02-03 16:24:34.197408+01	2026-02-03 16:24:34.197409+01	186836	2025-07-14 00:14:59+02	\N
901	15693	1020	DPE avec mention	116	107	5	2025-10-24 04:49:51+02	elearning_async	2026-02-03 16:24:34.19741+01	2026-02-03 16:24:34.197411+01	1584	2025-10-24 00:34:45+02	\N
902	15694	763	DPE - Avec Mention	139	107	5	2025-10-24 04:49:35+02	elearning_async	2026-02-03 16:24:34.197411+01	2026-02-03 16:24:34.197412+01	1584	2025-10-24 00:34:45+02	\N
903	15695	1151	Point tutoré - BC01 02	118	107	0	\N	elearning_async	2026-02-03 16:24:34.197413+01	2026-02-03 16:24:34.197414+01	0	\N	\N
904	15710	750	Blocs 1 et 2 - Bienvenue !	117	107	100	2025-06-07 23:19:03+02	elearning_async	2026-02-03 16:24:34.197415+01	2026-02-03 16:24:34.197415+01	1912	2025-06-07 22:35:04+02	2025-06-07 23:21:13+02
905	15711	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	107	0	\N	elearning_async	2026-02-03 16:24:34.197416+01	2026-02-03 16:24:34.197417+01	0	\N	\N
906	15712	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	107	0	\N	elearning_async	2026-02-03 16:24:34.197417+01	2026-02-03 16:24:34.197418+01	0	\N	\N
907	15713	768	[AE MI] Partie 3 : Conception de scénarios	143	107	0	\N	elearning_async	2026-02-03 16:24:34.197419+01	2026-02-03 16:24:34.19742+01	0	\N	\N
908	15714	769	[AE MI] Partie 4 : Le rapport	144	107	0	\N	elearning_async	2026-02-03 16:24:34.19742+01	2026-02-03 16:24:34.197421+01	0	\N	\N
909	15715	770	[AE MI] Cas Pratique	145	107	0	\N	elearning_async	2026-02-03 16:24:34.197422+01	2026-02-03 16:24:34.197423+01	0	\N	\N
910	15716	773	Mon Accompagnateur Rénov'	146	107	0	\N	elearning_async	2026-02-03 16:24:34.197423+01	2026-02-03 16:24:34.197424+01	0	\N	\N
911	15717	777	Audit énergétique - BCT	153	107	0	\N	elearning_async	2026-02-03 16:24:34.197425+01	2026-02-03 16:24:34.197425+01	0	\N	\N
912	15718	779	Management, Communication, Handicap	152	107	0	\N	elearning_async	2026-02-03 16:24:34.197426+01	2026-02-03 16:24:34.197427+01	0	\N	\N
913	15719	780	Ordonnancement, Pilotage, et Coordination	154	107	0	\N	elearning_async	2026-02-03 16:24:34.197428+01	2026-02-03 16:24:34.197428+01	0	\N	\N
914	18055	1898	MAR (C&M) - Module 1 : Les prérequis	147	107	60	2025-09-29 16:17:44+02	elearning_async	2026-02-03 16:24:34.197429+01	2026-02-03 16:24:34.19743+01	13806	2025-09-14 16:34:29+02	\N
915	18088	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	107	0	\N	elearning_async	2026-02-03 16:24:34.197431+01	2026-02-03 16:24:34.197431+01	0	\N	\N
916	18121	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	107	0	\N	elearning_async	2026-02-03 16:24:34.197432+01	2026-02-03 16:24:34.197433+01	0	\N	\N
917	18154	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	107	0	\N	elearning_async	2026-02-03 16:24:34.197433+01	2026-02-03 16:24:34.197434+01	0	\N	\N
918	18187	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	107	0	\N	elearning_async	2026-02-03 16:24:34.197435+01	2026-02-03 16:24:34.197436+01	0	\N	\N
919	15738	749	Chef de projet en rénovation énergétique - Bienvenue	115	108	100	2025-06-10 11:28:06+02	elearning_async	2026-02-03 16:24:34.639264+01	2026-02-03 16:24:34.639268+01	11296	2025-06-10 08:09:05+02	2025-06-10 11:27:24+02
920	15739	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	108	100	2025-06-15 11:09:59+02	elearning_async	2026-02-03 16:24:34.639269+01	2026-02-03 16:24:34.639269+01	18644	2025-06-13 08:42:08+02	2025-06-15 12:01:49+02
921	15740	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	108	100	2025-06-18 11:20:16+02	elearning_async	2026-02-03 16:24:34.63927+01	2026-02-03 16:24:34.63927+01	58628	2025-06-15 12:07:43+02	2025-06-18 14:59:08+02
922	15741	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	108	100	2025-06-19 10:02:20+02	elearning_async	2026-02-03 16:24:34.639271+01	2026-02-03 16:24:34.639271+01	3114	2025-06-18 15:01:05+02	2025-06-19 09:18:45+02
923	15742	756	Eco-conseiller - Module 4 : Aides et subventions	136	108	100	2025-06-20 11:15:53+02	elearning_async	2026-02-03 16:24:34.639272+01	2026-02-03 16:24:34.639272+01	18462	2025-06-19 12:18:55+02	2025-06-20 11:00:20+02
924	15743	757	Eco-conseiller - Module 5 : La relation client	137	108	100	2025-06-20 11:16:00+02	elearning_async	2026-02-03 16:24:34.639273+01	2026-02-03 16:24:34.639274+01	258	2025-06-20 11:15:56+02	2025-06-20 11:19:58+02
925	15744	752	Projet tutoré	114	108	100	2025-06-12 16:16:25+02	elearning_async	2026-02-03 16:24:34.639274+01	2026-02-03 16:24:34.639275+01	24740	2025-06-12 08:23:02+02	2025-06-12 16:22:12+02
926	15745	762	[AE] Guide du DPE	140	108	99	2025-07-11 15:38:01+02	elearning_async	2026-02-03 16:24:34.639275+01	2026-02-03 16:24:34.639276+01	95214	2025-06-30 15:32:22+02	2025-07-11 15:48:57+02
927	15746	761	DPE - Sans Mention	138	108	100	2026-01-15 09:55:09+01	elearning_async	2026-02-03 16:24:34.639276+01	2026-02-03 16:24:34.639277+01	86450	2025-06-20 11:22:37+02	2025-07-19 13:58:13+02
928	15747	1020	DPE avec mention	116	108	100	2025-09-01 12:03:32+02	elearning_async	2026-02-03 16:24:34.639277+01	2026-02-03 16:24:34.639278+01	57024	2025-07-28 11:05:07+02	2025-09-01 12:03:29+02
929	15748	763	DPE - Avec Mention	139	108	100	2025-09-01 11:51:26+02	elearning_async	2026-02-03 16:24:34.639279+01	2026-02-03 16:24:34.639279+01	57024	2025-07-28 11:05:07+02	2025-09-01 12:03:29+02
930	15749	1151	Point tutoré - BC01 02	118	108	0	\N	elearning_async	2026-02-03 16:24:34.63928+01	2026-02-03 16:24:34.63928+01	0	\N	\N
931	15764	750	Blocs 1 et 2 - Bienvenue !	117	108	0	\N	elearning_async	2026-02-03 16:24:34.639281+01	2026-02-03 16:24:34.639281+01	0	\N	\N
932	15765	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	108	100	2025-09-09 08:18:27+02	elearning_async	2026-02-03 16:24:34.639282+01	2026-02-03 16:24:34.639283+01	11738	2025-08-06 11:53:52+02	2025-09-08 08:47:40+02
933	15766	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	108	100	2025-09-09 08:21:42+02	elearning_async	2026-02-03 16:24:34.639283+01	2026-02-03 16:24:34.639284+01	2268	2025-09-08 08:49:00+02	2025-09-09 08:31:33+02
934	15767	768	[AE MI] Partie 3 : Conception de scénarios	143	108	100	2025-09-24 10:48:54+02	elearning_async	2026-02-03 16:24:34.639284+01	2026-02-03 16:24:34.639285+01	6298	2025-09-09 08:32:20+02	2025-09-24 10:51:41+02
935	15768	769	[AE MI] Partie 4 : Le rapport	144	108	100	2025-10-08 15:27:43+02	elearning_async	2026-02-03 16:24:34.639285+01	2026-02-03 16:24:34.639286+01	1562	2025-10-07 16:46:33+02	2025-10-08 15:32:49+02
936	15769	770	[AE MI] Cas Pratique	145	108	100	2025-10-22 15:47:05+02	elearning_async	2026-02-03 16:24:34.639286+01	2026-02-03 16:24:34.639287+01	2910	2025-10-08 15:33:37+02	2025-10-22 15:52:55+02
937	15770	773	Mon Accompagnateur Rénov'	146	108	0	\N	elearning_async	2026-02-03 16:24:34.639287+01	2026-02-03 16:24:34.639288+01	0	\N	\N
938	15771	777	Audit énergétique - BCT	153	108	0	\N	elearning_async	2026-02-03 16:24:34.639289+01	2026-02-03 16:24:34.639289+01	0	\N	\N
939	15772	779	Management, Communication, Handicap	152	108	10	2026-02-03 16:24:28+01	elearning_async	2026-02-03 16:24:34.63929+01	2026-02-03 16:24:34.63929+01	4438	2026-02-03 10:09:37+01	\N
940	15773	780	Ordonnancement, Pilotage, et Coordination	154	108	0	\N	elearning_async	2026-02-03 16:24:34.639291+01	2026-02-03 16:24:34.639291+01	0	\N	\N
941	18056	1898	MAR (C&M) - Module 1 : Les prérequis	147	108	100	2026-01-08 15:48:46+01	elearning_async	2026-02-03 16:24:34.639292+01	2026-02-03 16:24:34.639292+01	35792	2025-10-22 15:54:11+02	2026-01-08 16:26:48+01
942	18089	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	108	0	\N	elearning_async	2026-02-03 16:24:34.639293+01	2026-02-03 16:24:34.639293+01	0	\N	\N
943	18122	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	108	0	\N	elearning_async	2026-02-03 16:24:34.639294+01	2026-02-03 16:24:34.639294+01	0	\N	\N
944	18155	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	108	0	\N	elearning_async	2026-02-03 16:24:34.639295+01	2026-02-03 16:24:34.639296+01	0	\N	\N
945	18188	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	108	0	\N	elearning_async	2026-02-03 16:24:34.639296+01	2026-02-03 16:24:34.639297+01	0	\N	\N
946	15811	749	Chef de projet en rénovation énergétique - Bienvenue	115	109	0	\N	elearning_async	2026-02-03 16:24:35.163635+01	2026-02-03 16:24:35.163638+01	0	\N	\N
947	15812	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	109	8	2025-06-12 02:54:41+02	elearning_async	2026-02-03 16:24:35.16364+01	2026-02-03 16:24:35.16364+01	7	2025-06-12 02:54:41+02	\N
948	15813	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	109	0	\N	elearning_async	2026-02-03 16:24:35.163641+01	2026-02-03 16:24:35.163641+01	0	\N	\N
949	15814	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	109	0	\N	elearning_async	2026-02-03 16:24:35.163642+01	2026-02-03 16:24:35.163643+01	0	\N	\N
950	15815	756	Eco-conseiller - Module 4 : Aides et subventions	136	109	0	\N	elearning_async	2026-02-03 16:24:35.163643+01	2026-02-03 16:24:35.163644+01	0	\N	\N
951	15816	757	Eco-conseiller - Module 5 : La relation client	137	109	0	\N	elearning_async	2026-02-03 16:24:35.163644+01	2026-02-03 16:24:35.163645+01	0	\N	\N
952	15817	752	Projet tutoré	114	109	8	2025-07-02 02:08:53+02	elearning_async	2026-02-03 16:24:35.163646+01	2026-02-03 16:24:35.163647+01	420	2025-07-02 02:08:53+02	\N
953	15818	762	[AE] Guide du DPE	140	109	0	\N	elearning_async	2026-02-03 16:24:35.163647+01	2026-02-03 16:24:35.163648+01	0	\N	\N
954	15819	761	DPE - Sans Mention	138	109	0	\N	elearning_async	2026-02-03 16:24:35.163648+01	2026-02-03 16:24:35.163649+01	0	\N	\N
955	15820	1020	DPE avec mention	116	109	0	\N	elearning_async	2026-02-03 16:24:35.16365+01	2026-02-03 16:24:35.16365+01	0	\N	\N
956	15821	763	DPE - Avec Mention	139	109	0	\N	elearning_async	2026-02-03 16:24:35.163651+01	2026-02-03 16:24:35.163652+01	0	\N	\N
957	15822	1151	Point tutoré - BC01 02	118	109	0	\N	elearning_async	2026-02-03 16:24:35.163652+01	2026-02-03 16:24:35.163653+01	0	\N	\N
958	15837	750	Blocs 1 et 2 - Bienvenue !	117	109	0	\N	elearning_async	2026-02-03 16:24:35.163654+01	2026-02-03 16:24:35.163654+01	0	\N	\N
959	15838	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	109	0	\N	elearning_async	2026-02-03 16:24:35.163655+01	2026-02-03 16:24:35.163655+01	0	\N	\N
960	15839	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	109	0	\N	elearning_async	2026-02-03 16:24:35.163656+01	2026-02-03 16:24:35.163657+01	0	\N	\N
961	15840	768	[AE MI] Partie 3 : Conception de scénarios	143	109	0	\N	elearning_async	2026-02-03 16:24:35.163657+01	2026-02-03 16:24:35.163658+01	0	\N	\N
962	15841	769	[AE MI] Partie 4 : Le rapport	144	109	0	\N	elearning_async	2026-02-03 16:24:35.163659+01	2026-02-03 16:24:35.163659+01	0	\N	\N
963	15842	770	[AE MI] Cas Pratique	145	109	0	\N	elearning_async	2026-02-03 16:24:35.16366+01	2026-02-03 16:24:35.16366+01	0	\N	\N
964	15843	773	Mon Accompagnateur Rénov'	146	109	0	\N	elearning_async	2026-02-03 16:24:35.163661+01	2026-02-03 16:24:35.163662+01	0	\N	\N
965	15844	777	Audit énergétique - BCT	153	109	0	\N	elearning_async	2026-02-03 16:24:35.163662+01	2026-02-03 16:24:35.163663+01	0	\N	\N
966	15845	779	Management, Communication, Handicap	152	109	0	\N	elearning_async	2026-02-03 16:24:35.163664+01	2026-02-03 16:24:35.163664+01	0	\N	\N
967	15846	780	Ordonnancement, Pilotage, et Coordination	154	109	0	\N	elearning_async	2026-02-03 16:24:35.163665+01	2026-02-03 16:24:35.163665+01	0	\N	\N
968	18057	1898	MAR (C&M) - Module 1 : Les prérequis	147	109	0	\N	elearning_async	2026-02-03 16:24:35.163666+01	2026-02-03 16:24:35.163667+01	0	\N	\N
969	18090	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	109	0	\N	elearning_async	2026-02-03 16:24:35.163667+01	2026-02-03 16:24:35.163668+01	0	\N	\N
970	18123	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	109	0	\N	elearning_async	2026-02-03 16:24:35.163668+01	2026-02-03 16:24:35.163669+01	0	\N	\N
971	18156	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	109	0	\N	elearning_async	2026-02-03 16:24:35.16367+01	2026-02-03 16:24:35.16367+01	0	\N	\N
972	18189	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	109	0	\N	elearning_async	2026-02-03 16:24:35.163671+01	2026-02-03 16:24:35.163672+01	0	\N	\N
973	15936	749	Chef de projet en rénovation énergétique - Bienvenue	115	110	0	\N	elearning_async	2026-02-03 16:24:35.628664+01	2026-02-03 16:24:35.628667+01	0	\N	\N
974	15937	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	110	100	2025-05-25 14:52:31+02	elearning_async	2026-02-03 16:24:35.628668+01	2026-02-03 16:24:35.628669+01	1628	2025-05-15 02:07:14+02	2025-05-25 14:55:39+02
975	15938	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	110	100	2025-05-25 15:33:46+02	elearning_async	2026-02-03 16:24:35.628669+01	2026-02-03 16:24:35.62867+01	3786	2025-05-25 14:57:30+02	2025-05-25 16:15:09+02
976	15939	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	110	0	\N	elearning_async	2026-02-03 16:24:35.62867+01	2026-02-03 16:24:35.628671+01	0	\N	\N
977	15940	756	Eco-conseiller - Module 4 : Aides et subventions	136	110	11	2025-05-25 16:19:18+02	elearning_async	2026-02-03 16:24:35.628671+01	2026-02-03 16:24:35.628672+01	672	2025-05-25 16:19:18+02	\N
978	15941	757	Eco-conseiller - Module 5 : La relation client	137	110	0	\N	elearning_async	2026-02-03 16:24:35.628673+01	2026-02-03 16:24:35.628673+01	0	\N	\N
979	15942	752	Projet tutoré	114	110	0	\N	elearning_async	2026-02-03 16:24:35.628674+01	2026-02-03 16:24:35.628674+01	0	\N	\N
980	15943	762	[AE] Guide du DPE	140	110	0	\N	elearning_async	2026-02-03 16:24:35.628675+01	2026-02-03 16:24:35.628675+01	0	\N	\N
981	15944	761	DPE - Sans Mention	138	110	4	2025-05-26 13:23:01+02	elearning_async	2026-02-03 16:24:35.628676+01	2026-02-03 16:24:35.628676+01	1760	2025-05-26 12:46:19+02	\N
982	15945	1020	DPE avec mention	116	110	0	\N	elearning_async	2026-02-03 16:24:35.628677+01	2026-02-03 16:24:35.628677+01	0	\N	\N
983	15946	763	DPE - Avec Mention	139	110	0	\N	elearning_async	2026-02-03 16:24:35.628678+01	2026-02-03 16:24:35.628678+01	0	\N	\N
984	15947	750	Blocs 1 et 2 - Bienvenue !	117	110	0	\N	elearning_async	2026-02-03 16:24:35.628679+01	2026-02-03 16:24:35.628679+01	0	\N	\N
985	15948	1151	Point tutoré - BC01 02	118	110	0	\N	elearning_async	2026-02-03 16:24:35.62868+01	2026-02-03 16:24:35.628681+01	0	\N	\N
986	15963	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	110	0	\N	elearning_async	2026-02-03 16:24:35.628681+01	2026-02-03 16:24:35.628682+01	0	\N	\N
987	15964	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	110	0	\N	elearning_async	2026-02-03 16:24:35.628682+01	2026-02-03 16:24:35.628683+01	0	\N	\N
988	15965	768	[AE MI] Partie 3 : Conception de scénarios	143	110	0	\N	elearning_async	2026-02-03 16:24:35.628683+01	2026-02-03 16:24:35.628684+01	0	\N	\N
989	15966	769	[AE MI] Partie 4 : Le rapport	144	110	0	\N	elearning_async	2026-02-03 16:24:35.628685+01	2026-02-03 16:24:35.628685+01	0	\N	\N
990	15967	770	[AE MI] Cas Pratique	145	110	0	\N	elearning_async	2026-02-03 16:24:35.628686+01	2026-02-03 16:24:35.628686+01	0	\N	\N
991	15968	773	Mon Accompagnateur Rénov'	146	110	0	\N	elearning_async	2026-02-03 16:24:35.628687+01	2026-02-03 16:24:35.628687+01	0	\N	\N
992	15969	777	Audit énergétique - BCT	153	110	0	\N	elearning_async	2026-02-03 16:24:35.628688+01	2026-02-03 16:24:35.628688+01	0	\N	\N
993	15970	779	Management, Communication, Handicap	152	110	0	\N	elearning_async	2026-02-03 16:24:35.628689+01	2026-02-03 16:24:35.628689+01	0	\N	\N
994	15971	780	Ordonnancement, Pilotage, et Coordination	154	110	0	\N	elearning_async	2026-02-03 16:24:35.62869+01	2026-02-03 16:24:35.62869+01	0	\N	\N
995	18058	1898	MAR (C&M) - Module 1 : Les prérequis	147	110	0	\N	elearning_async	2026-02-03 16:24:35.628691+01	2026-02-03 16:24:35.628691+01	0	\N	\N
996	18091	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	110	0	\N	elearning_async	2026-02-03 16:24:35.628692+01	2026-02-03 16:24:35.628692+01	0	\N	\N
997	18124	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	110	0	\N	elearning_async	2026-02-03 16:24:35.628693+01	2026-02-03 16:24:35.628694+01	0	\N	\N
998	18157	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	110	0	\N	elearning_async	2026-02-03 16:24:35.628694+01	2026-02-03 16:24:35.628695+01	0	\N	\N
999	18190	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	110	0	\N	elearning_async	2026-02-03 16:24:35.628695+01	2026-02-03 16:24:35.628696+01	0	\N	\N
1000	16118	749	Chef de projet en rénovation énergétique - Bienvenue	115	111	0	\N	elearning_async	2026-02-03 16:24:36.101955+01	2026-02-03 16:24:36.101959+01	0	\N	\N
1001	16119	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	111	0	\N	elearning_async	2026-02-03 16:24:36.10196+01	2026-02-03 16:24:36.10196+01	0	\N	\N
1002	16120	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	111	0	\N	elearning_async	2026-02-03 16:24:36.101961+01	2026-02-03 16:24:36.101962+01	0	\N	\N
1003	16121	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	111	0	\N	elearning_async	2026-02-03 16:24:36.101962+01	2026-02-03 16:24:36.101963+01	0	\N	\N
1004	16122	756	Eco-conseiller - Module 4 : Aides et subventions	136	111	0	\N	elearning_async	2026-02-03 16:24:36.101963+01	2026-02-03 16:24:36.101964+01	0	\N	\N
1005	16123	757	Eco-conseiller - Module 5 : La relation client	137	111	0	\N	elearning_async	2026-02-03 16:24:36.101965+01	2026-02-03 16:24:36.101965+01	0	\N	\N
1006	16124	752	Projet tutoré	114	111	0	\N	elearning_async	2026-02-03 16:24:36.101966+01	2026-02-03 16:24:36.101966+01	0	\N	\N
1007	16125	762	[AE] Guide du DPE	140	111	0	\N	elearning_async	2026-02-03 16:24:36.101967+01	2026-02-03 16:24:36.101968+01	0	\N	\N
1008	16126	761	DPE - Sans Mention	138	111	0	\N	elearning_async	2026-02-03 16:24:36.101968+01	2026-02-03 16:24:36.101969+01	0	\N	\N
1009	16127	1020	DPE avec mention	116	111	0	\N	elearning_async	2026-02-03 16:24:36.10197+01	2026-02-03 16:24:36.10197+01	0	\N	\N
1010	16128	763	DPE - Avec Mention	139	111	0	\N	elearning_async	2026-02-03 16:24:36.101971+01	2026-02-03 16:24:36.101971+01	0	\N	\N
1011	16129	750	Blocs 1 et 2 - Bienvenue !	117	111	0	\N	elearning_async	2026-02-03 16:24:36.101972+01	2026-02-03 16:24:36.101972+01	0	\N	\N
1012	16130	1151	Point tutoré - BC01 02	118	111	0	\N	elearning_async	2026-02-03 16:24:36.101973+01	2026-02-03 16:24:36.101973+01	0	\N	\N
1013	16145	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	111	0	\N	elearning_async	2026-02-03 16:24:36.101974+01	2026-02-03 16:24:36.101975+01	0	\N	\N
1014	16146	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	111	0	\N	elearning_async	2026-02-03 16:24:36.101975+01	2026-02-03 16:24:36.101976+01	0	\N	\N
1015	16147	768	[AE MI] Partie 3 : Conception de scénarios	143	111	0	\N	elearning_async	2026-02-03 16:24:36.101976+01	2026-02-03 16:24:36.101977+01	0	\N	\N
1016	16148	769	[AE MI] Partie 4 : Le rapport	144	111	0	\N	elearning_async	2026-02-03 16:24:36.101978+01	2026-02-03 16:24:36.101978+01	0	\N	\N
1017	16149	770	[AE MI] Cas Pratique	145	111	0	\N	elearning_async	2026-02-03 16:24:36.101979+01	2026-02-03 16:24:36.10198+01	0	\N	\N
1018	16150	773	Mon Accompagnateur Rénov'	146	111	0	\N	elearning_async	2026-02-03 16:24:36.10198+01	2026-02-03 16:24:36.101981+01	0	\N	\N
1019	16151	777	Audit énergétique - BCT	153	111	0	\N	elearning_async	2026-02-03 16:24:36.101981+01	2026-02-03 16:24:36.101982+01	0	\N	\N
1020	16152	779	Management, Communication, Handicap	152	111	0	\N	elearning_async	2026-02-03 16:24:36.101982+01	2026-02-03 16:24:36.101983+01	0	\N	\N
1021	16153	780	Ordonnancement, Pilotage, et Coordination	154	111	0	\N	elearning_async	2026-02-03 16:24:36.101984+01	2026-02-03 16:24:36.101984+01	0	\N	\N
1022	18059	1898	MAR (C&M) - Module 1 : Les prérequis	147	111	0	\N	elearning_async	2026-02-03 16:24:36.101985+01	2026-02-03 16:24:36.101985+01	0	\N	\N
1023	18092	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	111	0	\N	elearning_async	2026-02-03 16:24:36.101986+01	2026-02-03 16:24:36.101986+01	0	\N	\N
1024	18125	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	111	0	\N	elearning_async	2026-02-03 16:24:36.101987+01	2026-02-03 16:24:36.101987+01	0	\N	\N
1025	18158	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	111	0	\N	elearning_async	2026-02-03 16:24:36.101988+01	2026-02-03 16:24:36.101989+01	0	\N	\N
1026	18191	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	111	0	\N	elearning_async	2026-02-03 16:24:36.101989+01	2026-02-03 16:24:36.10199+01	0	\N	\N
1027	17517	752	Projet tutoré	114	112	0	\N	elearning_async	2026-02-03 16:24:36.525344+01	2026-02-03 16:24:36.525347+01	0	\N	\N
1028	17518	749	Chef de projet en rénovation énergétique - Bienvenue	115	112	0	\N	elearning_async	2026-02-03 16:24:36.525348+01	2026-02-03 16:24:36.525349+01	0	\N	\N
1029	17519	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	112	0	\N	elearning_async	2026-02-03 16:24:36.525349+01	2026-02-03 16:24:36.52535+01	0	\N	\N
1030	17520	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	112	0	\N	elearning_async	2026-02-03 16:24:36.52535+01	2026-02-03 16:24:36.525351+01	0	\N	\N
1031	17521	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	112	0	\N	elearning_async	2026-02-03 16:24:36.525352+01	2026-02-03 16:24:36.525352+01	0	\N	\N
1032	17522	756	Eco-conseiller - Module 4 : Aides et subventions	136	112	0	\N	elearning_async	2026-02-03 16:24:36.525353+01	2026-02-03 16:24:36.525353+01	0	\N	\N
1033	17523	757	Eco-conseiller - Module 5 : La relation client	137	112	0	\N	elearning_async	2026-02-03 16:24:36.525354+01	2026-02-03 16:24:36.525354+01	0	\N	\N
1034	17524	762	[AE] Guide du DPE	140	112	0	\N	elearning_async	2026-02-03 16:24:36.525355+01	2026-02-03 16:24:36.525355+01	0	\N	\N
1035	17525	761	DPE - Sans Mention	138	112	0	\N	elearning_async	2026-02-03 16:24:36.525356+01	2026-02-03 16:24:36.525356+01	0	\N	\N
1036	17526	1020	DPE avec mention	116	112	0	\N	elearning_async	2026-02-03 16:24:36.525357+01	2026-02-03 16:24:36.525358+01	0	\N	\N
1037	17527	763	DPE - Avec Mention	139	112	0	\N	elearning_async	2026-02-03 16:24:36.525358+01	2026-02-03 16:24:36.525359+01	0	\N	\N
1038	17528	750	Blocs 1 et 2 - Bienvenue !	117	112	0	\N	elearning_async	2026-02-03 16:24:36.525359+01	2026-02-03 16:24:36.52536+01	0	\N	\N
1039	17529	1151	Point tutoré - BC01 02	118	112	0	\N	elearning_async	2026-02-03 16:24:36.52536+01	2026-02-03 16:24:36.525361+01	0	\N	\N
1040	17544	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	112	0	\N	elearning_async	2026-02-03 16:24:36.525361+01	2026-02-03 16:24:36.525362+01	0	\N	\N
1041	17545	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	112	0	\N	elearning_async	2026-02-03 16:24:36.525362+01	2026-02-03 16:24:36.525363+01	0	\N	\N
1042	17546	768	[AE MI] Partie 3 : Conception de scénarios	143	112	0	\N	elearning_async	2026-02-03 16:24:36.525363+01	2026-02-03 16:24:36.525364+01	0	\N	\N
1043	17547	769	[AE MI] Partie 4 : Le rapport	144	112	0	\N	elearning_async	2026-02-03 16:24:36.525364+01	2026-02-03 16:24:36.525365+01	0	\N	\N
1044	17548	770	[AE MI] Cas Pratique	145	112	0	\N	elearning_async	2026-02-03 16:24:36.525365+01	2026-02-03 16:24:36.525366+01	0	\N	\N
1045	17549	773	Mon Accompagnateur Rénov'	146	112	0	\N	elearning_async	2026-02-03 16:24:36.525367+01	2026-02-03 16:24:36.525367+01	0	\N	\N
1046	17550	777	Audit énergétique - BCT	153	112	0	\N	elearning_async	2026-02-03 16:24:36.525368+01	2026-02-03 16:24:36.525368+01	0	\N	\N
1047	17551	779	Management, Communication, Handicap	152	112	0	\N	elearning_async	2026-02-03 16:24:36.525369+01	2026-02-03 16:24:36.525369+01	0	\N	\N
1048	17552	780	Ordonnancement, Pilotage, et Coordination	154	112	0	\N	elearning_async	2026-02-03 16:24:36.52537+01	2026-02-03 16:24:36.52537+01	0	\N	\N
1049	18060	1898	MAR (C&M) - Module 1 : Les prérequis	147	112	0	\N	elearning_async	2026-02-03 16:24:36.525371+01	2026-02-03 16:24:36.525371+01	0	\N	\N
1050	18093	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	112	0	\N	elearning_async	2026-02-03 16:24:36.525372+01	2026-02-03 16:24:36.525373+01	0	\N	\N
1051	18126	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	112	0	\N	elearning_async	2026-02-03 16:24:36.525373+01	2026-02-03 16:24:36.525374+01	0	\N	\N
1052	18159	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	112	0	\N	elearning_async	2026-02-03 16:24:36.525374+01	2026-02-03 16:24:36.525375+01	0	\N	\N
1053	18192	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	112	0	\N	elearning_async	2026-02-03 16:24:36.525375+01	2026-02-03 16:24:36.525376+01	0	\N	\N
1054	17555	752	Projet tutoré	114	113	0	\N	elearning_async	2026-02-03 16:24:36.989839+01	2026-02-03 16:24:36.989842+01	0	\N	\N
1055	17556	749	Chef de projet en rénovation énergétique - Bienvenue	115	113	0	\N	elearning_async	2026-02-03 16:24:36.989843+01	2026-02-03 16:24:36.989843+01	0	\N	\N
1056	17557	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	113	0	\N	elearning_async	2026-02-03 16:24:36.989844+01	2026-02-03 16:24:36.989845+01	0	\N	\N
1057	17558	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	113	0	\N	elearning_async	2026-02-03 16:24:36.989845+01	2026-02-03 16:24:36.989846+01	0	\N	\N
1058	17559	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	113	0	\N	elearning_async	2026-02-03 16:24:36.989846+01	2026-02-03 16:24:36.989847+01	0	\N	\N
1059	17560	756	Eco-conseiller - Module 4 : Aides et subventions	136	113	0	\N	elearning_async	2026-02-03 16:24:36.989848+01	2026-02-03 16:24:36.989848+01	0	\N	\N
1060	17561	757	Eco-conseiller - Module 5 : La relation client	137	113	0	\N	elearning_async	2026-02-03 16:24:36.989849+01	2026-02-03 16:24:36.989849+01	0	\N	\N
1061	17562	762	[AE] Guide du DPE	140	113	0	\N	elearning_async	2026-02-03 16:24:36.98985+01	2026-02-03 16:24:36.98985+01	0	\N	\N
1062	17563	761	DPE - Sans Mention	138	113	0	\N	elearning_async	2026-02-03 16:24:36.989851+01	2026-02-03 16:24:36.989851+01	0	\N	\N
1063	17564	1020	DPE avec mention	116	113	0	\N	elearning_async	2026-02-03 16:24:36.989852+01	2026-02-03 16:24:36.989852+01	0	\N	\N
1064	17565	763	DPE - Avec Mention	139	113	0	\N	elearning_async	2026-02-03 16:24:36.989853+01	2026-02-03 16:24:36.989853+01	0	\N	\N
1065	17566	750	Blocs 1 et 2 - Bienvenue !	117	113	0	\N	elearning_async	2026-02-03 16:24:36.989854+01	2026-02-03 16:24:36.989854+01	0	\N	\N
1066	17567	1151	Point tutoré - BC01 02	118	113	0	\N	elearning_async	2026-02-03 16:24:36.989855+01	2026-02-03 16:24:36.989855+01	0	\N	\N
1067	17582	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	113	0	\N	elearning_async	2026-02-03 16:24:36.989856+01	2026-02-03 16:24:36.989856+01	0	\N	\N
1068	17583	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	113	0	\N	elearning_async	2026-02-03 16:24:36.989857+01	2026-02-03 16:24:36.989858+01	0	\N	\N
1069	17584	768	[AE MI] Partie 3 : Conception de scénarios	143	113	0	\N	elearning_async	2026-02-03 16:24:36.989858+01	2026-02-03 16:24:36.989859+01	0	\N	\N
1070	17585	769	[AE MI] Partie 4 : Le rapport	144	113	0	\N	elearning_async	2026-02-03 16:24:36.989859+01	2026-02-03 16:24:36.98986+01	0	\N	\N
1071	17586	770	[AE MI] Cas Pratique	145	113	0	\N	elearning_async	2026-02-03 16:24:36.98986+01	2026-02-03 16:24:36.989861+01	0	\N	\N
1072	17587	773	Mon Accompagnateur Rénov'	146	113	0	\N	elearning_async	2026-02-03 16:24:36.989862+01	2026-02-03 16:24:36.989862+01	0	\N	\N
1073	17588	777	Audit énergétique - BCT	153	113	0	\N	elearning_async	2026-02-03 16:24:36.989863+01	2026-02-03 16:24:36.989863+01	0	\N	\N
1074	17589	779	Management, Communication, Handicap	152	113	0	\N	elearning_async	2026-02-03 16:24:36.989864+01	2026-02-03 16:24:36.989864+01	0	\N	\N
1075	17590	780	Ordonnancement, Pilotage, et Coordination	154	113	0	\N	elearning_async	2026-02-03 16:24:36.989865+01	2026-02-03 16:24:36.989865+01	0	\N	\N
1076	18061	1898	MAR (C&M) - Module 1 : Les prérequis	147	113	0	\N	elearning_async	2026-02-03 16:24:36.989866+01	2026-02-03 16:24:36.989866+01	0	\N	\N
1077	18094	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	113	0	\N	elearning_async	2026-02-03 16:24:36.989867+01	2026-02-03 16:24:36.989867+01	0	\N	\N
1078	18127	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	113	0	\N	elearning_async	2026-02-03 16:24:36.989868+01	2026-02-03 16:24:36.989869+01	0	\N	\N
1079	18160	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	113	0	\N	elearning_async	2026-02-03 16:24:36.989869+01	2026-02-03 16:24:36.98987+01	0	\N	\N
1080	18193	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	113	0	\N	elearning_async	2026-02-03 16:24:36.98987+01	2026-02-03 16:24:36.989871+01	0	\N	\N
1081	19508	752	Projet tutoré	114	114	0	\N	elearning_async	2026-02-03 16:24:37.40826+01	2026-02-03 16:24:37.408264+01	0	\N	\N
1082	19509	749	Chef de projet en rénovation énergétique - Bienvenue	115	114	0	\N	elearning_async	2026-02-03 16:24:37.408265+01	2026-02-03 16:24:37.408266+01	0	\N	\N
1083	19510	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	114	0	\N	elearning_async	2026-02-03 16:24:37.408266+01	2026-02-03 16:24:37.408267+01	0	\N	\N
1084	19511	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	114	0	\N	elearning_async	2026-02-03 16:24:37.408268+01	2026-02-03 16:24:37.408268+01	0	\N	\N
1085	19512	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	114	0	\N	elearning_async	2026-02-03 16:24:37.408269+01	2026-02-03 16:24:37.408269+01	0	\N	\N
1086	19513	756	Eco-conseiller - Module 4 : Aides et subventions	136	114	0	\N	elearning_async	2026-02-03 16:24:37.40827+01	2026-02-03 16:24:37.40827+01	0	\N	\N
1087	19514	757	Eco-conseiller - Module 5 : La relation client	137	114	0	\N	elearning_async	2026-02-03 16:24:37.408271+01	2026-02-03 16:24:37.408271+01	0	\N	\N
1088	19515	762	[AE] Guide du DPE	140	114	0	\N	elearning_async	2026-02-03 16:24:37.408272+01	2026-02-03 16:24:37.408272+01	0	\N	\N
1089	19516	761	DPE - Sans Mention	138	114	0	\N	elearning_async	2026-02-03 16:24:37.408273+01	2026-02-03 16:24:37.408273+01	0	\N	\N
1090	19517	1020	DPE avec mention	116	114	0	\N	elearning_async	2026-02-03 16:24:37.408274+01	2026-02-03 16:24:37.408274+01	0	\N	\N
1091	19518	763	DPE - Avec Mention	139	114	0	\N	elearning_async	2026-02-03 16:24:37.408275+01	2026-02-03 16:24:37.408275+01	0	\N	\N
1092	19519	750	Blocs 1 et 2 - Bienvenue !	117	114	0	\N	elearning_async	2026-02-03 16:24:37.408276+01	2026-02-03 16:24:37.408276+01	0	\N	\N
1093	19520	1151	Point tutoré - BC01 02	118	114	0	\N	elearning_async	2026-02-03 16:24:37.408277+01	2026-02-03 16:24:37.408278+01	0	\N	\N
1094	19535	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	114	0	\N	elearning_async	2026-02-03 16:24:37.408278+01	2026-02-03 16:24:37.408279+01	0	\N	\N
1095	19536	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	114	0	\N	elearning_async	2026-02-03 16:24:37.408279+01	2026-02-03 16:24:37.40828+01	0	\N	\N
1096	19537	768	[AE MI] Partie 3 : Conception de scénarios	143	114	0	\N	elearning_async	2026-02-03 16:24:37.40828+01	2026-02-03 16:24:37.408281+01	0	\N	\N
1097	19538	769	[AE MI] Partie 4 : Le rapport	144	114	0	\N	elearning_async	2026-02-03 16:24:37.408281+01	2026-02-03 16:24:37.408282+01	0	\N	\N
1098	19539	770	[AE MI] Cas Pratique	145	114	0	\N	elearning_async	2026-02-03 16:24:37.408282+01	2026-02-03 16:24:37.408283+01	0	\N	\N
1099	19540	773	Mon Accompagnateur Rénov'	146	114	0	\N	elearning_async	2026-02-03 16:24:37.408283+01	2026-02-03 16:24:37.408284+01	0	\N	\N
1100	19541	777	Audit énergétique - BCT	153	114	0	\N	elearning_async	2026-02-03 16:24:37.408284+01	2026-02-03 16:24:37.408285+01	0	\N	\N
1101	19542	1898	MAR (C&M) - Module 1 : Les prérequis	147	114	0	\N	elearning_async	2026-02-03 16:24:37.408286+01	2026-02-03 16:24:37.408286+01	0	\N	\N
1102	19543	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	114	0	\N	elearning_async	2026-02-03 16:24:37.408287+01	2026-02-03 16:24:37.408287+01	0	\N	\N
1103	19544	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	114	0	\N	elearning_async	2026-02-03 16:24:37.408288+01	2026-02-03 16:24:37.408288+01	0	\N	\N
1104	19545	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	114	0	\N	elearning_async	2026-02-03 16:24:37.408289+01	2026-02-03 16:24:37.408289+01	0	\N	\N
1105	19546	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	114	0	\N	elearning_async	2026-02-03 16:24:37.40829+01	2026-02-03 16:24:37.40829+01	0	\N	\N
1106	19547	779	Management, Communication, Handicap	152	114	0	\N	elearning_async	2026-02-03 16:24:37.408291+01	2026-02-03 16:24:37.408291+01	0	\N	\N
1107	19548	780	Ordonnancement, Pilotage, et Coordination	154	114	0	\N	elearning_async	2026-02-03 16:24:37.408292+01	2026-02-03 16:24:37.408293+01	0	\N	\N
1108	19603	752	Projet tutoré	114	115	0	\N	elearning_async	2026-02-03 16:24:37.949965+01	2026-02-03 16:24:37.949969+01	0	\N	\N
1109	19604	749	Chef de projet en rénovation énergétique - Bienvenue	115	115	0	\N	elearning_async	2026-02-03 16:24:37.949971+01	2026-02-03 16:24:37.949972+01	0	\N	\N
1110	19605	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	115	0	\N	elearning_async	2026-02-03 16:24:37.949973+01	2026-02-03 16:24:37.949973+01	0	\N	\N
1111	19606	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	115	0	\N	elearning_async	2026-02-03 16:24:37.949974+01	2026-02-03 16:24:37.949975+01	0	\N	\N
1112	19607	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	115	0	\N	elearning_async	2026-02-03 16:24:37.949976+01	2026-02-03 16:24:37.949977+01	0	\N	\N
1113	19608	756	Eco-conseiller - Module 4 : Aides et subventions	136	115	0	\N	elearning_async	2026-02-03 16:24:37.949977+01	2026-02-03 16:24:37.949978+01	0	\N	\N
1114	19609	757	Eco-conseiller - Module 5 : La relation client	137	115	0	\N	elearning_async	2026-02-03 16:24:37.949979+01	2026-02-03 16:24:37.94998+01	0	\N	\N
1115	19610	762	[AE] Guide du DPE	140	115	0	\N	elearning_async	2026-02-03 16:24:37.94998+01	2026-02-03 16:24:37.949981+01	0	\N	\N
1116	19611	761	DPE - Sans Mention	138	115	0	\N	elearning_async	2026-02-03 16:24:37.949982+01	2026-02-03 16:24:37.949982+01	0	\N	\N
1117	19612	1020	DPE avec mention	116	115	0	\N	elearning_async	2026-02-03 16:24:37.949983+01	2026-02-03 16:24:37.949984+01	0	\N	\N
1118	19613	763	DPE - Avec Mention	139	115	0	\N	elearning_async	2026-02-03 16:24:37.949985+01	2026-02-03 16:24:37.949985+01	0	\N	\N
1119	19614	750	Blocs 1 et 2 - Bienvenue !	117	115	0	\N	elearning_async	2026-02-03 16:24:37.949986+01	2026-02-03 16:24:37.949987+01	0	\N	\N
1120	19615	1151	Point tutoré - BC01 02	118	115	0	\N	elearning_async	2026-02-03 16:24:37.949987+01	2026-02-03 16:24:37.949988+01	0	\N	\N
1121	19630	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	115	0	\N	elearning_async	2026-02-03 16:24:37.949989+01	2026-02-03 16:24:37.949989+01	0	\N	\N
1122	19631	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	115	0	\N	elearning_async	2026-02-03 16:24:37.94999+01	2026-02-03 16:24:37.949991+01	0	\N	\N
1123	19632	768	[AE MI] Partie 3 : Conception de scénarios	143	115	0	\N	elearning_async	2026-02-03 16:24:37.949992+01	2026-02-03 16:24:37.949992+01	0	\N	\N
1124	19633	769	[AE MI] Partie 4 : Le rapport	144	115	0	\N	elearning_async	2026-02-03 16:24:37.949993+01	2026-02-03 16:24:37.949994+01	0	\N	\N
1125	19634	770	[AE MI] Cas Pratique	145	115	0	\N	elearning_async	2026-02-03 16:24:37.949995+01	2026-02-03 16:24:37.949995+01	0	\N	\N
1126	19635	773	Mon Accompagnateur Rénov'	146	115	0	\N	elearning_async	2026-02-03 16:24:37.949996+01	2026-02-03 16:24:37.949997+01	0	\N	\N
1127	19636	777	Audit énergétique - BCT	153	115	0	\N	elearning_async	2026-02-03 16:24:37.949997+01	2026-02-03 16:24:37.949998+01	0	\N	\N
1128	19637	1898	MAR (C&M) - Module 1 : Les prérequis	147	115	0	\N	elearning_async	2026-02-03 16:24:37.949999+01	2026-02-03 16:24:37.949999+01	0	\N	\N
1183	3416	789	Chef de projet en rénovation énergétique - Bienvenue	156	119	0	\N	elearning_async	2026-02-03 16:24:39.95148+01	2026-02-03 16:24:39.951483+01	0	\N	\N
1129	19638	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	115	0	\N	elearning_async	2026-02-03 16:24:37.95+01	2026-02-03 16:24:37.950001+01	0	\N	\N
1130	19639	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	115	0	\N	elearning_async	2026-02-03 16:24:37.950002+01	2026-02-03 16:24:37.950002+01	0	\N	\N
1131	19640	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	115	0	\N	elearning_async	2026-02-03 16:24:37.950003+01	2026-02-03 16:24:37.950004+01	0	\N	\N
1132	19641	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	115	0	\N	elearning_async	2026-02-03 16:24:37.950004+01	2026-02-03 16:24:37.950005+01	0	\N	\N
1133	19642	779	Management, Communication, Handicap	152	115	0	\N	elearning_async	2026-02-03 16:24:37.950006+01	2026-02-03 16:24:37.950007+01	0	\N	\N
1134	19643	780	Ordonnancement, Pilotage, et Coordination	154	115	0	\N	elearning_async	2026-02-03 16:24:37.950007+01	2026-02-03 16:24:37.950008+01	0	\N	\N
1135	19720	752	Projet tutoré	114	116	0	\N	elearning_async	2026-02-03 16:24:38.379396+01	2026-02-03 16:24:38.3794+01	0	\N	\N
1136	19721	749	Chef de projet en rénovation énergétique - Bienvenue	115	116	0	\N	elearning_async	2026-02-03 16:24:38.379401+01	2026-02-03 16:24:38.379401+01	0	\N	\N
1137	19722	753	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	133	116	0	\N	elearning_async	2026-02-03 16:24:38.379402+01	2026-02-03 16:24:38.379403+01	0	\N	\N
1138	19723	754	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	134	116	0	\N	elearning_async	2026-02-03 16:24:38.379403+01	2026-02-03 16:24:38.379404+01	0	\N	\N
1139	19724	755	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	135	116	0	\N	elearning_async	2026-02-03 16:24:38.379404+01	2026-02-03 16:24:38.379405+01	0	\N	\N
1140	19725	756	Eco-conseiller - Module 4 : Aides et subventions	136	116	0	\N	elearning_async	2026-02-03 16:24:38.379406+01	2026-02-03 16:24:38.379406+01	0	\N	\N
1141	19726	757	Eco-conseiller - Module 5 : La relation client	137	116	0	\N	elearning_async	2026-02-03 16:24:38.379407+01	2026-02-03 16:24:38.379407+01	0	\N	\N
1142	19727	762	[AE] Guide du DPE	140	116	0	\N	elearning_async	2026-02-03 16:24:38.379408+01	2026-02-03 16:24:38.379408+01	0	\N	\N
1143	19728	761	DPE - Sans Mention	138	116	0	\N	elearning_async	2026-02-03 16:24:38.379409+01	2026-02-03 16:24:38.37941+01	0	\N	\N
1144	19729	1020	DPE avec mention	116	116	0	\N	elearning_async	2026-02-03 16:24:38.37941+01	2026-02-03 16:24:38.379411+01	0	\N	\N
1145	19730	763	DPE - Avec Mention	139	116	0	\N	elearning_async	2026-02-03 16:24:38.379411+01	2026-02-03 16:24:38.379412+01	0	\N	\N
1146	19731	750	Blocs 1 et 2 - Bienvenue !	117	116	0	\N	elearning_async	2026-02-03 16:24:38.379412+01	2026-02-03 16:24:38.379413+01	0	\N	\N
1147	19732	1151	Point tutoré - BC01 02	118	116	50	2025-10-02 11:32:41+02	elearning_async	2026-02-03 16:24:38.379414+01	2026-02-03 16:24:38.379414+01	22020	2025-10-02 11:32:41+02	\N
1148	19747	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	116	0	\N	elearning_async	2026-02-03 16:24:38.379415+01	2026-02-03 16:24:38.379415+01	0	\N	\N
1149	19748	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	116	0	\N	elearning_async	2026-02-03 16:24:38.379416+01	2026-02-03 16:24:38.379416+01	0	\N	\N
1150	19749	768	[AE MI] Partie 3 : Conception de scénarios	143	116	0	\N	elearning_async	2026-02-03 16:24:38.379417+01	2026-02-03 16:24:38.379418+01	0	\N	\N
1151	19750	769	[AE MI] Partie 4 : Le rapport	144	116	0	\N	elearning_async	2026-02-03 16:24:38.379418+01	2026-02-03 16:24:38.379419+01	0	\N	\N
1152	19751	770	[AE MI] Cas Pratique	145	116	0	\N	elearning_async	2026-02-03 16:24:38.379419+01	2026-02-03 16:24:38.37942+01	0	\N	\N
1153	19752	773	Mon Accompagnateur Rénov'	146	116	0	\N	elearning_async	2026-02-03 16:24:38.379421+01	2026-02-03 16:24:38.379421+01	0	\N	\N
1154	19753	777	Audit énergétique - BCT	153	116	0	\N	elearning_async	2026-02-03 16:24:38.379422+01	2026-02-03 16:24:38.379422+01	0	\N	\N
1155	19754	1898	MAR (C&M) - Module 1 : Les prérequis	147	116	0	\N	elearning_async	2026-02-03 16:24:38.379423+01	2026-02-03 16:24:38.379423+01	0	\N	\N
1156	19755	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	116	0	\N	elearning_async	2026-02-03 16:24:38.379424+01	2026-02-03 16:24:38.379425+01	0	\N	\N
1157	19756	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	116	0	\N	elearning_async	2026-02-03 16:24:38.379425+01	2026-02-03 16:24:38.379426+01	0	\N	\N
1158	19757	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	116	0	\N	elearning_async	2026-02-03 16:24:38.379426+01	2026-02-03 16:24:38.379427+01	0	\N	\N
1159	19758	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	116	0	\N	elearning_async	2026-02-03 16:24:38.379427+01	2026-02-03 16:24:38.379428+01	0	\N	\N
1160	19759	779	Management, Communication, Handicap	152	116	0	\N	elearning_async	2026-02-03 16:24:38.379429+01	2026-02-03 16:24:38.379429+01	0	\N	\N
1161	19760	780	Ordonnancement, Pilotage, et Coordination	154	116	0	\N	elearning_async	2026-02-03 16:24:38.37943+01	2026-02-03 16:24:38.37943+01	0	\N	\N
1162	3381	789	Chef de projet en rénovation énergétique - Bienvenue	156	118	0	\N	elearning_async	2026-02-03 16:24:39.536264+01	2026-02-03 16:24:39.536272+01	0	\N	\N
1163	3396	790	Blocs 1 et 2 - Bienvenue !	177	118	0	\N	elearning_async	2026-02-03 16:24:39.536276+01	2026-02-03 16:24:39.536277+01	0	\N	\N
1164	3397	792	Projet tutoré	178	118	0	\N	elearning_async	2026-02-03 16:24:39.536279+01	2026-02-03 16:24:39.536281+01	0	\N	\N
1165	3398	802	DPE - Sans Mention	179	118	0	\N	elearning_async	2026-02-03 16:24:39.536283+01	2026-02-03 16:24:39.536285+01	0	\N	\N
1166	3399	807	[AE MI] Partie 1 : Méthodologie & Données d'entrée	180	118	0	\N	elearning_async	2026-02-03 16:24:39.536287+01	2026-02-03 16:24:39.536289+01	0	\N	\N
1167	3400	814	Mon Accompagnateur Rénov'	181	118	0	\N	elearning_async	2026-02-03 16:24:39.536291+01	2026-02-03 16:24:39.536293+01	0	\N	\N
1168	3401	817	Management, Communication, Handicap	182	118	0	\N	elearning_async	2026-02-03 16:24:39.536295+01	2026-02-03 16:24:39.536296+01	0	\N	\N
1169	3402	819	Audit énergétique - BCT	183	118	0	\N	elearning_async	2026-02-03 16:24:39.536298+01	2026-02-03 16:24:39.5363+01	0	\N	\N
1170	3403	821	Ordonnancement, Pilotage, et Coordination	184	118	0	\N	elearning_async	2026-02-03 16:24:39.536302+01	2026-02-03 16:24:39.536304+01	0	\N	\N
1171	3404	793	Point tutoré - BC01 02	185	118	0	\N	elearning_async	2026-02-03 16:24:39.536306+01	2026-02-03 16:24:39.536308+01	0	\N	\N
1172	3405	808	[AE MI] Partie 2 : Contraintes et Pathologies	186	118	0	\N	elearning_async	2026-02-03 16:24:39.53631+01	2026-02-03 16:24:39.536312+01	0	\N	\N
1173	3406	794	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	157	118	0	\N	elearning_async	2026-02-03 16:24:39.536314+01	2026-02-03 16:24:39.536315+01	0	\N	\N
1174	3407	809	[AE MI] Partie 3 : Conception de scénarios	160	118	0	\N	elearning_async	2026-02-03 16:24:39.536318+01	2026-02-03 16:24:39.536319+01	0	\N	\N
1175	3408	795	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	187	118	0	\N	elearning_async	2026-02-03 16:24:39.536321+01	2026-02-03 16:24:39.536323+01	0	\N	\N
1176	3409	810	[AE MI] Partie 4 : Le rapport	161	118	0	\N	elearning_async	2026-02-03 16:24:39.536325+01	2026-02-03 16:24:39.536327+01	0	\N	\N
1177	3410	796	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	188	118	0	\N	elearning_async	2026-02-03 16:24:39.536329+01	2026-02-03 16:24:39.536331+01	0	\N	\N
1178	3411	811	[AE MI] Cas Pratique	162	118	0	\N	elearning_async	2026-02-03 16:24:39.536333+01	2026-02-03 16:24:39.536335+01	0	\N	\N
1179	3412	797	Eco-conseiller - Module 4 : Aides et subventions	189	118	0	\N	elearning_async	2026-02-03 16:24:39.536337+01	2026-02-03 16:24:39.536339+01	0	\N	\N
1180	3413	798	Eco-conseiller - Module 5 : La relation client	158	118	0	\N	elearning_async	2026-02-03 16:24:39.536341+01	2026-02-03 16:24:39.536342+01	0	\N	\N
1181	3414	803	[AE] Guide du DPE	190	118	0	\N	elearning_async	2026-02-03 16:24:39.536344+01	2026-02-03 16:24:39.536346+01	0	\N	\N
1182	3415	804	DPE - Avec Mention	159	118	0	\N	elearning_async	2026-02-03 16:24:39.536348+01	2026-02-03 16:24:39.53635+01	0	\N	\N
1184	3431	790	Blocs 1 et 2 - Bienvenue !	177	119	0	\N	elearning_async	2026-02-03 16:24:39.951484+01	2026-02-03 16:24:39.951485+01	0	\N	\N
1185	3432	792	Projet tutoré	178	119	0	\N	elearning_async	2026-02-03 16:24:39.951485+01	2026-02-03 16:24:39.951486+01	0	\N	\N
1186	3433	802	DPE - Sans Mention	179	119	0	\N	elearning_async	2026-02-03 16:24:39.951486+01	2026-02-03 16:24:39.951487+01	0	\N	\N
1187	3434	807	[AE MI] Partie 1 : Méthodologie & Données d'entrée	180	119	0	\N	elearning_async	2026-02-03 16:24:39.951488+01	2026-02-03 16:24:39.951488+01	0	\N	\N
1188	3435	814	Mon Accompagnateur Rénov'	181	119	0	\N	elearning_async	2026-02-03 16:24:39.951489+01	2026-02-03 16:24:39.951489+01	0	\N	\N
1189	3436	817	Management, Communication, Handicap	182	119	0	\N	elearning_async	2026-02-03 16:24:39.95149+01	2026-02-03 16:24:39.95149+01	0	\N	\N
1190	3437	819	Audit énergétique - BCT	183	119	0	\N	elearning_async	2026-02-03 16:24:39.951491+01	2026-02-03 16:24:39.951491+01	0	\N	\N
1191	3438	821	Ordonnancement, Pilotage, et Coordination	184	119	0	\N	elearning_async	2026-02-03 16:24:39.951492+01	2026-02-03 16:24:39.951492+01	0	\N	\N
1192	3439	793	Point tutoré - BC01 02	185	119	0	\N	elearning_async	2026-02-03 16:24:39.951493+01	2026-02-03 16:24:39.951493+01	0	\N	\N
1193	3440	808	[AE MI] Partie 2 : Contraintes et Pathologies	186	119	0	\N	elearning_async	2026-02-03 16:24:39.951494+01	2026-02-03 16:24:39.951494+01	0	\N	\N
1194	3441	794	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	157	119	0	\N	elearning_async	2026-02-03 16:24:39.951495+01	2026-02-03 16:24:39.951496+01	0	\N	\N
1195	3442	809	[AE MI] Partie 3 : Conception de scénarios	160	119	0	\N	elearning_async	2026-02-03 16:24:39.951496+01	2026-02-03 16:24:39.951497+01	0	\N	\N
1196	3443	795	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	187	119	0	\N	elearning_async	2026-02-03 16:24:39.951497+01	2026-02-03 16:24:39.951498+01	0	\N	\N
1197	3444	810	[AE MI] Partie 4 : Le rapport	161	119	0	\N	elearning_async	2026-02-03 16:24:39.951498+01	2026-02-03 16:24:39.951499+01	0	\N	\N
1198	3445	796	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	188	119	0	\N	elearning_async	2026-02-03 16:24:39.951499+01	2026-02-03 16:24:39.9515+01	0	\N	\N
1199	3446	811	[AE MI] Cas Pratique	162	119	0	\N	elearning_async	2026-02-03 16:24:39.951501+01	2026-02-03 16:24:39.951501+01	0	\N	\N
1200	3447	797	Eco-conseiller - Module 4 : Aides et subventions	189	119	0	\N	elearning_async	2026-02-03 16:24:39.951502+01	2026-02-03 16:24:39.951502+01	0	\N	\N
1201	3448	798	Eco-conseiller - Module 5 : La relation client	158	119	0	\N	elearning_async	2026-02-03 16:24:39.951503+01	2026-02-03 16:24:39.951503+01	0	\N	\N
1202	3449	803	[AE] Guide du DPE	190	119	0	\N	elearning_async	2026-02-03 16:24:39.951504+01	2026-02-03 16:24:39.951504+01	0	\N	\N
1203	3450	804	DPE - Avec Mention	159	119	0	\N	elearning_async	2026-02-03 16:24:39.951505+01	2026-02-03 16:24:39.951505+01	0	\N	\N
1204	3451	789	Chef de projet en rénovation énergétique - Bienvenue	156	120	0	\N	elearning_async	2026-02-03 16:24:40.38143+01	2026-02-03 16:24:40.381435+01	0	\N	\N
1205	3466	790	Blocs 1 et 2 - Bienvenue !	177	120	0	\N	elearning_async	2026-02-03 16:24:40.381437+01	2026-02-03 16:24:40.381437+01	0	\N	\N
1206	3467	792	Projet tutoré	178	120	0	\N	elearning_async	2026-02-03 16:24:40.381438+01	2026-02-03 16:24:40.381439+01	0	\N	\N
1207	3468	802	DPE - Sans Mention	179	120	0	\N	elearning_async	2026-02-03 16:24:40.38144+01	2026-02-03 16:24:40.381441+01	0	\N	\N
1208	3469	807	[AE MI] Partie 1 : Méthodologie & Données d'entrée	180	120	0	\N	elearning_async	2026-02-03 16:24:40.381442+01	2026-02-03 16:24:40.381443+01	0	\N	\N
1209	3470	814	Mon Accompagnateur Rénov'	181	120	0	\N	elearning_async	2026-02-03 16:24:40.381443+01	2026-02-03 16:24:40.381444+01	0	\N	\N
1210	3471	817	Management, Communication, Handicap	182	120	0	\N	elearning_async	2026-02-03 16:24:40.381445+01	2026-02-03 16:24:40.381446+01	0	\N	\N
1211	3472	819	Audit énergétique - BCT	183	120	0	\N	elearning_async	2026-02-03 16:24:40.381447+01	2026-02-03 16:24:40.381448+01	0	\N	\N
1212	3473	821	Ordonnancement, Pilotage, et Coordination	184	120	0	\N	elearning_async	2026-02-03 16:24:40.381449+01	2026-02-03 16:24:40.38145+01	0	\N	\N
1213	3474	793	Point tutoré - BC01 02	185	120	0	\N	elearning_async	2026-02-03 16:24:40.38145+01	2026-02-03 16:24:40.381451+01	0	\N	\N
1214	3475	808	[AE MI] Partie 2 : Contraintes et Pathologies	186	120	0	\N	elearning_async	2026-02-03 16:24:40.381452+01	2026-02-03 16:24:40.381453+01	0	\N	\N
1215	3476	794	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	157	120	0	\N	elearning_async	2026-02-03 16:24:40.381454+01	2026-02-03 16:24:40.381455+01	0	\N	\N
1216	3477	809	[AE MI] Partie 3 : Conception de scénarios	160	120	0	\N	elearning_async	2026-02-03 16:24:40.381456+01	2026-02-03 16:24:40.381456+01	0	\N	\N
1217	3478	795	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	187	120	0	\N	elearning_async	2026-02-03 16:24:40.381457+01	2026-02-03 16:24:40.381458+01	0	\N	\N
1218	3479	810	[AE MI] Partie 4 : Le rapport	161	120	0	\N	elearning_async	2026-02-03 16:24:40.381459+01	2026-02-03 16:24:40.38146+01	0	\N	\N
1219	3480	796	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	188	120	0	\N	elearning_async	2026-02-03 16:24:40.381461+01	2026-02-03 16:24:40.381462+01	0	\N	\N
1220	3481	811	[AE MI] Cas Pratique	162	120	0	\N	elearning_async	2026-02-03 16:24:40.381463+01	2026-02-03 16:24:40.381463+01	0	\N	\N
1221	3482	797	Eco-conseiller - Module 4 : Aides et subventions	189	120	0	\N	elearning_async	2026-02-03 16:24:40.381465+01	2026-02-03 16:24:40.381465+01	0	\N	\N
1222	3483	798	Eco-conseiller - Module 5 : La relation client	158	120	0	\N	elearning_async	2026-02-03 16:24:40.381466+01	2026-02-03 16:24:40.381467+01	0	\N	\N
1223	3484	803	[AE] Guide du DPE	190	120	0	\N	elearning_async	2026-02-03 16:24:40.381468+01	2026-02-03 16:24:40.381469+01	0	\N	\N
1224	3485	804	DPE - Avec Mention	159	120	0	\N	elearning_async	2026-02-03 16:24:40.38147+01	2026-02-03 16:24:40.38147+01	0	\N	\N
1225	3486	789	Chef de projet en rénovation énergétique - Bienvenue	156	121	0	\N	elearning_async	2026-02-03 16:24:40.809373+01	2026-02-03 16:24:40.809376+01	0	\N	\N
1226	3501	790	Blocs 1 et 2 - Bienvenue !	177	121	0	\N	elearning_async	2026-02-03 16:24:40.809377+01	2026-02-03 16:24:40.809378+01	0	\N	\N
1227	3502	792	Projet tutoré	178	121	0	\N	elearning_async	2026-02-03 16:24:40.809378+01	2026-02-03 16:24:40.809379+01	0	\N	\N
1228	3503	802	DPE - Sans Mention	179	121	0	\N	elearning_async	2026-02-03 16:24:40.809379+01	2026-02-03 16:24:40.80938+01	0	\N	\N
1229	3504	807	[AE MI] Partie 1 : Méthodologie & Données d'entrée	180	121	0	\N	elearning_async	2026-02-03 16:24:40.80938+01	2026-02-03 16:24:40.809381+01	0	\N	\N
1230	3505	814	Mon Accompagnateur Rénov'	181	121	0	\N	elearning_async	2026-02-03 16:24:40.809382+01	2026-02-03 16:24:40.809382+01	0	\N	\N
1231	3506	817	Management, Communication, Handicap	182	121	0	\N	elearning_async	2026-02-03 16:24:40.809383+01	2026-02-03 16:24:40.809383+01	0	\N	\N
1232	3507	819	Audit énergétique - BCT	183	121	0	\N	elearning_async	2026-02-03 16:24:40.809384+01	2026-02-03 16:24:40.809384+01	0	\N	\N
1233	3508	821	Ordonnancement, Pilotage, et Coordination	184	121	0	\N	elearning_async	2026-02-03 16:24:40.809385+01	2026-02-03 16:24:40.809385+01	0	\N	\N
1234	3509	793	Point tutoré - BC01 02	185	121	0	\N	elearning_async	2026-02-03 16:24:40.809386+01	2026-02-03 16:24:40.809386+01	0	\N	\N
1235	3510	808	[AE MI] Partie 2 : Contraintes et Pathologies	186	121	0	\N	elearning_async	2026-02-03 16:24:40.809387+01	2026-02-03 16:24:40.809387+01	0	\N	\N
1236	3511	794	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	157	121	0	\N	elearning_async	2026-02-03 16:24:40.809388+01	2026-02-03 16:24:40.809388+01	0	\N	\N
1237	3512	809	[AE MI] Partie 3 : Conception de scénarios	160	121	0	\N	elearning_async	2026-02-03 16:24:40.809389+01	2026-02-03 16:24:40.809389+01	0	\N	\N
1238	3513	795	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	187	121	0	\N	elearning_async	2026-02-03 16:24:40.80939+01	2026-02-03 16:24:40.80939+01	0	\N	\N
1239	3514	810	[AE MI] Partie 4 : Le rapport	161	121	0	\N	elearning_async	2026-02-03 16:24:40.809391+01	2026-02-03 16:24:40.809391+01	0	\N	\N
1240	3515	796	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	188	121	0	\N	elearning_async	2026-02-03 16:24:40.809392+01	2026-02-03 16:24:40.809392+01	0	\N	\N
1241	3516	811	[AE MI] Cas Pratique	162	121	0	\N	elearning_async	2026-02-03 16:24:40.809393+01	2026-02-03 16:24:40.809393+01	0	\N	\N
1242	3517	797	Eco-conseiller - Module 4 : Aides et subventions	189	121	0	\N	elearning_async	2026-02-03 16:24:40.809394+01	2026-02-03 16:24:40.809395+01	0	\N	\N
1243	3518	798	Eco-conseiller - Module 5 : La relation client	158	121	0	\N	elearning_async	2026-02-03 16:24:40.809395+01	2026-02-03 16:24:40.809396+01	0	\N	\N
1244	3519	803	[AE] Guide du DPE	190	121	0	\N	elearning_async	2026-02-03 16:24:40.809396+01	2026-02-03 16:24:40.809397+01	0	\N	\N
1245	3520	804	DPE - Avec Mention	159	121	0	\N	elearning_async	2026-02-03 16:24:40.809397+01	2026-02-03 16:24:40.809398+01	0	\N	\N
1246	3521	789	Chef de projet en rénovation énergétique - Bienvenue	156	122	0	\N	elearning_async	2026-02-03 16:24:41.301747+01	2026-02-03 16:24:41.30175+01	0	\N	\N
1247	3536	790	Blocs 1 et 2 - Bienvenue !	177	122	0	\N	elearning_async	2026-02-03 16:24:41.301751+01	2026-02-03 16:24:41.301751+01	0	\N	\N
1248	3537	792	Projet tutoré	178	122	0	\N	elearning_async	2026-02-03 16:24:41.301752+01	2026-02-03 16:24:41.301753+01	0	\N	\N
1249	3538	802	DPE - Sans Mention	179	122	0	\N	elearning_async	2026-02-03 16:24:41.301753+01	2026-02-03 16:24:41.301754+01	0	\N	\N
1250	3539	807	[AE MI] Partie 1 : Méthodologie & Données d'entrée	180	122	0	\N	elearning_async	2026-02-03 16:24:41.301754+01	2026-02-03 16:24:41.301755+01	0	\N	\N
1251	3540	814	Mon Accompagnateur Rénov'	181	122	0	\N	elearning_async	2026-02-03 16:24:41.301755+01	2026-02-03 16:24:41.301756+01	0	\N	\N
1252	3541	817	Management, Communication, Handicap	182	122	0	\N	elearning_async	2026-02-03 16:24:41.301757+01	2026-02-03 16:24:41.301757+01	0	\N	\N
1253	3542	819	Audit énergétique - BCT	183	122	0	\N	elearning_async	2026-02-03 16:24:41.301758+01	2026-02-03 16:24:41.301758+01	0	\N	\N
1254	3543	821	Ordonnancement, Pilotage, et Coordination	184	122	0	\N	elearning_async	2026-02-03 16:24:41.301759+01	2026-02-03 16:24:41.301759+01	0	\N	\N
1255	3544	793	Point tutoré - BC01 02	185	122	0	\N	elearning_async	2026-02-03 16:24:41.30176+01	2026-02-03 16:24:41.301761+01	0	\N	\N
1256	3545	808	[AE MI] Partie 2 : Contraintes et Pathologies	186	122	0	\N	elearning_async	2026-02-03 16:24:41.301761+01	2026-02-03 16:24:41.301762+01	0	\N	\N
1257	3546	794	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	157	122	0	\N	elearning_async	2026-02-03 16:24:41.301762+01	2026-02-03 16:24:41.301763+01	0	\N	\N
1258	3547	809	[AE MI] Partie 3 : Conception de scénarios	160	122	0	\N	elearning_async	2026-02-03 16:24:41.301763+01	2026-02-03 16:24:41.301764+01	0	\N	\N
1259	3548	795	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	187	122	0	\N	elearning_async	2026-02-03 16:24:41.301765+01	2026-02-03 16:24:41.301765+01	0	\N	\N
1260	3549	810	[AE MI] Partie 4 : Le rapport	161	122	0	\N	elearning_async	2026-02-03 16:24:41.301766+01	2026-02-03 16:24:41.301767+01	0	\N	\N
1261	3550	796	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	188	122	0	\N	elearning_async	2026-02-03 16:24:41.301767+01	2026-02-03 16:24:41.301768+01	0	\N	\N
1262	3551	811	[AE MI] Cas Pratique	162	122	0	\N	elearning_async	2026-02-03 16:24:41.301768+01	2026-02-03 16:24:41.301769+01	0	\N	\N
1263	3552	797	Eco-conseiller - Module 4 : Aides et subventions	189	122	0	\N	elearning_async	2026-02-03 16:24:41.30177+01	2026-02-03 16:24:41.30177+01	0	\N	\N
1264	3553	798	Eco-conseiller - Module 5 : La relation client	158	122	0	\N	elearning_async	2026-02-03 16:24:41.301771+01	2026-02-03 16:24:41.301771+01	0	\N	\N
1265	3554	803	[AE] Guide du DPE	190	122	0	\N	elearning_async	2026-02-03 16:24:41.301772+01	2026-02-03 16:24:41.301773+01	0	\N	\N
1266	3555	804	DPE - Avec Mention	159	122	0	\N	elearning_async	2026-02-03 16:24:41.301773+01	2026-02-03 16:24:41.301774+01	0	\N	\N
1267	3556	789	Chef de projet en rénovation énergétique - Bienvenue	156	123	0	\N	elearning_async	2026-02-03 16:24:41.692651+01	2026-02-03 16:24:41.692654+01	0	\N	\N
1268	3571	790	Blocs 1 et 2 - Bienvenue !	177	123	0	\N	elearning_async	2026-02-03 16:24:41.692655+01	2026-02-03 16:24:41.692656+01	0	\N	\N
1269	3572	792	Projet tutoré	178	123	0	\N	elearning_async	2026-02-03 16:24:41.692656+01	2026-02-03 16:24:41.692657+01	0	\N	\N
1270	3573	802	DPE - Sans Mention	179	123	0	\N	elearning_async	2026-02-03 16:24:41.692658+01	2026-02-03 16:24:41.692658+01	0	\N	\N
1271	3574	807	[AE MI] Partie 1 : Méthodologie & Données d'entrée	180	123	0	\N	elearning_async	2026-02-03 16:24:41.692659+01	2026-02-03 16:24:41.692659+01	0	\N	\N
1272	3575	814	Mon Accompagnateur Rénov'	181	123	0	\N	elearning_async	2026-02-03 16:24:41.69266+01	2026-02-03 16:24:41.69266+01	0	\N	\N
1273	3576	817	Management, Communication, Handicap	182	123	0	\N	elearning_async	2026-02-03 16:24:41.692661+01	2026-02-03 16:24:41.692661+01	0	\N	\N
1274	3577	819	Audit énergétique - BCT	183	123	0	\N	elearning_async	2026-02-03 16:24:41.692662+01	2026-02-03 16:24:41.692662+01	0	\N	\N
1275	3578	821	Ordonnancement, Pilotage, et Coordination	184	123	0	\N	elearning_async	2026-02-03 16:24:41.692663+01	2026-02-03 16:24:41.692663+01	0	\N	\N
1276	3579	793	Point tutoré - BC01 02	185	123	0	\N	elearning_async	2026-02-03 16:24:41.692664+01	2026-02-03 16:24:41.692664+01	0	\N	\N
1277	3580	808	[AE MI] Partie 2 : Contraintes et Pathologies	186	123	0	\N	elearning_async	2026-02-03 16:24:41.692665+01	2026-02-03 16:24:41.692665+01	0	\N	\N
1278	3581	794	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	157	123	0	\N	elearning_async	2026-02-03 16:24:41.692666+01	2026-02-03 16:24:41.692666+01	0	\N	\N
1279	3582	809	[AE MI] Partie 3 : Conception de scénarios	160	123	0	\N	elearning_async	2026-02-03 16:24:41.692667+01	2026-02-03 16:24:41.692667+01	0	\N	\N
1280	3583	795	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	187	123	0	\N	elearning_async	2026-02-03 16:24:41.692668+01	2026-02-03 16:24:41.692668+01	0	\N	\N
1281	3584	810	[AE MI] Partie 4 : Le rapport	161	123	0	\N	elearning_async	2026-02-03 16:24:41.692669+01	2026-02-03 16:24:41.692669+01	0	\N	\N
1282	3585	796	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	188	123	0	\N	elearning_async	2026-02-03 16:24:41.69267+01	2026-02-03 16:24:41.69267+01	0	\N	\N
1283	3586	811	[AE MI] Cas Pratique	162	123	0	\N	elearning_async	2026-02-03 16:24:41.692671+01	2026-02-03 16:24:41.692671+01	0	\N	\N
1284	3587	797	Eco-conseiller - Module 4 : Aides et subventions	189	123	0	\N	elearning_async	2026-02-03 16:24:41.692672+01	2026-02-03 16:24:41.692672+01	0	\N	\N
1285	3588	798	Eco-conseiller - Module 5 : La relation client	158	123	0	\N	elearning_async	2026-02-03 16:24:41.692673+01	2026-02-03 16:24:41.692673+01	0	\N	\N
1286	3589	803	[AE] Guide du DPE	190	123	0	\N	elearning_async	2026-02-03 16:24:41.692674+01	2026-02-03 16:24:41.692674+01	0	\N	\N
1287	3590	804	DPE - Avec Mention	159	123	0	\N	elearning_async	2026-02-03 16:24:41.692675+01	2026-02-03 16:24:41.692676+01	0	\N	\N
1288	3591	789	Chef de projet en rénovation énergétique - Bienvenue	156	124	0	\N	elearning_async	2026-02-03 16:24:42.136717+01	2026-02-03 16:24:42.13672+01	0	\N	\N
1289	3606	790	Blocs 1 et 2 - Bienvenue !	177	124	0	\N	elearning_async	2026-02-03 16:24:42.136721+01	2026-02-03 16:24:42.136722+01	0	\N	\N
1290	3607	792	Projet tutoré	178	124	0	\N	elearning_async	2026-02-03 16:24:42.136722+01	2026-02-03 16:24:42.136723+01	0	\N	\N
1291	3608	802	DPE - Sans Mention	179	124	0	\N	elearning_async	2026-02-03 16:24:42.136723+01	2026-02-03 16:24:42.136724+01	0	\N	\N
1292	3609	807	[AE MI] Partie 1 : Méthodologie & Données d'entrée	180	124	0	\N	elearning_async	2026-02-03 16:24:42.136725+01	2026-02-03 16:24:42.136725+01	0	\N	\N
1293	3610	814	Mon Accompagnateur Rénov'	181	124	0	\N	elearning_async	2026-02-03 16:24:42.136726+01	2026-02-03 16:24:42.136726+01	0	\N	\N
1294	3611	817	Management, Communication, Handicap	182	124	0	\N	elearning_async	2026-02-03 16:24:42.136727+01	2026-02-03 16:24:42.136727+01	0	\N	\N
297	18163	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	85	0	\N	elearning_async	2026-02-03 16:24:23.42899+01	2026-02-03 16:24:40.482223+01	0	\N	\N
306	5732	761	DPE - Sans Mention	138	86	0	\N	elearning_async	2026-02-03 16:24:23.912256+01	2026-02-03 16:24:40.876491+01	0	\N	\N
307	5733	763	DPE - Avec Mention	139	86	0	\N	elearning_async	2026-02-03 16:24:23.912258+01	2026-02-03 16:24:40.876491+01	0	\N	\N
308	5748	750	Blocs 1 et 2 - Bienvenue !	117	86	0	\N	elearning_async	2026-02-03 16:24:23.912259+01	2026-02-03 16:24:40.876491+01	0	\N	\N
309	5749	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	86	0	\N	elearning_async	2026-02-03 16:24:23.91226+01	2026-02-03 16:24:40.876491+01	0	\N	\N
310	5750	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	86	0	\N	elearning_async	2026-02-03 16:24:23.912261+01	2026-02-03 16:24:40.876491+01	0	\N	\N
311	5751	768	[AE MI] Partie 3 : Conception de scénarios	143	86	0	\N	elearning_async	2026-02-03 16:24:23.912262+01	2026-02-03 16:24:40.876491+01	0	\N	\N
312	5752	769	[AE MI] Partie 4 : Le rapport	144	86	0	\N	elearning_async	2026-02-03 16:24:23.912263+01	2026-02-03 16:24:40.876491+01	0	\N	\N
313	5753	770	[AE MI] Cas Pratique	145	86	0	\N	elearning_async	2026-02-03 16:24:23.912265+01	2026-02-03 16:24:40.876491+01	0	\N	\N
314	5754	773	Mon Accompagnateur Rénov'	146	86	0	\N	elearning_async	2026-02-03 16:24:23.912266+01	2026-02-03 16:24:40.876491+01	0	\N	\N
315	5755	777	Audit énergétique - BCT	153	86	0	\N	elearning_async	2026-02-03 16:24:23.912267+01	2026-02-03 16:24:40.876491+01	0	\N	\N
316	5756	779	Management, Communication, Handicap	152	86	0	\N	elearning_async	2026-02-03 16:24:23.912268+01	2026-02-03 16:24:40.876491+01	0	\N	\N
317	5757	780	Ordonnancement, Pilotage, et Coordination	154	86	0	\N	elearning_async	2026-02-03 16:24:23.912269+01	2026-02-03 16:24:40.876491+01	0	\N	\N
318	14330	1020	DPE avec mention	116	86	0	\N	elearning_async	2026-02-03 16:24:23.91227+01	2026-02-03 16:24:40.876491+01	0	\N	\N
319	15088	1151	Point tutoré - BC01 02	118	86	0	\N	elearning_async	2026-02-03 16:24:23.912271+01	2026-02-03 16:24:40.876491+01	0	\N	\N
320	18032	1898	MAR (C&M) - Module 1 : Les prérequis	147	86	0	\N	elearning_async	2026-02-03 16:24:23.912273+01	2026-02-03 16:24:40.876491+01	0	\N	\N
321	18065	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	86	0	\N	elearning_async	2026-02-03 16:24:23.912274+01	2026-02-03 16:24:40.876491+01	0	\N	\N
322	18098	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	86	0	\N	elearning_async	2026-02-03 16:24:23.912275+01	2026-02-03 16:24:40.876491+01	0	\N	\N
323	18131	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	86	0	\N	elearning_async	2026-02-03 16:24:23.912276+01	2026-02-03 16:24:40.876491+01	0	\N	\N
324	18164	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	86	0	\N	elearning_async	2026-02-03 16:24:23.912277+01	2026-02-03 16:24:40.876491+01	0	\N	\N
343	5790	779	Management, Communication, Handicap	152	87	0	\N	elearning_async	2026-02-03 16:24:24.381571+01	2026-02-03 16:24:41.338863+01	0	\N	\N
344	5791	780	Ordonnancement, Pilotage, et Coordination	154	87	0	\N	elearning_async	2026-02-03 16:24:24.381572+01	2026-02-03 16:24:41.338863+01	0	\N	\N
345	14331	1020	DPE avec mention	116	87	0	\N	elearning_async	2026-02-03 16:24:24.381573+01	2026-02-03 16:24:41.338863+01	0	\N	\N
346	15089	1151	Point tutoré - BC01 02	118	87	0	\N	elearning_async	2026-02-03 16:24:24.381574+01	2026-02-03 16:24:41.338863+01	0	\N	\N
347	18033	1898	MAR (C&M) - Module 1 : Les prérequis	147	87	0	\N	elearning_async	2026-02-03 16:24:24.381575+01	2026-02-03 16:24:41.338863+01	0	\N	\N
348	18066	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	87	0	\N	elearning_async	2026-02-03 16:24:24.381576+01	2026-02-03 16:24:41.338863+01	0	\N	\N
349	18099	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	87	0	\N	elearning_async	2026-02-03 16:24:24.381577+01	2026-02-03 16:24:41.338863+01	0	\N	\N
350	18132	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	87	0	\N	elearning_async	2026-02-03 16:24:24.381578+01	2026-02-03 16:24:41.338863+01	0	\N	\N
351	18165	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	87	0	\N	elearning_async	2026-02-03 16:24:24.38158+01	2026-02-03 16:24:41.338863+01	0	\N	\N
360	5800	761	DPE - Sans Mention	138	88	100	2025-08-10 08:24:25+02	elearning_async	2026-02-03 16:24:24.879548+01	2026-02-03 16:24:41.775772+01	27434	2025-06-20 09:24:47+02	2025-08-10 08:24:30+02
361	5801	763	DPE - Avec Mention	139	88	0	\N	elearning_async	2026-02-03 16:24:24.879549+01	2026-02-03 16:24:41.775772+01	0	\N	\N
362	5816	750	Blocs 1 et 2 - Bienvenue !	117	88	67	2025-06-12 11:08:28+02	elearning_async	2026-02-03 16:24:24.87955+01	2026-02-03 16:24:41.775772+01	502	2025-06-12 11:00:36+02	\N
363	5817	766	[AE MI] Partie 1 : Méthodologie & Données d'entrée	141	88	100	2025-08-14 10:57:00+02	elearning_async	2026-02-03 16:24:24.879552+01	2026-02-03 16:24:41.775772+01	4348	2025-08-12 09:56:21+02	2025-08-14 11:09:07+02
364	5818	767	[AE MI] Partie 2 : Contraintes et Pathologies	142	88	100	2025-08-13 08:55:36+02	elearning_async	2026-02-03 16:24:24.879553+01	2026-02-03 16:24:41.775772+01	888	2025-08-12 15:59:08+02	2025-08-13 08:59:47+02
365	5819	768	[AE MI] Partie 3 : Conception de scénarios	143	88	100	2025-08-19 08:18:05+02	elearning_async	2026-02-03 16:24:24.879554+01	2026-02-03 16:24:41.775772+01	1640	2025-08-13 08:50:37+02	2025-08-19 08:19:14+02
366	5820	769	[AE MI] Partie 4 : Le rapport	144	88	100	2025-08-19 08:19:56+02	elearning_async	2026-02-03 16:24:24.879555+01	2026-02-03 16:24:41.775772+01	650	2025-08-14 14:49:10+02	2025-08-19 08:20:54+02
367	5821	770	[AE MI] Cas Pratique	145	88	0	\N	elearning_async	2026-02-03 16:24:24.879556+01	2026-02-03 16:24:41.775772+01	0	\N	\N
368	5822	773	Mon Accompagnateur Rénov'	146	88	0	\N	elearning_async	2026-02-03 16:24:24.879557+01	2026-02-03 16:24:41.775772+01	0	\N	\N
369	5823	777	Audit énergétique - BCT	153	88	0	\N	elearning_async	2026-02-03 16:24:24.879558+01	2026-02-03 16:24:41.775772+01	0	\N	\N
370	5824	779	Management, Communication, Handicap	152	88	0	\N	elearning_async	2026-02-03 16:24:24.879559+01	2026-02-03 16:24:41.775772+01	0	\N	\N
371	5825	780	Ordonnancement, Pilotage, et Coordination	154	88	0	\N	elearning_async	2026-02-03 16:24:24.87956+01	2026-02-03 16:24:41.775772+01	0	\N	\N
372	14332	1020	DPE avec mention	116	88	0	\N	elearning_async	2026-02-03 16:24:24.879561+01	2026-02-03 16:24:41.775772+01	0	\N	\N
373	15090	1151	Point tutoré - BC01 02	118	88	100	2025-06-12 08:55:20+02	elearning_async	2026-02-03 16:24:24.879562+01	2026-02-03 16:24:41.775772+01	9480	2025-06-10 10:48:49+02	2025-08-12 15:30:56+02
374	18034	1898	MAR (C&M) - Module 1 : Les prérequis	147	88	100	2025-08-22 10:33:35+02	elearning_async	2026-02-03 16:24:24.879563+01	2026-02-03 16:24:41.775772+01	12714	2025-08-19 08:21:21+02	2025-08-22 16:02:50+02
375	18067	1899	MAR (C&M) - Module 2 : Les techniques de rénovation énergétique	148	88	2	2025-08-20 15:48:07+02	elearning_async	2026-02-03 16:24:24.879564+01	2026-02-03 16:24:41.775772+01	493	2025-08-20 15:48:07+02	\N
376	18100	1900	MAR (C&M) - Module 3 : Le cadre juridique d'un MAR	149	88	100	2025-09-14 10:27:41+02	elearning_async	2026-02-03 16:24:24.879566+01	2026-02-03 16:24:41.775772+01	1334	2025-08-31 11:10:27+02	2025-08-31 11:11:26+02
377	18133	1901	MAR (C&M) - Module 4 : Le financement de la rénovation énergétique	150	88	100	2025-08-31 11:12:44+02	elearning_async	2026-02-03 16:24:24.879567+01	2026-02-03 16:24:41.775772+01	376	2025-08-31 11:12:41+02	2025-08-31 11:19:18+02
378	18166	1902	MAR (C&M) - Module 5 : Démo plateforme "Mon Projet Anah"	151	88	100	2025-09-16 04:54:50+02	elearning_async	2026-02-03 16:24:24.879568+01	2026-02-03 16:24:41.775772+01	262	2025-08-31 11:20:54+02	2025-08-31 11:20:55+02
1295	3612	819	Audit énergétique - BCT	183	124	0	\N	elearning_async	2026-02-03 16:24:42.136728+01	2026-02-03 16:24:42.136728+01	0	\N	\N
1296	3613	821	Ordonnancement, Pilotage, et Coordination	184	124	0	\N	elearning_async	2026-02-03 16:24:42.136729+01	2026-02-03 16:24:42.136729+01	0	\N	\N
1297	3614	793	Point tutoré - BC01 02	185	124	0	\N	elearning_async	2026-02-03 16:24:42.13673+01	2026-02-03 16:24:42.13673+01	0	\N	\N
1298	3615	808	[AE MI] Partie 2 : Contraintes et Pathologies	186	124	0	\N	elearning_async	2026-02-03 16:24:42.136731+01	2026-02-03 16:24:42.136731+01	0	\N	\N
1299	3616	794	Eco-conseiller - Module 1 : Ecosystème de l'immobilier et de l'habitat résidentiel	157	124	0	\N	elearning_async	2026-02-03 16:24:42.136732+01	2026-02-03 16:24:42.136732+01	0	\N	\N
1300	3617	809	[AE MI] Partie 3 : Conception de scénarios	160	124	0	\N	elearning_async	2026-02-03 16:24:42.136733+01	2026-02-03 16:24:42.136733+01	0	\N	\N
1301	3618	795	Eco-conseiller - Module 2 : Techniques & thermique du bâtiment	187	124	0	\N	elearning_async	2026-02-03 16:24:42.136734+01	2026-02-03 16:24:42.136735+01	0	\N	\N
1302	3619	810	[AE MI] Partie 4 : Le rapport	161	124	0	\N	elearning_async	2026-02-03 16:24:42.136735+01	2026-02-03 16:24:42.136736+01	0	\N	\N
1303	3620	796	Eco-conseiller - Module 3 : Devoir de conseil & chiffrage	188	124	0	\N	elearning_async	2026-02-03 16:24:42.136736+01	2026-02-03 16:24:42.136737+01	0	\N	\N
1304	3621	811	[AE MI] Cas Pratique	162	124	0	\N	elearning_async	2026-02-03 16:24:42.136737+01	2026-02-03 16:24:42.136738+01	0	\N	\N
1305	3622	797	Eco-conseiller - Module 4 : Aides et subventions	189	124	0	\N	elearning_async	2026-02-03 16:24:42.136738+01	2026-02-03 16:24:42.136739+01	0	\N	\N
1306	3623	798	Eco-conseiller - Module 5 : La relation client	158	124	0	\N	elearning_async	2026-02-03 16:24:42.136739+01	2026-02-03 16:24:42.13674+01	0	\N	\N
1307	3624	803	[AE] Guide du DPE	190	124	0	\N	elearning_async	2026-02-03 16:24:42.13674+01	2026-02-03 16:24:42.136741+01	0	\N	\N
1308	3625	804	DPE - Avec Mention	159	124	0	\N	elearning_async	2026-02-03 16:24:42.136742+01	2026-02-03 16:24:42.136742+01	0	\N	\N
\.


--
-- Data for Name: participant_courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.participant_courses (id, participant_id, course_id, id_lap, overall_progression, activity_status, last_activity, created_at, updated_at) FROM stdin;
7	2	7	277	95	inactive	2025-07-03 19:54:26+02	2026-02-03 16:23:56.748582+01	2026-02-03 16:24:14.053132+01
8	3	7	278	100	completed	2025-03-22 10:01:31+01	2026-02-03 16:23:56.955273+01	2026-02-03 16:24:14.288829+01
9	4	7	279	0	inactive	\N	2026-02-03 16:23:57.216106+01	2026-02-03 16:24:14.531892+01
10	5	7	310	100	completed	2025-07-04 18:01:31+02	2026-02-03 16:23:57.406225+01	2026-02-03 16:24:14.758399+01
11	6	7	714	100	completed	2025-10-13 13:59:41+02	2026-02-03 16:23:57.606703+01	2026-02-03 16:24:14.972948+01
12	9	12	305	0	inactive	\N	2026-02-03 16:23:58.973949+01	2026-02-03 16:24:16.179527+01
13	9	13	305	0	inactive	\N	2026-02-03 16:23:58.97396+01	2026-02-03 16:24:16.179527+01
14	9	14	305	0	inactive	\N	2026-02-03 16:23:58.973965+01	2026-02-03 16:24:16.179527+01
15	9	15	305	0	inactive	\N	2026-02-03 16:23:58.973969+01	2026-02-03 16:24:16.179527+01
16	9	16	305	0	inactive	\N	2026-02-03 16:23:58.973973+01	2026-02-03 16:24:16.179527+01
17	10	12	306	100	completed	2025-03-29 16:42:17+01	2026-02-03 16:23:59.276498+01	2026-02-03 16:24:16.465705+01
18	10	13	306	100	completed	2025-05-10 23:52:47+02	2026-02-03 16:23:59.27651+01	2026-02-03 16:24:16.465705+01
19	10	14	306	100	completed	2025-05-11 01:25:21+02	2026-02-03 16:23:59.276514+01	2026-02-03 16:24:16.465705+01
20	10	15	306	100	completed	2025-05-23 18:44:07+02	2026-02-03 16:23:59.276518+01	2026-02-03 16:24:16.465705+01
21	10	16	306	100	completed	2025-05-23 19:06:26+02	2026-02-03 16:23:59.276522+01	2026-02-03 16:24:16.465705+01
22	11	12	307	100	completed	2025-05-20 21:30:18+02	2026-02-03 16:23:59.576511+01	2026-02-03 16:24:16.76722+01
23	11	13	307	100	completed	2025-05-23 11:50:08+02	2026-02-03 16:23:59.576524+01	2026-02-03 16:24:16.76722+01
24	11	14	307	17	inactive	2025-05-14 20:55:01+02	2026-02-03 16:23:59.576528+01	2026-02-03 16:24:16.76722+01
25	11	15	307	100	completed	2025-05-15 14:19:51+02	2026-02-03 16:23:59.576532+01	2026-02-03 16:24:16.76722+01
26	11	16	307	100	completed	2025-05-15 14:50:44+02	2026-02-03 16:23:59.576536+01	2026-02-03 16:24:16.76722+01
27	12	12	308	100	completed	2025-04-15 15:10:07+02	2026-02-03 16:23:59.889892+01	2026-02-03 16:24:17.064569+01
28	12	13	308	100	completed	2025-05-17 11:00:47+02	2026-02-03 16:23:59.889901+01	2026-02-03 16:24:17.064569+01
29	12	14	308	100	completed	2025-05-17 19:55:19+02	2026-02-03 16:23:59.889904+01	2026-02-03 16:24:17.064569+01
30	12	15	308	100	completed	2025-05-19 14:31:29+02	2026-02-03 16:23:59.889907+01	2026-02-03 16:24:17.064569+01
31	12	16	308	100	completed	2025-05-19 15:46:38+02	2026-02-03 16:23:59.88991+01	2026-02-03 16:24:17.064569+01
32	13	12	309	100	completed	2025-04-08 15:07:44+02	2026-02-03 16:24:00.184367+01	2026-02-03 16:24:17.384123+01
33	13	13	309	100	completed	2025-04-25 08:33:15+02	2026-02-03 16:24:00.184377+01	2026-02-03 16:24:17.384123+01
34	13	14	309	7	inactive	2025-04-25 08:33:15+02	2026-02-03 16:24:00.184382+01	2026-02-03 16:24:17.384123+01
35	13	15	309	0	inactive	\N	2026-02-03 16:24:00.184387+01	2026-02-03 16:24:17.384123+01
36	13	16	309	0	inactive	\N	2026-02-03 16:24:00.18439+01	2026-02-03 16:24:17.384123+01
37	14	12	523	100	completed	2025-05-10 13:37:41+02	2026-02-03 16:24:00.485491+01	2026-02-03 16:24:17.644701+01
38	14	13	523	0	inactive	\N	2026-02-03 16:24:00.485503+01	2026-02-03 16:24:17.644701+01
39	14	14	523	0	inactive	\N	2026-02-03 16:24:00.485506+01	2026-02-03 16:24:17.644701+01
40	14	15	523	0	inactive	\N	2026-02-03 16:24:00.48551+01	2026-02-03 16:24:17.644701+01
41	14	16	523	0	inactive	\N	2026-02-03 16:24:00.485513+01	2026-02-03 16:24:17.644701+01
42	15	12	607	100	completed	2025-05-16 09:27:54+02	2026-02-03 16:24:00.805789+01	2026-02-03 16:24:17.949245+01
43	15	13	607	100	completed	2025-05-20 14:13:17+02	2026-02-03 16:24:00.805801+01	2026-02-03 16:24:17.949245+01
44	15	14	607	100	completed	2025-05-20 16:47:07+02	2026-02-03 16:24:00.805805+01	2026-02-03 16:24:17.949245+01
45	15	15	607	100	completed	2025-05-27 19:03:39+02	2026-02-03 16:24:00.805809+01	2026-02-03 16:24:17.949245+01
46	15	16	607	100	completed	2025-06-09 19:41:25+02	2026-02-03 16:24:00.805813+01	2026-02-03 16:24:17.949245+01
47	16	12	730	100	completed	2025-06-06 16:29:08+02	2026-02-03 16:24:01.130112+01	2026-02-03 16:24:18.246008+01
52	19	26	351	96	inactive	2025-10-07 14:29:49+02	2026-02-03 16:24:02.405624+01	2026-02-03 16:24:19.435035+01
53	20	26	355	100	completed	2025-07-10 15:15:58+02	2026-02-03 16:24:02.641849+01	2026-02-03 16:24:19.655151+01
54	21	26	511	3	inactive	2025-05-02 16:47:02+02	2026-02-03 16:24:02.857758+01	2026-02-03 16:24:19.882+01
55	22	26	579	90	inactive	2025-05-28 09:49:45+02	2026-02-03 16:24:03.072044+01	2026-02-03 16:24:20.126693+01
56	23	30	352	0	inactive	\N	2026-02-03 16:24:03.505532+01	2026-02-03 16:24:20.56363+01
57	25	33	371	0	inactive	\N	2026-02-03 16:24:04.343609+01	2026-02-03 16:24:21.31512+01
58	30	39	412	0	inactive	\N	2026-02-03 16:24:06.424416+01	2026-02-03 16:24:23.141312+01
59	32	42	421	0	inactive	\N	2026-02-03 16:24:07.135351+01	2026-02-03 16:24:23.95602+01
60	34	45	442	100	completed	2025-04-16 16:38:23+02	2026-02-03 16:24:07.929327+01	2026-02-03 16:24:24.846333+01
61	34	46	442	100	completed	2025-04-22 16:47:49+02	2026-02-03 16:24:07.929332+01	2026-02-03 16:24:24.846333+01
62	34	47	442	100	completed	2025-04-25 17:18:23+02	2026-02-03 16:24:07.929334+01	2026-02-03 16:24:24.846333+01
63	34	48	442	100	completed	2025-04-28 17:02:45+02	2026-02-03 16:24:07.929335+01	2026-02-03 16:24:24.846333+01
64	34	49	442	100	completed	2025-04-29 12:51:08+02	2026-02-03 16:24:07.929336+01	2026-02-03 16:24:24.846333+01
65	34	50	442	50	inactive	2025-04-29 17:45:57+02	2026-02-03 16:24:07.929338+01	2026-02-03 16:24:24.846333+01
66	34	51	442	100	completed	2025-08-01 14:44:31+02	2026-02-03 16:24:07.929339+01	2026-02-03 16:24:24.846333+01
67	34	53	442	0	inactive	\N	2026-02-03 16:24:07.92934+01	2026-02-03 16:24:24.846333+01
68	34	54	442	0	inactive	\N	2026-02-03 16:24:07.929341+01	2026-02-03 16:24:24.846333+01
69	34	55	442	0	inactive	\N	2026-02-03 16:24:07.929343+01	2026-02-03 16:24:24.846333+01
70	34	56	442	0	inactive	\N	2026-02-03 16:24:07.929344+01	2026-02-03 16:24:24.846333+01
71	35	45	520	100	completed	2025-07-16 20:15:33+02	2026-02-03 16:24:08.20428+01	2026-02-03 16:24:25.218345+01
72	35	46	520	100	completed	2025-07-23 12:13:21+02	2026-02-03 16:24:08.204285+01	2026-02-03 16:24:25.218345+01
73	35	47	520	20	inactive	2025-07-23 12:38:19+02	2026-02-03 16:24:08.204286+01	2026-02-03 16:24:25.218345+01
74	35	48	520	0	inactive	\N	2026-02-03 16:24:08.204287+01	2026-02-03 16:24:25.218345+01
75	35	49	520	0	inactive	\N	2026-02-03 16:24:08.204288+01	2026-02-03 16:24:25.218345+01
76	35	50	520	0	inactive	\N	2026-02-03 16:24:08.204289+01	2026-02-03 16:24:25.218345+01
77	35	51	520	0	inactive	\N	2026-02-03 16:24:08.20429+01	2026-02-03 16:24:25.218345+01
78	35	53	520	0	inactive	\N	2026-02-03 16:24:08.204291+01	2026-02-03 16:24:25.218345+01
79	35	54	520	0	inactive	\N	2026-02-03 16:24:08.204292+01	2026-02-03 16:24:25.218345+01
80	35	55	520	0	inactive	\N	2026-02-03 16:24:08.204293+01	2026-02-03 16:24:25.218345+01
81	35	56	520	0	inactive	\N	2026-02-03 16:24:08.204295+01	2026-02-03 16:24:25.218345+01
93	37	45	632	100	completed	2025-06-23 16:00:46+02	2026-02-03 16:24:08.710256+01	2026-02-03 16:24:25.853758+01
94	37	46	632	83	inactive	2025-07-09 18:59:06+02	2026-02-03 16:24:08.71026+01	2026-02-03 16:24:25.853758+01
95	37	47	632	0	inactive	\N	2026-02-03 16:24:08.710261+01	2026-02-03 16:24:25.853758+01
96	37	48	632	0	inactive	\N	2026-02-03 16:24:08.710263+01	2026-02-03 16:24:25.853758+01
97	37	49	632	0	inactive	\N	2026-02-03 16:24:08.710264+01	2026-02-03 16:24:25.853758+01
98	37	50	632	0	inactive	\N	2026-02-03 16:24:08.710265+01	2026-02-03 16:24:25.853758+01
99	37	51	632	0	inactive	\N	2026-02-03 16:24:08.710266+01	2026-02-03 16:24:25.853758+01
100	37	53	632	0	inactive	\N	2026-02-03 16:24:08.710267+01	2026-02-03 16:24:25.853758+01
104	38	45	986	100	completed	2025-07-01 08:04:10+02	2026-02-03 16:24:08.960046+01	2026-02-03 16:24:26.152688+01
105	38	46	986	100	completed	2025-09-12 19:27:05+02	2026-02-03 16:24:08.96005+01	2026-02-03 16:24:26.152688+01
106	38	47	986	80	inactive	2025-10-12 07:01:02+02	2026-02-03 16:24:08.960051+01	2026-02-03 16:24:26.152688+01
107	38	48	986	100	completed	2025-09-23 08:52:34+02	2026-02-03 16:24:08.960053+01	2026-02-03 16:24:26.152688+01
108	38	49	986	100	completed	2025-09-08 19:14:46+02	2026-02-03 16:24:08.960054+01	2026-02-03 16:24:26.152688+01
109	38	50	986	100	completed	2025-10-05 11:19:14+02	2026-02-03 16:24:08.960055+01	2026-02-03 16:24:26.152688+01
110	38	51	986	100	completed	2025-10-05 11:28:17+02	2026-02-03 16:24:08.960056+01	2026-02-03 16:24:26.152688+01
111	38	53	986	28	inactive	2025-10-12 07:20:55+02	2026-02-03 16:24:08.960057+01	2026-02-03 16:24:26.152688+01
112	38	54	986	100	completed	2025-10-12 09:01:29+02	2026-02-03 16:24:08.960058+01	2026-02-03 16:24:26.152688+01
113	38	55	986	0	inactive	\N	2026-02-03 16:24:08.96006+01	2026-02-03 16:24:26.152688+01
114	38	56	986	0	inactive	\N	2026-02-03 16:24:08.960061+01	2026-02-03 16:24:26.152688+01
126	40	45	1285	100	completed	2025-08-18 16:23:02+02	2026-02-03 16:24:09.438781+01	2026-02-03 16:24:26.768127+01
127	40	46	1285	100	completed	2025-09-15 15:22:40+02	2026-02-03 16:24:09.438784+01	2026-02-03 16:24:26.768127+01
128	40	47	1285	100	completed	2025-09-16 15:43:57+02	2026-02-03 16:24:09.438785+01	2026-02-03 16:24:26.768127+01
129	40	48	1285	100	completed	2025-10-07 14:19:36+02	2026-02-03 16:24:09.438786+01	2026-02-03 16:24:26.768127+01
130	40	49	1285	100	completed	2025-10-07 16:00:59+02	2026-02-03 16:24:09.438788+01	2026-02-03 16:24:26.768127+01
131	40	50	1285	100	completed	2025-10-09 15:44:44+02	2026-02-03 16:24:09.438789+01	2026-02-03 16:24:26.768127+01
132	40	51	1285	100	completed	2025-10-12 21:42:32+02	2026-02-03 16:24:09.43879+01	2026-02-03 16:24:26.768127+01
133	40	53	1285	100	completed	2025-10-23 15:57:37+02	2026-02-03 16:24:09.438791+01	2026-02-03 16:24:26.768127+01
134	40	54	1285	100	completed	2025-10-23 22:26:28+02	2026-02-03 16:24:09.438792+01	2026-02-03 16:24:26.768127+01
135	40	55	1285	100	completed	2025-10-24 16:08:17+02	2026-02-03 16:24:09.438793+01	2026-02-03 16:24:26.768127+01
136	40	56	1285	0	inactive	\N	2026-02-03 16:24:09.438794+01	2026-02-03 16:24:26.768127+01
137	41	45	1334	100	completed	2025-09-17 12:44:31+02	2026-02-03 16:24:09.706791+01	2026-02-03 16:24:27.114408+01
138	41	46	1334	100	completed	2025-07-02 10:38:17+02	2026-02-03 16:24:09.706795+01	2026-02-03 16:24:27.114408+01
139	41	47	1334	100	completed	2025-10-27 16:17:17+01	2026-02-03 16:24:09.706796+01	2026-02-03 16:24:27.114408+01
140	41	48	1334	100	completed	2025-10-06 21:24:21+02	2026-02-03 16:24:09.706797+01	2026-02-03 16:24:27.114408+01
141	41	49	1334	100	completed	2025-10-27 16:29:53+01	2026-02-03 16:24:09.706798+01	2026-02-03 16:24:27.114408+01
142	41	50	1334	100	completed	2025-10-27 16:37:30+01	2026-02-03 16:24:09.706799+01	2026-02-03 16:24:27.114408+01
143	41	51	1334	100	completed	2025-10-14 21:39:43+02	2026-02-03 16:24:09.7068+01	2026-02-03 16:24:27.114408+01
144	41	53	1334	100	completed	2025-10-05 22:27:29+02	2026-02-03 16:24:09.706801+01	2026-02-03 16:24:27.114408+01
145	41	54	1334	100	completed	2025-10-07 16:45:14+02	2026-02-03 16:24:09.706802+01	2026-02-03 16:24:27.114408+01
146	41	55	1334	50	inactive	2025-10-27 14:42:41+01	2026-02-03 16:24:09.706803+01	2026-02-03 16:24:27.114408+01
147	41	56	1334	0	inactive	\N	2026-02-03 16:24:09.706804+01	2026-02-03 16:24:27.114408+01
148	42	45	1875	0	inactive	\N	2026-02-03 16:24:09.930935+01	2026-02-03 16:24:27.433388+01
149	42	46	1875	0	inactive	\N	2026-02-03 16:24:09.930939+01	2026-02-03 16:24:27.433388+01
150	42	47	1875	0	inactive	\N	2026-02-03 16:24:09.93094+01	2026-02-03 16:24:27.433388+01
151	42	48	1875	0	inactive	\N	2026-02-03 16:24:09.930941+01	2026-02-03 16:24:27.433388+01
152	42	49	1875	0	inactive	\N	2026-02-03 16:24:09.930942+01	2026-02-03 16:24:27.433388+01
153	42	50	1875	0	inactive	\N	2026-02-03 16:24:09.930943+01	2026-02-03 16:24:27.433388+01
154	42	51	1875	0	inactive	\N	2026-02-03 16:24:09.930944+01	2026-02-03 16:24:27.433388+01
155	42	53	1875	0	inactive	\N	2026-02-03 16:24:09.930945+01	2026-02-03 16:24:27.433388+01
156	42	54	1875	0	inactive	\N	2026-02-03 16:24:09.930946+01	2026-02-03 16:24:27.433388+01
159	43	57	581	100	completed	2025-06-06 17:43:53+02	2026-02-03 16:24:10.398532+01	2026-02-03 16:24:27.89812+01
160	43	58	581	100	completed	2025-06-06 23:26:45+02	2026-02-03 16:24:10.398543+01	2026-02-03 16:24:27.89812+01
161	43	59	581	100	completed	2025-05-11 18:41:39+02	2026-02-03 16:24:10.398547+01	2026-02-03 16:24:27.89812+01
162	43	60	581	100	completed	2025-05-31 10:45:14+02	2026-02-03 16:24:10.398551+01	2026-02-03 16:24:27.89812+01
163	43	62	581	100	completed	2025-05-31 10:42:55+02	2026-02-03 16:24:10.398555+01	2026-02-03 16:24:27.89812+01
164	43	61	581	100	completed	2025-05-31 10:44:10+02	2026-02-03 16:24:10.398558+01	2026-02-03 16:24:27.89812+01
165	44	57	582	100	completed	2025-05-09 10:58:41+02	2026-02-03 16:24:10.618373+01	2026-02-03 16:24:28.168911+01
166	44	58	582	56	inactive	2025-05-21 00:01:54+02	2026-02-03 16:24:10.618376+01	2026-02-03 16:24:28.168911+01
167	44	59	582	0	inactive	\N	2026-02-03 16:24:10.618377+01	2026-02-03 16:24:28.168911+01
168	44	60	582	0	inactive	\N	2026-02-03 16:24:10.618379+01	2026-02-03 16:24:28.168911+01
1	1	3	1247	0	inactive	\N	2026-02-03 16:23:56.397522+01	2026-02-03 16:24:13.600921+01
2	1	4	1247	0	inactive	\N	2026-02-03 16:23:56.397527+01	2026-02-03 16:24:13.600921+01
3	1	2	1247	0	inactive	\N	2026-02-03 16:23:56.397528+01	2026-02-03 16:24:13.600921+01
4	1	5	1247	0	inactive	\N	2026-02-03 16:23:56.39753+01	2026-02-03 16:24:13.600921+01
5	1	1	1247	0	inactive	\N	2026-02-03 16:23:56.397531+01	2026-02-03 16:24:13.600921+01
6	1	6	1247	0	inactive	\N	2026-02-03 16:23:56.397532+01	2026-02-03 16:24:13.600921+01
48	16	13	730	100	completed	2025-06-11 07:23:07+02	2026-02-03 16:24:01.130123+01	2026-02-03 16:24:18.246008+01
49	16	14	730	3	inactive	2025-06-11 07:27:59+02	2026-02-03 16:24:01.130127+01	2026-02-03 16:24:18.246008+01
50	16	15	730	100	completed	2025-06-11 08:22:32+02	2026-02-03 16:24:01.130131+01	2026-02-03 16:24:18.246008+01
51	16	16	730	100	completed	2025-06-11 08:36:58+02	2026-02-03 16:24:01.130151+01	2026-02-03 16:24:18.246008+01
171	45	57	976	0	inactive	\N	2026-02-03 16:24:10.894071+01	2026-02-03 16:24:28.413021+01
172	45	58	976	0	inactive	\N	2026-02-03 16:24:10.894077+01	2026-02-03 16:24:28.413021+01
183	63	75	553	0	inactive	\N	2026-02-03 16:24:15.620468+01	2026-02-03 16:24:33.249367+01
184	64	77	571	100	completed	2025-12-10 09:12:19+01	2026-02-03 16:24:16.096919+01	2026-02-03 16:24:33.672361+01
185	64	79	571	0	inactive	\N	2026-02-03 16:24:16.096933+01	2026-02-03 16:24:33.672361+01
186	64	80	571	0	inactive	\N	2026-02-03 16:24:16.096938+01	2026-02-03 16:24:33.672361+01
187	64	81	571	0	inactive	\N	2026-02-03 16:24:16.096943+01	2026-02-03 16:24:33.672361+01
188	64	82	571	0	inactive	\N	2026-02-03 16:24:16.096948+01	2026-02-03 16:24:33.672361+01
189	65	77	1402	47	inactive	2025-12-09 15:00:40+01	2026-02-03 16:24:16.305026+01	2026-02-03 16:24:33.908192+01
190	65	79	1402	0	inactive	\N	2026-02-03 16:24:16.305036+01	2026-02-03 16:24:33.908192+01
191	65	80	1402	0	inactive	\N	2026-02-03 16:24:16.30504+01	2026-02-03 16:24:33.908192+01
192	65	81	1402	0	inactive	\N	2026-02-03 16:24:16.305043+01	2026-02-03 16:24:33.908192+01
193	65	82	1402	0	inactive	\N	2026-02-03 16:24:16.305046+01	2026-02-03 16:24:33.908192+01
194	66	83	575	100	completed	2025-10-28 21:47:36+01	2026-02-03 16:24:16.79058+01	2026-02-03 16:24:34.40916+01
195	66	99	575	100	completed	2025-10-28 21:45:50+01	2026-02-03 16:24:16.790586+01	2026-02-03 16:24:34.40916+01
196	66	100	575	100	completed	2025-10-28 22:03:45+01	2026-02-03 16:24:16.790587+01	2026-02-03 16:24:34.40916+01
197	66	101	575	100	completed	2025-08-21 21:45:16+02	2026-02-03 16:24:16.790588+01	2026-02-03 16:24:34.40916+01
198	66	102	575	100	completed	2025-10-28 22:10:03+01	2026-02-03 16:24:16.79059+01	2026-02-03 16:24:34.40916+01
199	66	103	575	100	completed	2025-09-12 21:24:04+02	2026-02-03 16:24:16.790591+01	2026-02-03 16:24:34.40916+01
200	67	83	637	60	inactive	2025-06-18 23:29:54+02	2026-02-03 16:24:17.106834+01	2026-02-03 16:24:34.867008+01
201	67	99	637	100	completed	2025-06-08 16:52:23+02	2026-02-03 16:24:17.106839+01	2026-02-03 16:24:34.867008+01
202	67	100	637	0	inactive	\N	2026-02-03 16:24:17.106841+01	2026-02-03 16:24:34.867008+01
203	67	101	637	0	inactive	\N	2026-02-03 16:24:17.106842+01	2026-02-03 16:24:34.867008+01
206	68	104	576	0	inactive	\N	2026-02-03 16:24:17.526077+01	2026-02-03 16:24:35.263783+01
207	69	106	586	13	inactive	2025-05-19 21:09:31+02	2026-02-03 16:24:17.970342+01	2026-02-03 16:24:35.629924+01
208	70	106	587	82	inactive	2025-06-22 18:04:25+02	2026-02-03 16:24:18.20788+01	2026-02-03 16:24:35.833122+01
209	71	106	997	100	completed	2025-07-29 10:28:58+02	2026-02-03 16:24:18.450524+01	2026-02-03 16:24:36.081689+01
210	72	106	1038	81	inactive	2025-12-26 11:35:11+01	2026-02-03 16:24:18.679751+01	2026-02-03 16:24:36.256049+01
211	73	106	1142	0	inactive	\N	2026-02-03 16:24:18.912969+01	2026-02-03 16:24:36.523343+01
212	74	106	1163	100	completed	2025-08-19 09:09:15+02	2026-02-03 16:24:19.130282+01	2026-02-03 16:24:36.715923+01
213	75	106	1164	61	inactive	2025-06-26 10:12:29+02	2026-02-03 16:24:19.346753+01	2026-02-03 16:24:36.91791+01
214	76	106	1182	0	inactive	\N	2026-02-03 16:24:19.58768+01	2026-02-03 16:24:37.119694+01
215	77	106	1246	0	inactive	\N	2026-02-03 16:24:19.797365+01	2026-02-03 16:24:37.320796+01
216	78	106	1444	0	inactive	\N	2026-02-03 16:24:20.010695+01	2026-02-03 16:24:37.572497+01
217	83	115	634	100	completed	2025-05-22 10:48:23+02	2026-02-03 16:24:22.480371+01	2026-02-03 16:24:39.953101+01
218	83	117	634	0	inactive	\N	2026-02-03 16:24:22.480376+01	2026-02-03 16:24:39.953101+01
219	83	133	634	100	completed	2025-06-23 08:53:35+02	2026-02-03 16:24:22.480378+01	2026-02-03 16:24:39.953101+01
220	83	134	634	57	inactive	2025-10-08 21:33:23+02	2026-02-03 16:24:22.480379+01	2026-02-03 16:24:39.953101+01
221	83	135	634	0	inactive	\N	2026-02-03 16:24:22.480381+01	2026-02-03 16:24:39.953101+01
222	83	136	634	0	inactive	\N	2026-02-03 16:24:22.480382+01	2026-02-03 16:24:39.953101+01
223	83	137	634	0	inactive	\N	2026-02-03 16:24:22.480383+01	2026-02-03 16:24:39.953101+01
224	83	114	634	100	completed	2025-06-17 11:13:07+02	2026-02-03 16:24:22.480385+01	2026-02-03 16:24:39.953101+01
225	83	140	634	100	completed	2025-08-13 18:53:33+02	2026-02-03 16:24:22.480386+01	2026-02-03 16:24:39.953101+01
226	83	138	634	100	completed	2025-07-17 10:58:38+02	2026-02-03 16:24:22.480387+01	2026-02-03 16:24:39.953101+01
227	83	139	634	100	completed	2025-09-03 17:15:30+02	2026-02-03 16:24:22.480389+01	2026-02-03 16:24:39.953101+01
228	83	141	634	0	inactive	\N	2026-02-03 16:24:22.48039+01	2026-02-03 16:24:39.953101+01
244	84	115	638	100	completed	2025-06-10 09:27:14+02	2026-02-03 16:24:22.988866+01	2026-02-03 16:24:40.482223+01
271	85	115	639	100	completed	2025-05-21 13:24:40+02	2026-02-03 16:24:23.475207+01	2026-02-03 16:24:40.876491+01
272	85	133	639	100	completed	2025-06-21 19:07:11+02	2026-02-03 16:24:23.475212+01	2026-02-03 16:24:40.876491+01
273	85	134	639	100	completed	2025-08-07 10:15:41+02	2026-02-03 16:24:23.475213+01	2026-02-03 16:24:40.876491+01
274	85	135	639	100	completed	2025-08-07 10:26:51+02	2026-02-03 16:24:23.475215+01	2026-02-03 16:24:40.876491+01
275	85	136	639	43	inactive	2025-08-07 11:43:29+02	2026-02-03 16:24:23.475216+01	2026-02-03 16:24:40.876491+01
276	85	137	639	0	inactive	\N	2026-02-03 16:24:23.475217+01	2026-02-03 16:24:40.876491+01
277	85	114	639	15	inactive	2025-10-10 14:29:27+02	2026-02-03 16:24:23.475219+01	2026-02-03 16:24:40.876491+01
278	85	140	639	14	inactive	2025-07-11 15:34:09+02	2026-02-03 16:24:23.47522+01	2026-02-03 16:24:40.876491+01
279	85	138	639	61	inactive	2025-07-29 14:03:41+02	2026-02-03 16:24:23.475221+01	2026-02-03 16:24:40.876491+01
280	85	139	639	15	inactive	2025-10-10 14:29:24+02	2026-02-03 16:24:23.475223+01	2026-02-03 16:24:40.876491+01
281	85	117	639	0	inactive	\N	2026-02-03 16:24:23.475224+01	2026-02-03 16:24:40.876491+01
282	85	141	639	0	inactive	\N	2026-02-03 16:24:23.475225+01	2026-02-03 16:24:40.876491+01
283	85	142	639	0	inactive	\N	2026-02-03 16:24:23.475226+01	2026-02-03 16:24:40.876491+01
284	85	143	639	0	inactive	\N	2026-02-03 16:24:23.475228+01	2026-02-03 16:24:40.876491+01
285	85	144	639	0	inactive	\N	2026-02-03 16:24:23.475229+01	2026-02-03 16:24:40.876491+01
286	85	145	639	0	inactive	\N	2026-02-03 16:24:23.47523+01	2026-02-03 16:24:40.876491+01
287	85	146	639	0	inactive	\N	2026-02-03 16:24:23.475232+01	2026-02-03 16:24:40.876491+01
288	85	153	639	0	inactive	\N	2026-02-03 16:24:23.475233+01	2026-02-03 16:24:40.876491+01
289	85	152	639	0	inactive	\N	2026-02-03 16:24:23.475235+01	2026-02-03 16:24:40.876491+01
290	85	154	639	0	inactive	\N	2026-02-03 16:24:23.475236+01	2026-02-03 16:24:40.876491+01
291	85	116	639	15	inactive	2025-09-16 10:55:14+02	2026-02-03 16:24:23.475237+01	2026-02-03 16:24:40.876491+01
292	85	118	639	0	inactive	\N	2026-02-03 16:24:23.475239+01	2026-02-03 16:24:40.876491+01
293	85	147	639	0	inactive	\N	2026-02-03 16:24:23.47524+01	2026-02-03 16:24:40.876491+01
294	85	148	639	0	inactive	\N	2026-02-03 16:24:23.475241+01	2026-02-03 16:24:40.876491+01
295	85	149	639	0	inactive	\N	2026-02-03 16:24:23.475243+01	2026-02-03 16:24:40.876491+01
298	86	115	719	67	inactive	2025-06-06 18:30:50+02	2026-02-03 16:24:23.967331+01	2026-02-03 16:24:41.338863+01
299	86	133	719	0	inactive	\N	2026-02-03 16:24:23.967337+01	2026-02-03 16:24:41.338863+01
300	86	134	719	0	inactive	\N	2026-02-03 16:24:23.967339+01	2026-02-03 16:24:41.338863+01
301	86	135	719	0	inactive	\N	2026-02-03 16:24:23.96734+01	2026-02-03 16:24:41.338863+01
302	86	136	719	0	inactive	\N	2026-02-03 16:24:23.967342+01	2026-02-03 16:24:41.338863+01
303	86	137	719	0	inactive	\N	2026-02-03 16:24:23.967343+01	2026-02-03 16:24:41.338863+01
304	86	114	719	0	inactive	\N	2026-02-03 16:24:23.967345+01	2026-02-03 16:24:41.338863+01
305	86	140	719	0	inactive	\N	2026-02-03 16:24:23.967346+01	2026-02-03 16:24:41.338863+01
306	86	138	719	0	inactive	\N	2026-02-03 16:24:23.967348+01	2026-02-03 16:24:41.338863+01
307	86	139	719	0	inactive	\N	2026-02-03 16:24:23.967349+01	2026-02-03 16:24:41.338863+01
308	86	117	719	0	inactive	\N	2026-02-03 16:24:23.967351+01	2026-02-03 16:24:41.338863+01
309	86	141	719	0	inactive	\N	2026-02-03 16:24:23.967352+01	2026-02-03 16:24:41.338863+01
310	86	142	719	0	inactive	\N	2026-02-03 16:24:23.967354+01	2026-02-03 16:24:41.338863+01
311	86	143	719	0	inactive	\N	2026-02-03 16:24:23.967355+01	2026-02-03 16:24:41.338863+01
312	86	144	719	0	inactive	\N	2026-02-03 16:24:23.967357+01	2026-02-03 16:24:41.338863+01
313	86	145	719	0	inactive	\N	2026-02-03 16:24:23.967359+01	2026-02-03 16:24:41.338863+01
314	86	146	719	0	inactive	\N	2026-02-03 16:24:23.96736+01	2026-02-03 16:24:41.338863+01
315	86	153	719	0	inactive	\N	2026-02-03 16:24:23.967362+01	2026-02-03 16:24:41.338863+01
316	86	152	719	0	inactive	\N	2026-02-03 16:24:23.967363+01	2026-02-03 16:24:41.338863+01
317	86	154	719	0	inactive	\N	2026-02-03 16:24:23.967365+01	2026-02-03 16:24:41.338863+01
318	86	116	719	0	inactive	\N	2026-02-03 16:24:23.967366+01	2026-02-03 16:24:41.338863+01
319	86	118	719	0	inactive	\N	2026-02-03 16:24:23.967368+01	2026-02-03 16:24:41.338863+01
320	86	147	719	0	inactive	\N	2026-02-03 16:24:23.967369+01	2026-02-03 16:24:41.338863+01
321	86	148	719	0	inactive	\N	2026-02-03 16:24:23.967371+01	2026-02-03 16:24:41.338863+01
322	86	149	719	0	inactive	\N	2026-02-03 16:24:23.967372+01	2026-02-03 16:24:41.338863+01
323	86	150	719	0	inactive	\N	2026-02-03 16:24:23.967374+01	2026-02-03 16:24:41.338863+01
324	86	151	719	0	inactive	\N	2026-02-03 16:24:23.967375+01	2026-02-03 16:24:41.338863+01
325	87	115	720	0	inactive	\N	2026-02-03 16:24:24.426789+01	2026-02-03 16:24:41.775772+01
326	87	133	720	100	completed	2025-05-29 10:01:15+02	2026-02-03 16:24:24.426793+01	2026-02-03 16:24:41.775772+01
327	87	134	720	80	inactive	2025-06-04 08:15:36+02	2026-02-03 16:24:24.426794+01	2026-02-03 16:24:41.775772+01
328	87	135	720	0	inactive	\N	2026-02-03 16:24:24.426796+01	2026-02-03 16:24:41.775772+01
329	87	136	720	0	inactive	\N	2026-02-03 16:24:24.426797+01	2026-02-03 16:24:41.775772+01
330	87	137	720	0	inactive	\N	2026-02-03 16:24:24.426798+01	2026-02-03 16:24:41.775772+01
331	87	114	720	0	inactive	\N	2026-02-03 16:24:24.4268+01	2026-02-03 16:24:41.775772+01
352	88	115	\N	0	inactive	\N	2026-02-03 16:24:24.900574+01	2026-02-03 16:24:24.900577+01
353	88	133	\N	100	completed	2025-06-20 08:50:55+02	2026-02-03 16:24:24.900578+01	2026-02-03 16:24:24.900578+01
354	88	134	\N	100	completed	2025-06-20 10:18:01+02	2026-02-03 16:24:24.900579+01	2026-02-03 16:24:24.900579+01
355	88	135	\N	100	completed	2025-06-19 09:48:12+02	2026-02-03 16:24:24.90058+01	2026-02-03 16:24:24.90058+01
356	88	136	\N	100	completed	2025-06-20 09:23:52+02	2026-02-03 16:24:24.900581+01	2026-02-03 16:24:24.900581+01
357	88	137	\N	100	completed	2025-06-26 16:45:59+02	2026-02-03 16:24:24.900582+01	2026-02-03 16:24:24.900582+01
358	88	114	\N	0	inactive	\N	2026-02-03 16:24:24.900583+01	2026-02-03 16:24:24.900584+01
359	88	140	\N	100	completed	2025-08-05 09:23:52+02	2026-02-03 16:24:24.900584+01	2026-02-03 16:24:24.900585+01
360	88	138	\N	100	completed	2025-08-10 08:24:25+02	2026-02-03 16:24:24.900585+01	2026-02-03 16:24:24.900586+01
361	88	139	\N	0	inactive	\N	2026-02-03 16:24:24.900586+01	2026-02-03 16:24:24.900587+01
362	88	117	\N	67	inactive	2025-06-12 11:08:28+02	2026-02-03 16:24:24.900587+01	2026-02-03 16:24:24.900588+01
363	88	141	\N	100	completed	2025-08-14 10:57:00+02	2026-02-03 16:24:24.900588+01	2026-02-03 16:24:24.900589+01
364	88	142	\N	100	completed	2025-08-13 08:55:36+02	2026-02-03 16:24:24.900589+01	2026-02-03 16:24:24.90059+01
365	88	143	\N	100	completed	2025-08-19 08:18:05+02	2026-02-03 16:24:24.90059+01	2026-02-03 16:24:24.900591+01
366	88	144	\N	100	completed	2025-08-19 08:19:56+02	2026-02-03 16:24:24.900592+01	2026-02-03 16:24:24.900592+01
367	88	145	\N	0	inactive	\N	2026-02-03 16:24:24.900593+01	2026-02-03 16:24:24.900593+01
368	88	146	\N	0	inactive	\N	2026-02-03 16:24:24.900594+01	2026-02-03 16:24:24.900594+01
369	88	153	\N	0	inactive	\N	2026-02-03 16:24:24.900595+01	2026-02-03 16:24:24.900595+01
370	88	152	\N	0	inactive	\N	2026-02-03 16:24:24.900596+01	2026-02-03 16:24:24.900597+01
371	88	154	\N	0	inactive	\N	2026-02-03 16:24:24.900597+01	2026-02-03 16:24:24.900598+01
372	88	116	\N	0	inactive	\N	2026-02-03 16:24:24.900598+01	2026-02-03 16:24:24.900599+01
373	88	118	\N	100	completed	2025-06-12 08:55:20+02	2026-02-03 16:24:24.900599+01	2026-02-03 16:24:24.9006+01
374	88	147	\N	100	completed	2025-08-22 10:33:35+02	2026-02-03 16:24:24.9006+01	2026-02-03 16:24:24.900601+01
375	88	148	\N	2	inactive	2025-08-20 15:48:07+02	2026-02-03 16:24:24.900601+01	2026-02-03 16:24:24.900602+01
376	88	149	\N	100	completed	2025-09-14 10:27:41+02	2026-02-03 16:24:24.900602+01	2026-02-03 16:24:24.900603+01
377	88	150	\N	100	completed	2025-08-31 11:12:44+02	2026-02-03 16:24:24.900603+01	2026-02-03 16:24:24.900604+01
378	88	151	\N	100	completed	2025-09-16 04:54:50+02	2026-02-03 16:24:24.900604+01	2026-02-03 16:24:24.900605+01
379	89	115	\N	100	completed	2025-05-30 13:12:44+02	2026-02-03 16:24:25.379264+01	2026-02-03 16:24:25.379268+01
380	89	133	\N	100	completed	2025-06-30 14:26:24+02	2026-02-03 16:24:25.379269+01	2026-02-03 16:24:25.379269+01
381	89	134	\N	23	inactive	2025-06-30 14:45:47+02	2026-02-03 16:24:25.37927+01	2026-02-03 16:24:25.379271+01
382	89	135	\N	0	inactive	\N	2026-02-03 16:24:25.379271+01	2026-02-03 16:24:25.379272+01
383	89	136	\N	0	inactive	\N	2026-02-03 16:24:25.379272+01	2026-02-03 16:24:25.379273+01
384	89	137	\N	0	inactive	\N	2026-02-03 16:24:25.379273+01	2026-02-03 16:24:25.379274+01
385	89	114	\N	90	inactive	2025-10-02 13:17:50+02	2026-02-03 16:24:25.379274+01	2026-02-03 16:24:25.379275+01
386	89	140	\N	100	completed	2025-10-01 13:14:06+02	2026-02-03 16:24:25.379275+01	2026-02-03 16:24:25.379276+01
387	89	138	\N	100	completed	2025-10-02 13:04:37+02	2026-02-03 16:24:25.379277+01	2026-02-03 16:24:25.379277+01
388	89	139	\N	8	inactive	2025-07-31 11:45:28+02	2026-02-03 16:24:25.379278+01	2026-02-03 16:24:25.379278+01
389	89	117	\N	0	inactive	\N	2026-02-03 16:24:25.379279+01	2026-02-03 16:24:25.379279+01
390	89	141	\N	100	completed	2025-08-09 13:56:55+02	2026-02-03 16:24:25.37928+01	2026-02-03 16:24:25.37928+01
391	89	142	\N	100	completed	2025-08-11 11:46:28+02	2026-02-03 16:24:25.379281+01	2026-02-03 16:24:25.379281+01
392	89	143	\N	100	completed	2025-08-20 12:45:01+02	2026-02-03 16:24:25.379282+01	2026-02-03 16:24:25.379283+01
393	89	144	\N	100	completed	2025-08-24 17:46:17+02	2026-02-03 16:24:25.379283+01	2026-02-03 16:24:25.379284+01
394	89	145	\N	0	inactive	\N	2026-02-03 16:24:25.379284+01	2026-02-03 16:24:25.379285+01
395	89	146	\N	0	inactive	\N	2026-02-03 16:24:25.379285+01	2026-02-03 16:24:25.379286+01
396	89	153	\N	20	inactive	2025-12-14 08:01:52+01	2026-02-03 16:24:25.379286+01	2026-02-03 16:24:25.379287+01
397	89	152	\N	13	inactive	2025-12-24 16:17:30+01	2026-02-03 16:24:25.379288+01	2026-02-03 16:24:25.379288+01
398	89	154	\N	0	inactive	\N	2026-02-03 16:24:25.379289+01	2026-02-03 16:24:25.379289+01
399	89	116	\N	5	inactive	2025-07-20 17:56:37+02	2026-02-03 16:24:25.37929+01	2026-02-03 16:24:25.37929+01
400	89	118	\N	0	inactive	\N	2026-02-03 16:24:25.379291+01	2026-02-03 16:24:25.379291+01
401	89	147	\N	95	inactive	2025-09-23 17:47:56+02	2026-02-03 16:24:25.379292+01	2026-02-03 16:24:25.379293+01
402	89	148	\N	0	inactive	\N	2026-02-03 16:24:25.379293+01	2026-02-03 16:24:25.379294+01
403	89	149	\N	0	inactive	\N	2026-02-03 16:24:25.379294+01	2026-02-03 16:24:25.379295+01
404	89	150	\N	0	inactive	\N	2026-02-03 16:24:25.379295+01	2026-02-03 16:24:25.379296+01
405	89	151	\N	0	inactive	\N	2026-02-03 16:24:25.379296+01	2026-02-03 16:24:25.379297+01
406	90	115	\N	100	completed	2025-05-27 10:02:01+02	2026-02-03 16:24:25.87755+01	2026-02-03 16:24:25.877554+01
407	90	133	\N	100	completed	2025-06-04 16:06:39+02	2026-02-03 16:24:25.877555+01	2026-02-03 16:24:25.877555+01
408	90	134	\N	100	completed	2025-06-19 10:12:59+02	2026-02-03 16:24:25.877556+01	2026-02-03 16:24:25.877556+01
409	90	135	\N	100	completed	2026-01-25 15:23:40+01	2026-02-03 16:24:25.877557+01	2026-02-03 16:24:25.877557+01
410	90	136	\N	100	completed	2025-06-21 08:34:38+02	2026-02-03 16:24:25.877558+01	2026-02-03 16:24:25.877559+01
411	90	137	\N	100	completed	2025-06-21 09:15:30+02	2026-02-03 16:24:25.877559+01	2026-02-03 16:24:25.87756+01
412	90	114	\N	100	completed	2025-06-09 09:37:57+02	2026-02-03 16:24:25.87756+01	2026-02-03 16:24:25.877561+01
413	90	140	\N	100	completed	2025-09-19 09:13:54+02	2026-02-03 16:24:25.877561+01	2026-02-03 16:24:25.877562+01
414	90	138	\N	100	completed	2025-12-15 11:32:23+01	2026-02-03 16:24:25.877562+01	2026-02-03 16:24:25.877563+01
415	90	139	\N	100	completed	2025-09-14 10:13:13+02	2026-02-03 16:24:25.877563+01	2026-02-03 16:24:25.877564+01
416	90	117	\N	0	inactive	\N	2026-02-03 16:24:25.877565+01	2026-02-03 16:24:25.877565+01
82	36	45	592	50	inactive	2025-06-25 22:29:42+02	2026-02-03 16:24:08.480362+01	2026-02-03 16:24:25.535538+01
83	36	46	592	0	inactive	\N	2026-02-03 16:24:08.480367+01	2026-02-03 16:24:25.535538+01
84	36	47	592	0	inactive	\N	2026-02-03 16:24:08.480369+01	2026-02-03 16:24:25.535538+01
85	36	48	592	0	inactive	\N	2026-02-03 16:24:08.480371+01	2026-02-03 16:24:25.535538+01
86	36	49	592	0	inactive	\N	2026-02-03 16:24:08.480373+01	2026-02-03 16:24:25.535538+01
87	36	50	592	0	inactive	\N	2026-02-03 16:24:08.480375+01	2026-02-03 16:24:25.535538+01
88	36	51	592	0	inactive	\N	2026-02-03 16:24:08.480377+01	2026-02-03 16:24:25.535538+01
89	36	53	592	0	inactive	\N	2026-02-03 16:24:08.480379+01	2026-02-03 16:24:25.535538+01
90	36	54	592	0	inactive	\N	2026-02-03 16:24:08.480381+01	2026-02-03 16:24:25.535538+01
91	36	55	592	0	inactive	\N	2026-02-03 16:24:08.480383+01	2026-02-03 16:24:25.535538+01
92	36	56	592	0	inactive	\N	2026-02-03 16:24:08.480385+01	2026-02-03 16:24:25.535538+01
101	37	54	632	0	inactive	\N	2026-02-03 16:24:08.710268+01	2026-02-03 16:24:25.853758+01
102	37	55	632	0	inactive	\N	2026-02-03 16:24:08.710269+01	2026-02-03 16:24:25.853758+01
103	37	56	632	0	inactive	\N	2026-02-03 16:24:08.71027+01	2026-02-03 16:24:25.853758+01
115	39	45	1178	100	completed	2025-07-07 18:37:11+02	2026-02-03 16:24:09.186695+01	2026-02-03 16:24:26.468276+01
116	39	46	1178	100	completed	2025-07-07 19:11:38+02	2026-02-03 16:24:09.1867+01	2026-02-03 16:24:26.468276+01
117	39	47	1178	80	inactive	2025-07-29 18:36:05+02	2026-02-03 16:24:09.186701+01	2026-02-03 16:24:26.468276+01
118	39	48	1178	0	inactive	\N	2026-02-03 16:24:09.186702+01	2026-02-03 16:24:26.468276+01
119	39	49	1178	0	inactive	\N	2026-02-03 16:24:09.186703+01	2026-02-03 16:24:26.468276+01
120	39	50	1178	100	completed	2025-07-29 21:00:53+02	2026-02-03 16:24:09.186704+01	2026-02-03 16:24:26.468276+01
121	39	51	1178	100	completed	2025-08-09 12:58:46+02	2026-02-03 16:24:09.186705+01	2026-02-03 16:24:26.468276+01
122	39	53	1178	85	inactive	2025-08-23 08:15:57+02	2026-02-03 16:24:09.186706+01	2026-02-03 16:24:26.468276+01
123	39	54	1178	0	inactive	\N	2026-02-03 16:24:09.186707+01	2026-02-03 16:24:26.468276+01
124	39	55	1178	0	inactive	\N	2026-02-03 16:24:09.186708+01	2026-02-03 16:24:26.468276+01
125	39	56	1178	0	inactive	\N	2026-02-03 16:24:09.186709+01	2026-02-03 16:24:26.468276+01
157	42	55	1875	0	inactive	\N	2026-02-03 16:24:09.930947+01	2026-02-03 16:24:27.433388+01
158	42	56	1875	0	inactive	\N	2026-02-03 16:24:09.930948+01	2026-02-03 16:24:27.433388+01
169	44	62	582	0	inactive	\N	2026-02-03 16:24:10.61838+01	2026-02-03 16:24:28.168911+01
170	44	61	582	0	inactive	\N	2026-02-03 16:24:10.618381+01	2026-02-03 16:24:28.168911+01
173	45	59	976	0	inactive	\N	2026-02-03 16:24:10.894079+01	2026-02-03 16:24:28.413021+01
174	45	60	976	0	inactive	\N	2026-02-03 16:24:10.894081+01	2026-02-03 16:24:28.413021+01
175	45	61	976	0	inactive	\N	2026-02-03 16:24:10.894083+01	2026-02-03 16:24:28.413021+01
176	45	62	976	0	inactive	\N	2026-02-03 16:24:10.894085+01	2026-02-03 16:24:28.413021+01
177	46	57	981	0	inactive	\N	2026-02-03 16:24:11.162555+01	2026-02-03 16:24:28.67853+01
178	46	58	981	0	inactive	\N	2026-02-03 16:24:11.162567+01	2026-02-03 16:24:28.67853+01
179	46	59	981	0	inactive	\N	2026-02-03 16:24:11.162572+01	2026-02-03 16:24:28.67853+01
180	46	60	981	0	inactive	\N	2026-02-03 16:24:11.162575+01	2026-02-03 16:24:28.67853+01
181	46	61	981	0	inactive	\N	2026-02-03 16:24:11.162579+01	2026-02-03 16:24:28.67853+01
182	46	62	981	0	inactive	\N	2026-02-03 16:24:11.162583+01	2026-02-03 16:24:28.67853+01
204	67	102	637	0	inactive	\N	2026-02-03 16:24:17.106843+01	2026-02-03 16:24:34.867008+01
205	67	103	637	0	inactive	\N	2026-02-03 16:24:17.106845+01	2026-02-03 16:24:34.867008+01
229	83	142	634	0	inactive	\N	2026-02-03 16:24:22.480391+01	2026-02-03 16:24:39.953101+01
230	83	143	634	0	inactive	\N	2026-02-03 16:24:22.480393+01	2026-02-03 16:24:39.953101+01
231	83	144	634	0	inactive	\N	2026-02-03 16:24:22.480395+01	2026-02-03 16:24:39.953101+01
232	83	145	634	0	inactive	\N	2026-02-03 16:24:22.480396+01	2026-02-03 16:24:39.953101+01
233	83	146	634	0	inactive	\N	2026-02-03 16:24:22.480397+01	2026-02-03 16:24:39.953101+01
234	83	153	634	0	inactive	\N	2026-02-03 16:24:22.480399+01	2026-02-03 16:24:39.953101+01
235	83	152	634	0	inactive	\N	2026-02-03 16:24:22.4804+01	2026-02-03 16:24:39.953101+01
236	83	154	634	0	inactive	\N	2026-02-03 16:24:22.480401+01	2026-02-03 16:24:39.953101+01
237	83	116	634	100	completed	2025-09-03 18:04:01+02	2026-02-03 16:24:22.480403+01	2026-02-03 16:24:39.953101+01
238	83	118	634	0	inactive	\N	2026-02-03 16:24:22.480404+01	2026-02-03 16:24:39.953101+01
239	83	147	634	0	inactive	\N	2026-02-03 16:24:22.480405+01	2026-02-03 16:24:39.953101+01
240	83	148	634	0	inactive	\N	2026-02-03 16:24:22.480407+01	2026-02-03 16:24:39.953101+01
241	83	149	634	0	inactive	\N	2026-02-03 16:24:22.480408+01	2026-02-03 16:24:39.953101+01
242	83	150	634	0	inactive	\N	2026-02-03 16:24:22.48041+01	2026-02-03 16:24:39.953101+01
243	83	151	634	0	inactive	\N	2026-02-03 16:24:22.480411+01	2026-02-03 16:24:39.953101+01
245	84	133	638	0	inactive	\N	2026-02-03 16:24:22.988871+01	2026-02-03 16:24:40.482223+01
246	84	134	638	0	inactive	\N	2026-02-03 16:24:22.988873+01	2026-02-03 16:24:40.482223+01
247	84	135	638	0	inactive	\N	2026-02-03 16:24:22.988874+01	2026-02-03 16:24:40.482223+01
248	84	136	638	0	inactive	\N	2026-02-03 16:24:22.988876+01	2026-02-03 16:24:40.482223+01
249	84	137	638	0	inactive	\N	2026-02-03 16:24:22.988877+01	2026-02-03 16:24:40.482223+01
250	84	114	638	18	inactive	2025-06-10 10:22:46+02	2026-02-03 16:24:22.988878+01	2026-02-03 16:24:40.482223+01
251	84	140	638	0	inactive	\N	2026-02-03 16:24:22.988879+01	2026-02-03 16:24:40.482223+01
252	84	138	638	0	inactive	\N	2026-02-03 16:24:22.98888+01	2026-02-03 16:24:40.482223+01
253	84	139	638	0	inactive	\N	2026-02-03 16:24:22.988882+01	2026-02-03 16:24:40.482223+01
254	84	117	638	0	inactive	\N	2026-02-03 16:24:22.988883+01	2026-02-03 16:24:40.482223+01
255	84	141	638	0	inactive	\N	2026-02-03 16:24:22.988884+01	2026-02-03 16:24:40.482223+01
256	84	142	638	0	inactive	\N	2026-02-03 16:24:22.988885+01	2026-02-03 16:24:40.482223+01
257	84	143	638	0	inactive	\N	2026-02-03 16:24:22.988887+01	2026-02-03 16:24:40.482223+01
258	84	144	638	0	inactive	\N	2026-02-03 16:24:22.988888+01	2026-02-03 16:24:40.482223+01
259	84	145	638	0	inactive	\N	2026-02-03 16:24:22.988889+01	2026-02-03 16:24:40.482223+01
260	84	146	638	0	inactive	\N	2026-02-03 16:24:22.98889+01	2026-02-03 16:24:40.482223+01
261	84	153	638	0	inactive	\N	2026-02-03 16:24:22.988892+01	2026-02-03 16:24:40.482223+01
262	84	152	638	0	inactive	\N	2026-02-03 16:24:22.988893+01	2026-02-03 16:24:40.482223+01
263	84	154	638	0	inactive	\N	2026-02-03 16:24:22.988894+01	2026-02-03 16:24:40.482223+01
264	84	116	638	0	inactive	\N	2026-02-03 16:24:22.988896+01	2026-02-03 16:24:40.482223+01
265	84	118	638	0	inactive	\N	2026-02-03 16:24:22.988897+01	2026-02-03 16:24:40.482223+01
266	84	147	638	0	inactive	\N	2026-02-03 16:24:22.988898+01	2026-02-03 16:24:40.482223+01
267	84	148	638	0	inactive	\N	2026-02-03 16:24:22.988899+01	2026-02-03 16:24:40.482223+01
268	84	149	638	0	inactive	\N	2026-02-03 16:24:22.988901+01	2026-02-03 16:24:40.482223+01
269	84	150	638	0	inactive	\N	2026-02-03 16:24:22.988902+01	2026-02-03 16:24:40.482223+01
270	84	151	638	0	inactive	\N	2026-02-03 16:24:22.988903+01	2026-02-03 16:24:40.482223+01
296	85	150	639	0	inactive	\N	2026-02-03 16:24:23.475244+01	2026-02-03 16:24:40.876491+01
297	85	151	639	0	inactive	\N	2026-02-03 16:24:23.475246+01	2026-02-03 16:24:40.876491+01
332	87	140	720	0	inactive	\N	2026-02-03 16:24:24.426801+01	2026-02-03 16:24:41.775772+01
333	87	138	720	0	inactive	\N	2026-02-03 16:24:24.426802+01	2026-02-03 16:24:41.775772+01
334	87	139	720	0	inactive	\N	2026-02-03 16:24:24.426803+01	2026-02-03 16:24:41.775772+01
417	90	141	\N	100	completed	2025-08-06 15:10:19+02	2026-02-03 16:24:25.877566+01	2026-02-03 16:24:25.877566+01
418	90	142	\N	100	completed	2025-08-02 17:52:05+02	2026-02-03 16:24:25.877567+01	2026-02-03 16:24:25.877567+01
419	90	143	\N	100	completed	2026-01-12 09:23:03+01	2026-02-03 16:24:25.877568+01	2026-02-03 16:24:25.877568+01
420	90	144	\N	100	completed	2025-08-03 13:51:33+02	2026-02-03 16:24:25.877569+01	2026-02-03 16:24:25.87757+01
421	90	145	\N	100	completed	2025-08-06 21:26:30+02	2026-02-03 16:24:25.87757+01	2026-02-03 16:24:25.877571+01
422	90	146	\N	0	inactive	\N	2026-02-03 16:24:25.877571+01	2026-02-03 16:24:25.877572+01
423	90	153	\N	100	completed	2026-01-12 09:21:50+01	2026-02-03 16:24:25.877573+01	2026-02-03 16:24:25.877573+01
424	90	152	\N	25	inactive	2025-10-20 15:42:07+02	2026-02-03 16:24:25.877574+01	2026-02-03 16:24:25.877574+01
425	90	154	\N	0	inactive	\N	2026-02-03 16:24:25.877575+01	2026-02-03 16:24:25.877575+01
426	90	116	\N	100	completed	2025-09-14 10:25:58+02	2026-02-03 16:24:25.877576+01	2026-02-03 16:24:25.877576+01
427	90	118	\N	0	inactive	\N	2026-02-03 16:24:25.877577+01	2026-02-03 16:24:25.877577+01
428	90	147	\N	100	completed	2025-09-04 11:53:04+02	2026-02-03 16:24:25.877578+01	2026-02-03 16:24:25.877579+01
429	90	148	\N	100	completed	2025-09-13 11:23:10+02	2026-02-03 16:24:25.877579+01	2026-02-03 16:24:25.87758+01
430	90	149	\N	100	completed	2025-09-12 14:00:09+02	2026-02-03 16:24:25.87758+01	2026-02-03 16:24:25.877581+01
431	90	150	\N	100	completed	2025-09-13 09:13:15+02	2026-02-03 16:24:25.877582+01	2026-02-03 16:24:25.877582+01
432	90	151	\N	100	completed	2025-09-13 11:20:11+02	2026-02-03 16:24:25.877583+01	2026-02-03 16:24:25.877583+01
433	91	115	\N	100	completed	2025-06-06 14:11:41+02	2026-02-03 16:24:26.357045+01	2026-02-03 16:24:26.357048+01
434	91	133	\N	23	inactive	2025-06-24 17:27:03+02	2026-02-03 16:24:26.357049+01	2026-02-03 16:24:26.35705+01
435	91	134	\N	0	inactive	\N	2026-02-03 16:24:26.35705+01	2026-02-03 16:24:26.357051+01
436	91	135	\N	0	inactive	\N	2026-02-03 16:24:26.357052+01	2026-02-03 16:24:26.357052+01
437	91	136	\N	0	inactive	\N	2026-02-03 16:24:26.357053+01	2026-02-03 16:24:26.357053+01
438	91	137	\N	0	inactive	\N	2026-02-03 16:24:26.357054+01	2026-02-03 16:24:26.357055+01
439	91	114	\N	0	inactive	\N	2026-02-03 16:24:26.357055+01	2026-02-03 16:24:26.357056+01
440	91	140	\N	0	inactive	\N	2026-02-03 16:24:26.357056+01	2026-02-03 16:24:26.357057+01
441	91	138	\N	0	inactive	\N	2026-02-03 16:24:26.357058+01	2026-02-03 16:24:26.357058+01
442	91	139	\N	0	inactive	\N	2026-02-03 16:24:26.357059+01	2026-02-03 16:24:26.357059+01
443	91	117	\N	0	inactive	\N	2026-02-03 16:24:26.35706+01	2026-02-03 16:24:26.357061+01
444	91	141	\N	0	inactive	\N	2026-02-03 16:24:26.357061+01	2026-02-03 16:24:26.357062+01
445	91	142	\N	0	inactive	\N	2026-02-03 16:24:26.357063+01	2026-02-03 16:24:26.357063+01
446	91	143	\N	0	inactive	\N	2026-02-03 16:24:26.357064+01	2026-02-03 16:24:26.357064+01
447	91	144	\N	0	inactive	\N	2026-02-03 16:24:26.357065+01	2026-02-03 16:24:26.357066+01
448	91	145	\N	0	inactive	\N	2026-02-03 16:24:26.357066+01	2026-02-03 16:24:26.357067+01
449	91	146	\N	0	inactive	\N	2026-02-03 16:24:26.357068+01	2026-02-03 16:24:26.357068+01
450	91	153	\N	0	inactive	\N	2026-02-03 16:24:26.357069+01	2026-02-03 16:24:26.35707+01
451	91	152	\N	0	inactive	\N	2026-02-03 16:24:26.35707+01	2026-02-03 16:24:26.357071+01
452	91	154	\N	0	inactive	\N	2026-02-03 16:24:26.357071+01	2026-02-03 16:24:26.357072+01
453	91	116	\N	0	inactive	\N	2026-02-03 16:24:26.357073+01	2026-02-03 16:24:26.357073+01
454	91	118	\N	0	inactive	\N	2026-02-03 16:24:26.357074+01	2026-02-03 16:24:26.357074+01
455	91	147	\N	0	inactive	\N	2026-02-03 16:24:26.357075+01	2026-02-03 16:24:26.357076+01
456	91	148	\N	0	inactive	\N	2026-02-03 16:24:26.357076+01	2026-02-03 16:24:26.357077+01
457	91	149	\N	0	inactive	\N	2026-02-03 16:24:26.357078+01	2026-02-03 16:24:26.357078+01
458	91	150	\N	0	inactive	\N	2026-02-03 16:24:26.357079+01	2026-02-03 16:24:26.35708+01
459	91	151	\N	0	inactive	\N	2026-02-03 16:24:26.35708+01	2026-02-03 16:24:26.357081+01
460	92	115	\N	100	completed	2025-06-11 08:16:21+02	2026-02-03 16:24:26.821212+01	2026-02-03 16:24:26.821215+01
461	92	133	\N	27	inactive	2025-10-23 14:07:04+02	2026-02-03 16:24:26.821216+01	2026-02-03 16:24:26.821216+01
462	92	134	\N	0	inactive	\N	2026-02-03 16:24:26.821217+01	2026-02-03 16:24:26.821217+01
463	92	135	\N	0	inactive	\N	2026-02-03 16:24:26.821218+01	2026-02-03 16:24:26.821218+01
464	92	136	\N	0	inactive	\N	2026-02-03 16:24:26.821219+01	2026-02-03 16:24:26.82122+01
465	92	137	\N	0	inactive	\N	2026-02-03 16:24:26.82122+01	2026-02-03 16:24:26.821221+01
466	92	114	\N	100	completed	2025-10-24 10:39:42+02	2026-02-03 16:24:26.821221+01	2026-02-03 16:24:26.821222+01
467	92	140	\N	82	inactive	2025-09-03 15:33:04+02	2026-02-03 16:24:26.821222+01	2026-02-03 16:24:26.821223+01
468	92	138	\N	37	inactive	2025-10-24 10:39:24+02	2026-02-03 16:24:26.821224+01	2026-02-03 16:24:26.821224+01
469	92	139	\N	0	inactive	\N	2026-02-03 16:24:26.821225+01	2026-02-03 16:24:26.821225+01
470	92	117	\N	0	inactive	\N	2026-02-03 16:24:26.821226+01	2026-02-03 16:24:26.821226+01
471	92	141	\N	0	inactive	\N	2026-02-03 16:24:26.821227+01	2026-02-03 16:24:26.821227+01
472	92	142	\N	0	inactive	\N	2026-02-03 16:24:26.821228+01	2026-02-03 16:24:26.821229+01
473	92	143	\N	0	inactive	\N	2026-02-03 16:24:26.821229+01	2026-02-03 16:24:26.82123+01
474	92	144	\N	0	inactive	\N	2026-02-03 16:24:26.82123+01	2026-02-03 16:24:26.821231+01
475	92	145	\N	0	inactive	\N	2026-02-03 16:24:26.821231+01	2026-02-03 16:24:26.821232+01
476	92	146	\N	0	inactive	\N	2026-02-03 16:24:26.821232+01	2026-02-03 16:24:26.821233+01
477	92	153	\N	70	inactive	2025-10-04 11:34:02+02	2026-02-03 16:24:26.821234+01	2026-02-03 16:24:26.821234+01
478	92	152	\N	0	inactive	\N	2026-02-03 16:24:26.821235+01	2026-02-03 16:24:26.821235+01
479	92	154	\N	0	inactive	\N	2026-02-03 16:24:26.821236+01	2026-02-03 16:24:26.821236+01
480	92	116	\N	0	inactive	\N	2026-02-03 16:24:26.821237+01	2026-02-03 16:24:26.821237+01
481	92	118	\N	0	inactive	\N	2026-02-03 16:24:26.821238+01	2026-02-03 16:24:26.821239+01
482	92	147	\N	0	inactive	\N	2026-02-03 16:24:26.821239+01	2026-02-03 16:24:26.82124+01
483	92	148	\N	0	inactive	\N	2026-02-03 16:24:26.82124+01	2026-02-03 16:24:26.821241+01
484	92	149	\N	0	inactive	\N	2026-02-03 16:24:26.821241+01	2026-02-03 16:24:26.821242+01
485	92	150	\N	0	inactive	\N	2026-02-03 16:24:26.821242+01	2026-02-03 16:24:26.821243+01
486	92	151	\N	0	inactive	\N	2026-02-03 16:24:26.821244+01	2026-02-03 16:24:26.821244+01
487	93	115	\N	67	inactive	2025-06-06 09:12:17+02	2026-02-03 16:24:27.283944+01	2026-02-03 16:24:27.283947+01
488	93	133	\N	0	inactive	\N	2026-02-03 16:24:27.283948+01	2026-02-03 16:24:27.283949+01
489	93	134	\N	0	inactive	\N	2026-02-03 16:24:27.283949+01	2026-02-03 16:24:27.28395+01
490	93	135	\N	0	inactive	\N	2026-02-03 16:24:27.283951+01	2026-02-03 16:24:27.283951+01
491	93	136	\N	0	inactive	\N	2026-02-03 16:24:27.283952+01	2026-02-03 16:24:27.283952+01
492	93	137	\N	0	inactive	\N	2026-02-03 16:24:27.283953+01	2026-02-03 16:24:27.283953+01
493	93	114	\N	0	inactive	\N	2026-02-03 16:24:27.283954+01	2026-02-03 16:24:27.283954+01
494	93	140	\N	0	inactive	\N	2026-02-03 16:24:27.283955+01	2026-02-03 16:24:27.283956+01
495	93	138	\N	0	inactive	\N	2026-02-03 16:24:27.283956+01	2026-02-03 16:24:27.283957+01
496	93	139	\N	0	inactive	\N	2026-02-03 16:24:27.283957+01	2026-02-03 16:24:27.283958+01
497	93	117	\N	0	inactive	\N	2026-02-03 16:24:27.283958+01	2026-02-03 16:24:27.283959+01
498	93	141	\N	0	inactive	\N	2026-02-03 16:24:27.283959+01	2026-02-03 16:24:27.28396+01
499	93	142	\N	0	inactive	\N	2026-02-03 16:24:27.28396+01	2026-02-03 16:24:27.283961+01
500	93	143	\N	0	inactive	\N	2026-02-03 16:24:27.283961+01	2026-02-03 16:24:27.283962+01
501	93	144	\N	0	inactive	\N	2026-02-03 16:24:27.283962+01	2026-02-03 16:24:27.283963+01
502	93	145	\N	0	inactive	\N	2026-02-03 16:24:27.283963+01	2026-02-03 16:24:27.283964+01
503	93	146	\N	0	inactive	\N	2026-02-03 16:24:27.283965+01	2026-02-03 16:24:27.283965+01
504	93	153	\N	0	inactive	\N	2026-02-03 16:24:27.283966+01	2026-02-03 16:24:27.283966+01
505	93	152	\N	0	inactive	\N	2026-02-03 16:24:27.283967+01	2026-02-03 16:24:27.283967+01
506	93	154	\N	0	inactive	\N	2026-02-03 16:24:27.283968+01	2026-02-03 16:24:27.283968+01
507	93	116	\N	0	inactive	\N	2026-02-03 16:24:27.283969+01	2026-02-03 16:24:27.283969+01
508	93	118	\N	0	inactive	\N	2026-02-03 16:24:27.28397+01	2026-02-03 16:24:27.28397+01
509	93	147	\N	0	inactive	\N	2026-02-03 16:24:27.283971+01	2026-02-03 16:24:27.283972+01
510	93	148	\N	0	inactive	\N	2026-02-03 16:24:27.283972+01	2026-02-03 16:24:27.283973+01
511	93	149	\N	0	inactive	\N	2026-02-03 16:24:27.283973+01	2026-02-03 16:24:27.283974+01
512	93	150	\N	0	inactive	\N	2026-02-03 16:24:27.283975+01	2026-02-03 16:24:27.283975+01
513	93	151	\N	0	inactive	\N	2026-02-03 16:24:27.283976+01	2026-02-03 16:24:27.283976+01
514	94	115	\N	100	completed	2025-06-06 10:47:00+02	2026-02-03 16:24:27.731324+01	2026-02-03 16:24:27.731327+01
515	94	133	\N	38	inactive	2025-10-03 08:47:48+02	2026-02-03 16:24:27.731328+01	2026-02-03 16:24:27.731328+01
516	94	134	\N	3	inactive	2025-05-26 10:48:49+02	2026-02-03 16:24:27.731329+01	2026-02-03 16:24:27.73133+01
517	94	135	\N	0	inactive	\N	2026-02-03 16:24:27.73133+01	2026-02-03 16:24:27.731331+01
518	94	136	\N	0	inactive	\N	2026-02-03 16:24:27.731331+01	2026-02-03 16:24:27.731332+01
519	94	137	\N	0	inactive	\N	2026-02-03 16:24:27.731332+01	2026-02-03 16:24:27.731333+01
520	94	114	\N	3	inactive	2025-10-22 11:06:43+02	2026-02-03 16:24:27.731333+01	2026-02-03 16:24:27.731334+01
521	94	140	\N	99	inactive	2025-10-02 21:58:29+02	2026-02-03 16:24:27.731334+01	2026-02-03 16:24:27.731335+01
522	94	138	\N	39	inactive	2025-08-06 09:52:05+02	2026-02-03 16:24:27.731336+01	2026-02-03 16:24:27.731336+01
523	94	139	\N	8	inactive	2025-08-12 12:05:13+02	2026-02-03 16:24:27.731337+01	2026-02-03 16:24:27.731337+01
524	94	117	\N	0	inactive	\N	2026-02-03 16:24:27.731338+01	2026-02-03 16:24:27.731338+01
525	94	141	\N	0	inactive	\N	2026-02-03 16:24:27.731339+01	2026-02-03 16:24:27.731339+01
526	94	142	\N	0	inactive	\N	2026-02-03 16:24:27.73134+01	2026-02-03 16:24:27.73134+01
527	94	143	\N	0	inactive	\N	2026-02-03 16:24:27.731341+01	2026-02-03 16:24:27.731342+01
528	94	144	\N	33	inactive	2025-08-12 12:00:25+02	2026-02-03 16:24:27.731342+01	2026-02-03 16:24:27.731343+01
529	94	145	\N	50	inactive	2025-08-06 13:23:49+02	2026-02-03 16:24:27.731343+01	2026-02-03 16:24:27.731344+01
530	94	146	\N	0	inactive	\N	2026-02-03 16:24:27.731344+01	2026-02-03 16:24:27.731345+01
531	94	153	\N	0	inactive	\N	2026-02-03 16:24:27.731345+01	2026-02-03 16:24:27.731346+01
532	94	152	\N	0	inactive	\N	2026-02-03 16:24:27.731346+01	2026-02-03 16:24:27.731347+01
533	94	154	\N	0	inactive	\N	2026-02-03 16:24:27.731347+01	2026-02-03 16:24:27.731348+01
534	94	116	\N	5	inactive	2025-08-12 12:05:47+02	2026-02-03 16:24:27.731349+01	2026-02-03 16:24:27.731349+01
535	94	118	\N	0	inactive	\N	2026-02-03 16:24:27.73135+01	2026-02-03 16:24:27.73135+01
536	94	147	\N	0	inactive	\N	2026-02-03 16:24:27.731351+01	2026-02-03 16:24:27.731351+01
537	94	148	\N	0	inactive	\N	2026-02-03 16:24:27.731352+01	2026-02-03 16:24:27.731352+01
538	94	149	\N	0	inactive	\N	2026-02-03 16:24:27.731353+01	2026-02-03 16:24:27.731353+01
539	94	150	\N	0	inactive	\N	2026-02-03 16:24:27.731354+01	2026-02-03 16:24:27.731354+01
540	94	151	\N	0	inactive	\N	2026-02-03 16:24:27.731355+01	2026-02-03 16:24:27.731355+01
541	95	115	\N	67	inactive	2025-06-09 18:46:40+02	2026-02-03 16:24:28.116472+01	2026-02-03 16:24:28.116475+01
542	95	133	\N	100	completed	2025-06-26 10:19:37+02	2026-02-03 16:24:28.116476+01	2026-02-03 16:24:28.116477+01
543	95	134	\N	57	inactive	2025-06-27 12:28:12+02	2026-02-03 16:24:28.116477+01	2026-02-03 16:24:28.116478+01
544	95	135	\N	0	inactive	\N	2026-02-03 16:24:28.116479+01	2026-02-03 16:24:28.116479+01
545	95	136	\N	0	inactive	\N	2026-02-03 16:24:28.11648+01	2026-02-03 16:24:28.11648+01
546	95	137	\N	0	inactive	\N	2026-02-03 16:24:28.116481+01	2026-02-03 16:24:28.116481+01
547	95	114	\N	0	inactive	\N	2026-02-03 16:24:28.116482+01	2026-02-03 16:24:28.116482+01
548	95	140	\N	0	inactive	2025-07-09 19:37:20+02	2026-02-03 16:24:28.116483+01	2026-02-03 16:24:28.116484+01
549	95	138	\N	0	inactive	\N	2026-02-03 16:24:28.116484+01	2026-02-03 16:24:28.116485+01
550	95	139	\N	0	inactive	2025-06-18 17:00:17+02	2026-02-03 16:24:28.116486+01	2026-02-03 16:24:28.116486+01
551	95	117	\N	0	inactive	\N	2026-02-03 16:24:28.116487+01	2026-02-03 16:24:28.116487+01
552	95	141	\N	0	inactive	\N	2026-02-03 16:24:28.116488+01	2026-02-03 16:24:28.116489+01
553	95	142	\N	0	inactive	\N	2026-02-03 16:24:28.116489+01	2026-02-03 16:24:28.11649+01
554	95	143	\N	0	inactive	\N	2026-02-03 16:24:28.11649+01	2026-02-03 16:24:28.116491+01
555	95	144	\N	0	inactive	\N	2026-02-03 16:24:28.116491+01	2026-02-03 16:24:28.116492+01
556	95	145	\N	0	inactive	\N	2026-02-03 16:24:28.116493+01	2026-02-03 16:24:28.116493+01
557	95	146	\N	0	inactive	\N	2026-02-03 16:24:28.116494+01	2026-02-03 16:24:28.116494+01
558	95	153	\N	0	inactive	\N	2026-02-03 16:24:28.116495+01	2026-02-03 16:24:28.116495+01
559	95	152	\N	0	inactive	\N	2026-02-03 16:24:28.116496+01	2026-02-03 16:24:28.116497+01
560	95	154	\N	0	inactive	\N	2026-02-03 16:24:28.116497+01	2026-02-03 16:24:28.116498+01
561	95	116	\N	0	inactive	\N	2026-02-03 16:24:28.116498+01	2026-02-03 16:24:28.116499+01
562	95	118	\N	0	inactive	\N	2026-02-03 16:24:28.116499+01	2026-02-03 16:24:28.1165+01
563	95	147	\N	0	inactive	\N	2026-02-03 16:24:28.116501+01	2026-02-03 16:24:28.116501+01
564	95	148	\N	0	inactive	\N	2026-02-03 16:24:28.116502+01	2026-02-03 16:24:28.116502+01
565	95	149	\N	0	inactive	\N	2026-02-03 16:24:28.116503+01	2026-02-03 16:24:28.116504+01
566	95	150	\N	0	inactive	\N	2026-02-03 16:24:28.116504+01	2026-02-03 16:24:28.116505+01
567	95	151	\N	0	inactive	\N	2026-02-03 16:24:28.116505+01	2026-02-03 16:24:28.116506+01
568	96	115	\N	100	completed	2025-05-26 12:35:08+02	2026-02-03 16:24:28.613559+01	2026-02-03 16:24:28.613562+01
569	96	133	\N	100	completed	2025-06-06 09:53:24+02	2026-02-03 16:24:28.613563+01	2026-02-03 16:24:28.613563+01
570	96	134	\N	100	completed	2025-06-16 14:58:22+02	2026-02-03 16:24:28.613564+01	2026-02-03 16:24:28.613564+01
571	96	135	\N	100	completed	2025-06-16 16:41:00+02	2026-02-03 16:24:28.613565+01	2026-02-03 16:24:28.613565+01
572	96	136	\N	100	completed	2025-06-17 20:09:12+02	2026-02-03 16:24:28.613566+01	2026-02-03 16:24:28.613566+01
573	96	137	\N	100	completed	2025-06-18 09:48:47+02	2026-02-03 16:24:28.613567+01	2026-02-03 16:24:28.613567+01
574	96	114	\N	100	completed	2025-06-11 14:25:50+02	2026-02-03 16:24:28.613568+01	2026-02-03 16:24:28.613569+01
575	96	140	\N	65	inactive	2025-07-17 21:06:18+02	2026-02-03 16:24:28.613569+01	2026-02-03 16:24:28.61357+01
576	96	138	\N	100	completed	2025-07-17 15:29:05+02	2026-02-03 16:24:28.61357+01	2026-02-03 16:24:28.613571+01
577	96	139	\N	20	inactive	2025-09-03 13:21:19+02	2026-02-03 16:24:28.613571+01	2026-02-03 16:24:28.613572+01
578	96	117	\N	0	inactive	\N	2026-02-03 16:24:28.613572+01	2026-02-03 16:24:28.613573+01
579	96	141	\N	0	inactive	\N	2026-02-03 16:24:28.613573+01	2026-02-03 16:24:28.613574+01
580	96	142	\N	0	inactive	\N	2026-02-03 16:24:28.613574+01	2026-02-03 16:24:28.613575+01
581	96	143	\N	0	inactive	\N	2026-02-03 16:24:28.613575+01	2026-02-03 16:24:28.613576+01
582	96	144	\N	0	inactive	\N	2026-02-03 16:24:28.613576+01	2026-02-03 16:24:28.613577+01
583	96	145	\N	0	inactive	\N	2026-02-03 16:24:28.613578+01	2026-02-03 16:24:28.613578+01
584	96	146	\N	0	inactive	\N	2026-02-03 16:24:28.613579+01	2026-02-03 16:24:28.613579+01
585	96	153	\N	0	inactive	\N	2026-02-03 16:24:28.61358+01	2026-02-03 16:24:28.61358+01
586	96	152	\N	0	inactive	\N	2026-02-03 16:24:28.613581+01	2026-02-03 16:24:28.613581+01
587	96	154	\N	0	inactive	\N	2026-02-03 16:24:28.613582+01	2026-02-03 16:24:28.613582+01
588	96	116	\N	20	inactive	2025-09-03 14:11:24+02	2026-02-03 16:24:28.613583+01	2026-02-03 16:24:28.613583+01
589	96	118	\N	0	inactive	\N	2026-02-03 16:24:28.613584+01	2026-02-03 16:24:28.613585+01
590	96	147	\N	0	inactive	\N	2026-02-03 16:24:28.613585+01	2026-02-03 16:24:28.613586+01
591	96	148	\N	0	inactive	\N	2026-02-03 16:24:28.613586+01	2026-02-03 16:24:28.613587+01
592	96	149	\N	0	inactive	\N	2026-02-03 16:24:28.613587+01	2026-02-03 16:24:28.613588+01
593	96	150	\N	0	inactive	\N	2026-02-03 16:24:28.613588+01	2026-02-03 16:24:28.613589+01
594	96	151	\N	0	inactive	\N	2026-02-03 16:24:28.613589+01	2026-02-03 16:24:28.61359+01
595	46	115	\N	0	inactive	\N	2026-02-03 16:24:29.01465+01	2026-02-03 16:24:29.014652+01
596	46	133	\N	0	inactive	\N	2026-02-03 16:24:29.014653+01	2026-02-03 16:24:29.014654+01
597	46	134	\N	0	inactive	\N	2026-02-03 16:24:29.014654+01	2026-02-03 16:24:29.014655+01
598	46	135	\N	0	inactive	\N	2026-02-03 16:24:29.014656+01	2026-02-03 16:24:29.014656+01
599	46	136	\N	0	inactive	\N	2026-02-03 16:24:29.014657+01	2026-02-03 16:24:29.014657+01
600	46	137	\N	0	inactive	\N	2026-02-03 16:24:29.014658+01	2026-02-03 16:24:29.014658+01
601	46	114	\N	0	inactive	\N	2026-02-03 16:24:29.014659+01	2026-02-03 16:24:29.014659+01
602	46	140	\N	0	inactive	\N	2026-02-03 16:24:29.01466+01	2026-02-03 16:24:29.014661+01
603	46	138	\N	0	inactive	\N	2026-02-03 16:24:29.014661+01	2026-02-03 16:24:29.014662+01
604	46	139	\N	0	inactive	\N	2026-02-03 16:24:29.014662+01	2026-02-03 16:24:29.014663+01
605	46	117	\N	0	inactive	\N	2026-02-03 16:24:29.014663+01	2026-02-03 16:24:29.014664+01
606	46	141	\N	0	inactive	\N	2026-02-03 16:24:29.014664+01	2026-02-03 16:24:29.014665+01
607	46	142	\N	0	inactive	\N	2026-02-03 16:24:29.014666+01	2026-02-03 16:24:29.014666+01
608	46	143	\N	0	inactive	\N	2026-02-03 16:24:29.014667+01	2026-02-03 16:24:29.014667+01
609	46	144	\N	0	inactive	\N	2026-02-03 16:24:29.014668+01	2026-02-03 16:24:29.014668+01
610	46	145	\N	0	inactive	\N	2026-02-03 16:24:29.014669+01	2026-02-03 16:24:29.014669+01
611	46	146	\N	0	inactive	\N	2026-02-03 16:24:29.01467+01	2026-02-03 16:24:29.014671+01
612	46	153	\N	0	inactive	\N	2026-02-03 16:24:29.014671+01	2026-02-03 16:24:29.014672+01
613	46	152	\N	0	inactive	\N	2026-02-03 16:24:29.014672+01	2026-02-03 16:24:29.014673+01
614	46	154	\N	0	inactive	\N	2026-02-03 16:24:29.014673+01	2026-02-03 16:24:29.014674+01
615	46	116	\N	0	inactive	\N	2026-02-03 16:24:29.014675+01	2026-02-03 16:24:29.014675+01
616	46	118	\N	0	inactive	\N	2026-02-03 16:24:29.014676+01	2026-02-03 16:24:29.014676+01
617	46	147	\N	0	inactive	\N	2026-02-03 16:24:29.014677+01	2026-02-03 16:24:29.014678+01
618	46	148	\N	0	inactive	\N	2026-02-03 16:24:29.014678+01	2026-02-03 16:24:29.014679+01
619	46	149	\N	0	inactive	\N	2026-02-03 16:24:29.014679+01	2026-02-03 16:24:29.01468+01
620	46	150	\N	0	inactive	\N	2026-02-03 16:24:29.014681+01	2026-02-03 16:24:29.014681+01
621	46	151	\N	0	inactive	\N	2026-02-03 16:24:29.014682+01	2026-02-03 16:24:29.014682+01
622	97	115	\N	33	inactive	2025-06-10 20:33:07+02	2026-02-03 16:24:29.528699+01	2026-02-03 16:24:29.528703+01
623	97	133	\N	15	inactive	2025-06-15 20:27:29+02	2026-02-03 16:24:29.528704+01	2026-02-03 16:24:29.528705+01
624	97	134	\N	0	inactive	\N	2026-02-03 16:24:29.528706+01	2026-02-03 16:24:29.528706+01
625	97	135	\N	0	inactive	\N	2026-02-03 16:24:29.528707+01	2026-02-03 16:24:29.528708+01
626	97	136	\N	0	inactive	\N	2026-02-03 16:24:29.528709+01	2026-02-03 16:24:29.528709+01
627	97	137	\N	0	inactive	\N	2026-02-03 16:24:29.52871+01	2026-02-03 16:24:29.528711+01
628	97	114	\N	0	inactive	\N	2026-02-03 16:24:29.528711+01	2026-02-03 16:24:29.528712+01
629	97	140	\N	0	inactive	\N	2026-02-03 16:24:29.528713+01	2026-02-03 16:24:29.528714+01
630	97	138	\N	0	inactive	\N	2026-02-03 16:24:29.528714+01	2026-02-03 16:24:29.528715+01
631	97	116	\N	0	inactive	\N	2026-02-03 16:24:29.528716+01	2026-02-03 16:24:29.528716+01
632	97	139	\N	0	inactive	\N	2026-02-03 16:24:29.528717+01	2026-02-03 16:24:29.528718+01
633	97	117	\N	0	inactive	\N	2026-02-03 16:24:29.528718+01	2026-02-03 16:24:29.528719+01
634	97	141	\N	0	inactive	\N	2026-02-03 16:24:29.52872+01	2026-02-03 16:24:29.528721+01
635	97	142	\N	0	inactive	\N	2026-02-03 16:24:29.528721+01	2026-02-03 16:24:29.528722+01
636	97	143	\N	0	inactive	\N	2026-02-03 16:24:29.528723+01	2026-02-03 16:24:29.528723+01
637	97	144	\N	0	inactive	\N	2026-02-03 16:24:29.528724+01	2026-02-03 16:24:29.528725+01
638	97	145	\N	0	inactive	\N	2026-02-03 16:24:29.528725+01	2026-02-03 16:24:29.528726+01
639	97	146	\N	0	inactive	\N	2026-02-03 16:24:29.528727+01	2026-02-03 16:24:29.528728+01
640	97	153	\N	0	inactive	\N	2026-02-03 16:24:29.528728+01	2026-02-03 16:24:29.528729+01
641	97	152	\N	0	inactive	\N	2026-02-03 16:24:29.52873+01	2026-02-03 16:24:29.528731+01
642	97	154	\N	0	inactive	\N	2026-02-03 16:24:29.528731+01	2026-02-03 16:24:29.528732+01
643	97	118	\N	0	inactive	\N	2026-02-03 16:24:29.528733+01	2026-02-03 16:24:29.528733+01
644	97	147	\N	0	inactive	\N	2026-02-03 16:24:29.528734+01	2026-02-03 16:24:29.528735+01
645	97	148	\N	0	inactive	\N	2026-02-03 16:24:29.528735+01	2026-02-03 16:24:29.528736+01
646	97	149	\N	0	inactive	\N	2026-02-03 16:24:29.528737+01	2026-02-03 16:24:29.528738+01
647	97	150	\N	0	inactive	\N	2026-02-03 16:24:29.528738+01	2026-02-03 16:24:29.528739+01
648	97	151	\N	0	inactive	\N	2026-02-03 16:24:29.52874+01	2026-02-03 16:24:29.52874+01
649	98	115	\N	0	inactive	\N	2026-02-03 16:24:30.020625+01	2026-02-03 16:24:30.020628+01
650	98	133	\N	100	completed	2025-06-26 16:40:25+02	2026-02-03 16:24:30.020629+01	2026-02-03 16:24:30.02063+01
651	98	134	\N	57	inactive	2025-07-28 12:07:47+02	2026-02-03 16:24:30.020631+01	2026-02-03 16:24:30.020631+01
652	98	135	\N	0	inactive	\N	2026-02-03 16:24:30.020632+01	2026-02-03 16:24:30.020632+01
653	98	136	\N	0	inactive	\N	2026-02-03 16:24:30.020633+01	2026-02-03 16:24:30.020633+01
654	98	137	\N	0	inactive	\N	2026-02-03 16:24:30.020634+01	2026-02-03 16:24:30.020635+01
655	98	114	\N	100	completed	2025-06-16 15:35:23+02	2026-02-03 16:24:30.020635+01	2026-02-03 16:24:30.020636+01
656	98	140	\N	99	inactive	2025-07-15 15:49:09+02	2026-02-03 16:24:30.020636+01	2026-02-03 16:24:30.020637+01
657	98	138	\N	100	completed	2025-09-09 10:20:09+02	2026-02-03 16:24:30.020637+01	2026-02-03 16:24:30.020638+01
658	98	116	\N	0	inactive	\N	2026-02-03 16:24:30.020638+01	2026-02-03 16:24:30.020639+01
659	98	139	\N	0	inactive	\N	2026-02-03 16:24:30.020639+01	2026-02-03 16:24:30.02064+01
660	98	117	\N	100	completed	2025-06-11 17:24:58+02	2026-02-03 16:24:30.02064+01	2026-02-03 16:24:30.020641+01
661	98	141	\N	0	inactive	\N	2026-02-03 16:24:30.020642+01	2026-02-03 16:24:30.020642+01
662	98	142	\N	0	inactive	\N	2026-02-03 16:24:30.020643+01	2026-02-03 16:24:30.020643+01
663	98	143	\N	0	inactive	\N	2026-02-03 16:24:30.020644+01	2026-02-03 16:24:30.020644+01
664	98	144	\N	0	inactive	\N	2026-02-03 16:24:30.020645+01	2026-02-03 16:24:30.020646+01
665	98	145	\N	0	inactive	\N	2026-02-03 16:24:30.020646+01	2026-02-03 16:24:30.020647+01
666	98	146	\N	0	inactive	\N	2026-02-03 16:24:30.020647+01	2026-02-03 16:24:30.020648+01
667	98	153	\N	0	inactive	\N	2026-02-03 16:24:30.020648+01	2026-02-03 16:24:30.020649+01
668	98	152	\N	0	inactive	\N	2026-02-03 16:24:30.020649+01	2026-02-03 16:24:30.02065+01
669	98	154	\N	0	inactive	\N	2026-02-03 16:24:30.02065+01	2026-02-03 16:24:30.020651+01
670	98	118	\N	100	completed	2025-06-16 10:33:27+02	2026-02-03 16:24:30.020652+01	2026-02-03 16:24:30.020652+01
671	98	147	\N	0	inactive	\N	2026-02-03 16:24:30.020653+01	2026-02-03 16:24:30.020653+01
672	98	148	\N	0	inactive	\N	2026-02-03 16:24:30.020654+01	2026-02-03 16:24:30.020654+01
673	98	149	\N	0	inactive	\N	2026-02-03 16:24:30.020655+01	2026-02-03 16:24:30.020655+01
674	98	150	\N	0	inactive	\N	2026-02-03 16:24:30.020656+01	2026-02-03 16:24:30.020656+01
675	98	151	\N	0	inactive	\N	2026-02-03 16:24:30.020657+01	2026-02-03 16:24:30.020657+01
676	99	115	\N	100	completed	2025-06-10 21:28:23+02	2026-02-03 16:24:30.560749+01	2026-02-03 16:24:30.560753+01
677	99	133	\N	100	completed	2025-06-23 08:53:51+02	2026-02-03 16:24:30.560754+01	2026-02-03 16:24:30.560754+01
678	99	134	\N	0	inactive	\N	2026-02-03 16:24:30.560755+01	2026-02-03 16:24:30.560756+01
679	99	135	\N	0	inactive	\N	2026-02-03 16:24:30.560756+01	2026-02-03 16:24:30.560757+01
680	99	136	\N	0	inactive	\N	2026-02-03 16:24:30.560758+01	2026-02-03 16:24:30.560758+01
681	99	137	\N	0	inactive	\N	2026-02-03 16:24:30.560759+01	2026-02-03 16:24:30.56076+01
682	99	114	\N	3	inactive	2025-06-10 22:17:13+02	2026-02-03 16:24:30.560761+01	2026-02-03 16:24:30.560761+01
683	99	140	\N	6	inactive	2025-07-09 10:57:41+02	2026-02-03 16:24:30.560762+01	2026-02-03 16:24:30.560762+01
684	99	138	\N	0	inactive	\N	2026-02-03 16:24:30.560763+01	2026-02-03 16:24:30.560764+01
685	99	116	\N	0	inactive	\N	2026-02-03 16:24:30.560764+01	2026-02-03 16:24:30.560765+01
686	99	139	\N	0	inactive	\N	2026-02-03 16:24:30.560766+01	2026-02-03 16:24:30.560766+01
687	99	117	\N	0	inactive	\N	2026-02-03 16:24:30.560767+01	2026-02-03 16:24:30.560768+01
688	99	141	\N	0	inactive	\N	2026-02-03 16:24:30.560768+01	2026-02-03 16:24:30.560769+01
689	99	142	\N	0	inactive	\N	2026-02-03 16:24:30.56077+01	2026-02-03 16:24:30.56077+01
690	99	143	\N	0	inactive	\N	2026-02-03 16:24:30.560771+01	2026-02-03 16:24:30.560772+01
691	99	144	\N	0	inactive	\N	2026-02-03 16:24:30.560772+01	2026-02-03 16:24:30.560773+01
692	99	145	\N	0	inactive	\N	2026-02-03 16:24:30.560774+01	2026-02-03 16:24:30.560774+01
693	99	146	\N	0	inactive	\N	2026-02-03 16:24:30.560775+01	2026-02-03 16:24:30.560776+01
694	99	153	\N	0	inactive	\N	2026-02-03 16:24:30.560776+01	2026-02-03 16:24:30.560777+01
695	99	152	\N	0	inactive	\N	2026-02-03 16:24:30.560778+01	2026-02-03 16:24:30.560778+01
696	99	154	\N	0	inactive	\N	2026-02-03 16:24:30.560779+01	2026-02-03 16:24:30.560779+01
697	99	118	\N	0	inactive	\N	2026-02-03 16:24:30.56078+01	2026-02-03 16:24:30.560781+01
698	99	147	\N	0	inactive	\N	2026-02-03 16:24:30.560781+01	2026-02-03 16:24:30.560782+01
699	99	148	\N	0	inactive	\N	2026-02-03 16:24:30.560783+01	2026-02-03 16:24:30.560783+01
700	99	149	\N	0	inactive	\N	2026-02-03 16:24:30.560784+01	2026-02-03 16:24:30.560785+01
701	99	150	\N	0	inactive	\N	2026-02-03 16:24:30.560786+01	2026-02-03 16:24:30.560786+01
702	99	151	\N	0	inactive	\N	2026-02-03 16:24:30.560787+01	2026-02-03 16:24:30.560788+01
703	100	115	\N	0	inactive	\N	2026-02-03 16:24:31.042279+01	2026-02-03 16:24:31.042283+01
704	100	133	\N	100	completed	2025-06-16 14:17:52+02	2026-02-03 16:24:31.042284+01	2026-02-03 16:24:31.042285+01
705	100	134	\N	57	inactive	2025-07-03 14:07:11+02	2026-02-03 16:24:31.042286+01	2026-02-03 16:24:31.042286+01
706	100	135	\N	0	inactive	\N	2026-02-03 16:24:31.042287+01	2026-02-03 16:24:31.042288+01
707	100	136	\N	0	inactive	\N	2026-02-03 16:24:31.042289+01	2026-02-03 16:24:31.042289+01
708	100	137	\N	0	inactive	\N	2026-02-03 16:24:31.04229+01	2026-02-03 16:24:31.042291+01
709	100	114	\N	0	inactive	\N	2026-02-03 16:24:31.042292+01	2026-02-03 16:24:31.042293+01
710	100	140	\N	47	inactive	2025-08-04 10:38:05+02	2026-02-03 16:24:31.042293+01	2026-02-03 16:24:31.042294+01
711	100	138	\N	0	inactive	\N	2026-02-03 16:24:31.042295+01	2026-02-03 16:24:31.042296+01
712	100	116	\N	0	inactive	\N	2026-02-03 16:24:31.042296+01	2026-02-03 16:24:31.042297+01
713	100	139	\N	0	inactive	\N	2026-02-03 16:24:31.042298+01	2026-02-03 16:24:31.042299+01
714	100	117	\N	0	inactive	\N	2026-02-03 16:24:31.042299+01	2026-02-03 16:24:31.0423+01
715	100	141	\N	0	inactive	\N	2026-02-03 16:24:31.042301+01	2026-02-03 16:24:31.042302+01
716	100	142	\N	0	inactive	\N	2026-02-03 16:24:31.042303+01	2026-02-03 16:24:31.042303+01
717	100	143	\N	0	inactive	\N	2026-02-03 16:24:31.042304+01	2026-02-03 16:24:31.042305+01
718	100	144	\N	0	inactive	\N	2026-02-03 16:24:31.042306+01	2026-02-03 16:24:31.042306+01
719	100	145	\N	0	inactive	\N	2026-02-03 16:24:31.042307+01	2026-02-03 16:24:31.042308+01
720	100	146	\N	0	inactive	\N	2026-02-03 16:24:31.042309+01	2026-02-03 16:24:31.042309+01
721	100	153	\N	0	inactive	\N	2026-02-03 16:24:31.04231+01	2026-02-03 16:24:31.042311+01
722	100	152	\N	0	inactive	\N	2026-02-03 16:24:31.042312+01	2026-02-03 16:24:31.042312+01
723	100	154	\N	0	inactive	\N	2026-02-03 16:24:31.042313+01	2026-02-03 16:24:31.042314+01
724	100	118	\N	0	inactive	\N	2026-02-03 16:24:31.042315+01	2026-02-03 16:24:31.042316+01
725	100	147	\N	0	inactive	\N	2026-02-03 16:24:31.042317+01	2026-02-03 16:24:31.042318+01
726	100	148	\N	0	inactive	\N	2026-02-03 16:24:31.042319+01	2026-02-03 16:24:31.042319+01
727	100	149	\N	0	inactive	\N	2026-02-03 16:24:31.04232+01	2026-02-03 16:24:31.042321+01
728	100	150	\N	0	inactive	\N	2026-02-03 16:24:31.042322+01	2026-02-03 16:24:31.042323+01
729	100	151	\N	0	inactive	\N	2026-02-03 16:24:31.042323+01	2026-02-03 16:24:31.042324+01
730	101	115	\N	100	completed	2025-06-10 14:40:23+02	2026-02-03 16:24:31.515744+01	2026-02-03 16:24:31.515748+01
731	101	133	\N	100	completed	2025-06-19 15:53:06+02	2026-02-03 16:24:31.515749+01	2026-02-03 16:24:31.51575+01
732	101	134	\N	100	completed	2025-06-26 09:31:18+02	2026-02-03 16:24:31.51575+01	2026-02-03 16:24:31.515751+01
733	101	135	\N	100	completed	2025-06-29 13:57:24+02	2026-02-03 16:24:31.515752+01	2026-02-03 16:24:31.515753+01
734	101	136	\N	100	completed	2025-07-01 09:56:13+02	2026-02-03 16:24:31.515753+01	2026-02-03 16:24:31.515754+01
735	101	137	\N	100	completed	2025-07-02 10:18:25+02	2026-02-03 16:24:31.515755+01	2026-02-03 16:24:31.515755+01
736	101	114	\N	100	completed	2025-07-03 07:35:52+02	2026-02-03 16:24:31.515756+01	2026-02-03 16:24:31.515757+01
737	101	140	\N	100	completed	2025-09-12 18:31:27+02	2026-02-03 16:24:31.515757+01	2026-02-03 16:24:31.515758+01
738	101	138	\N	100	completed	2025-09-12 18:43:47+02	2026-02-03 16:24:31.515759+01	2026-02-03 16:24:31.515759+01
739	101	116	\N	100	completed	2025-09-12 15:44:10+02	2026-02-03 16:24:31.51576+01	2026-02-03 16:24:31.515761+01
740	101	139	\N	100	completed	2025-09-12 15:43:44+02	2026-02-03 16:24:31.515761+01	2026-02-03 16:24:31.515762+01
741	101	117	\N	0	inactive	\N	2026-02-03 16:24:31.515763+01	2026-02-03 16:24:31.515764+01
742	101	141	\N	100	completed	2025-08-05 10:37:58+02	2026-02-03 16:24:31.515764+01	2026-02-03 16:24:31.515765+01
743	101	142	\N	100	completed	2025-08-12 12:42:32+02	2026-02-03 16:24:31.515766+01	2026-02-03 16:24:31.515766+01
744	101	143	\N	100	completed	2025-08-14 13:02:43+02	2026-02-03 16:24:31.515767+01	2026-02-03 16:24:31.515768+01
745	101	144	\N	100	completed	2025-08-14 13:09:51+02	2026-02-03 16:24:31.515769+01	2026-02-03 16:24:31.515769+01
746	101	145	\N	0	inactive	\N	2026-02-03 16:24:31.51577+01	2026-02-03 16:24:31.515771+01
747	101	146	\N	0	inactive	\N	2026-02-03 16:24:31.515771+01	2026-02-03 16:24:31.515772+01
748	101	153	\N	100	completed	2025-08-26 08:37:18+02	2026-02-03 16:24:31.515773+01	2026-02-03 16:24:31.515773+01
749	101	152	\N	100	completed	2025-07-02 10:12:13+02	2026-02-03 16:24:31.515774+01	2026-02-03 16:24:31.515775+01
750	101	154	\N	100	completed	2025-09-08 14:46:29+02	2026-02-03 16:24:31.515776+01	2026-02-03 16:24:31.515776+01
751	101	118	\N	0	inactive	\N	2026-02-03 16:24:31.515777+01	2026-02-03 16:24:31.515778+01
752	101	147	\N	100	completed	2025-08-27 12:26:26+02	2026-02-03 16:24:31.515779+01	2026-02-03 16:24:31.515779+01
753	101	148	\N	100	completed	2025-08-29 14:55:51+02	2026-02-03 16:24:31.51578+01	2026-02-03 16:24:31.515781+01
754	101	149	\N	100	completed	2025-08-29 14:56:46+02	2026-02-03 16:24:31.515781+01	2026-02-03 16:24:31.515782+01
755	101	150	\N	100	completed	2025-08-29 16:55:41+02	2026-02-03 16:24:31.515783+01	2026-02-03 16:24:31.515784+01
756	101	151	\N	100	completed	2025-09-09 13:00:29+02	2026-02-03 16:24:31.515784+01	2026-02-03 16:24:31.515785+01
757	102	115	\N	100	completed	2025-06-10 23:06:55+02	2026-02-03 16:24:31.955499+01	2026-02-03 16:24:31.955502+01
758	102	133	\N	100	completed	2025-10-28 16:00:01+01	2026-02-03 16:24:31.955503+01	2026-02-03 16:24:31.955504+01
759	102	134	\N	57	inactive	2025-07-02 09:44:15+02	2026-02-03 16:24:31.955504+01	2026-02-03 16:24:31.955505+01
760	102	135	\N	0	inactive	\N	2026-02-03 16:24:31.955505+01	2026-02-03 16:24:31.955506+01
761	102	136	\N	0	inactive	\N	2026-02-03 16:24:31.955506+01	2026-02-03 16:24:31.955507+01
762	102	137	\N	0	inactive	\N	2026-02-03 16:24:31.955507+01	2026-02-03 16:24:31.955508+01
763	102	114	\N	100	completed	2025-06-14 00:29:18+02	2026-02-03 16:24:31.955508+01	2026-02-03 16:24:31.955509+01
764	102	140	\N	99	inactive	2025-07-16 19:24:00+02	2026-02-03 16:24:31.955509+01	2026-02-03 16:24:31.95551+01
765	102	138	\N	100	completed	2025-11-05 16:28:58+01	2026-02-03 16:24:31.955511+01	2026-02-03 16:24:31.955511+01
766	102	116	\N	0	inactive	\N	2026-02-03 16:24:31.955512+01	2026-02-03 16:24:31.955512+01
767	102	139	\N	100	completed	2025-11-09 22:13:30+01	2026-02-03 16:24:31.955513+01	2026-02-03 16:24:31.955513+01
768	102	117	\N	0	inactive	\N	2026-02-03 16:24:31.955514+01	2026-02-03 16:24:31.955514+01
769	102	141	\N	38	inactive	2025-10-28 16:00:03+01	2026-02-03 16:24:31.955515+01	2026-02-03 16:24:31.955515+01
770	102	142	\N	0	inactive	\N	2026-02-03 16:24:31.955516+01	2026-02-03 16:24:31.955516+01
771	102	143	\N	0	inactive	\N	2026-02-03 16:24:31.955517+01	2026-02-03 16:24:31.955517+01
772	102	144	\N	0	inactive	\N	2026-02-03 16:24:31.955518+01	2026-02-03 16:24:31.955519+01
773	102	145	\N	0	inactive	\N	2026-02-03 16:24:31.955519+01	2026-02-03 16:24:31.95552+01
774	102	146	\N	0	inactive	\N	2026-02-03 16:24:31.95552+01	2026-02-03 16:24:31.955521+01
775	102	153	\N	0	inactive	\N	2026-02-03 16:24:31.955522+01	2026-02-03 16:24:31.955522+01
776	102	152	\N	0	inactive	\N	2026-02-03 16:24:31.955523+01	2026-02-03 16:24:31.955523+01
777	102	154	\N	0	inactive	\N	2026-02-03 16:24:31.955524+01	2026-02-03 16:24:31.955524+01
778	102	118	\N	0	inactive	\N	2026-02-03 16:24:31.955525+01	2026-02-03 16:24:31.955525+01
779	102	147	\N	0	inactive	\N	2026-02-03 16:24:31.955526+01	2026-02-03 16:24:31.955526+01
780	102	148	\N	0	inactive	\N	2026-02-03 16:24:31.955527+01	2026-02-03 16:24:31.955527+01
781	102	149	\N	0	inactive	\N	2026-02-03 16:24:31.955528+01	2026-02-03 16:24:31.955528+01
782	102	150	\N	0	inactive	\N	2026-02-03 16:24:31.955529+01	2026-02-03 16:24:31.955529+01
783	102	151	\N	0	inactive	\N	2026-02-03 16:24:31.95553+01	2026-02-03 16:24:31.95553+01
784	103	115	\N	0	inactive	\N	2026-02-03 16:24:32.399281+01	2026-02-03 16:24:32.399284+01
785	103	133	\N	0	inactive	\N	2026-02-03 16:24:32.399285+01	2026-02-03 16:24:32.399286+01
786	103	134	\N	0	inactive	\N	2026-02-03 16:24:32.399286+01	2026-02-03 16:24:32.399287+01
787	103	135	\N	0	inactive	\N	2026-02-03 16:24:32.399287+01	2026-02-03 16:24:32.399288+01
788	103	136	\N	0	inactive	\N	2026-02-03 16:24:32.399289+01	2026-02-03 16:24:32.399289+01
789	103	137	\N	0	inactive	\N	2026-02-03 16:24:32.39929+01	2026-02-03 16:24:32.39929+01
790	103	114	\N	0	inactive	\N	2026-02-03 16:24:32.399291+01	2026-02-03 16:24:32.399291+01
791	103	140	\N	0	inactive	\N	2026-02-03 16:24:32.399292+01	2026-02-03 16:24:32.399293+01
792	103	138	\N	0	inactive	\N	2026-02-03 16:24:32.399293+01	2026-02-03 16:24:32.399294+01
793	103	116	\N	0	inactive	\N	2026-02-03 16:24:32.399294+01	2026-02-03 16:24:32.399295+01
794	103	139	\N	0	inactive	\N	2026-02-03 16:24:32.399295+01	2026-02-03 16:24:32.399296+01
795	103	117	\N	0	inactive	\N	2026-02-03 16:24:32.399296+01	2026-02-03 16:24:32.399297+01
796	103	141	\N	0	inactive	\N	2026-02-03 16:24:32.399297+01	2026-02-03 16:24:32.399298+01
797	103	142	\N	0	inactive	\N	2026-02-03 16:24:32.399298+01	2026-02-03 16:24:32.399299+01
798	103	143	\N	0	inactive	\N	2026-02-03 16:24:32.3993+01	2026-02-03 16:24:32.3993+01
799	103	144	\N	0	inactive	\N	2026-02-03 16:24:32.399301+01	2026-02-03 16:24:32.399301+01
800	103	145	\N	0	inactive	\N	2026-02-03 16:24:32.399302+01	2026-02-03 16:24:32.399302+01
801	103	146	\N	0	inactive	\N	2026-02-03 16:24:32.399303+01	2026-02-03 16:24:32.399304+01
802	103	153	\N	0	inactive	\N	2026-02-03 16:24:32.399304+01	2026-02-03 16:24:32.399305+01
803	103	152	\N	0	inactive	\N	2026-02-03 16:24:32.399305+01	2026-02-03 16:24:32.399306+01
804	103	154	\N	0	inactive	\N	2026-02-03 16:24:32.399306+01	2026-02-03 16:24:32.399307+01
805	103	118	\N	0	inactive	\N	2026-02-03 16:24:32.399308+01	2026-02-03 16:24:32.399308+01
806	103	147	\N	0	inactive	\N	2026-02-03 16:24:32.399309+01	2026-02-03 16:24:32.399309+01
807	103	148	\N	0	inactive	\N	2026-02-03 16:24:32.39931+01	2026-02-03 16:24:32.39931+01
808	103	149	\N	0	inactive	\N	2026-02-03 16:24:32.399311+01	2026-02-03 16:24:32.399311+01
809	103	150	\N	0	inactive	\N	2026-02-03 16:24:32.399312+01	2026-02-03 16:24:32.399312+01
810	103	151	\N	0	inactive	\N	2026-02-03 16:24:32.399313+01	2026-02-03 16:24:32.399313+01
811	104	115	\N	0	inactive	\N	2026-02-03 16:24:32.843098+01	2026-02-03 16:24:32.843102+01
812	104	133	\N	0	inactive	\N	2026-02-03 16:24:32.843103+01	2026-02-03 16:24:32.843104+01
813	104	134	\N	0	inactive	\N	2026-02-03 16:24:32.843105+01	2026-02-03 16:24:32.843105+01
814	104	135	\N	0	inactive	\N	2026-02-03 16:24:32.843106+01	2026-02-03 16:24:32.843107+01
815	104	136	\N	0	inactive	\N	2026-02-03 16:24:32.843108+01	2026-02-03 16:24:32.843109+01
816	104	137	\N	0	inactive	\N	2026-02-03 16:24:32.84311+01	2026-02-03 16:24:32.84311+01
817	104	114	\N	0	inactive	\N	2026-02-03 16:24:32.843111+01	2026-02-03 16:24:32.843112+01
818	104	140	\N	0	inactive	\N	2026-02-03 16:24:32.843113+01	2026-02-03 16:24:32.843113+01
819	104	138	\N	0	inactive	\N	2026-02-03 16:24:32.843114+01	2026-02-03 16:24:32.843115+01
820	104	116	\N	0	inactive	\N	2026-02-03 16:24:32.843115+01	2026-02-03 16:24:32.843116+01
821	104	139	\N	0	inactive	\N	2026-02-03 16:24:32.843117+01	2026-02-03 16:24:32.843118+01
822	104	117	\N	0	inactive	\N	2026-02-03 16:24:32.843118+01	2026-02-03 16:24:32.843119+01
823	104	141	\N	0	inactive	\N	2026-02-03 16:24:32.84312+01	2026-02-03 16:24:32.84312+01
824	104	142	\N	0	inactive	\N	2026-02-03 16:24:32.843121+01	2026-02-03 16:24:32.843122+01
825	104	143	\N	0	inactive	\N	2026-02-03 16:24:32.843123+01	2026-02-03 16:24:32.843123+01
826	104	144	\N	0	inactive	\N	2026-02-03 16:24:32.843124+01	2026-02-03 16:24:32.843125+01
827	104	145	\N	0	inactive	\N	2026-02-03 16:24:32.843126+01	2026-02-03 16:24:32.843126+01
828	104	146	\N	0	inactive	\N	2026-02-03 16:24:32.843127+01	2026-02-03 16:24:32.843128+01
829	104	153	\N	0	inactive	\N	2026-02-03 16:24:32.843129+01	2026-02-03 16:24:32.843129+01
830	104	152	\N	0	inactive	\N	2026-02-03 16:24:32.84313+01	2026-02-03 16:24:32.843131+01
831	104	154	\N	0	inactive	\N	2026-02-03 16:24:32.843132+01	2026-02-03 16:24:32.843132+01
832	104	118	\N	0	inactive	\N	2026-02-03 16:24:32.843133+01	2026-02-03 16:24:32.843134+01
833	104	147	\N	0	inactive	\N	2026-02-03 16:24:32.843135+01	2026-02-03 16:24:32.843135+01
834	104	148	\N	0	inactive	\N	2026-02-03 16:24:32.843136+01	2026-02-03 16:24:32.843137+01
835	104	149	\N	0	inactive	\N	2026-02-03 16:24:32.843138+01	2026-02-03 16:24:32.843138+01
836	104	150	\N	0	inactive	\N	2026-02-03 16:24:32.843139+01	2026-02-03 16:24:32.84314+01
837	104	151	\N	0	inactive	\N	2026-02-03 16:24:32.843141+01	2026-02-03 16:24:32.843141+01
838	105	115	\N	100	completed	2025-06-10 22:35:38+02	2026-02-03 16:24:33.299087+01	2026-02-03 16:24:33.29909+01
839	105	133	\N	100	completed	2025-12-08 09:30:37+01	2026-02-03 16:24:33.299091+01	2026-02-03 16:24:33.299091+01
840	105	134	\N	37	inactive	2025-11-20 15:53:01+01	2026-02-03 16:24:33.299092+01	2026-02-03 16:24:33.299092+01
841	105	135	\N	0	inactive	\N	2026-02-03 16:24:33.299093+01	2026-02-03 16:24:33.299093+01
842	105	136	\N	0	inactive	\N	2026-02-03 16:24:33.299094+01	2026-02-03 16:24:33.299094+01
843	105	137	\N	0	inactive	\N	2026-02-03 16:24:33.299095+01	2026-02-03 16:24:33.299095+01
844	105	114	\N	100	completed	2025-09-26 11:31:14+02	2026-02-03 16:24:33.299096+01	2026-02-03 16:24:33.299096+01
845	105	140	\N	0	inactive	\N	2026-02-03 16:24:33.299097+01	2026-02-03 16:24:33.299097+01
846	105	138	\N	100	completed	2025-07-21 18:58:11+02	2026-02-03 16:24:33.299098+01	2026-02-03 16:24:33.299099+01
847	105	116	\N	100	completed	2025-11-20 09:22:38+01	2026-02-03 16:24:33.299099+01	2026-02-03 16:24:33.2991+01
848	105	139	\N	100	completed	2025-11-20 09:10:40+01	2026-02-03 16:24:33.2991+01	2026-02-03 16:24:33.299101+01
849	105	118	\N	100	completed	2025-06-09 02:43:34+02	2026-02-03 16:24:33.299102+01	2026-02-03 16:24:33.299102+01
850	105	117	\N	0	inactive	\N	2026-02-03 16:24:33.299103+01	2026-02-03 16:24:33.299103+01
851	105	141	\N	38	active	2026-01-24 22:25:08+01	2026-02-03 16:24:33.299104+01	2026-02-03 16:24:33.299104+01
852	105	142	\N	0	inactive	\N	2026-02-03 16:24:33.299105+01	2026-02-03 16:24:33.299105+01
853	105	143	\N	0	inactive	\N	2026-02-03 16:24:33.299106+01	2026-02-03 16:24:33.299107+01
854	105	144	\N	0	inactive	\N	2026-02-03 16:24:33.299107+01	2026-02-03 16:24:33.299108+01
855	105	145	\N	0	inactive	\N	2026-02-03 16:24:33.299109+01	2026-02-03 16:24:33.299109+01
856	105	146	\N	0	inactive	\N	2026-02-03 16:24:33.29911+01	2026-02-03 16:24:33.29911+01
857	105	153	\N	0	inactive	\N	2026-02-03 16:24:33.299111+01	2026-02-03 16:24:33.299111+01
858	105	152	\N	0	inactive	\N	2026-02-03 16:24:33.299112+01	2026-02-03 16:24:33.299112+01
859	105	154	\N	0	inactive	\N	2026-02-03 16:24:33.299113+01	2026-02-03 16:24:33.299113+01
860	105	147	\N	0	inactive	\N	2026-02-03 16:24:33.299114+01	2026-02-03 16:24:33.299115+01
861	105	148	\N	0	inactive	\N	2026-02-03 16:24:33.299115+01	2026-02-03 16:24:33.299116+01
862	105	149	\N	0	inactive	\N	2026-02-03 16:24:33.299116+01	2026-02-03 16:24:33.299117+01
863	105	150	\N	0	inactive	\N	2026-02-03 16:24:33.299117+01	2026-02-03 16:24:33.299118+01
864	105	151	\N	0	inactive	\N	2026-02-03 16:24:33.299119+01	2026-02-03 16:24:33.299119+01
865	106	115	\N	100	completed	2025-06-09 09:12:44+02	2026-02-03 16:24:33.752417+01	2026-02-03 16:24:33.75242+01
866	106	133	\N	100	completed	2025-06-25 22:42:56+02	2026-02-03 16:24:33.752421+01	2026-02-03 16:24:33.752422+01
867	106	134	\N	100	completed	2025-08-09 10:04:54+02	2026-02-03 16:24:33.752422+01	2026-02-03 16:24:33.752423+01
868	106	135	\N	100	completed	2025-08-26 08:29:19+02	2026-02-03 16:24:33.752423+01	2026-02-03 16:24:33.752424+01
869	106	136	\N	100	completed	2025-08-14 07:51:48+02	2026-02-03 16:24:33.752424+01	2026-02-03 16:24:33.752425+01
870	106	137	\N	100	completed	2025-08-18 10:40:05+02	2026-02-03 16:24:33.752425+01	2026-02-03 16:24:33.752426+01
871	106	114	\N	100	completed	2025-10-07 07:08:02+02	2026-02-03 16:24:33.752426+01	2026-02-03 16:24:33.752427+01
872	106	140	\N	100	completed	2025-09-11 19:51:43+02	2026-02-03 16:24:33.752427+01	2026-02-03 16:24:33.752428+01
873	106	138	\N	100	completed	2025-10-12 23:39:54+02	2026-02-03 16:24:33.752428+01	2026-02-03 16:24:33.752429+01
874	106	116	\N	100	completed	2025-09-13 21:55:17+02	2026-02-03 16:24:33.752429+01	2026-02-03 16:24:33.75243+01
875	106	139	\N	100	completed	2025-08-21 16:19:17+02	2026-02-03 16:24:33.75243+01	2026-02-03 16:24:33.752431+01
876	106	118	\N	0	inactive	\N	2026-02-03 16:24:33.752432+01	2026-02-03 16:24:33.752432+01
877	106	117	\N	0	inactive	\N	2026-02-03 16:24:33.752433+01	2026-02-03 16:24:33.752433+01
878	106	141	\N	100	completed	2025-08-12 10:42:04+02	2026-02-03 16:24:33.752434+01	2026-02-03 16:24:33.752434+01
879	106	142	\N	100	completed	2025-08-22 14:25:28+02	2026-02-03 16:24:33.752435+01	2026-02-03 16:24:33.752435+01
880	106	143	\N	100	completed	2025-08-27 07:09:35+02	2026-02-03 16:24:33.752436+01	2026-02-03 16:24:33.752436+01
881	106	144	\N	100	completed	2025-08-27 07:46:25+02	2026-02-03 16:24:33.752437+01	2026-02-03 16:24:33.752437+01
882	106	145	\N	0	inactive	\N	2026-02-03 16:24:33.752438+01	2026-02-03 16:24:33.752438+01
883	106	146	\N	0	inactive	\N	2026-02-03 16:24:33.752439+01	2026-02-03 16:24:33.752439+01
884	106	153	\N	100	completed	2025-10-09 07:01:56+02	2026-02-03 16:24:33.75244+01	2026-02-03 16:24:33.75244+01
885	106	152	\N	3	inactive	2025-10-30 06:41:09+01	2026-02-03 16:24:33.752441+01	2026-02-03 16:24:33.752441+01
886	106	154	\N	62	inactive	2025-11-26 14:56:36+01	2026-02-03 16:24:33.752442+01	2026-02-03 16:24:33.752442+01
887	106	147	\N	100	completed	2025-10-07 06:45:12+02	2026-02-03 16:24:33.752443+01	2026-02-03 16:24:33.752443+01
888	106	148	\N	16	inactive	2025-11-12 00:17:39+01	2026-02-03 16:24:33.752444+01	2026-02-03 16:24:33.752444+01
889	106	149	\N	100	completed	2025-10-23 07:05:36+02	2026-02-03 16:24:33.752445+01	2026-02-03 16:24:33.752446+01
890	106	150	\N	50	inactive	2025-11-09 21:34:07+01	2026-02-03 16:24:33.752446+01	2026-02-03 16:24:33.752447+01
891	106	151	\N	0	inactive	\N	2026-02-03 16:24:33.752447+01	2026-02-03 16:24:33.752448+01
892	107	115	\N	100	completed	2025-10-17 14:30:27+02	2026-02-03 16:24:34.250794+01	2026-02-03 16:24:34.250798+01
893	107	133	\N	100	completed	2025-10-23 20:10:40+02	2026-02-03 16:24:34.2508+01	2026-02-03 16:24:34.250801+01
894	107	134	\N	3	inactive	2025-08-22 16:28:06+02	2026-02-03 16:24:34.250801+01	2026-02-03 16:24:34.250802+01
895	107	135	\N	100	completed	2025-10-07 15:19:29+02	2026-02-03 16:24:34.250803+01	2026-02-03 16:24:34.250804+01
896	107	136	\N	0	inactive	\N	2026-02-03 16:24:34.250804+01	2026-02-03 16:24:34.250805+01
897	107	137	\N	0	inactive	\N	2026-02-03 16:24:34.250806+01	2026-02-03 16:24:34.250806+01
898	107	114	\N	15	inactive	2025-10-02 16:53:47+02	2026-02-03 16:24:34.250807+01	2026-02-03 16:24:34.250808+01
899	107	140	\N	97	inactive	2025-10-24 00:14:20+02	2026-02-03 16:24:34.250809+01	2026-02-03 16:24:34.250809+01
900	107	138	\N	70	inactive	2025-10-27 14:05:33+01	2026-02-03 16:24:34.25081+01	2026-02-03 16:24:34.250811+01
901	107	116	\N	5	inactive	2025-10-24 04:49:51+02	2026-02-03 16:24:34.250812+01	2026-02-03 16:24:34.250813+01
902	107	139	\N	5	inactive	2025-10-24 04:49:35+02	2026-02-03 16:24:34.250814+01	2026-02-03 16:24:34.250814+01
903	107	118	\N	0	inactive	\N	2026-02-03 16:24:34.250815+01	2026-02-03 16:24:34.250816+01
904	107	117	\N	100	completed	2025-06-07 23:19:03+02	2026-02-03 16:24:34.250817+01	2026-02-03 16:24:34.250817+01
905	107	141	\N	0	inactive	\N	2026-02-03 16:24:34.250818+01	2026-02-03 16:24:34.250819+01
906	107	142	\N	0	inactive	\N	2026-02-03 16:24:34.250819+01	2026-02-03 16:24:34.25082+01
907	107	143	\N	0	inactive	\N	2026-02-03 16:24:34.250821+01	2026-02-03 16:24:34.250821+01
908	107	144	\N	0	inactive	\N	2026-02-03 16:24:34.250822+01	2026-02-03 16:24:34.250823+01
909	107	145	\N	0	inactive	\N	2026-02-03 16:24:34.250824+01	2026-02-03 16:24:34.250824+01
910	107	146	\N	0	inactive	\N	2026-02-03 16:24:34.250825+01	2026-02-03 16:24:34.250826+01
911	107	153	\N	0	inactive	\N	2026-02-03 16:24:34.250827+01	2026-02-03 16:24:34.250827+01
912	107	152	\N	0	inactive	\N	2026-02-03 16:24:34.250828+01	2026-02-03 16:24:34.250829+01
913	107	154	\N	0	inactive	\N	2026-02-03 16:24:34.25083+01	2026-02-03 16:24:34.25083+01
914	107	147	\N	60	inactive	2025-09-29 16:17:44+02	2026-02-03 16:24:34.250831+01	2026-02-03 16:24:34.250832+01
915	107	148	\N	0	inactive	\N	2026-02-03 16:24:34.250832+01	2026-02-03 16:24:34.250833+01
916	107	149	\N	0	inactive	\N	2026-02-03 16:24:34.250834+01	2026-02-03 16:24:34.250835+01
917	107	150	\N	0	inactive	\N	2026-02-03 16:24:34.250835+01	2026-02-03 16:24:34.250836+01
918	107	151	\N	0	inactive	\N	2026-02-03 16:24:34.250837+01	2026-02-03 16:24:34.250837+01
919	108	115	\N	100	completed	2025-06-10 11:28:06+02	2026-02-03 16:24:34.690462+01	2026-02-03 16:24:34.690466+01
920	108	133	\N	100	completed	2025-06-15 11:09:59+02	2026-02-03 16:24:34.690467+01	2026-02-03 16:24:34.690468+01
921	108	134	\N	100	completed	2025-06-18 11:20:16+02	2026-02-03 16:24:34.690469+01	2026-02-03 16:24:34.690469+01
922	108	135	\N	100	completed	2025-06-19 10:02:20+02	2026-02-03 16:24:34.69047+01	2026-02-03 16:24:34.690471+01
923	108	136	\N	100	completed	2025-06-20 11:15:53+02	2026-02-03 16:24:34.690471+01	2026-02-03 16:24:34.690472+01
924	108	137	\N	100	completed	2025-06-20 11:16:00+02	2026-02-03 16:24:34.690473+01	2026-02-03 16:24:34.690473+01
925	108	114	\N	100	completed	2025-06-12 16:16:25+02	2026-02-03 16:24:34.690474+01	2026-02-03 16:24:34.690475+01
926	108	140	\N	99	inactive	2025-07-11 15:38:01+02	2026-02-03 16:24:34.690476+01	2026-02-03 16:24:34.690477+01
927	108	138	\N	100	completed	2026-01-15 09:55:09+01	2026-02-03 16:24:34.690477+01	2026-02-03 16:24:34.690478+01
928	108	116	\N	100	completed	2025-09-01 12:03:32+02	2026-02-03 16:24:34.690479+01	2026-02-03 16:24:34.69048+01
929	108	139	\N	100	completed	2025-09-01 11:51:26+02	2026-02-03 16:24:34.69048+01	2026-02-03 16:24:34.690481+01
930	108	118	\N	0	inactive	\N	2026-02-03 16:24:34.690482+01	2026-02-03 16:24:34.690482+01
931	108	117	\N	0	inactive	\N	2026-02-03 16:24:34.690483+01	2026-02-03 16:24:34.690484+01
932	108	141	\N	100	completed	2025-09-09 08:18:27+02	2026-02-03 16:24:34.690485+01	2026-02-03 16:24:34.690486+01
933	108	142	\N	100	completed	2025-09-09 08:21:42+02	2026-02-03 16:24:34.690486+01	2026-02-03 16:24:34.690487+01
934	108	143	\N	100	completed	2025-09-24 10:48:54+02	2026-02-03 16:24:34.690488+01	2026-02-03 16:24:34.690489+01
935	108	144	\N	100	completed	2025-10-08 15:27:43+02	2026-02-03 16:24:34.690489+01	2026-02-03 16:24:34.69049+01
936	108	145	\N	100	completed	2025-10-22 15:47:05+02	2026-02-03 16:24:34.690491+01	2026-02-03 16:24:34.690491+01
937	108	146	\N	0	inactive	\N	2026-02-03 16:24:34.690492+01	2026-02-03 16:24:34.690493+01
938	108	153	\N	0	inactive	\N	2026-02-03 16:24:34.690494+01	2026-02-03 16:24:34.690494+01
939	108	152	\N	10	active	2026-02-03 16:24:28+01	2026-02-03 16:24:34.690495+01	2026-02-03 16:24:34.690496+01
940	108	154	\N	0	inactive	\N	2026-02-03 16:24:34.690496+01	2026-02-03 16:24:34.690497+01
941	108	147	\N	100	completed	2026-01-08 15:48:46+01	2026-02-03 16:24:34.690498+01	2026-02-03 16:24:34.690499+01
942	108	148	\N	0	inactive	\N	2026-02-03 16:24:34.690499+01	2026-02-03 16:24:34.6905+01
943	108	149	\N	0	inactive	\N	2026-02-03 16:24:34.690501+01	2026-02-03 16:24:34.690502+01
944	108	150	\N	0	inactive	\N	2026-02-03 16:24:34.690502+01	2026-02-03 16:24:34.690503+01
945	108	151	\N	0	inactive	\N	2026-02-03 16:24:34.690504+01	2026-02-03 16:24:34.690504+01
946	109	115	\N	0	inactive	\N	2026-02-03 16:24:35.211719+01	2026-02-03 16:24:35.211721+01
947	109	133	\N	8	inactive	2025-06-12 02:54:41+02	2026-02-03 16:24:35.211722+01	2026-02-03 16:24:35.211723+01
948	109	134	\N	0	inactive	\N	2026-02-03 16:24:35.211724+01	2026-02-03 16:24:35.211724+01
949	109	135	\N	0	inactive	\N	2026-02-03 16:24:35.211725+01	2026-02-03 16:24:35.211726+01
950	109	136	\N	0	inactive	\N	2026-02-03 16:24:35.211726+01	2026-02-03 16:24:35.211727+01
951	109	137	\N	0	inactive	\N	2026-02-03 16:24:35.211728+01	2026-02-03 16:24:35.211728+01
952	109	114	\N	8	inactive	2025-07-02 02:08:53+02	2026-02-03 16:24:35.211729+01	2026-02-03 16:24:35.21173+01
953	109	140	\N	0	inactive	\N	2026-02-03 16:24:35.21173+01	2026-02-03 16:24:35.211731+01
954	109	138	\N	0	inactive	\N	2026-02-03 16:24:35.211732+01	2026-02-03 16:24:35.211732+01
955	109	116	\N	0	inactive	\N	2026-02-03 16:24:35.211733+01	2026-02-03 16:24:35.211734+01
956	109	139	\N	0	inactive	\N	2026-02-03 16:24:35.211734+01	2026-02-03 16:24:35.211735+01
957	109	118	\N	0	inactive	\N	2026-02-03 16:24:35.211736+01	2026-02-03 16:24:35.211736+01
958	109	117	\N	0	inactive	\N	2026-02-03 16:24:35.211737+01	2026-02-03 16:24:35.211737+01
959	109	141	\N	0	inactive	\N	2026-02-03 16:24:35.211738+01	2026-02-03 16:24:35.211739+01
960	109	142	\N	0	inactive	\N	2026-02-03 16:24:35.211739+01	2026-02-03 16:24:35.21174+01
961	109	143	\N	0	inactive	\N	2026-02-03 16:24:35.211741+01	2026-02-03 16:24:35.211741+01
962	109	144	\N	0	inactive	\N	2026-02-03 16:24:35.211742+01	2026-02-03 16:24:35.211743+01
963	109	145	\N	0	inactive	\N	2026-02-03 16:24:35.211743+01	2026-02-03 16:24:35.211744+01
964	109	146	\N	0	inactive	\N	2026-02-03 16:24:35.211745+01	2026-02-03 16:24:35.211745+01
965	109	153	\N	0	inactive	\N	2026-02-03 16:24:35.211746+01	2026-02-03 16:24:35.211746+01
966	109	152	\N	0	inactive	\N	2026-02-03 16:24:35.211747+01	2026-02-03 16:24:35.211748+01
967	109	154	\N	0	inactive	\N	2026-02-03 16:24:35.211748+01	2026-02-03 16:24:35.211749+01
968	109	147	\N	0	inactive	\N	2026-02-03 16:24:35.21175+01	2026-02-03 16:24:35.21175+01
969	109	148	\N	0	inactive	\N	2026-02-03 16:24:35.211751+01	2026-02-03 16:24:35.211752+01
970	109	149	\N	0	inactive	\N	2026-02-03 16:24:35.211752+01	2026-02-03 16:24:35.211753+01
971	109	150	\N	0	inactive	\N	2026-02-03 16:24:35.211754+01	2026-02-03 16:24:35.211754+01
972	109	151	\N	0	inactive	\N	2026-02-03 16:24:35.211755+01	2026-02-03 16:24:35.211756+01
973	110	115	\N	0	inactive	\N	2026-02-03 16:24:35.649039+01	2026-02-03 16:24:35.649042+01
974	110	133	\N	100	completed	2025-05-25 14:52:31+02	2026-02-03 16:24:35.649043+01	2026-02-03 16:24:35.649043+01
975	110	134	\N	100	completed	2025-05-25 15:33:46+02	2026-02-03 16:24:35.649044+01	2026-02-03 16:24:35.649044+01
976	110	135	\N	0	inactive	\N	2026-02-03 16:24:35.649045+01	2026-02-03 16:24:35.649045+01
977	110	136	\N	11	inactive	2025-05-25 16:19:18+02	2026-02-03 16:24:35.649046+01	2026-02-03 16:24:35.649047+01
978	110	137	\N	0	inactive	\N	2026-02-03 16:24:35.649047+01	2026-02-03 16:24:35.649048+01
979	110	114	\N	0	inactive	\N	2026-02-03 16:24:35.649048+01	2026-02-03 16:24:35.649049+01
980	110	140	\N	0	inactive	\N	2026-02-03 16:24:35.649049+01	2026-02-03 16:24:35.64905+01
981	110	138	\N	4	inactive	2025-05-26 13:23:01+02	2026-02-03 16:24:35.64905+01	2026-02-03 16:24:35.649051+01
982	110	116	\N	0	inactive	\N	2026-02-03 16:24:35.649051+01	2026-02-03 16:24:35.649052+01
983	110	139	\N	0	inactive	\N	2026-02-03 16:24:35.649052+01	2026-02-03 16:24:35.649053+01
984	110	117	\N	0	inactive	\N	2026-02-03 16:24:35.649053+01	2026-02-03 16:24:35.649054+01
985	110	118	\N	0	inactive	\N	2026-02-03 16:24:35.649055+01	2026-02-03 16:24:35.649055+01
986	110	141	\N	0	inactive	\N	2026-02-03 16:24:35.649056+01	2026-02-03 16:24:35.649056+01
987	110	142	\N	0	inactive	\N	2026-02-03 16:24:35.649057+01	2026-02-03 16:24:35.649057+01
988	110	143	\N	0	inactive	\N	2026-02-03 16:24:35.649058+01	2026-02-03 16:24:35.649058+01
989	110	144	\N	0	inactive	\N	2026-02-03 16:24:35.649059+01	2026-02-03 16:24:35.649059+01
990	110	145	\N	0	inactive	\N	2026-02-03 16:24:35.64906+01	2026-02-03 16:24:35.64906+01
991	110	146	\N	0	inactive	\N	2026-02-03 16:24:35.649061+01	2026-02-03 16:24:35.649061+01
992	110	153	\N	0	inactive	\N	2026-02-03 16:24:35.649062+01	2026-02-03 16:24:35.649062+01
993	110	152	\N	0	inactive	\N	2026-02-03 16:24:35.649063+01	2026-02-03 16:24:35.649064+01
994	110	154	\N	0	inactive	\N	2026-02-03 16:24:35.649064+01	2026-02-03 16:24:35.649065+01
995	110	147	\N	0	inactive	\N	2026-02-03 16:24:35.649065+01	2026-02-03 16:24:35.649066+01
996	110	148	\N	0	inactive	\N	2026-02-03 16:24:35.649066+01	2026-02-03 16:24:35.649067+01
997	110	149	\N	0	inactive	\N	2026-02-03 16:24:35.649067+01	2026-02-03 16:24:35.649068+01
998	110	150	\N	0	inactive	\N	2026-02-03 16:24:35.649068+01	2026-02-03 16:24:35.649069+01
999	110	151	\N	0	inactive	\N	2026-02-03 16:24:35.649069+01	2026-02-03 16:24:35.64907+01
1000	111	115	\N	0	inactive	\N	2026-02-03 16:24:36.1231+01	2026-02-03 16:24:36.123103+01
1001	111	133	\N	0	inactive	\N	2026-02-03 16:24:36.123103+01	2026-02-03 16:24:36.123104+01
1002	111	134	\N	0	inactive	\N	2026-02-03 16:24:36.123105+01	2026-02-03 16:24:36.123105+01
1003	111	135	\N	0	inactive	\N	2026-02-03 16:24:36.123106+01	2026-02-03 16:24:36.123106+01
1004	111	136	\N	0	inactive	\N	2026-02-03 16:24:36.123107+01	2026-02-03 16:24:36.123108+01
1005	111	137	\N	0	inactive	\N	2026-02-03 16:24:36.123108+01	2026-02-03 16:24:36.123109+01
1006	111	114	\N	0	inactive	\N	2026-02-03 16:24:36.123109+01	2026-02-03 16:24:36.12311+01
1007	111	140	\N	0	inactive	\N	2026-02-03 16:24:36.12311+01	2026-02-03 16:24:36.123111+01
1008	111	138	\N	0	inactive	\N	2026-02-03 16:24:36.123111+01	2026-02-03 16:24:36.123112+01
1009	111	116	\N	0	inactive	\N	2026-02-03 16:24:36.123112+01	2026-02-03 16:24:36.123113+01
1010	111	139	\N	0	inactive	\N	2026-02-03 16:24:36.123114+01	2026-02-03 16:24:36.123114+01
1011	111	117	\N	0	inactive	\N	2026-02-03 16:24:36.123115+01	2026-02-03 16:24:36.123115+01
1012	111	118	\N	0	inactive	\N	2026-02-03 16:24:36.123116+01	2026-02-03 16:24:36.123116+01
1013	111	141	\N	0	inactive	\N	2026-02-03 16:24:36.123117+01	2026-02-03 16:24:36.123117+01
1014	111	142	\N	0	inactive	\N	2026-02-03 16:24:36.123118+01	2026-02-03 16:24:36.123118+01
1015	111	143	\N	0	inactive	\N	2026-02-03 16:24:36.123119+01	2026-02-03 16:24:36.123119+01
1016	111	144	\N	0	inactive	\N	2026-02-03 16:24:36.12312+01	2026-02-03 16:24:36.123121+01
1017	111	145	\N	0	inactive	\N	2026-02-03 16:24:36.123121+01	2026-02-03 16:24:36.123122+01
1018	111	146	\N	0	inactive	\N	2026-02-03 16:24:36.123123+01	2026-02-03 16:24:36.123123+01
1019	111	153	\N	0	inactive	\N	2026-02-03 16:24:36.123124+01	2026-02-03 16:24:36.123124+01
1020	111	152	\N	0	inactive	\N	2026-02-03 16:24:36.123125+01	2026-02-03 16:24:36.123125+01
1021	111	154	\N	0	inactive	\N	2026-02-03 16:24:36.123126+01	2026-02-03 16:24:36.123126+01
1022	111	147	\N	0	inactive	\N	2026-02-03 16:24:36.123127+01	2026-02-03 16:24:36.123127+01
1023	111	148	\N	0	inactive	\N	2026-02-03 16:24:36.123128+01	2026-02-03 16:24:36.123129+01
1024	111	149	\N	0	inactive	\N	2026-02-03 16:24:36.123129+01	2026-02-03 16:24:36.12313+01
1025	111	150	\N	0	inactive	\N	2026-02-03 16:24:36.12313+01	2026-02-03 16:24:36.123131+01
1026	111	151	\N	0	inactive	\N	2026-02-03 16:24:36.123132+01	2026-02-03 16:24:36.123132+01
1027	112	114	\N	0	inactive	\N	2026-02-03 16:24:36.54805+01	2026-02-03 16:24:36.548052+01
1028	112	115	\N	0	inactive	\N	2026-02-03 16:24:36.548053+01	2026-02-03 16:24:36.548053+01
1029	112	133	\N	0	inactive	\N	2026-02-03 16:24:36.548054+01	2026-02-03 16:24:36.548055+01
1030	112	134	\N	0	inactive	\N	2026-02-03 16:24:36.548055+01	2026-02-03 16:24:36.548056+01
1031	112	135	\N	0	inactive	\N	2026-02-03 16:24:36.548056+01	2026-02-03 16:24:36.548057+01
1032	112	136	\N	0	inactive	\N	2026-02-03 16:24:36.548057+01	2026-02-03 16:24:36.548058+01
1033	112	137	\N	0	inactive	\N	2026-02-03 16:24:36.548058+01	2026-02-03 16:24:36.548059+01
1034	112	140	\N	0	inactive	\N	2026-02-03 16:24:36.548059+01	2026-02-03 16:24:36.54806+01
1035	112	138	\N	0	inactive	\N	2026-02-03 16:24:36.54806+01	2026-02-03 16:24:36.548061+01
1036	112	116	\N	0	inactive	\N	2026-02-03 16:24:36.548061+01	2026-02-03 16:24:36.548062+01
1037	112	139	\N	0	inactive	\N	2026-02-03 16:24:36.548062+01	2026-02-03 16:24:36.548063+01
1038	112	117	\N	0	inactive	\N	2026-02-03 16:24:36.548064+01	2026-02-03 16:24:36.548064+01
1039	112	118	\N	0	inactive	\N	2026-02-03 16:24:36.548065+01	2026-02-03 16:24:36.548065+01
1040	112	141	\N	0	inactive	\N	2026-02-03 16:24:36.548066+01	2026-02-03 16:24:36.548066+01
1041	112	142	\N	0	inactive	\N	2026-02-03 16:24:36.548067+01	2026-02-03 16:24:36.548067+01
1042	112	143	\N	0	inactive	\N	2026-02-03 16:24:36.548068+01	2026-02-03 16:24:36.548068+01
1043	112	144	\N	0	inactive	\N	2026-02-03 16:24:36.548069+01	2026-02-03 16:24:36.548069+01
1044	112	145	\N	0	inactive	\N	2026-02-03 16:24:36.54807+01	2026-02-03 16:24:36.54807+01
1045	112	146	\N	0	inactive	\N	2026-02-03 16:24:36.548071+01	2026-02-03 16:24:36.548072+01
1046	112	153	\N	0	inactive	\N	2026-02-03 16:24:36.548072+01	2026-02-03 16:24:36.548073+01
1047	112	152	\N	0	inactive	\N	2026-02-03 16:24:36.548073+01	2026-02-03 16:24:36.548074+01
1048	112	154	\N	0	inactive	\N	2026-02-03 16:24:36.548074+01	2026-02-03 16:24:36.548075+01
1049	112	147	\N	0	inactive	\N	2026-02-03 16:24:36.548075+01	2026-02-03 16:24:36.548076+01
1050	112	148	\N	0	inactive	\N	2026-02-03 16:24:36.548076+01	2026-02-03 16:24:36.548077+01
1051	112	149	\N	0	inactive	\N	2026-02-03 16:24:36.548077+01	2026-02-03 16:24:36.548078+01
1052	112	150	\N	0	inactive	\N	2026-02-03 16:24:36.548078+01	2026-02-03 16:24:36.548079+01
1053	112	151	\N	0	inactive	\N	2026-02-03 16:24:36.54808+01	2026-02-03 16:24:36.54808+01
1054	113	114	\N	0	inactive	\N	2026-02-03 16:24:37.009888+01	2026-02-03 16:24:37.00989+01
1055	113	115	\N	0	inactive	\N	2026-02-03 16:24:37.009891+01	2026-02-03 16:24:37.009891+01
1056	113	133	\N	0	inactive	\N	2026-02-03 16:24:37.009892+01	2026-02-03 16:24:37.009892+01
1057	113	134	\N	0	inactive	\N	2026-02-03 16:24:37.009893+01	2026-02-03 16:24:37.009893+01
1058	113	135	\N	0	inactive	\N	2026-02-03 16:24:37.009894+01	2026-02-03 16:24:37.009894+01
1059	113	136	\N	0	inactive	\N	2026-02-03 16:24:37.009895+01	2026-02-03 16:24:37.009896+01
1060	113	137	\N	0	inactive	\N	2026-02-03 16:24:37.009896+01	2026-02-03 16:24:37.009897+01
1061	113	140	\N	0	inactive	\N	2026-02-03 16:24:37.009897+01	2026-02-03 16:24:37.009898+01
1062	113	138	\N	0	inactive	\N	2026-02-03 16:24:37.009898+01	2026-02-03 16:24:37.009899+01
1063	113	116	\N	0	inactive	\N	2026-02-03 16:24:37.009899+01	2026-02-03 16:24:37.0099+01
1064	113	139	\N	0	inactive	\N	2026-02-03 16:24:37.0099+01	2026-02-03 16:24:37.009901+01
1065	113	117	\N	0	inactive	\N	2026-02-03 16:24:37.009901+01	2026-02-03 16:24:37.009902+01
1066	113	118	\N	0	inactive	\N	2026-02-03 16:24:37.009902+01	2026-02-03 16:24:37.009903+01
1067	113	141	\N	0	inactive	\N	2026-02-03 16:24:37.009904+01	2026-02-03 16:24:37.009904+01
1068	113	142	\N	0	inactive	\N	2026-02-03 16:24:37.009905+01	2026-02-03 16:24:37.009905+01
1069	113	143	\N	0	inactive	\N	2026-02-03 16:24:37.009906+01	2026-02-03 16:24:37.009906+01
1070	113	144	\N	0	inactive	\N	2026-02-03 16:24:37.009907+01	2026-02-03 16:24:37.009908+01
1071	113	145	\N	0	inactive	\N	2026-02-03 16:24:37.009908+01	2026-02-03 16:24:37.009909+01
1072	113	146	\N	0	inactive	\N	2026-02-03 16:24:37.009909+01	2026-02-03 16:24:37.00991+01
1073	113	153	\N	0	inactive	\N	2026-02-03 16:24:37.00991+01	2026-02-03 16:24:37.009911+01
1074	113	152	\N	0	inactive	\N	2026-02-03 16:24:37.009911+01	2026-02-03 16:24:37.009912+01
1075	113	154	\N	0	inactive	\N	2026-02-03 16:24:37.009912+01	2026-02-03 16:24:37.009913+01
1076	113	147	\N	0	inactive	\N	2026-02-03 16:24:37.009913+01	2026-02-03 16:24:37.009914+01
1077	113	148	\N	0	inactive	\N	2026-02-03 16:24:37.009914+01	2026-02-03 16:24:37.009915+01
1078	113	149	\N	0	inactive	\N	2026-02-03 16:24:37.009915+01	2026-02-03 16:24:37.009916+01
1079	113	150	\N	0	inactive	\N	2026-02-03 16:24:37.009916+01	2026-02-03 16:24:37.009917+01
1080	113	151	\N	0	inactive	\N	2026-02-03 16:24:37.009917+01	2026-02-03 16:24:37.009918+01
1081	114	114	\N	0	inactive	\N	2026-02-03 16:24:37.427365+01	2026-02-03 16:24:37.427367+01
1082	114	115	\N	0	inactive	\N	2026-02-03 16:24:37.427368+01	2026-02-03 16:24:37.427369+01
1083	114	133	\N	0	inactive	\N	2026-02-03 16:24:37.427369+01	2026-02-03 16:24:37.42737+01
1084	114	134	\N	0	inactive	\N	2026-02-03 16:24:37.427371+01	2026-02-03 16:24:37.427371+01
1085	114	135	\N	0	inactive	\N	2026-02-03 16:24:37.427372+01	2026-02-03 16:24:37.427372+01
1086	114	136	\N	0	inactive	\N	2026-02-03 16:24:37.427373+01	2026-02-03 16:24:37.427373+01
1087	114	137	\N	0	inactive	\N	2026-02-03 16:24:37.427374+01	2026-02-03 16:24:37.427374+01
1088	114	140	\N	0	inactive	\N	2026-02-03 16:24:37.427375+01	2026-02-03 16:24:37.427375+01
1089	114	138	\N	0	inactive	\N	2026-02-03 16:24:37.427376+01	2026-02-03 16:24:37.427376+01
1090	114	116	\N	0	inactive	\N	2026-02-03 16:24:37.427377+01	2026-02-03 16:24:37.427378+01
1091	114	139	\N	0	inactive	\N	2026-02-03 16:24:37.427378+01	2026-02-03 16:24:37.427379+01
1092	114	117	\N	0	inactive	\N	2026-02-03 16:24:37.427379+01	2026-02-03 16:24:37.42738+01
1093	114	118	\N	0	inactive	\N	2026-02-03 16:24:37.42738+01	2026-02-03 16:24:37.427381+01
1094	114	141	\N	0	inactive	\N	2026-02-03 16:24:37.427382+01	2026-02-03 16:24:37.427382+01
1095	114	142	\N	0	inactive	\N	2026-02-03 16:24:37.427383+01	2026-02-03 16:24:37.427383+01
1096	114	143	\N	0	inactive	\N	2026-02-03 16:24:37.427384+01	2026-02-03 16:24:37.427384+01
1097	114	144	\N	0	inactive	\N	2026-02-03 16:24:37.427385+01	2026-02-03 16:24:37.427385+01
1098	114	145	\N	0	inactive	\N	2026-02-03 16:24:37.427386+01	2026-02-03 16:24:37.427386+01
1099	114	146	\N	0	inactive	\N	2026-02-03 16:24:37.427387+01	2026-02-03 16:24:37.427387+01
1100	114	153	\N	0	inactive	\N	2026-02-03 16:24:37.427388+01	2026-02-03 16:24:37.427389+01
1101	114	147	\N	0	inactive	\N	2026-02-03 16:24:37.427389+01	2026-02-03 16:24:37.42739+01
1102	114	148	\N	0	inactive	\N	2026-02-03 16:24:37.42739+01	2026-02-03 16:24:37.427391+01
1103	114	149	\N	0	inactive	\N	2026-02-03 16:24:37.427391+01	2026-02-03 16:24:37.427392+01
1104	114	150	\N	0	inactive	\N	2026-02-03 16:24:37.427392+01	2026-02-03 16:24:37.427393+01
1105	114	151	\N	0	inactive	\N	2026-02-03 16:24:37.427394+01	2026-02-03 16:24:37.427394+01
1106	114	152	\N	0	inactive	\N	2026-02-03 16:24:37.427395+01	2026-02-03 16:24:37.427395+01
1107	114	154	\N	0	inactive	\N	2026-02-03 16:24:37.427396+01	2026-02-03 16:24:37.427396+01
1108	115	114	\N	0	inactive	\N	2026-02-03 16:24:37.977868+01	2026-02-03 16:24:37.977871+01
1109	115	115	\N	0	inactive	\N	2026-02-03 16:24:37.977872+01	2026-02-03 16:24:37.977872+01
1110	115	133	\N	0	inactive	\N	2026-02-03 16:24:37.977873+01	2026-02-03 16:24:37.977873+01
1111	115	134	\N	0	inactive	\N	2026-02-03 16:24:37.977874+01	2026-02-03 16:24:37.977875+01
1112	115	135	\N	0	inactive	\N	2026-02-03 16:24:37.977875+01	2026-02-03 16:24:37.977876+01
1113	115	136	\N	0	inactive	\N	2026-02-03 16:24:37.977876+01	2026-02-03 16:24:37.977877+01
1114	115	137	\N	0	inactive	\N	2026-02-03 16:24:37.977877+01	2026-02-03 16:24:37.977878+01
1115	115	140	\N	0	inactive	\N	2026-02-03 16:24:37.977878+01	2026-02-03 16:24:37.977879+01
1116	115	138	\N	0	inactive	\N	2026-02-03 16:24:37.97788+01	2026-02-03 16:24:37.97788+01
1117	115	116	\N	0	inactive	\N	2026-02-03 16:24:37.977881+01	2026-02-03 16:24:37.977881+01
1118	115	139	\N	0	inactive	\N	2026-02-03 16:24:37.977882+01	2026-02-03 16:24:37.977882+01
1119	115	117	\N	0	inactive	\N	2026-02-03 16:24:37.977883+01	2026-02-03 16:24:37.977883+01
1120	115	118	\N	0	inactive	\N	2026-02-03 16:24:37.977884+01	2026-02-03 16:24:37.977885+01
1121	115	141	\N	0	inactive	\N	2026-02-03 16:24:37.977885+01	2026-02-03 16:24:37.977886+01
1122	115	142	\N	0	inactive	\N	2026-02-03 16:24:37.977886+01	2026-02-03 16:24:37.977887+01
1123	115	143	\N	0	inactive	\N	2026-02-03 16:24:37.977888+01	2026-02-03 16:24:37.977888+01
1124	115	144	\N	0	inactive	\N	2026-02-03 16:24:37.977889+01	2026-02-03 16:24:37.977889+01
1125	115	145	\N	0	inactive	\N	2026-02-03 16:24:37.97789+01	2026-02-03 16:24:37.97789+01
1126	115	146	\N	0	inactive	\N	2026-02-03 16:24:37.977891+01	2026-02-03 16:24:37.977891+01
1127	115	153	\N	0	inactive	\N	2026-02-03 16:24:37.977892+01	2026-02-03 16:24:37.977892+01
1128	115	147	\N	0	inactive	\N	2026-02-03 16:24:37.977893+01	2026-02-03 16:24:37.977894+01
1129	115	148	\N	0	inactive	\N	2026-02-03 16:24:37.977894+01	2026-02-03 16:24:37.977895+01
1130	115	149	\N	0	inactive	\N	2026-02-03 16:24:37.977895+01	2026-02-03 16:24:37.977896+01
1131	115	150	\N	0	inactive	\N	2026-02-03 16:24:37.977896+01	2026-02-03 16:24:37.977897+01
1132	115	151	\N	0	inactive	\N	2026-02-03 16:24:37.977897+01	2026-02-03 16:24:37.977898+01
1133	115	152	\N	0	inactive	\N	2026-02-03 16:24:37.977899+01	2026-02-03 16:24:37.977899+01
1134	115	154	\N	0	inactive	\N	2026-02-03 16:24:37.9779+01	2026-02-03 16:24:37.9779+01
1135	116	114	\N	0	inactive	\N	2026-02-03 16:24:38.39857+01	2026-02-03 16:24:38.398573+01
1136	116	115	\N	0	inactive	\N	2026-02-03 16:24:38.398573+01	2026-02-03 16:24:38.398574+01
1137	116	133	\N	0	inactive	\N	2026-02-03 16:24:38.398575+01	2026-02-03 16:24:38.398575+01
1138	116	134	\N	0	inactive	\N	2026-02-03 16:24:38.398576+01	2026-02-03 16:24:38.398576+01
1139	116	135	\N	0	inactive	\N	2026-02-03 16:24:38.398577+01	2026-02-03 16:24:38.398577+01
1140	116	136	\N	0	inactive	\N	2026-02-03 16:24:38.398578+01	2026-02-03 16:24:38.398578+01
1141	116	137	\N	0	inactive	\N	2026-02-03 16:24:38.398579+01	2026-02-03 16:24:38.398579+01
1142	116	140	\N	0	inactive	\N	2026-02-03 16:24:38.39858+01	2026-02-03 16:24:38.39858+01
1143	116	138	\N	0	inactive	\N	2026-02-03 16:24:38.398581+01	2026-02-03 16:24:38.398581+01
1144	116	116	\N	0	inactive	\N	2026-02-03 16:24:38.398582+01	2026-02-03 16:24:38.398582+01
1145	116	139	\N	0	inactive	\N	2026-02-03 16:24:38.398583+01	2026-02-03 16:24:38.398583+01
1146	116	117	\N	0	inactive	\N	2026-02-03 16:24:38.398584+01	2026-02-03 16:24:38.398584+01
1147	116	118	\N	50	inactive	2025-10-02 11:32:41+02	2026-02-03 16:24:38.398585+01	2026-02-03 16:24:38.398585+01
1148	116	141	\N	0	inactive	\N	2026-02-03 16:24:38.398586+01	2026-02-03 16:24:38.398587+01
1149	116	142	\N	0	inactive	\N	2026-02-03 16:24:38.398587+01	2026-02-03 16:24:38.398588+01
1150	116	143	\N	0	inactive	\N	2026-02-03 16:24:38.398588+01	2026-02-03 16:24:38.398589+01
1151	116	144	\N	0	inactive	\N	2026-02-03 16:24:38.398589+01	2026-02-03 16:24:38.39859+01
1152	116	145	\N	0	inactive	\N	2026-02-03 16:24:38.398591+01	2026-02-03 16:24:38.398591+01
1153	116	146	\N	0	inactive	\N	2026-02-03 16:24:38.398592+01	2026-02-03 16:24:38.398592+01
1154	116	153	\N	0	inactive	\N	2026-02-03 16:24:38.398593+01	2026-02-03 16:24:38.398593+01
1155	116	147	\N	0	inactive	\N	2026-02-03 16:24:38.398594+01	2026-02-03 16:24:38.398594+01
1156	116	148	\N	0	inactive	\N	2026-02-03 16:24:38.398595+01	2026-02-03 16:24:38.398595+01
1157	116	149	\N	0	inactive	\N	2026-02-03 16:24:38.398596+01	2026-02-03 16:24:38.398596+01
1158	116	150	\N	0	inactive	\N	2026-02-03 16:24:38.398597+01	2026-02-03 16:24:38.398597+01
1159	116	151	\N	0	inactive	\N	2026-02-03 16:24:38.398598+01	2026-02-03 16:24:38.398598+01
1160	116	152	\N	0	inactive	\N	2026-02-03 16:24:38.398599+01	2026-02-03 16:24:38.398599+01
1161	116	154	\N	0	inactive	\N	2026-02-03 16:24:38.3986+01	2026-02-03 16:24:38.3986+01
1162	118	156	\N	0	inactive	\N	2026-02-03 16:24:39.561873+01	2026-02-03 16:24:39.561877+01
1163	118	177	\N	0	inactive	\N	2026-02-03 16:24:39.561878+01	2026-02-03 16:24:39.561879+01
1164	118	178	\N	0	inactive	\N	2026-02-03 16:24:39.561879+01	2026-02-03 16:24:39.56188+01
1165	118	179	\N	0	inactive	\N	2026-02-03 16:24:39.561881+01	2026-02-03 16:24:39.561881+01
1166	118	180	\N	0	inactive	\N	2026-02-03 16:24:39.561882+01	2026-02-03 16:24:39.561883+01
1167	118	181	\N	0	inactive	\N	2026-02-03 16:24:39.561883+01	2026-02-03 16:24:39.561884+01
1168	118	182	\N	0	inactive	\N	2026-02-03 16:24:39.561885+01	2026-02-03 16:24:39.561885+01
1169	118	183	\N	0	inactive	\N	2026-02-03 16:24:39.561886+01	2026-02-03 16:24:39.561887+01
1170	118	184	\N	0	inactive	\N	2026-02-03 16:24:39.561888+01	2026-02-03 16:24:39.561888+01
1171	118	185	\N	0	inactive	\N	2026-02-03 16:24:39.561889+01	2026-02-03 16:24:39.56189+01
1172	118	186	\N	0	inactive	\N	2026-02-03 16:24:39.56189+01	2026-02-03 16:24:39.561891+01
1173	118	157	\N	0	inactive	\N	2026-02-03 16:24:39.561892+01	2026-02-03 16:24:39.561892+01
1174	118	160	\N	0	inactive	\N	2026-02-03 16:24:39.561893+01	2026-02-03 16:24:39.561893+01
1175	118	187	\N	0	inactive	\N	2026-02-03 16:24:39.561894+01	2026-02-03 16:24:39.561895+01
1176	118	161	\N	0	inactive	\N	2026-02-03 16:24:39.561895+01	2026-02-03 16:24:39.561896+01
1177	118	188	\N	0	inactive	\N	2026-02-03 16:24:39.561897+01	2026-02-03 16:24:39.561897+01
1178	118	162	\N	0	inactive	\N	2026-02-03 16:24:39.561898+01	2026-02-03 16:24:39.561899+01
1179	118	189	\N	0	inactive	\N	2026-02-03 16:24:39.561899+01	2026-02-03 16:24:39.5619+01
1180	118	158	\N	0	inactive	\N	2026-02-03 16:24:39.561901+01	2026-02-03 16:24:39.561901+01
1181	118	190	\N	0	inactive	\N	2026-02-03 16:24:39.561902+01	2026-02-03 16:24:39.561902+01
1182	118	159	\N	0	inactive	\N	2026-02-03 16:24:39.561903+01	2026-02-03 16:24:39.561904+01
1183	119	156	\N	0	inactive	\N	2026-02-03 16:24:39.968598+01	2026-02-03 16:24:39.968601+01
1184	119	177	\N	0	inactive	\N	2026-02-03 16:24:39.968602+01	2026-02-03 16:24:39.968602+01
1185	119	178	\N	0	inactive	\N	2026-02-03 16:24:39.968603+01	2026-02-03 16:24:39.968603+01
1186	119	179	\N	0	inactive	\N	2026-02-03 16:24:39.968604+01	2026-02-03 16:24:39.968605+01
1187	119	180	\N	0	inactive	\N	2026-02-03 16:24:39.968605+01	2026-02-03 16:24:39.968606+01
1188	119	181	\N	0	inactive	\N	2026-02-03 16:24:39.968606+01	2026-02-03 16:24:39.968607+01
1189	119	182	\N	0	inactive	\N	2026-02-03 16:24:39.968607+01	2026-02-03 16:24:39.968608+01
1190	119	183	\N	0	inactive	\N	2026-02-03 16:24:39.968608+01	2026-02-03 16:24:39.968609+01
1191	119	184	\N	0	inactive	\N	2026-02-03 16:24:39.96861+01	2026-02-03 16:24:39.96861+01
1192	119	185	\N	0	inactive	\N	2026-02-03 16:24:39.968611+01	2026-02-03 16:24:39.968611+01
1193	119	186	\N	0	inactive	\N	2026-02-03 16:24:39.968612+01	2026-02-03 16:24:39.968612+01
1194	119	157	\N	0	inactive	\N	2026-02-03 16:24:39.968613+01	2026-02-03 16:24:39.968613+01
1195	119	160	\N	0	inactive	\N	2026-02-03 16:24:39.968614+01	2026-02-03 16:24:39.968614+01
1196	119	187	\N	0	inactive	\N	2026-02-03 16:24:39.968615+01	2026-02-03 16:24:39.968615+01
1197	119	161	\N	0	inactive	\N	2026-02-03 16:24:39.968616+01	2026-02-03 16:24:39.968616+01
1198	119	188	\N	0	inactive	\N	2026-02-03 16:24:39.968617+01	2026-02-03 16:24:39.968617+01
1199	119	162	\N	0	inactive	\N	2026-02-03 16:24:39.968618+01	2026-02-03 16:24:39.968618+01
1200	119	189	\N	0	inactive	\N	2026-02-03 16:24:39.968619+01	2026-02-03 16:24:39.96862+01
1201	119	158	\N	0	inactive	\N	2026-02-03 16:24:39.96862+01	2026-02-03 16:24:39.968621+01
1202	119	190	\N	0	inactive	\N	2026-02-03 16:24:39.968621+01	2026-02-03 16:24:39.968622+01
1203	119	159	\N	0	inactive	\N	2026-02-03 16:24:39.968623+01	2026-02-03 16:24:39.968623+01
1204	120	156	\N	0	inactive	\N	2026-02-03 16:24:40.438662+01	2026-02-03 16:24:40.438669+01
1205	120	177	\N	0	inactive	\N	2026-02-03 16:24:40.438672+01	2026-02-03 16:24:40.438688+01
1206	120	178	\N	0	inactive	\N	2026-02-03 16:24:40.43869+01	2026-02-03 16:24:40.438691+01
1207	120	179	\N	0	inactive	\N	2026-02-03 16:24:40.438692+01	2026-02-03 16:24:40.438693+01
1208	120	180	\N	0	inactive	\N	2026-02-03 16:24:40.438694+01	2026-02-03 16:24:40.438695+01
1209	120	181	\N	0	inactive	\N	2026-02-03 16:24:40.438696+01	2026-02-03 16:24:40.438698+01
1210	120	182	\N	0	inactive	\N	2026-02-03 16:24:40.438699+01	2026-02-03 16:24:40.4387+01
1211	120	183	\N	0	inactive	\N	2026-02-03 16:24:40.438701+01	2026-02-03 16:24:40.438702+01
1212	120	184	\N	0	inactive	\N	2026-02-03 16:24:40.438703+01	2026-02-03 16:24:40.438704+01
1213	120	185	\N	0	inactive	\N	2026-02-03 16:24:40.438706+01	2026-02-03 16:24:40.438707+01
1214	120	186	\N	0	inactive	\N	2026-02-03 16:24:40.438708+01	2026-02-03 16:24:40.438709+01
1215	120	157	\N	0	inactive	\N	2026-02-03 16:24:40.43871+01	2026-02-03 16:24:40.438711+01
1216	120	160	\N	0	inactive	\N	2026-02-03 16:24:40.438712+01	2026-02-03 16:24:40.438713+01
1217	120	187	\N	0	inactive	\N	2026-02-03 16:24:40.438714+01	2026-02-03 16:24:40.438716+01
1218	120	161	\N	0	inactive	\N	2026-02-03 16:24:40.438717+01	2026-02-03 16:24:40.438718+01
1219	120	188	\N	0	inactive	\N	2026-02-03 16:24:40.438719+01	2026-02-03 16:24:40.43872+01
1220	120	162	\N	0	inactive	\N	2026-02-03 16:24:40.438721+01	2026-02-03 16:24:40.438723+01
1221	120	189	\N	0	inactive	\N	2026-02-03 16:24:40.438724+01	2026-02-03 16:24:40.438725+01
1222	120	158	\N	0	inactive	\N	2026-02-03 16:24:40.438726+01	2026-02-03 16:24:40.438727+01
1223	120	190	\N	0	inactive	\N	2026-02-03 16:24:40.438728+01	2026-02-03 16:24:40.438729+01
1224	120	159	\N	0	inactive	\N	2026-02-03 16:24:40.438731+01	2026-02-03 16:24:40.438732+01
1225	121	156	\N	0	inactive	\N	2026-02-03 16:24:40.844032+01	2026-02-03 16:24:40.844035+01
1226	121	177	\N	0	inactive	\N	2026-02-03 16:24:40.844036+01	2026-02-03 16:24:40.844037+01
1227	121	178	\N	0	inactive	\N	2026-02-03 16:24:40.844037+01	2026-02-03 16:24:40.844038+01
1228	121	179	\N	0	inactive	\N	2026-02-03 16:24:40.844039+01	2026-02-03 16:24:40.844039+01
1229	121	180	\N	0	inactive	\N	2026-02-03 16:24:40.84404+01	2026-02-03 16:24:40.84404+01
1230	121	181	\N	0	inactive	\N	2026-02-03 16:24:40.844041+01	2026-02-03 16:24:40.844042+01
1231	121	182	\N	0	inactive	\N	2026-02-03 16:24:40.844042+01	2026-02-03 16:24:40.844043+01
1232	121	183	\N	0	inactive	\N	2026-02-03 16:24:40.844043+01	2026-02-03 16:24:40.844044+01
1233	121	184	\N	0	inactive	\N	2026-02-03 16:24:40.844044+01	2026-02-03 16:24:40.844045+01
1234	121	185	\N	0	inactive	\N	2026-02-03 16:24:40.844045+01	2026-02-03 16:24:40.844046+01
1235	121	186	\N	0	inactive	\N	2026-02-03 16:24:40.844047+01	2026-02-03 16:24:40.844047+01
1236	121	157	\N	0	inactive	\N	2026-02-03 16:24:40.844048+01	2026-02-03 16:24:40.844049+01
1237	121	160	\N	0	inactive	\N	2026-02-03 16:24:40.844049+01	2026-02-03 16:24:40.84405+01
1238	121	187	\N	0	inactive	\N	2026-02-03 16:24:40.84405+01	2026-02-03 16:24:40.844051+01
1239	121	161	\N	0	inactive	\N	2026-02-03 16:24:40.844051+01	2026-02-03 16:24:40.844052+01
1240	121	188	\N	0	inactive	\N	2026-02-03 16:24:40.844052+01	2026-02-03 16:24:40.844053+01
1241	121	162	\N	0	inactive	\N	2026-02-03 16:24:40.844054+01	2026-02-03 16:24:40.844054+01
1242	121	189	\N	0	inactive	\N	2026-02-03 16:24:40.844055+01	2026-02-03 16:24:40.844055+01
1243	121	158	\N	0	inactive	\N	2026-02-03 16:24:40.844056+01	2026-02-03 16:24:40.844056+01
1244	121	190	\N	0	inactive	\N	2026-02-03 16:24:40.844057+01	2026-02-03 16:24:40.844058+01
1245	121	159	\N	0	inactive	\N	2026-02-03 16:24:40.844058+01	2026-02-03 16:24:40.844059+01
1246	122	156	\N	0	inactive	\N	2026-02-03 16:24:41.32461+01	2026-02-03 16:24:41.324612+01
1247	122	177	\N	0	inactive	\N	2026-02-03 16:24:41.324613+01	2026-02-03 16:24:41.324614+01
1248	122	178	\N	0	inactive	\N	2026-02-03 16:24:41.324614+01	2026-02-03 16:24:41.324615+01
1249	122	179	\N	0	inactive	\N	2026-02-03 16:24:41.324615+01	2026-02-03 16:24:41.324616+01
1250	122	180	\N	0	inactive	\N	2026-02-03 16:24:41.324617+01	2026-02-03 16:24:41.324617+01
1251	122	181	\N	0	inactive	\N	2026-02-03 16:24:41.324618+01	2026-02-03 16:24:41.324618+01
1252	122	182	\N	0	inactive	\N	2026-02-03 16:24:41.324619+01	2026-02-03 16:24:41.324619+01
1253	122	183	\N	0	inactive	\N	2026-02-03 16:24:41.32462+01	2026-02-03 16:24:41.32462+01
1254	122	184	\N	0	inactive	\N	2026-02-03 16:24:41.324621+01	2026-02-03 16:24:41.324621+01
1255	122	185	\N	0	inactive	\N	2026-02-03 16:24:41.324622+01	2026-02-03 16:24:41.324623+01
1256	122	186	\N	0	inactive	\N	2026-02-03 16:24:41.324623+01	2026-02-03 16:24:41.324624+01
1257	122	157	\N	0	inactive	\N	2026-02-03 16:24:41.324625+01	2026-02-03 16:24:41.324625+01
1258	122	160	\N	0	inactive	\N	2026-02-03 16:24:41.324626+01	2026-02-03 16:24:41.324626+01
1259	122	187	\N	0	inactive	\N	2026-02-03 16:24:41.324627+01	2026-02-03 16:24:41.324627+01
1260	122	161	\N	0	inactive	\N	2026-02-03 16:24:41.324628+01	2026-02-03 16:24:41.324628+01
1261	122	188	\N	0	inactive	\N	2026-02-03 16:24:41.324629+01	2026-02-03 16:24:41.32463+01
1262	122	162	\N	0	inactive	\N	2026-02-03 16:24:41.32463+01	2026-02-03 16:24:41.324631+01
1263	122	189	\N	0	inactive	\N	2026-02-03 16:24:41.324631+01	2026-02-03 16:24:41.324632+01
1264	122	158	\N	0	inactive	\N	2026-02-03 16:24:41.324632+01	2026-02-03 16:24:41.324633+01
1265	122	190	\N	0	inactive	\N	2026-02-03 16:24:41.324634+01	2026-02-03 16:24:41.324634+01
1266	122	159	\N	0	inactive	\N	2026-02-03 16:24:41.324635+01	2026-02-03 16:24:41.324635+01
1267	123	156	\N	0	inactive	\N	2026-02-03 16:24:41.714308+01	2026-02-03 16:24:41.714311+01
1268	123	177	\N	0	inactive	\N	2026-02-03 16:24:41.714312+01	2026-02-03 16:24:41.714313+01
1269	123	178	\N	0	inactive	\N	2026-02-03 16:24:41.714314+01	2026-02-03 16:24:41.714314+01
1270	123	179	\N	0	inactive	\N	2026-02-03 16:24:41.714315+01	2026-02-03 16:24:41.714315+01
1271	123	180	\N	0	inactive	\N	2026-02-03 16:24:41.714316+01	2026-02-03 16:24:41.714316+01
1272	123	181	\N	0	inactive	\N	2026-02-03 16:24:41.714317+01	2026-02-03 16:24:41.714317+01
1273	123	182	\N	0	inactive	\N	2026-02-03 16:24:41.714318+01	2026-02-03 16:24:41.714318+01
1274	123	183	\N	0	inactive	\N	2026-02-03 16:24:41.714319+01	2026-02-03 16:24:41.714319+01
1275	123	184	\N	0	inactive	\N	2026-02-03 16:24:41.71432+01	2026-02-03 16:24:41.714321+01
1276	123	185	\N	0	inactive	\N	2026-02-03 16:24:41.714321+01	2026-02-03 16:24:41.714322+01
1277	123	186	\N	0	inactive	\N	2026-02-03 16:24:41.714322+01	2026-02-03 16:24:41.714323+01
1278	123	157	\N	0	inactive	\N	2026-02-03 16:24:41.714323+01	2026-02-03 16:24:41.714324+01
1279	123	160	\N	0	inactive	\N	2026-02-03 16:24:41.714324+01	2026-02-03 16:24:41.714325+01
1280	123	187	\N	0	inactive	\N	2026-02-03 16:24:41.714325+01	2026-02-03 16:24:41.714326+01
1281	123	161	\N	0	inactive	\N	2026-02-03 16:24:41.714326+01	2026-02-03 16:24:41.714327+01
1282	123	188	\N	0	inactive	\N	2026-02-03 16:24:41.714327+01	2026-02-03 16:24:41.714328+01
1283	123	162	\N	0	inactive	\N	2026-02-03 16:24:41.714329+01	2026-02-03 16:24:41.714329+01
1284	123	189	\N	0	inactive	\N	2026-02-03 16:24:41.71433+01	2026-02-03 16:24:41.71433+01
1285	123	158	\N	0	inactive	\N	2026-02-03 16:24:41.714331+01	2026-02-03 16:24:41.714331+01
1286	123	190	\N	0	inactive	\N	2026-02-03 16:24:41.714332+01	2026-02-03 16:24:41.714332+01
1287	123	159	\N	0	inactive	\N	2026-02-03 16:24:41.714333+01	2026-02-03 16:24:41.714333+01
335	87	117	720	0	inactive	\N	2026-02-03 16:24:24.426805+01	2026-02-03 16:24:41.775772+01
336	87	141	720	0	inactive	\N	2026-02-03 16:24:24.426806+01	2026-02-03 16:24:41.775772+01
337	87	142	720	0	inactive	\N	2026-02-03 16:24:24.426807+01	2026-02-03 16:24:41.775772+01
338	87	143	720	0	inactive	\N	2026-02-03 16:24:24.426809+01	2026-02-03 16:24:41.775772+01
339	87	144	720	0	inactive	\N	2026-02-03 16:24:24.42681+01	2026-02-03 16:24:41.775772+01
340	87	145	720	0	inactive	\N	2026-02-03 16:24:24.426811+01	2026-02-03 16:24:41.775772+01
341	87	146	720	0	inactive	\N	2026-02-03 16:24:24.426813+01	2026-02-03 16:24:41.775772+01
342	87	153	720	0	inactive	\N	2026-02-03 16:24:24.426814+01	2026-02-03 16:24:41.775772+01
343	87	152	720	0	inactive	\N	2026-02-03 16:24:24.426815+01	2026-02-03 16:24:41.775772+01
344	87	154	720	0	inactive	\N	2026-02-03 16:24:24.426817+01	2026-02-03 16:24:41.775772+01
345	87	116	720	0	inactive	\N	2026-02-03 16:24:24.426818+01	2026-02-03 16:24:41.775772+01
346	87	118	720	0	inactive	\N	2026-02-03 16:24:24.426819+01	2026-02-03 16:24:41.775772+01
347	87	147	720	0	inactive	\N	2026-02-03 16:24:24.426821+01	2026-02-03 16:24:41.775772+01
348	87	148	720	0	inactive	\N	2026-02-03 16:24:24.426822+01	2026-02-03 16:24:41.775772+01
349	87	149	720	0	inactive	\N	2026-02-03 16:24:24.426823+01	2026-02-03 16:24:41.775772+01
350	87	150	720	0	inactive	\N	2026-02-03 16:24:24.426824+01	2026-02-03 16:24:41.775772+01
351	87	151	720	0	inactive	\N	2026-02-03 16:24:24.426826+01	2026-02-03 16:24:41.775772+01
\.


--
-- Data for Name: participant_hubspot_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.participant_hubspot_data (id, participant_id, id_action_formation, id_lap, c_url_transaction_hubspot, c_id_transaction_hubspot, created_at, updated_at) FROM stdin;
1	2	119	277	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/132063490294	132063490294	2026-02-03 16:23:56.750348+01	2026-02-03 16:24:14.053132+01
2	4	119	279	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/114179909825	114179909825	2026-02-03 16:23:57.21747+01	2026-02-03 16:24:14.531892+01
3	5	119	310	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/150887228619	150887228619	2026-02-03 16:23:57.40748+01	2026-02-03 16:24:14.758399+01
4	10	140	306	https://app-eu1.hubspot.com/contacts/25868618/record/0-1/202849878226	134625980648	2026-02-03 16:23:59.278817+01	2026-02-03 16:24:16.465705+01
5	11	140	307	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/134767423685	134767423685	2026-02-03 16:23:59.57888+01	2026-02-03 16:24:16.76722+01
6	12	140	308	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/156851173601	156851173601	2026-02-03 16:23:59.891631+01	2026-02-03 16:24:17.064569+01
7	14	140	523	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/175217170626	175217170626	2026-02-03 16:24:00.487754+01	2026-02-03 16:24:17.644701+01
8	15	140	607	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/196210183381	196210183381	2026-02-03 16:24:00.808135+01	2026-02-03 16:24:17.949245+01
9	16	140	730	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/214591854830	214591854830	2026-02-03 16:24:01.132474+01	2026-02-03 16:24:18.246008+01
10	19	175	351	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/167702913218	167702913218	2026-02-03 16:24:02.406929+01	2026-02-03 16:24:19.435035+01
11	20	175	355	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/166158206155	166158206155	2026-02-03 16:24:02.643151+01	2026-02-03 16:24:19.655151+01
12	21	175	511	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/166509727989	166509727989	2026-02-03 16:24:02.859044+01	2026-02-03 16:24:19.882+01
13	23	176	352	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/165751443649	165751443649	2026-02-03 16:24:03.506819+01	2026-02-03 16:24:20.56363+01
14	25	194	371	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/168067604691	168067604691	2026-02-03 16:24:04.34486+01	2026-02-03 16:24:21.31512+01
15	30	226	412	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/172456461545	172456461545	2026-02-03 16:24:06.424852+01	2026-02-03 16:24:23.141312+01
16	32	237	421	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/174349199589	174349199589	2026-02-03 16:24:07.135767+01	2026-02-03 16:24:23.95602+01
42	88	356	721	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/189721902321	189721902321	2026-02-03 16:24:24.902376+01	2026-02-03 16:24:24.902379+01
17	34	248	442	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/168155715800	168155715800	2026-02-03 16:24:07.930499+01	2026-02-03 16:24:24.846333+01
43	89	356	722	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/189722002623	189722002623	2026-02-03 16:24:25.381113+01	2026-02-03 16:24:25.381116+01
18	35	248	520	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/186069755086	186069755086	2026-02-03 16:24:08.205435+01	2026-02-03 16:24:25.218345+01
19	36	248	592	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/195460292833	195460292833	2026-02-03 16:24:08.481881+01	2026-02-03 16:24:25.535538+01
44	90	356	723	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/199356194041	199356194041	2026-02-03 16:24:25.879472+01	2026-02-03 16:24:25.879474+01
20	37	248	632	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/205629553871	205629553871	2026-02-03 16:24:08.711386+01	2026-02-03 16:24:25.853758+01
45	91	356	724	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/205543305438	205543305438	2026-02-03 16:24:26.359028+01	2026-02-03 16:24:26.359031+01
21	38	248	986	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/218356266232	218356266232	2026-02-03 16:24:08.961132+01	2026-02-03 16:24:26.152688+01
22	39	248	1178	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/234824532182	234824532182	2026-02-03 16:24:09.187788+01	2026-02-03 16:24:26.468276+01
46	92	356	725	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/201985188077	201985188077	2026-02-03 16:24:26.82295+01	2026-02-03 16:24:26.822953+01
47	93	356	726	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/205287818443	205287818443	2026-02-03 16:24:27.285668+01	2026-02-03 16:24:27.285671+01
48	94	356	727	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/206842697946	206842697946	2026-02-03 16:24:27.733017+01	2026-02-03 16:24:27.733019+01
49	95	356	728	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/207908549868	207908549868	2026-02-03 16:24:28.118275+01	2026-02-03 16:24:28.118277+01
23	43	256	581	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/193920438512	193920438512	2026-02-03 16:24:10.400461+01	2026-02-03 16:24:27.89812+01
24	44	256	582	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/192991113460	192991113460	2026-02-03 16:24:10.619185+01	2026-02-03 16:24:28.168911+01
50	96	356	733	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/214591818968	214591818968	2026-02-03 16:24:28.615383+01	2026-02-03 16:24:28.615385+01
51	97	356	1028	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/46331318517	46331318517	2026-02-03 16:24:29.530893+01	2026-02-03 16:24:29.530897+01
52	98	356	1060	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/208189657306	208189657306	2026-02-03 16:24:30.022473+01	2026-02-03 16:24:30.022476+01
25	63	288	553	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/189721952499	189721952499	2026-02-03 16:24:15.621186+01	2026-02-03 16:24:33.249367+01
26	64	303	571	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/189722158324	189722158324	2026-02-03 16:24:16.099586+01	2026-02-03 16:24:33.672361+01
27	66	306	575	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/193840696517	193840696517	2026-02-03 16:24:16.791708+01	2026-02-03 16:24:34.40916+01
28	67	306	637	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/208026076375	208026076375	2026-02-03 16:24:17.107839+01	2026-02-03 16:24:34.867008+01
29	68	307	576	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/193188063442	193188063442	2026-02-03 16:24:17.527569+01	2026-02-03 16:24:35.263783+01
30	69	313	586	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/184971953381	184971953381	2026-02-03 16:24:17.971138+01	2026-02-03 16:24:35.629924+01
31	70	313	587	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/178344166629	178344166629	2026-02-03 16:24:18.20922+01	2026-02-03 16:24:35.833122+01
32	71	313	997	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/219200315584	219200315584	2026-02-03 16:24:18.451985+01	2026-02-03 16:24:36.081689+01
33	72	313	1038	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/222899558609	222899558609	2026-02-03 16:24:18.680552+01	2026-02-03 16:24:36.256049+01
34	73	313	1142	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/231242604777	231242604777	2026-02-03 16:24:18.914333+01	2026-02-03 16:24:36.523343+01
35	74	313	1163	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/146255273159	146255273159	2026-02-03 16:24:19.131643+01	2026-02-03 16:24:36.715923+01
36	76	313	1182	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/186057056442	186057056442	2026-02-03 16:24:19.58891+01	2026-02-03 16:24:37.119694+01
37	83	356	634	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/205287723211	205287723211	2026-02-03 16:24:22.482559+01	2026-02-03 16:24:39.953101+01
38	84	356	638	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/126689752302	126689752302	2026-02-03 16:24:22.990853+01	2026-02-03 16:24:40.482223+01
39	85	356	639	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/186069796035	186069796035	2026-02-03 16:24:23.477316+01	2026-02-03 16:24:40.876491+01
40	86	356	719	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/148019023040	148019023040	2026-02-03 16:24:23.969467+01	2026-02-03 16:24:41.338863+01
41	87	356	720	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/173783611616	173783611616	2026-02-03 16:24:24.428886+01	2026-02-03 16:24:41.775772+01
53	99	356	1061	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/222899918031	222899918031	2026-02-03 16:24:30.562918+01	2026-02-03 16:24:30.562921+01
54	100	356	1062	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/229063135435	229063135435	2026-02-03 16:24:31.044701+01	2026-02-03 16:24:31.044704+01
55	101	356	1063	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/228090662130	228090662130	2026-02-03 16:24:31.518013+01	2026-02-03 16:24:31.518017+01
56	102	356	1064	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/222987082954	222987082954	2026-02-03 16:24:31.957333+01	2026-02-03 16:24:31.957335+01
57	103	356	1065	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/208962671814	208962671814	2026-02-03 16:24:32.401042+01	2026-02-03 16:24:32.401044+01
58	104	356	1066	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/156852540634	156852540634	2026-02-03 16:24:32.846009+01	2026-02-03 16:24:32.846012+01
59	106	356	1104	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/224286000346	224286000346	2026-02-03 16:24:33.754109+01	2026-02-03 16:24:33.754111+01
60	107	356	1128	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/180252123335	180252123335	2026-02-03 16:24:34.253162+01	2026-02-03 16:24:34.253165+01
61	108	356	1131	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/218356279514	218356279514	2026-02-03 16:24:34.692889+01	2026-02-03 16:24:34.692893+01
62	110	356	1183	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/179440328925	179440328925	2026-02-03 16:24:35.650796+01	2026-02-03 16:24:35.650798+01
63	118	363	648	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/60605112537	60605112537	2026-02-03 16:24:39.563607+01	2026-02-03 16:24:39.563609+01
64	119	363	649	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/25917113530	25917113530	2026-02-03 16:24:39.970552+01	2026-02-03 16:24:39.970555+01
65	120	363	650	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/141396195549	141396195549	2026-02-03 16:24:40.442455+01	2026-02-03 16:24:40.442461+01
66	121	363	651	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/39877121255	39877121255	2026-02-03 16:24:40.845624+01	2026-02-03 16:24:40.845626+01
67	123	363	653	https://app-eu1.hubspot.com/contacts/25868618/record/0-3/141455075569	141455075569	2026-02-03 16:24:41.715856+01	2026-02-03 16:24:41.715859+01
\.


--
-- Data for Name: participants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.participants (id, id_participant, nom, prenom, email, id_entreprise, created_at, updated_at) FROM stdin;
1	25	MOUYAL	Guy	guy.mouyal@fcs-consulting.com	1977	2026-02-03 16:23:56.141067+01	2026-02-03 16:23:56.137306+01
2	24	CHATEL	Didier	dch.chatel@free.fr	22	2026-02-03 16:23:56.555776+01	2026-02-03 16:23:56.55578+01
3	20	GIBERT	Eric	eric-gibert@orange.fr	18	2026-02-03 16:23:56.753505+01	2026-02-03 16:23:56.753511+01
4	21	PASSIANTE	Jordan	jordanpassiante@gmail.com	19	2026-02-03 16:23:56.954096+01	2026-02-03 16:23:56.954105+01
5	42	BANNOUR	Habiba	habiba.bannour@edu.escp.eu	42	2026-02-03 16:23:57.220914+01	2026-02-03 16:23:57.220923+01
6	383	RIGOULET	Maeva	mae.rigoulet12@gmail.com	383	2026-02-03 16:23:57.41102+01	2026-02-03 16:23:57.411028+01
7	27	APPRENANT	TEST	test@competences-et-metiers.com	25	2026-02-03 16:23:57.800252+01	2026-02-03 16:23:57.800261+01
8	36	DEFILS	Valérie	valeriedefils@gmail.com	36	2026-02-03 16:23:58.201488+01	2026-02-03 16:23:58.201498+01
9	37	MARSAUX	Etienne	etienne.marsaux@gmail.com	37	2026-02-03 16:23:58.688835+01	2026-02-03 16:23:58.688845+01
10	38	BRETTE	Marie	marie.brettecoudurier@gmail.com	38	2026-02-03 16:23:58.972663+01	2026-02-03 16:23:58.972672+01
11	39	VASSELIN	Michel	vasselin.michel@aliceadsl.fr	39	2026-02-03 16:23:59.282264+01	2026-02-03 16:23:59.282272+01
12	40	MOUNIAMA	Julien	julien.mouniama@hotmail.fr	40	2026-02-03 16:23:59.582285+01	2026-02-03 16:23:59.582293+01
13	41	DENTONE	Roselyne	roselynedentone@outlook.fr	41	2026-02-03 16:23:59.894113+01	2026-02-03 16:23:59.894118+01
14	199	FARHI	Mohamed	farhi.mohamed.mf@gmail.com	199	2026-02-03 16:24:00.183045+01	2026-02-03 16:24:00.183054+01
15	366	BOGLIOLO	Gilles	gilles.bogliolo@gmail.com	366	2026-02-03 16:24:00.491021+01	2026-02-03 16:24:00.491029+01
16	440	PRIOUL	Sebastien	prioulsebastien@hotmail.com	440	2026-02-03 16:24:00.811437+01	2026-02-03 16:24:00.811445+01
17	56	LIABOT	Frederique	fred.liabot@gmail.com	56	2026-02-03 16:24:01.316271+01	2026-02-03 16:24:01.316281+01
18	69	CAVILLON	Charlotte	charlotte.cavillon@gmail.com	69	2026-02-03 16:24:01.738085+01	2026-02-03 16:24:01.738094+01
19	86	LEITNER	Joss	jossleitner1@gmail.com	86	2026-02-03 16:24:02.135676+01	2026-02-03 16:24:02.135685+01
20	93	MYGARDON (FRICOT)	Virginie	virginie.mygardon@gmail.com	93	2026-02-03 16:24:02.410285+01	2026-02-03 16:24:02.410293+01
21	288	JACQUEMIN	Melanie	mel.jacquemin@laposte.net	288	2026-02-03 16:24:02.646685+01	2026-02-03 16:24:02.646693+01
22	355	ROIRON	Dominique	dominique.roiron@arkema.com	355	2026-02-03 16:24:02.862471+01	2026-02-03 16:24:02.86248+01
23	82	KNESS	Tiffany	tiffanyrose.kness@gmail.com	82	2026-02-03 16:24:03.277092+01	2026-02-03 16:24:03.277102+01
24	84	BRIMUSSE	Fabien	quarter.fabien@gmail.com	84	2026-02-03 16:24:03.755816+01	2026-02-03 16:24:03.755825+01
25	81	DEVISSCHERE	Angélique	angelikdk@hotmail.fr	81	2026-02-03 16:24:04.136451+01	2026-02-03 16:24:04.13646+01
26	145	LE MENN	Eulalie	eulalielaviemesourit@gmail.com	145	2026-02-03 16:24:04.576592+01	2026-02-03 16:24:04.576601+01
27	139	PERVAL	Fabrice	pervalfabrice@hotmail.fr	139	2026-02-03 16:24:05.028005+01	2026-02-03 16:24:05.028014+01
28	150	THIMPONT	Siegfried	siegfried1.0@hotmail.fr	150	2026-02-03 16:24:05.404001+01	2026-02-03 16:24:05.40401+01
29	141	DOGLIANI	Baptiste	doglianib@yahoo.fr	141	2026-02-03 16:24:05.793633+01	2026-02-03 16:24:05.793642+01
30	152	MOGNOLLE	Catherine	mognolle.catherine@neuf.fr	152	2026-02-03 16:24:06.248303+01	2026-02-03 16:24:06.248308+01
31	177	LEGASTELOIS	Marine	mlegastelois@live.fr	177	2026-02-03 16:24:06.617283+01	2026-02-03 16:24:06.617288+01
32	174	TISOPULOT	Cyril	tisopulot@yahoo.fr	174	2026-02-03 16:24:06.949465+01	2026-02-03 16:24:06.949468+01
33	173	MARCILLAT BEGERT	Mathilde	mathilde.marcillat@gmail.com	173	2026-02-03 16:24:07.304595+01	2026-02-03 16:24:07.304599+01
34	99	DUFOUR	Clara	claradufour53@hotmail.fr	99	2026-02-03 16:24:07.670024+01	2026-02-03 16:24:07.670028+01
35	297	JAUNET	Anita	juanimida10@gmail.com	297	2026-02-03 16:24:07.931701+01	2026-02-03 16:24:07.931704+01
36	365	ROYER	Angelina	angelina.royer@outlook.com	365	2026-02-03 16:24:08.206761+01	2026-02-03 16:24:08.206763+01
37	405	PIERSON	Leonie	leoniepierson55200@gmail.com	405	2026-02-03 16:24:08.483562+01	2026-02-03 16:24:08.483566+01
38	471	RIOU	Frédérick	frederickriou@gmail.com	471	2026-02-03 16:24:08.712493+01	2026-02-03 16:24:08.712496+01
39	637	GALLET	Nicolas	nicolasgallet85@gmail.com	637	2026-02-03 16:24:08.962319+01	2026-02-03 16:24:08.962322+01
40	724	MOUGIN	Marylène	maryl-88@hotmail.fr	724	2026-02-03 16:24:09.188939+01	2026-02-03 16:24:09.188942+01
41	788	DEVILLERS	Nicole	bleno.nicole@gmail.com	788	2026-02-03 16:24:09.438293+01	2026-02-03 16:24:09.438296+01
42	513	FINCO	Marc	marcfinco@yahoo.fr	513	2026-02-03 16:24:09.706315+01	2026-02-03 16:24:09.706318+01
43	349	AHO	Gabriel	gabrielaho@hotmail.fr	349	2026-02-03 16:24:10.083951+01	2026-02-03 16:24:10.083954+01
44	357	STEVENIN	Jean-Baptiste	jb.stevenin@gmail.com	357	2026-02-03 16:24:10.40301+01	2026-02-03 16:24:10.403016+01
45	465	VUILSTEKE	Loïc	je.lecuyer@laposte.net	465	2026-02-03 16:24:10.620235+01	2026-02-03 16:24:10.620237+01
46	178	SEMROUD	Sami	sami.semroud@competences-et-metiers.com	178	2026-02-03 16:24:10.893291+01	2026-02-03 16:24:10.893296+01
47	90	LAURENT	Marc	marctrunks84@gmail.com	90	2026-02-03 16:24:11.337331+01	2026-02-03 16:24:11.337341+01
48	224	GALEMPOIX	Karl	kgalempoix@outlook.fr	224	2026-02-03 16:24:11.706763+01	2026-02-03 16:24:11.706773+01
49	225	GAPIK	Sebastien	gapik.sebastien@yahoo.fr	225	2026-02-03 16:24:11.945384+01	2026-02-03 16:24:11.945394+01
50	227	LASPINA	Fabrice	entrepreneur.laspina@gmail.com	227	2026-02-03 16:24:12.172415+01	2026-02-03 16:24:12.172426+01
51	230	ORAND	Julien	julienorand29@yahoo.fr	230	2026-02-03 16:24:12.403098+01	2026-02-03 16:24:12.403102+01
52	234	THOMAS	Nicolas	thomanicola104@gmail.com	234	2026-02-03 16:24:12.570772+01	2026-02-03 16:24:12.570775+01
53	242	CONSTANTIN	PASCALE	pascaleconstantin584@gmail.com	242	2026-02-03 16:24:12.749871+01	2026-02-03 16:24:12.749874+01
54	185	HANINI	Reda	redaiyade24@gmail.com	185	2026-02-03 16:24:12.947115+01	2026-02-03 16:24:12.947119+01
55	247	MANSEUR	Nour	imeneberk@gmail.com	247	2026-02-03 16:24:13.141401+01	2026-02-03 16:24:13.141404+01
56	249	MILAN	Denis	denismilanperso@gmail.com	249	2026-02-03 16:24:13.346323+01	2026-02-03 16:24:13.346327+01
57	250	PASSENHEIM	Virgile	passenheim.virgile@orange.fr	250	2026-02-03 16:24:13.571032+01	2026-02-03 16:24:13.571043+01
58	184	MALONGA	Yendi	kenmalonga@gmail.com	184	2026-02-03 16:24:13.784681+01	2026-02-03 16:24:13.784691+01
59	283	FLORES	Benjamin	benjamin722b@gmail.com	283	2026-02-03 16:24:13.985899+01	2026-02-03 16:24:13.985909+01
60	284	ONUTA	Vitalie	vonuta1@gmail.com	284	2026-02-03 16:24:14.193539+01	2026-02-03 16:24:14.193549+01
61	286	KARYM	Yosra	imran020316@hotmail.com	286	2026-02-03 16:24:14.613689+01	2026-02-03 16:24:14.613695+01
62	293	RIVET	Arnaud	arnaudrivet625@gmail.com	293	2026-02-03 16:24:15.000269+01	2026-02-03 16:24:15.000274+01
63	324	JUIN	Isabelle	isabelle.juin.62@gmail.com	324	2026-02-03 16:24:15.394693+01	2026-02-03 16:24:15.394697+01
64	331	DACCORD	Emmanuel	cerq.daccord@orange.fr	331	2026-02-03 16:24:15.816352+01	2026-02-03 16:24:15.816361+01
65	840	LAURENT	Stéphane	contact@agorabat.fr	840	2026-02-03 16:24:16.103456+01	2026-02-03 16:24:16.103465+01
66	347	MAURICE	Johanna	johanna.maurice@gmail.com	347	2026-02-03 16:24:16.491107+01	2026-02-03 16:24:16.491115+01
67	413	MONNIER	Myriam	mimyani25@gmail.com	413	2026-02-03 16:24:16.793065+01	2026-02-03 16:24:16.793067+01
68	341	JEZEQUEL	Seranne	serannejezequel@yahoo.fr	341	2026-02-03 16:24:17.285458+01	2026-02-03 16:24:17.285467+01
69	287	MAZUC	Ludovic	ludovic.mazuc@gmail.com	287	2026-02-03 16:24:17.744201+01	2026-02-03 16:24:17.744206+01
70	211	JOURDAN	Olivier	jourdan.olivier26@gmail.com	211	2026-02-03 16:24:17.973229+01	2026-02-03 16:24:17.973234+01
71	487	CHAUVELLY	Wilfrid	wilfrid.26chauvelly@gmail.com	487	2026-02-03 16:24:18.213029+01	2026-02-03 16:24:18.213038+01
72	510	MUSQUET	Moise	moise.musquet@gmail.com	510	2026-02-03 16:24:18.456011+01	2026-02-03 16:24:18.45602+01
73	603	BOURDON	Nicolas	nicolasbourdon17@gmail.com	603	2026-02-03 16:24:18.68221+01	2026-02-03 16:24:18.682214+01
74	646	GIRARD	Yohann	delphineetyohann@free.fr	646	2026-02-03 16:24:18.918206+01	2026-02-03 16:24:18.918215+01
75	647	LEVIGNERON	Michel	panthererose85@gmail.com	647	2026-02-03 16:24:19.135385+01	2026-02-03 16:24:19.135393+01
76	296	MOIZAND	Aurelien	aurelmanue@outlook.com	296	2026-02-03 16:24:19.345526+01	2026-02-03 16:24:19.345536+01
77	708	SORRENTINO	Franck	palani13.fs@gmail.com	708	2026-02-03 16:24:19.592313+01	2026-02-03 16:24:19.592322+01
78	893	COUREAU	Alain	acoureau@efficity.com	893	2026-02-03 16:24:19.796226+01	2026-02-03 16:24:19.796235+01
79	374	De BREBISSON	Gabriel	gabdebreb@gmail.com	374	2026-02-03 16:24:20.188312+01	2026-02-03 16:24:20.188316+01
80	379	ESPUNA	Manon	manonespuna@gmail.com	379	2026-02-03 16:24:20.525975+01	2026-02-03 16:24:20.525985+01
81	380	SEVRAIN	Jerome	sevrainjerome@hotmail.fr	380	2026-02-03 16:24:20.915257+01	2026-02-03 16:24:20.91526+01
82	111	MELIS	Steven	steven_melis@hotmail.fr	111	2026-02-03 16:24:21.265176+01	2026-02-03 16:24:21.265186+01
83	397	DECOSTER	Martin	martin_decoster@hotmail.com	397	2026-02-03 16:24:21.97357+01	2026-02-03 16:24:21.973576+01
84	175	PEREIRA	Anthony	flexfuel63@gmail.com	175	2026-02-03 16:24:22.484087+01	2026-02-03 16:24:22.48409+01
85	298	BUSCEMA	Franck	franck.buscema@gmail.com	298	2026-02-03 16:24:22.992233+01	2026-02-03 16:24:22.992236+01
86	260	BREDEL	Olivier	obex.consulting@gmail.com	260	2026-02-03 16:24:23.478709+01	2026-02-03 16:24:23.478712+01
87	166	DA SILVA	Georges	georgesdasilva78990@gmail.com	166	2026-02-03 16:24:23.970982+01	2026-02-03 16:24:23.970985+01
88	320	POLGE	Xavier	xavier.polge@laposte.net	320	2026-02-03 16:24:24.4303+01	2026-02-03 16:24:24.430303+01
89	328	LAMY	Christophe	lamy.christophe82@gmail.com	328	2026-02-03 16:24:24.903484+01	2026-02-03 16:24:24.903486+01
90	377	BELLIER	Renan	renan.bellier@sfr.fr	377	2026-02-03 16:24:25.382317+01	2026-02-03 16:24:25.382319+01
91	399	PORTALES	Stéphanie	stephanieportales1975@gmail.com	399	2026-02-03 16:24:25.880694+01	2026-02-03 16:24:25.880697+01
92	386	ZAHIM	Asmae	biboula05@gmail.com	386	2026-02-03 16:24:26.360435+01	2026-02-03 16:24:26.360438+01
93	401	GHIGHI	Stéphane	stephaneghighi92@gmail.com	401	2026-02-03 16:24:26.824108+01	2026-02-03 16:24:26.82411+01
94	408	PITON	Lézin Richard	pitonrichard1@gmail.com	408	2026-02-03 16:24:27.286829+01	2026-02-03 16:24:27.286831+01
95	410	BOBARD	Franck	franck.bobard@me.com	410	2026-02-03 16:24:27.734069+01	2026-02-03 16:24:27.734071+01
96	439	LEBASTARD	Maxime	maximelebastard1@gmail.com	439	2026-02-03 16:24:28.11955+01	2026-02-03 16:24:28.119552+01
97	433	ROY	Yoan	yoanroy89@hotmail.fr	433	2026-02-03 16:24:29.013904+01	2026-02-03 16:24:29.013908+01
98	415	ALBARET	Geoffroy	albaretgeoffroy@gmail.com	415	2026-02-03 16:24:29.532372+01	2026-02-03 16:24:29.532375+01
99	514	BASSAYEVA	Choragat	choracat.bassayeva@gmail.com	514	2026-02-03 16:24:30.023698+01	2026-02-03 16:24:30.0237+01
100	534	BOUHASSOUN	Tijani	tijani.bouhassoun@gmail.com	534	2026-02-03 16:24:30.564636+01	2026-02-03 16:24:30.564639+01
101	525	CHEREL	Philippe	philippe.cherel08@free.fr	525	2026-02-03 16:24:31.046114+01	2026-02-03 16:24:31.046116+01
102	511	DARMONIAN	Rouzanna	r_ddesign@outlook.com	511	2026-02-03 16:24:31.519463+01	2026-02-03 16:24:31.519465+01
103	425	GASPARD	Angel	angel.gaspard58@gmail.com	425	2026-02-03 16:24:31.95851+01	2026-02-03 16:24:31.958512+01
104	344	GUISSE	Demba	dembaguisse4@gmail.com	344	2026-02-03 16:24:32.402241+01	2026-02-03 16:24:32.402243+01
105	545	BENRAHMOUNE	Omar	aronomar@hotmail.fr	545	2026-02-03 16:24:32.847516+01	2026-02-03 16:24:32.847519+01
106	521	HERRERA	Romain	romainherrera@gmail.com	521	2026-02-03 16:24:33.298446+01	2026-02-03 16:24:33.298449+01
107	601	GASTINES	Jean-Marc	jeanmarcgastines@gmail.com	601	2026-02-03 16:24:33.755254+01	2026-02-03 16:24:33.755256+01
108	473	VAZQUEZ	Philippe	puntocolor33@gmail.com	473	2026-02-03 16:24:34.25473+01	2026-02-03 16:24:34.254732+01
109	272	TAGLIATI	Noémie	noemietagliati3@gmail.com	272	2026-02-03 16:24:34.694336+01	2026-02-03 16:24:34.694339+01
110	213	STANKOVIC	Milé	mile93440@msn.com	213	2026-02-03 16:24:35.210908+01	2026-02-03 16:24:35.210912+01
111	259	BOUROUMIA	Karim	karim.bouroumia@gmail.com	259	2026-02-03 16:24:35.651883+01	2026-02-03 16:24:35.651885+01
112	264	DIOP	Mouhamadou Al Bachir	bachirdiop49@gmail.com	264	2026-02-03 16:24:36.122455+01	2026-02-03 16:24:36.122458+01
113	151	BEILLAN	Aurelie	aurelie.beillan@hotmail.fr	151	2026-02-03 16:24:36.54744+01	2026-02-03 16:24:36.547443+01
114	527	OUHEIRERRE	Roger	ouheirerre@yahoo.fr	527	2026-02-03 16:24:37.009301+01	2026-02-03 16:24:37.009305+01
115	1079	PINHEIRO	Magda	m.pinheiro@competences-et-metiers.com	1079	2026-02-03 16:24:37.426771+01	2026-02-03 16:24:37.426774+01
116	262	COSTE	Jean Philippe	eilgds13@gmail.com	262	2026-02-03 16:24:37.977218+01	2026-02-03 16:24:37.977222+01
117	411	LE BRETON	Magali	magali.lebreton@yopmail.com	411	2026-02-03 16:24:38.575088+01	2026-02-03 16:24:38.575092+01
118	424	BELKADI	Megdouda	belkadisamia2017@gmail.com	424	2026-02-03 16:24:39.035769+01	2026-02-03 16:24:39.03578+01
119	427	BOUGHRAB	Mourad	soufian-82@hotmail.fr	427	2026-02-03 16:24:39.564747+01	2026-02-03 16:24:39.56475+01
120	428	BROUARD	Alizée	alizee.brouard@gmail.com	428	2026-02-03 16:24:39.972073+01	2026-02-03 16:24:39.972077+01
121	429	CLOATRE	Régis	cloatreregis@gmail.com	429	2026-02-03 16:24:40.444736+01	2026-02-03 16:24:40.444741+01
122	430	COSSY	Sebastien	sebcossy@hotmail.fr	430	2026-02-03 16:24:40.846983+01	2026-02-03 16:24:40.846986+01
123	431	LAURENT	Cédric	cedric.laurent24@yahoo.com	431	2026-02-03 16:24:41.323998+01	2026-02-03 16:24:41.324001+01
124	432	ROUHANI	Alexandre	alexandrerouhani@hotmail.com	432	2026-02-03 16:24:41.717044+01	2026-02-03 16:24:41.717046+01
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
222	sync_all	2026-02-03 16:00:23.918337+01	error	\N	Force cleaned up sync record	2026-02-03 16:00:23.919576+01	2026-02-03 16:17:54.622413+01
224	table_setup_test	2026-02-03 15:18:08.750238+01	success	{"message": "Table setup verification"}	\N	2026-02-03 16:18:08.751288+01	2026-02-03 16:18:08.751291+01
225	table_setup_test	2026-02-03 15:18:10.095345+01	success	{"message": "Table setup verification"}	\N	2026-02-03 16:18:10.096291+01	2026-02-03 16:18:10.096294+01
223	sync_all	2026-02-03 16:17:54.633113+01	error	\N	Force cleaned up sync record	2026-02-03 16:17:54.634296+01	2026-02-03 16:18:11.483238+01
226	sync_all	2026-02-03 16:18:11.498711+01	error	\N	Force cleaned up sync record	2026-02-03 16:18:11.501186+01	2026-02-03 16:23:52.954717+01
228	table_setup_test	2026-02-03 15:24:07.257049+01	success	{"message": "Table setup verification"}	\N	2026-02-03 16:24:07.258129+01	2026-02-03 16:24:07.258132+01
229	table_setup_test	2026-02-03 15:24:08.604871+01	success	{"message": "Table setup verification"}	\N	2026-02-03 16:24:08.605786+01	2026-02-03 16:24:08.605789+01
227	sync_all	2026-02-03 16:23:52.971501+01	error	\N	Force cleaned up sync record	2026-02-03 16:23:52.972631+01	2026-02-03 16:24:10.040528+01
230	sync_all	2026-02-03 16:24:10.047437+01	in_progress	\N	\N	2026-02-03 16:24:10.04855+01	2026-02-03 16:24:10.048552+01
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

SELECT pg_catalog.setval('public.modules_id_seq', 1308, true);


--
-- Name: participant_courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.participant_courses_id_seq', 1308, true);


--
-- Name: participant_hubspot_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.participant_hubspot_data_id_seq', 68, true);


--
-- Name: participants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.participants_id_seq', 125, true);


--
-- Name: sync_metadata_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sync_metadata_id_seq', 230, true);


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

\unrestrict 3K0WtdklrFdozh4dpO2D1b4WqoLLVjxS7drS2TPIYROnXzr8rs6WVcJ19zbvSgx

