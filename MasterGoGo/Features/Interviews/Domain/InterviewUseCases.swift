import Foundation

struct LoadInterviewsUseCase {
    let repository: InterviewRepository

    func execute(platform: String) async throws -> InterviewCollection {
        try await repository.interviews(platform: platform)
    }
}
