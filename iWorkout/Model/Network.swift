//
//  Network.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-06-10.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import Foundation

enum Result <Value> {
    case success(Value)
    case failure(Error)
}

struct LoginRequest: Codable {
    var token: String
}

struct WorkoutResponse: Decodable {
    var id: Int
}

struct NoContent: Decodable {}

struct User: Codable {
    var id: Int
    var name: String
}

struct LoginResponse: Codable {
    var user: User
    var workouts: [Workout]
}

class Network {
    static let baseUrl = "17b466a3.ngrok.io"

    static func loadInitialState(token: String, completion: @escaping (Result<LoginResponse>) -> Void) {
        let request = LoginRequest(token: token)
        sendHTTPRequest(verb: "POST", path: "/login", body: request, completion: completion)
    }

    static func save(workout: Workout, completion: @escaping (Result<WorkoutResponse>) -> Void) {
        sendHTTPRequest(verb: "POST", path: "/workout", body: workout, completion: completion)
    }

    static func update(workout: Workout, completion: @escaping (Result<NoContent>) -> Void) {
        sendHTTPRequest(verb: "PUT", path: "/workout", body: workout, completion: completion, defaultValue: NoContent())
    }

    static func sendHTTPRequest<T: Codable, R: Decodable>(verb: String, path: String, body: T, completion: @escaping (Result<R>) -> Void, defaultValue: R? = nil) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseUrl
        urlComponents.path = path

        guard let url = urlComponents.url else {
            completion(.failure(WorkoutError.urlError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = verb
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let requestBody = try encoder.encode(body)
            request.httpBody = requestBody
        } catch {
            completion(.failure(error))
        }

        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                if let error = responseError {
                    completion(.failure(error))
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 204, let defaultValue = defaultValue {
                        completion(Result.success(defaultValue))
                        return
                    }

                    if let jsonData = responseData {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601

                        do {
                            let resp = try decoder.decode(R.self, from: jsonData)
                            completion(.success(resp))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.failure(WorkoutError.networkError(message: "No data retrieved from the server")))
                }
            }
        }

        task.resume()
    }
}
