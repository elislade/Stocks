import Foundation

extension TimeInterval {
    static let oneHour = 3600.0
    static let oneDay = oneHour * 24
    static let oneWeek = oneDay * 7
    static let oneMonth = 2_629_800.0
    static let threeMonth = oneMonth * 3
    static let sixMonth = oneMonth * 6
    static let oneYear = oneDay * 365
    static let twoYear = oneYear * 2
    static let fiveYear = oneYear * 5
    static let tenYear = oneYear * 10
    
    var description: String {
        switch self {
        case .oneHour: return "1h"
        case .oneDay: return "1d"
        case .oneWeek: return "1w"
        case .oneMonth: return "1m"
        case .threeMonth: return "3m"
        case .sixMonth: return "6m"
        case .oneYear: return "1y"
        case .twoYear: return "2y"
        case .fiveYear: return "5y"
        case .tenYear: return "10y"
        default: return "\(self)"
        }
    }
    
    func subPattern() -> (comp: Calendar.Component, change: Int) {
        switch self {
        case .oneDay: return (.hour, 2)
        case .oneWeek: return (.day, 1)
        case .oneMonth: return (.day, 7)
        case .threeMonth: return (.month, 1)
        case .sixMonth: return (.month, 2)
        case .oneYear: return (.month, 3)
        case .twoYear: return (.month, 4)
        case .fiveYear: return (.year, 1)
        case .tenYear: return (.year, 1)
        default: return (.day, 0)
        }
    }
    
    func calComponent() -> Calendar.Component {
        switch self {
        case .oneDay: return .hour
        case .oneWeek: return .weekday
        case .oneMonth: return .day
        case .threeMonth: return .month
        case .sixMonth: return .month
        case .oneYear: return .month
        case .twoYear: return .month
        case .fiveYear: return .year
        case .tenYear: return .year
        default: return .second
        }
    }
}
