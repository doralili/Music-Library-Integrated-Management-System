import streamlit as st

import base64
import os
from contextlib import nullcontext

def get_avatar_src(avatar_path):
    if not avatar_path:
        return None
    if str(avatar_path).startswith('http'):
        return avatar_path
    if str(avatar_path).startswith('avatars/') and os.path.exists(avatar_path):
        with open(avatar_path, "rb") as image_file:
            encoded_string = base64.b64encode(image_file.read()).decode()
            extension = str(avatar_path).split('.')[-1].lower()
            return f"data:image/{extension};base64,{encoded_string}"
    return None

from auth import auth, add_user
from music_manager import MusicManager

APP_NAME = "EchoBase"
APP_FULL_NAME = "EchoBase 音乐社区"

st.set_page_config(page_title=APP_FULL_NAME, page_icon="🎵", layout="wide")
mm = MusicManager()

ADD_SONG_FORM_KEYS = (
    "add_song_title", "add_artist_name", "add_album_name",
    "add_song_genre", "add_audio_url", "add_audio_file",
)

def reset_add_song_form_state():
    for key in ADD_SONG_FORM_KEYS:
        st.session_state.pop(key, None)
    st.session_state.add_song_step = 1
    st.session_state.add_song_audio_mode = None

def apply_theme():
    st.markdown(
        """
        <style>
        :root {
            --echo-bg: #0b0f14;
            --echo-panel: #121820;
            --echo-panel-soft: #18212b;
            --echo-card: #1b2430;
            --echo-line: #2b3947;
            --echo-text: #f5f7fb;
            --echo-muted: #a7b1bd;
            --echo-green: #1ed760;
            --echo-blue: #52a8ff;
            --echo-warm: #ffb86b;
        }

        .stApp {
            color: var(--echo-text);
            background:
                radial-gradient(circle at 20% 0%, rgba(30, 215, 96, 0.18), transparent 28rem),
                radial-gradient(circle at 84% 10%, rgba(82, 168, 255, 0.14), transparent 26rem),
                linear-gradient(180deg, #111923 0%, #0b0f14 42%, #080b10 100%);
        }

        .block-container {
            max-width: 1280px;
            padding-top: 1.6rem;
            padding-bottom: 3rem;
        }

        h1, h2, h3 {
            letter-spacing: 0;
            color: var(--echo-text);
        }

        h1 {
            font-weight: 780;
        }

        div[data-testid="stSidebar"] {
            background: #080b10;
            border-right: 1px solid var(--echo-line);
        }

        div[data-testid="stSidebar"] * {
            color: var(--echo-text) !important;
        }

        div[data-testid="stSidebar"] [data-testid="stMarkdownContainer"] p,
        div[data-testid="stSidebar"] [data-testid="stCaptionContainer"] {
            color: var(--echo-muted) !important;
        }

        div[data-testid="stTabs"] button {
            border-radius: 999px;
            color: var(--echo-muted);
            font-weight: 650;
            background: transparent;
            padding: 0.45rem 0.9rem;
            border-bottom-color: transparent !important;
            box-shadow: none !important;
        }

        div[data-testid="stTabs"] button[aria-selected="true"] {
            color: #08110c;
            background: var(--echo-green);
            border-bottom: 0 !important;
            box-shadow: none !important;
        }

        div[data-testid="stTabs"] [data-baseweb="tab-highlight"] {
            background-color: transparent !important;
        }

        div[data-testid="stTabs"] button[aria-selected="true"] * {
            color: #08110c !important;
        }

        div[data-testid="stExpander"] {
            border: 1px solid var(--echo-line);
            border-radius: 12px;
            background: linear-gradient(180deg, rgba(27, 36, 48, 0.96), rgba(18, 24, 32, 0.96));
            box-shadow: 0 16px 40px rgba(0, 0, 0, 0.24);
            overflow: hidden;
        }

        div[data-testid="stExpander"] summary,
        div[data-testid="stExpander"] summary * {
            color: var(--echo-text) !important;
            font-weight: 680;
        }

        div[data-testid="stAlert"] {
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.10);
            background: rgba(27, 36, 48, 0.92);
            color: var(--echo-text);
        }

        .stButton > button {
            border-radius: 999px;
            border: 1px solid rgba(255, 255, 255, 0.12);
            background: #222d3a;
            color: var(--echo-text);
            font-weight: 650;
            transition: transform 120ms ease, box-shadow 120ms ease, border-color 120ms ease, background 120ms ease;
        }

        .stButton > button:hover {
            transform: translateY(-1px);
            background: #2a3746;
            border-color: rgba(30, 215, 96, 0.55);
            box-shadow: 0 10px 24px rgba(0, 0, 0, 0.28);
        }

        .stButton > button[kind="primary"] {
            background: var(--echo-green);
            color: #07130b;
            border-color: var(--echo-green);
        }

        .stButton > button[kind="primary"] *,
        .echo-brand * {
            color: #07130b !important;
        }

        input, textarea, div[data-baseweb="select"] > div,
        div[data-baseweb="input"] > div {
            border-radius: 10px !important;
            background: #111821 !important;
            color: var(--echo-text) !important;
            border-color: var(--echo-line) !important;
        }

        input::placeholder,
        textarea::placeholder {
            color: #7f8a96 !important;
            opacity: 1 !important;
        }

        label, p, span, div[data-testid="stMarkdownContainer"] {
            color: var(--echo-text);
        }

        div[data-testid="stCaptionContainer"],
        .stMarkdown small {
            color: var(--echo-muted);
        }

        [data-testid="stMetricValue"],
        [data-testid="stMetricLabel"] {
            color: var(--echo-text);
        }

        [data-testid="stMetric"] {
            padding: 0.95rem 1rem;
            border: 1px solid var(--echo-line);
            border-radius: 12px;
            background: rgba(27, 36, 48, 0.84);
        }

        [data-testid="stDataFrame"],
        [data-testid="stTable"] {
            border: 1px solid var(--echo-line);
            border-radius: 12px;
            overflow: hidden;
            background: var(--echo-panel);
        }

        [data-testid="stHeader"] {
            background: rgba(8, 11, 16, 0.72);
            backdrop-filter: blur(14px);
        }

        hr {
            border-color: var(--echo-line);
        }

        .echo-hero {
            position: relative;
            padding: 4rem 3rem 3rem;
            margin-bottom: 1.25rem;
            border: 1px solid var(--echo-line);
            border-radius: 18px;
            background:
                linear-gradient(135deg, rgba(30, 215, 96, 0.22), transparent 36%),
                linear-gradient(225deg, rgba(82, 168, 255, 0.22), transparent 42%),
                linear-gradient(180deg, #1b2430 0%, #111821 100%);
            box-shadow: 0 24px 70px rgba(0, 0, 0, 0.32);
            overflow: hidden;
        }

        .echo-title {
            margin: 0;
            max-width: 820px;
            font-size: 3rem;
            line-height: 1.12;
            font-weight: 820;
            color: var(--echo-text);
        }

        .echo-subtitle {
            max-width: 650px;
            margin: 0.9rem 0 0;
            color: var(--echo-muted);
            font-size: 1.05rem;
        }

        .echo-brand {
            display: inline-flex;
            align-items: center;
            gap: 0.55rem;
            padding: 0.42rem 0.82rem;
            margin-bottom: 1rem;
            border-radius: 999px;
            color: #08110c;
            background: var(--echo-green);
            border: 1px solid rgba(255, 255, 255, 0.18);
            font-weight: 720;
        }

        .echo-hero::after {
            content: "";
            position: absolute;
            right: 3rem;
            bottom: -2.2rem;
            width: 13rem;
            height: 13rem;
            border-radius: 50%;
            border: 1.1rem solid rgba(245, 247, 251, 0.08);
            box-shadow: inset 0 0 0 2.2rem rgba(245, 247, 251, 0.04);
        }
        </style>
        """,
        unsafe_allow_html=True,
    )

