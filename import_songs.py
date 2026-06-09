import csv
from pathlib import Path

import psycopg2

BASE_DIR = Path(__file__).resolve().parent
SONGS_CSV = BASE_DIR / "songs_import_1000.csv"

# 连接数据库（改成你自己的连接信息）
conn = psycopg2.connect(
    dbname="music",
    user="omm",
    password="你的数据库密码",
    host="localhost",
    port="5432"
)
cur = conn.cursor()

# 读取 CSV 文件并导入
with open(SONGS_CSV, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    count = 0
    for row in reader:
        cur.execute("""
            INSERT INTO "Songs" (title, artist, album, duration_seconds, audio_url)
            VALUES (%s, %s, %s, %s, %s)
        """, (
            row['title'],
            row['artist'],
            row['album'],
            row['duration_seconds'],
            row['audio_url']
        ))
        count += 1

conn.commit()
print(f"✅ 成功导入 {count} 首歌曲！")
cur.close()
conn.close()
