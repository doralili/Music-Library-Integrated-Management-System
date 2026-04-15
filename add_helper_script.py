import re

with open(r"d:\数据库系统\poj1\music_manager.py", "r", encoding="utf-8") as f:
    content = f.read()

new_methods = """
    def get_all_artists(self):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT artist_id, name FROM Artists ORDER BY name")
            return cursor.fetchall()
        except: return []
        finally:
            if conn: conn.close()

    def get_all_albums(self):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT album_id, title FROM Albums ORDER BY title")
            return cursor.fetchall()
        except: return []
        finally:
            if conn: conn.close()

    @auth.require_role('sys_admin', 'music_admin')
    def get_or_create_artist(self, artist_name):
        if not artist_name: return None
        conn = create_connection()
        if not conn: return None
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT artist_id FROM Artists WHERE name = %s", (artist_name,))
            res = cursor.fetchone()
            if res: return res[0]
            cursor.execute("INSERT INTO Artists (name) VALUES (%s) RETURNING artist_id", (artist_name,))
            new_id = cursor.fetchone()[0]
            conn.commit()
            return new_id
        except: return None
        finally:
            if conn: conn.close()

    @auth.require_role('sys_admin', 'music_admin')
    def get_or_create_album(self, album_title):
        if not album_title: return None
        conn = create_connection()
        if not conn: return None
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT album_id FROM Albums WHERE title = %s", (album_title,))
            res = cursor.fetchone()
            if res: return res[0]
            cursor.execute("INSERT INTO Albums (title) VALUES (%s) RETURNING album_id", (album_title,))
            new_id = cursor.fetchone()[0]
            conn.commit()
            return new_id
        except: return None
        finally:
            if conn: conn.close()

"""

content = content.replace("    @auth.require_role('sys_admin', 'music_admin')\n    def add_song", new_methods + "    @auth.require_role('sys_admin', 'music_admin')\n    def add_song")

with open(r"d:\数据库系统\poj1\music_manager.py", "w", encoding="utf-8") as f:
    f.write(content)

print("success")
