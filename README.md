## 项目概述

本项目是 **music** —— 音乐 App 的 iOS 原生客户端（SwiftUI），与
[uniapp-vite-vue3-ts-music-app-ui](https://gitee.com/wuyuanwuhui99/uniapp-vite-vue3-ts-music-app-ui)（uni-app + Vue3 + TS 版本）
保持**同一套产品形态、同一套后端接口、同一套视觉规范**，目标是使用 SwiftUI 复刻一个与 uniapp 版本一模一样的音乐 App。

后端接口沿用 FastAPI 微服务集群，统一走网关（客户端配置 `http://127.0.0.1:4000`）：

| 模块 | 网关路径前缀 | 说明 |
|------|--------------|------|
| user | `/service/user` | 登录 / 注册 / 改密 / 用户信息（**本项目已接入**） |
| music | `/service/music` | 音乐列表、歌手、专辑、分类、播放地址 |
| social | `/service/social` | 评论、点赞 |
| circle | `/service/circle` | 音乐圈（朋友圈） |
| movie | `/service/movie` | 电影模块 |

## 主要特性

- **原生体验**：SwiftUI + iOS 26 SDK，纯原生渲染，无 Hybrid 层。
- **与 uniapp 版本对齐**：页面结构、交互流程、主题色 / 字号 / 间距完全对齐 uniapp 版本。
- **统一的网络层**：`HTTPClient` 单例统一封装 `request<T>` + 全量业务接口，`BaseResponse<T>` 统一解析。
- **统一的主题常量**：`Theme/Colors.swift` + `Theme/Dimens.swift`，禁止在页面里写魔法值。
- **可直接复用 chat 项目的用户模块**：登录、注册、忘记密码、重置密码、用户信息与
  [swift-chat-app](https://github.com/wuyuanwuhui999/swift-chat-app) 完全一致，接口也一致。

## 技术栈

- **UI**：SwiftUI（`@State` / `@ObservedObject` / `fullScreenCover`）
- **网络**：`URLSession`（`URLSessionConfiguration` + 超时 30s）
- **状态**：`AppState.shared`（ObservableObject 单例）+ `UserDefaults`（token / 缓存）
- **加密**：`CommonCrypto`（MD5，与后端登录密码加密口径一致）
- **最低版本**：iOS 26.2（与 chat 项目保持一致）

## 目录结构

```
swift-music-app/music/                     # Git 仓库根
├── music.xcodeproj                        # Xcode 工程（Xcode 16+ 文件系统同步工程）
├── music/                                 # 源码根
│   ├── App/MusicApp.swift                 # @main，根视图 = WelcomePage
│   ├── Api/APIEndpoints.swift             # APIEndpoint 枚举：path + method
│   ├── Config/Constants.swift             # baseURL / webSocketURL / Constants.API 路径表
│   ├── Models/                            # 数据模型
│   │   ├── AppState.swift                 # 登录态 / 用户信息（全局单例）
│   │   ├── PlayerState.swift              # 播放态：当前歌曲 / 播放列表 / 循环模式 / 模块名
│   │   ├── Music.swift                    # 歌曲模型
│   │   ├── MusicCategory.swift            # 音乐分类（首页模块）
│   │   ├── MusicAuthor.swift              # 歌手模型
│   │   ├── DecodingHelpers.swift          # 宽容解码（Int/String 兼容）
│   │   └── ...                            # User / Company / BaseResponse 等
│   ├── Network/HTTPClient.swift           # 网络单例，统一 request<T> + 全部业务接口
│   ├── Network/WebSocketManager.swift     # WebSocket（AI 对话，暂未启用）
│   ├── Theme/Colors.swift                 # 全部颜色
│   ├── Theme/Dimens.swift                 # 全部尺寸、字号、间距
│   ├── Utils/TokenManager.swift           # token 读写
│   ├── Utils/Validators.swift             # 邮箱等校验
│   ├── Utils/MusicUtils.swift             # 封面地址拼接（含 http→https 升级）等音乐工具方法
│   ├── UI/Pages/                          # 完整页面
│   │   ├── WelcomePage.swift              # 欢迎页（校验登录态）
│   │   ├── LoginPage.swift                # 登录（账号密码 / 邮箱验证码）
│   │   ├── RegisterPage.swift             # 注册
│   │   ├── ForgetPasswordPage.swift       # 忘记密码
│   │   ├── ResetPasswordPage.swift        # 重置密码
│   │   ├── UserInfoPage.swift             # 用户信息
│   │   ├── MusicIndexPage.swift           # 主页：四 Tab 容器 + 底部迷你播放器
│   │   ├── MusicHomePage.swift            # 首页 Tab：搜索栏 + 分类入口 + 榜单/歌手模块
│   │   ├── MusicRecommentPage.swift       # 推荐 Tab（占位）
│   │   ├── MusicCirclePage.swift          # 音乐圈 Tab（占位）
│   │   ├── MusicUserPage.swift            # 我的 Tab（占位）
│   │   └── MusicPlayerPage.swift          # 音乐播放页（占位）
│   ├── UI/Components/                     # 组件
│   │   ├── AppLogo.swift                  # 应用 Logo（icon_logo）
│   │   ├── CustomTextField.swift          # 圆角输入框
│   │   ├── HomeTabBar.swift               # 首页底部 Tab 栏（含中央凹槽）
│   │   ├── MiniPlayerView.swift           # 中央迷你播放器（旋转唱片）
│   │   ├── MusicSearchBar.swift           # 首页搜索栏（头像 + 关键词 + AI）
│   │   ├── MusicCategoryEntryRow.swift    # 首页四个分类入口
│   │   ├── MusicModuleHeader.swift        # 模块标题栏（折叠 + 更多）
│   │   ├── MusicModuleCard.swift          # 歌曲模块卡片（3 首 + 点赞）
│   │   ├── MusicSingerCard.swift          # 推荐歌手模块卡片
│   │   ├── MusicSongRow.swift             # 歌曲行
│   │   ├── MusicCoverView.swift           # 圆形封面 / 歌手头像
│   │   ├── UserAvatar.swift               # 当前用户头像
│   │   ├── PlaceholderPage.swift          # 占位页（统一 hello world）
│   │   └── PlaceholderDetailPage.swift    # 二级页面占位（带返回栏）
│   ├── Assets.xcassets                    # AppIcon / icon_logo / Tab 图标 / 首页图标 / 默认封面头像
│   └── Resources/                          # 静态图片资源
├── README.md
├── 提示词.md                               # AI 开发规范（最高优先级约束）
├── gitee-push.sh / github-push.sh          # 一键推送脚本
└── *.png / *.jpg                           # README 截图（不参与打包）
```

## 开发规范（摘要）

完整规范见 [提示词.md](提示词.md)，核心铁律：

- **目录**：页面 → `UI/Pages/`；组件 → `UI/Components/`；模型 → `Models/`；接口路径与常量 → `Config/Constants.swift`；主题 → `Theme/`。
- **间距**：一律 `Dimens.middleMargin`（15）。
- **卡片**：除 MusicIndexPage 外所有页面模块都用卡片 —— 圆角 `Dimens.borderRadius`、背景 `Colors.whiteColor`、内边距 `Dimens.middleMargin`。
- **按钮**：高 `Dimens.btnHeight`，圆角 `Dimens.btnHeight / 2`；确定 = `Colors.primaryColor` 底 + 白字；取消 = 透明底 + `Colors.grayColor` 边框与文字；禁用 = `Colors.grayColor` 底；删除 = `Colors.warnColor` 底。
- **输入框**：高 `Dimens.inputHeight`，圆角 `Dimens.inputHeight / 2`。
- **字体**：正文 `Dimens.normalFont`(17)、主标题 `Dimens.middleFont`(20)、大标题 `Dimens.bigFont`(30)。
- **颜色**：页面背景 `Colors.pageBackgroundColor`、主色 `Colors.primaryColor`、警告/删除 `Colors.warnColor`、灰 `Colors.grayColor`、次要文字 `Colors.subColor`。

## 网络层调用规范

```
页面 → HTTPClient.shared.<业务方法>(...) { result in DispatchQueue.main.async { ... } }
          └→ HTTPClient.request<T>(endpoint: APIEndpoint, ...)
                 ├─ URL  = Constants.baseURL + endpoint.path
                 ├─ 方法 = endpoint.method
                 ├─ 头部 = Authorization: Bearer <TokenManager.shared token>
                 └─ 解码 = BaseResponse<T>（status == "SUCCESS" 才算成功，用 isSuccess 判断）
```

**新增一个接口必须改四处**（顺序固定）：

1. `Config/Constants.swift` → `Constants.API` 加路径常量
2. `Api/APIEndpoints.swift` → `APIEndpoint` 加 case，并在 `path`、`method` 两个 switch 中补齐
3. `Network/HTTPClient.swift` → 加业务方法，回调 `(Result<T, NetworkError>) -> Void`
4. 页面中调用，回调里 `DispatchQueue.main.async` 后再改 `@State`

> 后端返回的 snake_case 字段由后端 `ResultUtil` 自动转驼峰，客户端模型直接用驼峰，无需 `CodingKeys` 映射下划线。

## 主流程（当前阶段）

```
WelcomePage（校验 token）
  ├─ 有效 → MusicIndexPage
  └─ 无效 → LoginPage ─┬→ 登录成功 → MusicIndexPage
                       ├→ RegisterPage ─── 注册成功 → MusicIndexPage
                       └→ ForgetPasswordPage → ResetPasswordPage ─── 重置成功 → MusicIndexPage

MusicIndexPage（四 Tab 容器，对齐 uniapp MusicIndexPage.vue / flutter MusicIndexPage.dart）
  ├─ 首页   → MusicHomePage（搜索栏 + 分类入口 + 榜单/歌手模块）
  ├─ 推荐   → MusicRecommentPage（占位）
  ├─ 音乐圈 → MusicCirclePage（占位）
  ├─ 我的   → MusicUserPage（占位）
  └─ 中央迷你播放器（旋转唱片）→ MusicPlayerPage（占位）
```

### 首页（MusicHomePage）实现要点

| 能力 | 说明 | 对应的 uniapp / flutter |
|------|------|--------------------------|
| 搜索栏 | 用户头像 + 推荐关键词（`getKeywordMusic`）+ AI 入口 | `MusicSearchComponent` / `buildSearchWidget` |
| 分类入口 | 歌手 / 分类歌曲 / 经典老歌 / 热门榜单（前两个可点） | `.category-wrapper` / `buildClassifyWidget` |
| 榜单模块 | 每个分类一张卡片，展示前 3 首歌，可折叠、可看更多 | `MusicClassifyComponent` / `buildMusicModuleByClassifyIdWidget` |
| 推荐歌手模块 | `category/classify == 推荐歌手` 时展示 4 个歌手 | `MusicSingerComponent` / `buildMusicAuthorListWidget` |
| 分页 | 初始 3 个模块，滚动到底 +1，到底显示「已经到底了」 | `pageNum` / `EasyRefresh.onLoad` |
| 播放 | 点歌 → 立即播放 + 拉取整榜单作为播放列表 → 进播放页 | `usePlayMusic` |
| 点赞 | 喜欢 / 取消喜欢（`insertMusicLike` / `deleteMusicLike`） | `MusicClassifyListComponent.useLike` |
| 二级页面 | 搜索 / 歌手分类 / 榜单列表 / 歌手歌曲 / AI / 个人中心 → 占位页 | `uni.navigateTo(...)` |

接口一览（音乐模块，全部走网关 `http://127.0.0.1:4000`）：

| 接口 | 方法 | 用途 |
|------|------|------|
| `/service/music/getKeywordMusic` | GET | 搜索框推荐关键词（单曲） |
| `/service/music/getMusicCategory` | GET | 首页分类模块列表 |
| `/service/music/getMusicListByCategoryId` | GET | 分类歌曲（分页，首页取 3 条） |
| `/service/music/getMusicAuthorListByCategoryId` | GET | 推荐歌手（首页取 4 个） |
| `/service/music/insertMusicLike/{musicId}` | POST | 点赞 |
| `/service/music/deleteMusicLike/{musicId}` | DELETE | 取消点赞 |

> 封面/头像统一走 `MusicUtils.coverURL(_:)`：相对路径拼 `baseURL`，外链自动把 `http://` 升级为 `https://`
> （iOS ATS 默认禁止 http 明文，第三方封面常是 http，不升级会一直落到默认图）。

### 主页容器（MusicIndexPage）实现要点

| 能力 | 说明 |
|------|------|
| 四 Tab 切换 | `HomeTabBar` + `selectedIndex`，选中态用 `*_active` 图标 + `Colors.primaryColor` 文字 |
| Tab 懒加载 | `initializedTabs`：只有点过的 Tab 才创建视图（对齐 uniapp `isInitComponent`） |
| 状态保留 | 已创建的 Tab 用 `opacity` + `allowsHitTesting` 隐藏，切回来不重建（对齐 `v-show` / keepAlive） |
| 中央迷你播放器 | `MiniPlayerView`：外圈页面背景色做凹槽，内圈封面；播放中 10 秒转一圈 |
| 播放状态 | `PlayerState.shared`：当前歌曲 / 播放列表 / 循环模式，`UserDefaults` 持久化，进首页时恢复 |

## 运行方式

1. 用 Xcode 26 打开 `music.xcodeproj`，选择 `music` scheme。
2. 选一台 iOS 26.2 模拟器（例如 iPhone 17 Pro），Command + R 运行。
3. 确保后端网关 `http://127.0.0.1:4000` 可用（`Config/Constants.swift` 中的 `baseURL`）。
4. 命令行构建验证：

```bash
xcodebuild -project music.xcodeproj -scheme music \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

> 登录密码在客户端先做 MD5 再提交（`password.md5`），与后端口径一致，测试账号：`吴时吴刻` / `123456`。

## 开发进度

| 阶段 | 内容 | 状态 |
|------|------|------|
| 一 | 基础工程搭建 + 用户模块（登录 / 注册 / 忘记密码 / 重置密码 / 用户信息）+ MusicIndexPage 占位 | ✅ 已完成 |
| 二 | MusicIndexPage 四 Tab 框架（Tab 切换 / 懒加载 / 中央迷你播放器 / 播放状态缓存）+ 五张占位页 | ✅ 已完成 |
| 三 | 首页 Tab 正式内容（搜索栏 / 分类入口 / 榜单模块 / 推荐歌手 / 加载更多 / 点赞 / 点歌进播放页） | ✅ 已完成 |
| 四 | 推荐 / 音乐圈 / 我的 三个 Tab 的正式内容 | ⏳ 待开发 |
| 五 | 音乐播放页（唱片旋转、歌词、进度、播放控制、评论点赞收藏） | ⏳ 待开发 |
| 六 | 二级跳转页（搜索、歌手分类、榜单列表、歌手歌曲列表、播放记录等） | ⏳ 待开发 |

> 首页里的二级页面（搜索 / 歌手分类 / 榜单列表 / 歌手歌曲 / AI 聊天 / 个人中心）当前统一用
> `PlaceholderDetailPage` 占位，跳转链路已通；实现某个页面时把 `MusicDetailRoute` 对应分支换成真实页面即可。

## 界面预览

> 以下截图为 **uniapp 版本的实际效果**，SwiftUI 版本按此逐个页面复刻（如果无法预览，请查看项目根目录 png 文件）。

![整体预览图](整体预览图.png)
![音乐首页](音乐首页.png)
![音乐推荐](音乐推荐.jpg)
![分类歌曲](分类歌曲.png)
![音乐搜索列表](音乐搜索列表.png)
![音乐播放页](音乐播放页.png)
![音乐歌词页](音乐歌词页.png)
![音乐歌手页](音乐歌手页.jpg)
![音乐歌手专辑页](音乐歌手专辑页.png)
![音乐点赞和评论](音乐点赞和评论.png)
![音乐收藏列表](音乐收藏列表.png)
![音乐圈评论](音乐圈评论.png)
![音乐朋友圈1](音乐朋友圈1.jpg)
![音乐朋友圈2](音乐朋友圈2.png)
![音乐我的1](音乐我的1.jpg)
![音乐我的2](音乐我的2.png)
![登录](登录.png)
![账号密码登录](账号密码登录.png)
![邮箱验证码登录](邮箱验证码登录.png)
![注册页面](注册页面.png)
![忘记密码](忘记密码.png)
![找回密码页面](找回密码页面.png)
![重置密码](重置密码.png)
![重置密码页面](重置密码页面.png)
![修改密码](修改密码.png)
![修改密码页面](修改密码页面.png)
![用户信息](用户信息.png)
![更改用户信息1](更改用户信息1.png)
![更改用户信息2](更改用户信息2.png)
![更改用户信息3](更改用户信息3.png)
![更改用户信息4](更改用户信息4.png)
![修改用户信息](修改用户信息.png)

## 代码提交

```bash
# Gitee
./gitee-push.sh

# GitHub
./github-push.sh
```

- Gitee：https://gitee.com/wuyuanwuhui99/swift-music-app
- GitHub：https://github.com/wuyuanwuhui999/swift-music-app

欢迎 Star / Fork，期待协作共建！ 🎵
