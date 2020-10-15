import UIKit

class SymbolTableViewCell: UITableViewCell {
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var marketLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        symbolLabel.textColor = UITheme.main.primaryForegroundColor
        marketLabel.textColor = UITheme.main.secondaryForegroundColor
        nameLabel.textColor = UITheme.main.primaryForegroundColor
        backgroundColor = UITheme.main.primaryBackgroundColor
    }
}
