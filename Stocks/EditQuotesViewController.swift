import UIKit

protocol EditQuotesDelegate {
    func quoteChangeTypeDidChange(_ type: QuoteChangeType)
    func quotesDidChange(_ quotes: [IEXQuote])
}

class EditQuotesViewController: ViewController {

    
    //MARK: - InterfaceBuilder
    
    @IBOutlet weak var segmentedStockChangeControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        if let type = QuoteChangeType(rawValue: sender.selectedSegmentIndex) {
            delegate?.quoteChangeTypeDidChange(type)
        }
    }
    
    
    //MARK: - Header Variables
    
    var data: [IEXQuote] = []
    var delegate: EditQuotesDelegate? = nil
    var changeState: QuoteChangeType = .percentage
    
    
    //MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "SymbolTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "ResultCell")
        tableView.setEditing(true, animated: false)
        tableView.separatorColor = UITheme.main.secondaryBackgroundColor
        segmentedStockChangeControl.selectedSegmentIndex = changeState.rawValue
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Add" {
            if let vc = (segue.destination as? UINavigationController)?.topViewController as? SearchTableViewController {
                vc.delegate = self
            }
        }
    }
}


//MARK: - AddStockable Delegate

extension EditQuotesViewController: SearchViewControllerDelegate {
    func didSelectQuote(_ quote: IEXQuote) {
        data.insert(quote, at: 0)
        tableView.reloadData()
        delegate?.quotesDidChange(data)
    }
}


//MARK: - UITableViewDataSource

extension EditQuotesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! SymbolTableViewCell
        let quote = data[indexPath.row]
        cell.nameLabel.text = quote.companyName
        cell.symbolLabel.text = quote.symbol
        cell.marketLabel.text = quote.primaryExchange
        return cell
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .top)
            delegate?.quotesDidChange(data)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // Override to support rearranging the table view.
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        data.insert(data.remove(at: fromIndexPath.row), at: to.row)
        tableView.reloadData()
        delegate?.quotesDidChange(data)
    }
}
