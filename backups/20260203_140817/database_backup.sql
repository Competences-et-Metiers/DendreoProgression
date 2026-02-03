--
-- PostgreSQL database dump
--

\restrict Sl5hnKcoBLD0gTepAtK1qqtHIMXqcqcADet5PVZ8athUVYLbLWokwi1UlqzVkPi

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
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.courses OWNER TO postgres;

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
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.modules OWNER TO postgres;

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
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.courses (id, id_action_formation, id_lam, intitule, status, total_modules, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: modules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modules (id, id_lmp, id_lam, intitule, course_id, participant_id, lms_progression, lms_last_access_at, mode_organisation, created_at, updated_at) FROM stdin;
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
46	sync_all	2026-02-03 12:37:47.253636+01	in_progress	\N	\N	2026-02-03 12:37:47.25479+01	2026-02-03 12:37:47.254792+01
\.


--
-- Name: courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.courses_id_seq', 1, false);


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

SELECT pg_catalog.setval('public.sync_metadata_id_seq', 46, true);


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

\unrestrict Sl5hnKcoBLD0gTepAtK1qqtHIMXqcqcADet5PVZ8athUVYLbLWokwi1UlqzVkPi

