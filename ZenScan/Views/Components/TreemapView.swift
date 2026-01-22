import SwiftUI

/// Treemap rectangle component for disk visualization
struct TreemapView: View {
    let items: [DiskSpaceItem]
    let totalSize: Int64
    let onSelect: (DiskSpaceItem) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            TreemapLayout(
                items: items,
                totalSize: totalSize,
                rect: CGRect(origin: .zero, size: geometry.size),
                onSelect: onSelect
            )
        }
    }
}

/// Recursive treemap layout
struct TreemapLayout: View {
    let items: [DiskSpaceItem]
    let totalSize: Int64
    let rect: CGRect
    let onSelect: (DiskSpaceItem) -> Void
    
    var body: some View {
        let rects = calculateRects(items: items, in: rect)
        
        ZStack(alignment: .topLeading) {
            ForEach(Array(zip(items, rects)), id: \.0.id) { item, itemRect in
                TreemapCell(
                    item: item,
                    rect: itemRect,
                    onSelect: onSelect
                )
            }
        }
    }
    
    /// Squarified treemap algorithm
    private func calculateRects(items: [DiskSpaceItem], in rect: CGRect) -> [CGRect] {
        guard !items.isEmpty, totalSize > 0 else { return [] }
        
        var rects: [CGRect] = []
        var remaining = rect
        var isVertical = rect.width < rect.height
        
        for item in items {
            let ratio = CGFloat(item.size) / CGFloat(totalSize)
            let area = ratio * rect.width * rect.height
            
            var itemRect: CGRect
            if isVertical {
                let height = min(area / remaining.width, remaining.height)
                itemRect = CGRect(
                    x: remaining.minX,
                    y: remaining.minY,
                    width: remaining.width,
                    height: height
                )
                remaining = CGRect(
                    x: remaining.minX,
                    y: remaining.minY + height,
                    width: remaining.width,
                    height: remaining.height - height
                )
            } else {
                let width = min(area / remaining.height, remaining.width)
                itemRect = CGRect(
                    x: remaining.minX,
                    y: remaining.minY,
                    width: width,
                    height: remaining.height
                )
                remaining = CGRect(
                    x: remaining.minX + width,
                    y: remaining.minY,
                    width: remaining.width - width,
                    height: remaining.height
                )
            }
            
            rects.append(itemRect)
            isVertical.toggle()
        }
        
        return rects
    }
}

/// Individual treemap cell
struct TreemapCell: View {
    let item: DiskSpaceItem
    let rect: CGRect
    let onSelect: (DiskSpaceItem) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button {
            onSelect(item)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(item.color.opacity(isHovered ? 0.9 : 0.7))
                
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                
                if rect.width > 60 && rect.height > 40 {
                    VStack(spacing: 2) {
                        Text(item.name)
                            .font(.caption2)
                            .lineLimit(1)
                        
                        Text(item.formattedSize)
                            .font(.caption2)
                            .opacity(0.8)
                    }
                    .foregroundColor(.white)
                    .padding(4)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: rect.width, height: rect.height)
        .offset(x: rect.minX, y: rect.minY)
        .onHover { isHovered = $0 }
    }
}
