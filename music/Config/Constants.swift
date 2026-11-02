import Foundation
// 在 Constants 结构体中添加新的 API 路径
struct Constants {
    // API基础域名
    static let baseURL = "http://127.0.0.1:4000"
    
    // WebSocket 地址
    static let webSocketURL = "ws://127.0.0.1:4000/service/chat/ws/chat"
        
    // 其他常量配置
    struct Timeout {
        static let request: TimeInterval = 30
        static let resource: TimeInterval = 60
    }
    
    struct Cache {
        static let maxAge: TimeInterval = 3600 * 24 * 30 // 1个月
    }
    
    /// 本地缓存 key（与 uniapp 版本的 uni.setStorage key 保持一致，方便两端对齐）
    struct StorageKey {
        static let music = "MUSIC_STORAGE_KEY"            // 当前播放的音乐
        static let musicList = "MUSIC_LIST_STORAGE_KEY"   // 播放列表
        static let loopMode = "LOOP_STORAGE_KEY"          // 循环播放模式
        static let circleUpdateTime = "CIRCLE_UPDATE_TIME" // 音乐圈上次查看时间
        static let musicSearchHistory = "MUSIC_SEARCH_HISTORY_KEY" // 搜索历史（逗号分隔）
    }

    /// 音乐模块通用配置（对齐 uniapp `common/constant.ts`）
    struct MusicConfig {
        /// 通用分页数量（uniapp PAGE_SIZE）
        static let pageSize = 20
        /// 播放列表一次拉取的最大条数（uniapp MAX_FAVORITE_NUMBER）
        static let maxPlaylistCount = 500
        /// 首页每个模块展示的歌曲数
        static let homeModuleSongCount = 3
        /// 首页初始加载的模块数（滚动到底再加 1）
        static let homeModuleInitialCount = 3
        /// 「推荐歌手」模块展示的歌手数
        static let homeSingerCount = 4
        /// 推荐页播放列表所属模块名（对齐 uniapp 推荐页的 "推荐歌曲"）
        static let recommendClassifyName = "推荐歌曲"
        /// 「我的」页：我喜欢的歌曲展示条数（对齐 flutter 5 条）
        static let userLikedCount = 5
        /// 「我的」页：我关注的歌手展示条数
        static let userAuthorCount = 5
        /// 「我的」页：播放记录展示条数（对齐 flutter 10 条）
        static let userRecordCount = 10
        /// 搜索结果的播放列表名（对齐 uniapp 搜索页的 "搜索"）
        static let searchClassifyName = "搜索"
        /// 搜索历史最多保留条数（对齐 flutter 20 条）
        static let searchHistoryMax = 20
    }

    /// 音乐圈 / 社交模块通用配置（对齐 uniapp `common/enum.ts` 的 CircleEnum / CommentEnum）
    struct CircleConfig {
        /// 音乐圈动态类型（查询动态列表用）
        static let musicType = "MUSIC"
        /// 音乐圈动态的点赞 / 评论关联类型
        static let musicCircleRelation = "MUSIC_CIRCLE"
        /// 每页条数（对齐 uniapp 音乐圈 pageSize）
        static let pageSize = 10
        /// 动态可见范围：公开
        static let permissionPublic = 1
        /// 动态可见范围：私密
        static let permissionPrivate = 0

        /// 可见范围文案（对齐 uniapp `PermissionMap`）
        static func permissionName(_ permission: Int) -> String {
            permission == permissionPrivate ? "私密" : "公开"
        }
    }
    
