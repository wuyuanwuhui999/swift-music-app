# AGENTS.md · music iOS 客户端（AI 接手必读）

> 这份文档是写给 **AI 编程助手**（以及新加入的人）看的项目速览：
> 5 分钟看懂「这是什么、怎么跑、代码怎么组织、接口有什么坑、改代码要守什么规矩」。
> 更细的逐页实现说明见 `README.md`，开发规范见 `提示词.md`。

---

## 1. 这是什么

`music` 是一个 **SwiftUI 原生 iOS 音乐 App**，产品形态与后端接口完全对齐两个既有前端项目：

| 参考项目 | 位置 | 作用 |
|---------|------|------|
| uniapp（uni-app + Vue3 + TS） | `https://gitee.com/wuyuanwuhui99/uniapp-vite-vue3-ts-music-app-ui`（作者本地另有一份在 `~/Documents/code/uniapp/`） | **视觉与交互的最终标准** |
| flutter | `flutter-music-app-ui`（作者本地在 `~/Documents/code/flutter/`） | 页面结构对照，**部分实现有 bug，以 uniapp 为准** |

也就是说：**功能、页面、样式都以 uniapp 项目为准**，这个 iOS 工程是 1:1 的原生复刻，
前端资源（图标、默认封面）也是从 uniapp 的 `static/` 目录拷贝到 `Assets.xcassets` 的。

后端是独立的 FastAPI 多服务网关：`http://127.0.0.1:4000`（作者本地在
`~/Documents/code/python/fast-api-app-service`），接口文档见其 `docs/api/` 下的
`music.md`、`social.md`、`circle.md`、`user.md`、`chat.md`、`gateway.md`。

> 拿不到参考项目也不影响开发：本文档第 6、7、8 节已经把这套接口的用法和坑写全了。

---

## 2. 技术栈与硬约束

- **纯 SwiftUI**，MVVM 轻量化（无 ViewModel 层，状态用房 `@State` + 单例 `ObservableObject`）
- **零第三方依赖**（无 SPM / CocoaPods），网络用 `URLSession`，播放用 `AVPlayer`
- Xcode 工程：`music.xcodeproj`，scheme `music`，Bundle ID `wuwenqiang.music`
- Deployment Target：**iOS 26.2**（用到了 `onScrollGeometryChange`、`.task(id:)` 等较新 API）
- **没有 test target，也没有 lint 配置** —— 不要声称「测试通过」，验证方式见第 10 节

---

## 3. 5 分钟跑起来

```bash
cd ~/Documents/code/swiftUI/swift-music-app/music

# 1) 先确认后端在跑
curl -s http://127.0.0.1:4000/service/music/getMusicCategory | head -c 100

# 2) 构建（模拟器，免签名）
xcodebuild -project music.xcodeproj -scheme music -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO

# 3) 安装并启动（APP 路径按本机 DerivedData 动态取，不要硬编码）
APP="$(xcodebuild -project music.xcodeproj -scheme music -sdk iphonesimulator \
  -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR/ {print $2}')/music.app"
xcrun simctl install booted "$APP"
xcrun simctl launch booted wuwenqiang.music

# 4) 截图（验证 UI 用）
xcrun simctl io booted screenshot /tmp/shot.png
```

- 登录：`/service/user/login` 的 `password` 字段要传**明文密码的 MD5（32 位小写）**，客户端不要传明文。
  测试账号请自行在本地后端注册，**任何账号、密码、token 都不要提交进仓库**（本仓库历史里也没有）。
- 后端地址、WebSocket 地址都在 `music/Config/Constants.swift` 顶部：
  `baseURL` / `webSocketURL`，换环境只改这两行。

---

## 4. 目录结构

