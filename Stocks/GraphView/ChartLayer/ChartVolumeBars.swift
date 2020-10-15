import QuartzCore

class ChartVolumeBars: CAShapeLayer {
    
    var volumes: [Int] = [] {
        didSet { setNeedsDisplay() }
    }
    
    var tintColor: CGColor = .white
    var barWidth: CGFloat = 2
    
    var minVolume: Int { volumes.min { $0 < $1 } ?? 0 }
    var maxVolume: Int { volumes.max { $0 < $1 } ?? 0 }
    var volumeDiff: Int { maxVolume - minVolume }
    var xScale: CGFloat { (bounds.width - barWidth) / CGFloat(volumes.count - 1) }
    
    override func display() {
        if volumes.count == 0 { return }
        let range:ClosedRange<Int> = 0...volumes.count - 1
        // Prevents dividing by zero which causes CALayerInvalidGeometry
        if volumeDiff == 0 { return }
        
        let volumeScale = (bounds.height - 3) / CGFloat(volumeDiff)
        let _path = CGMutablePath()
        
        for index in range {
            let volume = volumes[index]
            let index = CGFloat(index)
            let height = CGFloat(volume - minVolume) * volumeScale
            let x = index * xScale
            _path.move(to: CGPoint(x: x + (barWidth / 2), y: bounds.height))
            _path.addLine(to: CGPoint(x: x + (barWidth / 2), y: bounds.height - height))
        }
        
        lineWidth = 2
        path = _path
        strokeColor = tintColor
    }
}
