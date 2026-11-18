import Foundation

protocol TutorialRepository {
    func catalog() async throws -> [ContentSection]
    func section(slug: String) async throws -> ContentSection
    func course(section: String, slug: String) async throws -> Course
    func tutorial(section: String, course: String, slug: String) async throws -> Tutorial
    func tutorialImageURL(section: String, course: String, tutorial: String) -> URL?
    func defaultTutorials() async throws -> [Tutorial]
    func defaultTutorial(slug: String) async throws -> Tutorial
    func defaultTutorialImageURL(slug: String) -> URL?
}

protocol InterviewRepository {
    func interviews(platform: String) async throws -> InterviewCollection
}

protocol ContentRepository: TutorialRepository, InterviewRepository {}

struct RemoteContentRepository: ContentRepository {
    let client: APIClient
    let baseURL: URL
}
