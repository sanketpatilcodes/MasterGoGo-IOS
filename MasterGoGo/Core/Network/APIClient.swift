import Foundation

protocol APIClient {
    func data(endpoint: APIEndpoint) async throws -> Data
}

enum APIEndpoint: Hashable {
    case health
    case content
    case section(String)
    case course(section: String, course: String)
    case tutorial(section: String, course: String, tutorial: String)
    case tutorialImage(section: String, course: String, tutorial: String)
    case courseJSON(section: String, course: String)
    case tutorials
    case defaultTutorial(String)
    case defaultTutorialImage(String)
    case interviews(String)

    var path: String {
        switch self {
        case .health: return "/api/health"
        case .content: return "/api/content"
        case .section(let section): return "/api/content/\(section)/"
        case .course(let section, let course): return "/api/content/\(section)/\(course)/"
        case .tutorial(let section, let course, let tutorial): return "/api/content/\(section)/\(course)/\(tutorial)/"
        case .tutorialImage(let section, let course, let tutorial): return "/api/content/\(section)/\(course)/\(tutorial)/image"
        case .courseJSON(let section, let course): return "/api/content/\(section)/\(course)/content.json"
        case .tutorials: return "/api/tutorials"
        case .defaultTutorial(let tutorial): return "/api/tutorials/\(tutorial)"
        case .defaultTutorialImage(let tutorial): return "/api/tutorials/\(tutorial)/image"
        case .interviews(let platform): return "/api/interviews/\(platform)"
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case server(statusCode: Int)
    case decoding(Error)
    case transport(Error, URL)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The server returned an invalid response."
        case .server(let statusCode): return "The server returned status code \(statusCode)."
        case .decoding: return "The response format was not recognized."
        case .transport(let error, let url):
            return "Cannot connect to \(url.host ?? url.absoluteString):\(url.port ?? 80). Make sure the API is reachable from this device. (\(error.localizedDescription))"
        }
    }
}

struct URLSessionAPIClient: APIClient {
    let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://localhost:8080")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func data(endpoint: APIEndpoint) async throws -> Data {
        let url = baseURL.appendingPathComponent(endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            guard 200..<300 ~= httpResponse.statusCode else {
                throw APIError.server(statusCode: httpResponse.statusCode)
            }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error, url)
        }
    }
}

struct APIResponseDecoder {
    static func decodeArray<T: Decodable>(_ type: T.Type, from data: Data) throws -> [T] {
        let decoder = JSONDecoder()
        if let values = try? decoder.decode([T].self, from: data) { return values }
        if let envelope = try? decoder.decode(APIEnvelope<[T]>.self, from: data) { return envelope.data }
        throw APIError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Expected an array response")))
    }

    static func decodeValue<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(APIEnvelope<T>.self, from: data) { return envelope.data }
        if let value = try? decoder.decode(T.self, from: data) { return value }
        throw APIError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Expected an object response")))
    }
}
