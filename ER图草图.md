# 音乐库系统 ER 图草图

这份草图按课件 [2-conceptual data model.pptx](</C:/Users/27726/Documents/lxt/Learning/Sophomore/Second term/数据库系统/数据库系统/2-conceptual data model.pptx>) 中的 E-R 标准整理：

- 实体类型用矩形
- 联系类型用菱形
- 属性用椭圆样式
- 标识符属性加下划线
- 联系旁标注 `1`、`N`、`M`
- 尽量用“概念实体/联系”表达，而不是直接把中间表照搬成实体

## 推荐交付版

优先使用最终成图文件 [ER图_3x4.svg](</C:/Users/27726/Documents/lxt/Learning/Sophomore/Second term/数据库系统/数据库系统/poj1/ER图_3x4.svg>)。这是一张手工排版的 `3:4` 竖版图，连线比 Mermaid 自动布局更规整，交叉更少。

```mermaid
flowchart LR
    %% ========= Entities =========
    U[用户]
    AR[歌手]
    AL[专辑]
    S[歌曲]
    PL[歌单]
    C[歌曲评论]
    P[帖子]
    PC[帖子评论]

    %% ========= Entity Attributes =========
    U_ID([<u>用户编号</u>])
    U_NAME([用户名])
    U_ROLE([角色])

    AR_ID([<u>歌手编号</u>])
    AR_NAME([歌手名])

    AL_ID([<u>专辑编号</u>])
    AL_TITLE([专辑名])
    AL_YEAR([发行年份])

    S_ID([<u>歌曲编号</u>])
    S_TITLE([歌曲名])
    S_DUR([时长])
    S_CC([评论数/可导出])

    PL_ID([<u>歌单编号</u>])
    PL_NAME([歌单名])
    PL_TIME([创建时间])

    C_ID([<u>评论编号</u>])
    C_TEXT([评论内容])
    C_TIME([评论时间])

    P_ID([<u>帖子编号</u>])
    P_TITLE([标题])
    P_TEXT([正文])
    P_TIME([发帖时间])

    PC_ID([<u>帖子评论编号</u>])
    PC_TEXT([评论内容])
    PC_TIME([评论时间])

    %% ========= Relationships =========
    R1{创作}
    R2{收录}
    R3{发布}
    R4{包含}
    R5{发表}
    R6{针对}
    R7{发帖}
    R8{推荐}
    R9{评论}
    R10{属于}

    %% ========= Relationship Attribute =========
    R4_TIME([加入时间])

    %% ========= Entity-Attribute Links =========
    U --- U_ID
    U --- U_NAME
    U --- U_ROLE

    AR --- AR_ID
    AR --- AR_NAME

    AL --- AL_ID
    AL --- AL_TITLE
    AL --- AL_YEAR

    S --- S_ID
    S --- S_TITLE
    S --- S_DUR
    S --- S_CC

    PL --- PL_ID
    PL --- PL_NAME
    PL --- PL_TIME

    C --- C_ID
    C --- C_TEXT
    C --- C_TIME

    P --- P_ID
    P --- P_TITLE
    P --- P_TEXT
    P --- P_TIME

    PC --- PC_ID
    PC --- PC_TEXT
    PC --- PC_TIME

    %% ========= Entity-Relationship Links with Cardinality =========
    AR -- "1" --- R1
    R1 -- "N" --- AL

    AR -- "1" --- R10
    R10 -- "N" --- S

    AL -- "1" --- R2
    R2 -- "N" --- S

    U -- "1" --- R3
    R3 -- "N" --- PL

    PL -- "M" --- R4
    R4 -- "N" --- S
    R4 --- R4_TIME

    U -- "1" --- R5
    R5 -- "N" --- C

    S -- "1" --- R6
    R6 -- "N" --- C

    U -- "1" --- R7
    R7 -- "N" --- P

    P -- "N" --- R8
    R8 -- "1" --- S

    U -- "1" --- R9
    R9 -- "N" --- PC

    P -- "1" --- R6P
    R6P{针对}
    R6P -- "N" --- PC

    %% ========= Styles =========
    classDef entity fill:#ffffff,stroke:#222,stroke-width:1.6,color:#111;
    classDef relation fill:#fff4d6,stroke:#8a6a00,stroke-width:1.6,color:#111;
    classDef attr fill:#eef6ff,stroke:#4d78a8,stroke-width:1.2,color:#111;

    class U,AR,AL,S,PL,C,P,PC entity;
    class R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R6P relation;
    class U_ID,U_NAME,U_ROLE,AR_ID,AR_NAME,AL_ID,AL_TITLE,AL_YEAR,S_ID,S_TITLE,S_DUR,S_CC,PL_ID,PL_NAME,PL_TIME,C_ID,C_TEXT,C_TIME,P_ID,P_TITLE,P_TEXT,P_TIME,PC_ID,PC_TEXT,PC_TIME,R4_TIME attr;
```

## 这张图和数据库表的对应关系

- `用户` 对应 `Users`
- `歌手` 对应 `Artists`
- `专辑` 对应 `Albums`
- `歌曲` 对应 `Songs`
- `歌单` 对应 `Playlists`
- `歌曲评论` 对应 `Comments`
- `帖子` 对应 `Posts`
- `帖子评论` 对应 `Post_Comments`
- `包含` 是 `Playlists` 与 `Songs` 的多对多联系，对应中间表 `Playlist_Songs`

## 为什么这样画更符合课件标准

- 课件要求 E-R 图优先表达“实体-联系-属性”，所以我把 `Playlist_Songs` 还原成了 `歌单` 与 `歌曲` 之间的 `包含` 联系，并把 `added_at` 画成联系属性 `加入时间`。
- `Songs.comment_count` 在数据库里由触发器维护，更适合作为“可导出属性”理解，所以保留为 `评论数/可导出`，如果老师更强调纯概念模型，也可以直接删掉它。
- `Posts.recommended_song_id` 被画成 `帖子` 与 `歌曲` 之间的 `推荐` 联系，而不是直接写外键字段，这样更符合概念数据模型的表达习惯。
- 为了保持整张图清晰简洁，我只保留了主标识符和核心业务属性，没有把密码哈希、头像地址、音频地址这类实现层字段全部铺开。

## 如果你要交作业，建议

- 优先使用上面这版，不要直接提交“关系表结构图”。
- 如果老师要求更严格的 Chen 风格，可以把 `评论数/可导出` 删除，让图更纯粹。
- 如果老师要求标出可选参与，可以在 `专辑 - 收录 - 歌曲`、`帖子 - 推荐 - 歌曲` 两处额外备注“歌曲可不属于专辑”“帖子可不推荐歌曲”。
