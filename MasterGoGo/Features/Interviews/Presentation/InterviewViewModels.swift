import Combine
import Foundation

@MainActor
final class InterviewViewModel: ObservableObject {
    @Published private(set) var collection: InterviewCollection?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let loadInterviews: LoadInterviewsUseCase
    private let platform: String

    init(repository: InterviewRepository, platform: String = "android") {
        loadInterviews = LoadInterviewsUseCase(repository: repository)
        self.platform = platform
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { collection = try await loadInterviews.execute(platform: platform) }
        catch { errorMessage = error.localizedDescription }
    }
}
