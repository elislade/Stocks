import UIKit

protocol QuoteTableCellDelegate {
    func toggleQuoteChangeType()
}

class QuoteTableViewCell: UITableViewCell {
    
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var stockLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var changeButton: UIButton!
    
    
    //MARK: - IBActions
    
    @IBAction func changeButtonTapped(_ sender: Any) {
        // toggle > %, $, MKT Cap
        delegate?.toggleQuoteChangeType()
    }
    
    
    //MARK: - Header Variables
    
    var delegate: QuoteTableCellDelegate?
    
    var quote: IEXQuote? {
        didSet {
            guard let q = quote else { return }
            stockLabel.text = q.symbol
            priceLabel.text = "\(q.latestPrice)"
            changeButton.setTitle("\(q.change)", for: .normal)
        }
    }
    
    var changeToggleState: QuoteChangeType = .percentage {
        didSet {
            guard let q = quote else { return }
            
            var title = "––"
            
            if changeToggleState == .mrkCap {
                title = "\(q.marketCap.formatPoints())"
            } else if changeToggleState == .percentage {
                title = "\((q.changePercent * 100).roundDecimal(to: 100))%"
            } else {
                title = "\(q.change.roundDecimal(to: 100))"
            }
            
            changeButton.backgroundColor = q.change < 0.00 ? .stockRed : .stockGreen
            changeButton.setTitle(title, for: .normal)
        }
    }
    
    
    //MARK: - Override Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        changeButton.layer.cornerRadius = 4.0
        changeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        stockLabel.textColor = UITheme.main.primaryForegroundColor
        priceLabel.textColor = UITheme.main.primaryForegroundColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        let gray = UITheme.main.secondaryBackgroundColor
        backgroundColor = selected ? gray : .clear
    }
}
