from datetime import datetime
import logging

from db_init import create_connection
from auth import auth, add_user, hash_password  # 导入我们在上一步做好的权限管理器和新建用户函数

logger = logging.getLogger(__name__)

class MusicManager:
    """
    音乐库核心管理模块：负责管理音乐、歌手、专辑的增删改查。
    """
    def __init__(self):
        pass

    # ==========================================
    # 高级模糊查询 (拿满 10 分查询分的关键)
    # ==========================================
    def search_songs(self, keyword):
        """
        通过关键词模糊搜索音乐库。
        这不仅是一个简单的 WHERE = 查询，它还涉及了三个表的联查 (JOIN)
        以及对 歌名、歌手名、专辑名 的全方位模糊匹配 (ILIKE)
        """
        if not keyword:
            print("❌ 搜索关键词不能为空！")
            return []

        conn = create_connection()
        if not conn: return []

        try:
            cursor = conn.cursor()
            sql = """
            SELECT 
                s.song_id, 
                s.title AS song_title, 
                a.name AS artist_name, 
                al.title AS album_title, 
                s.duration_seconds, s.audio_url, al.cover_url,
                genre  -- 【添加：曲风】
            FROM Songs s
            LEFT JOIN Artists a ON s.artist_id = a.artist_id
            LEFT JOIN Albums al ON s.album_id = al.album_id
            WHERE s.title ILIKE %s
               OR a.name ILIKE %s
               OR al.title ILIKE %s
            ORDER BY s.title ASC;
            """
            
            search_pattern = f"%{keyword}%"
            cursor.execute(sql, (search_pattern, search_pattern, search_pattern))
            
            results = cursor.fetchall()
            
            print(f"\n🔍 关于 '{keyword}' 的搜索结果 (找到 {len(results)} 首):")
            print("-" * 75)
            print(f"{'ID':<5} | {'歌曲名称':<20} | {'歌手':<15} | {'专辑':<15} | {'时长(秒)'} | {'曲风'}")
            print("-" * 75)

            if results:
                for row in results:
                    s_id = row[0]
                    s_title = row[1]
                    s_artist = row[2] if row[2] else "未知歌手"
                    s_album = row[3] if row[3] else "单曲/未归档"
                    s_duration = row[4] if row[4] else 0
                    s_genre = row[7] if row[7] else "未设置"
                    
                    print(f"{s_id:<5} | {s_title:<20} | {s_artist:<15} | {s_album:<15} | {s_duration}s | {s_genre}")
            else:
                print("空空如也~")
            print("-" * 75)

            return results
        except Exception as e:
            print(f"搜索时发生错误: {e}")
            logger.exception("Failed to search songs with keyword=%r", keyword)
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()

    # ==========================================
    # 增删改操作：音乐管理员(和系统管理员)专属权限
    # ==========================================

    def get_all_artists(self):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT artist_id, name FROM Artists ORDER BY name")
            return cursor.fetchall()
        except Exception:
            logger.exception("Failed to fetch artists")
            return []
        finally:
            if conn: conn.close()

    def get_all_albums(self):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT album_id, title FROM Albums ORDER BY title")
            return cursor.fetchall()
        except Exception:
            logger.exception("Failed to fetch albums")
            return []
        finally:
            if conn: conn.close()

    def song_exists(self, title, artist_name, album_title):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            sql = """
            SELECT 1
            FROM Songs s
            JOIN Artists a ON s.artist_id = a.artist_id
            JOIN Albums al ON s.album_id = al.album_id
            WHERE s.title = %s AND a.name = %s AND al.title = %s
            LIMIT 1
            """
            cursor.execute(sql, (title, artist_name, album_title))
            return cursor.fetchone() is not None
        except Exception:
            logger.exception("Failed to check duplicate song title=%r artist=%r album=%r", title, artist_name, album_title)
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

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
        except Exception:
            logger.exception("Failed to get or create artist: %s", artist_name)
            return None
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
        except Exception:
            logger.exception("Failed to get or create album: %s", album_title)
            return None
        finally:
            if conn: conn.close()

    @auth.require_role('sys_admin', 'music_admin')
    def add_song(self, title, artist_id, album_id=None, duration_seconds=0, audio_url=None, genre=None):  # 【添加：genre】
        """添加一首新歌曲"""
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            sql = """
            INSERT INTO Songs 
            (title, artist_id, album_id, duration_seconds, audio_url, genre) 
            VALUES (%s, %s, %s, %s, %s, %s) 
            RETURNING song_id
            """
            cursor.execute(sql, (title, artist_id, album_id, duration_seconds, audio_url, genre))
            new_id = cursor.fetchone()[0]
            conn.commit()
            print(f"✅ 成功添加新歌曲 '{title}' (入库ID: {new_id})")
            return new_id
        except Exception as e:
            print(f"❌ 添加歌曲失败: {e}")
            logger.exception("Failed to add song title=%r artist_id=%s album_id=%s", title, artist_id, album_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin', 'music_admin')
    def delete_song(self, song_id):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            sql = "DELETE FROM Songs WHERE song_id = %s RETURNING song_id"
            cursor.execute(sql, (song_id,))
            deleted = cursor.fetchone()
            if deleted:
                conn.commit()
                print(f"✅ 成功删除歌曲 ID={song_id}")
                return True
            else:
                print(f"⚠️ 找不到 ID={song_id} 的歌曲，删除失败。")
                return False
        except Exception as e:
            print(f"❌ 删除歌曲失败: {e}")
            logger.exception("Failed to delete song_id=%s", song_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin', 'music_admin')
    def update_song(self, song_id, new_title=None, new_artist_id=None, new_album_id=None, new_duration=None, new_audio_url=None, new_genre=None):  # 【添加：new_genre】
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            sql = """
                UPDATE Songs 
                SET title = COALESCE(%s, title),
                    artist_id = COALESCE(%s, artist_id),
                    album_id = COALESCE(%s, album_id),
                    duration_seconds = COALESCE(%s, duration_seconds),
                    audio_url = COALESCE(%s, audio_url),
                    genre = COALESCE(%s, genre)  -- 【添加：曲风更新】
                WHERE song_id = %s
                RETURNING title
            """
            cursor.execute(sql, (new_title, new_artist_id, new_album_id, new_duration, new_audio_url, new_genre, song_id))
            updated = cursor.fetchone()
            if updated:
                conn.commit()
                print(f"✅ 成功修改歌曲 ID={song_id}，现名为: '{updated[0]}'")
                return True
            else:
                print(f"⚠️ 找不到 ID={song_id} 的歌曲，修改失败。")
                return False
        except Exception as e:
            print(f"❌ 修改歌曲失败: {e}")
            logger.exception("Failed to update song_id=%s", song_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def create_playlist(self, name):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            sql = "INSERT INTO Playlists (name, creator_id) VALUES (%s, %s) RETURNING playlist_id"
            cursor.execute(sql, (name, user_id))
            new_id = cursor.fetchone()[0]
            conn.commit()
            print(f"✅ 成功创建歌单 '{name}' (ID: {new_id})")
            return new_id
        except Exception as e:
            print(f"❌ 创建歌单失败: {e}")
            logger.exception("Failed to create playlist name=%r", name)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def get_my_playlists(self):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            sql = "SELECT playlist_id, name, created_at FROM Playlists WHERE creator_id = %s ORDER BY created_at DESC"
            cursor.execute(sql, (user_id,))
            results = cursor.fetchall()
            
            print(f"\n📂 {auth.current_user['username']} 的歌单列表:")
            print("-" * 50)
            for row in results:
                print(f"ID: {row[0]:<5} | 名称: {row[1]:<20} | 创建时间: {row[2]}")
            if not results:
                print("  (暂无歌单)")
            print("-" * 50)
            return results
        except Exception as e:
            print(f"❌ 获取歌单失败: {e}")
            logger.exception("Failed to fetch playlists for current user")
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin', 'music_admin')
    def get_song_detail(self, song_id):
        conn = create_connection()
        if not conn: return None
        try:
            cursor = conn.cursor()
            sql = """
            SELECT
                s.song_id, s.title, s.artist_id, a.name, s.album_id, al.title,
                s.duration_seconds, s.audio_url, s.genre  -- 【添加：曲风】
            FROM Songs s
            LEFT JOIN Artists a ON s.artist_id = a.artist_id
            LEFT JOIN Albums al ON s.album_id = al.album_id
            WHERE s.song_id = %s
            """
            cursor.execute(sql, (song_id,))
            return cursor.fetchone()
        except Exception as e:
            print(f"❌ 查询歌曲详情失败: {e}")
            logger.exception("Failed to fetch song detail for song_id=%s", song_id)
            return None
        finally:
            if conn:
                cursor.close()
                conn.close()

    # ==============================
    # 下面所有代码完全不动
    # ==============================

    @auth.require_role('music_admin', 'sys_admin')
    def get_all_playlists(self):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            sql = """
            SELECT p.playlist_id, p.name, u.username, p.created_at
            FROM Playlists p
            JOIN Users u ON p.creator_id = u.user_id
            ORDER BY p.created_at DESC, p.playlist_id DESC
            """
            cursor.execute(sql)
            return cursor.fetchall()
        except Exception as e:
            print(f"❌ 获取所有歌单失败: {e}")
            logger.exception("Failed to fetch all playlists")
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener','music_admin','sys_admin')
    def delete_playlist(self, playlist_id):
        conn = create_connection()
        if not conn:
            return False
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT creator_id, name FROM Playlists WHERE playlist_id = %s", (playlist_id,))
            playlist = cursor.fetchone()
            if not playlist:
                print(f"❌ 找不到 ID={playlist_id} 的歌单。")
                return False

            creator_id, playlist_name = playlist
            current_user = auth.current_user
            if creator_id != current_user['user_id']:
                print("❌ 操作拒绝：你只能删除自己的歌单！")
                return False

        # 先删除歌单内所有歌曲
            cursor.execute("DELETE FROM Playlist_Songs WHERE playlist_id = %s", (playlist_id,))
        # 再删除歌单
            cursor.execute("DELETE FROM Playlists WHERE playlist_id = %s", (playlist_id,))
        
            conn.commit()
            print(f"✅ 成功删除歌单 '{playlist_name}' (ID: {playlist_id})")
            return True
        except Exception as e:
            print(f"❌ 删除歌单失败: {e}")
            logger.exception("Failed to delete playlist_id=%s", playlist_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def add_to_playlist(self, playlist_id, song_id):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            cursor.execute("SELECT creator_id FROM Playlists WHERE playlist_id = %s", (playlist_id,))
            owner = cursor.fetchone()
            if not owner or owner[0] != user_id:
                print("❌ 操作拒绝：你只能向自己的歌单添加歌曲！")
                return False

            sql = "INSERT INTO Playlist_Songs (playlist_id, song_id) VALUES (%s, %s)"
            cursor.execute(sql, (playlist_id, song_id))
            conn.commit()
            print(f"✅ 成功将歌曲(ID:{song_id})加入歌单(ID:{playlist_id})！")
            return True
        except Exception as e:
            print(f"❌ 添加歌曲到歌单失败(可能已经在这个歌单里了): {e}")
            logger.exception("Failed to add song_id=%s to playlist_id=%s", song_id, playlist_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def view_playlist(self, playlist_id):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            sql = """
            SELECT 
                s.song_id, s.title, a.name, al.title, s.duration_seconds, s.audio_url, al.cover_url
            FROM Playlist_Songs ps
            JOIN Songs s ON ps.song_id = s.song_id
            LEFT JOIN Artists a ON s.artist_id = a.artist_id
            LEFT JOIN Albums al ON s.album_id = al.album_id
            WHERE ps.playlist_id = %s
            ORDER BY ps.added_at ASC;
            """
            cursor.execute(sql, (playlist_id,))
            results = cursor.fetchall()
            
            cursor.execute("SELECT name FROM Playlists WHERE playlist_id = %s", (playlist_id,))
            pl = cursor.fetchone()
            pl_name = pl[0] if pl else "未知歌单"

            print(f"\n🎵 歌单 [{pl_name}] 的内容:")
            print("-" * 65)
            print(f"{'ID':<5} | {'歌曲名称':<20} | {'歌手':<15} | {'时长(秒)'}")
            print("-" * 65)
            total_duration = 0
            for row in results:
                print(f"{row[0]:<5} | {row[1]:<20} | {row[2] if row[2] else '未知':<15} | {row[4]}s")
                if row[4]: total_duration += row[4]
            if not results:
                print("  (歌单还是空的，快去添加歌曲吧)")
            print("-" * 65)
            print(f"📊 聚合统计：共 {len(results)} 首歌曲，总时长 {total_duration} 秒。")
            return results
        except Exception as e:
            print(f"❌ 查看歌单失败: {e}")
            logger.exception("Failed to view playlist_id=%s", playlist_id)
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def get_comments(self, song_id):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            sql = """
            SELECT c.comment_id, u.user_id, u.username, u.avatar_url, c.content, c.created_at
            FROM Comments c
            JOIN Users u ON c.user_id = u.user_id
            WHERE c.song_id = %s
            ORDER BY c.created_at DESC;
            """
            cursor.execute(sql, (song_id,))
            return cursor.fetchall()
        except Exception as e:
            print(f"❌ 获取评论失败: {e}")
            logger.exception("Failed to fetch comments for song_id=%s", song_id)
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def add_comment(self, song_id, content):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            sql = "INSERT INTO Comments (song_id, user_id, content, created_at) VALUES (%s, %s, %s, %s) RETURNING comment_id"
            cursor.execute(sql, (song_id, user_id, content, datetime.now()))
            new_id = cursor.fetchone()[0]
            conn.commit()
            print(f"✅ 成功发布评论 (ID: {new_id})")
            return new_id
        except Exception as e:
            print(f"❌ 发布评论失败: {e}")
            logger.exception("Failed to add comment for song_id=%s", song_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def remove_from_playlist(self, playlist_id, song_id):
        conn = create_connection()
        if not conn: return False, "数据库连接失败。"
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT creator_id, name FROM Playlists WHERE playlist_id = %s", (playlist_id,))
            playlist = cursor.fetchone()
            if not playlist:
                return False, "找不到目标歌单。"

            creator_id, playlist_name = playlist
            current_user = auth.current_user
            if creator_id != current_user['user_id']:
                return False, "你只能删除自己歌单里的歌曲。"

            cursor.execute(
                "DELETE FROM Playlist_Songs WHERE playlist_id = %s AND song_id = %s RETURNING song_id",
                (playlist_id, song_id)
            )
            deleted = cursor.fetchone()
            if not deleted:
                conn.rollback()
                return False, "该歌曲不在目标歌单中。"

            conn.commit()
            return True, f"已从歌单《{playlist_name}》中移除该歌曲。"
        except Exception as e:
            logger.exception("Failed to remove song_id=%s from playlist_id=%s", song_id, playlist_id)
            conn.rollback()
            return False, f"删除歌单歌曲失败: {e}"
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def delete_comment(self, comment_id):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT song_id, user_id FROM Comments WHERE comment_id = %s", (comment_id,))
            comment = cursor.fetchone()
            if not comment:
                print(f"❌ 找不到 ID={comment_id} 的评论。")
                return False

            song_id, comment_user_id = comment
            current_user = auth.current_user
            can_manage_all = current_user['role'] in ('sys_admin', 'music_admin')
            if not can_manage_all and comment_user_id != current_user['user_id']:
                print("❌ 操作拒绝：你只能删除自己的评论！")
                return False

            cursor.execute("DELETE FROM Comments WHERE comment_id = %s", (comment_id,))
            conn.commit()
            print(f"✅ 成功删除评论 ID={comment_id}")
            return True
        except Exception as e:
            print(f"❌ 删除评论失败: {e}")
            logger.exception("Failed to delete comment_id=%s", comment_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def delete_post(self, post_id):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT user_id, title FROM Posts WHERE post_id = %s", (post_id,))
            post = cursor.fetchone()
            if not post:
                return False

            post_user_id, post_title = post
            current_user = auth.current_user
            can_manage_all = current_user['role'] in ('sys_admin', 'music_admin')
            if not can_manage_all and post_user_id != current_user['user_id']:
                return False

            cursor.execute("DELETE FROM Posts WHERE post_id = %s", (post_id,))
            conn.commit()
            print(f"✅ 成功删除帖子 '{post_title}' (ID: {post_id})")
            return True
        except Exception as e:
            logger.exception("Failed to delete post_id=%s", post_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def delete_post_comment(self, pcomment_id):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT user_id FROM Post_Comments WHERE pcomment_id = %s", (pcomment_id,))
            comment = cursor.fetchone()
            if not comment:
                return False

            comment_user_id = comment[0]
            current_user = auth.current_user
            can_manage_all = current_user['role'] in ('sys_admin', 'music_admin')
            if not can_manage_all and comment_user_id != current_user['user_id']:
                return False

            cursor.execute("DELETE FROM Post_Comments WHERE pcomment_id = %s", (pcomment_id,))
            conn.commit()
            print(f"✅ 成功删除论坛评论 ID={pcomment_id}")
            return True
        except Exception as e:
            logger.exception("Failed to delete post comment pcomment_id=%s", pcomment_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def toggle_like_song(self, song_id):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            
            cursor.execute("SELECT playlist_id FROM Playlists WHERE creator_id = %s AND name = '我喜欢的歌曲'", (user_id,))
            playlist = cursor.fetchone()
            
            if not playlist:
                cursor.execute("INSERT INTO Playlists (name, creator_id) VALUES ('我喜欢的歌曲', %s) RETURNING playlist_id", (user_id,))
                playlist_id = cursor.fetchone()[0]
            else:
                playlist_id = playlist[0]
                
            cursor.execute("SELECT 1 FROM Playlist_Songs WHERE playlist_id = %s AND song_id = %s", (playlist_id, song_id))
            exists = cursor.fetchone()
            
            if exists:
                cursor.execute("DELETE FROM Playlist_Songs WHERE playlist_id = %s AND song_id = %s", (playlist_id, song_id))
                action = "unliked"
            else:
                cursor.execute("INSERT INTO Playlist_Songs (playlist_id, song_id) VALUES (%s, %s)", (playlist_id, song_id))
                action = "liked"
                
            conn.commit()
            return action
        except Exception as e:
            print(f"❌ 点赞操作失败: {e}")
            logger.exception("Failed to toggle like for song_id=%s", song_id)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def is_song_liked(self, song_id):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            sql = """
            SELECT 1 FROM Playlist_Songs ps
            JOIN Playlists p ON ps.playlist_id = p.playlist_id
            WHERE p.creator_id = %s AND p.name = '我喜欢的歌曲' AND ps.song_id = %s
            """
            cursor.execute(sql, (user_id, song_id))
            return cursor.fetchone() is not None
        except Exception as e:
            logger.exception("Failed to check liked state for song_id=%s", song_id)
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def get_rankings(self, limit=10, l_offset=0, c_offset=0):
        conn = create_connection()
        if not conn: return [], []
        try:
            cursor = conn.cursor()
            
            likes_sql = """
            SELECT s.song_id, s.title, a.name, al.title, s.duration_seconds, COUNT(ps.song_id) AS like_count, s.audio_url, al.cover_url
            FROM Songs s
            LEFT JOIN Artists a ON s.artist_id = a.artist_id
            LEFT JOIN Albums al ON s.album_id = al.album_id
            JOIN Playlist_Songs ps ON s.song_id = ps.song_id
            JOIN Playlists p ON ps.playlist_id = p.playlist_id
            WHERE p.name = '我喜欢的歌曲'
            GROUP BY s.song_id, s.title, a.name, al.title, s.duration_seconds, s.audio_url, al.cover_url
            ORDER BY like_count DESC, s.song_id ASC
            LIMIT %s OFFSET %s;
            """
            safe_limit = max(int(limit), 1)
            safe_l_offset = max(int(l_offset), 0)
            safe_c_offset = max(int(c_offset), 0)
            cursor.execute(likes_sql, (safe_limit, safe_l_offset))
            likes_ranking = cursor.fetchall()
            
            comments_sql = """
            SELECT s.song_id, s.title, a.name, al.title, s.duration_seconds, COUNT(c.comment_id) AS comment_count, s.audio_url, al.cover_url
            FROM Songs s
            LEFT JOIN Artists a ON s.artist_id = a.artist_id
            LEFT JOIN Albums al ON s.album_id = al.album_id
            JOIN Comments c ON s.song_id = c.song_id
            GROUP BY s.song_id, s.title, a.name, al.title, s.duration_seconds, s.audio_url, al.cover_url
            ORDER BY comment_count DESC, s.song_id ASC
            LIMIT %s OFFSET %s;
            """
            cursor.execute(comments_sql, (safe_limit, safe_c_offset))
            comments_ranking = cursor.fetchall()
            
            return likes_ranking, comments_ranking
        except Exception as e:
            print(f"❌ 获取排行榜失败: {e}")
            logger.exception("Failed to fetch rankings")
            return [], []
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def create_post(self, title, content, recommended_song_id=None):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            sql = "INSERT INTO Posts (user_id, title, content, recommended_song_id) VALUES (%s, %s, %s, %s) RETURNING post_id"
            cursor.execute(sql, (user_id, title, content, recommended_song_id))
            new_id = cursor.fetchone()[0]
            conn.commit()
            return new_id
        except Exception as e:
            logger.exception(
                "Failed to create post for user_id=%s with recommended_song_id=%s",
                auth.current_user.get('user_id') if auth.current_user else None,
                recommended_song_id,
            )
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def get_all_posts(self, limit=10, offset=0):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            sql = """
            SELECT * FROM v_user_posts
            ORDER BY post_date DESC
            LIMIT %s OFFSET %s
            """
            cursor.execute(sql, (limit, offset))
            return cursor.fetchall()
        except Exception as e:
            logger.exception("Failed to fetch posts with limit=%s offset=%s", limit, offset)
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()
                
    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def get_user_posts(self, target_user_id):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            sql = """
            SELECT * FROM v_user_posts
            WHERE user_id = %s
            ORDER BY post_date DESC;
            """
            cursor.execute(sql, (target_user_id,))
            return cursor.fetchall()
        except Exception as e:
            logger.exception("Failed to fetch posts for user_id=%s", target_user_id)
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def get_post_comments(self, post_id):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            sql = """
            SELECT pc.pcomment_id, u.user_id, u.username, u.avatar_url, pc.content, pc.created_at
            FROM Post_Comments pc
            JOIN Users u ON pc.user_id = u.user_id
            WHERE pc.post_id = %s
            ORDER BY pc.created_at ASC;
            """
            cursor.execute(sql, (post_id,))
            return cursor.fetchall()
        except Exception as e:
            logger.exception("Failed to fetch comments for post_id=%s", post_id)
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener')
    def add_post_comment(self, post_id, content):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            sql = "INSERT INTO Post_Comments (post_id, user_id, content) VALUES (%s, %s, %s)"
            cursor.execute(sql, (post_id, user_id, content))
            conn.commit()
            return True
        except Exception as e:
            logger.exception(
                "Failed to add comment to post_id=%s for user_id=%s",
                post_id,
                auth.current_user.get('user_id') if auth.current_user else None,
            )
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    def get_user_info(self, user_id):
        conn = create_connection()
        if not conn: return None
        try:
            cursor = conn.cursor()
            sql = "SELECT user_id, username, role, bio, avatar_url, created_at FROM Users WHERE user_id = %s"
            cursor.execute(sql, (user_id,))
            return cursor.fetchone()
        except Exception as e:
            logger.exception("Failed to fetch user info for user_id=%s", user_id)
            return None
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def update_user_info(self, new_username, new_bio, new_avatar_url):
        conn = create_connection()
        if not conn: return False
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            sql = "UPDATE Users SET username = %s, bio = %s, avatar_url = %s WHERE user_id = %s"
            cursor.execute(sql, (new_username, new_bio, new_avatar_url, user_id))
            conn.commit()
            return True
        except Exception as e:
            logger.exception("Failed to update profile for user_id=%s", auth.current_user.get('user_id') if auth.current_user else None)
            conn.rollback()
            return False
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin')
    def get_all_users(self, keyword="", role_filter="全部"):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            sql = """
            SELECT user_id, username, role, bio, avatar_url, created_at FROM Users
            WHERE (%s = '' OR username ILIKE %s)
              AND (%s = '全部' OR role = %s)
            ORDER BY created_at DESC, user_id DESC
            """
            pattern = f"%{keyword}%"
            cursor.execute(sql, (keyword, pattern, role_filter, role_filter))
            return cursor.fetchall()
        except Exception as e:
            print(f"❌ 获取用户列表失败: {e}")
            logger.exception("Failed to fetch users with keyword=%r role_filter=%r", keyword, role_filter)
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()

    def _is_last_sys_admin(self, cursor, user_id):
        cursor.execute("SELECT role FROM Users WHERE user_id = %s", (user_id,))
        row = cursor.fetchone()
        if not row or row[0] != 'sys_admin':
            return False
        cursor.execute("SELECT COUNT(*) FROM Users WHERE role = 'sys_admin'")
        return cursor.fetchone()[0] <= 1

    @auth.require_role('listener', 'music_admin', 'sys_admin')
    def delete_current_user(self):
        conn = create_connection()
        if not conn: return False, "数据库连接失败。"
        try:
            cursor = conn.cursor()
            user_id = auth.current_user['user_id']
            if self._is_last_sys_admin(cursor, user_id):
                conn.rollback()
                return False, "不能删除最后一个系统管理员。"
            cursor.execute("DELETE FROM Users WHERE user_id = %s RETURNING username", (user_id,))
            deleted = cursor.fetchone()
            if not deleted:
                conn.rollback()
                return False, "找不到当前账号。"
            conn.commit()
            return True, f"账号 {deleted[0]} 已注销。"
        except Exception as e:
            logger.exception("Failed to delete current user_id=%s", auth.current_user.get('user_id') if auth.current_user else None)
            conn.rollback()
            return False, f"注销账号失败: {e}"
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin')
    def admin_reset_user_password(self, user_id, new_password):
        if not new_password:
            return False, "新密码不能为空。"

        conn = create_connection()
        if not conn: return False, "数据库连接失败。"
        try:
            cursor = conn.cursor()
            cursor.execute(
                "UPDATE Users SET password_hash = %s WHERE user_id = %s RETURNING username",
                (hash_password(new_password), user_id)
            )
            updated = cursor.fetchone()
            if not updated:
                conn.rollback()
                return False, "找不到该用户。"
            conn.commit()
            return True, f"用户 {updated[0]} 的密码已重置。"
        except Exception as e:
            logger.exception("Failed to reset password for user_id=%s", user_id)
            conn.rollback()
            return False, f"重置密码失败: {e}"
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin')
    def admin_get_recent_content(self, limit=50):
        conn = create_connection()
        if not conn: return []
        try:
            cursor = conn.cursor()
            safe_limit = max(int(limit), 1)
            sql = """
            SELECT 'post' AS content_type, p.post_id AS content_id, u.username, p.title, p.content, p.created_at
            FROM Posts p
            JOIN Users u ON p.user_id = u.user_id
            UNION ALL
            SELECT 'song_comment' AS content_type, c.comment_id AS content_id, u.username, s.title, c.content, c.created_at
            FROM Comments c
            JOIN Users u ON c.user_id = u.user_id
            JOIN Songs s ON c.song_id = s.song_id
            UNION ALL
            SELECT 'post_comment' AS content_type, pc.pcomment_id AS content_id, u.username, p.title, pc.content, pc.created_at
            FROM Post_Comments pc
            JOIN Users u ON pc.user_id = u.user_id
            JOIN Posts p ON pc.post_id = p.post_id
            ORDER BY created_at DESC
            LIMIT %s;
            """
            cursor.execute(sql, (safe_limit,))
            return cursor.fetchall()
        except Exception:
            logger.exception("Failed to fetch recent content for moderation")
            return []
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin')
    def admin_delete_content(self, content_type, content_id):
        table_map = {
            'post': ('Posts', 'post_id'),
            'song_comment': ('Comments', 'comment_id'),
            'post_comment': ('Post_Comments', 'pcomment_id'),
        }
        if content_type not in table_map:
            return False, "内容类型无效。"

        conn = create_connection()
        if not conn: return False, "数据库连接失败。"
        try:
            cursor = conn.cursor()
            table_name, id_column = table_map[content_type]
            cursor.execute(
                f"DELETE FROM {table_name} WHERE {id_column} = %s RETURNING {id_column}",
                (content_id,)
            )
            deleted = cursor.fetchone()
            if not deleted:
                conn.rollback()
                return False, "找不到该内容。"
            conn.commit()
            return True, f"已删除 {content_type} #{content_id}。"
        except Exception as e:
            logger.exception("Failed to delete moderated content type=%s id=%s", content_type, content_id)
            conn.rollback()
            return False, f"删除内容失败: {e}"
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin')
    def admin_create_user(self, username, password, role):
        if role not in ('sys_admin', 'music_admin', 'listener'):
            return False, "角色无效。"
        if not username or not password:
            return False, "用户名和密码不能为空。"

        conn = create_connection()
        if not conn: return False, "数据库连接失败。"
        try:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO Users (username, password_hash, role) VALUES (%s, %s, %s) RETURNING user_id",
                (username, hash_password(password), role)
            )
            new_user_id = cursor.fetchone()[0]
            conn.commit()
            return True, f"已创建用户 {username} (ID: {new_user_id})。"
        except Exception as e:
            logger.exception("Failed to create user %r with role=%s", username, role)
            conn.rollback()
            return False, f"创建用户失败，可能是用户名已存在: {e}"
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin')
    def admin_update_user_role(self, user_id, new_role):
        if new_role not in ('sys_admin', 'music_admin', 'listener'):
            return False, "角色无效。"

        conn = create_connection()
        if not conn: return False, "数据库连接失败。"
        try:
            cursor = conn.cursor()
            if new_role != 'sys_admin' and self._is_last_sys_admin(cursor, user_id):
                conn.rollback()
                return False, "不能降级最后一个系统管理员。"
            cursor.execute("UPDATE Users SET role = %s WHERE user_id = %s RETURNING username", (new_role, user_id))
            updated = cursor.fetchone()
            if not updated:
                conn.rollback()
                return False, "找不到该用户。"
            conn.commit()
            return True, f"用户 {updated[0]} 的角色已更新为 {new_role}。"
        except Exception as e:
            logger.exception("Failed to update user_id=%s role to %s", user_id, new_role)
            conn.rollback()
            return False, f"修改角色失败: {e}"
        finally:
            if conn:
                cursor.close()
                conn.close()

    @auth.require_role('sys_admin')
    def admin_delete_user(self, user_id):
        if auth.current_user and user_id == auth.current_user['user_id']:
            return False, "不能删除当前登录的管理员账号。"

        conn = create_connection()
        if not conn: return False, "数据库连接失败。"
        try:
            cursor = conn.cursor()
            if self._is_last_sys_admin(cursor, user_id):
                conn.rollback()
                return False, "不能删除最后一个系统管理员。"
            cursor.execute("DELETE FROM Users WHERE user_id = %s RETURNING username", (user_id,))
            deleted = cursor.fetchone()
            if not deleted:
                conn.rollback()
                return False, "找不到该用户。"
            conn.commit()
            return True, f"用户 {deleted[0]} 已删除。"
        except Exception as e:
            logger.exception("Failed to delete user_id=%s", user_id)
            conn.rollback()
            return False, f"删除用户失败: {e}"
        finally:
            if conn:
                cursor.close()
                conn.close()

    def _insert_test_data(self):
        conn = create_connection()
        if not conn: return
        cursor = conn.cursor()
        try:
            cursor.execute("SELECT count(*) FROM Artists WHERE artist_id = 1")
            if cursor.fetchone()[0] == 0:
                cursor.execute("INSERT INTO Artists (artist_id, name) VALUES (1, '周杰伦')")
                cursor.execute("INSERT INTO Artists (artist_id, name) VALUES (2, 'Taylor Swift')")
                
                cursor.execute("INSERT INTO Albums (album_id, title, artist_id) VALUES (1, '七里香', 1)")
                cursor.execute("INSERT INTO Albums (album_id, title, artist_id) VALUES (2, '1989', 2)")
                
                cursor.execute("INSERT INTO Songs (song_id, title, artist_id, album_id, duration_seconds) VALUES (1, '七里香', 1, 1, 299)")
                cursor.execute("INSERT INTO Songs (song_id, title, artist_id, album_id, duration_seconds) VALUES (2, '搁浅', 1, 1, 238)")
                cursor.execute("INSERT INTO Songs (song_id, title, artist_id, album_id, duration_seconds) VALUES (3, 'Blank Space', 2, 2, 231)")
                
            cursor.execute("SELECT setval('artists_artist_id_seq', (SELECT MAX(artist_id) FROM Artists))")
            cursor.execute("SELECT setval('albums_album_id_seq', (SELECT MAX(album_id) FROM Albums))")
            cursor.execute("SELECT setval('songs_song_id_seq', (SELECT MAX(song_id) FROM Songs))")
            
            conn.commit()
            print("\n✅ 测试用例环境检查完毕：测试歌曲已就绪！")
        except Exception as e:
            print(f"\n插入数据失败(可能是ID冲突无需重复插入): {e}")
            logger.exception("Failed to insert test data")
        finally:
            if conn:
                cursor.close()
                conn.close()

if __name__ == "__main__":
    mm = MusicManager()
    mm._insert_test_data()
    print("\n--- 搜歌名：比如我们仅仅输入'里香' (精准命中'七里香') ---")
    mm.search_songs("里香")
    
    print("\n=== 以下是 增删改 操作的满分测试 ===")
    print("\n[无权限测试] 未登录状态下，尝试添加新歌曲:")
    mm.add_song("夜的第七章", 1, 1, 220)
    
    print("\n[有权限测试] 登录 music_admin 身份进行操作:")
    try:
        add_user.__wrapped__("test_music_admin", "123", "music_admin")
    except Exception as e:
        logger.info("Skipped creating test_music_admin, likely already exists: %s", e)
    auth.login("test_music_admin", "123")
    
    print("\n1. 演示【增加】: 添加歌曲 '夜的第七章'")
    new_song_id = mm.add_song("夜的第七章", 1, 1, 220)
    mm.search_songs("第七章")

    print("\n2. 演示【修改】: 觉得时长填错了，把 '夜的第七章' 时长改为 300 秒，但不动其他参数")
    mm.update_song(new_song_id, new_duration=300)
    mm.search_songs("第七章")

    print("\n3. 演示【删除】: 把刚刚那首 '夜的第七章' 删掉")
    mm.delete_song(new_song_id)
    mm.search_songs("第七章")
    
    auth.logout()
    
    print("\n--- 搜歌手：比如我们输入'周杰伦' (模糊命中他的所有歌) ---")
    mm.search_songs("周杰伦")
    
    print("\n--- 搜专辑：比如我们输入'1989' (模糊命中这个专辑里所有的英文歌) ---")
    mm.search_songs("1989")
    
    print("\n--- 不存在的搜索 ---")
    mm.search_songs("陶喆")
    
    print("\n=== 阶段C：以下是 歌单(多对多关联+聚合统计) 操作测试 ===")
    try:
        add_user.__wrapped__("test_listener", "123", "listener")
    except Exception as e:
        logger.info("Skipped creating test_listener, likely already exists: %s", e)
    auth.login("test_listener", "123")
    
    print("\n1. 演示【建单】: 听众创建名为 '睡前轻音乐' 的歌单")
    pl_id = mm.create_playlist("睡前轻音乐")
    
    if pl_id:
        print("\n2. 演示【查单】: 查看我刚刚建的歌单")
        mm.get_my_playlists()
        
        print("\n3. 演示【收藏】: 把 '七里香'(ID:1) 和 'Blank Space'(ID:3) 加入歌单")
        mm.add_to_playlist(pl_id, 1)
        mm.add_to_playlist(pl_id, 3)
        
        print("\n4. 演示【详情和聚合统计】: 多表联查查看 '睡前轻音乐' 里的歌曲并聚合计算总时长")
        mm.view_playlist(pl_id)
        
    auth.logout()
