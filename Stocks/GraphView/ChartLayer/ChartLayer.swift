import QuartzCore

class ChartLayer: CALayer {
    
    let MIN_CANDLE_COUNT: Int = 3
    
    var timeInterval: TimeInterval {
        get { axisXLayer.timeInterval }
        set { axisXLayer.timeInterval = newValue }
    }
    
    var isFullscreen: Bool = false {
        didSet {
            axisYLayer.isFullscreen = isFullscreen
            axisXLayer.isFullscreen = isFullscreen
        }
    }
    
    var selectionTint: CGColor = .white {
        didSet {
            graphLayerSelection.tintColor = selectionTint
            volumeLayerSelection.tintColor = selectionTint
            graphLayerSelection.setNeedsDisplay()
            volumeLayerSelection.setNeedsDisplay()
        }
    }
    
    var candles: [CandleConformable] = [] {
        didSet {
            if candles.count > MIN_CANDLE_COUNT {
                typealias SplitData = (dates: [Date], closes: [Double], volumes: [Int])
                
                let splitData: SplitData = candles.reduce(into: (dates: [], closes: [], volumes: []), { res, this in
                    res.dates.append(this.date)
                    res.closes.append(this.close)
                    res.volumes.append(this.volume)
                })
                
                graphLayer.closes = splitData.closes
                graphLayerSelection.closes = splitData.closes
                
                volumeLayer.volumes = splitData.volumes
                volumeLayerSelection.volumes = splitData.volumes
                
                axisXLayer.dates = splitData.dates
                axisYLayer.closes = splitData.closes
            }
        }
    }
    
    
    // MARK: - Layers
    private let cursorLayer = CALayer()
    private let axisYLayer = ChartAxisY()
    private let axisXLayer = ChartAxisX()
    private let graphLayer = ChartGraphLayer()
    private let volumeLayer = ChartVolumeBars()
    private let graphLayerSelection = ChartGraphLayer()
    private let volumeLayerSelection = ChartVolumeBars()
    
    override init() {
        super.init()
        addSublayer(graphLayer)
        addSublayer(volumeLayer)
        addSublayer(makeBaseLine(y: 0))
        addSublayer(axisYLayer)
        addSublayer(axisXLayer)
        addSublayer(graphLayerSelection)
        addSublayer(volumeLayerSelection)
        addSublayer(cursorLayer)
        
        graphLayer.needsDisplayOnBoundsChange = true
        graphLayerSelection.lineWidth = 3
        graphLayerSelection.tintStrength = 2
        graphLayerSelection.mask = CALayer()
        graphLayerSelection.mask?.backgroundColor = .white
        volumeLayerSelection.mask = CALayer()
        volumeLayerSelection.mask?.backgroundColor = .white
        resetSelection()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        layoutLayers()
    }
    
    
    //MARK: - Private Methods
    
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
        let labelHeight: CGFloat = 16
        
        graphLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: isFullscreen ? bounds.width - yAxisWidth: bounds.width,
            height: bounds.height - (labelHeight + volumeHeight)
        )
        
        axisYLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: isFullscreen ? bounds.height - volumeHeight : bounds.height - volumeHeight - labelHeight
        )
        
        axisXLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width - yAxisWidth,
            height: bounds.height - volumeHeight
        )

        volumeLayer.frame = CGRect(
            x: 0,
            y: bounds.height - volumeHeight,
            width: graphLayer.bounds.width,
            height: volumeHeight
        )
        
        graphLayerSelection.mask?.frame = bounds
        graphLayerSelection.frame = graphLayer.frame
        volumeLayerSelection.mask?.frame = bounds
        volumeLayerSelection.frame = volumeLayer.frame
    }
    
    private func makeBaseLine(y: CGFloat) -> CALayer {
        let baseLine = CALayer()
        baseLine.frame = CGRect(x: 0, y: y, width: frame.width, height: 0.5)
        baseLine.backgroundColor = CGColor.white.copy(alpha: isFullscreen ? 1 : 0.6)!
        return baseLine
    }
    
    private func makeCursor(forIndex index: Int) -> CALayer {
        if graphLayer.pathPoints.count < index { return CALayer() }
        let point = graphLayer.pathPoints[index]
        
        let line = CALayer()
        line.frame = CGRect(x: point.x, y: 0, width: 1, height: graphLayer.frame.height)
        line.backgroundColor = selectionTint
        let dot = CALayer()
        dot.cornerRadius = 5
        dot.frame = CGRect(x: -4.5, y: point.y - 5, width: 10, height: 10)
        dot.backgroundColor = selectionTint
        line.addSublayer(dot)
        return line
    }
    
    
    //MARK: - Public Methods
    
    func candleIndex(closestTo point: CGPoint) -> Int {
        let step = (graphLayer.frame.width + 15) / CGFloat(candles.count)
        let absolutePoint = point
        
        var index = Int(ceil(absolutePoint.x / step))
        let minIndex = 0
        let maxIndex = graphLayer.pathPoints.count - 1
        
        if index < minIndex { index = minIndex }
        if index > maxIndex { index = maxIndex }
        
        return index
    }
    
    func selectData(betweenPoints points: [CGPoint]) {
        guard let first = points.first, let last = points.last else { return }
        
        let indexS = candleIndex(closestTo: first)
        let indexE = candleIndex(closestTo: last)
        
        let x = graphLayer.pathPoints[indexS].x
        let x2 = graphLayer.pathPoints[indexE].x
        
        CATransaction.setAnimationDuration(0)
        volumeLayerSelection.mask?.frame.origin.x = x
        volumeLayerSelection.mask?.frame.size.width = abs(x2 - x)
        graphLayerSelection.mask?.frame = volumeLayerSelection.mask?.frame ?? .zero
        CATransaction.commit()
        
        cursorLayer.sublayers = []
        cursorLayer.addSublayer(makeCursor(forIndex: indexS))
        
        if indexE > indexS {
            cursorLayer.addSublayer(makeCursor(forIndex: indexE))
        }
        
        graphLayerSelection.isHidden = false
        volumeLayerSelection.isHidden = false
    }
    
    func resetSelection() {
        cursorLayer.sublayers = []
        graphLayerSelection.isHidden = true
        volumeLayerSelection.isHidden = true
    }
}

extension CGColor {
    static let white = color(r: 1, g: 1, b: 1, a: 1)
    
    static func color(_ space: CGColorSpace = .sRGBSpace, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> CGColor {
        var p: [CGFloat] = [r,g,b,a]
        return CGColor(colorSpace: space, components: &p)!
    }
}

extension CGColorSpace {
    static let p3Space = CGColorSpace(name: CGColorSpace.displayP3)!
    static let sRGBSpace = CGColorSpace(name: CGColorSpace.sRGB)!
}
