//
//  UIViewController+Extension.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 03/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlertFailure(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
}
