//
//  LoginPageViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-08-20.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit

class LoginPageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    private lazy var pages: [UIViewController] = {
        return [
            self.getViewController(withIdentifier: "sbLogin"),
            self.getViewController(withIdentifier: "sbSignUp")
        ]
    }()

    private func getViewController(withIdentifier identifier: String) -> UIViewController {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier)
        if let controller = controller as? LoginViewController {
            controller.loginDelegate = self
        } else if let controller = controller as? SignupViewController {
            controller.loginDelegate = self
        }

        return controller
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else { return pages.last }

        guard pages.count > previousIndex else { return nil }

        return pages[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.index(of: viewController) else { return nil }

        let nextIndex = viewControllerIndex + 1

        guard nextIndex < pages.count else { return pages.first }

        guard pages.count > nextIndex else { return nil }

        return pages[nextIndex]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        if let firstViewController = pages.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Clear the text fields.
        guard let response = sender as? LoginResponse else {
            fatalError("Did not receive LoginResponse from sender")
        }
        guard let destination = segue.destination as? HomeViewController else {
            fatalError("Unable to retrieve target as ViewController")
        }

        destination.resp = response
    }

    @IBAction func returnToLoginPage(segue: UIStoryboardSegue) {
        Datastore.clearToken()
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }
    }
}

protocol LoginDelegate: class {
    func login(with response: LoginResponse)
}

extension LoginPageViewController: LoginDelegate {
    func login(with response: LoginResponse) {
        performSegue(withIdentifier: "ToHome", sender: response)
    }
}
