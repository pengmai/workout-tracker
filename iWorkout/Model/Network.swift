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

struct WorkoutRequest: Encodable {
    var id: Int
    var user: Int
    var start: Date
    var end: Date
}

struct WorkoutResponse: Decodable {
    var id: Int
}

class Network {
    static func save(workout: Workout, completion: @escaping (Result<Int>) -> Void) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "01ae8dad.ngrok.io"
        urlComponents.path = "/workout"

        guard let url = urlComponents.url else {
            completion(.failure(WorkoutError.urlError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers

        let encoder = JSONEncoder()
        do {
            let workoutRequest = try encoder.encode(workout)
            request.httpBody = workoutRequest
        } catch {
            completion(.failure(error))
        }

        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            DispatchQueue.main.async {
                if let error = responseError {
                    completion(.failure(error))
                } else if let jsonData = responseData {
                    let decoder = JSONDecoder()

                    do {
                        let workoutResponse = try decoder.decode(WorkoutResponse.self, from: jsonData)
                        completion(.success(workoutResponse.id))
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