```
music/
├── music.xcodeproj
├── music/
│   ├── App/MusicApp.swift              # 入口，根视图 WelcomePage（校验 token 后进 MusicIndexPage）
│   ├── Config/Constants.swift          # 后端地址、缓存 key、分页常量、MusicConfig/ChatConfig/CircleConfig、API 路径表
│   ├── Api/APIEndpoints.swift          # 接口枚举（path + method 映射），约 200 个接口值
│   ├── Network/
│   │   ├── HTTPClient.swift            # 网络单例，按模块分 extension：用户/音乐/社交/我的/搜索/评论/收藏
│   │   └── WebSocketManager.swift      # AI 对话 WebSocket（流式接收）
│   ├── Models/                         # 数据模型 + 全局状态
│   │   ├── AppState.swift              # 登录态、userData、currentPrompt（@Published 单例）
│   │   ├── PlayerState.swift           # 播放门面：当前歌曲 / 播放列表 / 循环模式 / 进度 / classifyName
│   │   ├── Music / MusicCategory / MusicAuthor / MusicAuthorCategory
│   │   ├── MusicCircle / FavoriteDirectory
│   │   ├── BaseResponse.swift          # 统一响应 { data, status, msg, total, token }
│   │   └── DecodingHelpers.swift       # Int/String/Double 宽容解码（后端字段类型不稳定）
│   ├── Utils/
│   │   ├── AudioPlayerManager.swift    # AVPlayer 薄封装（load/play/pause/seek/结束回调 + AVAudioSession）
│   │   ├── LyricParser.swift           # LRC 解析 + 当前行计算
│   │   ├── MusicUtils.swift            # 封面 URL 拼接（完整 URL / 相对路径 / {size} 占位 / http→https）
│   │   ├── DateUtils.swift             # 相对时间（刚刚 / N分前 / 日期）
│   │   ├── TokenManager.swift          # Keychain/UserDefaults 存 token
│   │   └── Validators.swift            # 表单校验
│   ├── Theme/
│   │   ├── Colors.swift                # 所有颜色（主题橙 primaryColor、灰、白、页面底色…）
│   │   └── Dimens.swift                # 所有尺寸（字号、间距、圆角、图标、按钮高度…）
│   └── UI/
│       ├── Pages/                      # 27 个页面（见第 6 节页面地图）
│       └── Components/                 # 28 个可复用组件
└── README.md / 提示词.md / *.png        # 文档与截图
```

---

## 5. 分层与三条铁律

```
Pages ──► Components（纯展示 + 回调）
  │
  ├──► PlayerState.shared   ← 播放相关的一切（当前歌曲、列表、进度、循环模式）
  ├──► AppState.shared      ← 登录用户信息
  └──► HTTPClient.shared    ← 所有网络请求（extension 按模块分组）
            └──► APIEndpoints / Constants.API  ← 路径与方法
```

**铁律 1：播放状态只有一个源。** 任何页面要播放，都走 `PlayerState.shared`，
不要自己 new `AVPlayer`。`AudioPlayerManager` 只被 `PlayerState` 持有。

```swift
playerState.setMusic(music, autoPlay: true)   // 切歌
playerState.setMusicList(list)                // 换播放列表
playerState.setClassifyName("推荐歌曲")        // 播放列表名（决定「当前列表是否属于本模块」）
```

页面里「点一首歌」的标准写法（各列表页已经完全一致，新页面照抄）：

```swift
if playerState.currentMusic?.id != music.id {
    playerState.setMusic(music, autoPlay: true)
} else if !playerState.isPlaying {
    playerState.play()
}
// 当前播放列表不属于本页模块时，先拉整表（500 条）当播放列表
if playerState.classifyName != classifyName {
    HTTPClient.shared.xxx(pageSize: Constants.MusicConfig.maxPlaylistCount) { ... }
}
showPlayerPage = true
```

**铁律 2：尺寸和颜色不许硬编码。** 字号/间距/圆角一律 `Dimens.xxx`，颜色一律 `Colors.xxx`，
接口路径一律 `Constants.API.xxx` + `APIEndpoints` 枚举。

