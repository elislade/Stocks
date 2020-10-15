import UIKit

typealias Res<T: Decodable> = (T?, Error?) -> Void

struct StocksAPI {
    
    enum APIError: LocalizedError { case noData }
    
    static let shared = StocksAPI()
    
    var isSandboxed = true
    
    let prodPath = "https://cloud.iexapis.com/stable"
    let sandboxPath = "https://sandbox.iexapis.com/stable"
    
    var prodToken: String {
        ENV["API_TOKEN"] as? String ?? "_"
    }
    
    var sandboxToken: String {
        ENV["API_TOKEN_SANDBOX"] as? String ?? "_"
    }
    
    var path: String { isSandboxed ? sandboxPath : prodPath }
    var token: String { isSandboxed ? sandboxToken : prodToken }
    
    var session = URLSession.shared
    var decoder = JSONDecoder()
    var encoder = JSONEncoder()
    
    init() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }
    
    func request(from string: String, with params: [String:String] = [:]) -> URLRequest? {
        var p = params
        p["token"] = token
        
        if let u = URL(string: path + string + p.asUrlQuery) {
            return URLRequest(url: u)
        } else {
            return nil
        }
    }
    
    func get<T: Decodable>(with req: URLRequest, completion: @escaping Res<T>){
        session.dataTask(with: req){ data, res, err in
            if let d = data {
                do {
                    let t = try decoder.decode(T.self, from: d)
                    completion(t, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion(nil, APIError.noData)
            }
        }.resume()
    }
    
    func getSymbols(completion: @escaping Res<[Symbol]>) {
        if let req = request(from:"/ref-data/symbols") {
            get(with: req, completion: completion)
        } else {
            completion(nil, NSError(domain: "string not valid as URL", code: 0, userInfo: nil))
        }
    }
    
    func getBatch(for symbols: [String], completion: @escaping Res<BatchIEX<IEXQuote>>) {
        let output = "/stock/market/batch"
        if let req = request(from: output, with: ["symbols": symbols.joined(separator:","), "types": "quote"]) {
            get(with: req, completion: completion)
        } else {
            completion(nil, NSError(domain: "string not valid as URL", code: 0, userInfo: nil))
        }
    }
    
    func getQuote(for symbol: String, completion: @escaping Res<IEXQuote>) {
        if let req = request(from: "/stock/\(symbol)/quote") {
            get(with: req, completion: completion)
        } else {
            completion(nil, NSError(domain: "string not valid as URL", code: 0, userInfo: nil))
        }
    }
    
    func getNews(for symbol: String, completion: @escaping Res<[IEXNewsItem]>) {
        if let req = request(from: "/stock/\(symbol)/news") {
            get(with: req, completion: completion)
        } else {
            completion(nil, NSError(domain: "string not valid as URL", code: 0, userInfo: nil))
        }
    }
    
    func getChart(for symbol: String, range: TimeInterval, completion: @escaping Res<[IEXCandle]>) {
        let output = range == .oneDay ? "/stock/\(symbol)/intraday-prices" : "/stock/\(symbol)/chart/\(range.description)"
        if let req = request(from: output, with: [:]) {
            get(with: req, completion: completion)
        } else {
            completion(nil, NSError(domain: "string not valid as URL", code: 0, userInfo: nil))
        }
    }
}
