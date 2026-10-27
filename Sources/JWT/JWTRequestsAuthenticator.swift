//
//  JWTAuthenticator.swift
//  AppStoreConnect-Swift-SDK
//
//  Created by Antoine van der Lee on 08/11/2018.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An Authenticator for URL Requests which makes use of the RequestAdapter from Alamofire.
// The lock protects both the cached token and the replaceable token creator
final class JWTRequestsAuthenticator: @unchecked Sendable {

    private let lock = NSLock()
    private var cachedToken: JWT.Token?
    private let apiConfiguration: APIConfiguration

    /// The JWT Creator to use for creating the JWT token. Can be overriden for test use cases.
    private var storedJWTCreator: JWTCreatable

    var jwtCreator: JWTCreatable {
        get { lock.withLock { storedJWTCreator } }
        set { lock.withLock { storedJWTCreator = newValue } }
    }

    init(apiConfiguration: APIConfiguration) {
        self.apiConfiguration = apiConfiguration
        self.storedJWTCreator = JWT(keyIdentifier: apiConfiguration.privateKeyID, issuerIdentifier: apiConfiguration.issuerID, expireDuration: apiConfiguration.expirationDuration)
    }

    /// Generates a new JWT Token, but only if the in memory cached one is not expired.
    private func createToken() throws -> JWT.Token {
        return try lock.withLock {
            if let cachedToken = cachedToken, !cachedToken.isExpired {
                return cachedToken
            }

            let token = try storedJWTCreator.signedToken(using: apiConfiguration.privateKey)
            cachedToken = token
            return token
        }
    }

    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        let token = try createToken()
        var urlRequest = urlRequest
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
}
