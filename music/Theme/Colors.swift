import SwiftUI

struct Colors {
    // 主色调
    static let primaryColor = Color(red: 255/255, green: 174/255, blue: 0/255)
    
    static let warnColor = Color(red: 255/255, green: 59/255, blue: 48/255)

    // 灰色，用于小标题、禁用按钮、提示文字、禁用文字
    static let grayColor = Color(red: 221/255, green: 221/255, blue: 221/255)
    
    static let subColor = Color(red:128/255,green:128/255,blue:128/255)
    
    // 白色
    static let whiteColor = Color.white
    
    static let blackColor = Color.black;
    
    // 页面背景颜色
    static let pageBackgroundColor = Color(red: 239/255, green: 239/255, blue: 239/255)

    // MARK: - 播放页专用
    /// 半透明黑：唱片外圈底色 / 进度条未选中部分（uniapp rgba(0,0,0,0.1)）
    static let opacityBlack = Color.black.opacity(0.1)
    /// 半透明白：唱片外圈、进度条底色（uniapp rgba(255,255,255,0.2)）
    static let opacityWhite = Color.white.opacity(0.3)
    /// 唱片渐变中间色（uniapp @linear-gradient #333）
    static let discGradient = Color(red: 51/255, green: 51/255, blue: 51/255)

    /// 蓝色辅助色：音乐圈昵称、点赞用户名（uniapp @blue-color #3e7d9b）
    static let blueColor = Color(red: 62/255, green: 125/255, blue: 155/255)
}

// 扩展Color以便更方便使用
extension Color {
    static let themePrimary = Colors.primaryColor
    static let themeSub = Colors.subColor
    static let themeGray = Colors.grayColor
    static let themeWhite = Colors.whiteColor
    static let themeBackground = Colors.pageBackgroundColor
    static let blackColor = Colors.blackColor
    static let whiteColor = Colors.whiteColor
    static let warnColor = Colors.warnColor
}
