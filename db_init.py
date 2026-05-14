import psycopg2
from psycopg2 import Error
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from werkzeug.security import generate_password_hash

# ================= 配置区 =================
DB_HOST = "127.0.0.1"
DB_PORT = "5432"
DB_USER = "myadmin"
DB_PASS = "Axmo@9830"
DB_NAME = "music"
DEFAULT_ADMIN_USERNAME = "admin"
DEFAULT_ADMIN_PASSWORD = "admin123"
# ==========================================


def create_database():
    """
    从默认 postgres 数据库连接，并创建 music 数据库。
    """
    try:
        connection = psycopg2.connect(
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT,
            database="postgres",
        )
        connection.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = connection.cursor()

        cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (DB_NAME,))
        if not cursor.fetchone():
            print(f"正在创建数据库 {DB_NAME}...")
            cursor.execute(f"CREATE DATABASE {DB_NAME};")
            print(f"✅ 数据库 '{DB_NAME}' 创建成功！\n")
        else:
            print(f"ℹ️ 数据库 '{DB_NAME}' 已存在。\n")

        cursor.close()
        connection.close()
        return True
    except Error as e:
        print(f"❌ 创建数据库时发生错误: {e}")
        return False


def create_connection():
    """
    连接到 music 数据库。
    """
    try:
        connection = psycopg2.connect(
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
        )
        return connection
    except Error as e:
        print(f"连接 {DB_NAME} 数据库时发生错误: {e}")
        return None


