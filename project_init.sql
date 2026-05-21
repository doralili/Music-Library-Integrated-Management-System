-- ======================================================
-- 音乐图书馆综合管理系统 完整初始化 SQL
-- 功能：创建所有表 + 支持自动时长、搜索、曲风、歌单、播放
-- 执行后，项目可直接运行
-- ======================================================

-- ================== 1. 歌曲表（核心） ==================
CREATE TABLE IF NOT EXISTS "Songs" (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255) NOT NULL,
    album VARCHAR(255),
    duration_seconds INTEGER,   -- 自动识别时长使用
    genre VARCHAR(100),         -- 曲风字段（搜索功能）
    audio_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================== 2. 歌单表 ==================
CREATE TABLE IF NOT EXISTS "Playlists" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================== 3. 歌单-歌曲关联表 ==================
CREATE TABLE IF NOT EXISTS "Playlist_Songs" (
    playlist_id INTEGER REFERENCES "Playlists"(id) ON DELETE CASCADE,
    song_id INTEGER REFERENCES "Songs"(id) ON DELETE CASCADE,
    PRIMARY KEY (playlist_id, song_id)
);

-- ================== 4. 初始化完成 ==================
INSERT INTO "Songs" (title, artist, album, duration_seconds, genre, audio_url)
VALUES ('示例歌曲', '示例歌手', '示例专辑', 180, '流行', '');