import UIKit

//protocol GraphDelegate {
//    func selectedCandles(candles:[Candle])
//}

class GraphViewController: ViewController {
    
    let intervals: [TimeInterval] = [.oneDay, .oneMonth, .threeMonth, .sixMonth, .oneYear, .twoYear]
    
    
    //MARK: - Interface Builder
    
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var graphView: GraphView!
    
    
    //MARK: - Header Variables
    
    var isFullscreen: Bool {
        get { graphView.isFullscreen }
        set { graphView.isFullscreen = newValue }
    }

    lazy var selectedLabel: UILabel = {
        let t = UILabel()
        t.textAlignment = .center
        t.textColor = .white
        t.font = UIFont.systemFont(ofSize: 18)
        t.layer.cornerRadius = 8
        t.layer.masksToBounds = true
        return t
    }()
    
    lazy var segmentedControl: UISegmentedControl = {
        let s = UISegmentedControl(items: intervals.map{ $0.description.uppercased() })
        s.selectedSegmentIndex = 2
        s.addTarget(self, action: #selector(checkDataCache), for: .valueChanged)
        return s
    }()
    
    var quote: IEXQuote? {
        didSet {
            if quote != oldValue && quote != nil {
                fetchData()
            }
        }
    }
    
    var dataCache: [String: [IEXCandle]] = [:]
    
    
    //MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        graphView.delegate = self
        mainStack.insertArrangedSubview(segmentedControl, at: 0)
        mainStack.insertArrangedSubview(selectedLabel, at: 1)
        selectedLabel.backgroundColor = UIColor(displayP3Red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        selectedLabel.heightAnchor.constraint(equalToConstant: 31).isActive = true
        selectedLabel.isHidden = true
    }
    
    @objc func checkDataCache() {
        let interval = intervals[segmentedControl.selectedSegmentIndex]
        
        if interval != .oneDay {
            if let cacheValue = dataCache["\(interval)"] {
                if cacheValue.count > 0 {
                    self.graphView.candles = cacheValue
                    self.graphView.timeInterval = interval
                } else {
                    fetchData()
                }
            } else {
                fetchData()
            }
        } else {
            fetchData()
        }
    }
    
    func fetchData() {
        guard let q = quote else { return }
        let interval = intervals[segmentedControl.selectedSegmentIndex]
        
        StocksAPI.shared.getChart(for: q.symbol, range: interval) { candles, error in
            guard let candles = candles else { return }

            DispatchQueue.main.async {
                self.graphView.candles = candles
                self.graphView.timeInterval = interval
                
                if interval != .oneDay {
                    self.dataCache["\(interval)"] = candles
                }
            }
        }
    }
}


extension GraphViewController: GraphViewDelegate {
    func graphView(_ graphView: GraphView, didStartSelecting candles: [CandleConformable]) {
        guard let first = candles.first, let last = candles.last else { return }

        segmentedControl.isHidden = true
        selectedLabel.isHidden = false
        
        let minValue = first.close
        
        if candles.count == 1 {
            // single selecteion
            
            let d = NumberFormatter.localizedString(from: NSNumber(value: minValue), number: .decimal)
            selectedLabel.text = d
            selectedLabel.textColor = view.tintColor
            graphView.tintColor = view.tintColor
        } else if candles.count > 1 {
            // candle spread
            
            let maxValue = last.close
            let change = (maxValue - minValue)
            let d = NumberFormatter.localizedString(from: NSNumber(value: maxValue - minValue), number: .decimal)
            let ps = NumberFormatter.localizedString(from: NSNumber(value: change / minValue), number: .percent)
            
            graphView.tintColor = maxValue < minValue ? .stockRed : .stockGreen
            selectedLabel.textColor = maxValue < minValue ? .stockRed : .stockGreen
            selectedLabel.text = "\(d) (\(ps))"
        }
    }
    
    func graphView(_ graphView: GraphView, didFinishSelecting candles: [CandleConformable]) {
        segmentedControl.isHidden = false
        selectedLabel.isHidden = true
    }
}
