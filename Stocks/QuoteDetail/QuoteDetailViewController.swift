import UIKit
import SafariServices

protocol QuoteDetailDelegate {
    func editButtonTapped()
}

class QuoteDetailViewController: ViewController {
    
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var pageViewCtrlContainer: UIView!
    @IBOutlet weak var marketStatusLabel: UILabel!
    
    
    //MARK: - IBActions
    
    @IBAction func marketSourceTapped(_ sender: Any) {
        let safari = SFSafariViewController(url: URL(string:"https://iextrading.com")!)
        safari.preferredControlTintColor = view.tintColor
        safari.modalPresentationStyle = .formSheet
        present(safari, animated: true, completion: nil)
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        delegate?.editButtonTapped()
    }
    
    
    //MARK: - Header Variables
    
    var delegate: QuoteDetailDelegate?
    
    let pageViewCtrl = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    let statsCtrl:StatsViewController = {
        StatsViewController()
    }()
    
    let graphViewCtrl: GraphViewController = {
        GraphViewController()
    }()
    
    let newsCtrl: NewsTableViewController = {
        NewsTableViewController()
    }()
    
    var detailCtrls = [UIViewController]()
    
    var currentIndex: Int? = 0
    private var pendingIndex: Int? = 0
    
    var quote: IEXQuote? {
        didSet {
            statsCtrl.quote = quote
            graphViewCtrl.quote = quote
            
            StocksAPI.shared.getNews(for: quote!.symbol){ news, error in
                guard let news = news else { return }
                self.newsCtrl.data = news
            }
        }
    }
    
    
    //MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //marketStatusLabel.textColor = UITheme.main.secondaryForegroundColor
        
        graphViewCtrl.view.backgroundColor = .clear
        newsCtrl.view.backgroundColor = .clear
        statsCtrl.view.backgroundColor = .clear
        
        pageViewCtrl.dataSource = self
        pageViewCtrl.delegate = self
        pageViewCtrl.setViewControllers([statsCtrl], direction: .forward, animated: true, completion: nil)
        pageViewCtrl.view.frame.size = pageViewCtrlContainer.frame.size
        addChild(pageViewCtrl)
        
        pageViewCtrlContainer.addSubview(pageViewCtrl.view)
        pageViewCtrl.didMove(toParent: self)
        
        detailCtrls = [statsCtrl, graphViewCtrl, newsCtrl]
        
        pageControl.numberOfPages = detailCtrls.count
        pageControl.currentPage = 0
    }
}


//MARK: - UIPageViewControllerDataSource

extension QuoteDetailViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currIndex = currentIndex else { return detailCtrls[0] }
        
        var index = currIndex - 1
        
        if index < 0 {
            index = detailCtrls.count - 1
        }
        
        return detailCtrls[index]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currIndex = currentIndex else { return detailCtrls[0] }
        
        var index = currIndex + 1
        
        if index > detailCtrls.count - 1 {
            index = 0
        }
        
        return detailCtrls[index]
    }
}


//MARK: - UIPageViewControllerDelegate

extension QuoteDetailViewController: UIPageViewControllerDelegate {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let currentIndex = detailCtrls.firstIndex(of: viewController)!
        if currentIndex == 0 {
            return nil
        }
        let previousIndex = abs((currentIndex - 1) % detailCtrls.count)
        return detailCtrls[previousIndex]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let currentIndex = detailCtrls.firstIndex(of: viewController)!
        if currentIndex == detailCtrls.count-1 {
            return nil
        }
        let nextIndex = abs((currentIndex + 1) % detailCtrls.count)
        return detailCtrls[nextIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            currentIndex = pendingIndex
            if let index = currentIndex {
                pageControl.currentPage = index
            }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        pendingIndex = detailCtrls.firstIndex(of: pendingViewControllers.first!)
    }
}
