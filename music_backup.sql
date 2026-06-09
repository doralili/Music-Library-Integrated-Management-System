--
-- openGauss database dump
--

SET statement_timeout = 0;
SET xmloption = content;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET session_replication_role = replica;
SET client_min_messages = warning;

DROP DATABASE IF EXISTS music;
--
-- Name: music; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE music WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'C' LC_CTYPE = 'C' DBCOMPATIBILITY = 'PG';


\connect music

SET statement_timeout = 0;
SET xmloption = content;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET session_replication_role = replica;
SET client_min_messages = warning;

SET search_path = public;

--
-- Name: sync_song_comment_count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION sync_song_comment_count() RETURNS trigger
    LANGUAGE plpgsql NOT SHIPPABLE
 AS $$
        BEGIN
            IF TG_OP = 'INSERT' THEN
                UPDATE Songs
                SET comment_count = COALESCE(comment_count, 0) + 1
                WHERE song_id = NEW.song_id;
                RETURN NEW;
            ELSIF TG_OP = 'DELETE' THEN
                UPDATE Songs
                SET comment_count = GREATEST(COALESCE(comment_count, 0) - 1, 0)
                WHERE song_id = OLD.song_id;
                RETURN OLD;
            ELSIF TG_OP = 'UPDATE' AND NEW.song_id <> OLD.song_id THEN
                UPDATE Songs
                SET comment_count = GREATEST(COALESCE(comment_count, 0) - 1, 0)
                WHERE song_id = OLD.song_id;
                UPDATE Songs
                SET comment_count = COALESCE(comment_count, 0) + 1
                WHERE song_id = NEW.song_id;
                RETURN NEW;
            END IF;
            RETURN NEW;
        END;
        $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: albums; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE albums (
    album_id integer NOT NULL,
    title character varying(100) NOT NULL,
    artist_id integer,
    release_year integer,
    cover_url character varying(500)
)
WITH (orientation=row, compression=no);


--
-- Name: albums_album_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE  SEQUENCE albums_album_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: albums_album_id_seq; Type: LARGE SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER  SEQUENCE albums_album_id_seq OWNED BY albums.album_id;


--
-- Name: artists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE artists (
    artist_id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text
)
WITH (orientation=row, compression=no);


--
-- Name: artists_artist_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE  SEQUENCE artists_artist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: artists_artist_id_seq; Type: LARGE SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER  SEQUENCE artists_artist_id_seq OWNED BY artists.artist_id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments (
    comment_id integer NOT NULL,
    song_id integer,
    user_id integer,
    content text NOT NULL,
    created_at timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no);


--
-- Name: comments_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE  SEQUENCE comments_comment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_comment_id_seq; Type: LARGE SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER  SEQUENCE comments_comment_id_seq OWNED BY comments.comment_id;


--
-- Name: playlist_songs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE playlist_songs (
    playlist_id integer NOT NULL,
    song_id integer NOT NULL,
    added_at timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no);


--
-- Name: playlists; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE playlists (
    playlist_id integer NOT NULL,
    name character varying(100) NOT NULL,
    creator_id integer,
    created_at timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no);


--
-- Name: playlists_playlist_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE  SEQUENCE playlists_playlist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: playlists_playlist_id_seq; Type: LARGE SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER  SEQUENCE playlists_playlist_id_seq OWNED BY playlists.playlist_id;


--
-- Name: post_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE post_comments (
    pcomment_id integer NOT NULL,
    post_id integer,
    user_id integer,
    content text NOT NULL,
    created_at timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no);


--
-- Name: post_comments_pcomment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE  SEQUENCE post_comments_pcomment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_comments_pcomment_id_seq; Type: LARGE SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER  SEQUENCE post_comments_pcomment_id_seq OWNED BY post_comments.pcomment_id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posts (
    post_id integer NOT NULL,
    user_id integer,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    recommended_song_id integer,
    created_at timestamp without time zone DEFAULT pg_systimestamp()
)
WITH (orientation=row, compression=no);


--
-- Name: posts_post_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE  SEQUENCE posts_post_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_post_id_seq; Type: LARGE SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER  SEQUENCE posts_post_id_seq OWNED BY posts.post_id;


--
-- Name: songs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE songs (
    song_id integer NOT NULL,
    title character varying(150) NOT NULL,
    artist_id integer,
    album_id integer,
    duration_seconds integer,
    audio_url character varying(500),
    genre character varying(100) DEFAULT '未知'::character varying,
    comment_count integer DEFAULT 0,
    CONSTRAINT songs_duration_seconds_check CHECK ((duration_seconds > 0))
)
WITH (orientation=row, compression=no);


--
-- Name: songs_song_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE  SEQUENCE songs_song_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: songs_song_id_seq; Type: LARGE SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER  SEQUENCE songs_song_id_seq OWNED BY songs.song_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    user_id integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(20) NOT NULL,
    bio text,
    avatar_url character varying(255),
    created_at timestamp without time zone DEFAULT pg_systimestamp(),
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['sys_admin'::character varying, 'music_admin'::character varying, 'listener'::character varying])::text[])))
)
WITH (orientation=row, compression=no);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE  SEQUENCE users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_user_id_seq; Type: LARGE SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER  SEQUENCE users_user_id_seq OWNED BY users.user_id;


--
-- Name: v_user_posts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW v_user_posts(post_id,post_title,post_content,post_date,user_id,author_name,author_avatar,song_id,recommended_song_name,artist_name,album_name,recommended_cover_url,duration_seconds,recommended_audio_url) AS
    SELECT p.post_id, p.title AS post_title, p.content AS post_content, p.created_at AS post_date, u.user_id, u.username AS author_name, u.avatar_url AS author_avatar, s.song_id, s.title AS recommended_song_name, art.name AS artist_name, alb.title AS album_name, alb.cover_url AS recommended_cover_url, s.duration_seconds, s.audio_url AS recommended_audio_url FROM ((((posts p JOIN users u ON ((p.user_id = u.user_id))) LEFT JOIN songs s ON ((p.recommended_song_id = s.song_id))) LEFT JOIN artists art ON ((s.artist_id = art.artist_id))) LEFT JOIN albums alb ON ((s.album_id = alb.album_id)));


--
-- Name: album_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE albums ALTER COLUMN album_id SET DEFAULT nextval('albums_album_id_seq'::regclass);


--
-- Name: artist_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE artists ALTER COLUMN artist_id SET DEFAULT nextval('artists_artist_id_seq'::regclass);


--
-- Name: comment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE comments ALTER COLUMN comment_id SET DEFAULT nextval('comments_comment_id_seq'::regclass);


--
-- Name: playlist_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE playlists ALTER COLUMN playlist_id SET DEFAULT nextval('playlists_playlist_id_seq'::regclass);


--
-- Name: pcomment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE post_comments ALTER COLUMN pcomment_id SET DEFAULT nextval('post_comments_pcomment_id_seq'::regclass);


--
-- Name: post_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE posts ALTER COLUMN post_id SET DEFAULT nextval('posts_post_id_seq'::regclass);


--
-- Name: song_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE songs ALTER COLUMN song_id SET DEFAULT nextval('songs_song_id_seq'::regclass);


--
-- Name: user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN user_id SET DEFAULT nextval('users_user_id_seq'::regclass);


--
-- Data for Name: albums; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.albums (album_id, title, artist_id, release_year, cover_url) FROM stdin;
1	Rock	1	\N	\N
2	Inspirational	2	\N	\N
3	Easy Listening	3	\N	\N
4	Instrumental	4	\N	\N
5	Electronic	5	\N	\N
6	Soundtrack	6	\N	\N
7	Hip Hop/Rap	7	\N	\N
8	Classical	6	\N	\N
9	Comedy	13	\N	\N
10	Orchestral	4	\N	\N
11	New Age	14	\N	\N
12	Dance	15	\N	\N
13	Country	12	\N	\N
14	World	1	\N	\N
15	Folk	1	\N	\N
16	R&B/Soul	12	\N	\N
17	Children's Music	1	\N	\N
18	chinese	1	\N	\N
19	Holiday	1	\N	\N
20	Christian & Gospel	1	\N	\N
21	Brazilian	13	\N	\N
22	Pop	1	\N	\N
23	Jazz	23	\N	\N
24	Reggae	13	\N	\N
25	Alternative	5	\N	\N
26	ODDINARY	\N	\N	\N
415	ODDINARY	63	\N	\N
416	ODDINARY	64	\N	\N
286	Instrumental	8	\N	\N
287	Electronic	44	\N	\N
288	Soundtrack	16	\N	\N
289	Soundtrack	8	\N	\N
290	Electronic	42	\N	\N
291	Electronic	16	\N	\N
292	Electronic	4	\N	\N
293	Electronic	52	\N	\N
294	Electronic	36	\N	\N
295	Electronic	48	\N	\N
296	Hip Hop/Rap	22	\N	\N
297	Instrumental	18	\N	\N
298	Instrumental	22	\N	\N
299	Soundtrack	29	\N	\N
300	Electronic	30	\N	\N
301	Instrumental	17	\N	\N
302	Electronic	50	\N	\N
303	Children's Music	13	\N	\N
304	Soundtrack	31	\N	\N
305	Instrumental	15	\N	\N
306	Electronic	40	\N	\N
307	Classical	33	\N	\N
308	Orchestral	32	\N	\N
309	Electronic	35	\N	\N
310	Electronic	58	\N	\N
311	Electronic	1	\N	\N
312	Easy Listening	25	\N	\N
313	Electronic	61	\N	\N
314	Electronic	29	\N	\N
315	Easy Listening	7	\N	\N
316	Easy Listening	11	\N	\N
317	Folk	12	\N	\N
318	Electronic	19	\N	\N
319	R&B/Soul	22	\N	\N
320	Electronic	8	\N	\N
321	Electronic	41	\N	\N
322	Classical	1	\N	\N
323	Easy Listening	34	\N	\N
324	Electronic	47	\N	\N
325	Instrumental	7	\N	\N
326	Instrumental	23	\N	\N
327	Electronic	33	\N	\N
328	Electronic	60	\N	\N
329	Electronic	55	\N	\N
330	Hip Hop/Rap	12	\N	\N
331	World	13	\N	\N
332	New Age	1	\N	\N
333	Rock	11	\N	\N
334	Electronic	34	\N	\N
335	Soundtrack	19	\N	\N
336	Electronic	9	\N	\N
337	Electronic	39	\N	\N
338	Electronic	62	\N	\N
339	Electronic	54	\N	\N
340	Soundtrack	1	\N	\N
341	Easy Listening	15	\N	\N
342	Holiday	25	\N	\N
343	Easy Listening	59	\N	\N
344	Easy Listening	9	\N	\N
345	Children's Music	18	\N	\N
346	Inspirational	13	\N	\N
347	Hip Hop/Rap	11	\N	\N
348	Instrumental	11	\N	\N
349	Orchestral	16	\N	\N
350	Orchestral	11	\N	\N
351	Instrumental	6	\N	\N
352	Hip Hop/Rap	20	\N	\N
353	New Age	11	\N	\N
354	Rock	6	\N	\N
355	Soundtrack	12	\N	\N
356	Instrumental	2	\N	\N
357	Classical	26	\N	\N
358	Rock	12	\N	\N
359	Electronic	53	\N	\N
360	Electronic	43	\N	\N
361	Holiday	7	\N	\N
362	Electronic	32	\N	\N
363	Dance	27	\N	\N
364	Electronic	11	\N	\N
365	Hip Hop/Rap	19	\N	\N
366	Rock	8	\N	\N
367	Easy Listening	2	\N	\N
368	Classical	22	\N	\N
369	Electronic	28	\N	\N
370	Electronic	18	\N	\N
371	Electronic	45	\N	\N
372	Electronic	57	\N	\N
373	Electronic	15	\N	\N
374	World	25	\N	\N
375	Easy Listening	22	\N	\N
376	Easy Listening	4	\N	\N
377	Instrumental	25	\N	\N
378	Soundtrack	13	\N	\N
379	Orchestral	26	\N	\N
380	Classical	10	\N	\N
381	Instrumental	12	\N	\N
382	Soundtrack	10	\N	\N
383	Instrumental	30	\N	\N
384	Electronic	27	\N	\N
385	Instrumental	19	\N	\N
386	Dance	4	\N	\N
387	Soundtrack	11	\N	\N
388	Electronic	38	\N	\N
389	Electronic	23	\N	\N
390	Electronic	10	\N	\N
391	Instrumental	13	\N	\N
392	Electronic	13	\N	\N
393	Orchestral	1	\N	\N
394	Easy Listening	16	\N	\N
395	Easy Listening	35	\N	\N
396	Hip Hop/Rap	24	\N	\N
397	Electronic	22	\N	\N
398	Instrumental	9	\N	\N
399	Electronic	49	\N	\N
400	Electronic	56	\N	\N
401	Electronic	21	\N	\N
402	Instrumental	16	\N	\N
403	Reggae	1	\N	\N
404	Instrumental	21	\N	\N
405	Electronic	46	\N	\N
406	Easy Listening	36	\N	\N
407	Electronic	37	\N	\N
408	Electronic	6	\N	\N
409	Instrumental	1	\N	\N
410	Electronic	17	\N	\N
411	Electronic	51	\N	\N
412	Soundtrack	26	\N	\N
413	Hip Hop/Rap	1	\N	\N
414	Electronic	12	\N	\N
\.
;

--
-- Name: albums_album_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('albums_album_id_seq', 416, true);


--
-- Data for Name: artists; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.artists (artist_id, name, description) FROM stdin;
1	Zambolino	\N
2	Bluewave	\N
3	Calima	\N
4	Johny Grimes	\N
5	HiLau	\N
6	Nebulite	\N
7	Aventure	\N
8	Pufino	\N
9	massobeats	\N
10	Alegend	\N
11	Aylex	\N
12	Dagored	\N
13	Walen	\N
14	numbthefeelings	\N
15	Spiring	\N
16	Sunborn	\N
17	AgusAlvarez	\N
18	Piki	\N
19	Tetuano	\N
20	NVL8	\N
21	ESCP	\N
22	Moavii	\N
23	Avanti	\N
24	Burgundy X	\N
25	Aetheric	\N
26	Orchestronika	\N
27	AgusAlvarez, Luke Bergs	\N
28	Limujii	\N
29	Project Ex	\N
30	Lukrembo	\N
31	Conquest	\N
32	Kashia	\N
33	Epic Spectrum	\N
34	Filo Starquez	\N
35	Chill Pulse	\N
36	Ocean Bloom	\N
37	Unheard	\N
38	Sunova	\N
39	Aeris	\N
40	Luke Bergs, AgusAlvarez	\N
41	Damtaro	\N
42	Eric Lund	\N
43	tubebackr	\N
44	Luke Bergs, Nebulite	\N
45	Hazelwood	\N
46	Tetuano, tubebackr	\N
47	Burgundy	\N
48	tubebackr, Filo Starquez	\N
49	tubebackr, Tetuano	\N
50	AgusAlvarez, Waesto	\N
51	VTEMO	\N
52	HiLau, tubebackr	\N
53	AgusAlvarez, Sunova	\N
54	shandr	\N
55	Waesto	\N
56	Soyb	\N
57	Amine Maxwell	\N
58	Guillermo Guareschi	\N
59	Hoffy Beats	\N
60	Luke Bergs, Waesto	\N
61	Popsicles	\N
62	Luke Bergs	\N
63	Stray Kids	\N
64	StrayKids	\N
\.
;

--
-- Name: artists_artist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('artists_artist_id_seq', 64, true);


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.comments (comment_id, song_id, user_id, content, created_at) FROM stdin;
1	436	2	11	2026-05-22 14:39:17.0858
3	2	2	好好听！	2026-06-03 21:12:14.353761
\.
;

--
-- Name: comments_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('comments_comment_id_seq', 3, true);


--
-- Data for Name: playlist_songs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.playlist_songs (playlist_id, song_id, added_at) FROM stdin;
1	436	2026-05-22 03:46:12.670513
4	436	2026-05-28 02:23:32.718939
5	444	2026-05-28 02:31:04.805652
1	2	2026-06-03 13:11:42.001562
\.
;

--
-- Data for Name: playlists; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.playlists (playlist_id, name, creator_id, created_at) FROM stdin;
1	我喜欢的歌曲	2	2026-05-22 03:46:12.664863
4	推荐歌单1	2	2026-05-28 01:11:34.961471
5	我喜欢的歌曲	7	2026-05-28 02:31:04.802479
\.
;

--
-- Name: playlists_playlist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('playlists_playlist_id_seq', 5, true);


--
-- Data for Name: post_comments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.post_comments (pcomment_id, post_id, user_id, content, created_at) FROM stdin;
4	5	5	好听好听	2026-05-28 01:39:43.629472
5	7	5	有品有品	2026-06-03 13:14:13.890502
\.
;

--
-- Name: post_comments_pcomment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('post_comments_pcomment_id_seq', 5, true);


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.posts (post_id, user_id, title, content, recommended_song_id, created_at) FROM stdin;
5	2	推荐推荐	这首歌特别特别好听全世界都来听好吗好的	951	2026-05-28 01:10:22.467718
6	7	11	11	436	2026-05-28 02:32:35.799536
7	2	巨好听！神曲来的！	好喜欢呀！	1875	2026-06-03 13:13:19.442804
\.
;

--
-- Name: posts_post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('posts_post_id_seq', 7, true);


