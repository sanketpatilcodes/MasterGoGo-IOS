import Foundation

extension RemoteContentRepository: InterviewRepository {
    func interviews(platform: String) async throws -> InterviewCollection {
        let data = try await client.data(endpoint: .interviews(platform))
        if let collection = try? APIResponseDecoder.decodeValue(InterviewCollection.self, from: data) {
            return collection
        }
        let questions = try APIResponseDecoder.decodeArray(InterviewQuestion.self, from: data)
        return InterviewCollection(platform: platform, questions: questions)
    }
}
