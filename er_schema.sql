-- ER diagram schema for the openGauss-based music library management system.
-- This file is intended for ERD tools such as DBeaver, DataGrip, dbdiagram-compatible
-- SQL importers, or other database modeling tools that can reverse-engineer DDL.

CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    bio TEXT,
    avatar_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_role_check
        CHECK (role IN ('sys_admin', 'music_admin', 'listener'))
);

CREATE TABLE Artists (
    artist_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE Albums (
    album_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    artist_id INT,
    release_year INT,
    cover_url VARCHAR(500),
    CONSTRAINT albums_artist_fk
        FOREIGN KEY (artist_id)
        REFERENCES Artists(artist_id)
        ON DELETE CASCADE,
    CONSTRAINT albums_title_artist_unique
        UNIQUE (title, artist_id)
);

CREATE TABLE Songs (
    song_id SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    artist_id INT,
    album_id INT,
    duration_seconds INT,
    audio_url VARCHAR(500),
    genre VARCHAR(100),
    comment_count INT DEFAULT 0,
    CONSTRAINT songs_artist_fk
        FOREIGN KEY (artist_id)
        REFERENCES Artists(artist_id)
        ON DELETE CASCADE,
    CONSTRAINT songs_album_fk
        FOREIGN KEY (album_id)
        REFERENCES Albums(album_id)
        ON DELETE SET NULL,
    CONSTRAINT songs_duration_check
        CHECK (duration_seconds > 0),
    CONSTRAINT songs_title_artist_album_unique
        UNIQUE (title, artist_id, album_id)
);

CREATE TABLE Playlists (
    playlist_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    creator_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT playlists_creator_fk
        FOREIGN KEY (creator_id)
        REFERENCES Users(user_id)
        ON DELETE CASCADE
);

CREATE TABLE Playlist_Songs (
    playlist_id INT NOT NULL,
    song_id INT NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (playlist_id, song_id),
    CONSTRAINT playlist_songs_playlist_fk
        FOREIGN KEY (playlist_id)
        REFERENCES Playlists(playlist_id)
        ON DELETE CASCADE,
    CONSTRAINT playlist_songs_song_fk
        FOREIGN KEY (song_id)
        REFERENCES Songs(song_id)
        ON DELETE CASCADE
);

CREATE TABLE Comments (
    comment_id SERIAL PRIMARY KEY,
    song_id INT,
    user_id INT,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT comments_song_fk
        FOREIGN KEY (song_id)
        REFERENCES Songs(song_id)
        ON DELETE CASCADE,
    CONSTRAINT comments_user_fk
        FOREIGN KEY (user_id)
        REFERENCES Users(user_id)
        ON DELETE CASCADE
);

CREATE TABLE Posts (
    post_id SERIAL PRIMARY KEY,
    user_id INT,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    recommended_song_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT posts_user_fk
        FOREIGN KEY (user_id)
        REFERENCES Users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT posts_recommended_song_fk
        FOREIGN KEY (recommended_song_id)
        REFERENCES Songs(song_id)
        ON DELETE SET NULL
);

CREATE TABLE Post_Comments (
    pcomment_id SERIAL PRIMARY KEY,
    post_id INT,
    user_id INT,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT post_comments_post_fk
        FOREIGN KEY (post_id)
        REFERENCES Posts(post_id)
        ON DELETE CASCADE,
    CONSTRAINT post_comments_user_fk
        FOREIGN KEY (user_id)
        REFERENCES Users(user_id)
        ON DELETE CASCADE
);

-- Optional performance indexes. They are not required for ER relationships,
-- but they document the main query paths used by the system.
CREATE INDEX idx_songs_artist_id ON Songs (artist_id);
CREATE INDEX idx_songs_album_id ON Songs (album_id);
CREATE INDEX idx_playlist_songs_song_id ON Playlist_Songs (song_id);
CREATE INDEX idx_comments_song_id ON Comments (song_id);