--
-- Data for Name: songs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.songs (song_id, title, artist_id, album_id, duration_seconds, audio_url, genre, comment_count) FROM stdin;
1	Slowburn	1	1	126	https://data.freetouse.com/music/tracks/a97ec58e-b099-497c-9d3f-270403406104/file/mp3/file.mp3	未知	0
2	Better Days	2	2	166	https://data.freetouse.com/music/tracks/b6b6e570-a1ae-4f64-bb86-1561d7ca9eb5/file/mp3/file.mp3	未知	1
3	Ocean Time	3	3	146	https://data.freetouse.com/music/tracks/dbfa2f2d-2414-4839-8fe1-7900068ee859/file/mp3/file.mp3	未知	0
4	Full Moon	3	3	140	https://data.freetouse.com/music/tracks/5b34cebb-5a70-493b-90d0-0bd82d7f2fa7/file/mp3/file.mp3	未知	0
5	Starry Night	3	3	140	https://data.freetouse.com/music/tracks/149e4202-f3c5-4b3d-b3a5-0f7d37a1d1bb/file/mp3/file.mp3	未知	0
6	Forest Zen	3	3	137	https://data.freetouse.com/music/tracks/cd0e5721-13f0-4740-ba14-949773603930/file/mp3/file.mp3	未知	0
7	Homecoming	3	3	129	https://data.freetouse.com/music/tracks/2d0f167b-b8a1-433a-806d-c0df2c2e556f/file/mp3/file.mp3	未知	0
8	Autumn Bliss	3	3	137	https://data.freetouse.com/music/tracks/df477a9c-80e6-49b1-abda-a678155676d7/file/mp3/file.mp3	未知	0
9	Spring Flow	3	3	152	https://data.freetouse.com/music/tracks/99631c37-c0c8-4918-95cd-d8c05dd2cce3/file/mp3/file.mp3	未知	0
11	Glass Shop	3	3	145	https://data.freetouse.com/music/tracks/6efa949e-080a-43bc-8980-1b2085ef700a/file/mp3/file.mp3	未知	0
12	Himalayas	3	3	159	https://data.freetouse.com/music/tracks/0ba920f0-3ab3-444a-bc35-b6a05702e382/file/mp3/file.mp3	未知	0
13	Beautiful Life	4	4	164	https://data.freetouse.com/music/tracks/b5cc20fc-7b0d-41cc-b048-90b43cb6ae68/file/mp3/file.mp3	未知	0
14	Big Deal	5	5	188	https://data.freetouse.com/music/tracks/b3ff64a5-7fcc-45e3-8748-70539f1229c6/file/mp3/file.mp3	未知	0
16	Monday Routine	7	315	143	https://data.freetouse.com/music/tracks/c7c31884-f971-4430-8190-31b1f79f3e68/file/mp3/file.mp3	未知	0
17	Ophelia	1	311	106	https://data.freetouse.com/music/tracks/39e028e3-fe03-4286-9ab9-8d436a2a45cc/file/mp3/file.mp3	未知	0
18	Insidious	8	286	139	https://data.freetouse.com/music/tracks/b87e5651-ec4f-47fa-990e-4d2dbc057e23/file/mp3/file.mp3	未知	0
20	farlands	9	398	156	https://data.freetouse.com/music/tracks/a230a236-50ef-482b-86e1-856fd400b212/file/mp3/file.mp3	未知	0
21	Lagoon	4	292	134	https://data.freetouse.com/music/tracks/735f4c4d-fc34-489f-b76a-5a4738cc9e9e/file/mp3/file.mp3	未知	0
22	Overdrive	6	354	96	https://data.freetouse.com/music/tracks/ae01872e-4553-4569-bf06-f6ae375b1322/file/mp3/file.mp3	未知	0
23	Riding The Wave	1	1	104	https://data.freetouse.com/music/tracks/222c77dc-08e7-4fb1-9cac-01f25612c3ef/file/mp3/file.mp3	未知	0
24	The Sun's Ray	7	7	148	https://data.freetouse.com/music/tracks/8f23c45b-2d10-4be2-adef-5a19c6436159/file/mp3/file.mp3	未知	0
25	Supernova	10	382	174	https://data.freetouse.com/music/tracks/90a07fa6-db72-4165-8d4c-37c700416ac6/file/mp3/file.mp3	未知	0
26	Geography	11	387	120	https://data.freetouse.com/music/tracks/a5b2e60b-03b4-463e-98cb-dcdb04e5e1aa/file/mp3/file.mp3	未知	0
28	Christmas Time	6	351	149	https://data.freetouse.com/music/tracks/63237a9c-87e8-4df5-88db-ae308097b355/file/mp3/file.mp3	未知	0
29	Childhood	7	7	161	https://data.freetouse.com/music/tracks/c3b4be4a-e39a-4d07-bee9-dcac7986eefd/file/mp3/file.mp3	未知	0
30	Wedding Waltz	6	8	134	https://data.freetouse.com/music/tracks/f0242b85-3b87-4590-89a0-606e0aa1eb66/file/mp3/file.mp3	未知	0
31	once was	9	398	151	https://data.freetouse.com/music/tracks/7fea0d46-b7f1-49c0-b6a5-0a5c39a02a7c/file/mp3/file.mp3	未知	0
32	Urban Pulse	12	330	110	https://data.freetouse.com/music/tracks/9d94da4c-d04b-4668-bf5f-e6f494afff10/file/mp3/file.mp3	未知	0
34	Sneaky Robber	13	9	99	https://data.freetouse.com/music/tracks/87f2cdfe-f087-4325-8b7b-60274a90f0cb/file/mp3/file.mp3	未知	0
35	First Days of Spring	1	322	86	https://data.freetouse.com/music/tracks/1e14299b-94db-4b19-aa5b-4f8a4f27ad5d/file/mp3/file.mp3	未知	0
36	Iron Pulse	6	354	163	https://data.freetouse.com/music/tracks/023061e4-1711-4a44-b019-93374be13772/file/mp3/file.mp3	未知	0
37	Easy Tone	7	325	141	https://data.freetouse.com/music/tracks/f60f7301-5291-4142-afd7-53ab36f83ef9/file/mp3/file.mp3	未知	0
38	Moving Forward	2	2	150	https://data.freetouse.com/music/tracks/c19cf4da-9d2a-4918-a5e0-046bec5f0487/file/mp3/file.mp3	未知	0
39	Conspiracy Detective	13	391	148	https://data.freetouse.com/music/tracks/6ffd1828-93c1-4349-abc9-223fcd0f327f/file/mp3/file.mp3	未知	0
40	Pixel Duck	4	376	172	https://data.freetouse.com/music/tracks/c793b370-25cf-46d5-a88f-559a554338d1/file/mp3/file.mp3	未知	0
42	Soft Morning	7	325	166	https://data.freetouse.com/music/tracks/8b55c2b4-9640-486b-bd5f-b1ee9807b420/file/mp3/file.mp3	未知	0
43	Long Journey Home	4	10	158	https://data.freetouse.com/music/tracks/90b3be4f-9aae-4066-8b50-87fd66aa4eee/file/mp3/file.mp3	未知	0
44	Cosmic Whale	4	376	142	https://data.freetouse.com/music/tracks/e8300827-633c-4d4e-82a2-3470e328a3e7/file/mp3/file.mp3	未知	0
46	Back To Synthwave	6	408	187	https://data.freetouse.com/music/tracks/40973ee4-4486-4513-9046-09d2749642b4/file/mp3/file.mp3	未知	0
47	Sea Coastline	15	12	157	https://data.freetouse.com/music/tracks/b1a5be56-2342-4681-8902-8caab6d59129/file/mp3/file.mp3	未知	0
48	Stellar	7	325	182	https://data.freetouse.com/music/tracks/7d57ea7a-85a8-4f71-97c8-7b777eaa02f6/file/mp3/file.mp3	未知	0
49	Childhood Lost	1	322	76	https://data.freetouse.com/music/tracks/83c6cf9f-f398-4a61-88c3-fd48fe12724f/file/mp3/file.mp3	未知	0
50	Sustainable	11	316	137	https://data.freetouse.com/music/tracks/7db903c2-9586-4533-8da2-93e2472f1207/file/mp3/file.mp3	未知	0
51	redemption	14	11	106	https://data.freetouse.com/music/tracks/c09dc2c5-5bb1-4fb1-843b-d074d1a7e265/file/mp3/file.mp3	未知	0
52	Chillout	16	291	139	https://data.freetouse.com/music/tracks/557e43c7-4ea2-4b65-b6ba-574653b4935a/file/mp3/file.mp3	未知	0
53	Subtle Glow	7	325	133	https://data.freetouse.com/music/tracks/1c4d9b3c-870c-41dc-8e01-c702a4520dc1/file/mp3/file.mp3	未知	0
54	Sunny Trails	12	13	156	https://data.freetouse.com/music/tracks/0eb63b49-c1cf-4aac-92de-ae8f49a409c7/file/mp3/file.mp3	未知	0
55	citrus	9	398	136	https://data.freetouse.com/music/tracks/654e7631-341d-4af6-a40b-0f38039365c1/file/mp3/file.mp3	未知	0
27	Cassette Groove	7	7	167	https://data.freetouse.com/music/tracks/aac3e875-3fe7-4a91-b3a9-d651d7bb12e7/file/mp3/file.mp3	未知	0
56	Funk It Up	17	410	166	https://data.freetouse.com/music/tracks/e3e7662b-72a2-41bc-ba6d-e071d8dd2850/file/mp3/file.mp3	未知	0
57	Bosporus	1	14	108	https://data.freetouse.com/music/tracks/94218271-30aa-4669-bdd4-41ee5993f116/file/mp3/file.mp3	未知	0
58	before dawn	14	11	100	https://data.freetouse.com/music/tracks/e7bb8d54-6e15-4b9e-8f95-77bacdf435f8/file/mp3/file.mp3	未知	0
59	Close Friends	7	7	182	https://data.freetouse.com/music/tracks/77150365-316a-4acb-92c9-1d2fbb4766fe/file/mp3/file.mp3	未知	0
60	Colossal	11	387	118	https://data.freetouse.com/music/tracks/d5aca868-0444-4ba1-86fc-7d91cd7676b6/file/mp3/file.mp3	未知	0
61	Dreamy Cat	4	376	183	https://data.freetouse.com/music/tracks/923cf9c0-fa29-49c6-8770-b318a5346fb4/file/mp3/file.mp3	未知	0
62	Instance	4	292	133	https://data.freetouse.com/music/tracks/7ae0cf54-254a-4504-a302-28cae53179aa/file/mp3/file.mp3	未知	0
63	Trinity	4	292	150	https://data.freetouse.com/music/tracks/7fa9bd07-ff25-44e0-b343-4be730499b15/file/mp3/file.mp3	未知	0
64	Trinix	4	386	143	https://data.freetouse.com/music/tracks/66e1b1b9-5c27-4796-a919-71dddefc4c19/file/mp3/file.mp3	未知	0
65	Evening Nostalgia	7	7	103	https://data.freetouse.com/music/tracks/17c668bd-ec37-4986-81e6-4ca0a44eb618/file/mp3/file.mp3	未知	0
66	Steady	1	1	125	https://data.freetouse.com/music/tracks/a4120e12-65f6-4709-a1ed-dbff24523e47/file/mp3/file.mp3	未知	0
67	Moments	16	291	141	https://data.freetouse.com/music/tracks/31f12c10-3a06-471d-bffa-b5107affec92/file/mp3/file.mp3	未知	0
68	Trendy	11	333	146	https://data.freetouse.com/music/tracks/9306fe9f-ec76-4284-a337-15d7b04358b0/file/mp3/file.mp3	未知	0
69	In Your Hands	7	7	138	https://data.freetouse.com/music/tracks/0eb2a756-e3c1-4c37-b487-1547c044192f/file/mp3/file.mp3	未知	0
70	Fakir	1	14	128	https://data.freetouse.com/music/tracks/733adec1-5f69-483c-8183-b09b02d54c49/file/mp3/file.mp3	未知	0
71	The Choice	13	346	129	https://data.freetouse.com/music/tracks/0b8d1ab9-db77-414e-9fe9-1713613a2b83/file/mp3/file.mp3	未知	0
72	Sundown	17	301	181	https://data.freetouse.com/music/tracks/04e98369-4b02-4d6c-b93f-7336af00b562/file/mp3/file.mp3	未知	0
74	petals	9	398	134	https://data.freetouse.com/music/tracks/56193a8c-d821-4a73-83ed-9e96f3e6caa2/file/mp3/file.mp3	未知	0
75	Quiet Bounce	7	7	144	https://data.freetouse.com/music/tracks/c6110ad3-ef27-4337-b561-cb366fe80bbb/file/mp3/file.mp3	未知	0
76	Andorra	1	15	95	https://data.freetouse.com/music/tracks/c4a60593-64f7-4076-9a6e-a8865eca970e/file/mp3/file.mp3	未知	0
77	Blue Planet	18	297	220	https://data.freetouse.com/music/tracks/ab2c0d6d-05f0-4429-9e09-12bcbe7355bf/file/mp3/file.mp3	未知	0
78	Lifestyle Groove	12	16	113	https://data.freetouse.com/music/tracks/37f8b2c2-4b7b-479a-aee7-7b94075388fd/file/mp3/file.mp3	未知	0
80	Abyss	19	335	122	https://data.freetouse.com/music/tracks/21c3d8b4-423b-4617-b630-3fc70ad91cf7/file/mp3/file.mp3	未知	0
81	Come On	1	1	79	https://data.freetouse.com/music/tracks/449963df-2677-4d3f-9502-db64b77f9a12/file/mp3/file.mp3	未知	0
82	afraid	14	11	88	https://data.freetouse.com/music/tracks/313a251c-f9af-448d-8949-1f282762c618/file/mp3/file.mp3	未知	0
83	Strategic	11	316	122	https://data.freetouse.com/music/tracks/c07816bd-92e3-4ecf-b513-6de2d5da2216/file/mp3/file.mp3	未知	0
84	Productive	11	364	142	https://data.freetouse.com/music/tracks/2afd80dc-7c13-4555-9827-db113a61611c/file/mp3/file.mp3	未知	0
85	lullaby	14	11	84	https://data.freetouse.com/music/tracks/a14d69c6-ceae-448f-8b52-1f3bedb03f19/file/mp3/file.mp3	未知	0
86	Pink Clouds	20	352	99	https://data.freetouse.com/music/tracks/d663407f-da1c-4851-ac34-041914d2f4f7/file/mp3/file.mp3	未知	0
87	distant	14	11	95	https://data.freetouse.com/music/tracks/b36c225a-3a96-4269-aab8-4c955d31a9c4/file/mp3/file.mp3	未知	0
88	memories	9	398	154	https://data.freetouse.com/music/tracks/103e1b68-5b31-41e7-bc84-9b11b61d7597/file/mp3/file.mp3	未知	0
89	Swag Season	20	352	98	https://data.freetouse.com/music/tracks/623a7071-6518-4b50-8a16-8e19d70622aa/file/mp3/file.mp3	未知	0
90	Evolving	11	364	133	https://data.freetouse.com/music/tracks/e7da62d7-3024-486f-9295-98a25f5ceb50/file/mp3/file.mp3	未知	0
91	ashes	14	11	86	https://data.freetouse.com/music/tracks/1c801912-0dd5-4e73-ae57-b32e02fd5f94/file/mp3/file.mp3	未知	0
92	Trappin	20	352	146	https://data.freetouse.com/music/tracks/ec06b686-2e68-4735-b76d-479d1f8094a3/file/mp3/file.mp3	未知	0
93	De Profundis	1	409	113	https://data.freetouse.com/music/tracks/07563975-e114-4304-8ed4-5a8860d2a06d/file/mp3/file.mp3	未知	0
94	your cold hands	14	11	76	https://data.freetouse.com/music/tracks/d5550be1-9ed0-4a17-85aa-01d326625b00/file/mp3/file.mp3	未知	0
95	Over You	20	352	121	https://data.freetouse.com/music/tracks/0b2ef91a-3a81-4453-a5c6-5bfd8c99ce76/file/mp3/file.mp3	未知	0
96	Warm Morning	12	381	163	https://data.freetouse.com/music/tracks/98dd5cde-767d-4c47-91c7-51686d489f6f/file/mp3/file.mp3	未知	0
97	timeless	9	398	148	https://data.freetouse.com/music/tracks/d4247218-17f2-4375-81a3-efd5c092533b/file/mp3/file.mp3	未知	0
98	lose her	14	11	97	https://data.freetouse.com/music/tracks/24f3a2ff-f85a-479d-adad-279ad7170f19/file/mp3/file.mp3	未知	0
99	Loved to Feel	20	352	157	https://data.freetouse.com/music/tracks/540f1f38-b88c-4905-bdf1-63f6e3bcf9f8/file/mp3/file.mp3	未知	0
100	Jungle Monkey	13	331	124	https://data.freetouse.com/music/tracks/cce6c6cf-6574-4a39-a2e9-e84f90182356/file/mp3/file.mp3	未知	0
101	Passage	1	1	116	https://data.freetouse.com/music/tracks/5e8f6033-dae2-470d-8a48-0dbf9a44b59d/file/mp3/file.mp3	未知	0
102	wake me up	14	11	91	https://data.freetouse.com/music/tracks/a0348e62-c666-4547-b7d8-95c2e6d2ae4e/file/mp3/file.mp3	未知	0
103	Backstreets	12	381	124	https://data.freetouse.com/music/tracks/6fdfb1a8-c21b-4a5a-ad24-15e1c522b9fb/file/mp3/file.mp3	未知	0
104	Colourful	15	305	127	https://data.freetouse.com/music/tracks/edcf473d-2b1e-4b7d-b2ca-ea009209b726/file/mp3/file.mp3	未知	0
105	things i never said	14	11	84	https://data.freetouse.com/music/tracks/cfa655be-c04c-4740-8361-56e48b25b358/file/mp3/file.mp3	未知	0
106	Keep It Cool	13	392	140	https://data.freetouse.com/music/tracks/a58941f3-57e7-4060-9abe-a91dc162f042/file/mp3/file.mp3	未知	0
108	floating	14	11	79	https://data.freetouse.com/music/tracks/4b8692c4-5e20-42db-b5c7-73aed0030242/file/mp3/file.mp3	未知	0
109	Fashion Flow	21	401	255	https://data.freetouse.com/music/tracks/4cd43a21-6a98-4a91-88c8-b646c51d3a0b/file/mp3/file.mp3	未知	0
110	Downtown	19	318	128	https://data.freetouse.com/music/tracks/1777ba8e-9d18-4c23-ae7f-7bb81b82b44c/file/mp3/file.mp3	未知	0
111	Sinister	11	387	175	https://data.freetouse.com/music/tracks/b0e90f9b-1aa0-43ea-8d36-be9ff0c293b6/file/mp3/file.mp3	未知	0
112	when i'm gone	14	11	96	https://data.freetouse.com/music/tracks/f321cc4f-bc81-4bf7-9153-42597ce21d54/file/mp3/file.mp3	未知	0
113	sky	9	398	136	https://data.freetouse.com/music/tracks/947eedd6-6f23-4503-9d27-e4c472682a77/file/mp3/file.mp3	未知	0
114	Root	22	298	58	https://data.freetouse.com/music/tracks/eba38cc0-7253-497c-8800-68d84fbc2b10/file/mp3/file.mp3	未知	0
115	Investigations	11	387	157	https://data.freetouse.com/music/tracks/a732a2c6-1ec3-441f-9c1d-8ad39595d5c5/file/mp3/file.mp3	未知	0
116	Open Field	16	288	122	https://data.freetouse.com/music/tracks/d5bbb15f-fa3e-46a8-aebc-6d7a4da947d5/file/mp3/file.mp3	未知	0
117	Vibe With You	5	5	205	https://data.freetouse.com/music/tracks/823e5841-5bc6-4104-814a-6b225f76eac7/file/mp3/file.mp3	未知	0
10	Silence of the Night Forest	3	3	146	https://data.freetouse.com/music/tracks/a3fc559a-3e02-41dd-9f05-868cd9a09594/file/mp3/file.mp3	未知	0
15	Eternal Rise	6	6	105	https://data.freetouse.com/music/tracks/87e28ee3-818a-4416-81be-70760bfacabe/file/mp3/file.mp3	未知	0
19	Subtle Progression	2	2	158	https://data.freetouse.com/music/tracks/9eeb2a91-885c-4256-b71e-d2a7f5476d23/file/mp3/file.mp3	未知	0
33	Coffee & Vinyl	7	7	143	https://data.freetouse.com/music/tracks/3b8280eb-dc65-4288-96db-d2f36de03cc9/file/mp3/file.mp3	未知	0
118	Medical Research	11	316	89	https://data.freetouse.com/music/tracks/55ac1b56-70ea-4fce-95e0-de17598a8d4f/file/mp3/file.mp3	未知	0
119	Simple Success	2	2	161	https://data.freetouse.com/music/tracks/74ed5b0a-31b8-4e97-bbba-0c26745d88a1/file/mp3/file.mp3	未知	0
120	Boomer	1	1	136	https://data.freetouse.com/music/tracks/bb1cc9a9-68b3-4009-82ea-5e88a827719f/file/mp3/file.mp3	未知	0
121	Steel & Glory	11	333	120	https://data.freetouse.com/music/tracks/75035428-cbb5-4795-a19c-cef856dfc0f1/file/mp3/file.mp3	未知	0
122	Lothlorien	1	340	167	https://data.freetouse.com/music/tracks/3c8fc0a9-57a7-49d2-93c6-719be168a080/file/mp3/file.mp3	未知	0
123	The Sky	16	402	182	https://data.freetouse.com/music/tracks/5b18886c-3472-4259-b9bb-f80fb4f6f924/file/mp3/file.mp3	未知	0
124	Powered	11	364	126	https://data.freetouse.com/music/tracks/2fedf2db-b98f-4caa-b0a7-c708779d18ad/file/mp3/file.mp3	未知	0
125	Future Focus	2	2	148	https://data.freetouse.com/music/tracks/4c670361-244a-4ac7-95a9-e888fb2a9b41/file/mp3/file.mp3	未知	0
126	Nighthawk	1	1	93	https://data.freetouse.com/music/tracks/9a421961-6825-4c15-8651-3f673fa9828f/file/mp3/file.mp3	未知	0
127	Stalker	1	311	131	https://data.freetouse.com/music/tracks/38137490-f9f4-4a7e-8dab-18094b4eb5fc/file/mp3/file.mp3	未知	0
129	Late Night	15	373	130	https://data.freetouse.com/music/tracks/cd7f2db3-1b11-4b2f-9d9b-9679c3c13abd/file/mp3/file.mp3	未知	0
130	Demiurge	1	1	129	https://data.freetouse.com/music/tracks/62d1b151-361b-42ce-84c2-dea2e9fd7c6c/file/mp3/file.mp3	未知	0
131	Crime Scene	11	387	127	https://data.freetouse.com/music/tracks/d47e2600-28b6-4100-acf1-afbc05f0945b/file/mp3/file.mp3	未知	0
132	Tiptoe	1	17	63	https://data.freetouse.com/music/tracks/bc1176d8-eed8-414f-b556-03d54c11427c/file/mp3/file.mp3	未知	0
134	Warm Rain	1	322	118	https://data.freetouse.com/music/tracks/cfa3b1bd-6acd-49e0-a026-f4b7cd741859/file/mp3/file.mp3	未知	0
135	Unstoppable	11	387	189	https://data.freetouse.com/music/tracks/9238d410-4ce7-48c9-b290-c4e915bb9a22/file/mp3/file.mp3	未知	0
136	Better Days	16	402	157	https://data.freetouse.com/music/tracks/f5c5960b-7a00-48be-b388-3c709dd1d2fb/file/mp3/file.mp3	未知	0
137	Swanlake	1	332	149	https://data.freetouse.com/music/tracks/3aff8d54-7167-4ee6-bf4d-1420523c6269/file/mp3/file.mp3	未知	0
41	Bazar	1	311	90	https://data.freetouse.com/music/tracks/cffa4586-e7ce-4b1a-960a-2c52dfb80adc/file/mp3/file.mp3	未知	0
45	insomnia	14	11	89	https://data.freetouse.com/music/tracks/20c03c02-b1de-4eaf-92be-840136262933/file/mp3/file.mp3	未知	0
79	Cold Coffee	7	7	158	https://data.freetouse.com/music/tracks/6ebc2c15-2e43-4163-901d-e25ab823db96/file/mp3/file.mp3	未知	0
107	Moment of Peace	1	332	147	https://data.freetouse.com/music/tracks/2f02b7db-85b9-430d-b8ba-1aaee67e545e/file/mp3/file.mp3	未知	0
138	Lumora	11	348	132	https://data.freetouse.com/music/tracks/b92bc882-054d-4a0c-be14-f50242ecfbcc/file/mp3/file.mp3	未知	0
139	Soft Static	23	389	188	https://data.freetouse.com/music/tracks/15baf58e-2e84-43b0-a30a-b147308c8088/file/mp3/file.mp3	未知	0
140	chilly	9	398	156	https://data.freetouse.com/music/tracks/74468a92-1c20-4a9d-8bf7-7cdc277b43a5/file/mp3/file.mp3	未知	0
141	Geisha	1	18	136	https://data.freetouse.com/music/tracks/2661f463-0b0f-4b9b-9ff6-c5f9752f461a/file/mp3/file.mp3	未知	0
142	Obscure	11	387	203	https://data.freetouse.com/music/tracks/7f2069ab-aa21-4999-a169-ac6939ca8b85/file/mp3/file.mp3	未知	0
143	Driving On Country Roads	12	13	126	https://data.freetouse.com/music/tracks/dea2bed9-9070-498d-8f66-463f503a8fb9/file/mp3/file.mp3	未知	0
144	Morning Hope	2	2	128	https://data.freetouse.com/music/tracks/6f220e78-246f-4ded-85ea-b119c6f1eac0/file/mp3/file.mp3	未知	0
145	New World	10	382	199	https://data.freetouse.com/music/tracks/7e36cb3a-a5c7-47b7-b33e-3acaa672cbb9/file/mp3/file.mp3	未知	0
146	The One	24	396	111	https://data.freetouse.com/music/tracks/dfb7921e-0397-46bf-8d4a-db1ea67c860f/file/mp3/file.mp3	未知	0
147	City Life	15	341	99	https://data.freetouse.com/music/tracks/ffe5f357-28d4-493a-b7d8-9c581e3e7f6a/file/mp3/file.mp3	未知	0
148	Motions	16	402	122	https://data.freetouse.com/music/tracks/65c6f488-e939-4464-8e72-9c1a72fa9f6e/file/mp3/file.mp3	未知	0
149	Train Rag	1	311	112	https://data.freetouse.com/music/tracks/de072c6d-4c3d-4468-87da-1c17a28c70cc/file/mp3/file.mp3	未知	0
150	Next Step	11	348	118	https://data.freetouse.com/music/tracks/20b417b2-6cf8-44d0-bedc-7d5f247f90b1/file/mp3/file.mp3	未知	0
151	Snap Attack	11	347	88	https://data.freetouse.com/music/tracks/8e4716a0-0f36-4669-bc1e-eaf74baa968b/file/mp3/file.mp3	未知	0
152	Sultan	1	14	107	https://data.freetouse.com/music/tracks/1c227098-3e7f-4ab6-99be-49686a4094db/file/mp3/file.mp3	未知	0
153	Vacation	16	291	161	https://data.freetouse.com/music/tracks/12ecf0e4-d47d-48f0-be5d-884ffd09a4bb/file/mp3/file.mp3	未知	0
154	Tape Memories	7	7	152	https://data.freetouse.com/music/tracks/9f6976d6-efbd-413a-bcc0-b35129e88efb/file/mp3/file.mp3	未知	0
155	Level Up	11	348	137	https://data.freetouse.com/music/tracks/09234107-742a-4ec0-9a9b-9bec0c3df48c/file/mp3/file.mp3	未知	0
156	Emotive Technology	2	356	140	https://data.freetouse.com/music/tracks/0bf398cf-dbcf-40e7-9a22-83785328763b/file/mp3/file.mp3	未知	0
157	Heist	1	1	95	https://data.freetouse.com/music/tracks/d27254b3-4b58-44d2-bd7c-07dde6567683/file/mp3/file.mp3	未知	0
158	Happy Days	16	291	131	https://data.freetouse.com/music/tracks/fa67249f-416f-4de9-b70f-2f8c346fba9b/file/mp3/file.mp3	未知	0
159	Vogue Machine	11	348	159	https://data.freetouse.com/music/tracks/0a824cb7-56b7-4cac-88e6-e8f680f0c629/file/mp3/file.mp3	未知	0
161	ruby	9	398	137	https://data.freetouse.com/music/tracks/44f13459-4b6c-4063-b86c-b6c5491fb77f/file/mp3/file.mp3	未知	0
162	Insights	11	316	131	https://data.freetouse.com/music/tracks/430de930-81b2-4c84-a1e6-d621f96f05e7/file/mp3/file.mp3	未知	0
163	In the Kitchen	7	7	119	https://data.freetouse.com/music/tracks/cc5b9248-135b-4f64-839f-0cf9a4271f1d/file/mp3/file.mp3	未知	0
164	Imagine	16	291	159	https://data.freetouse.com/music/tracks/67f994a2-55b9-45bb-96d0-d61f342556bd/file/mp3/file.mp3	未知	0
165	Legends	1	1	95	https://data.freetouse.com/music/tracks/d7eb7fdf-38d3-49c2-a185-707e291a4095/file/mp3/file.mp3	未知	0
166	Explore the Unknown	2	2	147	https://data.freetouse.com/music/tracks/bd16f6c6-d1ea-44f2-9b69-dccf046167ae/file/mp3/file.mp3	未知	0
167	Aloha	23	326	159	https://data.freetouse.com/music/tracks/71b5b1ae-92ea-4846-b574-aad775d65a61/file/mp3/file.mp3	未知	0
168	Crossroads	11	347	146	https://data.freetouse.com/music/tracks/277f99ae-626a-4397-94e1-6c811fbacaea/file/mp3/file.mp3	未知	0
169	Midnight Velvet	12	16	120	https://data.freetouse.com/music/tracks/d6a3a0bb-ddac-473b-95e7-abd7aa50d50d/file/mp3/file.mp3	未知	0
170	Drip	11	364	100	https://data.freetouse.com/music/tracks/fc506a71-d618-4f60-995f-46e0997274ae/file/mp3/file.mp3	未知	0
171	Far Away	16	291	142	https://data.freetouse.com/music/tracks/0cfa943e-9b6f-49a7-9fb2-5baa953d6b65/file/mp3/file.mp3	未知	0
172	Uke Waves	11	316	129	https://data.freetouse.com/music/tracks/25b07db9-e62f-41d2-8609-5a882f3ef948/file/mp3/file.mp3	未知	0
173	Eastbound	24	396	97	https://data.freetouse.com/music/tracks/b2d1d717-fee7-40a8-bd4d-c8d6131f9396/file/mp3/file.mp3	未知	0
174	Urban Ease	7	7	146	https://data.freetouse.com/music/tracks/cb715351-c1b0-48d3-b30e-8d267f947cd1/file/mp3/file.mp3	未知	0
175	The Living Dead	1	340	220	https://data.freetouse.com/music/tracks/a6ba2b66-61a1-4fad-8044-8b47087a6ae6/file/mp3/file.mp3	未知	0
176	Going Back	16	402	156	https://data.freetouse.com/music/tracks/2dcc5e74-8913-45ce-9be5-79ae6d7e7627/file/mp3/file.mp3	未知	0
177	Building the Future	11	316	137	https://data.freetouse.com/music/tracks/ad7deb5e-aaca-4757-8ad8-3d065846f6b8/file/mp3/file.mp3	未知	0
178	Dreams	16	394	135	https://data.freetouse.com/music/tracks/10f72c60-6e86-44a7-b07c-75f18bdccf64/file/mp3/file.mp3	未知	0
179	Coffee & Streets	11	347	117	https://data.freetouse.com/music/tracks/007ac6b4-3880-4e9a-8887-758498e0ba89/file/mp3/file.mp3	未知	0
180	Lullaby	7	7	165	https://data.freetouse.com/music/tracks/94ab810c-f14e-4f36-9c7c-54359d01e3b5/file/mp3/file.mp3	未知	0
181	Jingle Bells	1	19	103	https://data.freetouse.com/music/tracks/deb2e28a-f63f-46fd-81f0-02aeae2dad5a/file/mp3/file.mp3	未知	0
182	Evening Thoughts	16	291	135	https://data.freetouse.com/music/tracks/f02e1029-1977-452a-ab52-f9768da0caa5/file/mp3/file.mp3	未知	0
183	Rise Up	11	348	113	https://data.freetouse.com/music/tracks/3ac71652-c886-4af0-8e79-459f554dcf11/file/mp3/file.mp3	未知	0
184	Silent Wish	7	361	165	https://data.freetouse.com/music/tracks/7a58cdf0-f724-4170-956a-71d8935da829/file/mp3/file.mp3	未知	0
185	Deep Within	16	349	124	https://data.freetouse.com/music/tracks/0c01d2db-0a29-4894-8795-afbbaeb90951/file/mp3/file.mp3	未知	0
186	Good Energy	11	347	103	https://data.freetouse.com/music/tracks/1b5bdcee-f88e-42b3-836c-a7cef179f253/file/mp3/file.mp3	未知	0
187	Back Alley	24	396	108	https://data.freetouse.com/music/tracks/7b36cd3b-e4a6-4ea1-9fc3-c6fbffa3cada/file/mp3/file.mp3	未知	0
188	The River	1	1	301	https://data.freetouse.com/music/tracks/10ea68d6-3c2a-4783-8108-c577f3b47f51/file/mp3/file.mp3	未知	0
189	Good Days	7	7	130	https://data.freetouse.com/music/tracks/d98b9913-e8a2-429f-a2fc-04c20b0dff10/file/mp3/file.mp3	未知	0
190	Live to Inspire	2	2	132	https://data.freetouse.com/music/tracks/5765c11a-69ac-4f93-85f5-c707fa04e415/file/mp3/file.mp3	未知	0
191	Dark Frequency	11	353	142	https://data.freetouse.com/music/tracks/80aed66c-6af9-4cb2-89d9-770c0bf6c478/file/mp3/file.mp3	未知	0
192	Better Place	16	402	184	https://data.freetouse.com/music/tracks/25c467d6-0d52-4f54-8342-2b9726668fe3/file/mp3/file.mp3	未知	0
193	lost	14	11	90	https://data.freetouse.com/music/tracks/a16accc7-91d0-4257-b5ea-c8c1627e3d41/file/mp3/file.mp3	未知	0
194	thoughts	9	398	157	https://data.freetouse.com/music/tracks/f67fd291-a51f-4b23-b4fa-1130871ec892/file/mp3/file.mp3	未知	0
195	By the Fireplace	7	361	158	https://data.freetouse.com/music/tracks/3b3c9a55-149c-4709-866c-9e3c294aa5ce/file/mp3/file.mp3	未知	0
196	Adrenaline Drive	11	364	129	https://data.freetouse.com/music/tracks/cd4bd8a0-cfc8-4834-96b5-db9d0002b1e9/file/mp3/file.mp3	未知	0
197	Echoes of the Fields	25	374	154	https://data.freetouse.com/music/tracks/59d2cd5a-01ec-4ba1-a2fd-9a6d9181438a/file/mp3/file.mp3	未知	0
198	The Sea	25	374	133	https://data.freetouse.com/music/tracks/f0fb7626-32b8-4755-b8ac-8a1d9ff023b0/file/mp3/file.mp3	未知	0
199	Dancing Glens	25	374	122	https://data.freetouse.com/music/tracks/58fb836d-c7ca-4e2a-ab99-d5b3711dbefd/file/mp3/file.mp3	未知	0
200	Chieftains Celebration	25	374	124	https://data.freetouse.com/music/tracks/896356c1-c943-4b26-a5ad-71f9893f8b9c/file/mp3/file.mp3	未知	0
201	New Age Mystery	25	374	148	https://data.freetouse.com/music/tracks/2cda4728-3e08-4668-94eb-fe07db96e0f4/file/mp3/file.mp3	未知	0
202	Bourre Waltz	25	374	124	https://data.freetouse.com/music/tracks/151dadbd-148d-47e0-9010-011c09f07968/file/mp3/file.mp3	未知	0
203	Whispers of the Harp	25	374	138	https://data.freetouse.com/music/tracks/d7c841cd-8f5b-43f1-9fc7-7cd9670b58aa/file/mp3/file.mp3	未知	0
204	After the Storm	25	374	128	https://data.freetouse.com/music/tracks/a2e8b61f-898c-4544-bb06-e016226ec9cf/file/mp3/file.mp3	未知	0
205	When Autumn Calls	1	409	166	https://data.freetouse.com/music/tracks/140fa163-6bd3-47d6-b186-bd0b7533a740/file/mp3/file.mp3	未知	0
206	Mellow Summer	7	7	167	https://data.freetouse.com/music/tracks/0c662dcc-3d0e-4f65-8738-6e02aa6f4b90/file/mp3/file.mp3	未知	0
207	Back To Life	11	364	137	https://data.freetouse.com/music/tracks/bc1097a5-e58d-4c94-98a7-64b454413776/file/mp3/file.mp3	未知	0
208	Christmas Carol	1	19	119	https://data.freetouse.com/music/tracks/4a5e0c8b-c54f-4c58-a81d-c3493eb7ebaf/file/mp3/file.mp3	未知	0
209	Far Behind	2	2	127	https://data.freetouse.com/music/tracks/50e43114-7d91-49d5-9de1-2824e14ae18f/file/mp3/file.mp3	未知	0
210	liminal	14	11	109	https://data.freetouse.com/music/tracks/a1b74ac6-298b-4a20-88b1-b6b679c544c5/file/mp3/file.mp3	未知	0
211	Sleeping Baby	13	303	125	https://data.freetouse.com/music/tracks/4e596884-3d3a-401d-83c4-7274b075c206/file/mp3/file.mp3	未知	0
212	Before Christmas	7	361	147	https://data.freetouse.com/music/tracks/72bb59b2-aedf-45f1-8087-63e5dbd1270a/file/mp3/file.mp3	未知	0
214	Flow State	5	5	140	https://data.freetouse.com/music/tracks/1634c013-53c9-4211-b65d-7e8f1ac4c4bd/file/mp3/file.mp3	未知	0
215	On a Silent Night	1	19	106	https://data.freetouse.com/music/tracks/735369d6-f999-4692-9e44-a996f53e046f/file/mp3/file.mp3	未知	0
216	Pastel Loop	7	7	144	https://data.freetouse.com/music/tracks/8152bfa5-d5ca-46e6-9c94-b18c4d227130/file/mp3/file.mp3	未知	0
217	Quiet Fields	12	317	122	https://data.freetouse.com/music/tracks/9d1180d9-bde0-493a-80ce-c7d88c41265f/file/mp3/file.mp3	未知	0
218	just call	14	11	111	https://data.freetouse.com/music/tracks/f881c61d-669e-47c8-b427-90538b7ce9b1/file/mp3/file.mp3	未知	0
219	Winter Story	7	361	127	https://data.freetouse.com/music/tracks/73b8857b-95a1-4265-a8f4-5c3fdab7c99b/file/mp3/file.mp3	未知	0
220	Where We Belong	11	387	119	https://data.freetouse.com/music/tracks/14948771-333c-4715-bb0b-1bf40a364caa/file/mp3/file.mp3	未知	0
221	Sunday	25	377	159	https://data.freetouse.com/music/tracks/48d6dc32-f8fd-418c-90ee-81d4318f57b1/file/mp3/file.mp3	未知	0
222	Happy Feet	25	377	133	https://data.freetouse.com/music/tracks/e3942d21-378f-4657-afb4-d39721a32423/file/mp3/file.mp3	未知	0
223	Coconut Kind of Love	25	377	165	https://data.freetouse.com/music/tracks/e5045748-7287-40f6-b47b-77ea12c871ab/file/mp3/file.mp3	未知	0
224	Evening Tone	7	315	184	https://data.freetouse.com/music/tracks/045a8fed-fe80-4b88-8afb-725d80383c58/file/mp3/file.mp3	未知	0
225	Playtime	25	377	159	https://data.freetouse.com/music/tracks/430fbd18-f360-4463-bf82-b514c0c4a182/file/mp3/file.mp3	未知	0
226	Rainbow	25	377	188	https://data.freetouse.com/music/tracks/12ac0635-cdd3-4a19-a28f-d5d807278052/file/mp3/file.mp3	未知	0
227	Sunshine	25	377	121	https://data.freetouse.com/music/tracks/73a9ea47-4762-4eff-a2a3-3f32783834b4/file/mp3/file.mp3	未知	0
228	School Bus	25	377	135	https://data.freetouse.com/music/tracks/24b9fe90-4745-4743-b27e-122303f52cb6/file/mp3/file.mp3	未知	0
229	Heat Is On	1	409	109	https://data.freetouse.com/music/tracks/7e9167d6-3c17-4404-ba10-a2c262909577/file/mp3/file.mp3	未知	0
230	Sneaky Spider	1	340	75	https://data.freetouse.com/music/tracks/450024bf-fa92-43df-9c71-9fa9116fd3d2/file/mp3/file.mp3	未知	0
231	stargazing	14	11	102	https://data.freetouse.com/music/tracks/eca02433-6381-4e8f-8a54-dd2bb1608695/file/mp3/file.mp3	未知	0
232	Momo Island	18	345	198	https://data.freetouse.com/music/tracks/59dcdeae-3e5a-468a-93fc-df5578f2ee9e/file/mp3/file.mp3	未知	0
233	Harlem Heat	12	381	109	https://data.freetouse.com/music/tracks/97085583-5881-4962-9e47-1a95af20c6c5/file/mp3/file.mp3	未知	0
234	Moody Weather	7	7	150	https://data.freetouse.com/music/tracks/cfdaaaca-1bf2-48a2-af99-ffe7bf067bc3/file/mp3/file.mp3	未知	0
235	Subway Reverie	21	401	218	https://data.freetouse.com/music/tracks/fc2f9bfe-9ff5-47ae-b8bb-45d601745751/file/mp3/file.mp3	未知	0
236	Innovating Care	11	316	151	https://data.freetouse.com/music/tracks/ee09388f-c072-40cc-81f7-1ff439e1c744/file/mp3/file.mp3	未知	0
237	Summer Is Gone	1	15	98	https://data.freetouse.com/music/tracks/36658629-e5a9-4909-be24-0c29ee51c8bc/file/mp3/file.mp3	未知	0
238	Greetings	25	342	111	https://data.freetouse.com/music/tracks/00685f37-9e94-402c-a6ab-0d684e7306e5/file/mp3/file.mp3	未知	0
239	Whispers of Snow	25	342	120	https://data.freetouse.com/music/tracks/7e9a7d5a-1420-40a4-82f5-4cfa76bfe8f5/file/mp3/file.mp3	未知	0
240	Christmas Eve	25	342	124	https://data.freetouse.com/music/tracks/586288c9-3f64-489a-8f2e-3d3bcb95ff46/file/mp3/file.mp3	未知	0
241	Sledding All Day	25	342	123	https://data.freetouse.com/music/tracks/caa3499a-ab0e-41f1-9b86-895882993294/file/mp3/file.mp3	未知	0
242	Vienne Carol Nights	25	342	128	https://data.freetouse.com/music/tracks/940503a7-93fe-4b8d-b577-25be56b9ff45/file/mp3/file.mp3	未知	0
243	mind blackout	14	11	99	https://data.freetouse.com/music/tracks/6b877847-a81b-48e7-8b63-8c3128bc888b/file/mp3/file.mp3	未知	0
244	until then	9	398	162	https://data.freetouse.com/music/tracks/5d7a1139-7704-41ee-aef5-f0e8010a28bf/file/mp3/file.mp3	未知	0
245	Butterflies	22	375	141	https://data.freetouse.com/music/tracks/94bcd747-8d2d-4e1e-b579-302b30636631/file/mp3/file.mp3	未知	0
246	Daydream Wind	7	7	148	https://data.freetouse.com/music/tracks/24c6f8d5-fbc6-43e7-bba4-7b1831456287/file/mp3/file.mp3	未知	0
247	Energy Overload	11	364	100	https://data.freetouse.com/music/tracks/6089a3ca-ebf4-4a7d-b829-90e624b557e9/file/mp3/file.mp3	未知	0
248	Skatepark	1	1	94	https://data.freetouse.com/music/tracks/ebe2fbb5-ce38-4931-a9af-ab0c1d7b85df/file/mp3/file.mp3	未知	0
249	Life Cycles	25	312	167	https://data.freetouse.com/music/tracks/849e7e5f-5d16-41cc-8150-a674c7c1af0a/file/mp3/file.mp3	未知	0
250	Wandering Away	25	312	178	https://data.freetouse.com/music/tracks/88a568ab-f7d4-47e1-aafb-33c50b710027/file/mp3/file.mp3	未知	0
251	Sacred Connection	25	312	211	https://data.freetouse.com/music/tracks/d36401f2-7c19-492b-b0da-c93b8d31a89c/file/mp3/file.mp3	未知	0
252	Soft Respite	25	312	201	https://data.freetouse.com/music/tracks/605fd8c7-0bc5-42bb-b2e0-c7a7b5d45fd8/file/mp3/file.mp3	未知	0
253	Journey of Life	25	312	189	https://data.freetouse.com/music/tracks/923893a3-a5cd-42a0-866e-7f131b81bd20/file/mp3/file.mp3	未知	0
254	The Hidden Civilization	25	312	179	https://data.freetouse.com/music/tracks/a5dab373-2c6a-45e8-bbbb-5d6fb8779735/file/mp3/file.mp3	未知	0
255	find the way	14	11	168	https://data.freetouse.com/music/tracks/ff743e69-0fd5-46d6-a091-6d0554e2f380/file/mp3/file.mp3	未知	0
256	Silhouette	22	375	140	https://data.freetouse.com/music/tracks/86726550-723d-402a-bf16-cf497f7f45bf/file/mp3/file.mp3	未知	0
257	Comfort Zone	2	367	142	https://data.freetouse.com/music/tracks/5ab40c06-8efd-443f-bbce-6090e8a5d2b0/file/mp3/file.mp3	未知	0
258	6PM	7	7	129	https://data.freetouse.com/music/tracks/dc6e9e50-ac77-4445-8fd6-7f8778950372/file/mp3/file.mp3	未知	0
259	The Flight	26	412	164	https://data.freetouse.com/music/tracks/da702bf5-8714-4e1e-aa70-5a6dc83ec7f5/file/mp3/file.mp3	未知	0
260	Spiritus in Me	1	20	96	https://data.freetouse.com/music/tracks/024733cf-a68a-42a8-b48e-a411d0702c28/file/mp3/file.mp3	未知	0
261	Explosive Energy	12	358	122	https://data.freetouse.com/music/tracks/fcf26ed0-b2d0-43ca-9a0b-8c6127fda0e1/file/mp3/file.mp3	未知	0
262	Fresh Groove	11	347	63	https://data.freetouse.com/music/tracks/1ed67d78-4813-4713-abc7-264479f8c0df/file/mp3/file.mp3	未知	0
263	glass house	14	11	146	https://data.freetouse.com/music/tracks/3f036e19-e318-4e6e-bd25-8a86b58f45c2/file/mp3/file.mp3	未知	0
264	Deserted	22	298	127	https://data.freetouse.com/music/tracks/4c44478c-5990-4553-a45c-b90340d19aab/file/mp3/file.mp3	未知	0
265	Countdown Waiting	13	378	130	https://data.freetouse.com/music/tracks/4f5c340e-fe96-4e42-bace-357672c8fbbf/file/mp3/file.mp3	未知	0
266	Journey to Greatness	2	367	152	https://data.freetouse.com/music/tracks/850d1f38-e89d-4360-95f2-ae16a9299159/file/mp3/file.mp3	未知	0
267	Show Yourself	26	412	170	https://data.freetouse.com/music/tracks/a8bfa2aa-b6d7-4f0c-b163-3898d5733ccd/file/mp3/file.mp3	未知	0
268	Indecision	7	7	102	https://data.freetouse.com/music/tracks/d33a07dd-85f4-4ef3-97b1-12749b2920a6/file/mp3/file.mp3	未知	0
270	Desert Road	1	1	117	https://data.freetouse.com/music/tracks/1f9bd3be-3948-4c0c-b8ca-31326db5f357/file/mp3/file.mp3	未知	0
271	Rhythm Reactor	25	377	101	https://data.freetouse.com/music/tracks/ebb60d36-0a77-4208-8616-b9016807ea5a/file/mp3/file.mp3	未知	0
272	Chain Reaction	25	377	95	https://data.freetouse.com/music/tracks/10aa6c0a-9ca9-45a2-b7af-7d8106126e05/file/mp3/file.mp3	未知	0
273	Edge of Motion	25	377	94	https://data.freetouse.com/music/tracks/382cf1f0-4942-4ed7-b2b1-64859348bb3a/file/mp3/file.mp3	未知	0
274	Snap Crackle	25	377	90	https://data.freetouse.com/music/tracks/17e30401-c53b-455a-abcd-2d3a185da5e0/file/mp3/file.mp3	未知	0
276	Rush Factor	25	377	93	https://data.freetouse.com/music/tracks/9bb9e170-8e47-4f86-9039-d610c0744ccd/file/mp3/file.mp3	未知	0
277	absence	14	11	106	https://data.freetouse.com/music/tracks/8c0f7ac2-8a26-49c4-8c65-1f9c9aff3d57/file/mp3/file.mp3	未知	0
278	Rhythm Storm	11	347	64	https://data.freetouse.com/music/tracks/85b8df51-af44-4502-989d-aa564e5d6f72/file/mp3/file.mp3	未知	0
279	Rise Up	26	412	121	https://data.freetouse.com/music/tracks/d1fda10e-0a68-408c-8708-cf1336aa5aaf/file/mp3/file.mp3	未知	0
281	The Feeling	27	363	184	https://data.freetouse.com/music/tracks/db6d6c5a-2709-449b-8e89-4cad77545d07/file/mp3/file.mp3	未知	0
282	Wastelands	1	311	166	https://data.freetouse.com/music/tracks/c1f6a5c1-e0b5-41ed-9e54-b0416767bfb8/file/mp3/file.mp3	未知	0
283	Haunted House	25	342	141	https://data.freetouse.com/music/tracks/d3da0409-9a6b-4568-a3e9-f6f527125951/file/mp3/file.mp3	未知	0
284	Spooky Dance	25	342	128	https://data.freetouse.com/music/tracks/5289424c-166a-4d4d-9034-29574843d792/file/mp3/file.mp3	未知	0
285	Graveyard Waltz	25	342	146	https://data.freetouse.com/music/tracks/e3c2bce7-a208-480e-8c55-78c44c97da27/file/mp3/file.mp3	未知	0
286	Clowns	25	342	124	https://data.freetouse.com/music/tracks/cd2394a6-e4d4-4fae-8fa9-c375509950a6/file/mp3/file.mp3	未知	0
287	i never knew her	14	11	86	https://data.freetouse.com/music/tracks/cf352229-59cf-46b3-a1ce-5ed70e7272c2/file/mp3/file.mp3	未知	0
288	Trick or Treat	25	342	140	https://data.freetouse.com/music/tracks/8064abb7-770b-4007-8330-81ace3690901/file/mp3/file.mp3	未知	0
289	Brazilian Hype	13	21	114	https://data.freetouse.com/music/tracks/494a2a2a-6afe-4a3d-831c-4026eda92bdf/file/mp3/file.mp3	未知	0
290	Sparkling	12	16	139	https://data.freetouse.com/music/tracks/ea3f036a-d903-436c-8575-1ae3de4a2a53/file/mp3/file.mp3	未知	0
291	Power of Nature	26	412	156	https://data.freetouse.com/music/tracks/4dd25142-a233-4d88-b8b5-e474d391ac02/file/mp3/file.mp3	未知	0
292	Spicey	1	409	84	https://data.freetouse.com/music/tracks/756cc478-7db2-4f78-955b-7858c09e4ecc/file/mp3/file.mp3	未知	0
293	Future Outlook	2	367	149	https://data.freetouse.com/music/tracks/33c3ea55-b8e2-4576-8806-a4f610eb6e78/file/mp3/file.mp3	未知	0
294	winter morning	14	11	101	https://data.freetouse.com/music/tracks/f10263a9-0f25-4f27-aa7a-f14c6e715ee8/file/mp3/file.mp3	未知	0
295	Another Try	26	412	151	https://data.freetouse.com/music/tracks/6bf5078a-7369-4ed1-8ba3-bb5c315bac41/file/mp3/file.mp3	未知	0
296	Reflection	1	311	155	https://data.freetouse.com/music/tracks/82ec5770-dab1-4eb7-ac9e-3dd67a7ef555/file/mp3/file.mp3	未知	0
297	Inspirational Elegance	2	367	142	https://data.freetouse.com/music/tracks/b177712e-6f1c-4af8-acd0-3fede022a9c1/file/mp3/file.mp3	未知	0
298	Nowhere To Go	26	379	217	https://data.freetouse.com/music/tracks/f174a482-b8d2-4440-8e30-3c6f275e9c1e/file/mp3/file.mp3	未知	0
299	Aeternum	1	340	149	https://data.freetouse.com/music/tracks/4d40a801-c593-4a07-b855-61a612d992f0/file/mp3/file.mp3	未知	0
300	1984	5	5	187	https://data.freetouse.com/music/tracks/776ee96a-977e-4210-ad84-285f5eca6a26/file/mp3/file.mp3	未知	0
301	Dirty Streets	12	330	107	https://data.freetouse.com/music/tracks/78fc8912-8f31-4531-a633-c41c3a87dfcd/file/mp3/file.mp3	未知	0
302	Skyscrapers	2	367	139	https://data.freetouse.com/music/tracks/3a19f305-1026-4ba3-8a29-1d55cb9c3ef0/file/mp3/file.mp3	未知	0
303	Motivation	26	412	77	https://data.freetouse.com/music/tracks/b04991a0-565f-41ce-8d19-55e68c239581/file/mp3/file.mp3	未知	0
305	moonlit	9	398	170	https://data.freetouse.com/music/tracks/5b515798-1d49-4c3d-9783-d7a2a78b5781/file/mp3/file.mp3	未知	0
306	Trespass	5	5	144	https://data.freetouse.com/music/tracks/eeb53ec2-a9fa-4148-9c78-1552f0523f18/file/mp3/file.mp3	未知	0
307	The Dead Man's March	12	355	113	https://data.freetouse.com/music/tracks/11bb4771-aeff-4588-95b3-c03b541ae874/file/mp3/file.mp3	未知	0
308	Hero	26	412	205	https://data.freetouse.com/music/tracks/fa31b4ab-e872-47cb-8771-a0a900381f48/file/mp3/file.mp3	未知	0
309	Beautiful Ideas	2	367	139	https://data.freetouse.com/music/tracks/78f7dd67-0326-403d-8762-f4e41f5f77ad/file/mp3/file.mp3	未知	0
310	Rotten Bones	1	1	258	https://data.freetouse.com/music/tracks/220f9481-554f-4344-a82b-3c670667ed92/file/mp3/file.mp3	未知	0
311	Get Prepared	26	379	163	https://data.freetouse.com/music/tracks/d16c7dd4-3a69-4953-bb21-f057693d615e/file/mp3/file.mp3	未知	0
312	Responsibility	1	1	143	https://data.freetouse.com/music/tracks/0b8d6cc9-041a-45ed-91c4-3681fa8b3f45/file/mp3/file.mp3	未知	0
313	Tech Reflections	2	367	141	https://data.freetouse.com/music/tracks/b7fb2ba9-75a4-4214-909b-20c4a4d8f5bd/file/mp3/file.mp3	未知	0
314	Feel The Storm	26	357	98	https://data.freetouse.com/music/tracks/8de1b585-bdbb-48b7-8fcf-6b6381c7dc9b/file/mp3/file.mp3	未知	0
315	Berlin Nights	1	22	100	https://data.freetouse.com/music/tracks/0449a098-c4e1-4c20-8e69-feba387cdd92/file/mp3/file.mp3	未知	0
316	Good Times	22	298	113	https://data.freetouse.com/music/tracks/e0a61c45-ac6c-4342-992b-7e1ee2ca0b4f/file/mp3/file.mp3	未知	0
317	Achievement	2	367	127	https://data.freetouse.com/music/tracks/57c0d631-d558-4754-aa2d-7253d7d18edf/file/mp3/file.mp3	未知	0
318	Win The Battle	26	379	122	https://data.freetouse.com/music/tracks/0052cf96-d222-4818-909f-2b1daf4fe080/file/mp3/file.mp3	未知	0
319	Old World	1	340	82	https://data.freetouse.com/music/tracks/b282d18d-bda6-412c-ac24-5c79ebd871a4/file/mp3/file.mp3	未知	0
320	Pause the World	19	385	157	https://data.freetouse.com/music/tracks/df3ba4b6-e23b-4eb9-9f50-1faafe7a4ef3/file/mp3/file.mp3	未知	0
321	Two Days	22	298	128	https://data.freetouse.com/music/tracks/0f889389-5b3a-4bcf-ac9f-1826758fd574/file/mp3/file.mp3	未知	0
322	Fire of the Orient	1	1	103	https://data.freetouse.com/music/tracks/1577455b-f2a7-4ee5-bace-1ad67b504da9/file/mp3/file.mp3	未知	0
323	Lets Talk	22	298	121	https://data.freetouse.com/music/tracks/fcd792bb-731e-4318-a34e-6d4c30136e41/file/mp3/file.mp3	未知	0
324	Robotnik	1	311	107	https://data.freetouse.com/music/tracks/c373adbb-37c8-4d52-9837-0e53e992177d/file/mp3/file.mp3	未知	0
326	Watching the Waves	7	7	174	https://data.freetouse.com/music/tracks/5673169d-c8b1-42dc-8378-713706ef57f1/file/mp3/file.mp3	未知	0
327	Apache Flute	13	331	150	https://data.freetouse.com/music/tracks/6dd01b02-95cc-427d-99e4-db5d54a4b129/file/mp3/file.mp3	未知	0
328	Know Me	22	298	161	https://data.freetouse.com/music/tracks/813c7a4d-093f-41ac-9d8a-015e4963bf97/file/mp3/file.mp3	未知	0
330	Feeling Good	23	326	111	https://data.freetouse.com/music/tracks/5fe9a901-c7b7-4735-a8b8-51cb564d78e0/file/mp3/file.mp3	未知	0
331	Eternity	8	289	350	https://data.freetouse.com/music/tracks/48466995-d790-4bed-97f9-cfbff9558673/file/mp3/file.mp3	未知	0
332	sable	9	344	168	https://data.freetouse.com/music/tracks/b84080cc-801e-46c8-94de-6ad02cae37d9/file/mp3/file.mp3	未知	0
333	Slide Away	22	298	142	https://data.freetouse.com/music/tracks/0460ee7d-8335-4def-9c3d-ffb561a7d0e9/file/mp3/file.mp3	未知	0
334	Limit	1	1	230	https://data.freetouse.com/music/tracks/f95388fb-e64d-4397-9afb-e03b542dda38/file/mp3/file.mp3	未知	0
336	Digital Mayham	8	320	177	https://data.freetouse.com/music/tracks/20b13b5e-6f19-4b38-8b1e-f5780ccb4e04/file/mp3/file.mp3	未知	0
337	Mountains	1	393	114	https://data.freetouse.com/music/tracks/65b5fa6c-14e8-4e02-ad1d-cc9c192a826b/file/mp3/file.mp3	未知	0
338	Out & About	22	298	131	https://data.freetouse.com/music/tracks/7e3ceb65-8144-4d6b-9e07-0381969545ed/file/mp3/file.mp3	未知	0
339	Classic Rock	8	366	188	https://data.freetouse.com/music/tracks/c23eafeb-03e4-461b-983a-7f8795c0ef33/file/mp3/file.mp3	未知	0
340	Bomb	1	311	145	https://data.freetouse.com/music/tracks/99984a9b-d4d0-4441-9ab4-75cd43a5c51e/file/mp3/file.mp3	未知	0
341	Moving On	28	369	159	https://data.freetouse.com/music/tracks/c1d122ca-f5de-44ae-933a-8c093b382834/file/mp3/file.mp3	未知	0
342	Never Gonna	22	298	143	https://data.freetouse.com/music/tracks/490acc74-0b1f-45fc-b7b7-ee0cfe4d2266/file/mp3/file.mp3	未知	0
343	Waveform Love	23	389	100	https://data.freetouse.com/music/tracks/50345b7f-ccf9-483d-b934-67474a250b4c/file/mp3/file.mp3	未知	0
344	Forgiveness	1	14	126	https://data.freetouse.com/music/tracks/8b74f758-1eff-4655-ad28-cc2e6632aad6/file/mp3/file.mp3	未知	0
345	dainty	9	344	161	https://data.freetouse.com/music/tracks/8c14a3db-7e5d-442f-9b71-2f3e391b2e35/file/mp3/file.mp3	未知	0
346	Ascension	10	382	165	https://data.freetouse.com/music/tracks/0b71b10c-c045-4604-8952-007233424059/file/mp3/file.mp3	未知	0
347	The Island Of Haying	22	298	149	https://data.freetouse.com/music/tracks/6149aa16-f021-40d4-997e-4e91f4eceadd/file/mp3/file.mp3	未知	0
348	Imbolc	1	15	128	https://data.freetouse.com/music/tracks/078f64cf-bc7b-4e54-a3c2-e66fba21547c/file/mp3/file.mp3	未知	0
349	Research Station	29	299	168	https://data.freetouse.com/music/tracks/577e7429-ff1c-4b62-a2e9-397ce14c4791/file/mp3/file.mp3	未知	0
350	Fly With Me	22	375	126	https://data.freetouse.com/music/tracks/f9ed5409-c0c0-4a64-944a-b1d800c14518/file/mp3/file.mp3	未知	0
351	Dark Star	1	311	96	https://data.freetouse.com/music/tracks/c27126c2-4e78-4c01-809b-14a7068696d3/file/mp3/file.mp3	未知	0
352	falling	9	398	161	https://data.freetouse.com/music/tracks/52970478-61e2-41bc-8dee-3e1a3db9d3ae/file/mp3/file.mp3	未知	0
353	Above It All	22	298	153	https://data.freetouse.com/music/tracks/e419aa54-7263-4d5e-9f17-00bd7c4c2ec3/file/mp3/file.mp3	未知	0
354	Rolling	5	5	160	https://data.freetouse.com/music/tracks/0701e4b6-fd97-4568-8228-654decf85265/file/mp3/file.mp3	未知	0
355	Sakura	1	14	123	https://data.freetouse.com/music/tracks/de2c05f5-e646-479c-aaff-76f2b3ecafbb/file/mp3/file.mp3	未知	0
356	Vintage Posters	21	404	252	https://data.freetouse.com/music/tracks/b011b4b8-26d4-4166-ab96-99412aaaa20c/file/mp3/file.mp3	未知	0
357	Poolside	22	298	143	https://data.freetouse.com/music/tracks/2da8bdcc-6f86-41c0-8330-c7c055a50daf/file/mp3/file.mp3	未知	0
358	Desert Blaze	5	5	201	https://data.freetouse.com/music/tracks/575e0cc3-2fa0-4270-82d7-8d84ae4f4aaa/file/mp3/file.mp3	未知	0
360	Soulmates	12	16	184	https://data.freetouse.com/music/tracks/82486846-2d06-4f7c-a822-985b1bd3c27b/file/mp3/file.mp3	未知	0
361	Green Leaves	22	375	141	https://data.freetouse.com/music/tracks/9f935c23-34a5-49ec-bc15-895161379cb7/file/mp3/file.mp3	未知	0
362	Falling Into You	7	315	166	https://data.freetouse.com/music/tracks/5a20ebdb-6943-4e92-bdbf-67ba8188ea92/file/mp3/file.mp3	未知	0
363	Temple of the Ancients	29	299	223	https://data.freetouse.com/music/tracks/11f1dc71-2b9f-47dd-8c7d-a6b0673f502c/file/mp3/file.mp3	未知	0
364	Wolf	1	413	116	https://data.freetouse.com/music/tracks/5ba54f00-a920-4661-ac8b-7a12c6efb52f/file/mp3/file.mp3	未知	0
365	Flow	22	298	117	https://data.freetouse.com/music/tracks/bc08b6d9-bbf7-4334-8b51-68d8c83ddae7/file/mp3/file.mp3	未知	0
366	Aura Power	13	392	113	https://data.freetouse.com/music/tracks/0682f6e1-da4d-42bf-910f-6e70e2b8b375/file/mp3/file.mp3	未知	0
367	Bean	30	383	143	https://data.freetouse.com/music/tracks/c501fb69-b32e-4bdb-a777-18fc0c9f4d84/file/mp3/file.mp3	未知	0
368	Flavour Tip	19	318	209	https://data.freetouse.com/music/tracks/72683521-69f2-49a7-97d7-f61aa4d9c751/file/mp3/file.mp3	未知	0
369	Octopus	1	1	126	https://data.freetouse.com/music/tracks/1a3152ef-3a31-4ffb-b78c-fb4daa34e3d7/file/mp3/file.mp3	未知	0
370	Stranded	22	298	149	https://data.freetouse.com/music/tracks/8ca27375-95f2-427c-80c5-7ee572c9551b/file/mp3/file.mp3	未知	0
372	Jamaican Rasta	13	24	153	https://data.freetouse.com/music/tracks/4ea5e5cc-92b5-4806-b9c6-02afb4b19786/file/mp3/file.mp3	未知	0
373	Silly Punks	19	318	129	https://data.freetouse.com/music/tracks/0eadc9f3-4248-4a5e-a2e5-fb2eb0410914/file/mp3/file.mp3	未知	0
374	Green Hills	1	340	229	https://data.freetouse.com/music/tracks/27280172-a1cf-41e0-87d7-581db2697c76/file/mp3/file.mp3	未知	0
375	Belong	22	298	129	https://data.freetouse.com/music/tracks/f190447c-cb77-4949-9739-f39d20417f0b/file/mp3/file.mp3	未知	0
376	The Last Path	5	25	152	https://data.freetouse.com/music/tracks/29575b42-6a1e-45ca-9893-91bca2422463/file/mp3/file.mp3	未知	0
377	Way Back	1	14	110	https://data.freetouse.com/music/tracks/427e8eec-97d3-4302-baa1-567c9e90a533/file/mp3/file.mp3	未知	0
378	The Last Knight	11	387	148	https://data.freetouse.com/music/tracks/71a38f27-218b-4757-9c09-1f1fa5145156/file/mp3/file.mp3	未知	0
379	Floating	1	403	123	https://data.freetouse.com/music/tracks/6dbaeafb-f6eb-4474-8eff-64b6f7cc4f59/file/mp3/file.mp3	未知	0
380	Peace	10	382	230	https://data.freetouse.com/music/tracks/4f3a09f4-fae4-450b-94c7-ad729b38c039/file/mp3/file.mp3	未知	0
381	Saved by Brothers	11	387	153	https://data.freetouse.com/music/tracks/bbf7b06d-b98d-4eda-8bc6-81ace8d49f1b/file/mp3/file.mp3	未知	0
382	Go On	1	1	108	https://data.freetouse.com/music/tracks/f1df93c2-3ca3-4276-99f6-5131796e64fd/file/mp3/file.mp3	未知	0
383	Eclipse	10	382	190	https://data.freetouse.com/music/tracks/6cce9e10-dc2f-4691-ad57-4a98712ab48c/file/mp3/file.mp3	未知	0
384	Wild Emotions	12	13	116	https://data.freetouse.com/music/tracks/03d84fff-d35c-458d-8800-7be8091f43a8/file/mp3/file.mp3	未知	0
385	Now or Never	11	387	102	https://data.freetouse.com/music/tracks/ace2bc90-8373-4917-96d7-326db8da1a1a/file/mp3/file.mp3	未知	0
386	Infinity	1	340	186	https://data.freetouse.com/music/tracks/f5d67d15-f4ff-47a7-8b28-088ac03d9831/file/mp3/file.mp3	未知	0
387	Everglow	10	382	215	https://data.freetouse.com/music/tracks/d85703e6-cba3-414a-9b2b-63d715c74f06/file/mp3/file.mp3	未知	0
388	Lost in Time	11	387	132	https://data.freetouse.com/music/tracks/bcef766f-c7ad-424e-97d1-ef6552906814/file/mp3/file.mp3	未知	0
389	Time is Ticking	31	304	132	https://data.freetouse.com/music/tracks/119d4d43-f751-4ee3-8f5a-ad66cc4fa461/file/mp3/file.mp3	未知	0
390	To the Glowing Forest	18	297	128	https://data.freetouse.com/music/tracks/6137281b-8f3d-47aa-80f2-69cf0df3f695/file/mp3/file.mp3	未知	0
391	Winery	11	350	117	https://data.freetouse.com/music/tracks/4aeb6c42-c8f9-435f-a6dc-19cb94b79b82/file/mp3/file.mp3	未知	0
392	Triumph	31	304	145	https://data.freetouse.com/music/tracks/20c203f1-7ba1-4d4b-8bc1-9ea0c33855c5/file/mp3/file.mp3	未知	0
393	White Mountains	1	1	208	https://data.freetouse.com/music/tracks/53cd2a1d-e272-4706-883c-5ff7562b3de3/file/mp3/file.mp3	未知	0
394	Agitation	32	308	170	https://data.freetouse.com/music/tracks/c9c32907-4902-4ff1-b693-60a559aad73d/file/mp3/file.mp3	未知	0
395	True	22	319	94	https://data.freetouse.com/music/tracks/47ff415e-f8a4-430e-846a-e284d84db04b/file/mp3/file.mp3	未知	0
396	Market	31	304	126	https://data.freetouse.com/music/tracks/7128d9d8-b74d-4c48-90c6-f0d6bfc76730/file/mp3/file.mp3	未知	0
397	Tension Rising	11	387	124	https://data.freetouse.com/music/tracks/83dbb241-eee2-4e4d-b856-c1d2dcb0f072/file/mp3/file.mp3	未知	0
398	Monday Mood	2	367	148	https://data.freetouse.com/music/tracks/916ac437-daab-4855-8bdb-092c36ee05b7/file/mp3/file.mp3	未知	0
399	Genesis One	29	299	150	https://data.freetouse.com/music/tracks/e7fe3f9d-cef8-4f25-be78-daab662d701f/file/mp3/file.mp3	未知	0
400	1984	1	409	100	https://data.freetouse.com/music/tracks/402d67cc-f450-4cab-9252-2bd871abf72f/file/mp3/file.mp3	未知	0
401	The Silver Grail	31	304	90	https://data.freetouse.com/music/tracks/85064963-0da3-4778-bae4-0e2deac9e055/file/mp3/file.mp3	未知	0
402	Pinnacle	10	382	137	https://data.freetouse.com/music/tracks/59208d5b-3a45-4944-8b84-6d0944c3599f/file/mp3/file.mp3	未知	0
403	Sunset	7	315	141	https://data.freetouse.com/music/tracks/51d52c1c-a3b3-4397-8554-075dc3ca7834/file/mp3/file.mp3	未知	0
404	bonsai	9	398	134	https://data.freetouse.com/music/tracks/42a132c4-9042-432b-8b8b-4f41647684f2/file/mp3/file.mp3	未知	0
405	Skyline Vibes	11	316	169	https://data.freetouse.com/music/tracks/561d1b87-447e-404a-b7e3-ba725d1ff29d/file/mp3/file.mp3	未知	0
406	Sunshine	22	296	123	https://data.freetouse.com/music/tracks/9404f7a9-b951-4c5e-accf-f01a0894dcc0/file/mp3/file.mp3	未知	0
407	Adventure	31	304	171	https://data.freetouse.com/music/tracks/e4328fb3-19d5-42e0-9d51-70ebd9fe8284/file/mp3/file.mp3	未知	0
409	Jester Dance	31	304	110	https://data.freetouse.com/music/tracks/2fe1ed90-030d-4797-95b0-bacdd26fef9c/file/mp3/file.mp3	未知	0
410	Clean Sheet	7	315	147	https://data.freetouse.com/music/tracks/829bd6b8-9122-4809-9642-35bcfd409d3d/file/mp3/file.mp3	未知	0
411	Legends Never Fall	11	387	145	https://data.freetouse.com/music/tracks/963a80a8-fdbc-45d1-99a1-86c8215d5db3/file/mp3/file.mp3	未知	0
412	Dark Heart	13	391	109	https://data.freetouse.com/music/tracks/7ed51474-87e9-4383-9b1b-3fa34c608a97/file/mp3/file.mp3	未知	0
413	Hope	33	307	104	https://data.freetouse.com/music/tracks/35548325-1409-4190-93dd-7d99194d13a4/file/mp3/file.mp3	未知	0
414	Windswept	1	322	118	https://data.freetouse.com/music/tracks/b7abdbdc-29a2-4456-b96f-300a7dd52d67/file/mp3/file.mp3	未知	0
415	Voyage	10	382	160	https://data.freetouse.com/music/tracks/3dfef496-9df7-4ce2-bd05-4acc8181a1ed/file/mp3/file.mp3	未知	0
417	We Are	22	368	122	https://data.freetouse.com/music/tracks/d495589f-33f7-4aaf-88f3-a226992598ce/file/mp3/file.mp3	未知	0
418	Digital Soul	5	5	138	https://data.freetouse.com/music/tracks/675d4812-cc10-4a8f-a8f5-a6756a9ef54a/file/mp3/file.mp3	未知	0
420	Dusty Rocks	12	358	106	https://data.freetouse.com/music/tracks/b29266f0-3d53-4d82-8148-bc1d3cc0e882/file/mp3/file.mp3	未知	0
421	Cascade	10	382	141	https://data.freetouse.com/music/tracks/db90eea6-9f01-46a4-ad27-4b7c4b671136/file/mp3/file.mp3	未知	0
422	Forgiveness	33	307	169	https://data.freetouse.com/music/tracks/59916b94-aad7-4f94-a1e3-69f5d356d1a2/file/mp3/file.mp3	未知	0
423	Digital Flow	2	367	125	https://data.freetouse.com/music/tracks/9c93d1b7-d4bd-488c-a40c-a51db8eb0538/file/mp3/file.mp3	未知	0
424	Wavy Strut	19	365	145	https://data.freetouse.com/music/tracks/a0753b45-0b29-4112-a644-3f91facf0fbb/file/mp3/file.mp3	未知	0
425	Canopy Rain	34	323	158	https://data.freetouse.com/music/tracks/c040f228-7b5d-417f-9b26-ba2fb06e03b7/file/mp3/file.mp3	未知	0
426	Slow and Sweet	12	414	131	https://data.freetouse.com/music/tracks/2f19165c-a9ae-4a1e-ab49-1aee42b115e4/file/mp3/file.mp3	未知	0
427	Endless	22	375	159	https://data.freetouse.com/music/tracks/92db18a7-6935-4892-87c6-7b40287393fd/file/mp3/file.mp3	未知	0
428	Touch the Sky	7	315	124	https://data.freetouse.com/music/tracks/7015c4b4-d837-4b04-86dc-48f342411170/file/mp3/file.mp3	未知	0
429	Burning Castles	31	304	127	https://data.freetouse.com/music/tracks/e5b8b61f-e859-4f9e-b1d3-e523561c0aa8/file/mp3/file.mp3	未知	0
430	Horizons	10	382	140	https://data.freetouse.com/music/tracks/564314ce-e1f4-47c6-a767-873b6b0c5eb4/file/mp3/file.mp3	未知	0
431	Fallen	33	307	132	https://data.freetouse.com/music/tracks/94f9bbb4-83a6-4af8-a169-602e78c5b04c/file/mp3/file.mp3	未知	0
432	Sexy Touch	12	414	126	https://data.freetouse.com/music/tracks/39a7e116-785c-4b46-809e-de2b3f1323d5/file/mp3/file.mp3	未知	0
433	Flow State	35	395	154	https://data.freetouse.com/music/tracks/5dd3b97b-ac7c-418c-a362-5994c440f57f/file/mp3/file.mp3	未知	0
435	Fun Time	1	22	113	https://data.freetouse.com/music/tracks/5f3d4364-5685-4807-9199-fbcfe1293ac3/file/mp3/file.mp3	未知	0
437	Infinity	10	380	197	https://data.freetouse.com/music/tracks/3688ac7b-608f-44e6-a95e-8d021d336f36/file/mp3/file.mp3	未知	0
438	Archipelago	36	406	188	https://data.freetouse.com/music/tracks/ad28d4f4-db5f-42d5-af59-462a343df611/file/mp3/file.mp3	未知	0
439	Park Vibes	34	323	149	https://data.freetouse.com/music/tracks/2e078088-4b84-4d57-a3b3-7d7c8057750b/file/mp3/file.mp3	未知	0
440	Frisbee	5	5	150	https://data.freetouse.com/music/tracks/ab97c2c7-6a68-4b04-8d2d-12fe6cb4ce38/file/mp3/file.mp3	未知	0
441	Folk Story	12	414	135	https://data.freetouse.com/music/tracks/ebb8c711-0ca5-4efc-93ef-bd7a6a927848/file/mp3/file.mp3	未知	0
442	Bohemo Island	22	375	133	https://data.freetouse.com/music/tracks/276c1e3d-7e82-482d-ac3a-82b95746ac8e/file/mp3/file.mp3	未知	0
443	Evening Night	37	407	124	https://data.freetouse.com/music/tracks/03fd541e-408b-43ec-8364-e5f03c2202fe/file/mp3/file.mp3	未知	0
444	A Better Future	2	367	142	https://data.freetouse.com/music/tracks/ba2e6f83-a241-49c6-9a06-929cd581669e/file/mp3/file.mp3	未知	0
445	Final Scene	13	346	138	https://data.freetouse.com/music/tracks/a465ae94-35d2-4a55-b5a4-de7b9acdf1e3/file/mp3/file.mp3	未知	0
446	Warriors	8	320	127	https://data.freetouse.com/music/tracks/98175c61-4579-43aa-8174-6da02e9c573b/file/mp3/file.mp3	未知	0
447	Village	8	320	137	https://data.freetouse.com/music/tracks/3682e674-7b11-4741-89c7-a4ee36021bcf/file/mp3/file.mp3	未知	0
448	Breton	8	320	137	https://data.freetouse.com/music/tracks/0e16f7c8-2011-4a43-864f-8755fe657080/file/mp3/file.mp3	未知	0
449	In Flight	10	382	176	https://data.freetouse.com/music/tracks/f7f4e88b-64e9-47c8-a842-0933c0dea39d/file/mp3/file.mp3	未知	0
452	Iluvena	22	375	123	https://data.freetouse.com/music/tracks/b15d706e-2bc0-461d-8f9d-f3764b2a0e4d/file/mp3/file.mp3	未知	0
453	Metropolitan	12	414	101	https://data.freetouse.com/music/tracks/a5e891e6-72a6-4c63-9e28-1de9cd655784/file/mp3/file.mp3	未知	0
454	Chill Walk	7	315	124	https://data.freetouse.com/music/tracks/c968c541-c132-45bd-98aa-f0c6138b1bb5/file/mp3/file.mp3	未知	0
455	Bye Bye	37	407	167	https://data.freetouse.com/music/tracks/1a6081da-82e0-459c-9cf1-19efea83093b/file/mp3/file.mp3	未知	0
456	Echoes of Aurora	29	299	357	https://data.freetouse.com/music/tracks/f5581d63-8413-4a1b-a3cf-329a89255309/file/mp3/file.mp3	未知	0
457	Sky Mall	21	401	222	https://data.freetouse.com/music/tracks/7f688caa-fb77-4b7a-b8b9-f24ed061a178/file/mp3/file.mp3	未知	0
458	Dragon Kingdom	13	392	147	https://data.freetouse.com/music/tracks/368e3f43-6650-42a8-94aa-fdbf1eabaa0c/file/mp3/file.mp3	未知	0
459	Mistaken	22	397	139	https://data.freetouse.com/music/tracks/11f67086-33bd-4c48-be22-e9190b445f10/file/mp3/file.mp3	未知	0
460	Blue Skies	10	382	272	https://data.freetouse.com/music/tracks/345e16e3-1043-4bc2-9c70-38be53f5ff9e/file/mp3/file.mp3	未知	0
461	Irish Waltz	8	320	167	https://data.freetouse.com/music/tracks/d0b5709d-946d-4fcf-aace-b3328a997fd8/file/mp3/file.mp3	未知	0
462	Wall Of Sound	12	414	98	https://data.freetouse.com/music/tracks/c7883508-aab4-4fbe-9729-f0345779bfdc/file/mp3/file.mp3	未知	0
463	Keep Dreaming	37	407	133	https://data.freetouse.com/music/tracks/294772e0-adcb-45fe-9d67-c655c3e5197c/file/mp3/file.mp3	未知	0
464	Born to Win	11	364	125	https://data.freetouse.com/music/tracks/96beb7fd-9ab3-4d62-8d15-3c65ad012fea/file/mp3/file.mp3	未知	0
465	Try Me	22	397	133	https://data.freetouse.com/music/tracks/7d428dbf-05a9-4b9b-aeab-c1cd4930aab5/file/mp3/file.mp3	未知	0
466	Lost Somewhere	1	311	184	https://data.freetouse.com/music/tracks/02d59b2e-8503-4f29-b9a8-15aba348f69a/file/mp3/file.mp3	未知	0
467	Nostalgia Gaming	13	392	125	https://data.freetouse.com/music/tracks/5b3ccfcd-8736-4a7c-a8bc-d67e1ad1eb99/file/mp3/file.mp3	未知	0
468	Spheres	10	382	185	https://data.freetouse.com/music/tracks/8c777df2-aa9a-4f9b-8896-30ec009ed020/file/mp3/file.mp3	未知	0
469	Listen To My Heartbeat	12	414	146	https://data.freetouse.com/music/tracks/aff41c70-2343-4a3e-b0ff-68098c322a3a/file/mp3/file.mp3	未知	0
470	Legend	8	320	138	https://data.freetouse.com/music/tracks/50fd1938-d216-482f-9090-43ed1374c279/file/mp3/file.mp3	未知	0
471	Leader	1	311	96	https://data.freetouse.com/music/tracks/25c3d700-eb1f-4383-87a0-bd1d0c99ae71/file/mp3/file.mp3	未知	0
472	Survival Mode	37	407	231	https://data.freetouse.com/music/tracks/44749d67-bfa3-413f-9490-a2b99f078c52/file/mp3/file.mp3	未知	0
473	Sky With Yellow Spots	39	337	99	https://data.freetouse.com/music/tracks/ca8d164a-f930-4029-b2cc-2d794a330afc/file/mp3/file.mp3	未知	0
474	Talking with the Bird	39	337	143	https://data.freetouse.com/music/tracks/0c4c1ebb-3b87-45d4-bfa6-ee19e8d23c81/file/mp3/file.mp3	未知	0
475	Home	39	337	144	https://data.freetouse.com/music/tracks/7777df28-6a8b-4505-9d0b-7498c32558dc/file/mp3/file.mp3	未知	0
476	Moving Mountains	39	337	139	https://data.freetouse.com/music/tracks/d419b28c-d48d-4c92-8e4f-a2727e8be661/file/mp3/file.mp3	未知	0
477	The Beauty Spreads its Wings	39	337	153	https://data.freetouse.com/music/tracks/cf4c4633-31d2-43a1-96c0-c7a9dbddb69d/file/mp3/file.mp3	未知	0
478	Chamomile Waltz	39	337	131	https://data.freetouse.com/music/tracks/f8977a67-783b-4e7e-b986-87fdae1a17fb/file/mp3/file.mp3	未知	0
479	Evening at the Tram Station	39	337	161	https://data.freetouse.com/music/tracks/51163c96-b10d-4de0-808a-214f8894d464/file/mp3/file.mp3	未知	0
480	Galaxy in Your Eyes	39	337	139	https://data.freetouse.com/music/tracks/be8ceb31-db5f-41f6-bf21-e64518cc9833/file/mp3/file.mp3	未知	0
481	Lavender Waltz	39	337	137	https://data.freetouse.com/music/tracks/20752c38-5ab8-438a-a580-8ab0cca92f0d/file/mp3/file.mp3	未知	0
482	The Day We Met	39	337	124	https://data.freetouse.com/music/tracks/53748d6d-5c7d-4396-9b13-2ade0c3bedcf/file/mp3/file.mp3	未知	0
483	Blueberry Waltz	39	337	122	https://data.freetouse.com/music/tracks/254c4830-0b41-44ef-8abc-e85de9746967/file/mp3/file.mp3	未知	0
484	Heart & Soul	39	337	136	https://data.freetouse.com/music/tracks/10839e9e-b4ba-4f9f-8ce9-513f66bc9851/file/mp3/file.mp3	未知	0
485	Andromeda	39	337	113	https://data.freetouse.com/music/tracks/8a5520e1-e5d1-41c1-a1cb-19bdc74fefd1/file/mp3/file.mp3	未知	0
486	Deja Vu	39	337	141	https://data.freetouse.com/music/tracks/427181eb-a1a4-4983-bde3-9d08abb7f768/file/mp3/file.mp3	未知	0
487	The Wheel	39	337	144	https://data.freetouse.com/music/tracks/3e1729a1-2e56-4077-b92b-669068dd062a/file/mp3/file.mp3	未知	0
488	Upon the Waves	39	337	112	https://data.freetouse.com/music/tracks/497449c8-0959-4d98-ae39-072002c9d78a/file/mp3/file.mp3	未知	0
489	Lullaby for Elizabeth	39	337	142	https://data.freetouse.com/music/tracks/af7608e7-4cf3-4900-a122-275807b8f814/file/mp3/file.mp3	未知	0
490	Crystal Waltz	39	337	111	https://data.freetouse.com/music/tracks/8617ec3a-0411-4517-8eb1-0da8cc6b773d/file/mp3/file.mp3	未知	0
491	Find a Path	39	337	100	https://data.freetouse.com/music/tracks/84f5b722-7706-4d24-9047-6c6d7dd7eb44/file/mp3/file.mp3	未知	0
492	Paris Chanson	13	392	147	https://data.freetouse.com/music/tracks/62475893-5b5a-4f9e-9198-ad33fb417a3c/file/mp3/file.mp3	未知	0
493	Falling Into Infinity	11	387	156	https://data.freetouse.com/music/tracks/18f601c0-aa30-463e-8bc7-13c1bffef1f4/file/mp3/file.mp3	未知	0
494	Sonnea	22	397	113	https://data.freetouse.com/music/tracks/af7aa6e4-899f-4b4b-aae2-532d01e5a357/file/mp3/file.mp3	未知	0
495	Stranger at Night	1	311	126	https://data.freetouse.com/music/tracks/4c92b233-71ba-4977-a1a8-3bdb51ebe480/file/mp3/file.mp3	未知	0
496	Lineage	10	382	186	https://data.freetouse.com/music/tracks/1189406e-8ad5-4c43-88d5-8915844543c5/file/mp3/file.mp3	未知	0
497	Ya'll Don't Know	37	407	148	https://data.freetouse.com/music/tracks/8d34dcd5-5a8c-4e24-9112-ae20cf2b1069/file/mp3/file.mp3	未知	0
498	Into The Future	12	414	133	https://data.freetouse.com/music/tracks/4863c7fc-b3c3-4bbf-93be-baec4574296d/file/mp3/file.mp3	未知	0
499	Passion	40	306	163	https://data.freetouse.com/music/tracks/146997b7-0961-4534-b37f-caf53c474b5b/file/mp3/file.mp3	未知	0
500	Heritage	8	320	133	https://data.freetouse.com/music/tracks/ed84638f-99a6-4705-986e-f6bd72405f2c/file/mp3/file.mp3	未知	0
501	Peaceful	8	320	134	https://data.freetouse.com/music/tracks/60c8c360-e0cb-4b6e-a031-dab16392dbb1/file/mp3/file.mp3	未知	0
502	Imperator	1	311	124	https://data.freetouse.com/music/tracks/a512c034-4462-47fb-ac35-b1dd5c2d7e4a/file/mp3/file.mp3	未知	0
503	Air	8	320	122	https://data.freetouse.com/music/tracks/e55127ec-5ef9-4955-a8df-412499649a07/file/mp3/file.mp3	未知	0
504	Ballad	8	320	128	https://data.freetouse.com/music/tracks/8fcb7e28-5643-4c5b-9864-bf65a9192bf6/file/mp3/file.mp3	未知	0
505	Metronome	22	397	129	https://data.freetouse.com/music/tracks/c8bc1b51-c628-43cf-90b8-c3094969dbb0/file/mp3/file.mp3	未知	0
506	Folk Dance	13	392	127	https://data.freetouse.com/music/tracks/7f8a3a49-2136-4482-a39d-3ff99212c391/file/mp3/file.mp3	未知	0
507	Once Upon A Time	35	309	124	https://data.freetouse.com/music/tracks/28cadb26-e481-4dc8-b946-63286b871586/file/mp3/file.mp3	未知	0
508	Blue Skies	1	311	171	https://data.freetouse.com/music/tracks/c22bbc87-0b35-49ce-a0ac-c4c416b8b446/file/mp3/file.mp3	未知	0
509	Every Thang Shakin	37	407	111	https://data.freetouse.com/music/tracks/a9f0af2e-360b-4486-8342-36cad83c52ab/file/mp3/file.mp3	未知	0
510	Freedom Bike	12	414	128	https://data.freetouse.com/music/tracks/03bed188-82cc-46bb-9f93-0ba477e9df70/file/mp3/file.mp3	未知	0
511	Moments	22	397	128	https://data.freetouse.com/music/tracks/5d3381df-a6d7-4221-a106-57d1bd6b1435/file/mp3/file.mp3	未知	0
512	River Flows	36	294	162	https://data.freetouse.com/music/tracks/155d3323-8324-4541-9b9d-4f71c41fe8a5/file/mp3/file.mp3	未知	0
513	Beautiful Day	1	311	208	https://data.freetouse.com/music/tracks/c4a88b2d-a672-4715-ab08-c0c1df8caef9/file/mp3/file.mp3	未知	0
514	Pyramid Secrets	13	392	128	https://data.freetouse.com/music/tracks/94ab114d-2992-47fc-8742-3256ad36b674/file/mp3/file.mp3	未知	0
515	Trip Out	37	407	183	https://data.freetouse.com/music/tracks/ba4c5fa5-784c-449e-8398-99a544b57081/file/mp3/file.mp3	未知	0
516	Follow The Light	32	362	135	https://data.freetouse.com/music/tracks/11f36be5-d08f-408a-938b-0adfb0047d8f/file/mp3/file.mp3	未知	0
517	The Basics	22	397	131	https://data.freetouse.com/music/tracks/cfa62422-a3ae-4828-b843-69d390e49942/file/mp3/file.mp3	未知	0
518	Cozy Evening	35	309	119	https://data.freetouse.com/music/tracks/2968cdd3-21a0-40c9-998f-719da7cc9c94/file/mp3/file.mp3	未知	0
519	Wanderer at Night	1	311	229	https://data.freetouse.com/music/tracks/d43e3536-98ad-4b7a-8a66-574373150d42/file/mp3/file.mp3	未知	0
520	Deep Love	19	318	164	https://data.freetouse.com/music/tracks/1a1ad4b9-cfc2-4a57-9873-51739d2a3119/file/mp3/file.mp3	未知	0
521	Motocross Game	13	392	125	https://data.freetouse.com/music/tracks/e53622e5-c955-4388-9297-909d10750432/file/mp3/file.mp3	未知	0
522	Mud	12	414	123	https://data.freetouse.com/music/tracks/46258c86-4c12-4b89-a118-ba69f208d131/file/mp3/file.mp3	未知	0
523	Soase	22	397	128	https://data.freetouse.com/music/tracks/1b369319-5c8e-4911-89d4-4406489063ba/file/mp3/file.mp3	未知	0
524	Better Now	36	294	127	https://data.freetouse.com/music/tracks/2b42af8c-8b84-4125-b28f-549ab5ea1ac6/file/mp3/file.mp3	未知	0
525	Dancing In The Rain	1	311	145	https://data.freetouse.com/music/tracks/e27de288-d4b0-4577-872b-a26fcbd78628/file/mp3/file.mp3	未知	0
526	A Little Explorer	18	370	234	https://data.freetouse.com/music/tracks/322f9c1d-d614-4bd8-9a08-9d2d15e40947/file/mp3/file.mp3	未知	0
527	Romance	12	414	117	https://data.freetouse.com/music/tracks/95b0392c-e9bb-47c8-96fc-d5af779fc09b/file/mp3/file.mp3	未知	0
528	Sunset Drive	35	309	121	https://data.freetouse.com/music/tracks/2ca316c3-6143-4b49-9f63-15d560d12007/file/mp3/file.mp3	未知	0
529	Imagination	10	390	165	https://data.freetouse.com/music/tracks/92f3a0e2-d2bb-441c-a2c5-38bf0860f5d9/file/mp3/file.mp3	未知	0
530	Break	22	397	100	https://data.freetouse.com/music/tracks/2969871b-0d2e-4ae0-ac8f-ed8290d86d28/file/mp3/file.mp3	未知	0
531	Odyssey	10	390	217	https://data.freetouse.com/music/tracks/e71f8244-f8a1-403f-8733-cf9df42e37cb/file/mp3/file.mp3	未知	0
532	Giant Wave	1	311	142	https://data.freetouse.com/music/tracks/e7a6690c-412b-4c37-adbd-8c50b423a9cb/file/mp3/file.mp3	未知	0
533	Want You Back	35	309	110	https://data.freetouse.com/music/tracks/45041b33-f778-43d3-ab6b-d227eb009280/file/mp3/file.mp3	未知	0
534	Waiting For The Rain	12	414	130	https://data.freetouse.com/music/tracks/a9ba5d81-60a9-4726-a93d-879c38e71b4f/file/mp3/file.mp3	未知	0
535	ocean	9	336	151	https://data.freetouse.com/music/tracks/f14bf3ec-349c-41dc-979e-f00526906ada/file/mp3/file.mp3	未知	0
536	Signal	1	311	126	https://data.freetouse.com/music/tracks/d64c0985-38a5-4477-b8f8-03ce4dea4cd0/file/mp3/file.mp3	未知	0
537	Display	22	397	102	https://data.freetouse.com/music/tracks/4e647294-c4da-4836-967b-fa9864d8ded1/file/mp3/file.mp3	未知	0
538	Travel Alone	35	309	150	https://data.freetouse.com/music/tracks/97a57fd4-4910-4522-8653-b21158b7b8a8/file/mp3/file.mp3	未知	0
539	Always Love	33	327	114	https://data.freetouse.com/music/tracks/63cab4c2-947e-4842-9eb6-6f60589967db/file/mp3/file.mp3	未知	0
540	Happiness In My Soul	12	414	122	https://data.freetouse.com/music/tracks/0105ff85-edcd-484a-8d05-27ea1f24dbdf/file/mp3/file.mp3	未知	0
541	Connect	36	294	184	https://data.freetouse.com/music/tracks/566403f0-9997-47ac-b6c1-41f4b5c69e95/file/mp3/file.mp3	未知	0
542	Moroccan Night	13	392	133	https://data.freetouse.com/music/tracks/728ed711-2004-4f9c-8c07-c6b899859fe8/file/mp3/file.mp3	未知	0
543	Funky Monkey	1	311	90	https://data.freetouse.com/music/tracks/1bd623cd-3e6d-4479-bd16-0e0e13734dbf/file/mp3/file.mp3	未知	0
544	Guesswork	35	309	133	https://data.freetouse.com/music/tracks/c48c115e-e495-42c6-aec9-6656fa8a3d51/file/mp3/file.mp3	未知	0
545	Final Breath of a Star	29	314	193	https://data.freetouse.com/music/tracks/c3547804-09cb-4b6b-be98-556daf29908d/file/mp3/file.mp3	未知	0
546	stroll	9	336	180	https://data.freetouse.com/music/tracks/3e6024e2-d36c-439e-af62-6d6b2d79f3b3/file/mp3/file.mp3	未知	0
547	Foreign	22	397	132	https://data.freetouse.com/music/tracks/e306e01b-5036-4c2e-8333-4361b213b9a8/file/mp3/file.mp3	未知	0
548	Wild Tales	1	311	110	https://data.freetouse.com/music/tracks/4454f76d-0ced-41bc-8153-8a81d032b8e5/file/mp3/file.mp3	未知	0
549	Mission	33	327	170	https://data.freetouse.com/music/tracks/c26d4a56-0f9a-4d01-aaa6-a757d4815640/file/mp3/file.mp3	未知	0
550	Blues In My Socks	12	414	137	https://data.freetouse.com/music/tracks/390f1abc-6191-44cf-96d6-c964a0c024f6/file/mp3/file.mp3	未知	0
551	Faster	1	311	159	https://data.freetouse.com/music/tracks/4b3a2346-e781-4983-8e03-bca852c5e52a/file/mp3/file.mp3	未知	0
552	Enough Time	37	407	124	https://data.freetouse.com/music/tracks/8b0b5620-8e03-404d-975a-0c880a28e48b/file/mp3/file.mp3	未知	0
553	Silent Night	1	311	112	https://data.freetouse.com/music/tracks/f6254f0a-f022-4689-9972-c3ed4962df31/file/mp3/file.mp3	未知	0
554	Livin Water	37	407	124	https://data.freetouse.com/music/tracks/b8350130-67ee-4012-afd5-b425f1eae823/file/mp3/file.mp3	未知	0
555	Gamma	1	311	80	https://data.freetouse.com/music/tracks/5cddcd90-abbb-4292-abf8-9c6f696f6aa8/file/mp3/file.mp3	未知	0
556	Desert West	12	414	116	https://data.freetouse.com/music/tracks/92f1b476-97bc-4af5-84c3-dcfe19d4b656/file/mp3/file.mp3	未知	0
557	Back To Promise	37	407	93	https://data.freetouse.com/music/tracks/44f617d2-409d-461c-bb2b-63374a473929/file/mp3/file.mp3	未知	0
558	Polaroid	1	311	100	https://data.freetouse.com/music/tracks/60b2e910-6614-4933-9489-c519030f134c/file/mp3/file.mp3	未知	0
560	Area 16	29	314	162	https://data.freetouse.com/music/tracks/afc0f563-1981-47d3-af14-63aec0fc5f35/file/mp3/file.mp3	未知	0
561	Horizon	1	311	128	https://data.freetouse.com/music/tracks/7e77a349-8307-4e2c-82bb-c6a9bdc07277/file/mp3/file.mp3	未知	0
562	High Up	27	384	170	https://data.freetouse.com/music/tracks/d9251814-4090-4aa2-bb84-7e06aff5eb8c/file/mp3/file.mp3	未知	0
563	All In	22	397	137	https://data.freetouse.com/music/tracks/c357c016-e0a6-45e1-86f6-aab3f0460874/file/mp3/file.mp3	未知	0
564	Lighthouse	1	311	103	https://data.freetouse.com/music/tracks/80dc8514-24d4-4d00-904d-7efb9c3820a1/file/mp3/file.mp3	未知	0
565	Majestic	10	390	227	https://data.freetouse.com/music/tracks/c71a7fff-f3fa-48ca-b792-719f5f7fb3a5/file/mp3/file.mp3	未知	0
566	Clean it Up	37	407	119	https://data.freetouse.com/music/tracks/f4309edd-7bbd-4790-b8e9-8f75e70d47c2/file/mp3/file.mp3	未知	0
567	Tropicaneva	22	397	118	https://data.freetouse.com/music/tracks/e8df9085-f606-40f7-aed4-6707cd32e2a6/file/mp3/file.mp3	未知	0
568	Nostalgic	1	311	99	https://data.freetouse.com/music/tracks/c1c31325-ef8b-4d10-8a02-6773eb642f05/file/mp3/file.mp3	未知	0
569	Tranquility	29	314	131	https://data.freetouse.com/music/tracks/65376134-6e13-4f88-adf8-ca2f2db5fd87/file/mp3/file.mp3	未知	0
570	Asleep	22	397	162	https://data.freetouse.com/music/tracks/8c748bd2-017a-4e85-9253-7a67136ff1ab/file/mp3/file.mp3	未知	0
571	Destiny	10	390	265	https://data.freetouse.com/music/tracks/51fee5f3-c971-45f3-b7cc-d6ca74b21c73/file/mp3/file.mp3	未知	0
572	Spinning	1	311	138	https://data.freetouse.com/music/tracks/c9659c50-bdf3-42de-b815-87173272350e/file/mp3/file.mp3	未知	0
573	Combat	41	321	138	https://data.freetouse.com/music/tracks/fbbfefd1-127e-4778-a172-8993020d0de1/file/mp3/file.mp3	未知	0
574	Thats Right	22	397	125	https://data.freetouse.com/music/tracks/02dfa1fb-367a-48e2-b03f-73c1aef3ddaf/file/mp3/file.mp3	未知	0
575	Caribbean	1	311	119	https://data.freetouse.com/music/tracks/d749debd-50cc-4aea-affb-b78776fbf257/file/mp3/file.mp3	未知	0
576	Ancient Warriors	1	311	143	https://data.freetouse.com/music/tracks/d7756c6a-0461-4bbe-b719-95d08cc389d0/file/mp3/file.mp3	未知	0
577	Feeling Good	22	397	125	https://data.freetouse.com/music/tracks/235955b8-8345-4383-9c7b-5b2ff0e76e32/file/mp3/file.mp3	未知	0
578	Eternity	10	390	166	https://data.freetouse.com/music/tracks/a612e3de-895f-4416-8c36-d8daa681a649/file/mp3/file.mp3	未知	0
579	Happy New Year	33	327	149	https://data.freetouse.com/music/tracks/6b31d60c-5da1-41b1-a7b4-946ad73ccbb0/file/mp3/file.mp3	未知	0
580	Beachhouse	1	311	221	https://data.freetouse.com/music/tracks/da80ad1b-c0d5-44f9-8110-af1001e6e83a/file/mp3/file.mp3	未知	0
581	Yayuu	42	290	206	https://data.freetouse.com/music/tracks/64b709a7-e76a-47a5-a67b-fd48e422e1e7/file/mp3/file.mp3	未知	0
582	Winter Magic	22	397	96	https://data.freetouse.com/music/tracks/77ea6b19-b573-45e4-9288-677ae9494ae2/file/mp3/file.mp3	未知	0
584	Icicle	35	309	145	https://data.freetouse.com/music/tracks/1d211890-15cb-4d28-a0a4-70c7495ac03b/file/mp3/file.mp3	未知	0
585	Clarity	41	321	166	https://data.freetouse.com/music/tracks/1f7c4e12-375c-4b59-a007-b108a3424278/file/mp3/file.mp3	未知	0
586	Fantasy World	1	311	101	https://data.freetouse.com/music/tracks/de107ade-2157-4bcc-8ced-1a201d22c633/file/mp3/file.mp3	未知	0
587	Night Hawk	5	5	189	https://data.freetouse.com/music/tracks/b61c7ba7-ba14-4ee4-b0dc-2e2e5a32654c/file/mp3/file.mp3	未知	0
589	Sunset Strip	1	311	103	https://data.freetouse.com/music/tracks/e1da89a3-cf1f-41cc-9494-7ab65f0cceb4/file/mp3/file.mp3	未知	0
590	Once Again	22	397	162	https://data.freetouse.com/music/tracks/a04ceac6-5b96-4d8f-84fd-33b233ac9cb2/file/mp3/file.mp3	未知	0
591	Victory	11	364	120	https://data.freetouse.com/music/tracks/0c5212f4-2fbc-4801-9ac3-7709932dabd0/file/mp3/file.mp3	未知	0
593	All I Want For Christmas	35	309	112	https://data.freetouse.com/music/tracks/bd8aef1a-1909-4335-8ada-2d4defab8bbc/file/mp3/file.mp3	未知	0
594	Holy Night	33	327	102	https://data.freetouse.com/music/tracks/750e1f94-c53a-451b-a3e4-e14c010552d5/file/mp3/file.mp3	未知	0
595	Jingle Bell Rock	35	309	136	https://data.freetouse.com/music/tracks/9ab2c214-cb54-41a0-9770-4dec5cef034f/file/mp3/file.mp3	未知	0
596	Christmas Lullaby	33	327	105	https://data.freetouse.com/music/tracks/b9ed4663-33a4-4d50-86bc-1a5e14e4dcd0/file/mp3/file.mp3	未知	0
597	Last Christmas	33	327	117	https://data.freetouse.com/music/tracks/1e06eac8-6933-4576-a117-526586631668/file/mp3/file.mp3	未知	0
598	Let It Snow	33	327	98	https://data.freetouse.com/music/tracks/8270842c-99e5-4f47-96b7-0eefc77fd7df/file/mp3/file.mp3	未知	0
599	Just A Minute	22	397	133	https://data.freetouse.com/music/tracks/fb8f95c5-08c6-4e99-9a8e-be744435d01f/file/mp3/file.mp3	未知	0
600	Face The Future	11	364	203	https://data.freetouse.com/music/tracks/02f2dae0-5a1c-4e63-80d2-da388a488fb0/file/mp3/file.mp3	未知	0
601	downtown	9	336	156	https://data.freetouse.com/music/tracks/158e9227-d671-4280-b14c-cf228c52cc64/file/mp3/file.mp3	未知	0
602	Eternal Love	11	364	133	https://data.freetouse.com/music/tracks/32425f2c-377b-44e1-87f4-87f68c14261f/file/mp3/file.mp3	未知	0
603	Evolution	11	364	179	https://data.freetouse.com/music/tracks/bb35d76a-dd8e-4f67-ad83-09a733036d8f/file/mp3/file.mp3	未知	0
604	AI AGENTS	19	318	162	https://data.freetouse.com/music/tracks/9e925898-e260-4670-814e-2b60a5b19af4/file/mp3/file.mp3	未知	0
605	Daydreams	11	364	107	https://data.freetouse.com/music/tracks/97165fba-4d37-49dc-a09e-a8fd514a3497/file/mp3/file.mp3	未知	0
606	Study Night	34	334	176	https://data.freetouse.com/music/tracks/86a08ccc-6e7f-4aa2-97cf-767bc244cc1c/file/mp3/file.mp3	未知	0
607	Breaking News	13	392	92	https://data.freetouse.com/music/tracks/d991b41c-8d69-4480-919c-80e6ba644ad2/file/mp3/file.mp3	未知	0
608	UNBOX	43	360	205	https://data.freetouse.com/music/tracks/ff0e7b69-ab13-4afb-8fe3-7242c5270e97/file/mp3/file.mp3	未知	0
609	Extreme Force	11	364	162	https://data.freetouse.com/music/tracks/4eeedd8b-e7bd-4299-bd74-c3abd81e8a5e/file/mp3/file.mp3	未知	0
610	Echo Valley	23	389	161	https://data.freetouse.com/music/tracks/ef3224a7-288d-4368-8123-0727803da801/file/mp3/file.mp3	未知	0
611	Champions	13	392	145	https://data.freetouse.com/music/tracks/593fd64b-0ec5-449e-8310-8d547ea77f96/file/mp3/file.mp3	未知	0
612	Next Time	22	397	194	https://data.freetouse.com/music/tracks/e6418250-bd36-fa37-06eb-2a4eca55b53a/file/mp3/file.mp3	未知	0
613	glimmer	9	336	151	https://data.freetouse.com/music/tracks/06ab6f7a-077c-45de-bf00-0ed687c28afe/file/mp3/file.mp3	未知	0
614	Turbo	22	397	148	https://data.freetouse.com/music/tracks/dc8d22ef-6ded-4b4f-4915-c416151175e6/file/mp3/file.mp3	未知	0
615	Our Way	44	287	151	https://data.freetouse.com/music/tracks/856bbb6d-b062-ad1e-c681-90dca37472c6/file/mp3/file.mp3	未知	0
616	Blur	45	371	146	https://data.freetouse.com/music/tracks/c551e457-092b-d950-9aef-951659ebdb92/file/mp3/file.mp3	未知	0
617	Avenue	22	397	199	https://data.freetouse.com/music/tracks/b6949340-096a-8154-b970-e150d6b4fd4b/file/mp3/file.mp3	未知	0
618	Here We Go	46	405	174	https://data.freetouse.com/music/tracks/7dba500c-a9d0-55b8-d40a-2feaf0309079/file/mp3/file.mp3	未知	0
619	Vampire Dracula	13	392	111	https://data.freetouse.com/music/tracks/af7c6e7e-9813-f2b6-af58-0344bf9e1a40/file/mp3/file.mp3	未知	0
620	Lurker	45	371	154	https://data.freetouse.com/music/tracks/788e805a-0e7d-327d-3e5a-69bd8cff5e53/file/mp3/file.mp3	未知	0
621	Downtown	22	397	155	https://data.freetouse.com/music/tracks/919f6e99-d3ef-b391-4edb-1edb702c582f/file/mp3/file.mp3	未知	0
622	Time Traveller	34	334	151	https://data.freetouse.com/music/tracks/0bc63770-c824-a5c4-9c66-9faeb66a0b32/file/mp3/file.mp3	未知	0
623	Bar Soul	13	392	128	https://data.freetouse.com/music/tracks/0cc41fb0-2a7b-f945-b0c5-cb8c88b4284c/file/mp3/file.mp3	未知	0
624	Higher	22	397	131	https://data.freetouse.com/music/tracks/f64a9b03-539b-8f30-e457-3e47c9b53e69/file/mp3/file.mp3	未知	0
625	Zero	38	388	209	https://data.freetouse.com/music/tracks/fbf48129-7c32-fb6d-dff7-c44694084863/file/mp3/file.mp3	未知	0
626	Coming Of Age	45	371	208	https://data.freetouse.com/music/tracks/eabaf213-04cc-e8e3-5ee3-a513bd45ea1f/file/mp3/file.mp3	未知	0
627	Vlog Funk	19	318	137	https://data.freetouse.com/music/tracks/4924767c-8dc5-6c2c-c593-5bd2a21b47e6/file/mp3/file.mp3	未知	0
628	Starlight	22	397	132	https://data.freetouse.com/music/tracks/7d0bd840-3b05-8859-e3e7-db942c0ea37b/file/mp3/file.mp3	未知	0
629	Loveless	41	321	144	https://data.freetouse.com/music/tracks/89312087-27b5-2562-2c9f-a9e660829d91/file/mp3/file.mp3	未知	0
630	Lounge Bar Lofi	34	334	160	https://data.freetouse.com/music/tracks/5c40f234-cd1d-8a8f-2ba2-77342de95b70/file/mp3/file.mp3	未知	0
631	Artificial Intelligence	11	364	157	https://data.freetouse.com/music/tracks/8f1e805f-0e6e-6886-1ec7-c3e4bcef4494/file/mp3/file.mp3	未知	0
632	Decadence	43	360	187	https://data.freetouse.com/music/tracks/50440375-e8e6-5df7-9cdc-0997532f86c0/file/mp3/file.mp3	未知	0
633	Payback	47	324	119	https://data.freetouse.com/music/tracks/8f5d5106-d7b6-990a-1dbd-44962fe0389f/file/mp3/file.mp3	未知	0
634	Sun	22	397	130	https://data.freetouse.com/music/tracks/82f4482e-c1fe-482a-2c09-2bcef5bad10b/file/mp3/file.mp3	未知	0
635	Too Many Times	23	389	201	https://data.freetouse.com/music/tracks/b92bbd81-b5e3-382d-2d8a-8023ed6e7340/file/mp3/file.mp3	未知	0
636	Fashion Queen	11	364	133	https://data.freetouse.com/music/tracks/298ac51a-59ad-4dcb-d72f-2d5f06b87016/file/mp3/file.mp3	未知	0
637	B Reel	19	318	128	https://data.freetouse.com/music/tracks/3ffa855c-7f65-3802-e6d5-1fe24f573de3/file/mp3/file.mp3	未知	0
638	Far Away	22	397	123	https://data.freetouse.com/music/tracks/51ba83ee-55cb-0f12-e294-64d972f9981a/file/mp3/file.mp3	未知	0
640	Reflection	45	371	120	https://data.freetouse.com/music/tracks/9e6a474f-c462-d38e-2c16-587cc134537a/file/mp3/file.mp3	未知	0
641	On Hold	11	364	89	https://data.freetouse.com/music/tracks/87f647d2-a7b8-07db-b253-e4350060374c/file/mp3/file.mp3	未知	0
642	Ovanea	22	397	124	https://data.freetouse.com/music/tracks/13c0a03b-4cb3-896f-c196-1fac968376c7/file/mp3/file.mp3	未知	0
643	Lost Your Love	23	389	174	https://data.freetouse.com/music/tracks/5b720f28-e8f5-ee8e-bf60-1b070c81e0f6/file/mp3/file.mp3	未知	0
644	Sunrise	43	360	186	https://data.freetouse.com/music/tracks/4b6a8c63-9688-d427-b2c2-ac7541d52356/file/mp3/file.mp3	未知	0
645	Sunset Dreams	22	397	87	https://data.freetouse.com/music/tracks/e9ff9604-d9d9-4fe0-8afb-26e1bc532680/file/mp3/file.mp3	未知	0
646	Ahead Of Us	35	309	132	https://data.freetouse.com/music/tracks/70644ab9-91d9-8b74-62c9-b80e1e8cf4c6/file/mp3/file.mp3	未知	0
647	Dawn	10	382	177	https://data.freetouse.com/music/tracks/ad9be0ab-3cc5-443f-b66e-b6e68eb49c51/file/mp3/file.mp3	未知	0
648	Kids Funk	19	318	102	https://data.freetouse.com/music/tracks/5aee1392-b345-7ac9-bf7a-650ea974c0ed/file/mp3/file.mp3	未知	0
649	Keep Pushing	11	364	128	https://data.freetouse.com/music/tracks/b61a5840-b7b0-4e7c-b3f0-e136a9f64e31/file/mp3/file.mp3	未知	0
650	See Me Through	47	324	122	https://data.freetouse.com/music/tracks/b7dca04d-98c2-a7fc-6caf-8b85492e9492/file/mp3/file.mp3	未知	0
651	city	9	336	140	https://data.freetouse.com/music/tracks/cc3d9f0e-53a1-405f-812b-abea2e3fb8be/file/mp3/file.mp3	未知	0
652	Je T'aime	23	389	154	https://data.freetouse.com/music/tracks/0cd48def-0187-7b57-6221-31fd7ffeac2d/file/mp3/file.mp3	未知	0
653	Moonlit Mangroves	34	334	169	https://data.freetouse.com/music/tracks/ac45f67f-ee87-ab7b-08ac-894b88dc9502/file/mp3/file.mp3	未知	0
654	Dream On	22	397	162	https://data.freetouse.com/music/tracks/58ce355e-9db1-1181-4d76-c6f2cf4b39f0/file/mp3/file.mp3	未知	0
655	Warrior	13	392	133	https://data.freetouse.com/music/tracks/f3dd3860-aaf0-ac5d-3e09-a3067111f423/file/mp3/file.mp3	未知	0
656	ANIME	11	364	114	https://data.freetouse.com/music/tracks/b8db95aa-977f-3e14-7846-90157e3e9228/file/mp3/file.mp3	未知	0
657	Spark	49	399	151	https://data.freetouse.com/music/tracks/52a51c94-d490-b4bf-c708-896ea0555d8c/file/mp3/file.mp3	未知	0
658	Walk On By	35	309	132	https://data.freetouse.com/music/tracks/7e0b6c72-7ca6-6ea3-0a13-1b711b4091ee/file/mp3/file.mp3	未知	0
659	At Ease	45	371	106	https://data.freetouse.com/music/tracks/ba1fa94b-1d39-7b71-7fc1-63ef5c30f357/file/mp3/file.mp3	未知	0
660	Poetry	35	309	134	https://data.freetouse.com/music/tracks/5472cd41-87b8-0b7a-fb70-82fb837a5a6b/file/mp3/file.mp3	未知	0
661	Joyful Boredom	23	389	111	https://data.freetouse.com/music/tracks/3a2a28cb-b40e-20ee-ddb7-8be3e20d2304/file/mp3/file.mp3	未知	0
662	Summer Never Ends	36	294	142	https://data.freetouse.com/music/tracks/660b8c27-9366-b0b5-68e7-e8cce62e3e1f/file/mp3/file.mp3	未知	0
663	Universal	22	397	113	https://data.freetouse.com/music/tracks/34dc5b7a-3c92-4fb5-2f0d-f5bb48d95958/file/mp3/file.mp3	未知	0
664	Morning Light	33	327	240	https://data.freetouse.com/music/tracks/0f1372b5-5340-f550-8089-02a8d0d713ea/file/mp3/file.mp3	未知	0
665	Jawed Elephants	43	360	266	https://data.freetouse.com/music/tracks/565fbc14-bb46-e770-2a9b-890fde053203/file/mp3/file.mp3	未知	0
666	Hold Me Now	23	389	138	https://data.freetouse.com/music/tracks/4d944741-cce3-8845-929c-2eb4eddf4f21/file/mp3/file.mp3	未知	0
667	Infinite Galaxy	13	392	160	https://data.freetouse.com/music/tracks/25df1bf7-b804-62bc-e941-c01da8c7ea7b/file/mp3/file.mp3	未知	0
668	Chances	47	324	119	https://data.freetouse.com/music/tracks/374a40f3-7b76-d282-5fc8-9c95e8c180d4/file/mp3/file.mp3	未知	0
669	Catamaran	36	294	151	https://data.freetouse.com/music/tracks/bd2afcf3-209e-31c9-3171-b59a9b3a82ee/file/mp3/file.mp3	未知	0
670	High	28	369	145	https://data.freetouse.com/music/tracks/44f079cd-0f2a-e499-c217-0d07834e03b2/file/mp3/file.mp3	未知	0
671	Echoes From The Void	35	309	130	https://data.freetouse.com/music/tracks/a8524feb-8988-0973-ae0a-8d8a2022ba07/file/mp3/file.mp3	未知	0
672	Ethos	33	327	184	https://data.freetouse.com/music/tracks/a20b95a4-085b-ee46-f009-d7583890d296/file/mp3/file.mp3	未知	0
673	Northern Lights	23	389	146	https://data.freetouse.com/music/tracks/9fab7c51-811b-5a40-ff91-e2224a4ab27e/file/mp3/file.mp3	未知	0
674	Beach Slam	22	397	91	https://data.freetouse.com/music/tracks/a1cbdf27-331e-8124-8326-5efcb92d2f43/file/mp3/file.mp3	未知	0
675	Vlogger	19	318	128	https://data.freetouse.com/music/tracks/ceb97f63-2d97-d9b6-bee1-6d92e40ac5f1/file/mp3/file.mp3	未知	0
676	Evermore	10	382	164	https://data.freetouse.com/music/tracks/f19d092e-ed7a-4f7a-a848-519cfb9c5681/file/mp3/file.mp3	未知	0
677	Braveheart	10	390	181	https://data.freetouse.com/music/tracks/70b7d123-df0a-471c-b57d-ffd610adbdd9/file/mp3/file.mp3	未知	0
678	Jungle	36	294	148	https://data.freetouse.com/music/tracks/aba20bb8-5f67-9e06-23c2-3feab4178c29/file/mp3/file.mp3	未知	0
679	Mindwave	23	389	151	https://data.freetouse.com/music/tracks/5a252413-b0e8-98ba-0121-a5a8305b3242/file/mp3/file.mp3	未知	0
680	Sundara	50	302	159	https://data.freetouse.com/music/tracks/755e2a17-13a7-710c-1d14-3c62e660029f/file/mp3/file.mp3	未知	0
681	Maui	45	371	138	https://data.freetouse.com/music/tracks/e0f78f6d-3922-5272-2291-89120e4eaa6d/file/mp3/file.mp3	未知	0
682	Do You Want Me	43	360	202	https://data.freetouse.com/music/tracks/900e28d1-dd50-3536-8b0e-88d826972355/file/mp3/file.mp3	未知	0
683	Faded Light	10	382	139	https://data.freetouse.com/music/tracks/3d6cd36c-f24c-4502-8699-072d3b7549d3/file/mp3/file.mp3	未知	0
684	Parga	22	397	110	https://data.freetouse.com/music/tracks/b08ae724-e996-0606-c1e3-d5b242d4ca5d/file/mp3/file.mp3	未知	0
685	The Reason Is You	23	389	169	https://data.freetouse.com/music/tracks/d87bbaa7-9dba-5527-2946-b87e933b1ad4/file/mp3/file.mp3	未知	0
686	Make a Stand	34	334	156	https://data.freetouse.com/music/tracks/0455e5fe-58a0-005e-2207-d13b5f94c711/file/mp3/file.mp3	未知	0
687	Sandcastles	36	294	149	https://data.freetouse.com/music/tracks/85c8a37d-c5d9-49f5-6fa2-4cd681dc6909/file/mp3/file.mp3	未知	0
688	Waiting For The Sun	23	389	232	https://data.freetouse.com/music/tracks/2ff6f90a-a9e1-8a34-eb1e-e4e5c517f24b/file/mp3/file.mp3	未知	0
691	Fresh Start	35	309	153	https://data.freetouse.com/music/tracks/5845e53c-08ee-1fa1-504f-a96739114569/file/mp3/file.mp3	未知	0
692	Closer	23	389	192	https://data.freetouse.com/music/tracks/1eb6ab04-1e34-cbab-cd9a-ad672bcc3954/file/mp3/file.mp3	未知	0
693	Lost	22	397	116	https://data.freetouse.com/music/tracks/0659f373-1a69-be1a-cd01-6d39cc63db94/file/mp3/file.mp3	未知	0
694	Pink Clouds	33	327	137	https://data.freetouse.com/music/tracks/4ada7bc6-8045-d830-2bed-a4cc14c537d7/file/mp3/file.mp3	未知	0
695	Rush Metal	8	320	214	https://data.freetouse.com/music/tracks/3683dc8e-ecc9-95a1-03d9-f51bd7b5402a/file/mp3/file.mp3	未知	0
696	Fake Romance	23	389	158	https://data.freetouse.com/music/tracks/8c35b5ef-ed8e-0c6b-df4c-5d9c54875288/file/mp3/file.mp3	未知	0
697	Office Jam	35	309	98	https://data.freetouse.com/music/tracks/1896d63d-5af8-8702-0a6a-c4f9e9f74b1b/file/mp3/file.mp3	未知	0
698	Langoos	22	397	120	https://data.freetouse.com/music/tracks/7779eb26-e2c3-3f8f-93ce-3159e169a94c/file/mp3/file.mp3	未知	0
699	Paradise	23	389	230	https://data.freetouse.com/music/tracks/a04a889a-9790-8b3b-ea2f-6076d106cdb1/file/mp3/file.mp3	未知	0
701	OSAKA	49	399	280	https://data.freetouse.com/music/tracks/39d0e34b-8a9e-ec90-e9d3-4363a496a64a/file/mp3/file.mp3	未知	0
702	Rush	11	364	151	https://data.freetouse.com/music/tracks/7a18da50-7d97-c802-dc52-4eaed08cc4d5/file/mp3/file.mp3	未知	0
703	Sky Clearing	33	327	169	https://data.freetouse.com/music/tracks/24b5f6b9-e5e9-b7f1-36cc-5da09b2f5f71/file/mp3/file.mp3	未知	0
704	Atmospheric Guitar	8	320	192	https://data.freetouse.com/music/tracks/313cb883-61bd-939f-5e92-9f01be2b6bc6/file/mp3/file.mp3	未知	0
705	Used To Say	23	389	164	https://data.freetouse.com/music/tracks/cf656af0-58df-e80c-06ff-bd3eb30e49dc/file/mp3/file.mp3	未知	0
706	Neon Sunset	35	309	203	https://data.freetouse.com/music/tracks/e7583c5c-71d6-0662-7d55-e9d4b4c1a33f/file/mp3/file.mp3	未知	0
707	So Refreshing	11	364	116	https://data.freetouse.com/music/tracks/ec5b97ab-0262-b699-8757-8effc108ab4a/file/mp3/file.mp3	未知	0
708	Canariea	22	397	136	https://data.freetouse.com/music/tracks/f4ac2ac0-bb5e-bf26-8e3a-3a5f6ef08d80/file/mp3/file.mp3	未知	0
709	Drum Story	8	320	120	https://data.freetouse.com/music/tracks/4b0e5836-596a-b937-fbd1-fdff19772f83/file/mp3/file.mp3	未知	0
710	The One For You	23	389	182	https://data.freetouse.com/music/tracks/c2131658-1326-5399-e3ca-c53b7c9138c4/file/mp3/file.mp3	未知	0
711	Shaman	1	311	180	https://data.freetouse.com/music/tracks/adcfeff0-021c-497e-9996-eb98a0fb7103/file/mp3/file.mp3	未知	0
712	Cool Rock	8	320	156	https://data.freetouse.com/music/tracks/18f8d8cc-1ec9-93c2-05b1-1e9b4761cfc4/file/mp3/file.mp3	未知	0
713	Vacation	11	364	126	https://data.freetouse.com/music/tracks/5223c780-a092-7134-ddc4-70bd9977acd1/file/mp3/file.mp3	未知	0
714	Tariro	8	320	139	https://data.freetouse.com/music/tracks/8ca850b2-2ef4-0384-155b-f1c47025ca67/file/mp3/file.mp3	未知	0
715	Sunny Day	11	364	124	https://data.freetouse.com/music/tracks/be509499-4aa2-0a95-08a0-ca856003a884/file/mp3/file.mp3	未知	0
716	Stay	23	389	156	https://data.freetouse.com/music/tracks/5da543df-819b-ae9a-f164-e7238ef39103/file/mp3/file.mp3	未知	0
717	LOUD	11	364	113	https://data.freetouse.com/music/tracks/ac880653-91f8-0b0b-cd87-f0a48347a40e/file/mp3/file.mp3	未知	0
718	Take Me Back	13	392	156	https://data.freetouse.com/music/tracks/69e6fbdf-d537-2884-fda6-9a1ccfcaa035/file/mp3/file.mp3	未知	0
719	Synergy	11	364	150	https://data.freetouse.com/music/tracks/e9df589f-1286-e430-d5a2-7acbfc9b3ffb/file/mp3/file.mp3	未知	0
720	Dreamscape	8	320	165	https://data.freetouse.com/music/tracks/9c4669bd-79ee-f0e9-f317-ab09250d7efc/file/mp3/file.mp3	未知	0
721	Stardust	8	320	138	https://data.freetouse.com/music/tracks/45d4d6cc-7622-cd6a-27fe-b69862540987/file/mp3/file.mp3	未知	0
722	Echoes	8	320	172	https://data.freetouse.com/music/tracks/d29829d2-c1b6-d1a4-ee8c-098f11346fb6/file/mp3/file.mp3	未知	0
723	Thief In The Night	23	389	216	https://data.freetouse.com/music/tracks/062913c9-b3ab-4387-6ba6-90884d7cdc79/file/mp3/file.mp3	未知	0
725	These Days	11	364	127	https://data.freetouse.com/music/tracks/eb83a0e5-0d1d-5d3e-3721-a48d12209e96/file/mp3/file.mp3	未知	0
726	Ride It	35	309	128	https://data.freetouse.com/music/tracks/d6f53a8e-dbb2-136c-0683-a64f36bdbcbb/file/mp3/file.mp3	未知	0
727	Warriors	10	382	192	https://data.freetouse.com/music/tracks/2d615b0e-d70f-40e0-978a-bde877ff977f/file/mp3/file.mp3	未知	0
728	Wings of Freedom	10	390	126	https://data.freetouse.com/music/tracks/67e80b77-8bf2-4475-866b-eab66c48b178/file/mp3/file.mp3	未知	0
729	Emotional Moments	10	390	164	https://data.freetouse.com/music/tracks/51a187dd-40b0-4c9d-9e07-60b30465d08d/file/mp3/file.mp3	未知	0
730	Luxury	8	320	157	https://data.freetouse.com/music/tracks/e7963b02-a46e-6c51-19c6-75827ab80883/file/mp3/file.mp3	未知	0
731	Braveheart	11	364	126	https://data.freetouse.com/music/tracks/650e051f-fc68-3219-1fc3-8c76066488dd/file/mp3/file.mp3	未知	0
732	Ride Or Die	23	389	178	https://data.freetouse.com/music/tracks/b82bb236-3ed5-933b-457e-5ba90c6fbee2/file/mp3/file.mp3	未知	0
733	Freshness	11	364	127	https://data.freetouse.com/music/tracks/b3169f65-06e7-9ac8-be71-b3525a179a4a/file/mp3/file.mp3	未知	0
734	Daydreams	8	320	130	https://data.freetouse.com/music/tracks/87770436-20d0-93d8-491a-aea2d8af0821/file/mp3/file.mp3	未知	0
735	Green Symphony	30	300	128	https://data.freetouse.com/music/tracks/babb673f-3b54-e5d2-cd62-64d88957d916/file/mp3/file.mp3	未知	0
736	Pressure	33	327	153	https://data.freetouse.com/music/tracks/8a6596d6-e0a8-f20a-6aba-881d675b56d0/file/mp3/file.mp3	未知	0
737	I Can Fly	11	364	137	https://data.freetouse.com/music/tracks/ed5b13b0-d960-bc9a-39f3-704cd86b175e/file/mp3/file.mp3	未知	0
738	Happy	23	389	183	https://data.freetouse.com/music/tracks/b512eba1-f77b-fbda-9c35-6e02d4231012/file/mp3/file.mp3	未知	0
739	familiar places	9	336	151	https://data.freetouse.com/music/tracks/3c26c8e7-3fab-4f83-6968-b3023aab714c/file/mp3/file.mp3	未知	0
740	Looking Back	35	309	151	https://data.freetouse.com/music/tracks/5dfdff9e-ad9c-3b28-9978-11b568dcdce0/file/mp3/file.mp3	未知	0
741	Summer Sound	11	364	127	https://data.freetouse.com/music/tracks/2dac8b39-aa44-cb6c-24f4-351b8a18bf86/file/mp3/file.mp3	未知	0
742	Antique	8	320	127	https://data.freetouse.com/music/tracks/13a49cfb-7f4d-96a6-1961-fd29b75ea2d5/file/mp3/file.mp3	未知	0
743	Take That	51	411	164	https://data.freetouse.com/music/tracks/7a467b4c-d107-d61c-aeeb-d7a29e2a26d3/file/mp3/file.mp3	未知	0
744	Break Of Dawn	23	389	159	https://data.freetouse.com/music/tracks/c76c5b42-3e12-e70c-7b1b-f257420e0165/file/mp3/file.mp3	未知	0
745	Overtaken	33	327	131	https://data.freetouse.com/music/tracks/96ef8816-7961-5006-c2a3-fb9d9a32b177/file/mp3/file.mp3	未知	0
746	Legacy	11	364	120	https://data.freetouse.com/music/tracks/8c0c7b8e-fb04-09d1-d5ed-b527a0db803d/file/mp3/file.mp3	未知	0
747	Avocado	8	320	168	https://data.freetouse.com/music/tracks/9330b222-e965-4f35-ef42-188e002aabd6/file/mp3/file.mp3	未知	0
748	Umbrella	22	397	120	https://data.freetouse.com/music/tracks/822c7f80-232a-9dde-98a0-56e66e07fc92/file/mp3/file.mp3	未知	0
749	Guns N Roses	23	389	155	https://data.freetouse.com/music/tracks/33bb009e-39c6-823c-4937-0d004a96b3d5/file/mp3/file.mp3	未知	0
750	City Lights	22	397	174	https://data.freetouse.com/music/tracks/986319e0-3ac7-6123-f794-ca60da968aa8/file/mp3/file.mp3	未知	0
751	Lux	1	311	259	https://data.freetouse.com/music/tracks/171d5765-b546-4162-8110-a19c329da453/file/mp3/file.mp3	未知	0
752	Sprinkles	22	397	120	https://data.freetouse.com/music/tracks/8ff6b09a-e811-6cac-97f6-148db451b7a0/file/mp3/file.mp3	未知	0
753	Sleepless	22	397	173	https://data.freetouse.com/music/tracks/99b0de4d-49a1-ba52-4f78-ac20cb0c57e3/file/mp3/file.mp3	未知	0
754	Guardians	11	364	168	https://data.freetouse.com/music/tracks/bf73e6a4-b86f-c568-b077-f7aa237cf769/file/mp3/file.mp3	未知	0
755	Too Late	22	375	106	https://data.freetouse.com/music/tracks/eecb9480-d113-9306-c82f-53c571d6c517/file/mp3/file.mp3	未知	0
756	Aura	38	388	139	https://data.freetouse.com/music/tracks/8a93d279-9cbf-0b10-3672-b29654708cba/file/mp3/file.mp3	未知	0
757	Summertide	22	397	174	https://data.freetouse.com/music/tracks/3b51a997-3c4d-0db6-43df-35befe757eb3/file/mp3/file.mp3	未知	0
758	Arrival	11	364	113	https://data.freetouse.com/music/tracks/3bee4740-db28-6987-02b0-39a49235b034/file/mp3/file.mp3	未知	0
759	daydream	9	336	175	https://data.freetouse.com/music/tracks/e6207929-3a45-ea7a-9f63-5b3e3917f7dd/file/mp3/file.mp3	未知	0
760	Adventure	22	397	195	https://data.freetouse.com/music/tracks/18d05342-e857-0df7-e09c-12cec5bbcb79/file/mp3/file.mp3	未知	0
761	Just a Dream	34	334	131	https://data.freetouse.com/music/tracks/794990e3-6962-f42b-092b-ceebd62d3069/file/mp3/file.mp3	未知	0
762	Wayfarer	33	327	86	https://data.freetouse.com/music/tracks/4f9f0cf7-429c-d786-a30c-0d54bc3bcd8a/file/mp3/file.mp3	未知	0
763	Beach	38	388	149	https://data.freetouse.com/music/tracks/33d25466-d8c0-be57-e18c-19888b562092/file/mp3/file.mp3	未知	0
764	Guava	52	293	228	https://data.freetouse.com/music/tracks/59da573d-fcc9-4aae-8fd5-fc991182a099/file/mp3/file.mp3	未知	0
765	Fallen Kingdom	33	327	125	https://data.freetouse.com/music/tracks/0139921c-9c35-7dc9-7f1d-d45dd8dc6e4b/file/mp3/file.mp3	未知	0
766	Loving	8	320	111	https://data.freetouse.com/music/tracks/02ce0504-a082-5ebf-b6a2-fbe4c0a6d669/file/mp3/file.mp3	未知	0
767	Nervous	8	320	67	https://data.freetouse.com/music/tracks/a4ad2edc-4bac-b633-2493-7b810e47e3cb/file/mp3/file.mp3	未知	0
768	Relief	8	320	230	https://data.freetouse.com/music/tracks/887fc75e-4a08-e5a7-5c0a-d91856268c82/file/mp3/file.mp3	未知	0
769	Glamorous	8	320	139	https://data.freetouse.com/music/tracks/24ae4e5b-aeb4-1985-4439-a55a05f358e8/file/mp3/file.mp3	未知	0
770	Move	53	359	160	https://data.freetouse.com/music/tracks/f338707e-1261-bd5c-211c-ef5b110da5a2/file/mp3/file.mp3	未知	0
771	Mood	38	388	145	https://data.freetouse.com/music/tracks/6ecf8bdf-8b03-c473-3644-e111d3e80095/file/mp3/file.mp3	未知	0
772	Recovery	8	320	104	https://data.freetouse.com/music/tracks/0e162c5d-76f4-2c45-33de-8f7ffc177c7c/file/mp3/file.mp3	未知	0
773	Ethereum	8	320	182	https://data.freetouse.com/music/tracks/2c7112d4-8fc9-5623-dec6-259087de6eb2/file/mp3/file.mp3	未知	0
774	Rogue	8	320	134	https://data.freetouse.com/music/tracks/fbd410e0-b66c-6b09-680c-662b584ca663/file/mp3/file.mp3	未知	0
775	Serenade	8	320	111	https://data.freetouse.com/music/tracks/b0f03a9e-713a-308b-54b7-c9af41cc0a80/file/mp3/file.mp3	未知	0
776	Syndicate	8	320	175	https://data.freetouse.com/music/tracks/a7066bba-d63f-4145-2ba7-56e7e4476d50/file/mp3/file.mp3	未知	0
777	Lucifer	8	320	168	https://data.freetouse.com/music/tracks/17e59520-cfa0-b56e-810c-b5bb7fbe52ee/file/mp3/file.mp3	未知	0
778	Knockturnal	8	320	123	https://data.freetouse.com/music/tracks/ca20be48-1e75-efda-5b62-06daa1ef40f2/file/mp3/file.mp3	未知	0
779	ESTD	8	320	169	https://data.freetouse.com/music/tracks/e5bc1b26-534c-dc42-3ed4-9c0ade318b3d/file/mp3/file.mp3	未知	0
780	Journey	53	359	231	https://data.freetouse.com/music/tracks/1cb43a13-d0a3-7df7-0d53-dc6eb774c212/file/mp3/file.mp3	未知	0
781	Fun and Catchy	11	364	129	https://data.freetouse.com/music/tracks/033c56f1-eeb5-110c-aac8-8019729833e4/file/mp3/file.mp3	未知	0
782	Medieval Village	13	392	132	https://data.freetouse.com/music/tracks/706f027e-a5f1-dda5-b9fc-a36a40d66edf/file/mp3/file.mp3	未知	0
783	Destiny	11	364	150	https://data.freetouse.com/music/tracks/35870ebd-5735-4685-2e55-dd095498bdd9/file/mp3/file.mp3	未知	0
784	Lonely Samurai	13	392	148	https://data.freetouse.com/music/tracks/ec910786-00fa-aac6-491b-2aafc13e3788/file/mp3/file.mp3	未知	0
785	Tension	33	327	131	https://data.freetouse.com/music/tracks/7fb8d735-bae2-6e24-3892-686225a1babd/file/mp3/file.mp3	未知	0
786	Event	11	364	146	https://data.freetouse.com/music/tracks/76e8e1d5-4991-0975-ebae-27600f02c295/file/mp3/file.mp3	未知	0
787	Bali	13	392	157	https://data.freetouse.com/music/tracks/6b59c31c-6ee4-6de7-0fb3-023f19f310f7/file/mp3/file.mp3	未知	0
788	Heroes	38	388	163	https://data.freetouse.com/music/tracks/6d348686-f7cd-6473-10a8-27fcf21cf4e3/file/mp3/file.mp3	未知	0
789	Growing Older	33	327	80	https://data.freetouse.com/music/tracks/b88aa103-2768-acb9-ab06-d2f8848efd48/file/mp3/file.mp3	未知	0
790	Snake Charmer	13	392	120	https://data.freetouse.com/music/tracks/c2815e5b-def2-77b1-eef1-bc2167e67d85/file/mp3/file.mp3	未知	0
791	gingersweet	9	336	156	https://data.freetouse.com/music/tracks/07eb4398-8c28-b1e9-64b1-ea2dafa2af6f/file/mp3/file.mp3	未知	0
792	Next Level	51	411	153	https://data.freetouse.com/music/tracks/708b427a-3a0d-2022-2c07-326840c5cf03/file/mp3/file.mp3	未知	0
793	Freedom Motivation	13	392	126	https://data.freetouse.com/music/tracks/fd81c4fa-7070-ae39-9adf-918f487162c9/file/mp3/file.mp3	未知	0
794	Spaceship	30	300	159	https://data.freetouse.com/music/tracks/05b697d3-150a-dfbd-94ff-044d790b070a/file/mp3/file.mp3	未知	0
795	Ascend	33	327	106	https://data.freetouse.com/music/tracks/77eb7eed-1342-ee02-b7ac-5223bee955a1/file/mp3/file.mp3	未知	0
796	Romantic Love	13	392	104	https://data.freetouse.com/music/tracks/7d3d9881-50a2-f992-1ae5-286951ababa7/file/mp3/file.mp3	未知	0
797	Palms	38	388	180	https://data.freetouse.com/music/tracks/c14133a7-f73a-1904-61ec-de62959a175b/file/mp3/file.mp3	未知	0
798	Flowering	33	327	128	https://data.freetouse.com/music/tracks/f6775560-9590-4a13-1f65-7943df2a5160/file/mp3/file.mp3	未知	0
799	Road Trip	5	5	189	https://data.freetouse.com/music/tracks/125e2579-dfd1-498c-bb12-e02dd3c0cfe4/file/mp3/file.mp3	未知	0
800	Restaurant Groove	13	392	133	https://data.freetouse.com/music/tracks/01840d16-209b-d939-6333-36bfbf0546a1/file/mp3/file.mp3	未知	0
801	Firefly	35	309	103	https://data.freetouse.com/music/tracks/51be0252-6e72-3cd4-454d-706f983e4cb0/file/mp3/file.mp3	未知	0
802	Heroes	51	411	227	https://data.freetouse.com/music/tracks/78aa41e5-7ea1-f719-4c4d-7ac8be542019/file/mp3/file.mp3	未知	0
803	Rainbow	38	388	149	https://data.freetouse.com/music/tracks/4ff74d77-71b1-d66d-6d5a-eb3c33717889/file/mp3/file.mp3	未知	0
804	Timeless	33	327	120	https://data.freetouse.com/music/tracks/70a9e65c-1d42-399e-a065-d05d3fe41896/file/mp3/file.mp3	未知	0
805	Sunset Guitar	13	392	142	https://data.freetouse.com/music/tracks/14ee4879-dbfc-de63-c2c6-2b4ed60f25a7/file/mp3/file.mp3	未知	0
806	Nebula	1	311	293	https://data.freetouse.com/music/tracks/5e741a20-879c-4350-a436-68fac2fccc19/file/mp3/file.mp3	未知	0
808	Apple Tree	30	300	174	https://data.freetouse.com/music/tracks/3e636a48-05ff-96aa-1f68-afa3cfb0ddeb/file/mp3/file.mp3	未知	0
809	Summer Memories	13	392	143	https://data.freetouse.com/music/tracks/cc8a2cd7-2e24-910c-39c7-0ced8a6d3ac3/file/mp3/file.mp3	未知	0
810	Vinyl Junkie	19	318	144	https://data.freetouse.com/music/tracks/24858bff-dd3a-ead1-d930-01f869c9868e/file/mp3/file.mp3	未知	0
811	By My Side	33	327	125	https://data.freetouse.com/music/tracks/32397cf6-dee2-52ce-e633-57a28d3f8a04/file/mp3/file.mp3	未知	0
812	Playful	35	309	152	https://data.freetouse.com/music/tracks/bc3ce43a-6c19-60f5-b6cd-a9b781140f99/file/mp3/file.mp3	未知	0
813	Ibiza Vibes	13	392	131	https://data.freetouse.com/music/tracks/4c33c998-e04a-13a0-7345-b7bcd15493c1/file/mp3/file.mp3	未知	0
815	Thinking Of Me	23	389	186	https://data.freetouse.com/music/tracks/82bfb12c-6a14-8453-ff44-09076a6404ff/file/mp3/file.mp3	未知	0
816	All Night	47	324	130	https://data.freetouse.com/music/tracks/f79f8ab3-c7c8-f05d-3c41-e540470d5ee6/file/mp3/file.mp3	未知	0
817	Dance of the Seas	36	294	106	https://data.freetouse.com/music/tracks/30c83dd5-0c9e-dbfe-3a85-c941bdc8c2e5/file/mp3/file.mp3	未知	0
818	Temptations	33	327	196	https://data.freetouse.com/music/tracks/7a0fcaf4-adb3-61b7-355c-5f818ac859ed/file/mp3/file.mp3	未知	0
819	Oasis	13	392	157	https://data.freetouse.com/music/tracks/27f029b4-f1bf-d2a2-691e-ed40c6353478/file/mp3/file.mp3	未知	0
820	Fast Lane	43	360	203	https://data.freetouse.com/music/tracks/06132bd2-c544-8148-12d4-0d7e1f4e8fd0/file/mp3/file.mp3	未知	0
821	The Island	23	389	167	https://data.freetouse.com/music/tracks/ee2397c4-c4cd-b48f-9402-1fd493c8d948/file/mp3/file.mp3	未知	0
822	Respite	35	309	246	https://data.freetouse.com/music/tracks/b1bbae7d-9daf-71b9-699b-41a6505f4b7e/file/mp3/file.mp3	未知	0
823	Refresh	11	364	134	https://data.freetouse.com/music/tracks/71afbac7-591d-fe5b-6747-495d34520620/file/mp3/file.mp3	未知	0
824	When Tomorrow Comes	33	327	107	https://data.freetouse.com/music/tracks/94c59ac5-d4b8-8dec-c706-1d5ef7aa8adb/file/mp3/file.mp3	未知	0
825	Supersonic	47	324	127	https://data.freetouse.com/music/tracks/16ea1f05-33cb-2347-00d4-238a1d8b189c/file/mp3/file.mp3	未知	0
827	Sunshine	38	388	157	https://data.freetouse.com/music/tracks/38b6fc32-ccf1-f548-ebec-8fb4f9cfb440/file/mp3/file.mp3	未知	0
828	Beach Bum	54	339	181	https://data.freetouse.com/music/tracks/40c5370b-0341-722d-e275-74f6720056c2/file/mp3/file.mp3	未知	0
829	Amazing Day	11	364	109	https://data.freetouse.com/music/tracks/4d6a31ed-1514-d020-abb5-4ff05f8c4708/file/mp3/file.mp3	未知	0
830	Wandering	33	327	154	https://data.freetouse.com/music/tracks/3b50d9e7-9d1e-942b-f735-fe699531815c/file/mp3/file.mp3	未知	0
831	Chance Of Sunshine	23	389	112	https://data.freetouse.com/music/tracks/0a80a13a-ae3f-07ee-db59-86262d96dcf7/file/mp3/file.mp3	未知	0
832	Drop It	11	364	172	https://data.freetouse.com/music/tracks/9f2aa749-2e5c-7156-0be6-02b5e2d9949f/file/mp3/file.mp3	未知	0
833	Deep Thoughts	22	397	120	https://data.freetouse.com/music/tracks/804f43dc-eb28-b5fc-23fa-8f67db48d384/file/mp3/file.mp3	未知	0
834	Wooden Table	30	300	149	https://data.freetouse.com/music/tracks/2e3f9b1a-9323-75b1-8f2c-ba0b774acba7/file/mp3/file.mp3	未知	0
835	Long Road Home	33	327	114	https://data.freetouse.com/music/tracks/32aead48-d409-8755-3b19-ea70803e6b13/file/mp3/file.mp3	未知	0
836	Been Waiting	49	399	226	https://data.freetouse.com/music/tracks/e63c1269-9f12-a115-f77e-d47e33f075b7/file/mp3/file.mp3	未知	0
837	Trending	11	364	113	https://data.freetouse.com/music/tracks/923dc424-6b9f-c2ca-6205-8b057640ba22/file/mp3/file.mp3	未知	0
838	Midnight Bliss	22	397	120	https://data.freetouse.com/music/tracks/5c557a87-b788-3f09-ada6-20a480e2502a/file/mp3/file.mp3	未知	0
839	Dreams of the Future	22	397	137	https://data.freetouse.com/music/tracks/d5093bb6-c235-fc21-f3e7-f127cfb7f7a1/file/mp3/file.mp3	未知	0
840	Streetview	22	397	122	https://data.freetouse.com/music/tracks/30b86e8e-0fcf-b68e-08b9-a94789186a90/file/mp3/file.mp3	未知	0
841	Fool 4 You	23	389	141	https://data.freetouse.com/music/tracks/5697104d-3b8c-9440-0ac6-0e78782c71ef/file/mp3/file.mp3	未知	0
842	Successful	11	364	166	https://data.freetouse.com/music/tracks/54d46c91-9ed5-6620-8f1e-b4ee264bc228/file/mp3/file.mp3	未知	0
843	Warm Cup of Coffe	22	397	116	https://data.freetouse.com/music/tracks/d3c93e78-d827-8bc6-ce02-8441a0d886d3/file/mp3/file.mp3	未知	0
844	Sunbeams	22	397	127	https://data.freetouse.com/music/tracks/7d1e6aaf-f28c-e998-02fa-a81b8dc3a307/file/mp3/file.mp3	未知	0
845	Downfall	33	327	76	https://data.freetouse.com/music/tracks/be2955d4-6bd5-22e5-bda9-2f223e50f906/file/mp3/file.mp3	未知	0
846	Feelings	36	294	167	https://data.freetouse.com/music/tracks/360d3763-ddd7-3278-e89a-7eb43dcdbaee/file/mp3/file.mp3	未知	0
848	Brand	11	364	137	https://data.freetouse.com/music/tracks/3e0e95db-e341-5589-8fe4-1211ad00b35d/file/mp3/file.mp3	未知	0
849	Oveza	22	397	136	https://data.freetouse.com/music/tracks/90e167d4-502c-218b-e411-5a95ee83a857/file/mp3/file.mp3	未知	0
850	Big Waves	23	389	185	https://data.freetouse.com/music/tracks/ead525bd-ea89-e354-1b51-e3834dcd24e3/file/mp3/file.mp3	未知	0
851	Like You	22	397	123	https://data.freetouse.com/music/tracks/3b15a174-795f-8815-f620-ec9c756e433a/file/mp3/file.mp3	未知	0
852	Wallflower	33	327	106	https://data.freetouse.com/music/tracks/c5169269-9c67-9dbe-22c5-226790361349/file/mp3/file.mp3	未知	0
853	Rainy Day	35	309	111	https://data.freetouse.com/music/tracks/fda176af-8cc3-60f9-9d81-9f2ab9784af3/file/mp3/file.mp3	未知	0
854	Lets Go	22	397	112	https://data.freetouse.com/music/tracks/bbe8afe7-e4ca-fa78-5571-621d1d8baaec/file/mp3/file.mp3	未知	0
855	swing	9	336	141	https://data.freetouse.com/music/tracks/a6aadf90-330f-1f9b-edd8-ca3a01753d87/file/mp3/file.mp3	未知	0
856	Paradise Palms	22	397	143	https://data.freetouse.com/music/tracks/28fb96a3-0b70-a45f-f009-ffb49e54ad77/file/mp3/file.mp3	未知	0
857	Seller	11	364	118	https://data.freetouse.com/music/tracks/fd429366-9232-0aa5-eba9-353485786df0/file/mp3/file.mp3	未知	0
858	Night Drive	13	392	138	https://data.freetouse.com/music/tracks/472fc995-d3d1-0434-aede-b570af377a8f/file/mp3/file.mp3	未知	0
859	Bon Aleè	22	397	127	https://data.freetouse.com/music/tracks/185fed25-e4b6-7b77-750f-e0ae555b95be/file/mp3/file.mp3	未知	0
860	Sweetest Love	23	389	169	https://data.freetouse.com/music/tracks/cb1d6a8c-1f46-d0ec-60e7-3c5e821de6fc/file/mp3/file.mp3	未知	0
861	Woali	22	397	131	https://data.freetouse.com/music/tracks/90df396d-86b3-274a-8c6e-27a17e1e5f42/file/mp3/file.mp3	未知	0
862	Futuristic	11	364	144	https://data.freetouse.com/music/tracks/983e2d81-11d8-a819-cf44-9eb3e3d6569b/file/mp3/file.mp3	未知	0
863	Flower Cup	30	300	176	https://data.freetouse.com/music/tracks/07ce4507-fa07-341e-4cd3-6acc0d0ff912/file/mp3/file.mp3	未知	0
864	Force	41	321	147	https://data.freetouse.com/music/tracks/ce9f9792-14ad-2814-0f92-af8719688011/file/mp3/file.mp3	未知	0
865	Social Network	11	364	150	https://data.freetouse.com/music/tracks/6ee5ae67-e4f9-a203-83f6-182e8c088e14/file/mp3/file.mp3	未知	0
866	Without You	23	389	188	https://data.freetouse.com/music/tracks/ac4a23c2-87d2-a854-53a0-1a4aed9467ce/file/mp3/file.mp3	未知	0
867	Winter Wind	33	327	118	https://data.freetouse.com/music/tracks/c9245f7a-185b-27e0-6692-80095cc0a0bb/file/mp3/file.mp3	未知	0
868	Rave	13	392	122	https://data.freetouse.com/music/tracks/a8f2adc0-657d-5714-c776-c037d243a3b1/file/mp3/file.mp3	未知	0
869	AI Technology	11	364	138	https://data.freetouse.com/music/tracks/8d9fd8f2-2306-7a3c-1da3-d9775a999dd8/file/mp3/file.mp3	未知	0
870	Loving You	23	389	166	https://data.freetouse.com/music/tracks/ad011d08-b5a5-0009-0393-be7025967508/file/mp3/file.mp3	未知	0
871	Good Days	11	364	119	https://data.freetouse.com/music/tracks/7576094e-6000-f551-08b6-85e9111cf4f0/file/mp3/file.mp3	未知	0
872	Aftermath	33	327	133	https://data.freetouse.com/music/tracks/7adf492c-a9f1-ab02-5d44-ef8b9200bf8f/file/mp3/file.mp3	未知	0
873	Hold You	50	302	154	https://data.freetouse.com/music/tracks/670c3da6-0135-887a-2984-ae90b756bd1b/file/mp3/file.mp3	未知	0
874	Driving	23	389	161	https://data.freetouse.com/music/tracks/f0884001-254e-ba1b-1487-d39b87d40552/file/mp3/file.mp3	未知	0
875	Growth	36	294	111	https://data.freetouse.com/music/tracks/26a9f7c7-e964-8366-f267-b9f0123fde76/file/mp3/file.mp3	未知	0
876	Take It Easy	6	408	171	https://data.freetouse.com/music/tracks/ca6ee5f0-4f28-8554-f32d-9fbc95915c5d/file/mp3/file.mp3	未知	0
877	Distant River	33	327	107	https://data.freetouse.com/music/tracks/b0051873-c401-bf1c-1933-6b14a8386eed/file/mp3/file.mp3	未知	0
878	Gloomy Morning	35	309	116	https://data.freetouse.com/music/tracks/cd1dab3b-38a9-75fa-fda7-8f2ec9ed6b44/file/mp3/file.mp3	未知	0
879	Vlogs	11	364	89	https://data.freetouse.com/music/tracks/68fe7ce3-7689-3b31-2399-0fe1ae3de2c2/file/mp3/file.mp3	未知	0
880	Forward	41	321	200	https://data.freetouse.com/music/tracks/05e1f8c6-7bce-50d3-3e36-35beb18d997a/file/mp3/file.mp3	未知	0
881	Waterfall	34	334	161	https://data.freetouse.com/music/tracks/740c14f1-f660-952f-cf8e-0c58c25916ab/file/mp3/file.mp3	未知	0
882	Last Chance	55	329	141	https://data.freetouse.com/music/tracks/da48f9a9-d852-2730-cca3-16d7d9b14c06/file/mp3/file.mp3	未知	0
883	Spring Wind	36	294	137	https://data.freetouse.com/music/tracks/2213531e-5a01-ea26-c556-df37b0b2e745/file/mp3/file.mp3	未知	0
884	Engineering	11	364	126	https://data.freetouse.com/music/tracks/9d2d8a9a-f277-8f62-0258-bca81a758be7/file/mp3/file.mp3	未知	0
886	Blast	11	364	111	https://data.freetouse.com/music/tracks/67bf868c-e469-b259-cd45-adcc9fcd895d/file/mp3/file.mp3	未知	0
887	Hope	50	302	140	https://data.freetouse.com/music/tracks/dfe4be50-953a-24e1-62ca-b7959ceaf604/file/mp3/file.mp3	未知	0
888	Tropical Ukulele	11	364	113	https://data.freetouse.com/music/tracks/29cd5815-a8dd-7ed7-55cf-0721f9bcfa75/file/mp3/file.mp3	未知	0
889	Digital	11	364	142	https://data.freetouse.com/music/tracks/d8443b05-06fe-d709-c9b5-a3280f86ea56/file/mp3/file.mp3	未知	0
890	Found You	55	329	144	https://data.freetouse.com/music/tracks/eec3a813-091f-468c-c6b2-4e5893bbea82/file/mp3/file.mp3	未知	0
891	Sounds of Nature	11	364	209	https://data.freetouse.com/music/tracks/39e7afc7-b515-e275-63bc-bc5a43a5664c/file/mp3/file.mp3	未知	0
892	Running	35	309	110	https://data.freetouse.com/music/tracks/3b1575b1-0c94-aa1c-b22d-0709a2e21294/file/mp3/file.mp3	未知	0
894	Business	11	364	155	https://data.freetouse.com/music/tracks/50b174e3-ef36-a2e5-4616-82b5f6e0c9f5/file/mp3/file.mp3	未知	0
895	Live It	11	364	126	https://data.freetouse.com/music/tracks/e494ecab-71b7-7ee0-97d1-932e855fe7cb/file/mp3/file.mp3	未知	0
896	Ethereal	35	309	150	https://data.freetouse.com/music/tracks/9d30191f-ffd5-34f3-f301-fa940064ebeb/file/mp3/file.mp3	未知	0
897	Domino	56	400	139	https://data.freetouse.com/music/tracks/9f87b933-6944-f131-f536-1370fc4b45a4/file/mp3/file.mp3	未知	0
898	Summer Party	11	364	132	https://data.freetouse.com/music/tracks/fb743f1b-7577-8ea9-ce23-ba44996b8d39/file/mp3/file.mp3	未知	0
899	Cozy	57	372	131	https://data.freetouse.com/music/tracks/4fd1f005-cf56-e56f-e3a3-317f012f6ab1/file/mp3/file.mp3	未知	0
900	Room Tour	11	364	114	https://data.freetouse.com/music/tracks/1d7741e4-9f34-360d-722b-9c5d294b8f51/file/mp3/file.mp3	未知	0
901	Perfect Timing	35	309	117	https://data.freetouse.com/music/tracks/8dab8bea-388c-3815-0852-b08ed2580543/file/mp3/file.mp3	未知	0
902	lush	9	336	147	https://data.freetouse.com/music/tracks/ea5dcd08-57c5-ff05-c0c9-68dd2915b668/file/mp3/file.mp3	未知	0
903	Off Road	11	364	106	https://data.freetouse.com/music/tracks/1506d0f6-94f6-f604-46b6-2149c62efe14/file/mp3/file.mp3	未知	0
904	Floating	56	400	128	https://data.freetouse.com/music/tracks/83001df2-4688-eb24-2806-af8fef28faf6/file/mp3/file.mp3	未知	0
905	Hot	11	364	96	https://data.freetouse.com/music/tracks/dff9310c-26da-1071-1c94-1b2937cef0f9/file/mp3/file.mp3	未知	0
906	Beach Life	43	360	206	https://data.freetouse.com/music/tracks/79d68e73-dee3-f07e-c2a1-af6ac1585549/file/mp3/file.mp3	未知	0
907	Happiness	11	364	116	https://data.freetouse.com/music/tracks/3627351d-8f40-25c6-bb63-fd2dcd70c477/file/mp3/file.mp3	未知	0
908	Travelling	11	364	177	https://data.freetouse.com/music/tracks/323e7d9d-80f9-fbc5-510a-77aadaf53209/file/mp3/file.mp3	未知	0
909	Desert Caravan	13	392	137	https://data.freetouse.com/music/tracks/f23ae924-6941-b4e5-6add-1c68478762fe/file/mp3/file.mp3	未知	0
910	Happy Moments	11	364	146	https://data.freetouse.com/music/tracks/2811bd91-52c0-72a3-7e82-9cb096ffbad3/file/mp3/file.mp3	未知	0
911	Moonshine	43	360	196	https://data.freetouse.com/music/tracks/4992bcb6-427b-d41f-7efd-56ce6f689587/file/mp3/file.mp3	未知	0
912	Shoreline	34	334	196	https://data.freetouse.com/music/tracks/defd1b75-ec36-127c-4e84-781fcf202055/file/mp3/file.mp3	未知	0
913	Pastry	11	364	108	https://data.freetouse.com/music/tracks/da45ae0f-6ec0-3e1d-f547-018ce49449aa/file/mp3/file.mp3	未知	0
915	Running	13	392	97	https://data.freetouse.com/music/tracks/7c13bd9c-a6ed-7c3f-c735-1affaf744dfd/file/mp3/file.mp3	未知	0
916	Cute Animals	11	364	154	https://data.freetouse.com/music/tracks/03ca3367-3354-dd12-c92f-6dd3067c809c/file/mp3/file.mp3	未知	0
917	Sport Power	13	392	128	https://data.freetouse.com/music/tracks/b56cfc25-a61f-71d4-82a5-6f2cea03ad06/file/mp3/file.mp3	未知	0
918	Happy Day	11	364	153	https://data.freetouse.com/music/tracks/2208dafc-9627-b6e0-147f-7979ea17ab95/file/mp3/file.mp3	未知	0
919	Lagoon	34	334	154	https://data.freetouse.com/music/tracks/9624e7cd-9ba5-0dd4-ab9a-c35a1f1a38a1/file/mp3/file.mp3	未知	0
920	Carnival	11	364	111	https://data.freetouse.com/music/tracks/7d3c789d-01ea-0f8e-bff0-782f956fd03b/file/mp3/file.mp3	未知	0
921	Western	13	392	156	https://data.freetouse.com/music/tracks/8cc42389-f3a6-30b6-2feb-7170eb0928c8/file/mp3/file.mp3	未知	0
922	Sunset Sadness	36	294	130	https://data.freetouse.com/music/tracks/cb062c7b-555b-ac4b-899c-862b1e78869d/file/mp3/file.mp3	未知	0
923	Chinese Traditions	11	364	111	https://data.freetouse.com/music/tracks/928cca2b-6f68-9959-3e77-4c17c711c70e/file/mp3/file.mp3	未知	0
924	Nobody	19	318	247	https://data.freetouse.com/music/tracks/3c0fadbf-8985-39c4-e086-c7d825e6d89a/file/mp3/file.mp3	未知	0
925	Play	13	392	155	https://data.freetouse.com/music/tracks/b66d8218-e10c-10ff-1e62-7a462e6bb2d0/file/mp3/file.mp3	未知	0
926	Taste	35	309	118	https://data.freetouse.com/music/tracks/75f5dd82-44ef-d282-0b67-737a94fa4204/file/mp3/file.mp3	未知	0
927	Rejuvenate	36	294	130	https://data.freetouse.com/music/tracks/8042be1a-8b3e-d9f6-e394-ac3ceea32be2/file/mp3/file.mp3	未知	0
928	Sunday Sessions	19	318	136	https://data.freetouse.com/music/tracks/e8a288f2-1bd9-e30a-0a24-e88bfbadb13e/file/mp3/file.mp3	未知	0
929	Burning	13	392	127	https://data.freetouse.com/music/tracks/ba3b92e2-2e40-5514-beef-46009d8cdd83/file/mp3/file.mp3	未知	0
930	Within Us	33	327	87	https://data.freetouse.com/music/tracks/30ac49c5-3257-4e6d-6c74-672ae0f0a7b7/file/mp3/file.mp3	未知	0
931	Happy Chinese New Year	11	364	161	https://data.freetouse.com/music/tracks/02829ad6-42bc-9b3e-8f36-6ceec52eadae/file/mp3/file.mp3	未知	0
932	9am, meeeh	18	370	206	https://data.freetouse.com/music/tracks/fcd4ca38-da20-0f15-a371-01f4e0fbd2fa/file/mp3/file.mp3	未知	0
933	11pm, gurgle gurgle	18	370	163	https://data.freetouse.com/music/tracks/949d3d49-47c7-a787-f866-6313cdaca61c/file/mp3/file.mp3	未知	0
934	3pm, moshi moshi	18	370	171	https://data.freetouse.com/music/tracks/86ee33ed-78bd-c081-007f-a090724f0c99/file/mp3/file.mp3	未知	0
935	Imperfections	19	318	256	https://data.freetouse.com/music/tracks/ed51b231-2718-dbc2-9211-185af1ee5470/file/mp3/file.mp3	未知	0
936	The Waiting	58	310	139	https://data.freetouse.com/music/tracks/e37a0fde-6b68-2bb0-fb27-784077f985cc/file/mp3/file.mp3	未知	0
937	Spiral of Time	58	310	124	https://data.freetouse.com/music/tracks/0860caa4-d473-803c-4e3b-934e9abd24cb/file/mp3/file.mp3	未知	0
938	Riding South	58	310	133	https://data.freetouse.com/music/tracks/d1962bcb-92e0-42b3-d0cf-4819d031e93a/file/mp3/file.mp3	未知	0
939	Rays of Light	58	310	134	https://data.freetouse.com/music/tracks/873a854c-22f7-6a16-2aae-e0bf5c9cea8d/file/mp3/file.mp3	未知	0
940	glisten	9	336	151	https://data.freetouse.com/music/tracks/67ccf3a3-097b-8dc0-cbc5-e2ac25745068/file/mp3/file.mp3	未知	0
941	Joshua Tree	58	310	150	https://data.freetouse.com/music/tracks/acffc6ff-ecec-9217-c532-6ddd1b506283/file/mp3/file.mp3	未知	0
942	Farewell	58	310	127	https://data.freetouse.com/music/tracks/971f7872-6b99-c9f3-5875-951870f4f403/file/mp3/file.mp3	未知	0
943	Above All	58	310	172	https://data.freetouse.com/music/tracks/fcd76163-3945-ea4f-d8f7-1021c92131f4/file/mp3/file.mp3	未知	0
944	End of Times	58	310	143	https://data.freetouse.com/music/tracks/fd016620-4217-6298-d967-960cd19a58eb/file/mp3/file.mp3	未知	0
945	Libellule	58	310	189	https://data.freetouse.com/music/tracks/a1e2f2ed-6e08-39d9-f936-b3d0009b2d77/file/mp3/file.mp3	未知	0
946	Lemonade	36	294	137	https://data.freetouse.com/music/tracks/7a474d9c-1b2c-3889-74a0-3ea55d67588e/file/mp3/file.mp3	未知	0
947	Urban Journey	11	364	124	https://data.freetouse.com/music/tracks/b766bd25-6b85-b727-077d-6c742421f768/file/mp3/file.mp3	未知	0
949	Dreams of Tomorrow	47	324	158	https://data.freetouse.com/music/tracks/c8365103-2d41-52b8-d912-45a74df47c83/file/mp3/file.mp3	未知	0
950	Epic Motivation	11	364	140	https://data.freetouse.com/music/tracks/afe87210-8a89-2e6a-e5e2-55dcb1775ec3/file/mp3/file.mp3	未知	0
951	Acoustic Heaven	58	310	177	https://data.freetouse.com/music/tracks/353d9dce-7e9a-b136-330f-3a532b28d512/file/mp3/file.mp3	未知	0
952	Like You Mean It	47	324	128	https://data.freetouse.com/music/tracks/4488447b-2571-249a-c60f-1a6565f3455d/file/mp3/file.mp3	未知	0
953	Sticks & Stones	59	343	148	https://data.freetouse.com/music/tracks/ef6c8300-ddae-403b-9f36-2e252ed03280/file/mp3/file.mp3	未知	0
954	A Sweet Story	58	310	134	https://data.freetouse.com/music/tracks/1378cc91-134c-1aba-eccd-469f9bcf1619/file/mp3/file.mp3	未知	0
955	Christmas Miracle	13	392	129	https://data.freetouse.com/music/tracks/4c0d4de9-491b-1b43-c794-7481d0531e8a/file/mp3/file.mp3	未知	0
956	Fashion Jive	47	324	133	https://data.freetouse.com/music/tracks/ea5df505-0935-386f-5e10-63790634d5f1/file/mp3/file.mp3	未知	0
957	Market	11	364	166	https://data.freetouse.com/music/tracks/14274297-cc1a-bb36-b64d-07644482486f/file/mp3/file.mp3	未知	0
959	Fiji	50	302	147	https://data.freetouse.com/music/tracks/3bd00443-06bc-71e1-5c39-6eec2323ad66/file/mp3/file.mp3	未知	0
960	noon	9	336	188	https://data.freetouse.com/music/tracks/202f6745-784e-97aa-73c5-50653f5bdf16/file/mp3/file.mp3	未知	0
961	Flicker	47	324	127	https://data.freetouse.com/music/tracks/205b1521-1a94-2a0b-d053-295f314e8f6e/file/mp3/file.mp3	未知	0
962	Reels	11	364	131	https://data.freetouse.com/music/tracks/2d44c75b-6c45-3573-a649-769d068e8b73/file/mp3/file.mp3	未知	0
963	Snap Your Fingers	11	364	68	https://data.freetouse.com/music/tracks/bf10318d-acb3-6542-7b8c-248b65abd669/file/mp3/file.mp3	未知	0
964	In Your Eyes	13	392	136	https://data.freetouse.com/music/tracks/76d82c83-19b3-91da-d450-16cc843d6f30/file/mp3/file.mp3	未知	0
965	Nighttime	1	311	140	https://data.freetouse.com/music/tracks/33173ba5-a7d7-4c62-aa76-5d7125ce212e/file/mp3/file.mp3	未知	0
966	Heaven	11	364	198	https://data.freetouse.com/music/tracks/6822ff47-c01a-6054-a648-76cd59d38bf5/file/mp3/file.mp3	未知	0
967	Homesick	60	328	178	https://data.freetouse.com/music/tracks/fb40b3da-4c42-005e-069d-11b55297032a/file/mp3/file.mp3	未知	0
968	Triumph	47	324	139	https://data.freetouse.com/music/tracks/52f9571c-44a4-97bc-0e26-d8d5b3542ae1/file/mp3/file.mp3	未知	0
969	chamomile	9	336	152	https://data.freetouse.com/music/tracks/b11211ec-fd3e-b38f-db96-4286bafea680/file/mp3/file.mp3	未知	0
970	Blue Fields	43	360	232	https://data.freetouse.com/music/tracks/575d2935-192f-612d-08b3-d822d1757748/file/mp3/file.mp3	未知	0
971	Time Slip	47	324	121	https://data.freetouse.com/music/tracks/7260971e-9849-8d5e-e710-bd9bae49e33c/file/mp3/file.mp3	未知	0
972	Take It Slow	40	306	165	https://data.freetouse.com/music/tracks/1cc6c0a8-58d1-63af-e3b7-5d4ecd8da36e/file/mp3/file.mp3	未知	0
973	Passing Time	34	334	174	https://data.freetouse.com/music/tracks/6f9516bd-ec8d-527e-30a7-9b25d028829e/file/mp3/file.mp3	未知	0
974	Space	41	321	162	https://data.freetouse.com/music/tracks/720f3b85-2cbc-9e54-8dca-9ffb2f60b13f/file/mp3/file.mp3	未知	0
975	Voyager	19	318	184	https://data.freetouse.com/music/tracks/4e8cad67-088e-3792-5ca7-5fa478ac7f1e/file/mp3/file.mp3	未知	0
976	Mirrorball	47	324	111	https://data.freetouse.com/music/tracks/eed25eee-f604-e37b-727a-3deb70e44b54/file/mp3/file.mp3	未知	0
977	Get Yours, Get Out	47	324	135	https://data.freetouse.com/music/tracks/55565d5d-a311-accd-3e21-95f58f2b829f/file/mp3/file.mp3	未知	0
978	Get It	11	364	108	https://data.freetouse.com/music/tracks/47747de2-1833-6493-70a4-b8bec20f6712/file/mp3/file.mp3	未知	0
979	Legacies	11	364	106	https://data.freetouse.com/music/tracks/e0e4862a-46c1-c54d-b376-5471540ff11c/file/mp3/file.mp3	未知	0
980	Hot Mocha	30	300	135	https://data.freetouse.com/music/tracks/f926dcd5-31ef-08b1-db52-e6bb941e60d9/file/mp3/file.mp3	未知	0
981	Tea Cozy	30	300	158	https://data.freetouse.com/music/tracks/4d98d270-65ba-c78a-f7f1-bf5f5a5ca7ba/file/mp3/file.mp3	未知	0
982	Wintry Street	30	300	120	https://data.freetouse.com/music/tracks/6eb71ddf-28d9-9085-c090-b8c051e4b712/file/mp3/file.mp3	未知	0
983	Hello	30	300	141	https://data.freetouse.com/music/tracks/d9494571-916b-5320-dd43-d889bc9230fc/file/mp3/file.mp3	未知	0
984	Train Covered In White	30	300	156	https://data.freetouse.com/music/tracks/0797bde3-5cd8-3588-be58-8b9aed88017f/file/mp3/file.mp3	未知	0
985	Concierge Lounge	30	300	171	https://data.freetouse.com/music/tracks/f872f6c8-2bb9-561d-67cb-0c71136afc7a/file/mp3/file.mp3	未知	0
986	Vintage Store	30	300	151	https://data.freetouse.com/music/tracks/8bb7ab60-c980-1ceb-37ee-398e9fb397b5/file/mp3/file.mp3	未知	0
987	Snow Walk	30	300	98	https://data.freetouse.com/music/tracks/cd7a8866-7015-7906-dec1-7a8107fc68bb/file/mp3/file.mp3	未知	0
988	Until Late At Night	30	300	98	https://data.freetouse.com/music/tracks/82f27d06-0f49-5c42-183d-80f736a4d93e/file/mp3/file.mp3	未知	0
989	I Snowboard	30	300	156	https://data.freetouse.com/music/tracks/ae9faa8c-961d-7039-2b78-c104304e08ab/file/mp3/file.mp3	未知	0
990	Early Morning In Winter	30	300	96	https://data.freetouse.com/music/tracks/059ce49c-50c6-cdda-ddb0-9f8fb3d655fb/file/mp3/file.mp3	未知	0
992	Tell Me	47	324	141	https://data.freetouse.com/music/tracks/4e451dd5-8955-5804-8ede-abeadb65c913/file/mp3/file.mp3	未知	0
993	Tech Village	11	364	96	https://data.freetouse.com/music/tracks/1851e407-207a-7f3c-5f1b-a683ed246927/file/mp3/file.mp3	未知	0
994	Falling	43	360	174	https://data.freetouse.com/music/tracks/159a51ba-bc7d-6e53-c8a2-7bdbfef5c129/file/mp3/file.mp3	未知	0
995	Storm	11	364	99	https://data.freetouse.com/music/tracks/92472de0-c0eb-4644-9637-209b6c204ff1/file/mp3/file.mp3	未知	0
996	Office	35	309	148	https://data.freetouse.com/music/tracks/5317074a-f175-00ae-2418-108b0e6a3d95/file/mp3/file.mp3	未知	0
997	Ignition	47	324	137	https://data.freetouse.com/music/tracks/0298d931-7319-9e46-fd2d-f1347efb5fdc/file/mp3/file.mp3	未知	0
998	aromatic	9	336	155	https://data.freetouse.com/music/tracks/216a2e13-dc5d-4e83-fe85-3e3fa1dfb1ba/file/mp3/file.mp3	未知	0
999	Whispers	61	313	228	https://data.freetouse.com/music/tracks/5b6a7700-66bb-c252-c90f-f59220c5e7d9/file/mp3/file.mp3	未知	0
1000	Sunlight	62	338	196	https://data.freetouse.com/music/tracks/5d74da71-f734-07b9-5ab9-39545dc6416c/file/mp3/file.mp3	未知	0
1875	maniac	64	416	1	audios/adcce6c5-3dbc-4754-9f3f-2e1605c77a45.mp3	未知	0
128	Purity	11	364	179	https://data.freetouse.com/music/tracks/e2e9e93c-0eb2-4db5-ab50-34cd0d7a3813/file/mp3/file.mp3	未知	0
213	Turn It Louder	11	364	131	https://data.freetouse.com/music/tracks/1303f407-26b2-4971-87fa-64072b18138b/file/mp3/file.mp3	未知	0
269	Tides & Smiles	22	298	79	https://data.freetouse.com/music/tracks/6c0ba5ed-22fa-413e-82e8-89976eda06bd/file/mp3/file.mp3	未知	0
275	Pulse Mechanics	25	377	101	https://data.freetouse.com/music/tracks/8ab003f9-4dbe-4de0-9cc7-3563b21ef46a/file/mp3/file.mp3	未知	0
304	Machine Head	1	1	103	https://data.freetouse.com/music/tracks/7a092607-7a8c-4dfb-bcaa-9c81e6c09fd4/file/mp3/file.mp3	未知	0
325	The Era of Rock	8	366	207	https://data.freetouse.com/music/tracks/dff10ecb-176f-441f-95e5-7fdd3209598f/file/mp3/file.mp3	未知	0
329	Cuckoo	1	340	69	https://data.freetouse.com/music/tracks/37f1982b-2c6c-4a3d-893d-0b5c14a23d15/file/mp3/file.mp3	未知	0
359	Whales	1	332	317	https://data.freetouse.com/music/tracks/a59b2be2-a8de-42cb-898c-2d3e5bc9fd80/file/mp3/file.mp3	未知	0
408	Sunny Vibes	7	315	124	https://data.freetouse.com/music/tracks/5f11ae49-f022-4b27-9564-d2a591b60907/file/mp3/file.mp3	未知	0
416	Afternoon Coffee	7	315	132	https://data.freetouse.com/music/tracks/90368336-d39f-4298-96a8-feaa5c550425/file/mp3/file.mp3	未知	0
419	Blacksmith	31	304	96	https://data.freetouse.com/music/tracks/d11621ca-6bc4-4e2f-969d-3d7238864935/file/mp3/file.mp3	未知	0
434	Prepare	22	375	146	https://data.freetouse.com/music/tracks/663cd1e1-9f2b-4a6f-8e88-c3ebc487ba29/file/mp3/file.mp3	未知	0
559	Breeze	22	397	155	https://data.freetouse.com/music/tracks/8d9831ad-ab21-46a2-9291-bfb336e1f2ff/file/mp3/file.mp3	未知	0
588	Fancy Park	18	370	192	https://data.freetouse.com/music/tracks/d8c593e3-0753-4a39-a919-756ea8e58a7b/file/mp3/file.mp3	未知	0
689	Summer Night	22	397	107	https://data.freetouse.com/music/tracks/5f31efb3-fb72-1cba-c091-5f702592598a/file/mp3/file.mp3	未知	0
826	Surfing	1	311	61	https://data.freetouse.com/music/tracks/80f083b1-cc7f-46ff-881b-5d8612241fde/file/mp3/file.mp3	未知	0
847	Greece	22	397	121	https://data.freetouse.com/music/tracks/3ac7e5f0-18ce-f096-760b-c495458f4c60/file/mp3/file.mp3	未知	0
885	1998	6	408	118	https://data.freetouse.com/music/tracks/8be47368-883c-d9d1-953c-f0e6a3991b95/file/mp3/file.mp3	未知	0
893	Beach	11	364	181	https://data.freetouse.com/music/tracks/f5480a3e-77cd-2ade-6635-79b2cec1cbc3/file/mp3/file.mp3	未知	0
958	Christmas	11	364	118	https://data.freetouse.com/music/tracks/d1acdc98-bc22-11aa-4015-8116e10bef8e/file/mp3/file.mp3	未知	0
991	I Can't Feel	11	364	175	https://data.freetouse.com/music/tracks/60b184b9-ba2f-1444-998a-bf0b0c496d62/file/mp3/file.mp3	未知	0
814	Sun	38	388	190	https://data.freetouse.com/music/tracks/f820f095-189b-f144-0c2a-ed6f21054404/file/mp3/file.mp3	未知	0
335	Espresso Loop	23	23	117	https://data.freetouse.com/music/tracks/c0d924fd-9d06-4958-bdd2-d54c9fbae7f0/file/mp3/file.mp3	未知	0
73	Titanium	10	382	141	https://data.freetouse.com/music/tracks/09981b4e-07f8-4bdb-a36d-32819e8db413/file/mp3/file.mp3	未知	0
133	Valhalla	11	387	168	https://data.freetouse.com/music/tracks/ae9ab086-6e30-498c-9df2-d4805f4b3c93/file/mp3/file.mp3	未知	0
160	Innovation Flow	2	356	121	https://data.freetouse.com/music/tracks/b4df2f01-b857-4911-b443-273caeebac43/file/mp3/file.mp3	未知	0
280	Digital Horizons	2	367	144	https://data.freetouse.com/music/tracks/0419ab14-c38f-4be4-afdc-20d9e30da050/file/mp3/file.mp3	未知	0
371	Moonlight Tribal Carnival	18	297	128	https://data.freetouse.com/music/tracks/db75c5a4-c0b9-4d46-ae33-d356ab03b816/file/mp3/file.mp3	未知	0
436	A Beautiful Garden	7	315	132	https://data.freetouse.com/music/tracks/9fc7d845-8ed9-4bda-9ff9-9e428aaaf85e/file/mp3/file.mp3	未知	1
450	Swing	8	320	127	https://data.freetouse.com/music/tracks/8c3a8d02-c689-45c6-b7e4-2af7cbfe20ed/file/mp3/file.mp3	未知	0
451	Energy	38	388	170	https://data.freetouse.com/music/tracks/9429d4b1-34a2-4a9c-bbda-a9bfe62b9c85/file/mp3/file.mp3	未知	0
583	Christmas Eve	11	364	129	https://data.freetouse.com/music/tracks/865d304c-4e58-4a5f-aad7-992000a9c02d/file/mp3/file.mp3	未知	0
592	Feliz Navidad	33	327	121	https://data.freetouse.com/music/tracks/d2df3e59-a469-4f4c-8b98-8865204f0692/file/mp3/file.mp3	未知	0
639	Morning Sun	48	295	172	https://data.freetouse.com/music/tracks/a3e906d3-a120-cd73-2008-f5669aa769a7/file/mp3/file.mp3	未知	0
690	Lost Treasure	34	334	151	https://data.freetouse.com/music/tracks/fa8be536-fe39-a7a9-1f1e-d0ccb84d33eb/file/mp3/file.mp3	未知	0
700	Oceanfront	36	294	142	https://data.freetouse.com/music/tracks/38c42d27-2aab-fc3c-dc6a-3d2fc7380c6a/file/mp3/file.mp3	未知	0
724	Golden Hour	13	392	162	https://data.freetouse.com/music/tracks/87e2d203-eee9-e504-66fb-9bec9cc372c7/file/mp3/file.mp3	未知	0
807	Waking Up	36	294	134	https://data.freetouse.com/music/tracks/89aeef2e-fe4c-b14f-a5a8-59c4046cb926/file/mp3/file.mp3	未知	0
914	Gameboy	13	392	99	https://data.freetouse.com/music/tracks/a26d27b1-8b82-c165-eb24-b20d1fa4d661/file/mp3/file.mp3	未知	0
948	Appalachian Trail	58	310	127	https://data.freetouse.com/music/tracks/0c7a9f3f-e546-fb4a-298b-9fd31d2e7026/file/mp3/file.mp3	未知	0
\.
;

