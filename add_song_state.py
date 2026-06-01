import streamlit as st


ADD_SONG_FORM_KEYS = (
    "add_song_title", "add_artist_name", "add_album_name",
    "add_song_genre", "add_audio_url", "add_audio_file",
    "add_audio_uploaded_path", "add_audio_duration", "add_audio_upload_key",
    "add_song_draft",
)


def reset_add_song_form_state():
    for key in ADD_SONG_FORM_KEYS:
        st.session_state.pop(key, None)
    st.session_state.add_song_step = 1
    st.session_state.add_song_audio_mode = None


def get_add_song_draft():
    if 'add_song_draft' not in st.session_state:
        st.session_state.add_song_draft = {
            "title": "",
            "artist": "",
            "album": "",
            "genre": "",
            "audio_url": None,
            "duration": None,
        }
    return st.session_state.add_song_draft


def sync_add_song_step_to_draft(step):
    draft = get_add_song_draft()
    if step == 1:
        draft["title"] = st.session_state.get("add_song_title", draft.get("title", ""))
    elif step == 2:
        draft["artist"] = st.session_state.get("add_artist_name", draft.get("artist", ""))
        draft["album"] = st.session_state.get("add_album_name", draft.get("album", ""))
    elif step == 3:
        draft["genre"] = st.session_state.get("add_song_genre", draft.get("genre", ""))
    elif step >= 4:
        if st.session_state.get("add_song_audio_mode") == "url":
            draft["audio_url"] = st.session_state.get("add_audio_url", draft.get("audio_url"))
            draft["duration"] = None
        elif st.session_state.get("add_audio_uploaded_path"):
            draft["audio_url"] = st.session_state.get("add_audio_uploaded_path")
            draft["duration"] = st.session_state.get("add_audio_duration")


def restore_add_song_widget_value(key, value):
    if key not in st.session_state:
        st.session_state[key] = value or ""
