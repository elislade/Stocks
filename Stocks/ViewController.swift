import UIKit

class ViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UITheme.main.preferredStatusBarStyle
    }
    
    
    //MARK: - Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UITheme.main.primaryBackgroundColor
    }
}
