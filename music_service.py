from dataclasses import dataclass


@dataclass
class ServiceResult:
    ok: bool
    message: str
    value: object = None
    detail: str = ""


class MusicLibraryService:
    def __init__(self, manager):
        self.manager = manager

    def add_song(self, title, artist, album, duration, audio_url, genre=None):
        title = (title or "").strip()
        artist = (artist or "").strip()
        album = (album or "").strip()
        audio_url = (audio_url or "").strip()
        genre = (genre or "").strip() or None
        duration = int(duration or 1)

        missing = [
            label for label, value in (
                ("歌曲名称", title),
                ("歌手名称", artist),
                ("专辑名称", album),
                ("音频地址", audio_url),
            )
            if not value
        ]
        if missing:
            return ServiceResult(False, "请补全：" + "、".join(missing))
        if duration <= 0:
            return ServiceResult(False, "歌曲时长必须大于 0 秒")
        if self.manager.song_exists(title, artist, album):
            return ServiceResult(False, "歌曲已存在，不能重复添加")

        song_id = self.manager.add_song_with_metadata(title, artist, album, duration, audio_url, genre)
        if song_id:
            return ServiceResult(True, f"添加成功，歌曲 ID：{song_id}", song_id)
        return ServiceResult(
            False,
            "添加失败",
            detail=getattr(self.manager, "last_error", "") or "数据库未返回具体错误，请查看日志。",
        )

    def update_song(self, song_id, title, artist, album, duration, audio_url, genre):
        title = (title or "").strip()
        artist = (artist or "").strip()
        album = (album or "").strip()
        audio_url = (audio_url or "").strip()
        genre = (genre or "").strip()
        duration = int(duration or 1)

        if not title or not artist or not album:
            return ServiceResult(False, "标题、歌手、专辑不能为空")
        if duration <= 0:
            return ServiceResult(False, "歌曲时长必须大于 0 秒")

        artist_id = self.manager.get_or_create_artist(artist)
        if not artist_id:
            return ServiceResult(False, "保存失败：歌手信息无法写入", detail=getattr(self.manager, "last_error", ""))
        album_id = self.manager.get_or_create_album(album, artist_id)
        if not album_id:
            return ServiceResult(False, "保存失败：专辑信息无法写入", detail=getattr(self.manager, "last_error", ""))

        ok = self.manager.update_song(
            song_id,
            title,
            artist_id,
            album_id,
            duration,
            audio_url or None,
            genre or None,
        )
        if ok:
            return ServiceResult(True, "修改成功")
        return ServiceResult(
            False,
            "修改失败",
            detail=getattr(self.manager, "last_error", "") or "数据库未返回具体错误，请查看日志。",
        )
