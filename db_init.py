import argparse
import csv
from pathlib import Path

import psycopg2
from psycopg2 import Error, pool
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from werkzeug.security import generate_password_hash


# ================= 配置 =================
DB_HOST = "127.0.0.1"
DB_PORT = "5432"
DB_USER = "myadmin"
DB_PASS = "Axmo@9830"
DB_NAME = "music"

DEFAULT_ADMIN_USERNAME = "admin"
DEFAULT_ADMIN_PASSWORD = "admin123"
UNKNOWN_GENRE = "\u672a\u77e5"
BASE_DIR = Path(__file__).resolve().parent
SONGS_CSV = BASE_DIR / "songs_import_1000.csv"
# ========================================

_connection_pool = None


class PooledConnection:
    def __init__(self, source_pool, connection):
        self._pool = source_pool
        self._connection = connection
        self._closed = False

    def close(self):
        if self._closed:
            return
        try:
            self._connection.rollback()
        except Exception:
            pass
        self._pool.putconn(self._connection)
        self._closed = True

    def __getattr__(self, name):
        return getattr(self._connection, name)


def get_connection_pool():
    global _connection_pool
    if _connection_pool is None:
        _connection_pool = pool.SimpleConnectionPool(
            minconn=1,
            maxconn=8,
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
        )
    return _connection_pool


def create_database(reset=False):
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

        if reset:
            cursor.execute(
                """
                SELECT pg_terminate_backend(pid)
                FROM pg_stat_activity
                WHERE datname = %s AND pid <> pg_backend_pid();
                """,
                (DB_NAME,),
            )
            cursor.execute(f"DROP DATABASE IF EXISTS {DB_NAME};")
            cursor.execute(f"CREATE DATABASE {DB_NAME};")
            print("[OK] 数据库已按 --reset 要求重建")
        else:
            cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s", (DB_NAME,))
            if cursor.fetchone():
                print("[OK] 数据库已存在，保留原有数据")
            else:
                cursor.execute(f"CREATE DATABASE {DB_NAME};")
                print("[OK] 数据库不存在，已新建")

        cursor.close()
        connection.close()
        return True
    except Error as e:
        print(f"[ERROR] 创建/检查数据库失败: {e}")
        return False


def create_connection():
    try:
        db_pool = get_connection_pool()
        return PooledConnection(db_pool, db_pool.getconn())
    except Error as e:
        print(f"[ERROR] 连接失败: {e}")
        return None


def constraint_exists(cursor, table_name, constraint_name):
    cursor.execute(
        """
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t ON c.conrelid = t.oid
        WHERE t.relname = %s AND c.conname = %s
        """,
        (table_name.lower(), constraint_name.lower()),
    )
    return cursor.fetchone() is not None


def column_exists(cursor, table_name, column_name):
    cursor.execute(
        """
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = %s AND column_name = %s
        """,
        (table_name.lower(), column_name.lower()),
    )
    return cursor.fetchone() is not None


def add_column_if_missing(cursor, table_name, column_name, ddl):
    if column_exists(cursor, table_name, column_name):
        return
    cursor.execute(ddl)


def add_constraint_if_missing(cursor, table_name, constraint_name, ddl):
    if constraint_exists(cursor, table_name, constraint_name):
        return
    cursor.execute(ddl)


def foreign_key_exists(cursor, table_name, column_name, foreign_table_name):
    cursor.execute(
        """
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t ON c.conrelid = t.oid
        JOIN pg_class ft ON c.confrelid = ft.oid
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(c.conkey)
        WHERE c.contype = 'f'
          AND t.relname = %s
          AND a.attname = %s
          AND ft.relname = %s
        """,
        (table_name.lower(), column_name.lower(), foreign_table_name.lower()),
    )
    return cursor.fetchone() is not None


def add_foreign_key_if_missing(cursor, table_name, column_name, foreign_table_name, ddl):
    if foreign_key_exists(cursor, table_name, column_name, foreign_table_name):
        return
    cursor.execute(ddl)


def drop_constraint_if_exists(cursor, table_name, constraint_name):
    if constraint_exists(cursor, table_name, constraint_name):
        cursor.execute(f"ALTER TABLE {table_name} DROP CONSTRAINT {constraint_name};")


def index_exists(cursor, index_name):
    cursor.execute("SELECT 1 FROM pg_class WHERE relkind = 'i' AND relname = %s", (index_name.lower(),))
    return cursor.fetchone() is not None


def create_index_if_missing(cursor, index_name, ddl):
    if index_exists(cursor, index_name):
        return
    cursor.execute(ddl)


def extension_available(cursor, extension_name):
    cursor.execute("SELECT 1 FROM pg_available_extensions WHERE name = %s", (extension_name,))
    return cursor.fetchone() is not None


