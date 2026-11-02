import SwiftUI

struct Dimens {
    // 头像尺寸
    static let smallAvater: CGFloat = 30
    static let middleAvater: CGFloat = 50
    static let bigAvater: CGFloat = 80
    
    // 图标尺寸
    static let smallIcon: CGFloat = 15
    static let middleIcon: CGFloat = 30
    static let bigIcon: CGFloat = 50
    
    // 字体大小
    static let normalFont:CGFloat = 17
    static let middleFont:CGFloat = 20
    static let bigFont:CGFloat = 30
    
    static let smallMargin: CGFloat = 10
    static let middleMargin: CGFloat = 15
    static let largeMargin: CGFloat = 20
    
    static let btnHeight: CGFloat = 50
    static let smallBtnHeight:CGFloat = 40
    static let inputHeight: CGFloat = 50
    
    static let borderRadius: CGFloat = 10
    
    // MARK: - 音乐项目独有尺寸（对齐 flutter-music-app-ui 的 ThemeSize）
    /// 底部 Tab 栏高度
    static let bottomBarHeight: CGFloat = 85
    /// 底部中央迷你播放器直径（flutter: minPlayIcon）
    static let miniPlayerSize: CGFloat = 80
    /// 迷你播放器外圈描边宽度（页面背景色，用于做「凹槽」效果）
    static let miniPlayerBorder: CGFloat = 3
    /// 音乐圈未读红点直径
    static let redCircle: CGFloat = 8

    // MARK: - 首页（MusicHomePage）专用尺寸（对齐 uniapp 的 rpx 值）
    /// 歌曲列表行封面直径（uniapp @middle-avater 80rpx）
    static let musicCover: CGFloat = 40
    /// 推荐歌手头像直径（uniapp @big-avater 120rpx）
    static let musicSingerAvatar: CGFloat = 60
    /// 列表行操作小图标（uniapp @sm-icon-size 40rpx）
    static let musicRowIcon: CGFloat = 20
    /// 分类入口大图标（uniapp @lg-icon-size * 1.5 = 105rpx）
    static let musicCategoryIcon: CGFloat = 52
    /// 模块标题前的展开/折叠箭头（uniapp @sm-icon-size 40rpx）
    static let musicArrowIcon: CGFloat = 20
    /// 首页搜索框高度（uniapp @middle-avater 80rpx）
    static let musicSearchHeight: CGFloat = 40

    // MARK: - 播放页专用尺寸（对齐 uniapp 的 rpx 值）
    /// 唱片直径（uniapp @play-circle-size 500rpx）
    static let playerDisc: CGFloat = 250
    /// 唱片内圈内边距（uniapp @middle-avater 80rpx）
    static let playerDiscPadding: CGFloat = 40
    /// 播放 / 暂停圆钮直径（uniapp @big-avater 120rpx）
    static let playerCircle: CGFloat = 60
    /// 播放 / 暂停圆钮描边宽度（uniapp @border-size 5rpx）
    static let playerCircleBorder: CGFloat = 2.5
    /// 播放页循环模式弹层宽度（uniapp @popup-menu-width 300rpx）
    static let playerLoopMenuWidth: CGFloat = 150

    // MARK: - 音乐圈专用尺寸（对齐 uniapp 的 rpx 值）
    /// 动态操作气泡菜单宽度（uniapp @popup-menu-width 300rpx）
    static let circleActionMenuWidth: CGFloat = 150
    /// 动态操作气泡菜单高度（uniapp @popup-menu-height 80rpx）
    static let circleActionMenuHeight: CGFloat = 40
    /// 发布动态悬浮按钮直径（uniapp @middle-avater 80rpx）
    static let circlePublishButton: CGFloat = 40
    /// 发布动态页文字输入区高度
    static let shareTextAreaHeight: CGFloat = 160
}

// 扩展CGFloat以便更方便使用
extension CGFloat {
    static let smallAvater = Dimens.smallAvater
    static let middleAvater = Dimens.middleAvater
    static let bigAvater = Dimens.bigAvater
    
    static let smallIcon = Dimens.smallIcon
    static let middleIcon = Dimens.middleIcon
    static let bigIcon = Dimens.bigIcon
    
    static let normalFont: CGFloat = Dimens.normalFont
    static let middleFont: CGFloat = Dimens.middleFont
    static let bigFont: CGFloat = Dimens.bigFont
    
    static let smallMargin: CGFloat = Dimens.smallMargin
    static let middleMargin: CGFloat = Dimens.middleMargin
    static let largeMargin: CGFloat = Dimens.largeMargin
    
    static let btnHeight: CGFloat = Dimens.btnHeight
    static let smallBtnHeight:CGFloat = Dimens.smallBtnHeight
    static let inputHeight: CGFloat = Dimens.inputHeight
    
    static let borderRadius: CGFloat = Dimens.borderRadius
}
