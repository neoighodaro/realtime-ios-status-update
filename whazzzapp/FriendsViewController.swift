//
//  FriendsViewController.swift
//  whazzzapp
//
//  Created by Neo Ighodaro on 27/08/2017.
//  Copyright © 2017 CreativityKills Co. All rights reserved.
//

import UIKit
import PusherSwift
import Alamofire

class FriendsViewController: UITableViewController {
    
    var friends : [[String:String]] = []
    
    static let API_ENDPOINT = "http://localhost:4000";
    
    var username : String = ""
    
    var pusher : Pusher!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Random username
        username = "Anonymous" + String(Int(arc4random_uniform(1000)))

        // Set the title
        navigationItem.title = "Friends List"
        
        // Set the right button...
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Status",
            style: .plain,
            target: self,
            action: #selector(showPopup(_:))
        )
        
        // Listen for events
        listenForRealtimeEvents()
        
        // Update online presence
        let date = Date().addingTimeInterval(0)
        let timer = Timer(fireAt: date, interval: 1, target: self, selector: #selector(postOnlinePresence), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
    }
    
    public func postOnlinePresence() {
        let params: Parameters = ["username": username]
        
        Alamofire.request(FriendsViewController.API_ENDPOINT + "/online", method: .post, parameters: params).validate().responseJSON { response in
            switch response.result {
                
            case .success:
                _ = "Online"
            case .failure(let error):
                print(error)
            }
        }
    }
    
    public func postStatusUpdate(message: String) {
        let params: Parameters = ["username": username, "status": message]
        
        Alamofire.request(FriendsViewController.API_ENDPOINT + "/status", method: .post, parameters: params).validate().responseJSON { response in
            switch response.result {
                
            case .success:
                _ = "Updated"
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func listenForRealtimeEvents() {
        pusher = Pusher(key: "PUSHER_KEY", options: PusherClientOptions(host: .cluster("PUSHER_CLUSTER")))
        
        let channel = pusher.subscribe("new_status")
        let _ = channel.bind(eventName: "update", callback: { (data: Any?) -> Void in
            if let data = data as? [String: AnyObject] {
                let username = data["username"] as! String
                
                let status = data["status"] as! String
                
                let index = self.friends.index(where: { $0["username"] == username })
                
                if index != nil {
                    self.friends[index!]["status"] = status
                    self.tableView.reloadData()
                }
            }
        })
        
        let channel2 = pusher.subscribe("new_status")
        let _ = channel2.bind(eventName: "online", callback: { (data: Any?) -> Void in
            if let data = data as? [String: AnyObject] {
                let username = data["username"] as! String
                
                let index = self.friends.index(where: { $0["username"] == username })
                
                if username != self.username && index == nil {
                    self.friends.append(["username": username, "status": "No Status"])
                    self.tableView.reloadData()
                }
            }
        })
        
        pusher.connect()
    }
    
    // Show update popup
    public func showPopup(_ sender: Any) {
        let alertController = UIAlertController(
            title: "Update your status",
            message: "What would you like your status to say?",
            preferredStyle: .alert
        )
        
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.placeholder = "Status"
        })

        alertController.addAction(UIAlertAction(title: "Update", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            let status = (alertController.textFields?[0].text)! as String
            self.postStatusUpdate(message: status)
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friends", for: indexPath)

        var status   = friends[indexPath.row]["status"]
        
        if status == "" {
            status = "User has not updated status!"
        }
        
        cell.detailTextLabel?.textColor = UIColor.gray
        
        cell.imageView?.image = UIImage(named: "avatar.png")
        cell.textLabel?.text = friends[indexPath.row]["username"]
        cell.detailTextLabel?.text = status
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
}
