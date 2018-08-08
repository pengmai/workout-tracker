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

struct User: Codable {
    var id: Int
    var name: String
}

struct LoginResponse: Codable {
    var user: User
    var workouts: [Workout]
}

class Network {
    static let baseUrl = "85e5cb98.ngrok.io"

    static func loadInitialState(token: String, completion: @escaping (Result<LoginResponse>) -> Void) {
        let request = LoginRequest(token: token)
        sendHTTPRequest(verb: "POST", path: "/login", body: request, completion: completion)
    }

    static func save(workout: Workout, completion: @escaping (Result<WorkoutResponse>) -> Void) {
        sendHTTPRequest(verb: "POST", path: "/workout", body: workout, completion: completion)
    }

    static func sendHTTPRequest<T: Codable, R: Decodable>(verb: String, path: String, body: T, completion: @escaping (Result<R>) -> Void) {
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
                } else if let jsonData = responseData {
                    let decoder = JSONDecoder()

                    do {
                        let response = try decoder.decode(R.self, from: jsonData)
                        completion(.success(response))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(WorkoutError.networkError(message: "No data retrieved from the server")))
                }
            }
        }

        task.resume()
    }
}
