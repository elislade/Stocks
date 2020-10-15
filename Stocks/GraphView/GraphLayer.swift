import QuartzCore

class ChartLayer:CALayer {
    
    struct YLabelViewData {
        let strings: [String]
        let alignment: CATextLayerAlignmentMode
    }
    
    struct XLabelViewData {
        let range: Range<Int>
        let value: String
        let alignment: CATextLayerAlignmentMode
    }
    
    var yAxisLabel: YLabelViewData = YLabelViewData(strings: ["No Data"], alignment: .right)
    var timeInterval: TimeInterval = .oneMonth
    var isFullscreen: Bool = false
    
    
    //MARK: - Private Vars
    
    private(set) var prevIndex: Int = 0
    private(set) var prevRange: ClosedRange<Int> = 0...0
    private let labelHeight: CGFloat = 16
    private var points: [CGPoint] = []
    
    private var maxClose: Double = 0
    private var minClose: Double = 0
    private var maxVolume: Int = 0
    private var minVolume: Int = 0
    
    
    // MARK: - Layers
    private var graphLayer = CALayer()
    
    private var volumeLayer = CAShapeLayer() // relative volume
    private var axisYLayer = CAShapeLayer()  // prices
    private var axisXLayer = CAShapeLayer()  // dates
    
    private var feebackLabel = CATextLayer()
    
    private var graphLayerSelection = CALayer()
    private var volumeLayerSelection = CAShapeLayer()
    
