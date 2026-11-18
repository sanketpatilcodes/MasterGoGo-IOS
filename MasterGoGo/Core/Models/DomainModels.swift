import Foundation

struct ContentSection: Identifiable, Decodable, Hashable {
    let slug: String
    let title: String
    let description: String?
    let courses: [Course]

    var id: String { slug }
}

struct Course: Identifiable, Decodable, Hashable {
    let slug: String
    let title: String
    let description: String?
    let tutorials: [Tutorial]

    var id: String { slug }
}

struct Tutorial: Identifiable, Decodable, Hashable {
    let slug: String
    let title: String
    let summary: String?
    let body: String?
    let imagePath: String?

    var id: String { slug }
}

struct InterviewQuestion: Identifiable, Decodable, Hashable {
    let id: String
    let question: String
    let answer: String?

    enum CodingKeys: String, CodingKey { case id, question, answer }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? values.decode(String.self, forKey: .id) {
            id = stringID
        } else if let integerID = try? values.decode(Int.self, forKey: .id) {
            id = String(integerID)
        } else {
            id = UUID().uuidString
        }
        question = try values.decodeIfPresent(String.self, forKey: .question) ?? ""
        answer = try values.decodeIfPresent(String.self, forKey: .answer)
    }
}

struct InterviewCategory: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let questions: [InterviewQuestion]

    enum CodingKeys: String, CodingKey { case id, name, questions }

    init(id: String, name: String, questions: [InterviewQuestion]) {
        self.id = id
        self.name = name
        self.questions = questions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? values.decode(String.self, forKey: .id) {
            id = stringID
        } else if let integerID = try? values.decode(Int.self, forKey: .id) {
            id = String(integerID)
        } else {
            id = UUID().uuidString
        }
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? "Interview Questions"
        questions = try values.decodeIfPresent([InterviewQuestion].self, forKey: .questions) ?? []
    }
}

struct InterviewCollection: Decodable, Hashable {
    let platform: String
    let appName: String
    let categories: [InterviewCategory]

    var questions: [InterviewQuestion] {
        categories.flatMap(\.questions)
    }

    enum CodingKeys: String, CodingKey { case platform, appName, categories, questions }

    init(platform: String, questions: [InterviewQuestion]) {
        self.platform = platform
        appName = "\(platform.capitalized) Interview Questions"
        categories = [InterviewCategory(id: "default", name: "Interview Questions", questions: questions)]
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        appName = try values.decodeIfPresent(String.self, forKey: .appName) ?? "Interview Questions"
        platform = try values.decodeIfPresent(String.self, forKey: .platform) ?? "android"
        if let decodedCategories = try values.decodeIfPresent([InterviewCategory].self, forKey: .categories) {
            categories = decodedCategories
        } else {
            let questions = try values.decodeIfPresent([InterviewQuestion].self, forKey: .questions) ?? []
            categories = [InterviewCategory(id: "default", name: "Interview Questions", questions: questions)]
        }
    }
}

struct APIEnvelope<Value: Decodable>: Decodable {
    let data: Value
}

extension KeyedDecodingContainer {
    func decodeFirst<T: Decodable>(_ type: T.Type, forKeys keys: [Key]) throws -> T? {
        for key in keys {
            if let value = try decodeIfPresent(type, forKey: key) {
                return value
            }
        }
        return nil
    }
}

extension ContentSection {
    enum CodingKeys: String, CodingKey {
        case slug, id, title, name, description, courses
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        slug = try values.decodeFirst(String.self, forKeys: [.slug, .id]) ?? "section"
        title = try values.decodeFirst(String.self, forKeys: [.title, .name]) ?? slug.capitalized
        description = try values.decodeIfPresent(String.self, forKey: .description)
        courses = try values.decodeIfPresent([Course].self, forKey: .courses) ?? []
    }
}

extension Course {
    enum CodingKeys: String, CodingKey {
        case slug, id, title, name, description, tutorials
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        slug = try values.decodeFirst(String.self, forKeys: [.slug, .id]) ?? "course"
        title = try values.decodeFirst(String.self, forKeys: [.title, .name]) ?? slug.capitalized
        description = try values.decodeIfPresent(String.self, forKey: .description)
        tutorials = try values.decodeIfPresent([Tutorial].self, forKey: .tutorials) ?? []
    }
}

extension Tutorial {
    enum CodingKeys: String, CodingKey {
        case slug, id, title, name, summary, description, body, content, imagePath, imageURL
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        slug = try values.decodeFirst(String.self, forKeys: [.slug, .id]) ?? "tutorial"
        title = try values.decodeFirst(String.self, forKeys: [.title, .name]) ?? slug.capitalized
        summary = try values.decodeFirst(String.self, forKeys: [.summary, .description])
        body = try values.decodeFirst(String.self, forKeys: [.body, .content])
        imagePath = try values.decodeFirst(String.self, forKeys: [.imagePath, .imageURL])
    }
}

