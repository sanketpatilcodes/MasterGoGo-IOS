import XCTest
@testable import MasterGoGo

final class APIEndpointTests: XCTestCase {
    func testEndpointPathsMatchDocumentedAPI() {
        XCTAssertEqual(APIEndpoint.content.path, "/api/content")
        XCTAssertEqual(APIEndpoint.section("android").path, "/api/content/android/")
        XCTAssertEqual(APIEndpoint.course(section: "android", course: "solid-principles").path, "/api/content/android/solid-principles/")
        XCTAssertEqual(APIEndpoint.tutorial(section: "android", course: "solid-principles", tutorial: "single-responsibility-principle").path, "/api/content/android/solid-principles/single-responsibility-principle/")
        XCTAssertEqual(APIEndpoint.tutorialImage(section: "android", course: "solid-principles", tutorial: "single-responsibility-principle").path, "/api/content/android/solid-principles/single-responsibility-principle/image")
        XCTAssertEqual(APIEndpoint.interviews("android").path, "/api/interviews/android")
    }
}

final class DomainDecodingTests: XCTestCase {
    func testInterviewEnvelopeDecodesNumericIDsAndFlattensQuestions() throws {
        let json = """
        {
            "data": {
                "platform": "android",
                "appName": "Android Interview Questions",
                "categories": [{
                    "id": 1,
                    "name": "Android Basics",
                    "questions": [{"id": 7, "question": "What is an Activity?", "answer": "A screen."}]
                }]
            }
        }
        """
        let data = Data(json.utf8)

        let collection = try APIResponseDecoder.decodeValue(InterviewCollection.self, from: data)

        XCTAssertEqual(collection.platform, "android")
        XCTAssertEqual(collection.categories.count, 1)
        XCTAssertEqual(collection.categories[0].id, "1")
        XCTAssertEqual(collection.questions.map(\.id), ["7"])
        XCTAssertEqual(collection.questions.first?.answer, "A screen.")
    }

    func testTutorialDecoderSupportsCommonAliases() throws {
        let json = """
        {
            "id": "single-responsibility-principle",
            "name": "Single Responsibility Principle",
            "description": "One reason to change.",
            "content": "Article body",
            "imageURL": "/images/srp.png"
        }
        """
        let data = Data(json.utf8)

        let tutorial = try APIResponseDecoder.decodeValue(Tutorial.self, from: data)

        XCTAssertEqual(tutorial.slug, "single-responsibility-principle")
        XCTAssertEqual(tutorial.title, "Single Responsibility Principle")
        XCTAssertEqual(tutorial.summary, "One reason to change.")
        XCTAssertEqual(tutorial.body, "Article body")
        XCTAssertEqual(tutorial.imagePath, "/images/srp.png")
    }

    func testArrayDecoderSupportsDataEnvelope() throws {
        let data = Data("{\"data\":[{\"slug\":\"android\",\"title\":\"Android\",\"courses\":[]}] }".utf8)

        let sections = try APIResponseDecoder.decodeArray(ContentSection.self, from: data)

        XCTAssertEqual(sections.map(\.slug), ["android"])
    }
}

final class UseCaseTests: XCTestCase {
    func testTutorialUseCaseDelegatesToRepository() async throws {
        let repository = MockTutorialRepository()
        let expected = Course(slug: "solid-principles", title: "SOLID Principles", description: nil, tutorials: [])
        repository.courseResult = expected

        let result = try await LoadCourseUseCase(repository: repository).execute(section: "android", course: "solid-principles")

        XCTAssertEqual(result, expected)
        XCTAssertEqual(repository.receivedCourseRequest?.section, "android")
        XCTAssertEqual(repository.receivedCourseRequest?.slug, "solid-principles")
    }

    func testInterviewUseCasePassesPlatformToRepository() async throws {
        let repository = MockInterviewRepository()
        let expected = InterviewCollection(platform: "android", questions: [])
        repository.result = expected

        let result = try await LoadInterviewsUseCase(repository: repository).execute(platform: "android")

        XCTAssertEqual(result, expected)
        XCTAssertEqual(repository.receivedPlatform, "android")
    }
}

final class RemoteRepositoryTests: XCTestCase {
    func testInterviewRepositoryDecodesWrappedResponse() async throws {
        let client = MockAPIClient(responses: [
            .interviews("android"): Data("{\"data\":{\"platform\":\"android\",\"categories\":[]}}".utf8)
        ])
        let repository = RemoteContentRepository(client: client, baseURL: URL(string: "http://localhost:8080")!)

        let result = try await repository.interviews(platform: "android")

        XCTAssertEqual(result.platform, "android")
        XCTAssertEqual(client.requestedEndpoints, [.interviews("android")])
    }

    func testSectionRepositoryMapsCourseArrayToSection() async throws {
        let json = #"{"data":[{"slug":"scope-functions","title":"Scope Functions","tutorials":[]}]}"#
        let client = MockAPIClient(responses: [
            .section("kotlin"): Data(json.utf8)
        ])
        let repository = RemoteContentRepository(client: client, baseURL: URL(string: "http://localhost:8080")!)

        let result = try await repository.section(slug: "kotlin")

        XCTAssertEqual(result.slug, "kotlin")
        XCTAssertEqual(result.courses.map(\.slug), ["scope-functions"])
    }
}

private final class MockAPIClient: APIClient {
    let responses: [APIEndpoint: Data]
    private(set) var requestedEndpoints: [APIEndpoint] = []

    init(responses: [APIEndpoint: Data]) {
        self.responses = responses
    }

    func data(endpoint: APIEndpoint) async throws -> Data {
        requestedEndpoints.append(endpoint)
        guard let response = responses[endpoint] else {
            throw TestError.missingResponse
        }
        return response
    }
}

private final class MockTutorialRepository: TutorialRepository {
    var courseResult: Course?
    var receivedCourseRequest: (section: String, slug: String)?

    func catalog() async throws -> [ContentSection] { [] }
    func section(slug: String) async throws -> ContentSection {
        ContentSection(slug: slug, title: slug, description: nil, courses: [])
    }
    func course(section: String, slug: String) async throws -> Course {
        receivedCourseRequest = (section, slug)
        return courseResult ?? Course(slug: slug, title: slug, description: nil, tutorials: [])
    }
    func tutorial(section: String, course: String, slug: String) async throws -> Tutorial {
        Tutorial(slug: slug, title: slug, summary: nil, body: nil, imagePath: nil)
    }
    func tutorialImageURL(section: String, course: String, tutorial: String) -> URL? { nil }
    func defaultTutorials() async throws -> [Tutorial] { [] }
    func defaultTutorial(slug: String) async throws -> Tutorial {
        Tutorial(slug: slug, title: slug, summary: nil, body: nil, imagePath: nil)
    }
    func defaultTutorialImageURL(slug: String) -> URL? { nil }
}

private final class MockInterviewRepository: InterviewRepository {
    var result = InterviewCollection(platform: "android", questions: [])
    private(set) var receivedPlatform: String?

    func interviews(platform: String) async throws -> InterviewCollection {
        receivedPlatform = platform
        return result
    }
}

private enum TestError: Error {
    case missingResponse
}