--
-- Name: songs_song_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('songs_song_id_seq', 1875, true);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (user_id, username, password_hash, role, bio, avatar_url, created_at) FROM stdin;
1	admin	pbkdf2:sha256:1000000$dxRvg4193UDtpMxi$661a129be73d371cd2d0a1af494f8fa9d9518f1d2aeed9fbc99fbb82db4068c1	sys_admin	\N	\N	2026-05-22 02:59:44.423878
2	test_listener	pbkdf2:sha256:1000000$fBjxrfOHMjlz6Fjh$c4338ab04175adebe0d0f3061c5ab02ab670d47813351059e3610f3acadfd61d	listener	\N	\N	2026-05-22 03:12:10.295304
4	test_music_admin	pbkdf2:sha256:1000000$UFbV5S3HiNAh759v$5fce066468586b14de537e5859f564808d27c212a8769594d0d11e3bcc0311a9	music_admin	\N	\N	2026-05-22 03:48:25.641138
5	lili	pbkdf2:sha256:1000000$EQPtyMYPTsGhB6vK$8f04cdee88cb598efdb769af7927eb850750899dcfdf6e5a8a6ac23eed9ce9dc	listener	\N	\N	2026-05-28 01:39:02.762742
7	lili2	pbkdf2:sha256:1000000$LAjEXwrpcAKOSCUk$75598b77613fab15fd5b455db104f4e1c6849f2798851039f3184e15860d7fb1	listener	\N	\N	2026-05-28 02:30:36.763695
\.
;

