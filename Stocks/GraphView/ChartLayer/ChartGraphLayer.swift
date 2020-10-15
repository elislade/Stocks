import QuartzCore

class ChartGraphLayer: CALayer {
    
    var tintColor: CGColor = .white
    var lineWidth: CGFloat = 1
    var tintStrength: CGFloat = 1
    
    var closes: [Double] = [] {
        didSet { setNeedsDisplay() }
    }
    
    var minClose: Double { closes.min { $0 < $1 } ?? 0 }
    var maxClose: Double { closes.max { $0 < $1 } ?? 0 }
    var closeDiff: Double { maxClose - minClose }
    var yScale: CGFloat { bounds.height / CGFloat(closeDiff) }
    var xScale: CGFloat { bounds.width / CGFloat(closes.count - 1) }
    
    private(set) var pathPoints: [CGPoint] = []
    
    private func cachePathPoints() {
        pathPoints = []
        for (index, close) in closes.enumerated() {
            pathPoints.append(CGPoint(
                x: CGFloat(index) * xScale,
                y: (bounds.height - CGFloat(close - minClose) * yScale)
            ))
        }
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
    
    override func display() {
        cachePathPoints()
        let path = makePath(from: pathPoints)
        
        let line = CAShapeLayer()
        line.frame = bounds
        line.strokeColor = tintColor.copy(alpha: 1)
        line.lineWidth = lineWidth
        line.lineJoin = .round
        line.path = path
        line.fillColor = nil
        
        let fill = CAGradientLayer()
        fill.frame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height)
        fill.colors = [tintColor.copy(alpha: 0.05 * tintStrength)!, tintColor.copy(alpha: 0.4 * tintStrength)!]
        
        let layerMask = CAShapeLayer()
        if let firstPoint = pathPoints.first, let lastPoint = pathPoints.last {
            path.addLine(to: CGPoint(x: lastPoint.x, y: fill.frame.height))
            path.addLine(to: CGPoint(x: firstPoint.x, y: fill.frame.height))
        }
        
        layerMask.path = path
        fill.mask = layerMask
        
        sublayers = []
        addSublayer(fill)
        addSublayer(line)
    }
}
