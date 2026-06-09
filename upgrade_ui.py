import re
from pathlib import Path

app_file = Path(__file__).resolve().parent / 'app.py'
with open(app_file, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update render_song_card method signature and implementation
old_sig = 'def render_song_card(song_id, song_name, artist, album, duration, audio_url=None, count_info="", key_prefix="search"):'
new_sig = 'def render_song_card(song_id, song_name, artist, album, duration, audio_url=None, cover_url=None, count_info="", key_prefix="search"):'
text = text.replace(old_sig, new_sig)

old_card_head = '''        title_text = f"{count_info}🎵 {song_name} - {artist} (专辑: {album}) [{duration}s]"
        with st.expander(title_text):
            if audio_url:
                st.audio(audio_url)'''
new_card_head = '''        title_text = f"{count_info}🎵 {song_name} - {artist} (专辑: {album}) [{duration}s]"
        with st.expander(title_text):
            col_img, col_info = st.columns([1, 4])
            with col_img:
                if cover_url:
                    st.image(cover_url, use_container_width=True)
                else:
                    st.write("💿 暂无封面")
            with col_info:
                if audio_url:
                    st.audio(audio_url)'''
text = text.replace(old_card_head, new_card_head)

# 2. Fix Tuple Unpackings
# search_songs (7 elements)
# old: render_song_card(row[0], row[1], row[2], row[3], row[4], row[5], key_prefix="search")
# Wait, let's just make search_songs fetch dynamically
text = text.replace('def search_songs', 'def xxxx') # dummy, we use re.sub for all tuple matches

# Playlist
text = text.replace('s_id, s_name, s_art, s_alb, s_dur, s_aud = row', 's_id, s_name, s_art, s_alb, s_dur, s_aud, s_cov = row')
text = text.replace('render_song_card(s_id, s_name, s_art, s_alb, s_dur, audio_url=s_aud, key_prefix=f"pl_{view_pl_id}_{s_id}")', 
                    'render_song_card(s_id, s_name, s_art, s_alb, s_dur, audio_url=s_aud, cover_url=s_cov, key_prefix=f"pl_{view_pl_id}_{s_id}")')

# Rankings likes
text = text.replace('s_id, s_name, s_art, s_alb, s_dur, count, s_aud = row', 's_id, s_name, s_art, s_alb, s_dur, count, s_aud, s_cov = row')
text = text.replace('audio_url=s_aud, count_info=f"🏅 Top', 'audio_url=s_aud, cover_url=s_cov, count_info=f"🏅 Top')


# Search
text = text.replace('render_song_card(row[0], row[1], row[2], row[3], row[4], row[5], key_prefix="search")',
                    'render_song_card(row[0], row[1], row[2], row[3], row[4], row[5], row[6], key_prefix="search")')

# Posts (v_user_posts returns 14 elements)
old_post_unpack = 'pid, ptitle, pcontent, ptime, p_uid, p_uname, p_uavatar, s_id, s_title, a_name, al_title, s_dur, s_aud = row'
new_post_unpack = 'pid, ptitle, pcontent, ptime, p_uid, p_uname, p_uavatar, s_id, s_title, a_name, al_title, s_cov, s_dur, s_aud = row'

text = text.replace(old_post_unpack, new_post_unpack)

text = text.replace('render_song_card(s_id, s_title, a_name, al_title, s_dur, audio_url=s_aud, key_prefix=f"f_song_{pid}_{s_id}")',
                    'render_song_card(s_id, s_title, a_name, al_title, s_dur, audio_url=s_aud, cover_url=s_cov, key_prefix=f"f_song_{pid}_{s_id}")')

# User Avatar in Profile
old_uavatar = '''        if not u_info:
            st.warning("该用户不存在或已注销")
        else:
            uid, uname, urole, ubio, uavatar, utime = u_info

            st.header(f"👤 {uname} 的个人主页")'''

new_uavatar = '''        if not u_info:
            st.warning("该用户不存在或已注销")
        else:
            uid, uname, urole, ubio, uavatar, utime = u_info

            u_col1, u_col2 = st.columns([1, 5])
            with u_col1:
                if uavatar:
                    st.image(uavatar, use_container_width=True)
                else:
                    st.write("👤 暂无头像")
            with u_col2:
                st.header(f" {uname} 的个人主页")'''
text = text.replace(old_uavatar, new_uavatar)

# User Avatar in My Profile Tab
old_myavatar = '''        with tab_mine:
            st.header("👤 我的" )
            
            if not st.session_state.logged_in_user_id:
                st.info("尚未登录，请先在下方登录")'''
new_myavatar = '''        with tab_mine:
            st.header("👤 我的" )
            
            if not st.session_state.logged_in_user_id:
                st.info("尚未登录，请先在下方登录")'''
text = text.replace(old_myavatar, new_myavatar)

old_myinfo = '''                # 我的账号资料
                u_info = mm.get_user_info(cur_uid)
                if u_info:
                    uid, uname, urole, ubio, uavatar, utime = u_info
                    st.write(f"**用户名:** {uname}")'''
new_myinfo = '''                # 我的账号资料
                u_info = mm.get_user_info(cur_uid)
                if u_info:
                    uid, uname, urole, ubio, uavatar, utime = u_info
                    u_col1, u_col2 = st.columns([1, 4])
                    with u_col1:
                        if uavatar:
                            st.image(uavatar, use_container_width=True)
                    with u_col2:
                        st.write(f"**用户名:** {uname}")'''
text = text.replace(old_myinfo, new_myinfo)

# Replace author avatar in forum
old_f_avatar = '''                    st.markdown(f"**{p_uname}** 发起:")
                    with st.expander(f"📄 {ptitle} (发布于 {ptime.strftime('%m-%d %H:%M')})"):'''
new_f_avatar = '''                    c_av, c_desc = st.columns([1, 10])
                    with c_av:
                        if p_uavatar:
                            st.image(p_uavatar, width=40)
                    with c_desc:
                        st.markdown(f"**{p_uname}** 发起:")
                    with st.expander(f"📄 {ptitle} (发布于 {ptime.strftime('%m-%d %H:%M')})"):'''
text = text.replace(old_f_avatar, new_f_avatar)

with open(app_file, 'w', encoding='utf-8') as f:
    f.write(text)
    
print("App updated!")
