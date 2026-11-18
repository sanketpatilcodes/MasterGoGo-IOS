import Foundation

extension RemoteContentRepository: TutorialRepository {
    func catalog() async throws -> [ContentSection] {
        let data = try await client.data(endpoint: .content)
        if let sections = try? APIResponseDecoder.decodeArray(ContentSection.self, from: data) {
            return sections
        }
        if let catalog = try? APIResponseDecoder.decodeValue(CatalogEnvelope.self, from: data) {
            return catalog.sections
        }
        throw APIError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Expected catalog response")))
    }

    func section(slug: String) async throws -> ContentSection {
        let data = try await client.data(endpoint: .section(slug))
        if let courses = try? APIResponseDecoder.decodeArray(Course.self, from: data) {
            return ContentSection(
                slug: slug,
                title: slug.replacingOccurrences(of: "-", with: " ").capitalized,
                description: nil,
                courses: courses
            )
        }
        return try APIResponseDecoder.decodeValue(ContentSection.self, from: data)
    }

    func course(section: String, slug: String) async throws -> Course {
        let data = try await client.data(endpoint: .course(section: section, course: slug))
        return try APIResponseDecoder.decodeValue(Course.self, from: data)
    }

    func tutorial(section: String, course: String, slug: String) async throws -> Tutorial {
        let data = try await client.data(endpoint: .tutorial(section: section, course: course, tutorial: slug))
        return try APIResponseDecoder.decodeValue(Tutorial.self, from: data)
    }

    func tutorialImageURL(section: String, course: String, tutorial: String) -> URL? {
        baseURL.appendingPathComponent(APIEndpoint.tutorialImage(section: section, course: course, tutorial: tutorial).path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    func defaultTutorials() async throws -> [Tutorial] {
        let data = try await client.data(endpoint: .tutorials)
        return try APIResponseDecoder.decodeArray(Tutorial.self, from: data)
    }

    func defaultTutorial(slug: String) async throws -> Tutorial {
        let data = try await client.data(endpoint: .defaultTutorial(slug))
        return try APIResponseDecoder.decodeValue(Tutorial.self, from: data)
    }

    func defaultTutorialImageURL(slug: String) -> URL? {
        baseURL.appendingPathComponent(APIEndpoint.defaultTutorialImage(slug).path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}

struct CatalogEnvelope: Decodable {
    let sections: [ContentSection]

    enum CodingKeys: String, CodingKey { case sections, content, data }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try values.decodeIfPresent([ContentSection].self, forKey: .sections) {
            sections = value
        } else if let value = try values.decodeIfPresent([ContentSection].self, forKey: .content) {
            sections = value
        } else {
            sections = try values.decodeIfPresent([ContentSection].self, forKey: .data) ?? []
        }
    }
}
