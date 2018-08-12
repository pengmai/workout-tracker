//
//  UIViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-06-10.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit

extension UIViewController {
    func showActivityIndicator() -> UIVisualEffectView {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)

        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()

        effectView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        effectView.layer.masksToBounds = true
        activityIndicator.frame = CGRect(x: view.bounds.midX - 50, y: view.bounds.midY - 50, width: 100, height: 100)
        activityIndicator.startAnimating()
        effectView.contentView.addSubview(activityIndicator)
        view.addSubview(effectView)
        return effectView
    }

    func displayAlert(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }
}
