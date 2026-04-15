import re

with open(r"d:\数据库系统\poj1\music_manager.py", "r", encoding="utf-8") as f:
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

with open(r"d:\数据库系统\poj1\music_manager.py", "w", encoding="utf-8") as f:
    f.write(content)

print("done")
