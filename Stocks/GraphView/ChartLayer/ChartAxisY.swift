import QuartzCore

class ChartAxisY: CAShapeLayer {
    
    var isFullscreen: Bool = false
    var labelHeight: CGFloat = 15
    
    var closes: [Double] = [] {
        didSet { setNeedsDisplay() }
    }
    
    var minClose: Double { closes.min { $0 < $1 } ?? 0 }
    var maxClose: Double { closes.max { $0 < $1 } ?? 0 }
    
    private func makeLabel(string: String) -> CATextLayer {
        let label = CATextLayer()
        label.string = string
        label.contentsScale = 2.0
        label.fontSize = 14
        label.frame = CGRect(x: 0, y: 0, width: 60, height: labelHeight)
        label.foregroundColor = isFullscreen ? .white : CGColor.white.copy(alpha: 0.7)
        return label
    }
    
    override func display() {
        sublayers = []
        
        let line = CAShapeLayer()
        line.frame = bounds
        
        let _path = CGMutablePath()
        
        let changeClose = maxClose - minClose
        let numberOfLabels = isFullscreen ? 5 : 2
        let segPixelChange = (bounds.height - labelHeight) / CGFloat(numberOfLabels - 1)
        let valueChangePerPixel:CGFloat = CGFloat(changeClose) / (bounds.height - labelHeight)
        let segValueChange = segPixelChange * valueChangePerPixel
        
        for index in 0..<numberOfLabels {
            let v = CGFloat(maxClose) - (CGFloat(index) * segValueChange)
            let y = CGFloat(index) * segPixelChange
            
            let label = makeLabel(string: Double(v).format(as: .currency))
            label.alignmentMode = .right
            label.frame.origin.x = 0
            label.frame.origin.y = y
            label.frame.size.width = bounds.width
            addSublayer(label)

            _path.move(to: CGPoint(x: 0, y: y ))
            _path.addLine(to: CGPoint(x: line.frame.width, y: y ))
        }
        
        if isFullscreen {
            line.lineWidth = 1
            line.path = _path
            line.lineDashPattern = [1, 2]
            line.lineCap = .round
            line.strokeColor = CGColor.white.copy(alpha:0.2)
            addSublayer(line)
        }
    }
}
