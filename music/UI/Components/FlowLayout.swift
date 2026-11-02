//
//  FlowLayout.swift
//  music
//
//  Created by 吴文强 on 2026/11/01.
//

import SwiftUI

/// 自动换行的流式布局（子视图按行排布，放不下就换行）
///
/// 用于搜索页的历史搜索标签，对齐 flutter `Wrap` 的效果。
struct FlowLayout: Layout {
    /// 水平间距
    var spacing: CGFloat = Dimens.smallMargin
    /// 垂直间距
    var lineSpacing: CGFloat = Dimens.smallMargin

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0 && rowWidth + spacing + size.width > maxWidth {
                // 换行
                totalHeight += rowHeight + lineSpacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }

        totalHeight += rowHeight
        return CGSize(width: proposal.width ?? rowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                // 换行
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    FlowLayout {
        ForEach(["黄昏", "周传雄", "刘欢", "王菲", "笑傲江湖", "盛夏的果实"], id: \.self) { item in
            Text(item)
                .font(.system(size: Dimens.normalFont))
                .padding(.horizontal, Dimens.middleMargin)
                .padding(.vertical, Dimens.smallMargin)
                .background(Colors.pageBackgroundColor)
                .cornerRadius(Dimens.smallMargin)
        }
    }
    .padding()
}