    // API路径
    struct API {
        static let login = "/service/user/login"
        static let register = "/service/user/register"
        static let getUserData = "/service/user/getUserData"
        static let logout = "/service/user/logout"
        static let sendEmailVertifyCode = "/service/user/sendEmailVertifyCode"
        static let loginByEmail = "/service/user/loginByEmail"
        static let getTenantList = "/service/tenant/getTenantList"
        static let getDirectoryList = "/service/chat/getDirectoryList"
        static let getDocListByDirId = "/service/chat/getDocListByDirId"
        static let getPublicDocList = "/service/chat/getPublicDocList"
        static let createDir = "/service/chat/createDir"
        static let getChatHistory = "/service/chat/getChatHistory"
        static let getChatHistoryByChatId = "/service/chat/getChatHistoryByChatId"
        static let uploadDoc = "/service/chat/uploadDoc"
        static let deleteDoc = "/service/chat/deleteDoc/{docId}"
        static let updateDocPermission = "/service/chat/updateDocPermission"
        static let updateUser = "/service/user/updateUser"
        static let updateAvater = "/service/user/updateAvater"
        static let vertifyUser = "/service/user/vertifyUser"
        static let resetPassword = "/service/user/resetPassword"
        static let updatePassword = "/service/user/updatePassword"
        static let getPrompt = "/service/prompt/getPrompt"
        static let updatePrompt = "/service/prompt/updatePrompt"
        static let getCompanyList = "/service/company/getCompanyList"
        static let getTenantUserList = "/service/tenant/getTenantUserList"
        static let addTenantUser = "/service/tenant/addTenantUser/{tenantId}/{userId}"

        static let addAdmin = "/service/tenant/addAdmin/{tenantId}/{userId}"
        static let cancelAdmin = "/service/tenant/cancelAdmin/{tenantId}/{userId}"
        static let searchCompanyUsers = "/service/company/searchUsers"

        static let getCompanyUsers = "/service/company/getCompanyUsers"
        static let addCompanyUser = "/service/company/addUser"

        static let getDepartments = "/service/company/getDepartments"
        static let getPositions = "/service/company/getPositions"
        static let searchTenantUsers = "/service/tenant/searchTenantUsers"

        static let getPromptList = "/service/prompt/getPromptList"
        static let deletePrompt = "/service/prompt/deletePrompt/{promptId}"
        static let insertPrompt = "/service/prompt/insertPrompt"
        
        static let getModelList = "/service/chat/getModelList"
        static let addModel = "/service/chat/addModel"
        static let deleteModel = "/service/chat/deleteModel/{modelId}"
        static let updateModel = "/service/chat/updateModel"

        // MARK: - 音乐模块（music-service）
        static let getKeywordMusic = "/service/music/getKeywordMusic"
        static let getMusicCategory = "/service/music/getMusicCategory"
        static let getMusicListByCategoryId = "/service/music/getMusicListByCategoryId"
        static let getMusicAuthorListByCategoryId = "/service/music/getMusicAuthorListByCategoryId"
        static let searchMusic = "/service/music/searchMusic"
        static let getMusicListByAuthorId = "/service/music/getMusicListByAuthorId"
        static let insertMusicLike = "/service/music/insertMusicLike/{musicId}"
        static let deleteMusicLike = "/service/music/deleteMusicLike/{musicId}"

        // MARK: - 我的（MusicUserPage）相关
        static let getMusicLike = "/service/music/getMusicLike"
        static let getMusicRecord = "/service/music/getMusicRecord"
        static let getFavoriteAuthor = "/service/music/getFavoriteAuthor"
        static let deleteFavoriteAuthor = "/service/music/deleteFavoriteAuthor/{authorId}"
        static let getFavoriteDirectory = "/service/music/getFavoriteDirectory"
        static let insertFavoriteDirectory = "/service/music/insertFavoriteDirectory"
        static let deleteFavoriteDirectory = "/service/music/deleteFavoriteDirectory/{favoriteId}"

        // MARK: - 音乐圈 / 社交模块
        static let getCircleListByType = "/service/circle/getCircleListByType"
        static let saveLike = "/service/social/saveLike"
        static let deleteLike = "/service/social/deleteLike"
        static let insertComment = "/service/social/insertComment"
        static let insertCircle = "/service/circle/insertCircle"
    }
}