    override init() {
        super.init()
        addSublayer(graphLayer)
        addSublayer(volumeLayer)
        addSublayer(makeBaseLine(y: 0))
        //addSublayer(makeBaseLine(y: graphRect.height + (labelHeight * 2)))
        addSublayer(axisYLayer)
        addSublayer(axisXLayer)
        
        addSublayer(graphLayerSelection)
        addSublayer(volumeLayerSelection)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var candles = [CandleConformable]() {
        didSet {
            if candles.count > 3 {
                feebackLabel.opacity = 0
                
                maxClose = candles.max { $0.close < $1.close }!.close
                minClose = candles.min { $0.close < $1.close }!.close
                maxVolume = candles.max { $0.volume < $1.volume }!.volume
                minVolume = candles.min { $0.volume < $1.volume }!.volume
                layoutLayers()
                scaleChartPointsToViewSize()
                renderLayers()
            } else {
                feebackLabel.opacity = 1
            }
        }
    }
    
    func strings(from component:Calendar.Component) -> [String]? {
        switch component {
        case .month: return Calendar.current.shortMonthSymbols
        case .weekday: return Calendar.current.shortWeekdaySymbols
        default: return nil
        }
    }
    
    
    //MARK: - Private Methods
    
    private func makeXAxisData() -> [XLabelViewData] {
        var data = [XLabelViewData]()
        
        guard candles.count > 0 else { return data }
        
        let ranges = makeXDataRanges()
        
        for i in ranges.enumerated() {
            let range = i.element.range
            let comp = timeInterval.calComponent()
            let c = Calendar.current.component(comp, from: i.element.candle.date)
            var value = "\(c)"
            if let s = strings(from: comp) {
                value = s[c-1]
            }
            data.append(XLabelViewData(range:range, value: value, alignment: .left))
        }
        return data
    }
    
    private func makeXDataRanges() -> [(range: Range<Int>, candle: CandleConformable)] {
        var ranges = [(Range<Int>, CandleConformable)]()
        
        var lastStartIndex = 0
        var lastCandle = candles.first!
        
        for i in candles.enumerated() {
            let s = timeInterval.subPattern()
            let lastComp = Calendar.current.component(s.comp, from: lastCandle.date)
            let currentComp = Calendar.current.component(s.comp, from: i.element.date)
            
            if currentComp >= lastComp + s.change || lastComp > currentComp {
                ranges.append((lastStartIndex..<i.offset, candles[lastStartIndex]))
                lastStartIndex = i.offset
                lastCandle = i.element
            }
        }
        ranges.append((lastStartIndex..<candles.count, candles[lastStartIndex]))
        return ranges
    }
    
    private func scaleChartPointsToViewSize() {
        points = []
        let closeDiff = maxClose - minClose
        let yscale = graphLayer.frame.height / CGFloat(closeDiff)
        let xScale = graphLayer.frame.width / CGFloat(candles.count - 1)
        
        for (index, candle) in candles.enumerated() {
            points.append(CGPoint(
                x: CGFloat(index) * xScale,
                y: graphLayer.frame.height - CGFloat(candle.close - minClose) * yscale
            ))
        }
    }
    
    private func makeLabel(string: String) -> CATextLayer {
        let label = CATextLayer()
        label.string = string
        label.contentsScale = 2.0
        label.fontSize = 14
        label.frame = CGRect(x: 0, y: 0, width: 60, height: labelHeight)
        label.foregroundColor = isFullscreen ? .white : .color(r:0.44, g:0.46, b:0.45, a:1.00)
        return label
    }
    
    private func makePath(from points: [CGPoint]) -> CGMutablePath {
        let path = CGMutablePath()
        for (index, point) in points.enumerated() {
            if index == 0 {
                path.move(to: point)
            }
            path.addLine(to: point)
        }
        return path
    }
    
    private func renderGraph(color: CGColor, range: CountableClosedRange<Int>, isSelected: Bool = false) {
        let graph = isSelected ? graphLayerSelection : graphLayer
        
        let localPoints = Array(points[range])
        let path = makePath(from: localPoints)
        
        let line = CAShapeLayer()
        line.frame = graph.frame
        line.strokeColor = color.copy(alpha: 1)
        line.lineWidth = isSelected ? 2 : 1
        line.lineJoin = .round
        line.path = path
        line.fillColor = nil
        
        let fill = CAGradientLayer()
        fill.frame = CGRect(x: graph.frame.minX, y: graph.frame.minY, width: graph.frame.width, height: graph.frame.height + 16)
        fill.colors = [color.copy(alpha: 0.2)!, color.copy(alpha: 0.7)!]
        
        let layerMask = CAShapeLayer()
        if let firstPoint = localPoints.first, let lastPoint = localPoints.last {
            path.addLine(to: CGPoint(x: lastPoint.x, y: fill.frame.height))
            path.addLine(to: CGPoint(x: firstPoint.x, y: fill.frame.height))
        }
        layerMask.path = path
        fill.mask = layerMask
        
        graph.sublayers = []
        graph.addSublayer(fill)
        graph.addSublayer(line)
    }
    
    private func renderVolumeBars(with color: CGColor = .white, range: CountableClosedRange<Int>, isSelected: Bool = false) {
        let layer = isSelected ? volumeLayerSelection : volumeLayer
        let width:CGFloat = 2
        let xScale = (volumeLayer.frame.width - width) / CGFloat(candles.count - 1)
        let volumeDiff = maxVolume - minVolume
        
        // Prevents dividing by zero which causes CALayerInvalidGeometry
        if volumeDiff == 0 { return }
        
        let volumeScale = (volumeLayer.frame.height - 3) / CGFloat(volumeDiff)
        let barsPath = CGMutablePath()
        
        for index in range {
            let candle = candles[index]
            let index = CGFloat(index)
            let height = CGFloat(candle.volume - minVolume) * volumeScale
            let x = index * xScale
            barsPath.move(to: CGPoint(x: x, y: volumeLayer.frame.height))
            barsPath.addLine(to: CGPoint(x: x, y: volumeLayer.frame.height - height))
        }
        
        layer.lineWidth = 2
        layer.path = barsPath
        layer.strokeColor = color
    }
    
    private func renderAxisY() {
        let line = CAShapeLayer()
        line.frame = CGRect(
            x: axisYLayer.frame.width - self.frame.width,
            y: 0,
            width: self.frame.width,
            height: axisYLayer.frame.height
        )
        
        let path = CGMutablePath()
        
        let changeClose = maxClose - minClose
        let numberOfLabels = isFullscreen ? 5 : 2
        
        let segPixelChange = (axisYLayer.frame.height - labelHeight) / CGFloat(numberOfLabels - 1)
        let valueChangePerPixel:CGFloat = CGFloat(changeClose) / (axisYLayer.frame.height - labelHeight)
        let segValueChange = segPixelChange * valueChangePerPixel
        
        for index in 0..<numberOfLabels {
            let v = CGFloat(maxClose) - (CGFloat(index) * segValueChange)
            let y = CGFloat(index) * segPixelChange
            
            let label = makeLabel(string: Double(v).format(as: .currency))
            label.alignmentMode = yAxisLabel.alignment
            label.frame.origin.x = 0
            label.frame.origin.y = y
            label.frame.size.width = axisYLayer.frame.width
            axisYLayer.addSublayer(label)

            path.move(to: CGPoint(x: 0, y: y ))
            path.addLine(to: CGPoint(x:self.frame.width, y: y ))
        }
        
        if isFullscreen {
            line.lineWidth = 1
            line.path = path
            line.lineDashPattern = [1,2]
            line.lineCap = .round
            line.strokeColor = CGColor.white.copy(alpha:0.2)
            axisYLayer.addSublayer(line)
        }
    }
    
    private func renderAxisX() {
        let step = axisXLayer.frame.width / CGFloat(candles.count - 1)
        
        //let line = CAShapeLayer()
        //line.frame = frame
        
        let path = CGMutablePath()
        
        for data in makeXAxisData() {
            let x = CGFloat(data.range.lowerBound) * step
            let label = makeLabel(string: data.value)
            let width = (CGFloat(data.range.count) * step) - 1
            label.frame.size.width = width
            label.alignmentMode = data.alignment
            label.frame.origin.y = axisXLayer.frame.height - label.frame.height
            label.frame.origin.x = x
            axisXLayer.addSublayer(label)
            path.move(to: CGPoint(x: x + width + 1, y: 0 ))
            path.addLine(to: CGPoint(x: x + width + 1, y: axisXLayer.frame.height))
        }
        
        axisXLayer.lineWidth = 1
        axisXLayer.path = path
        axisXLayer.lineCap = .round
        axisXLayer.strokeColor = CGColor.white.copy(alpha: 0.15)
        //layer.addSublayer(line)
    }
    
    private func makeBaseLine(y: CGFloat) -> CALayer {
        let baseLine = CALayer()
        baseLine.frame = CGRect(x: 0, y: y, width: frame.width, height: 0.5)
        baseLine.backgroundColor = CGColor.white.copy(alpha: isFullscreen ? 1 : 0.6)!
        return baseLine
    }
    
    private func layoutLayers() {
        
        // Layer Layout
        // |--------------------|---|
        // |        Graph       |   |
        // |--------------------| Y |
        // |          X         |   |
        // |--------------------|---|
        // |        Volume      |   |
        // |--------------------|---|
        
        let volumeHeight: CGFloat = 20
        let yAxisWidth: CGFloat = 42
        
        axisYLayer.backgroundColor = .color(r: 1, g: 0.2, b: 0.4, a: 0.7)
        axisYLayer.frame = CGRect(
            x: bounds.width - yAxisWidth,
            y: 0,
            width: yAxisWidth,
            height: isFullscreen ? frame.height - volumeHeight : frame.height - volumeHeight - labelHeight
        )
        
        axisXLayer.backgroundColor = .color(r: 0.2, g: 0.5, b: 0.4, a: 0.5)
        axisXLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: frame.width - yAxisWidth,
            height: isFullscreen ? frame.height - volumeHeight : frame.height - volumeHeight - labelHeight
        )
        
        graphLayer.backgroundColor = .color(r: 0.1, g: 0.2, b: 0.8, a: 0.5)
        graphLayer.borderWidth = 2
        graphLayer.borderColor = .color(r: 0, g: 0, b: 0, a: 1)
        graphLayer.frame = CGRect(
            x: bounds.minX,
            y: 0,
            width: isFullscreen ? bounds.width - yAxisWidth: bounds.width,
            height: bounds.height - (labelHeight + volumeHeight + labelHeight)
        )
        
        graphLayerSelection.frame = graphLayer.frame
        
        volumeLayer.backgroundColor = .color(r: 1, g: 0, b: 0.2, a: 0.5)
        volumeLayer.frame = CGRect(
            x: 0,
            y: bounds.height - volumeHeight,
            width: graphLayer.frame.width,
            height: volumeHeight
        )
    }
    
