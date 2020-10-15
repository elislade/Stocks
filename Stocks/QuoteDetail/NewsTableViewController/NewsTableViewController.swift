import UIKit
import SafariServices

class NewsTableViewController: UITableViewController {
    
    
    //MARK: - Header Variables
    
    var data = [IEXNewsItem]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    //MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "NewsTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NewsTableViewCell
        let news = data[indexPath.row]
        cell.textLabel?.text = news.headline
        cell.textLabel?.textColor = UITheme.main.primaryForegroundColor
        cell.detailTextLabel?.text = "\(news.source) - \(news.datetime.format(as: .medium))"
        cell.detailTextLabel?.textColor = UITheme.main.secondaryForegroundColor
        cell.backgroundView = UIView()
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newsItem = data[indexPath.row]
        let safari = SFSafariViewController(url: newsItem.url)
        safari.modalPresentationStyle = .formSheet
        present(safari, animated: true, completion: nil)
    }
}
