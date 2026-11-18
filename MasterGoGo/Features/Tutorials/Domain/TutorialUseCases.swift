import Foundation

struct LoadCatalogUseCase {
    let repository: TutorialRepository
    func execute() async throws -> [ContentSection] { try await repository.catalog() }
}

struct LoadSectionUseCase {
    let repository: TutorialRepository
    func execute(slug: String) async throws -> ContentSection { try await repository.section(slug: slug) }
}

struct LoadCourseUseCase {
    let repository: TutorialRepository
    func execute(section: String, course: String) async throws -> Course { try await repository.course(section: section, slug: course) }
}

struct LoadTutorialUseCase {
    let repository: TutorialRepository
    func execute(section: String, course: String, slug: String) async throws -> Tutorial { try await repository.tutorial(section: section, course: course, slug: slug) }
}

struct LoadDefaultTutorialsUseCase {
    let repository: TutorialRepository
    func execute() async throws -> [Tutorial] { try await repository.defaultTutorials() }
}

struct LoadDefaultTutorialUseCase {
    let repository: TutorialRepository
    func execute(slug: String) async throws -> Tutorial { try await repository.defaultTutorial(slug: slug) }
}
