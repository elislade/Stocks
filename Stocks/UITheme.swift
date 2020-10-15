import UIKit

struct UITheme {
    let preferredStatusBarStyle: UIStatusBarStyle
    let keyboardAppearance: UIKeyboardAppearance
    let barStyle: UIBarStyle
    let blurEffectStyle: UIBlurEffect.Style
    let tintColor: UIColor
    
    let primaryBackgroundColor: UIColor
    let secondaryBackgroundColor: UIColor
    
    let primaryForegroundColor: UIColor
    let secondaryForegroundColor: UIColor
    
    static var main: UITheme! {
        didSet {
            if #available(iOS 13, *) { return }
            
            let effect = UIBlurEffect(style: main.blurEffectStyle)
            UITableViewCell.appearance().backgroundColor = .clear
            UINavigationBar.appearance().barStyle = main.barStyle
            UITabBar.appearance().barStyle = main.barStyle
            UIToolbar.appearance().barStyle = main.barStyle
            UIVisualEffectView.appearance().effect = effect
            UIVisualEffectView.appearance().backgroundColor = main.secondaryBackgroundColor.withAlphaComponent(0.6)
            UITextField.appearance().keyboardAppearance = main.keyboardAppearance
            UISearchBar.appearance().keyboardAppearance = main.keyboardAppearance
            UISearchBar.appearance().barStyle = main.barStyle
            UITableView.appearance().backgroundColor = main.primaryBackgroundColor
            UITableView.appearance().separatorColor = main.secondaryBackgroundColor
            UIPageControl.appearance().pageIndicatorTintColor = main.primaryForegroundColor.withAlphaComponent(0.3)
            UIPageControl.appearance().currentPageIndicatorTintColor = main.primaryForegroundColor
            UIActivityIndicatorView.appearance().color = main.secondaryBackgroundColor
        }
    }
    
    static let light = UITheme(
        preferredStatusBarStyle: .default,
        keyboardAppearance: .default,
        barStyle: .default,
        blurEffectStyle: .light,
        tintColor: UIColor(red: 0.7, green: 0.3, blue: 0.4, alpha: 1),
        primaryBackgroundColor: UIColor(hue: 1, saturation: 0, brightness: 0.96, alpha: 1),
        secondaryBackgroundColor: .white,
        primaryForegroundColor: .darkGray,
        secondaryForegroundColor: .lightGray
    )
    
    static let dark = UITheme(
        preferredStatusBarStyle: .lightContent,
        keyboardAppearance: .dark,
        barStyle: .black,
        blurEffectStyle: .dark,
        tintColor: UIColor(red:1.00, green:0.64, blue:0.23, alpha:1.00),
        primaryBackgroundColor: .black,
        secondaryBackgroundColor: .darkGray,
        primaryForegroundColor: .white,
        secondaryForegroundColor: .lightGray
    )
}

