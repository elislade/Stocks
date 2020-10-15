import UIKit

extension Double {
    func roundDecimal(to nearest:Double) -> Double {
        let d = Double(self)
        return Darwin.round(nearest * d) / nearest
    }
    
    func roundToPlaces(_ places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        let d = Double(self)
        return Darwin.round(d * divisor) / divisor
    }
    
    func formatPoints() -> String {
        let thousandNum = self/1_000
        let millionNum = self/1_000_000
        let billionNum = self/1_000_000_000
        
        if self >= 1_000 && self < 1000000 {
            if(floor(thousandNum) == thousandNum){
                return("\(Int(thousandNum))k")
            }
            return("\(thousandNum.roundToPlaces(1))k")
        }
        
        if self >= 1_000_000 && self < 1_000_000_000 {
            if(floor(millionNum) == millionNum){
                return("\(Int(thousandNum))k")
            }
            return ("\(millionNum.roundToPlaces(1))M")
        }
        
        if self > 1_000_000_000 {
            if(floor(billionNum) == billionNum){
                return("\(Int(thousandNum))k")
            }
            return ("\(billionNum.roundToPlaces(1))B")
        } else {
            if(floor(self) == self){
                return ("\(Int(self))")
            }
            return ("\(self)")
        }
    }
    
    func format(as style:NumberFormatter.Style, modify:((NumberFormatter) -> Void)? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        if style == .percent {
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 2
        }
        modify?(formatter)
        if let string = formatter.string(from: (self as NSNumber)) {
            return string
        }
        return "--"
    }
}

extension Date {
    func format(as style: DateFormatter.Style, modify:((DateFormatter) -> Void)? = nil) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .short
        modify?(formatter)
        return formatter.string(from: self)
    }
    
    func formatInterval(toDate date:Date, withStyle style:DateIntervalFormatter.Style) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .short
        return formatter.string(from: self, to: date)
    }
}

extension DateFormatter {
    static let test: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let alt: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension UIColor {
    static let stockRed = UIColor(red:1.00, green:0.23, blue:0.18, alpha:1.00)
    static let stockGreen = UIColor(red:0.29, green:0.85, blue:0.39, alpha:1.00)
}

extension Point {
    func distance(to point: Self) -> CGFloat {
        // a^2 + b^2 = c^2, c = sqrt(a^2 + b^2)
        let a = pow((self.x - point.x), 2)
        let b = pow((self.y - point.y), 2)
        return sqrt(a + b)
    }
}

extension CGPoint: Point {}


//MARK: - Global Functions

func randomChar() -> Character {
    return "ABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement()!
}

protocol Treeable {
    associatedtype Branch:Treeable
    
    var parent:Branch? { get }
    var children:[Branch] { get }
}

extension Treeable {
    func children<T>(ofType type: T.Type, toDepth depth:Int = 4) -> [T] {
        if children.count == 0 || depth == 0 {
            return []
        } else {
            var matches = [T]()
            for child in children {
                if let match = child as? T {
                    matches.append(match)
                }
                matches.append(contentsOf: child.children(ofType: type, toDepth: depth - 1))
            }
            return matches
        }
    }
}

extension UIView: Treeable {
    var parent: UIView? { superview }
    var children: [UIView] { subviews }
}

extension UIViewController: Treeable {}

extension Dictionary where Key == String, Value == String {
    var asUrlQuery:String {
        var c = URLComponents()
        c.queryItems = []
        for (key, value) in self {
            c.queryItems?.append(URLQueryItem(name: key, value: String(describing: value) ))
        }
        return c.url?.relativeString ?? ""
    }
}

extension UserDefaults {
    var quotes:[IEXQuote] {
        get {
            guard let d = data(forKey: "myQuotes") else { return [] }
            if let q = try? JSONDecoder().decode([IEXQuote].self, from: d){
                return q
            } else {
                return []
            }
        }
        set {
            set(try? JSONEncoder().encode(newValue), forKey: "myQuotes")
        }
    }
}