**铁律 3：二级页面路由要带关联值。** 需要携带数据的页面（歌手、收藏夹、分类等）用
`case authorList(MusicAuthor)` 这种形式，**不要**「先设一个 `@State` 再设 route」——
`fullScreenCover(item:)` 的内容闭包会读到旧值（这是本项目踩过的坑，务必遵守）。

---

## 6. 页面地图（入口 → 页面 → 关键接口）

### 主框架

| 页面 | 文件 | 入口 / 说明 |
|------|------|------------|
| 欢迎/登录/注册/找回 | `WelcomePage` `LoginPage` `RegisterPage` `ForgetPasswordPage` `ResetPasswordPage` | 复用 chat 项目的用户模块 |
| 四 Tab 容器 | `MusicIndexPage` | 自定义 TabBar + 中央迷你播放器；Tab 懒加载、状态保留 |
| 首页 | `MusicHomePage` | 搜索栏（含 AI 图标）、四个分类入口（歌手 / 分类歌曲 / 经典老歌 可点）、榜单模块流（首屏 3 个，滚动加载到 33 个）、推荐歌手 |
| 推荐 | `MusicRecommentPage` | 带名次（前三名奖牌）的歌曲列表；`categoryId` 固定为 1（有数据但不在首页分类列表里） |
| 音乐圈 | `MusicCirclePage` | 动态流 + 点赞 + 评论/二级回复 + 发布按钮 |
| 我的 | `MusicUserPage` | 用户卡 + 收藏夹 + 我喜欢 + 关注歌手 + 播放记录（可折叠、下拉刷新） |

### 播放

| 页面 | 文件 | 入口 / 说明 |
|------|------|------------|
| 播放页 | `MusicPlayerPage` | 迷你播放器点开；模糊封面 + 旋转唱片 + 同步歌词 + 进度 + 控制栏 |
| 歌词全屏 | `MusicLyricPage` | 播放页点歌词区域 |
| 评论弹窗 | `Components/CommentDialogView` | 播放页「评论」按钮（sheet） |
| 收藏夹弹窗 | `Components/FavoriteDirectoryDialogView` | 播放页「收藏夹」按钮（sheet） |
| 分享到音乐圈 | `MusicSharePage` | 播放页「分享」按钮 |

### 二级页面

| 页面 | 文件 | 入口 |
|------|------|------|
| 搜索 | `MusicSearchPage` | 首页搜索栏 |
| 歌曲分类 | `MusicCategoryPage` | 首页「分类歌曲」入口 |
| 筛选/榜单歌曲列表 | `MusicClassifyListPage` | 首页模块标题栏「更多」 |
| 歌手分类 | `MusicAuthorCategoryPage` | 首页「歌手」入口、「推荐歌手 > 更多」 |
| 歌手歌曲列表 | `MusicAuthorListPage` | 推荐歌手卡片、歌手分类列表、我关注的歌手 |
| 选歌页 | `MusicCirCleCheckPage` | 发布动态页「选择歌曲」 |
| 我喜欢的歌曲 | `MusicFavoriteListPage` | 我的页「更多」 |
| 播放记录 | `RecordMusicPage` | 我的页「更多」 |
| 我关注的歌手 | `FavoriteAuthorListPage` | 我的页「更多」 |
| 收藏夹详情 | `FavoriteMusicPage` | 我的页收藏夹行 |
| 个人信息 | `EditUserInfoPage` | 我的页用户卡编辑按钮、首页搜索栏头像 |
| 修改密码 | `UpdatePasswordPage` | 个人信息页 |
| AI 助手 | `ChatPage` | 首页搜索栏 AI 图标（WebSocket 流式） |

### 关键可复用组件

