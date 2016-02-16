//
//  ViewController.swift
//  SampleApp
//
//  Created by Johannes Plunien on 15/02/16.
//  Copyright © 2016 Johannes Plunien. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1000
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let detailViewController = segue.destinationViewController as? DetailViewController else { return }
        guard let cell = sender as? UITableViewCell else { return }
        guard let indexPath = self.tableView.indexPathForCell(cell) else { return }
        detailViewController.detailLabelText = "Detail \(indexPath.row)"
    }

}
