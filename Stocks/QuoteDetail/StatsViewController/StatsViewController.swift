import UIKit

class StatsViewController: UIViewController {
    
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var openLabel: UILabel!
    @IBOutlet weak var highLabel: UILabel!
    @IBOutlet weak var lowLabel: UILabel!
    @IBOutlet weak var volLabel: UILabel!
    @IBOutlet weak var peLabel: UILabel!
    @IBOutlet weak var markCapLabel: UILabel!
    @IBOutlet weak var high52Label: UILabel!
    @IBOutlet weak var low52Label: UILabel!
    @IBOutlet weak var avgVolLabel: UILabel!
    @IBOutlet weak var yeildLabel: UILabel!
    
    
    //MARK: - Header Variables
    
    var quote: IEXQuote? {
        didSet {
            guard let q = quote else { return }
            
            titleLabel.text = q.companyName
                
            if let open = q.open {
                openLabel.text = "\(open)"
            }
            if let high = q.high {
                highLabel.text = "\(high)"
            }
            if let low = q.low {
                lowLabel.text = "\(low)"
            }
            if let vol = q.latestVolume {
                volLabel.text = "\(vol)"
            }
            peLabel.text = "\(q.peRatio)"
            markCapLabel.text = "\(q.marketCap.formatPoints())"
            high52Label.text = "\(q.week52High)"
            low52Label.text = "\(q.week52Low)"
            avgVolLabel.text = "--"
            yeildLabel.text = "--"
        }
    }
    
    
    //MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let primary = UITheme.main.primaryForegroundColor
        let secondary = UITheme.main.secondaryForegroundColor
        
        for label in view.children(ofType: UILabel.self) {
            label.textColor = label.tag == 2 ? secondary : primary
        }
    }
}
