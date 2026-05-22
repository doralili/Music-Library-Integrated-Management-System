import argparse
import csv

import psycopg2
from psycopg2 import Error
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
# ========================================


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
        return psycopg2.connect(
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
        )
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
            title VARCHAR(100) UNIQUE NOT NULL,
            artist_id INT REFERENCES Artists(artist_id) ON DELETE CASCADE,
            release_year INT,
            cover_url VARCHAR(500)
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
            playlist_id INT,
            song_id INT,
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

    with open("songs_import_1000.csv", "r", encoding="utf-8-sig") as f:
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

            cursor.execute("SELECT album_id FROM Albums WHERE title = %s", (album,))
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