def initialize_database():
    """
    创建系统所需的全部表、视图、触发器和索引。
    """
    create_tables_sql = """
    CREATE TABLE IF NOT EXISTS Users (
        user_id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(20) CHECK (role IN ('sys_admin', 'music_admin', 'listener')) NOT NULL,
        bio TEXT,
        avatar_url VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    DO $$
    BEGIN
        BEGIN
            ALTER TABLE Users ADD COLUMN bio TEXT;
        EXCEPTION WHEN duplicate_column THEN
            RAISE NOTICE 'column bio already exists';
        END;
        BEGIN
            ALTER TABLE Users ADD COLUMN avatar_url VARCHAR(255);
        EXCEPTION WHEN duplicate_column THEN
            RAISE NOTICE 'column avatar_url already exists';
        END;
    END;
    $$;

    CREATE TABLE IF NOT EXISTS Artists (
        artist_id SERIAL PRIMARY KEY,
        name VARCHAR(100) CONSTRAINT uq_artists_name UNIQUE NOT NULL,
        description TEXT
    );

    CREATE TABLE IF NOT EXISTS Albums (
        album_id SERIAL PRIMARY KEY,
        title VARCHAR(100) CONSTRAINT uq_albums_title UNIQUE NOT NULL,
        artist_id INT REFERENCES Artists(artist_id) ON DELETE CASCADE,
        release_year INT,
        cover_url VARCHAR(500)
    );

    DO $$
    BEGIN
        BEGIN
            ALTER TABLE Albums ADD COLUMN cover_url VARCHAR(500);
        EXCEPTION WHEN duplicate_column THEN
            RAISE NOTICE 'column cover_url already exists';
        END;
    END;
    $$;

    CREATE TABLE IF NOT EXISTS Songs (
        song_id SERIAL PRIMARY KEY,
        title VARCHAR(150) NOT NULL,
        artist_id INT REFERENCES Artists(artist_id) ON DELETE CASCADE,
        album_id INT REFERENCES Albums(album_id) ON DELETE SET NULL,
        duration_seconds INT CONSTRAINT chk_songs_duration_positive CHECK (duration_seconds IS NULL OR duration_seconds > 0),
        audio_url VARCHAR(500),
        comment_count INT DEFAULT 0 CONSTRAINT chk_songs_comment_count_nonnegative CHECK (comment_count >= 0),
        CONSTRAINT uq_songs_title_artist_album UNIQUE (title, artist_id, album_id)
    );

    DO $$
    BEGIN
        BEGIN
            ALTER TABLE Songs ADD COLUMN audio_url VARCHAR(500);
        EXCEPTION WHEN duplicate_column THEN
            RAISE NOTICE 'column audio_url already exists';
        END;
        BEGIN
            ALTER TABLE Songs ADD COLUMN comment_count INT DEFAULT 0;
        EXCEPTION WHEN duplicate_column THEN
            RAISE NOTICE 'column comment_count already exists';
        END;
    END;
    $$;

    CREATE TABLE IF NOT EXISTS Playlists (
        playlist_id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        creator_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_playlists_creator_name UNIQUE (creator_id, name)
    );

    CREATE TABLE IF NOT EXISTS Playlist_Songs (
        playlist_id INT REFERENCES Playlists(playlist_id) ON DELETE CASCADE,
        song_id INT REFERENCES Songs(song_id) ON DELETE CASCADE,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (playlist_id, song_id)
    );

    CREATE TABLE IF NOT EXISTS Comments (
        comment_id SERIAL PRIMARY KEY,
        song_id INT REFERENCES Songs(song_id) ON DELETE CASCADE,
        user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS Posts (
        post_id SERIAL PRIMARY KEY,
        user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
        title VARCHAR(200) NOT NULL,
        content TEXT NOT NULL,
        recommended_song_id INT REFERENCES Songs(song_id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS Post_Comments (
        pcomment_id SERIAL PRIMARY KEY,
        post_id INT REFERENCES Posts(post_id) ON DELETE CASCADE,
        user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE OR REPLACE FUNCTION update_song_comment_count()
    RETURNS TRIGGER AS $$
    BEGIN
        UPDATE Songs
        SET comment_count = comment_count + 1
        WHERE song_id = NEW.song_id;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS trg_after_insert_comment ON Comments;
    CREATE TRIGGER trg_after_insert_comment
    AFTER INSERT ON Comments
    FOR EACH ROW
    EXECUTE PROCEDURE update_song_comment_count();

    CREATE OR REPLACE FUNCTION decrease_song_comment_count()
    RETURNS TRIGGER AS $$
    BEGIN
        UPDATE Songs
        SET comment_count = GREATEST(comment_count - 1, 0)
        WHERE song_id = OLD.song_id;
        RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS trg_after_delete_comment ON Comments;
    CREATE TRIGGER trg_after_delete_comment
    AFTER DELETE ON Comments
    FOR EACH ROW
    EXECUTE PROCEDURE decrease_song_comment_count();

    CREATE OR REPLACE VIEW v_user_posts AS
    SELECT
        p.post_id,
        p.title AS post_title,
        p.content AS post_content,
        p.created_at AS post_date,
        u.user_id,
        u.username AS author_name,
        u.avatar_url AS author_avatar,
        s.song_id,
        s.title AS recommended_song_name,
        art.name AS artist_name,
        alb.title AS album_name,
        alb.cover_url AS recommended_cover_url,
        s.duration_seconds,
        s.audio_url AS recommended_audio_url
    FROM Posts p
    JOIN Users u ON p.user_id = u.user_id
    LEFT JOIN Songs s ON p.recommended_song_id = s.song_id
    LEFT JOIN Artists art ON s.artist_id = art.artist_id
    LEFT JOIN Albums alb ON s.album_id = alb.album_id;

    CREATE INDEX IF NOT EXISTS idx_songs_title ON Songs(title);
    CREATE INDEX IF NOT EXISTS idx_songs_artist_id ON Songs(artist_id);
    CREATE INDEX IF NOT EXISTS idx_songs_album_id ON Songs(album_id);
    CREATE INDEX IF NOT EXISTS idx_comments_user_id ON Comments(user_id);
    CREATE INDEX IF NOT EXISTS idx_comments_song_id ON Comments(song_id);
    CREATE INDEX IF NOT EXISTS idx_playlists_creator ON Playlists(creator_id);
    CREATE INDEX IF NOT EXISTS idx_posts_user_id ON Posts(user_id);

    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_artists_name') THEN
            ALTER TABLE Artists ADD CONSTRAINT uq_artists_name UNIQUE (name);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_albums_title') THEN
            ALTER TABLE Albums ADD CONSTRAINT uq_albums_title UNIQUE (title);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_songs_duration_positive') THEN
            ALTER TABLE Songs ADD CONSTRAINT chk_songs_duration_positive CHECK (duration_seconds IS NULL OR duration_seconds > 0);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_songs_comment_count_nonnegative') THEN
            ALTER TABLE Songs ADD CONSTRAINT chk_songs_comment_count_nonnegative CHECK (comment_count >= 0);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_songs_title_artist_album') THEN
            ALTER TABLE Songs ADD CONSTRAINT uq_songs_title_artist_album UNIQUE (title, artist_id, album_id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_playlists_creator_name') THEN
            ALTER TABLE Playlists ADD CONSTRAINT uq_playlists_creator_name UNIQUE (creator_id, name);
        END IF;
    END;
    $$;
    """

    if not create_database():
        return

    conn = create_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute(create_tables_sql)
            conn.commit()
            print("====================================")
            print("✅ 音乐库所有数据表初始化创建成功！")
            print("====================================")
        except Error as e:
            print(f"创建表时发生错误: {e}")
            conn.rollback()
        finally:
            cursor.close()
            conn.close()

    initialize_seed_data()