apply_theme()

# ================= 状态同步 =================
if 'current_user' in st.session_state:
    auth.current_user = st.session_state.current_user
else:
    auth.current_user = None


if 'view_user_id' not in st.session_state:
    st.session_state.view_user_id = None

# 分页状态
if 'forum_page' not in st.session_state: st.session_state.forum_page = 1
if 'rank_likes_page' not in st.session_state: st.session_state.rank_likes_page = 1
if 'rank_comments_page' not in st.session_state: st.session_state.rank_comments_page = 1


# ================= 辅助函数: 头像点击跳转 =================
def go_to_user_profile(u_id):
    st.session_state.view_user_id = u_id

def back_to_main():
    st.session_state.view_user_id = None

# 如果未登录
if not auth.current_user:
    st.markdown(
        f"""
        <section class="echo-hero">
            <div class="echo-brand">🎵 {APP_NAME}</div>
            <h1 class="echo-title">{APP_FULL_NAME}</h1>
            <p class="echo-subtitle">围绕歌曲、专辑、歌单和乐评建立的轻量音乐数据空间。</p>
        </section>
        """,
        unsafe_allow_html=True,
    )
    st.write("---")
    col1, col2, col3 = st.columns([1, 2, 1])
    with col2:
        login_tab, reg_tab = st.tabs(["🔐 账号登录", "📝 免费注册"])
        with login_tab:
            st.info("提示: admin / admin123 (系统管理)\n\ntest_music_admin / 123 (音乐管理)\n\ntest_listener / 123 (听众)")
            username = st.text_input("用户名", key="l_usr")
            password = st.text_input("密码", type="password", key="l_pwd")
            if st.button("🚀 立即登录", use_container_width=True, type="primary"):
                if auth.login(username, password):
                    st.session_state.current_user = auth.current_user
                    reset_add_song_form_state()
                    st.session_state.add_song_owner_id = auth.current_user['user_id']
                    st.rerun()
                else:
                    st.error("❌ 用户名或密码错误！")
        with reg_tab:
            st.info("✨ 欢迎新用户，免费注册为听众！")
            reg_username = st.text_input("设置新用户名", key="r_usr")
            reg_password = st.text_input("设置密码", type="password", key="r_pwd")
            reg_confirm = st.text_input("再次输入密码", type="password", key="r_pwd_conf")
            if st.button("🔥 立即注册", type="primary", use_container_width=True):
                if not reg_username or not reg_password:
                    st.error("用户名和密码都不能为空！")
                elif reg_password != reg_confirm:
                    st.error("两次输入的密码不一致！")
                else:
                    try:
                        if add_user.__wrapped__(reg_username, reg_password, "listener"):
                            st.success("✅ 注册成功！请切换到 [🔐 账号登录] 面板进行登录！")
                            st.balloons()
                        else:
                            st.error("注册失败，可能是用户名已经被占用了。")
                    except Exception as e:
                        st.error(f"注册失败，可能用户名已经被占用了。详细记录: {e}")

