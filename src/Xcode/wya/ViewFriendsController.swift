//
//  ViewFriendsController.swift
//  wya
//
//  Created by Ariel Peterson on 11/29/18.
//  Copyright © 2018 Zeeshan Khan. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation
import GoogleSignIn


var friends : [String] = []

class ViewFriendsController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var errorMessage = ""
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    let SERVER = "http://c02c0a92.ngrok.io"
    
    var friends : [String] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getFriends(user_name: "Ariel")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MyCell.self, forCellReuseIdentifier: "customcell")
        //tableView.register(Header.self, forHeaderFooterViewReuseIdentifier: "headerId")
        //tableView.sectionHeaderHeight = 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath) as! MyCell
        cell.nameLabel.text = friends[indexPath.item]
        cell.myViewFriendsController = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showNavigation", sender: self)
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "headerId")
    }
    
    func deleteCell(cell: UITableViewCell) {
        if let deletionIndexPath = tableView.indexPath(for: cell) {
            friends.remove(at: deletionIndexPath.row)
            tableView.deleteRows(at: [deletionIndexPath], with: .automatic)
        }
    }
    
    func getFriends(user_name: String)  {
        
        var friends : Array<String> = []
        dataTask?.cancel()
        let url_string = SERVER+"/getFriends?user_name="+user_name
        let url = NSURL(string: url_string)!
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        dataTask = defaultSession.dataTask(with: request as URLRequest) {
            data, response, error in
            defer { self.dataTask = nil }
            if let error = error {
                self.errorMessage += "DataTask error: " + error.localizedDescription + "\n"
                print(self.errorMessage)
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200
            {
                // data sent back from server is a json_object
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String:Array<String>]
                friends = (json?["friends"])!
                for friend in friends {
                    self.friends.append(friend)
                }
                print(response)
                self.tableView.reloadData()
            }
        }
        dataTask?.resume()
        
    }
}

class Header: UITableViewHeaderFooterView {
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "My Friends"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    func setupViews() {
        addSubview(nameLabel)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[v0]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["v0": nameLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["v0": nameLabel]))
        
    }
    
}

class MyCell : UITableViewCell {
    
    var myViewFriendsController: ViewFriendsController?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Sample Item"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    func setupViews() {
        addSubview(nameLabel)
        addSubview(actionButton)
        
        actionButton.addTarget(self, action: Selector(("handleAction")), for: .touchUpInside)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[v0]-8-[v1(80)]-8-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["v0": nameLabel, "v1": actionButton]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["v0": nameLabel]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["v0": actionButton]))
        
    }
    
    func handleAction() {
        myViewFriendsController?.deleteCell(cell: self)
    }
}
