import Foundation
import Crypto
import Testing
@testable import ASC

private func asyncProvider(statusCode: Int = 200, data: Data = Data()) throws -> APIProvider {
    let key = P256.Signing.PrivateKey().derRepresentation.base64EncodedString()
    let configuration = try APIConfiguration(issuerID: "issuer", privateKeyID: "key", privateKey: key)
    return APIProvider(configuration: configuration, requestExecutor: AsyncRequestExecutor(statusCode: statusCode, data: data))
}

@Test func asyncRequestDecodedResponse() async throws {
    let provider = try asyncProvider(data: Data(#"{"value":"decoded"}"#.utf8))
    let request = Request<[String: String]>(path: "test", method: "GET", id: "test")
    let response = try await provider.request(request)
    #expect(response == ["value": "decoded"])
}

@Test func asyncVoidRequest() async throws {
    let provider = try asyncProvider(statusCode: 204)
    try await provider.request(Request<Void>(path: "test", method: "DELETE", id: "test"))
}

@Test func asyncRequestFailure() async throws {
    let provider = try asyncProvider(statusCode: 403)
    do {
        try await provider.request(Request<Void>(path: "test", method: "DELETE", id: "test"))
        Issue.record("Expected request failure")
    } catch let error as APIProvider.Error {
        guard case .requestFailure(let statusCode, _, _) = error else {
            Issue.record("Unexpected error: \(error)")
            return
        }
        #expect(statusCode == 403)
    }
}

@Test func asyncDownload() async throws {
    let provider = try asyncProvider()
    let url = try await provider.download(Request<Data>(path: "test", method: "GET", id: "test"))
    #expect(url.path == "/tmp/asc-report")
}

@Test func asyncNextPage() async throws {
    let provider = try asyncProvider(data: Data(#"{"data":[],"links":{"self":"https://example.com/next"}}"#.utf8))
    let request = Request<AppsResponse>(path: "test", method: "GET", id: "test")
    let current = AppsResponse(data: [], links: PagedDocumentLinks(this: "https://example.com/first", next: "https://example.com/next"))
    let next = try await provider.request(request, pageAfter: current)
    #expect(next?.links.this == "https://example.com/next")
    let last = AppsResponse(data: [], links: PagedDocumentLinks(this: "https://example.com/last"))
    let end = try await provider.request(request, pageAfter: last)
    #expect(end == nil)
}
