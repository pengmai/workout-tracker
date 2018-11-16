//
//  SignupViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-08-20.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit
import os

class SignupViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!

    weak var loginDelegate: LoginDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        updateSignUpButtonState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Actions
    @IBAction func nameChanged(_ sender: UITextField) {
        updateSignUpButtonState()
    }

    @IBAction func passwordChanged(_ sender: UITextField) {
        updateSignUpButtonState()
    }

    @IBAction func confirmPasswordChanged(_ sender: UITextField) {
        updateSignUpButtonState()
    }

    @IBAction func goToLoginButtonPressed(_ sender: UIButton) {
        loginDelegate?.goToLoginPage()
    }

    @IBAction func goButtonPressed(_ sender: UITextField) {
        signUp()
    }

    @IBAction func signUpButtonPressed(_ sender: UIButton) {
        signUp()
    }

    private func signUp() {
        let activityIndicator = showActivityIndicator()
        guard let name = nameTextField.text, let password = passwordTextField.text else {
            return
        }

        Network.signUp(name: name, password: password, completion: { (result) in
            activityIndicator.removeFromSuperview()
            switch result {
            case .success(let response):
                // The server doesn't return the name of a newly signed up user
                let user = User(id: response.id, name: name, token: response.token)
                Datastore.saveToken(response.token)
                self.clearTextFields()
                self.loginDelegate?.login(with: LoginResponse(user: user, workouts: []))
            case .failure(let err):
                if let err = err as? HTTPError {
                    os_log("Failed to sign up new user: %{public}@", log: OSLog.default, type: .error, err.body)
                    switch err.code {
                    case 400:
                        self.displayAlert(title: "The name you selected is taken.", message: "Please try again with a different name.")
                        return
                    default:
                        break
                    }
                } else {
                    os_log("Failed to sign up new user: %{public}@", log: OSLog.default, type: .error, err.localizedDescription)
                }
                self.displayAlert(title: "Something went wrong.", message: "We were unable to create a profile for you. Please try again.")
            }
        })
    }

    private func updateSignUpButtonState() {
        if let name = nameTextField.text,
            let password = passwordTextField.text,
            let confirmPassword = confirmPasswordTextField.text,
            name.count > 1 && password.count > 1 && password == confirmPassword {
            signUpButton.isEnabled = true
        } else {
            signUpButton.isEnabled = false
        }
    }

    private func clearTextFields() {
        nameTextField.text = nil
        passwordTextField.text = nil
        confirmPasswordTextField.text = nil
    }
}
