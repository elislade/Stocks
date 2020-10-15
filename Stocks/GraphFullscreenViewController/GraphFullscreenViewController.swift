import UIKit

class GraphFullscreenViewController: ViewController {
    
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var valueChangeLabel: UILabel!
    @IBOutlet weak var percentChangeLabel: UILabel!
    @IBOutlet weak var graphContainer: UIView!
    
    
    //MARK: - Header Variables
    
    var quote: IEXQuote?
    lazy var graphController: GraphViewController = {
        GraphViewController()
    }()
    
    let timeLabel: UILabel = {
        let v = UILabel(frame: CGRect(x:0, y:0, width: 200, height:34))
        v.backgroundColor = UITheme.main.primaryBackgroundColor
        v.textColor = UITheme.main.secondaryForegroundColor
        v.font = UIFont.systemFont(ofSize: 21)
        v.textAlignment = .center
        return v
    }()
    
    
    //MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        symbolLabel.textColor = UITheme.main.primaryForegroundColor
        nameLabel.textColor = UITheme.main.secondaryForegroundColor
        priceLabel.textColor = UITheme.main.primaryForegroundColor
        
        addChild(graphController)
        graphContainer.addSubview(graphController.view)
        graphController.didMove(toParent: self)
        graphController.isFullscreen = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let q = quote {
            graphController.quote = q
            
            symbolLabel.text = q.symbol
            nameLabel.text = q.companyName
            priceLabel.text = "\(q.latestPrice)"
            let txtColor: UIColor = q.change < 0 ? .stockRed : .stockGreen
            valueChangeLabel.text = "\(q.change.roundDecimal(to: 1000))"
            valueChangeLabel.textColor = txtColor
            percentChangeLabel.text = "\((q.changePercent * 100).roundDecimal(to: 1000))%"
            percentChangeLabel.textColor = txtColor
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        graphController.view.frame = graphContainer.bounds
    }
    
}
