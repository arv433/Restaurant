//
//  OrderTableViewController.swift
//  Restaurant
//
//  Created by Arvin Zojaji on 2018-12-02.
//  Copyright © 2018 Arvin Zojaji. All rights reserved.
//

import UIKit
import UserNotifications

class OrderTableViewController: UITableViewController {

    var orderMinutes = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem

        NotificationCenter.default.addObserver(tableView, selector: #selector(UITableView.reloadData), name: MenuController.orderUpdateNotification, object: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuController.shared.order.menuItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderCellIdentifier", for: indexPath)

        configure(cell, forItemAt: indexPath)

        return cell
    }

    func configure(_ cell: UITableViewCell, forItemAt indexPath: IndexPath) {
        let menuItem = MenuController.shared.order.menuItems[indexPath.row]
        cell.textLabel?.text = menuItem.name
        cell.detailTextLabel?.text = String(format: "$%.2f", menuItem.price)
        MenuController.shared.fetchImage(url: menuItem.imageUrl) { image in
            guard let image = image else { return }
            DispatchQueue.main.async {
                if let currentIndexPath = self.tableView.indexPath(for: cell), currentIndexPath != indexPath {
                    return
                }
                cell.imageView?.image = image
                cell.setNeedsLayout()
            }
        }
    }


    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
//            tableView.deleteRows(at: [indexPath], with: .fade)
            MenuController.shared.order.menuItems.remove(at: indexPath.row)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    @IBAction func submitTapped(_ sender: UIBarButtonItem) {
        let orderTotal = MenuController.shared.order.menuItems.reduce(0.0) {
            (result, menuItem) -> Double in
            return result + menuItem.price
        }
        let formattedOrder = String(format: "$%.2f", orderTotal)
        
        let alert = UIAlertController(title: "Confirm Order", message: "You are about to submit your order with a total of \(formattedOrder)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Submit", style: .default) {
            action in self.uploadOrder()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ConfirmationSegue" {
            let orderConfirmationViewController = segue.destination as! OrderConfirmationViewController
            orderConfirmationViewController.minutes = orderMinutes
        }
    }
    
    func uploadOrder() {
        let menuIds = MenuController.shared.order.menuItems.map { $0.id }
        MenuController.shared.submitOrder(forMenuIDs: menuIds) { (minutes) in
            DispatchQueue.main.async {
                if let minutes = minutes {
                    self.orderMinutes = minutes
                    self.performSegue(withIdentifier: "ConfirmationSegue", sender: nil)
                    self.setNotification(withMinutes: minutes)
                }
            }
        }
    }
    
    func setNotification(withMinutes minutes: Int) {
        // set content
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Your order will be ready soon"
        notificationContent.body = "10 minutes until your order is ready for pickup"
        notificationContent.sound = UNNotificationSound.default

        // create and schedule notification
        let triggerInterval = (Double(minutes) * 60.0) - 600.0
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerInterval, repeats: false)
        let notificationIdentifier = "UYLocalNotification"
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: notificationContent, trigger: notificationTrigger)
        MenuController.shared.notificationCenter.add(request) { (error) in
            if let error = error {
                print(error)
            } else {
                print("Request should probably be added to shared notifications center")
            }
        }
    }

    @IBAction func unwindToOrderList(segue: UIStoryboardSegue) {
        MenuController.shared.order.menuItems = []
    }
}
