import Combine
import Foundation

@MainActor
final class CatalogViewModel: ObservableObject {
    @Published private(set) var sections: [ContentSection] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let loadCatalog: LoadCatalogUseCase

    init(repository: TutorialRepository) {
        loadCatalog = LoadCatalogUseCase(repository: repository)
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { sections = try await loadCatalog.execute() }
        catch { errorMessage = error.localizedDescription }
    }
}

@MainActor
final class SectionViewModel: ObservableObject {
    @Published private(set) var section: ContentSection?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let loadSection: LoadSectionUseCase
    private let slug: String

    init(repository: TutorialRepository, slug: String) {
        loadSection = LoadSectionUseCase(repository: repository)
        self.slug = slug
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { section = try await loadSection.execute(slug: slug) }
        catch { errorMessage = error.localizedDescription }
    }
}

@MainActor
final class CourseViewModel: ObservableObject {
    @Published private(set) var course: Course?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let loadCourse: LoadCourseUseCase
    private let sectionSlug: String
    private let courseSlug: String

    init(repository: TutorialRepository, sectionSlug: String, courseSlug: String) {
        loadCourse = LoadCourseUseCase(repository: repository)
        self.sectionSlug = sectionSlug
        self.courseSlug = courseSlug
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { course = try await loadCourse.execute(section: sectionSlug, course: courseSlug) }
        catch { errorMessage = error.localizedDescription }
    }
}

@MainActor
final class TutorialViewModel: ObservableObject {
    @Published private(set) var tutorial: Tutorial?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let loadTutorial: LoadTutorialUseCase
    private let repository: TutorialRepository
    private let sectionSlug: String
    private let courseSlug: String
    private let tutorialSlug: String

    init(repository: TutorialRepository, sectionSlug: String, courseSlug: String, tutorialSlug: String) {
        loadTutorial = LoadTutorialUseCase(repository: repository)
        self.repository = repository
        self.sectionSlug = sectionSlug
        self.courseSlug = courseSlug
        self.tutorialSlug = tutorialSlug
    }

    var imageURL: URL? {
        repository.tutorialImageURL(section: sectionSlug, course: courseSlug, tutorial: tutorialSlug)
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { tutorial = try await loadTutorial.execute(section: sectionSlug, course: courseSlug, slug: tutorialSlug) }
        catch { errorMessage = error.localizedDescription }
    }
}
