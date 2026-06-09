import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
MUSIC_MANAGER_FILE = BASE_DIR / "music_manager.py"

with open(MUSIC_MANAGER_FILE, "r", encoding="utf-8") as f:
    content = f.read()

pattern = r"def get_all_posts\(self, limit=10, offset=0\):[\s\S]*?except Exception as e:"
replacement = """def get_all_posts(self, limit=10, offset=0):
        try:
            conn = create_connection()
            if not conn: return []
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM v_user_posts ORDER BY post_date DESC LIMIT %s OFFSET %s", (limit, offset))
            return cursor.fetchall()
        except Exception as e:"""

content = re.sub(pattern, replacement, content)

with open(MUSIC_MANAGER_FILE, "w", encoding="utf-8") as f:
    f.write(content)

print("done")