def create_or_migrate_schema(conn):
    cursor = conn.cursor()

    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS Users (
            user_id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            role VARCHAR(20) NOT NULL,
            bio TEXT,
            avatar_url VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS Artists (
            artist_id SERIAL PRIMARY KEY,
            name VARCHAR(100) UNIQUE NOT NULL,
            description TEXT
        );

        CREATE TABLE IF NOT EXISTS Albums (
            album_id SERIAL PRIMARY KEY,
            title VARCHAR(100) NOT NULL,
            artist_id INT REFERENCES Artists(artist_id) ON DELETE CASCADE,
            release_year INT,
            cover_url VARCHAR(500),
            UNIQUE (title, artist_id)
        );

        CREATE TABLE IF NOT EXISTS Songs (
            song_id SERIAL PRIMARY KEY,
            title VARCHAR(150) NOT NULL,
            artist_id INT REFERENCES Artists(artist_id) ON DELETE CASCADE,
            album_id INT REFERENCES Albums(album_id) ON DELETE SET NULL,
            duration_seconds INT CHECK (duration_seconds > 0),
            audio_url VARCHAR(500),
            genre VARCHAR(100),
            comment_count INT DEFAULT 0,
            UNIQUE (title, artist_id, album_id)
        );

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
        """
    )

    add_column_if_missing(cursor, "playlists", "created_at", "ALTER TABLE Playlists ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
    add_column_if_missing(cursor, "playlist_songs", "added_at", "ALTER TABLE Playlist_Songs ADD COLUMN added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
    add_column_if_missing(cursor, "songs", "genre", "ALTER TABLE Songs ADD COLUMN genre VARCHAR(100);")
    add_column_if_missing(cursor, "songs", "comment_count", "ALTER TABLE Songs ADD COLUMN comment_count INT DEFAULT 0;")
    add_column_if_missing(cursor, "albums", "cover_url", "ALTER TABLE Albums ADD COLUMN cover_url VARCHAR(500);")
    add_column_if_missing(cursor, "users", "bio", "ALTER TABLE Users ADD COLUMN bio TEXT;")
    add_column_if_missing(cursor, "users", "avatar_url", "ALTER TABLE Users ADD COLUMN avatar_url VARCHAR(255);")
    add_column_if_missing(cursor, "users", "created_at", "ALTER TABLE Users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;")
    cursor.execute("ALTER TABLE Songs ALTER COLUMN genre SET DEFAULT %s;", (UNKNOWN_GENRE,))
    cursor.execute("UPDATE Songs SET genre = %s WHERE genre IS NULL OR genre IN ('δ֪', '??')", (UNKNOWN_GENRE,))

    cursor.execute(
        """
        UPDATE Albums al
        SET artist_id = picked.artist_id
        FROM (
            SELECT album_id, MIN(artist_id) AS artist_id
            FROM Songs
            WHERE album_id IS NOT NULL AND artist_id IS NOT NULL
            GROUP BY album_id
        ) picked
        WHERE al.album_id = picked.album_id AND al.artist_id IS NULL;
        """
    )
    drop_constraint_if_exists(cursor, "Albums", "albums_title_key")
    cursor.execute(
        """
        WITH mismatched AS (
            SELECT s.song_id, al.title AS album_title, s.artist_id AS song_artist_id
            FROM Songs s
            JOIN Albums al ON s.album_id = al.album_id
            WHERE s.album_id IS NOT NULL
              AND s.artist_id IS NOT NULL
              AND al.artist_id IS NOT NULL
              AND al.artist_id <> s.artist_id
        ),
        target AS (
            SELECT m.song_id, al.album_id AS target_album_id
            FROM mismatched m
            JOIN Albums al
              ON al.title = m.album_title
             AND al.artist_id = m.song_artist_id
        ),
        effective AS (
            SELECT
                s.song_id,
                s.title,
                s.artist_id,
                COALESCE(t.target_album_id, s.album_id) AS effective_album_id
            FROM Songs s
            LEFT JOIN target t ON t.song_id = s.song_id
            WHERE s.album_id IS NOT NULL
        ),
        duplicate_songs AS (
            SELECT song_id, keep_id
            FROM (
                SELECT
                    song_id,
                    MIN(song_id) OVER (
                        PARTITION BY title, artist_id, effective_album_id
                    ) AS keep_id
                FROM effective
            ) ranked
            WHERE song_id <> keep_id
        ),
        moved_playlists AS (
            INSERT INTO Playlist_Songs (playlist_id, song_id, added_at)
            SELECT ps.playlist_id, d.keep_id, MIN(ps.added_at)
            FROM Playlist_Songs ps
            JOIN duplicate_songs d ON d.song_id = ps.song_id
            WHERE NOT EXISTS (
                SELECT 1
                FROM Playlist_Songs existing
                WHERE existing.playlist_id = ps.playlist_id
                  AND existing.song_id = d.keep_id
            )
            GROUP BY ps.playlist_id, d.keep_id
            RETURNING playlist_id
        ),
        removed_playlist_links AS (
            DELETE FROM Playlist_Songs ps
            USING duplicate_songs d
            WHERE ps.song_id = d.song_id
            RETURNING ps.song_id
        ),
        moved_comments AS (
            UPDATE Comments c
            SET song_id = d.keep_id
            FROM duplicate_songs d
            WHERE c.song_id = d.song_id
            RETURNING c.comment_id
        ),
        moved_posts AS (
            UPDATE Posts p
            SET recommended_song_id = d.keep_id
            FROM duplicate_songs d
            WHERE p.recommended_song_id = d.song_id
            RETURNING p.post_id
        )
        DELETE FROM Songs s
        USING duplicate_songs d
        WHERE s.song_id = d.song_id;
        """
    )
    cursor.execute(
        """
        WITH mismatched AS (
            SELECT s.song_id, al.title AS album_title, s.artist_id AS song_artist_id
            FROM Songs s
            JOIN Albums al ON s.album_id = al.album_id
            WHERE s.album_id IS NOT NULL
              AND s.artist_id IS NOT NULL
              AND al.artist_id IS NOT NULL
              AND al.artist_id <> s.artist_id
        ),
        target_albums AS (
            INSERT INTO Albums (title, artist_id)
            SELECT DISTINCT m.album_title, m.song_artist_id
            FROM mismatched m
            WHERE NOT EXISTS (
                SELECT 1
                FROM Albums existing
                WHERE existing.title = m.album_title
                  AND existing.artist_id = m.song_artist_id
            )
            RETURNING album_id, title, artist_id
        )
        UPDATE Songs s
        SET album_id = al.album_id
        FROM mismatched m
        JOIN Albums al
          ON al.title = m.album_title
         AND al.artist_id = m.song_artist_id
        WHERE s.song_id = m.song_id;
        """
    )
    add_constraint_if_missing(
        cursor,
        "albums",
        "albums_title_artist_id_key",
        "ALTER TABLE Albums ADD CONSTRAINT albums_title_artist_id_key UNIQUE (title, artist_id);",
    )

    add_constraint_if_missing(
        cursor,
        "users",
        "users_role_check",
        """
        ALTER TABLE Users
        ADD CONSTRAINT users_role_check
        CHECK (role IN ('sys_admin', 'music_admin', 'listener'));
        """,
    )

    if extension_available(cursor, "pg_trgm"):
        cursor.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm;")
        create_index_if_missing(cursor, "idx_songs_title_trgm", "CREATE INDEX idx_songs_title_trgm ON Songs USING GIN (title gin_trgm_ops);")
        create_index_if_missing(cursor, "idx_artists_name_trgm", "CREATE INDEX idx_artists_name_trgm ON Artists USING GIN (name gin_trgm_ops);")
        create_index_if_missing(cursor, "idx_albums_title_trgm", "CREATE INDEX idx_albums_title_trgm ON Albums USING GIN (title gin_trgm_ops);")
    else:
        create_index_if_missing(cursor, "idx_songs_title_lower", "CREATE INDEX idx_songs_title_lower ON Songs (LOWER(title));")
        create_index_if_missing(cursor, "idx_artists_name_lower", "CREATE INDEX idx_artists_name_lower ON Artists (LOWER(name));")
        create_index_if_missing(cursor, "idx_albums_title_lower", "CREATE INDEX idx_albums_title_lower ON Albums (LOWER(title));")
    create_index_if_missing(cursor, "idx_songs_artist_id", "CREATE INDEX idx_songs_artist_id ON Songs (artist_id);")
    create_index_if_missing(cursor, "idx_songs_album_id", "CREATE INDEX idx_songs_album_id ON Songs (album_id);")
    create_index_if_missing(cursor, "idx_playlist_songs_song_id", "CREATE INDEX idx_playlist_songs_song_id ON Playlist_Songs (song_id);")
    create_index_if_missing(cursor, "idx_comments_song_id", "CREATE INDEX idx_comments_song_id ON Comments (song_id);")

    cursor.execute(
        """
        CREATE OR REPLACE FUNCTION sync_song_comment_count()
        RETURNS TRIGGER AS $$
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
        $$ LANGUAGE plpgsql;

        DROP TRIGGER IF EXISTS trg_comments_sync_song_count ON Comments;
        CREATE TRIGGER trg_comments_sync_song_count
        AFTER INSERT OR UPDATE OR DELETE ON Comments
        FOR EACH ROW EXECUTE PROCEDURE sync_song_comment_count();

        UPDATE Songs s
        SET comment_count = counts.comment_count
        FROM (
            SELECT s2.song_id, COUNT(c.comment_id)::INT AS comment_count
            FROM Songs s2
            LEFT JOIN Comments c ON c.song_id = s2.song_id
            GROUP BY s2.song_id
        ) counts
        WHERE s.song_id = counts.song_id;
        """
    )

    cursor.execute(
        """
        DELETE FROM Playlist_Songs ps
        WHERE NOT EXISTS (SELECT 1 FROM Playlists p WHERE p.playlist_id = ps.playlist_id)
           OR NOT EXISTS (SELECT 1 FROM Songs s WHERE s.song_id = ps.song_id);
        """
    )
    if constraint_exists(cursor, "playlist_songs", "playlist_songs_playlist_id_fkey"):
        drop_constraint_if_exists(cursor, "Playlist_Songs", "playlist_songs_playlist_fk")
    if constraint_exists(cursor, "playlist_songs", "playlist_songs_song_id_fkey"):
        drop_constraint_if_exists(cursor, "Playlist_Songs", "playlist_songs_song_fk")

    add_foreign_key_if_missing(
        cursor,
        "playlist_songs",
        "playlist_id",
        "playlists",
        """
        ALTER TABLE Playlist_Songs
        ADD CONSTRAINT playlist_songs_playlist_fk
        FOREIGN KEY (playlist_id) REFERENCES Playlists(playlist_id) ON DELETE CASCADE;
        """,
    )
    add_foreign_key_if_missing(
        cursor,
        "playlist_songs",
        "song_id",
        "songs",
        """
        ALTER TABLE Playlist_Songs
        ADD CONSTRAINT playlist_songs_song_fk
        FOREIGN KEY (song_id) REFERENCES Songs(song_id) ON DELETE CASCADE;
        """,
    )

    cursor.execute(
        """
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
        """
    )

    conn.commit()
    cursor.close()


def initialize_database(reset=False):
    if not create_database(reset=reset):
        return

    conn = create_connection()
    if not conn:
        return

    create_or_migrate_schema(conn)
    conn.close()

    create_admin_user()
    imported = import_1000_songs_from_csv()
    print(f"\n[DONE] 数据库准备完成！默认保留已有数据，本次补齐导入 {imported} 首歌曲。")


def create_admin_user():
    conn = create_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT user_id FROM Users WHERE username = %s", (DEFAULT_ADMIN_USERNAME,))
    if not cursor.fetchone():
        cursor.execute(
            """
            INSERT INTO Users (username, password_hash, role)
            VALUES (%s, %s, %s)
            """,
            (
                DEFAULT_ADMIN_USERNAME,
                generate_password_hash(DEFAULT_ADMIN_PASSWORD, method="pbkdf2:sha256"),
                "sys_admin",
            ),
        )
    conn.commit()
    conn.close()


def import_1000_songs_from_csv():
    conn = create_connection()
    cursor = conn.cursor()
    inserted = 0

    with open(SONGS_CSV, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            title = row["title"]
            artist = row["artist"]
            album = row["album"]
            duration = int(row["duration_seconds"])
            audio_url = row["audio_url"]

            cursor.execute("SELECT artist_id FROM Artists WHERE name = %s", (artist,))
            artist_row = cursor.fetchone()
            if artist_row:
                artist_id = artist_row[0]
            else:
                cursor.execute("INSERT INTO Artists (name) VALUES (%s) RETURNING artist_id", (artist,))
                artist_id = cursor.fetchone()[0]

            cursor.execute("SELECT album_id FROM Albums WHERE title = %s AND artist_id = %s", (album, artist_id))
            album_row = cursor.fetchone()
            if album_row:
                album_id = album_row[0]
            else:
                cursor.execute("INSERT INTO Albums (title, artist_id) VALUES (%s, %s) RETURNING album_id", (album, artist_id))
                album_id = cursor.fetchone()[0]

            cursor.execute(
                "SELECT song_id FROM Songs WHERE title = %s AND artist_id = %s AND album_id = %s",
                (title, artist_id, album_id),
            )
            if cursor.fetchone():
                continue
            cursor.execute(
                """
                INSERT INTO Songs (title, artist_id, album_id, duration_seconds, audio_url, genre)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                (title, artist_id, album_id, duration, audio_url, UNKNOWN_GENRE),
            )
            if cursor.rowcount:
                inserted += 1

    conn.commit()
    conn.close()
    return inserted


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Initialize or migrate the music database.")
    parser.add_argument("--reset", action="store_true", help="drop and recreate the database before importing data")
    args = parser.parse_args()
    initialize_database(reset=args.reset)
