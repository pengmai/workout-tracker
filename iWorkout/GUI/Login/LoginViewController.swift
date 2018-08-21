//
//  LoginViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-08-20.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit
import os

class LoginViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    weak var loginDelegate: LoginDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        let activityIndicator = showActivityIndicator()
        if let token = Datastore.getToken() {
            Network.loadInitialState(token: token, completion: { (result) in
                activityIndicator.removeFromSuperview()
                switch result {
                case .success(let response):
                    if response.user.token != token {
                        Datastore.saveToken(token)
                    }
                    self.loginDelegate?.login(with: response)
                case .failure(let err):
                    os_log("Failed to retrieve workouts: %s", log: OSLog.default, type: .error, err.localizedDescription)
                    self.displayAlert(title: "Something went wrong.", message: "We weren't able to retrieve your workouts.")
                }
            })
        } else {
            activityIndicator.removeFromSuperview()
        }

        updateLoginButtonState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Actions
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        guard let userText = usernameField.text,
            let passText = passwordField.text else {
            return
        }

        let activityIndicator = showActivityIndicator()
        Network.logIn(name: userText, password: passText, completion: { (result) in
            activityIndicator.removeFromSuperview()
            switch result {
            case .success(let response):
                Datastore.saveToken(response.user.token)
                self.clearTextFields()
                self.loginDelegate?.login(with: response)
            case .failure(let err):
                os_log("Failed to retrieve workouts: %s", log: OSLog.default, type: .error, err.localizedDescription)
                self.displayAlert(title: "Something went wrong.", message: "We weren't able to log you in.")
            }
        })
    }

    @IBAction func userNameFieldDidChange(_ sender: UITextField) {
        updateLoginButtonState()
    }

    @IBAction func passwordFieldDidChange(_ sender: UITextField) {
        updateLoginButtonState()
    }

    private func updateLoginButtonState() {
        if let userText = usernameField.text,
            let passText = passwordField.text,
            userText.count > 1 && passText.count > 1 {
            loginButton.isEnabled = true
        } else {
            loginButton.isEnabled = false
        }
    }

    private func clearTextFields() {
        usernameField.text = nil
        passwordField.text = nil
    }
}
