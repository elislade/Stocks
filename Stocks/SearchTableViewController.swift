import UIKit

protocol SearchViewControllerDelegate {
    func didSelectQuote(_ quote:IEXQuote)
}

class SearchTableViewController: TableViewController {
    
    
    //MARK: - Header Variables
    
    //var results = [IEXQuote]()
    var delegate: SearchViewControllerDelegate?
    let searchBar = UISearchBar()
    
    var symbols = [Symbol]()
    var filteredSymbols = [Symbol]()
    
    
    //MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "SymbolTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "ResultCell")
        tableView.separatorColor = UITheme.main.secondaryBackgroundColor
        
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.placeholder = "Search"
        searchBar.showsCancelButton = true
        
        navigationItem.prompt = "Type a company name or stock symbol."
        navigationItem.titleView = searchBar
        
        StocksAPI.shared.getSymbols { symbols, error in
            if let syms = symbols {
                self.symbols = syms
            }
            
            if let e = error {
                print(e)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSymbols.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! SymbolTableViewCell
        let symbol = filteredSymbols[indexPath.row]
        cell.nameLabel.text = symbol.name
        cell.symbolLabel.text = symbol.symbol
        cell.marketLabel.text = ""
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let symbol = filteredSymbols[indexPath.row]
        
        StocksAPI.shared.getQuote(for: symbol.symbol){ data, error in
            guard let res = data else { return }
            DispatchQueue.main.async {
                self.delegate?.didSelectQuote(res)
            }
        }
        
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
}


//MARK: - UISearchBarDelegate

extension SearchTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredSymbols = symbols.filter({ $0.name.contains(searchText) || $0.symbol.contains(searchText.uppercased()) })
        tableView.reloadData()
    }
}
