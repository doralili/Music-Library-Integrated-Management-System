import psycopg2
import csv
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
# ========================================

def create_database():
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

        cursor.execute(f"DROP DATABASE IF EXISTS {DB_NAME};")
        cursor.execute(f"CREATE DATABASE {DB_NAME};")
        print("✅ 全新干净数据库已创建")

        cursor.close()
        connection.close()
        return True
    except Error as e:
        print(f"❌ 创建数据库失败: {e}")
        return False

def create_connection():
    try:
        return psycopg2.connect(
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME
        )
    except Error as e:
        print(f"❌ 连接失败: {e}")
        return None

def initialize_database():
    create_database()
    conn = create_connection()
    if not conn:
        return

    cursor = conn.cursor()

    # ===================== 建表（已加入 genre）=====================
    cursor.execute("""
    CREATE TABLE Users (
        user_id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL,
        bio TEXT,
        avatar_url VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE Artists (
        artist_id SERIAL PRIMARY KEY,
        name VARCHAR(100) UNIQUE NOT NULL,
        description TEXT
    );

    CREATE TABLE Albums (
        album_id SERIAL PRIMARY KEY,
        title VARCHAR(100) UNIQUE NOT NULL,
        artist_id INT REFERENCES Artists(artist_id) ON DELETE CASCADE,
        release_year INT,
        cover_url VARCHAR(500)
    );

    CREATE TABLE Songs (
        song_id SERIAL PRIMARY KEY,
        title VARCHAR(150) NOT NULL,
        artist_id INT REFERENCES Artists(artist_id) ON DELETE CASCADE,
        album_id INT REFERENCES Albums(album_id) ON DELETE SET NULL,
        duration_seconds INT CHECK (duration_seconds > 0),
        audio_url VARCHAR(500),
        genre VARCHAR(100) DEFAULT '未知',  
        comment_count INT DEFAULT 0,
        UNIQUE (title, artist_id, album_id)
    );

    CREATE TABLE Playlists (
        playlist_id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        creator_id INT REFERENCES Users(user_id) ON DELETE CASCADE
    );

    CREATE TABLE Playlist_Songs (
        playlist_id INT,
        song_id INT,
        PRIMARY KEY (playlist_id, song_id)
    );

    CREATE TABLE Comments (
        comment_id SERIAL PRIMARY KEY,
        song_id INT REFERENCES Songs(song_id) ON DELETE CASCADE,
        user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    conn.commit()
    cursor.close()
    conn.close()

    create_admin_user()
    import_1000_songs_from_csv()
    print("\n🎉 数据库初始化完成！genre 字段已添加！1000 首歌已导入！")

def create_admin_user():
    conn = create_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO Users (username, password_hash, role)
        VALUES (%s, %s, %s)
    """, (
        DEFAULT_ADMIN_USERNAME,
        generate_password_hash(DEFAULT_ADMIN_PASSWORD),
        "sys_admin"
    ))
    conn.commit()
    conn.close()

def import_1000_songs_from_csv():
    conn = create_connection()
    cursor = conn.cursor()

    with open("songs_import_1000.csv", "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            title = row["title"]
            artist = row["artist"]
            album = row["album"]
            duration = int(row["duration_seconds"])
            audio_url = row["audio_url"]

            # 插入艺术家
            cursor.execute("INSERT INTO Artists (name) VALUES (%s) ON CONFLICT DO NOTHING", (artist,))
            cursor.execute("SELECT artist_id FROM Artists WHERE name = %s", (artist,))
            artist_id = cursor.fetchone()[0]

            # 插入专辑
            cursor.execute("INSERT INTO Albums (title, artist_id) VALUES (%s, %s) ON CONFLICT DO NOTHING", (album, artist_id))
            cursor.execute("SELECT album_id FROM Albums WHERE title = %s", (album,))
            album_id = cursor.fetchone()[0]

            # 插入歌曲 带 genre
            cursor.execute("""
                INSERT INTO Songs (title, artist_id, album_id, duration_seconds, audio_url, genre)
                VALUES (%s, %s, %s, %s, %s, '未知')
                ON CONFLICT DO NOTHING
            """, (title, artist_id, album_id, duration, audio_url))

    conn.commit()
    conn.close()

if __name__ == "__main__":
    initialize_database()