def initialize_seed_data():
    """
    插入默认管理员和演示测试数据。
    使用查询后插入的方式保持脚本可重复执行，避免重复创建相同记录。
    """
    conn = create_connection()
    if not conn:
        return

    try:
        cursor = conn.cursor()

        cursor.execute("SELECT user_id FROM Users WHERE username = %s", (DEFAULT_ADMIN_USERNAME,))
        if not cursor.fetchone():
            cursor.execute(
                "INSERT INTO Users (username, password_hash, role) VALUES (%s, %s, %s)",
                (
                    DEFAULT_ADMIN_USERNAME,
                    generate_password_hash(DEFAULT_ADMIN_PASSWORD, method="pbkdf2:sha256"),
                    "sys_admin",
                ),
            )

        seed_artists = [
            ("周杰伦", "华语流行音乐歌手"),
            ("Taylor Swift", "English pop singer-songwriter"),
        ]
        for name, description in seed_artists:
            cursor.execute("SELECT artist_id FROM Artists WHERE name = %s", (name,))
            if not cursor.fetchone():
                cursor.execute(
                    "INSERT INTO Artists (name, description) VALUES (%s, %s)",
                    (name, description),
                )

        cursor.execute("SELECT artist_id FROM Artists WHERE name = %s", ("周杰伦",))
        jay_id = cursor.fetchone()[0]
        cursor.execute("SELECT artist_id FROM Artists WHERE name = %s", ("Taylor Swift",))
        taylor_id = cursor.fetchone()[0]

        seed_albums = [
            ("七里香", jay_id, 2004),
            ("1989", taylor_id, 2014),
        ]
        for title, artist_id, release_year in seed_albums:
            cursor.execute("SELECT album_id FROM Albums WHERE title = %s", (title,))
            if not cursor.fetchone():
                cursor.execute(
                    "INSERT INTO Albums (title, artist_id, release_year) VALUES (%s, %s, %s)",
                    (title, artist_id, release_year),
                )

        cursor.execute("SELECT album_id FROM Albums WHERE title = %s", ("七里香",))
        qlxiang_album_id = cursor.fetchone()[0]
        cursor.execute("SELECT album_id FROM Albums WHERE title = %s", ("1989",))
        album_1989_id = cursor.fetchone()[0]

        seed_songs = [
            ("七里香", jay_id, qlxiang_album_id, 299),
            ("搁浅", jay_id, qlxiang_album_id, 238),
            ("Blank Space", taylor_id, album_1989_id, 231),
        ]
        for title, artist_id, album_id, duration_seconds in seed_songs:
            cursor.execute(
                """
                SELECT song_id FROM Songs
                WHERE title = %s AND artist_id = %s AND album_id = %s
                """,
                (title, artist_id, album_id),
            )
            if not cursor.fetchone():
                cursor.execute(
                    """
                    INSERT INTO Songs (title, artist_id, album_id, duration_seconds)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (title, artist_id, album_id, duration_seconds),
                )

        cursor.execute("SELECT setval('users_user_id_seq', COALESCE((SELECT MAX(user_id) FROM Users), 1))")
        cursor.execute("SELECT setval('artists_artist_id_seq', COALESCE((SELECT MAX(artist_id) FROM Artists), 1))")
        cursor.execute("SELECT setval('albums_album_id_seq', COALESCE((SELECT MAX(album_id) FROM Albums), 1))")
        cursor.execute("SELECT setval('songs_song_id_seq', COALESCE((SELECT MAX(song_id) FROM Songs), 1))")

        conn.commit()
        print("✅ 默认管理员与测试数据初始化完成！")
        print(f"   默认管理员: {DEFAULT_ADMIN_USERNAME} / {DEFAULT_ADMIN_PASSWORD}")
    except Error as e:
        print(f"初始化默认数据时发生错误: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    initialize_database()
