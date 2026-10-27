import Foundation
@testable import ASC
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct AsyncRequestExecutor: RequestExecutor {
    let statusCode: Int
    let data: Data

    func execute(_ request: URLRequest, completion: @escaping @Sendable (Result<Response<Data>, any Error>) -> Void) {
        Task.detached {
            completion(.success(Response(requestURL: request.url, statusCode: statusCode, rateLimit: nil, data: data)))
        }
    }

    func download(_ request: URLRequest, completion: @escaping @Sendable (Result<Response<URL>, any Error>) -> Void) {
        Task.detached {
            completion(.success(Response(requestURL: request.url, statusCode: statusCode, rateLimit: nil, data: URL(fileURLWithPath: "/tmp/asc-report"))))
        }
    }
}