| 组件 | 用在哪 |
|------|--------|
| `MusicNavBar` | 所有二级页顶部（返回 + 居中标题） |
| `MusicSongRow` / `MusicSongListCard` | 歌曲行 / 白底卡片列表（分类、歌手、搜索、喜欢、收藏夹 5 处共用） |
| `MusicRankRow` | 带名次歌曲行（推荐页） |
| `MusicAuthorRow` | 歌手行（歌手分类、我关注的歌手） |
| `MusicUserListRow` | 我的页通用行（封面 + 标题 + 副标题 + 播放/删除/菜单） |
| `MusicCoverView` / `MusicAuthorAvatarView` | 圆形封面 / 歌手头像（无图用首字兜底） |
| `MusicModuleHeader` / `MusicSectionHeader` | 可折叠标题栏 |
| `MusicPlayerDisc` / `LyricScrollView` / `BlurredCoverBackground` | 播放页与歌词页（旋转唱片 / 可调字号的同步歌词 / 模糊封面背景） |
| `MusicCircleCard` / `CircleCommentRow` | 音乐圈动态卡 / 评论行（递归回复） |
| `FlowLayout` | 自动换行流布局（搜索历史标签） |

> 目前无引用的历史遗留：`PlaceholderPage`、`PlaceholderDetailPage`、`AIAvatar`、`ChatMessage`、
> 以及 chat 项目带过来的 `UserInfoPage`（部分仍被登录/用户链路引用）——新代码不要再依赖占位页。

---

## 7. 怎么加一个新接口（固定 3 步 + 1 步）

1. `Config/Constants.swift` 的 `Constants.API` 里加路径（路径参数用 `{musicId}` 占位）
2. `Api/APIEndpoints.swift` 加 `case`，并补三处映射：`path`（替换占位符）、`method`（GET 列表 / POST 列表）
3. `Network/HTTPClient.swift` 加对应 extension 方法（统一返回 `Result<T, NetworkError>`，
   成功判 `response.isSuccess`，否则 `.custom(message: response.msg ?? "默认文案")`）
4. 需要分页的接口返回 `(列表, 总数)` 二元组（如 `getMusicLike`、`getMusicListByCategoryId`）

---

## 8. 后端已知坑（改代码前必看）

| # | 现象 | 处理方式 |
|---|------|---------|
| 1 | `POST /service/music/insertMusicFavorite/{musicId}` 的 body 是**纯 int 数组** `[21]`（收藏夹 id 列表，`[]` = 取消收藏）；传 `[{"favoriteId":21}]` 会 422 | 客户端已按文档修正；语义是「先清空该歌所有收藏，再按传入重建」，所以「只从某个收藏夹移出」要先取其余收藏夹再提交剩余 id |
| 2 | `POST /service/social/insertComment` 返回 FAIL「发表评论失败」，但评论**实际已入库**，且 `data` 恒为 null | 音乐圈与播放页评论都采用**乐观更新**：业务报错也本地插入，只有网络错误才回滚提示 |
| 3 | `POST /service/social/saveLike` 返回 FAIL「LikeSchema is not defined」，点赞记录实际已写库 | 同上，乐观更新 |
| 4 | `DELETE /service/social/deleteComment/{id}` 返回「评论不存在」 | 暂不支持删除评论 |
| 5 | `POST /service/circle/insertCircle` 不写 `create_time`，而动态列表按 `create_time` 倒序 → 新动态排最后 | 发布成功后本地构造一条动态，通过 `.musicCircleDidUpdate` 通知让列表**置顶插入**（不动服务端排序） |
| 6 | `GET /service/music/getFavoriteDirectory` 的 `musicId` 必填（不传 422）；返回的 `checked` 表示该歌是否在此收藏夹 | 我的页按「当前播放歌曲 → 第一首喜欢的歌曲」取值 |
| 7 | `GET /service/music/getFavoriteAuthor` **不返回** `isLike` / `total` | 「我关注的歌手」列表强制已关注图标、不显示「N首」 |
| 8 | 播放记录没有删除接口 | 我的页删除只做本地移除并提示 |
| 9 | AI 聊天：`type=online` 的模型后端返回「不支持的模型类型 online」 | 模型列表把 `type != "online"`（ollama）排前面，online 兜底 |
| 10 | 字段类型不稳定：`total` 可能是字符串、`authorId` 可能是字符串 | 所有模型走 `DecodingHelpers` 宽容解码 |
| 11 | 封面地址有三种形态：完整 URL、相对路径、带 `{size}` 的 CDN 地址 | 一律走 `MusicUtils.coverURL()`；外链 `http` 自动升 `https`，本地 `127.0.0.1` 保持不变（ATS） |

