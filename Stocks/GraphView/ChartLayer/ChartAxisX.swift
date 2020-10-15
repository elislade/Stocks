import QuartzCore

class ChartAxisX: CAShapeLayer {
    
    struct XLabelViewData {
        let range: Range<Int>
        let value: String
        let alignment: CATextLayerAlignmentMode
    }
    
    let labelHeight: CGFloat = 15
    
    var isFullscreen: Bool = false
    var timeInterval: TimeInterval = .oneMonth
    
    var dates: [Date] = [] {
        didSet { setNeedsDisplay() }
    }
    
    func strings(from component:Calendar.Component) -> [String]? {
        switch component {
        case .month: return Calendar.current.shortMonthSymbols
        case .weekday: return Calendar.current.shortWeekdaySymbols
        default: return nil
        }
    }
    
    private func makeLabel(string: String) -> CATextLayer {
        let label = CATextLayer()
        label.string = string
        label.contentsScale = 2.0
        label.fontSize = 12
        label.frame = CGRect(x: 0, y: 0, width: 60, height: labelHeight)
        label.foregroundColor = isFullscreen ? .white : CGColor.white.copy(alpha: 0.7)
        return label
    }
    
    private func makeXAxisData() -> [XLabelViewData] {
        var data = [XLabelViewData]()
        
        guard dates.count > 0 else { return data }
        
        let ranges = makeXDataRanges()
        
        for i in ranges.enumerated() {
            let range = i.element.range
            let comp = timeInterval.calComponent()
            let c = Calendar.current.component(comp, from: i.element.candle)
            var value = "\(c)"
            if let s = strings(from: comp) {
                value = s[c-1]
            }
            data.append(XLabelViewData(range:range, value: value, alignment: .left))
        }
        return data
    }
    
    private func makeXDataRanges() -> [(range: Range<Int>, candle: Date)] {
        var ranges = [(Range<Int>, Date)]()
        
        var lastStartIndex = 0
        var lastCandle = dates.first!
        
        for i in dates.enumerated() {
            let s = timeInterval.subPattern()
            let lastComp = Calendar.current.component(s.comp, from: lastCandle)
            let currentComp = Calendar.current.component(s.comp, from: i.element)
            
            if currentComp >= lastComp + s.change || lastComp > currentComp {
                ranges.append((lastStartIndex..<i.offset, dates[lastStartIndex]))
                lastStartIndex = i.offset
                lastCandle = i.element
            }
        }
        ranges.append((lastStartIndex..<dates.count, dates[lastStartIndex]))
        return ranges
    }
    
    override func display() {
        let step = bounds.width / CGFloat(dates.count - 1)
        sublayers = []
        
        let _path = CGMutablePath()
        
        for data in makeXAxisData() {
            let x = CGFloat(data.range.lowerBound) * step
            let label = makeLabel(string: data.value)
            let width = (CGFloat(data.range.count) * step) - 1
            label.frame.size.width = width
            label.alignmentMode = data.alignment
            label.frame.origin.y = bounds.height - label.frame.height
            label.frame.origin.x = x
            addSublayer(label)
            _path.move(to: CGPoint(x: x + width + 1, y: 0))
            _path.addLine(to: CGPoint(x: x + width + 1, y: bounds.height))
        }
        
        lineWidth = 1
        path = _path
        lineCap = .round
        strokeColor = CGColor.white.copy(alpha: 0.15)
    }
    
}