    private func renderLayers() {
        if candles.count > 3 {
            renderAxisY()
            renderAxisX()
            renderGraph(color: .white, range: 0...candles.count - 1)
            renderVolumeBars(with: .white, range: 0...candles.count - 1)
        }
    }
    
//    private func makeLayers(){
//        if candles.count == 0 { return }
//
//        if let s = sublayers {
//            s.forEach{ $0.removeFromSuperlayer() }
//        }
//
//         calculate all the different layer frames
//        let volumeHeight: CGFloat = 20
//        let yAxisTop: CGFloat = isFullscreen ? labelHeight : 0
//        let yAxisHeight: CGFloat = isFullscreen ? frame.height - volumeHeight : frame.height - volumeHeight - labelHeight
//        let yAxisWidth: CGFloat = 42
//
//        calculatePoints()
//        let volumeBarsRect = CGRect(x: 0, y: bounds.height - volumeHeight, width: graphRect.width, height: volumeHeight)
//        let yAxisRect = CGRect(x: bounds.width - yAxisWidth, y: yAxisTop, width: yAxisWidth, height: yAxisHeight)
//        let xAxisRect = CGRect(x: 0, y: 0, width: graphRect.width, height: bounds.height - volumeHeight)
//
//        let colors = ( CGColor.white.copy(alpha: 0.2)!,  CGColor.white.copy(alpha: 0.02)!)
//    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        layoutLayers()
        scaleChartPointsToViewSize()
        renderLayers()
    }
    
    private func makeCursor(forIndex index: Int, withColor color: CGColor) -> CALayer {
        if points.count < index { return CALayer() }
        let point = points[index]
        
        let line = CALayer()
        line.frame = CGRect(x: point.x, y: 0, width: 1, height: graphLayer.frame.height + (labelHeight * 2))
        line.backgroundColor = color
        let dot = CALayer()
        dot.cornerRadius = 5
        dot.frame = CGRect(x: -4.5, y: (point.y + labelHeight) - 5, width: 10, height: 10)
        dot.backgroundColor = color
        line.addSublayer(dot)
        return line
    }
    
    
    //MARK: - Public Methods
    
    func index(closestTo point: CGPoint) -> Int {
        let step = (graphLayer.frame.width + 15) / CGFloat(candles.count)
        let absolutePoint = point //convert(point, from: nil)
        
        var index = Int(ceil(absolutePoint.x / step))
        let minIndex = 0
        let maxIndex = points.count - 1
        
        if index < minIndex { index = minIndex }
        if index > maxIndex { index = maxIndex }
        
        return index
    }
    
    func selectData(inRange range: CountableClosedRange<Int>, withColor color: CGColor) {
        if range != prevRange {
            prevRange = range
        }
        
        graphLayerSelection.sublayers?.removeAll()
        
        if range.count > 1 {
            //let colors = (color.copy(alpha:0.2)!, color.copy(alpha:0.7)!)
            renderGraph(color: color, range: range, isSelected: true)
            //selectedGraphLayer.addSublayer(renderGraph(colors: colors, range: range, lineWidth: 2))
            graphLayerSelection.addSublayer(makeCursor(forIndex: range.lowerBound, withColor: color))
        }
        graphLayerSelection.addSublayer(makeCursor(forIndex: range.upperBound, withColor: color))
        renderVolumeBars(with: color, range: range, isSelected: true)
    }
    
    func resetSelection() {
        graphLayerSelection.sublayers?.removeAll()
    }
}

extension CGColor {
    static let white = color(r: 1, g: 1, b: 1, a: 1)
    
    static func color(_ space:CGColorSpace = .sRGBSpace, r: CGFloat, g:CGFloat, b:CGFloat, a:CGFloat) -> CGColor {
        var p:[CGFloat] = [r,g,b,a]
        return CGColor(colorSpace: space, components: &p)!
    }
}

extension CGColorSpace {
    static let p3Space = CGColorSpace(name: CGColorSpace.displayP3)!
    static let sRGBSpace = CGColorSpace(name: CGColorSpace.sRGB)!
}
