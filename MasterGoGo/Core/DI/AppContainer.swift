import Foundation

enum APIConfiguration {
    static var baseURL: URL {
        let value = UserDefaults.standard.string(forKey: "API_BASE_URL") ?? "http://127.0.0.1:8080"
        return URL(string: value) ?? URL(string: "http://127.0.0.1:8080")!
    }
}

struct AppContainer {
    let repository: ContentRepository

    init(baseURL: URL = APIConfiguration.baseURL) {
        let client = URLSessionAPIClient(baseURL: baseURL)
        repository = RemoteContentRepository(client: client, baseURL: baseURL)
    }
}
