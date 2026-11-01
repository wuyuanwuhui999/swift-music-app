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
│   ├── Models/                            # 数据模型 + AppState + BaseResponse
│   ├── Network/HTTPClient.swift           # 网络单例，统一 request<T> + 全部业务接口
│   ├── Network/WebSocketManager.swift     # WebSocket（AI 对话，暂未启用）
│   ├── Theme/Colors.swift                 # 全部颜色
│   ├── Theme/Dimens.swift                 # 全部尺寸、字号、间距
│   ├── Utils/TokenManager.swift           # token 读写
│   ├── Utils/Validators.swift             # 邮箱等校验
│   ├── UI/Pages/                          # 完整页面
│   │   ├── WelcomePage.swift              # 欢迎页（校验登录态）
│   │   ├── LoginPage.swift                # 登录（账号密码 / 邮箱验证码）
│   │   ├── RegisterPage.swift             # 注册
│   │   ├── ForgetPasswordPage.swift       # 忘记密码
│   │   ├── ResetPasswordPage.swift        # 重置密码
│   │   ├── UserInfoPage.swift             # 用户信息
│   │   └── HomePage.swift                 # 主页（当前仅 hello world 占位）
│   ├── UI/Components/                     # 组件
│   │   ├── AppLogo.swift                  # 应用 Logo（icon_logo）
│   │   └── CustomTextField.swift          # 圆角输入框
│   ├── Assets.xcassets                    # AppIcon / AccentColor / icon_logo
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
- **卡片**：除 HomePage 外所有页面模块都用卡片 —— 圆角 `Dimens.borderRadius`、背景 `Colors.whiteColor`、内边距 `Dimens.middleMargin`。
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
  ├─ 有效 → HomePage（hello world 占位）
  └─ 无效 → LoginPage ─┬→ 登录成功 → HomePage
                       ├→ RegisterPage ─── 注册成功 → HomePage
                       └→ ForgetPasswordPage → ResetPasswordPage ─── 重置成功 → HomePage
HomePage（后续迭代：底部 Tab = 首页 / 推荐 / 音乐圈 / 我的，用户信息 → UserInfoPage）
```

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
| 一 | 基础工程搭建 + 用户模块（登录 / 注册 / 忘记密码 / 重置密码 / 用户信息）+ HomePage 占位 | ✅ 已完成 |
| 二 | 首页 / 推荐 / 分类 / 排行榜（music 模块接口） | ⏳ 待开发 |
| 三 | 音乐播放页 / 歌词页 / 播放控制与后台播放 | ⏳ 待开发 |
| 四 | 音乐圈（动态、评论、点赞）、收藏与播放记录 | ⏳ 待开发 |
| 五 | 「我的」页与设置、头像上传、修改密码 | ⏳ 待开发 |

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
