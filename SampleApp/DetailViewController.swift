//
//  DetailViewController.swift
//  SampleApp
//
//  Created by Plunien, Johannes(AWF) on 16/02/16.
//  Copyright © 2016 Johannes Plunien. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet private weak var detailLabel: UILabel!

    var detailLabelText: String?

    override func viewDidLoad() {
        self.detailLabel.text = self.detailLabelText
    }

}
