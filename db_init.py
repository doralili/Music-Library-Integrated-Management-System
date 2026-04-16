import psycopg2
from psycopg2 import Error
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# ================= 配置区 =================
DB_HOST = "127.0.0.1"
DB_PORT = "5432"
DB_USER = "myadmin"
DB_PASS = "Axmo@9830"
DB_NAME = "music"
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
        name VARCHAR(100) NOT NULL,
        description TEXT
    );

    CREATE TABLE IF NOT EXISTS Albums (
        album_id SERIAL PRIMARY KEY,
        title VARCHAR(100) NOT NULL,
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
        duration_seconds INT,
        audio_url VARCHAR(500),
        comment_count INT DEFAULT 0
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
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    CREATE INDEX IF NOT EXISTS idx_comments_user_id ON Comments(user_id);
    CREATE INDEX IF NOT EXISTS idx_playlists_creator ON Playlists(creator_id);
    CREATE INDEX IF NOT EXISTS idx_posts_user_id ON Posts(user_id);
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


if __name__ == "__main__":
    initialize_database()