--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('users_user_id_seq', 7, true);


--
-- Name: albums_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY  (album_id);


--
-- Name: albums_title_artist_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE albums
    ADD CONSTRAINT albums_title_artist_id_key UNIQUE (title, artist_id);


--
-- Name: artists_name_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE artists
    ADD CONSTRAINT artists_name_key UNIQUE (name);


--
-- Name: artists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE artists
    ADD CONSTRAINT artists_pkey PRIMARY KEY  (artist_id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY  (comment_id);


--
-- Name: playlist_songs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE playlist_songs
    ADD CONSTRAINT playlist_songs_pkey PRIMARY KEY  (playlist_id, song_id);


--
-- Name: playlists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY  (playlist_id);


--
-- Name: post_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE post_comments
    ADD CONSTRAINT post_comments_pkey PRIMARY KEY  (pcomment_id);


--
-- Name: posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY  (post_id);


--
-- Name: songs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE songs
    ADD CONSTRAINT songs_pkey PRIMARY KEY  (song_id);


--
-- Name: songs_title_artist_id_album_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE songs
    ADD CONSTRAINT songs_title_artist_id_album_id_key UNIQUE (title, artist_id, album_id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE users
    ADD CONSTRAINT users_pkey PRIMARY KEY  (user_id);


--
-- Name: users_username_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_albums_title_lower; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_albums_title_lower ON albums USING btree (lower((title)::text)) TABLESPACE pg_default;


--
-- Name: idx_artists_name_lower; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_artists_name_lower ON artists USING btree (lower((name)::text)) TABLESPACE pg_default;


--
-- Name: idx_comments_song_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_comments_song_id ON comments USING btree (song_id) TABLESPACE pg_default;


--
-- Name: idx_playlist_songs_song_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_playlist_songs_song_id ON playlist_songs USING btree (song_id) TABLESPACE pg_default;


--
-- Name: idx_songs_album_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_songs_album_id ON songs USING btree (album_id) TABLESPACE pg_default;


--
-- Name: idx_songs_artist_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_songs_artist_id ON songs USING btree (artist_id) TABLESPACE pg_default;


--
-- Name: idx_songs_title_lower; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX idx_songs_title_lower ON songs USING btree (lower((title)::text)) TABLESPACE pg_default;


--
-- Name: trg_comments_sync_song_count; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_comments_sync_song_count AFTER INSERT OR DELETE OR UPDATE ON public.comments FOR EACH ROW EXECUTE PROCEDURE public.sync_song_comment_count();


--
-- Name: albums_artist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE albums
    ADD CONSTRAINT albums_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES artists(artist_id) ON DELETE CASCADE;


--
-- Name: comments_song_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE comments
    ADD CONSTRAINT comments_song_id_fkey FOREIGN KEY (song_id) REFERENCES songs(song_id) ON DELETE CASCADE;


--
-- Name: comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;


--
-- Name: playlist_songs_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE playlist_songs
    ADD CONSTRAINT playlist_songs_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES playlists(playlist_id) ON DELETE CASCADE;


--
-- Name: playlist_songs_song_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE playlist_songs
    ADD CONSTRAINT playlist_songs_song_id_fkey FOREIGN KEY (song_id) REFERENCES songs(song_id) ON DELETE CASCADE;


--
-- Name: playlists_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE playlists
    ADD CONSTRAINT playlists_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(user_id) ON DELETE CASCADE;


--
-- Name: post_comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE post_comments
    ADD CONSTRAINT post_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE;


--
-- Name: post_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE post_comments
    ADD CONSTRAINT post_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;


--
-- Name: posts_recommended_song_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE posts
    ADD CONSTRAINT posts_recommended_song_id_fkey FOREIGN KEY (recommended_song_id) REFERENCES songs(song_id) ON DELETE SET NULL;


--
-- Name: posts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE posts
    ADD CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;


--
-- Name: songs_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE songs
    ADD CONSTRAINT songs_album_id_fkey FOREIGN KEY (album_id) REFERENCES albums(album_id) ON DELETE SET NULL;


--
-- Name: songs_artist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE songs
    ADD CONSTRAINT songs_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES artists(artist_id) ON DELETE CASCADE;


--
-- openGauss database dump complete
--

