import UIKit

enum QuoteChangeType: Int {
    case percentage = 0, price, mrkCap
}

class QuotesViewController: ViewController {

    
    //MARK: - Interface Builder
    
    @IBOutlet weak var blurViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) { }
    
    
    //MARK: - Header Variables
    
    private var pendingIndex: Int = 0
    
    var currentStockIndex: Int = 0
    var currentSelectedData: IEXQuote?
    
    lazy var fullscreenCtrl: UIPageViewController = {
        let c = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        c.view.backgroundColor = .clear
        c.dataSource = self
        c.delegate = self
        c.modalTransitionStyle = .crossDissolve
        return c
    }()
    
    var data: [IEXQuote] {
        get { UserDefaults.standard.quotes }
        set { UserDefaults.standard.quotes = newValue }
    }
    
    var cellToggleState: QuoteChangeType = .percentage {
        didSet {
            tableView.reloadData()
            let indexP = IndexPath(row: currentStockIndex, section: 0)
            tableView.selectRow(at: indexP, animated: false, scrollPosition: .none)
        }
    }
    
    var detailController: QuoteDetailViewController? {
        children(ofType: QuoteDetailViewController.self).first
    }
    
    
    //MARK: - Public Methods
    
    func getData() {
        let mySymbols = data.count > 0 ? data.map{ $0.symbol } : ["AAPL","TSLA","FB"]
        
        StocksAPI.shared.getBatch(for: mySymbols){ data, error in
            guard let res = data else { return }
            var d = [IEXQuote]()
            
            for symbol in mySymbols {
                if let q = res[symbol]?["quote"] {
                    d.append(q)
                }
            }
            
            self.data = d
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.propagateDataFromCell()
            }
        }
    }
    
    func propagateDataFromCell(at index:Int = 0) {
        if data.count == 0 { return }
        
        let indexPath = IndexPath(row: index, section: 0)
        detailController?.quote = data[index]
        currentSelectedData = data[index]
        
        var rect = tableView.bounds
        rect.size.height -= tableView.contentInset.bottom
        
        if let visableIndexPaths = tableView.indexPathsForRows(in: rect) {
            let scrollPos: UITableView.ScrollPosition = visableIndexPaths.contains(indexPath) ? .none : .middle
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: scrollPos)
        }
        
        currentStockIndex = index
        
        let gvc = GraphFullscreenViewController()
        gvc.quote = data[index]
        fullscreenCtrl.setViewControllers([gvc], direction: .forward, animated: false, completion: nil)
    }
    
    func fullscreenCheck(from traitCollection: UITraitCollection, animated: Bool) {
        if traitCollection.verticalSizeClass == .compact {
            if presentedViewController == nil && data.count > 0 {
                present(fullscreenCtrl, animated: animated, completion: nil)
            }
        } else {
            if presentedViewController == fullscreenCtrl {
                fullscreenCtrl.dismiss(animated: animated, completion: nil)
            }
        }
    }
    
    
    //MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = tableView.scrollIndicatorInsets
        tableView.separatorColor = UITheme.main.secondaryBackgroundColor
        
        detailController?.delegate = self
        detailController?.view.backgroundColor = .clear
        
        // propagateDataFromCell()
        // tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fullscreenCheck(from: traitCollection, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blurViewHeight.constant = 256 + view.safeAreaInsets.bottom
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (_) in
            self.fullscreenCheck(from: newCollection, animated: true)
        }, completion: .none)
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Edit" {
            if let vc = (segue.destination as? UINavigationController)?.topViewController as? EditQuotesViewController {
                vc.data = data
                vc.delegate = self
                vc.changeState = cellToggleState
            }
        }
    }
}


extension QuotesViewController: EditQuotesDelegate {
    func quoteChangeTypeDidChange(_ type: QuoteChangeType) {
        cellToggleState = type
    }
    
    func quotesDidChange(_ quotes: [IEXQuote]) {
        data = quotes
        tableView.reloadData()
        if let curStock = currentSelectedData {
            let index = data.firstIndex(of: curStock) == nil ? 0 : data.firstIndex(of: curStock)!
            propagateDataFromCell(at: index)
        }
    }
}


extension QuotesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StockCell", for: indexPath) as! QuoteTableViewCell
        cell.quote = data[indexPath.row]
        cell.delegate = self
        cell.changeToggleState = cellToggleState
        return cell
    }
}


extension QuotesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        propagateDataFromCell(at: indexPath.row)
    }
}


extension QuotesViewController: QuoteDetailDelegate {
    func editButtonTapped() {
        performSegue(withIdentifier: "Edit", sender: self)
    }
}


extension QuotesViewController: QuoteTableCellDelegate {
    func toggleQuoteChangeType() {
        if cellToggleState == .percentage {
            cellToggleState = .price
        } else if cellToggleState == .price {
            cellToggleState = .mrkCap
        } else {
            cellToggleState = .percentage
        }
    }
}


extension QuotesViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if currentStockIndex == 0 {
            currentStockIndex = data.count - 1
        } else {
            currentStockIndex -= 1
        }
        
        let gvc = GraphFullscreenViewController()
        gvc.quote = data[currentStockIndex]
        
        return gvc
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if currentStockIndex == data.count - 1 {
            currentStockIndex = 0
        } else {
            currentStockIndex += 1
        }
        
        let gvc = GraphFullscreenViewController()
        gvc.quote = data[currentStockIndex]
        
        return gvc
    }
}

extension QuotesViewController: UIPageViewControllerDelegate {
    
    //    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    //
    //
    //        //let currentIndex = detailCtrls.index(of: viewController)!
    //
    //        let currentIndex = data.index(of: ((viewController as? GraphFullscreenViewController)?.stock)!)!
    //
    //        if currentIndex == 0 {
    //            return nil
    //        }
    //        let previousIndex = abs((currentIndex - 1) % data.count)
    //        let s = UIStoryboard(name: "Main", bundle: nil)
    //        let gvc = s.instantiateViewController(withIdentifier: "GraphFull") as? GraphFullscreenViewController
    //        gvc?.stock = data[previousIndex]
    //        return gvc
    //    }
    //
    //    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    //        let currentIndex = detailCtrls.index(of: viewController)!
    //        if currentIndex == detailCtrls.count-1 {
    //            return nil
    //        }
    //        let nextIndex = abs((currentIndex + 1) % detailCtrls.count)
    //        return detailCtrls[nextIndex]
    //    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            // propagateDataFromCell(at: pendingIndex)
            // print("completed")
            currentStockIndex = pendingIndex
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pendingIndex = data.firstIndex(of: ((pendingViewControllers.first as? GraphFullscreenViewController)?.quote)!)!
        print("pending index", pendingIndex)
        //pendingIndex = detailCtrls.index(of: pendingViewControllers.first!)
    }
}