---

## 9. 代码风格

- 注释、文档、提交信息全部用**中文**；每个文件顶部有 `///` 说明「入口 / 对齐哪个参考页面 / 用到的接口」
- 页面结构顺序固定：`body` → `// MARK: - 子视图` → `// MARK: - 计算属性` → `// MARK: - 数据` → `// MARK: - 交互`
- 网络回调统一 `DispatchQueue.main.async` 回到主线程再改 `@State`
- 分页统一：`pageNum/total/isLoading + fetch(page:replace:) + onScrollGeometryChange 距底 200pt 加载 + footer「正在加载更多... / 已经到底了」`
- 下拉刷新统一 `.refreshable { await reload() }`，`reload` 用 `withCheckedContinuation` 包回调式请求
- 防重复点击：`isLikeLoading` / `isSubmitting` 之类的布尔量守卫

---

## 10. 怎么验证（没有测试套件，靠这三样）

1. **构建**：`xcodebuild ... build CODE_SIGNING_ALLOWED=NO`，必须 `BUILD SUCCEEDED` 且 0 error
2. **真机模拟验证**：`simctl install/launch` → `simctl io booted screenshot` → 看图确认数据与样式
   - 交互类验证常用「临时探针」：在页面里加 `.task { sleep; 触发动作 }` 并在改动处标 `// TEMP-VERIFY`，
     截图确认后**必须删除**探针并重新 `grep TEMP-VERIFY` 确认无残留
3. **接口先用 curl 打通**：改动涉及新接口时，先用 `curl` 验证返回结构，再写 Swift 代码

> 不要在总结里写「测试全部通过」——本项目没有测试；只能写「构建通过 + 截图验证 + ad-hoc 脚本检查」。

---

## 11. Git 与推送

- 两个远端：**Gitee 优先**（`gitee` remote，`wuyuanwuhui99`），然后 GitHub（`github` remote，`wuyuanwuhui999`）
- GitHub 走海外网络偶尔 `443` 超时：**不要反复重试**，记录「待补推」，下次一起推
- 每完成一个页面/功能就提交一次，提交信息写清「做了什么 + 关键实现点 + 修了什么接口坑」
- 仓库里有 `gitee-push.sh` / `github-push.sh` 两个脚本

---

## 12. 已知未做 / 可扩展

- **后台播放 / 锁屏控制**：需要 `UIBackgroundModes=audio` + `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter`（当前只在 App 内播放）
- 搜索历史只支持清空全部，没有单条删除
- AI 助手没有会话历史（每次进页面是新会话），没有文档上传/知识库
- 播放记录无删除、评论无删除（后端缺接口）
- 收藏夹重命名 / 排序、歌曲菜单（更多）目前是空实现

---

## 13. 速查

| 我要… | 去哪 |
|-------|------|
| 改后端地址 | `Config/Constants.swift` 的 `baseURL` / `webSocketURL` |
| 加接口 | `Constants.API` → `APIEndpoints`（path/method） → `HTTPClient` |
| 改主题色 / 字号 | `Theme/Colors.swift` / `Theme/Dimens.swift` |
| 改播放逻辑 | `Models/PlayerState.swift`（引擎在 `Utils/AudioPlayerManager.swift`） |
| 看某个页面怎么写的 | `README.md` 的「各页面实现要点」 |
| 看开发规范与页面清单 | `提示词.md` |
| 对照原版 UI | uniapp 项目同名页面 / `static/` 图标 |
