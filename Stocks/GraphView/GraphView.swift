import UIKit

protocol GraphViewDelegate {
    func graphView(_ graphView: GraphView, didStartSelecting candles: [CandleConformable])
    func graphView(_ graphView: GraphView, didFinishSelecting candles: [CandleConformable])
}

protocol CandleConformable {
    var open: Double { get }
    var close: Double { get }
    var volume: Int { get }
    var date: Date { get }
}

class GraphView: UIView {
    
    override class var layerClass: AnyClass { ChartLayer.self }
    
    private var previousSelectedRange: ClosedRange<Int> = 0...0
    private var hapticFeedback = UISelectionFeedbackGenerator()
    private var graphLayer: ChartLayer { layer as! ChartLayer }
    
    var delegate: GraphViewDelegate?
    
    var timeInterval: TimeInterval {
        get { graphLayer.timeInterval }
        set { graphLayer.timeInterval = newValue }
    }
    
    var isFullscreen: Bool {
        get { graphLayer.isFullscreen }
        set { graphLayer.isFullscreen = newValue }
    }

    var candles: [CandleConformable] {
        get { graphLayer.candles }
        set { graphLayer.candles = newValue }
    }
    
    func index(closestTo point: CGPoint) -> Int {
        graphLayer.candleIndex(closestTo: point)
    }
    
    func selectData(betweenPoints points: [CGPoint]) {
        hapticFeedback.prepare()
        let s = graphLayer.candleIndex(closestTo: points.first!)
        let e = graphLayer.candleIndex(closestTo: points.last!)
        let range = s...e
        if range != previousSelectedRange {
            previousSelectedRange = range
            hapticFeedback.selectionChanged()
        }
        
        graphLayer.selectData(betweenPoints: points)
    }
    
    func resetSelection(){
        graphLayer.resetSelection()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addGestureRecognizer(GraphGestureRecognizer(target: self, action: #selector(customGesture)))
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        graphLayer.selectionTint = tintColor.cgColor
    }
    
    
    //MARK: - Gesture Handler
    
    @objc func customGesture(rec: GraphGestureRecognizer) {
        if candles.count == 0 { return }
        
        if rec.state == .began || rec.state == .changed {
            let points = rec.activeTouches.map { $0.location(in: self) }
            
            guard let minPoint = points.min(by: { a, b in a.x < b.x }) else {
                resetSelection()
                return
            }
            
            let same = points.max(by: { a, b in a.x < b.x }) == minPoint
            let maxPoint = !same ? points.max(by: { a, b in a.x < b.x }) : nil
            
            let start = index(closestTo: minPoint)
            
            if let m = maxPoint {
                let end = index(closestTo: m)
                delegate?.graphView(self, didStartSelecting: Array(candles[start...end]))
                selectData(betweenPoints: [minPoint, m])
            } else {
                delegate?.graphView(self, didStartSelecting: [candles[start]])
                selectData(betweenPoints: [minPoint, minPoint])
            }
            
        } else {
            delegate?.graphView(self, didFinishSelecting: [])
            resetSelection()
        }
    }
}