else:
    # ====== 已登录：定义渲染歌曲卡片的组件 ======
       
    def render_song_card(song_id, song_name, artist, album, duration, audio_url=None, cover_url=None, count_info="", key_prefix="search", playlist_id=None):
        title_text = f"{count_info}🎵 {song_name} - {artist} (专辑: {album})" if count_info else f"🎵 {song_name} - {artist} (专辑: {album})"
        with st.expander(title_text):
            if audio_url:
                st.audio(audio_url)
            action_key = f"song_action_{key_prefix}_{song_id}"
            if playlist_id is not None:
                scol1, scol2, scol3, scol4, scol5 = st.columns([3, 1, 1, 1, 1])
            else:
                scol1, scol2, scol3, scol4 = st.columns([3, 1, 1, 1])
            with scol1:
                st.write(f"**歌曲ID:** {song_id} &nbsp;|&nbsp; **时长:** {duration if duration else '未知'}秒")
            with scol2:
                liked = mm.is_song_liked(song_id)
                btn_text = "💔 取消喜欢" if liked else "❤️ 喜欢此歌曲"
                if st.button(btn_text, key=f"like_btn_{key_prefix}_{song_id}", use_container_width=True):
                    action = mm.toggle_like_song(song_id)
                    if action == "liked":
                        st.toast("已自动加入歌单【我喜欢的歌曲】！", icon="❤️")
                    else:
                        st.toast("已从【我喜欢的歌曲】中移出。", icon="💔")
                    st.rerun()
            with scol3:
                if st.button("📁 加入歌单", key=f"open_pl_{key_prefix}_{song_id}", use_container_width=True):
                    st.session_state[action_key] = "playlist"
                    st.rerun()
            with scol4:
                if st.button("💬 歌曲评论", key=f"open_cmt_{key_prefix}_{song_id}", use_container_width=True):
                    st.session_state[action_key] = "comment"
                    st.rerun()
            if playlist_id is not None:
                with scol5:
                    if st.button("🗑️ 移出歌单", key=f"rm_pl_{key_prefix}_{playlist_id}_{song_id}", use_container_width=True):
                        ok, msg = mm.remove_from_playlist(playlist_id, song_id)
                        if ok:
                            st.success(msg)
                            st.rerun()
                        else:
                            st.error(msg)

            active_song_action = st.session_state.get(action_key)
            if active_song_action:
                st.divider()

            if active_song_action == "playlist":
                st.write("##### 📁 把这首歌加入歌单")
                my_playlists = mm.get_my_playlists()
                if my_playlists:
                    pl_opts = {f"{p[1]} (ID:{p[0]})": p[0] for p in my_playlists}
                    pl_col1, pl_col2 = st.columns([3, 1])
                    with pl_col1:
                        selected_pl = st.selectbox("选择目标歌单", options=list(pl_opts.keys()), key=f"sel_pl_{key_prefix}_{song_id}", label_visibility="collapsed")
                    with pl_col2:
                        if st.button("📥 加入", key=f"btn_pl_{key_prefix}_{song_id}", use_container_width=True):
                            target_id = pl_opts[selected_pl]
                            if mm.add_to_playlist(target_id, song_id):
                                st.toast(f"成功将《{song_name}》加入到歌单", icon="✅")
                                st.rerun()
                else:
                    st.caption("您还没有创建任何歌单，先去【🎧 收藏】里新建一个吧！")

            elif active_song_action == "comment":
                st.write("##### 💬 歌曲评论区")
                col_c1, col_c2 = st.columns([1, 1])
                with col_c1:
                    comment_key = f"cmt_text_{key_prefix}_{song_id}"
                    if st.session_state.pop(f"clear_{comment_key}", False):
                        st.session_state[comment_key] = ""
                    new_comment = st.text_area(f"写下你对《{song_name}》的评论...", height=100, key=comment_key)
                    if st.button("🚀 发送评论", key=f"cmt_btn_{key_prefix}_{song_id}"):
                        if new_comment.strip():
                            if mm.add_comment(song_id, new_comment):
                                st.success("评论发布成功！")
                                st.session_state[f"clear_{comment_key}"] = True
                                st.rerun()
                        else:
                            st.warning("评论内容不能为空！")
                
                with col_c2:
                    comments = mm.get_comments(song_id)
                    if comments:
                        st.caption(f"共 {len(comments)} 条评论:")
                        for c_id, c_uid, c_user, c_avatar, c_content, c_time in comments:
                            can_delete_comment = (
                                auth.current_user['user_id'] == c_uid or
                                auth.current_user['role'] in ('sys_admin', 'music_admin')
                            )
                            if can_delete_comment:
                                cn1, cn2, cn3 = st.columns([3, 1, 1])
                            else:
                                cn1, cn2 = st.columns([3, 1])
                            with cn1:
                                c_avatar_src = get_avatar_src(c_avatar)
                                if c_avatar_src:
                                    st.markdown(f"<img src='{c_avatar_src}' style='width:30px; height:30px; border-radius:50%; vertical-align:middle; margin-right:10px;'> **{c_user}**  ·  _{c_time.strftime('%Y-%m-%d %H:%M')}_", unsafe_allow_html=True)
                                else:
                                    ava_disp = c_avatar if c_avatar else "👤"
                                    st.markdown(f"**{ava_disp} {c_user}**  ·  _{c_time.strftime('%Y-%m-%d %H:%M')}_")
                            with cn2:
                                if st.button("看TA主页", key=f"go_u_{key_prefix}_{song_id}_{c_id}"):
                                    go_to_user_profile(c_uid)
                                    st.rerun()
                            if can_delete_comment:
                                with cn3:
                                    if st.button("删除评论", key=f"del_cmt_{key_prefix}_{song_id}_{c_id}"):
                                        if mm.delete_comment(c_id):
                                            st.success("评论已删除。")
                                            st.rerun()
                                        else:
                                            st.error("删除评论失败。")
                            st.info(c_content)
                    else:
                        st.info("还没有人对这首歌发表评论，快来抢沙发吧🛋️！")
    # ====== 侧边栏 ======
    with st.sidebar:
        # 获取当前用户实时信息
        me_info = mm.get_user_info(auth.current_user['user_id'])
        my_avatar = me_info[4] if me_info and me_info[4] else "👤"
        my_name = me_info[1] if me_info else auth.current_user['username']
        
        my_avatar_src = get_avatar_src(my_avatar)
        if my_avatar_src:
            st.markdown(f"## <img src='{my_avatar_src}' style='width:40px; height:40px; border-radius:50%; vertical-align:middle;'> {my_name}", unsafe_allow_html=True)
        else:
            st.markdown(f"## {my_avatar} {my_name}")
        st.write(f"🎖️ 身份：`{auth.current_user['role']}`")
        if me_info and me_info[3]:
            st.caption(f"📝 个性签名: {me_info[3]}")
        st.divider()
        if st.button("退出登录", use_container_width=True):
            auth.logout()
            st.session_state.pop('current_user')
            st.session_state.view_user_id = None
            reset_add_song_form_state()
            st.session_state.pop('add_song_owner_id', None)
            st.rerun()

    # ====== 页面顶栏 ======
    st.title(f"🎵 {APP_FULL_NAME}")

    # ================= 路由：如果是查看任意用户的信息页 =================
    if st.session_state.view_user_id:
        target_uid = st.session_state.view_user_id
        if st.button("🔙 返回主界面"):
            back_to_main()
            st.rerun()
            
        u_info = mm.get_user_info(target_uid)
        if not u_info:
            st.warning("该用户不存在或已注销")
        else:
            uid, uname, urole, ubio, uavatar, utime = u_info
            

            st.write("---")
            
            st.write("---")
            cc1, cc2 = st.columns([1, 4])
            with cc1:
                uavatar_src = get_avatar_src(uavatar)
                if uavatar_src:
                    st.markdown(f"<div style='text-align: center;'><img src='{uavatar_src}' style='width: 150px; height: 150px; border-radius: 50%;'></div>", unsafe_allow_html=True)
                else:
                    st.markdown(f"<h1 style='font-size: 80px; text-align: center;'>{uavatar if uavatar else '👤'}</h1>", unsafe_allow_html=True)
            with cc2:
                st.header(f"{uname} 的主页")
                st.write(f"**身份:** {urole} &nbsp;|&nbsp; **注册时间:** {utime.strftime('%Y-%m-%d')}")
                st.write(f"**个性签名:** {ubio if ubio else '这个人很懒，什么都没写~'}")
            
            st.divider()
            st.subheader(f"📝 {uname} 在论坛发布的帖子")
            user_posts = mm.get_user_posts(target_uid)
            if user_posts:
                for row in user_posts:
                    pid, ptitle, pcontent, ptime, p_uid, p_uname, p_uavatar, s_id, s_title, a_name, al_title, s_cov, s_dur, s_aud = row
                    with st.expander(f"📄 {ptitle} (发布于 {ptime.strftime('%m-%d %H:%M')})"):
                        st.markdown(pcontent)
                        if s_id:
                            st.info(f"🎧 TA推荐了歌曲：**{s_title}** - {a_name} (专辑: {al_title})")
            else:
                st.info("TA 还没有发布过任何帖子哦。")
                
    # ================= 路由：正常的主标签页界面 =================
    else:
        current_role = auth.current_user['role']
        render_listener_tabs = current_role == 'listener'
        if render_listener_tabs:
            tab_playlist, tab_search, tab_forum, tab_mine = st.tabs(["🎧 收藏", "🔍 发现音乐", "💬 论坛", "👤 我的"])
            tab_music = nullcontext()
            tab_sys = nullcontext()
        elif current_role == 'sys_admin':
            tab_forum, tab_music, tab_sys = st.tabs(["💬 论坛管理", "⚙️ 曲库管理", "👥 用户管理"])
            tab_playlist = tab_search = tab_mine = None
        elif current_role == 'music_admin':
            tab_forum, tab_music = st.tabs(["💬 论坛管理", "⚙️ 曲库管理"])
            tab_sys = nullcontext()
            tab_playlist = tab_search = tab_mine = None
        else:
            tab_playlist = tab_search = tab_mine = None
            tab_forum = nullcontext()
            tab_music = nullcontext()
            tab_sys = nullcontext()

        if render_listener_tabs:
            # ----------------- Tab 1: 收藏 (我的歌单) -----------------
            with tab_playlist:
                st.header("🎧 个人收藏与歌单")
            
                st.subheader("新建一个歌单")
                c_pl1, c_pl2 = st.columns([1, 2])
                with c_pl1:
                    if st.button("➕ 创建歌单", use_container_width=True, key="show_create_playlist"):
                        st.session_state.show_create_playlist_form = True

                    if st.session_state.get("show_create_playlist_form", False):
                        if st.session_state.pop("clear_new_playlist_name", False):
                            st.session_state.new_playlist_name = ""
                        new_pl_name = st.text_input("想要给它起个什么名字？", key="new_playlist_name")
                        if st.button("确认创建歌单", use_container_width=True, key="confirm_create_playlist"):
                            if new_pl_name:
                                if mm.create_playlist(new_pl_name):
                                    st.success(f"成功创建歌单: {new_pl_name}")
                                    st.session_state.clear_new_playlist_name = True
                                    st.session_state.show_create_playlist_form = False
                                    st.rerun()
                                else:
                                    st.error("创建失败。")
                            else:
                                st.warning("名字不能为空！")

                st.divider()
                st.subheader("📊 浏览我的歌单详细信息")
                playlists = mm.get_my_playlists()
                if playlists:
                    pl_options = {f"{p[1]} (ID:{p[0]})": p[0] for p in playlists}
                    with st.expander(f"📁 展开以选择要查看的歌单 (当前共 {len(playlists)} 个歌单)", expanded=True):
                        view_pl_name = st.selectbox("选择要查看的歌单", options=list(pl_options.keys()), key="view_pl", label_visibility="collapsed")
                        view_pl_id = pl_options[view_pl_name]
                
                    st.write(f"#### 💿 正在查看: {view_pl_name}")
                    if st.button("删除当前歌单", key=f"del_my_playlist_{view_pl_id}"):
                        if mm.delete_playlist(view_pl_id):
                            st.success("歌单已成功删除!")
            # 关键：删除成功后，立刻清空view_pl_id，避免后续渲染错误信息
                            st.session_state.view_pl_id = None
                            st.rerun()
                        else:
                            st.error("删除歌单失败")
                    songs = mm.view_playlist(view_pl_id)
                    if songs:
                        for row in songs:
                            s_id, s_name, s_art, s_alb, s_dur, s_aud, s_cov = row
                            render_song_card(
                                s_id, s_name, s_art, s_alb, s_dur,
                                audio_url=s_aud, cover_url=s_cov,
                                key_prefix=f"pl_{view_pl_id}_{s_id}",
                                playlist_id=view_pl_id
                            )
                    
                        total_time = sum(s[4] for s in songs if s[4])
                        st.info(f"📊 统计数据：共 {len(songs)} 首歌，总时长 {total_time // 60}分{total_time % 60}秒。")
                    else:
                        st.warning("该歌单中暂时还没有歌曲哦。")

        if render_listener_tabs:
            # ----------------- Tab 2: 搜索 (发现音乐) -----------------

            with tab_search:
                st.header("🔍 发现音乐 (搜索与榜单)")
                st.subheader("🏆 全站音乐排行榜")
                PAGE_SIZE = 10
                rank_likes, rank_comments = mm.get_rankings(limit=PAGE_SIZE, l_offset=(st.session_state.rank_likes_page-1)*PAGE_SIZE, c_offset=(st.session_state.rank_comments_page-1)*PAGE_SIZE)
            
                rtab1, rtab2 = st.tabs(["❤️ 最多喜欢", "💬 最多评论"])
                with rtab1:
                    if rank_likes:
                        for i, row in enumerate(rank_likes):
                            s_id, s_name, s_art, s_alb, s_dur, count, s_aud, s_cov = row
                            render_song_card(s_id, s_name, s_art, s_alb, s_dur, audio_url=s_aud, cover_url=s_cov, count_info=f"🏅 Top {(st.session_state.rank_likes_page-1)*PAGE_SIZE+i+1} (❤️ {count}) | ", key_prefix=f"rankl_{s_id}")
                    else: st.info("还没有人喜欢过歌曲呢！")

                    # 喜欢榜分页组件
                    lc1, lc2, lc3 = st.columns([1,2,1])
                    with lc1:
                        if st.session_state.rank_likes_page > 1:
                            if st.button("上一页", key="btn_rl_prev"): st.session_state.rank_likes_page -= 1; st.rerun()
                    with lc2:
                        st.write(f"当前第 {st.session_state.rank_likes_page} 页")
                    with lc3:
                        if rank_likes and len(rank_likes) == PAGE_SIZE:
                            if st.button("下一页", key="btn_rl_next"): st.session_state.rank_likes_page += 1; st.rerun()
                with rtab2:
                    if rank_comments:
                        for i, row in enumerate(rank_comments):
                            s_id, s_name, s_art, s_alb, s_dur, count, s_aud, s_cov = row
                            render_song_card(s_id, s_name, s_art, s_alb, s_dur, audio_url=s_aud, cover_url=s_cov, count_info=f"🏅 Top {(st.session_state.rank_comments_page-1)*PAGE_SIZE+i+1} (💬 {count}评) | ", key_prefix=f"rankc_{s_id}")
                    else: st.info("暂时还没有评论，快去抢沙发！")

                    # 评论榜分页组件
                    cc1, cc2, cc3 = st.columns([1,2,1])
                    with cc1:
                        if st.session_state.rank_comments_page > 1:
                            if st.button("上一页", key="btn_rc_prev"): st.session_state.rank_comments_page -= 1; st.rerun()
                    with cc2:
                        st.write(f"当前第 {st.session_state.rank_comments_page} 页")
                    with cc3:
                        if rank_comments and len(rank_comments) == PAGE_SIZE:
                            if st.button("下一页", key="btn_rc_next"): st.session_state.rank_comments_page += 1; st.rerun()
            
                st.write("---")
                st.subheader("🔎 搜索站内音乐")
                search_kw = st.text_input("输入关键词（歌名/歌手/专辑）：", "")
                if st.button("开始搜索", use_container_width=True) or search_kw:
                    results = mm.search_songs(search_kw)
                    if results:
                        for row in results:
                            render_song_card(row[0], row[1], row[2], row[3], row[4], row[5], row[6], key_prefix="search")
                    else:
                        st.warning("空空如也，换个词试试吧~")

        # ----------------- Tab 3: 论坛 (音乐交流) -----------------
        with tab_forum:
            st.header("💬 音乐交流论坛")
            
            # 发布新帖
            if 'p_song_id' not in st.session_state:
                st.session_state.p_song_id = 0
            if 'p_song_label' not in st.session_state:
                st.session_state.p_song_label = ""
            if 'p_song_search_results' not in st.session_state:
                st.session_state.p_song_search_results = []
            if 'p_song_search_kw' not in st.session_state:
                st.session_state.p_song_search_kw = ""
            if st.session_state.pop('clear_post_search_kw', False):
                st.session_state.post_search_kw = ""
            if st.session_state.pop('clear_post_form', False):
                st.session_state.post_title = ""
                st.session_state.post_content = ""

            with st.expander("✍️ 发布新帖子", expanded=False):
                p_title = st.text_input("帖子标题：", key="post_title")
                p_content = st.text_area("帖子正文内容：", height=150, key="post_content")
                
                st.write("**为你的帖子配上一首推荐曲目（可选）**")
                scol1, scol2 = st.columns([3, 1])
                with scol1:
                    search_kw = st.text_input("🔍 搜索想推荐的音乐（歌名/歌手/专辑）", key="post_search_kw")
                with scol2:
                    st.write("") # 补齐高度
                    st.write("")
                    do_search = st.button("查找")

                if st.session_state.p_song_id > 0:
                    selected_song_label = st.session_state.p_song_label or f"歌曲 ID {st.session_state.p_song_id}"
                    ss1, ss2 = st.columns([4, 1])
                    with ss1:
                        st.success(f"已附加推荐曲目：{selected_song_label}")
                    with ss2:
                        if st.button("❌ 取消推荐"):
                            st.session_state.p_song_id = 0
                            st.session_state.p_song_label = ""
                            st.rerun()

                if search_kw and do_search:
                    st.session_state.p_song_search_kw = search_kw
                    st.session_state.p_song_search_results = mm.search_songs(search_kw)

                search_res = st.session_state.p_song_search_results
                if search_res:
                    for row in search_res:
                        s_id, s_title, a_name, al_title, s_dur, s_aud, s_cov = row[:7]
                        with st.container():
                            cc1, cc2, cc3 = st.columns([5, 2, 2])
                            with cc1: st.write(f"🎵 **{s_title}** - {a_name}")
                            with cc2: st.caption(al_title)
                            with cc3:
                                if st.button("✅ 选定配乐", key=f"sel_ps_{s_id}"):
                                    st.session_state.p_song_id = s_id
                                    st.session_state.p_song_label = f"{s_title} - {a_name}"
                                    st.session_state.p_song_search_results = []
                                    st.session_state.p_song_search_kw = ""
                                    st.session_state.clear_post_search_kw = True
                                    st.rerun()
                elif search_kw and do_search:
                    st.warning("没有找到相关音乐")

                if st.button("🚀 马上发布我的贴子", type="primary"):
                    if not p_title.strip() or not p_content.strip():
                        st.error("标题和内容都不能为空！")
                    else:
                        r_sid = st.session_state.p_song_id if st.session_state.p_song_id > 0 else None
                        if mm.create_post(p_title, p_content, r_sid):
                            st.success("发布成功！")
                            st.session_state.p_song_id = 0 # 清空选择状态
                            st.session_state.p_song_label = ""
                            st.session_state.p_song_search_results = []
                            st.session_state.p_song_search_kw = ""
                            st.session_state.clear_post_form = True
                            st.session_state.clear_post_search_kw = True
                            st.rerun()
                        else: st.error("发布失败（请系统状态！）")
            st.divider()
            st.subheader("🌐 论坛大厅")
            FORUM_PAGE_SIZE = 5
            posts = mm.get_all_posts(limit=FORUM_PAGE_SIZE, offset=(st.session_state.forum_page-1)*FORUM_PAGE_SIZE)
            if posts:
                for row in posts:
                    pid, ptitle, pcontent, ptime, p_uid, p_uname, p_uavatar, s_id, s_title, a_name, al_title, s_cov, s_dur, s_aud = row
                    can_delete_post = (
                        auth.current_user['user_id'] == p_uid or
                        auth.current_user['role'] in ('sys_admin', 'music_admin')
                    )
                    ava = "👤"
                    if p_uavatar:
                        ava = "🖼️" if get_avatar_src(p_uavatar) else p_uavatar
                    
                    with st.expander(f"📄 {ptitle}  (✍️ {ava} {p_uname} 发布于 {ptime.strftime('%m-%d %H:%M')})"):
                        if can_delete_post:
                            fcol1, fcol2, fcol3 = st.columns([5, 1, 1])
                        else:
                            fcol1, fcol2 = st.columns([5, 1])
                        with fcol1:
                            st.markdown(f"**📝 帖子内容:**\n\n{pcontent}")
                        with fcol2:
                            if st.button("此人主页", key=f"f_avatar_{pid}", use_container_width=True):
                                go_to_user_profile(p_uid)
                                st.rerun()
                        if can_delete_post:
                            with fcol3:
                                if st.button("删除帖子", key=f"del_post_{pid}", use_container_width=True):
                                    if mm.delete_post(pid):
                                        st.success("帖子已删除。")
                                        st.rerun()
                                    else:
                                        st.error("删除帖子失败。")

                        if s_id:
                            st.write("---")
                            st.write("**🎶 楼主在本帖里强烈推荐此歌曲：**")
                            render_song_card(s_id, s_title, a_name, al_title, s_dur, audio_url=s_aud, cover_url=s_cov, key_prefix=f"f_song_{pid}_{s_id}")
                            
                        st.write("---")
                        st.write("##### 💬 帖子回声(回帖区)")
                        # 展示回帖
                        p_comments = mm.get_post_comments(pid)
                        if p_comments:
                            for pc_id, pc_uid, pc_uname, pc_uavatar, pc_content, pc_time in p_comments:
                                can_delete_post_comment = (
                                    auth.current_user['user_id'] == pc_uid or
                                    auth.current_user['role'] in ('sys_admin', 'music_admin')
                                )
                                if can_delete_post_comment:
                                    scol1, scol2, scol3 = st.columns([5, 1, 1])
                                else:
                                    scol1, scol2 = st.columns([5, 1])
                                with scol1:
                                    pc_uavatar_src = get_avatar_src(pc_uavatar)
                                    if pc_uavatar_src:
                                        st.markdown(f"<img src='{pc_uavatar_src}' style='width:30px; height:30px; border-radius:50%; vertical-align:middle; margin-right:10px;'> **{pc_uname}** _{pc_time.strftime('%m-%d %H:%M')}_ :", unsafe_allow_html=True)
                                    else:
                                        pc_ava = pc_uavatar if pc_uavatar else "👤"
                                        st.markdown(f"**{pc_ava} {pc_uname}** _{pc_time.strftime('%m-%d %H:%M')}_ :")
                                    st.info(pc_content)
                                with scol2:
                                    if st.button("看TA主页", key=f"go_upc_{pid}_{pc_id}"):
                                        go_to_user_profile(pc_uid)
                                        st.rerun()
                                if can_delete_post_comment:
                                    with scol3:
                                        if st.button("删除回帖", key=f"del_pc_{pid}_{pc_id}"):
                                            if mm.delete_post_comment(pc_id):
                                                st.success("回帖已删除。")
                                                st.rerun()
                                            else:
                                                st.error("删除回帖失败。")
                        else:
                            st.caption("还没有人回帖，快来这里各抒己见~")
                            
                        reply_key = f"n_pc_{pid}"
                        if st.session_state.pop(f"clear_{reply_key}", False):
                            st.session_state[reply_key] = ""
                        n_c = st.text_input("我想回复该帖...", key=reply_key)
                        if st.button("发送回帖", key=f"btn_pc_{pid}"):
                            if n_c.strip():
                                mm.add_post_comment(pid, n_c)
                                st.session_state[f"clear_{reply_key}"] = True
                                st.rerun()
                                
            # 论坛帖子分页控件
            fc1, fc2, fc3 = st.columns([1,2,1])
            with fc1:
                if st.session_state.forum_page > 1:
                    if st.button("上一页", key="f_prev"): st.session_state.forum_page -= 1; st.rerun()
            with fc2:
                st.write(f"当前帖子大厅页码: {st.session_state.forum_page}")
            with fc3:
                if posts and len(posts) == FORUM_PAGE_SIZE:
                    if st.button("下一页", key="f_next"): st.session_state.forum_page += 1; st.rerun()
            if not posts:
                st.info("论坛还是冷冷清清的呢，快去发布第一篇帖子吧！")

        if render_listener_tabs:
            # ----------------- Tab 4: 我的 (个人信息) -----------------
            with tab_mine:
                st.header("👤 我的" )
            
                mc1, mc2 = st.columns([1, 2])
                with mc1:
                    st.subheader("⚙️ 编辑个人资料")
                    my_id = auth.current_user['user_id']
                    my_info = mm.get_user_info(my_id)
                
                    curr_name = my_info[1] if my_info else auth.current_user['username']
                    curr_bio = my_info[3] if my_info and my_info[3] else ""
                    curr_avatar = my_info[4] if my_info and my_info[4] else "🧑‍💻"
                
                    new_uname = st.text_input("修改用户名", value=curr_name)
                
                    # 更换为支持本地图片的上传组件
                    avatar_file = st.file_uploader("🖼️ 上传本地头像", type=['png', 'jpg', 'jpeg'])
                    new_avatar = st.text_input("或者使用URL/字符", value=curr_avatar, help="若上传了图片，此输入将被忽略")
                
                    new_bio = st.text_area("完善个人简介", value=curr_bio)

                    if st.button("💾 保存我的资料更改", type="primary", use_container_width=True):
                        if not new_uname.strip(): st.error("用户名不能为空")
                        else:
                            final_avatar = new_avatar
                            if avatar_file is not None:
                                if not os.path.exists("avatars"):
                                    os.makedirs("avatars")
                                ext = avatar_file.name.split('.')[-1]
                                avatar_path = f"avatars/user_{my_id}.{ext}"
                                with open(avatar_path, "wb") as f:
                                    f.write(avatar_file.getbuffer())
                                final_avatar = avatar_path

                            if mm.update_user_info(new_uname, new_bio, final_avatar):
                                st.success("您的资料更新成功！")
                                st.rerun()
                            else:
                                st.error("更新失败（可能是用户名与系统里的其他用户重复了！）")

                    st.divider()
                    st.subheader("🧨 注销账号")
                    st.caption("此操作会永久删除当前账号及其关联数据，执行后需要重新注册。")
                    confirm_delete_name = st.text_input("请输入当前用户名以确认注销", key="confirm_delete_account_name")
                    if st.button("永久注销我的账号", key="btn_delete_current_account", use_container_width=True):
                        if confirm_delete_name.strip() != curr_name:
                            st.error("确认用户名不匹配，已取消注销。")
                        else:
                            ok, msg = mm.delete_current_user()
                            if ok:
                                st.success(msg)
                                auth.logout()
                                st.session_state.pop('current_user', None)
                                st.session_state.view_user_id = None
                                reset_add_song_form_state()
                                st.session_state.pop('add_song_owner_id', None)
                                st.rerun()
                            else:
                                st.error(msg)
            
                with mc2:
                    st.subheader(f"📝 {curr_name}，看看你在论坛发过的帖子")
                    user_posts = mm.get_user_posts(my_id)
                    if user_posts:
                        for row in user_posts:
                            pid, ptitle, pcontent, ptime, p_uid, p_uname, p_uavatar, s_id, s_title, a_name, al_title, s_cov, s_dur, s_aud = row
                            with st.expander(f"📄 {ptitle} (发布于 {ptime.strftime('%m-%d %H:%M')})"):
                                st.markdown(pcontent)
                                if s_id:
                                    st.info(f"🎧 你在这篇帖子里强推了歌曲：**{s_title}**")
                                if st.button("去论坛大厅亲自查看我的原帖反馈", key=f"my_p_g_{pid}"):
                                    st.info("这需要请您直接切换到【论坛】板块然后在下拉大厅中查找您的这篇帖子哦~")
                    else:
                        st.info("你还没有在论坛发布过任何帖子哦，快去【论坛】水一贴吧！")

        if current_role in ('sys_admin', 'music_admin'):
            # ----------------- Tab 5: 曲库管理 -----------------
                
            with tab_music:
                st.header("⚙️ 音乐曲库资源管理")
                if auth.current_user['role'] not in ('sys_admin', 'music_admin'):
                    st.error("⛔ 权限不足，仅系统管理员/曲库管理员可访问")
                else:
                    st.info("✅ 权限验证通过，可管理全库歌曲")

                    # ==================== Add song wizard ====================
                    with st.expander("➕ 单独添加新歌曲", expanded=True):
                        if 'add_song_step' not in st.session_state:
                            st.session_state.add_song_step = 1
                        current_user_id = auth.current_user['user_id']
                        if st.session_state.get('add_song_owner_id') != current_user_id:
                            reset_add_song_form_state()
                            st.session_state.add_song_owner_id = current_user_id
                        if st.session_state.pop('reset_add_song_form', False):
                            reset_add_song_form_state()
                            st.session_state.add_song_owner_id = current_user_id
                        if 'add_song_audio_mode' not in st.session_state:
                            st.session_state.add_song_audio_mode = None

                        step = st.session_state.add_song_step
                        n_title = st.session_state.get('add_song_title', '')
                        artist_name = st.session_state.get('add_artist_name', '')
                        album_name = st.session_state.get('add_album_name', '')
                        genre = st.session_state.get('add_song_genre', '')
                        final_url = None
                        auto_dur = None

                        if step == 1:
                            n_title = st.text_input("歌曲名称 *", key="add_song_title")
                            can_next = bool(n_title.strip())
                            if st.button("下一步", type="primary", use_container_width=True):
                                if can_next:
                                    st.session_state.add_song_step = 2
                                    st.rerun()
                                else:
                                    st.warning("请先填写歌曲名称")

                        elif step == 2:
                            artist_name = st.text_input("歌手名称 *", key="add_artist_name")
                            album_name = st.text_input("专辑名称 *", key="add_album_name")
                            can_next = bool(artist_name.strip() and album_name.strip())
                            if st.button("下一步", type="primary", use_container_width=True):
                                if can_next:
                                    st.session_state.add_song_step = 3
                                    st.rerun()
                                else:
                                    st.warning("请先填写歌手名称和专辑名称")

                        elif step == 3:
                            genre = st.text_input("歌曲曲风（可留空）", placeholder="例如：流行、古风、摇滚", key="add_song_genre")
                            if st.button("下一步", type="primary", use_container_width=True):
                                st.session_state.add_song_step = 4
                                st.rerun()

                        else:
                            a1, a2 = st.columns(2)
                            if a1.button("在线URL", use_container_width=True):
                                st.session_state.add_song_audio_mode = "url"
                            if a2.button("本地上传MP3", use_container_width=True):
                                st.session_state.add_song_audio_mode = "upload"

                            if st.session_state.add_song_audio_mode == "url":
                                final_url = st.text_input("音频URL *", key="add_audio_url")
                            elif st.session_state.add_song_audio_mode == "upload":
                                up = st.file_uploader("上传MP3 *", type=["mp3"], key="add_audio_file")
                                if up:
                                    import os, uuid
                                    os.makedirs("audios", exist_ok=True)
                                    fn = f"audios/{uuid.uuid4()}.mp3"
                                    with open(fn, "wb") as f:
                                        f.write(up.getvalue())
                                    final_url = fn

                                    try:
                                        from mutagen.mp3 import MP3
                                        import io
                                        audio = MP3(io.BytesIO(up.getvalue()))
                                        auto_dur = int(audio.info.length)
                                        st.success(f"✅ 时长识别：{auto_dur} 秒")
                                    except Exception:
                                        auto_dur = 1
                                        st.warning("⚠️ 无法识别时长，使用默认1秒")

                            all_required_ready = bool(
                                n_title.strip() and artist_name.strip() and album_name.strip() and final_url
                            )
                            if st.button("确认", type="primary", use_container_width=True, disabled=not all_required_ready):
                                if not (n_title.strip() and artist_name.strip() and album_name.strip() and final_url):
                                    st.error("请填写必填项")
                                elif mm.song_exists(n_title.strip(), artist_name.strip(), album_name.strip()):
                                    st.error("歌曲已存在")
                                else:
                                    aid = mm.get_or_create_artist(artist_name.strip())
                                    alid = mm.get_or_create_album(album_name.strip())
                                    sid = mm.add_song(
                                        n_title.strip(), aid, alid,
                                        auto_dur if auto_dur else 1,
                                        final_url,
                                        genre.strip() or None,
                                    )
                                    if sid:
                                        st.success("添加成功！")
                                        st.session_state.reset_add_song_form = True
                                        st.rerun()

                    # ==================== 修改歌曲信息 ====================
                    with st.expander("✏️ 修改歌曲信息"):
                        kw = st.text_input("输入歌曲名称搜索")
                        sid = None
                        if kw:
                            res = mm.search_songs(kw)
                            if res:
                                opt = {f"{r[1]} - {r[2]}": r[0] for r in res}
                                sel = st.selectbox("选择歌曲", opt.keys())
                                sid = opt[sel]

                        if sid:
                            d = mm.get_song_detail(sid)
                            st.caption(f"当前：{d[1]} / {d[4]} / {d[6]}秒 / 曲风：{d[8] if d[8] else '未知'}")
                            c1,c2 = st.columns(2)
                            nt = c1.text_input("新标题")
                            na = c1.text_input("新歌手")
                            nal = c2.text_input("新专辑")
                            nd = c2.number_input("新时长(秒)", min_value=0)
                            nu = st.text_input("新音频地址")
                            ng = st.text_input("新曲风")

                            if st.button("保存修改"):
                                naid = mm.get_or_create_artist(na) if na else None
                                nalid = mm.get_or_create_album(nal) if nal else None
                                ok = mm.update_song(sid, nt or None, naid, nalid, nd if nd>0 else None, nu or None, ng or None)
                                if ok:
                                    st.success("修改成功")
                                    st.rerun()

                    # ==================== 删除歌曲 ====================
                    with st.expander("🗑️ 删除歌曲"):
                        delete_kw = st.text_input(
                            "输入关键词搜索要删除的歌曲（歌名/歌手/专辑）",
                            key="delete_song_kw",
                        ).strip()
                        delete_song_id = None
                        if delete_kw:
                            delete_results = mm.search_songs(delete_kw)
                            if delete_results:
                                delete_options = {
                                    f"ID {r[0]} | {r[1]} - {r[2]} | 专辑：{r[3] if r[3] else '未知'}": r[0]
                                    for r in delete_results
                                }
                                selected_delete = st.selectbox(
                                    "选择要删除的歌曲",
                                    list(delete_options.keys()),
                                    key="delete_song_select",
                                )
                                delete_song_id = delete_options[selected_delete]
                            else:
                                st.warning("没有找到匹配歌曲")

                        if delete_song_id and st.button("🔥 删除选中歌曲", key="btn_delete_selected_song"):
                            if mm.delete_song(delete_song_id):
                                st.success("删除成功")
                                st.rerun()
                            else:
                                st.error("删除失败，请检查该歌曲是否存在")
        if current_role == 'sys_admin':
            # ----------------- Tab 6: 账号安全 -----------------
            with tab_sys:
                st.header("🛡️ 系统安全及角色权限分发")
                if auth.current_user['role'] != 'sys_admin':
                    st.error("⛔ 权限拦截：您目前的身份是普通用户或曲库网管，无权染指系统底层权限！")
                else:
                    st.warning("超级管理员确认访问。您可以通过此控制台查看并管理系统用户。")

                    st.subheader("➕ 新增系统用户")
                    ac1, ac2, ac3 = st.columns([2, 2, 1])
                    new_admin_username = ac1.text_input("用户名", key="admin_create_username")
                    new_admin_password = ac2.text_input("初始密码", type="password", key="admin_create_password")
                    new_admin_role = ac3.selectbox("角色", ["listener", "music_admin", "sys_admin"], key="admin_create_role")
                    if st.button("创建用户", key="btn_admin_create_user", type="primary"):
                        ok, msg = mm.admin_create_user(new_admin_username.strip(), new_admin_password, new_admin_role)
                        if ok:
                            st.success(msg)
                            st.rerun()
                        else:
                            st.error(msg)

                    st.divider()
                    st.subheader("👥 用户列表与权限管理")
                    if st.session_state.pop("clear_admin_user_keyword", False):
                        st.session_state.admin_user_keyword = ""
                    fc1, fc2, fc3 = st.columns([2, 1, 1])
                    user_keyword = fc1.text_input("按用户名搜索", key="admin_user_keyword")
                    role_filter = fc2.selectbox("按角色筛选", ["全部", "listener", "music_admin", "sys_admin"], key="admin_role_filter")
                    with fc3:
                        st.write("")
                        if st.button("显示全部用户", key="btn_show_all_users", use_container_width=True):
                            st.session_state.admin_show_all_users = True
                            st.session_state.clear_admin_user_keyword = True
                            st.rerun()

                    should_show_user_results = True
                    if user_keyword.strip():
                        st.session_state.admin_show_all_users = False
                        users = mm.get_all_users(user_keyword.strip(), role_filter)
                    elif st.session_state.get("admin_show_all_users", False):
                        users = mm.get_all_users("", role_filter)
                    else:
                        users = []
                        should_show_user_results = False
                        st.info("请输入用户名关键词搜索，或点击“显示全部用户”。")

                    if users:
                        st.caption(f"共找到 {len(users)} 个用户")
                        for uid, uname, urole, ubio, uavatar, ucreated in users:
                            with st.expander(f"ID {uid} | {uname} | {urole} | {ucreated.strftime('%Y-%m-%d %H:%M')}"):
                                st.write(f"**简介:** {ubio if ubio else '暂无'}")
                                mc1, mc2 = st.columns([1, 1])
                                selected_role = mc1.selectbox(
                                    "角色",
                                    ["listener", "music_admin", "sys_admin"],
                                    index=["listener", "music_admin", "sys_admin"].index(urole),
                                    key=f"user_role_{uid}",
                                )
                                if mc1.button("更新角色", key=f"btn_role_{uid}"):
                                    ok, msg = mm.admin_update_user_role(uid, selected_role)
                                    if ok:
                                        st.success(msg)
                                        st.rerun()
                                    else:
                                        st.error(msg)

                                if mc2.button("删除用户", key=f"btn_delete_user_{uid}"):
                                    ok, msg = mm.admin_delete_user(uid)
                                    if ok:
                                        st.success(msg)
                                        st.rerun()
                                    else:
                                        st.error(msg)

                                rp1, rp2 = st.columns([2, 1])
                                reset_password = rp1.text_input("重置密码", type="password", key=f"reset_pwd_{uid}")
                                if rp2.button("确认重置", key=f"btn_reset_pwd_{uid}"):
                                    ok, msg = mm.admin_reset_user_password(uid, reset_password)
                                    if ok:
                                        st.success(msg)
                                    else:
                                        st.error(msg)
                    elif should_show_user_results:
                        st.info("没有找到匹配的用户。")

                    st.divider()
                    st.subheader("🧹 管理记录")
                    recent_contents = mm.admin_get_recent_content(limit=50)
                    if recent_contents:
                        for content_type, content_id, author, subject, content, created_at in recent_contents:
                            with st.expander(f"{content_type} #{content_id} | {author} | {created_at.strftime('%Y-%m-%d %H:%M')}"):
                                st.write(f"**关联对象:** {subject}")
                                st.write(content)
                                if st.button("删除该内容", key=f"mod_del_{content_type}_{content_id}"):
                                    ok, msg = mm.admin_delete_content(content_type, content_id)
                                    if ok:
                                        st.success(msg)
                                        st.rerun()
                                    else:
                                        st.error(msg)
                    else:
                        st.info("暂无帖子或评论内容。")
