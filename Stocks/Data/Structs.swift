import Foundation

let ENV: [String: Any] = {
    guard
        let u = Bundle.main.url(forResource: "ENV", withExtension: "json"),
        let d = try? Data(contentsOf: u),
        let j = try? JSONSerialization.jsonObject(with: d, options: .fragmentsAllowed) as? [String: Any]
    else {
        return [:]
    }
    
    return j
}()

//MARK: - IEXQuote

typealias BatchIEX<T: Decodable> = [String: [String: T]]

struct IEXQuote: Codable, Equatable {
    let symbol: String
    let companyName: String
    let open: Double?
    let high: Double?
    let low: Double?
    let latestVolume: Int?
    let marketCap: Double
    let week52High: Double
    let week52Low: Double
    let peRatio: Double
    let latestPrice: Double
    let change: Double
    let changePercent: Double
    let primaryExchange: String
}

struct Symbol: Decodable {
    let symbol: String
    let name: String
}


//MARK: - IEXNewsItem

struct IEXNewsItem: Codable {
    let datetime: Date
    let headline: String
    let source: String
    let url: URL
    let summary: String
    let related: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // getting weird date formatting years in the 5000's
        // maybe not from the 1970's, could be 2001?
        let dateInterval = try container.decode(Double.self, forKey: .datetime)
        
        //datetime = Date(timeIntervalSince1970: dateInterval)
        datetime = Date(timeIntervalSinceReferenceDate: dateInterval)
        headline = try container.decode(String.self, forKey: .headline)
        source = try container.decode(String.self, forKey: .source)
        url = try container.decode(URL.self, forKey: .url)
        summary = try container.decode(String.self, forKey: .summary)
        related = try container.decode(String.self, forKey: .related)
    }
}


//MARK: - IEXCandle

struct IEXCandle: Codable {
    let date: Date
    let open: Double
    let close: Double
    let low: Double
    let volume: Int
    var closeOrLow: Double { low }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        low = try container.decode(Double.self, forKey: .low)
        volume = try container.decode(Int.self, forKey: .volume)
        
        let formatter = DateFormatter.test
        
        open = try container.decode(Double.self, forKey: .open)
        close = try container.decode(Double.self, forKey: .close)
        
        let dateString = try container.decode(String.self, forKey: .date)
        
        if let date = formatter.date(from: dateString) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .date,
                in: container,
                debugDescription: "Date string does not match format expected by formatter."
            )
        }
    }
}

extension IEXCandle: CandleConformable { }
