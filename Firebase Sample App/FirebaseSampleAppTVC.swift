//
//  FirebaseSampleAppTVC.swift
//  Firebase Sample App
//
//  Created by Richard Gathogo on 27/01/2017.
//  Copyright © 2017 Richard Gathogo. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
struct EventFields {
    static let NAME = "name"
    static let START_DATE = "startdate"
    static let DESCRIPTION = "description"
    static let LOCATION = "location"
    static let USERID = "userid"
    static let POSTER_PATH = "poster_path"
}
class FirebaseSampleAppTVC: UITableViewController , UITextFieldDelegate{
    let tableViewCellIdentifier = "tableViewCell"
    let ADD_EVENT_SEGUE = "Add Event";
    var ref:FIRDatabaseReference!
    var _refHandle : FIRDatabaseHandle!
    var events : [FIRDataSnapshot]! = [];
    let dateFormatter = DateFormatter();
    override func viewDidLoad() {
        super.viewDidLoad()
        let eventCellNib = UINib(nibName: "EventCell", bundle: nil)
        self.tableView.register(eventCellNib, forCellReuseIdentifier: tableViewCellIdentifier)
        self.tableView.estimatedRowHeight = self.tableView.rowHeight;
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        configureDatabase();
        configureSignButton();
        dateFormatter.dateFormat = "yyyy-MM-dd hh:ss";
    }
    
    @IBOutlet weak var signInButton: UIBarButtonItem!
    @IBAction func signIn(_ sender: UIBarButtonItem) {
        if let _ = FIRAuth.auth()?.currentUser {
            do {
                try FIRAuth.auth()?.signOut();
                configureSignButton();
            }catch {
                
            }
        } else {
        let signInVC = UIAlertController(title: "Sign", message: "Sign", preferredStyle: .alert);
        signInVC.addTextField(configurationHandler: nil)
        signInVC.addTextField { (passwordField) in
            passwordField.isSecureTextEntry = true;
        }
        let action = UIAlertAction(title: "Sign In", style: .default) { (action) in
            //signIn Code an
            guard let email = signInVC.textFields?[0].text, let password = signInVC.textFields?[1].text else  {
                return
            }
            self.signInUser(email: email, password: password)
            
        }
        signInVC.addAction(action)
        present(signInVC, animated: true, completion: nil)
        }
    }
    
    

    @IBAction func addEvent(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: ADD_EVENT_SEGUE, sender: nil)
    }
    func configureDatabase()  {
        self.ref = FIRDatabase.database().reference();
        self._refHandle = self.ref.child("events").queryOrdered(byChild: "startdate").observe(.childAdded, with: { [weak self] (snapshot) in
            guard let strongSelf = self else {return}
            strongSelf.events.append(snapshot);
            strongSelf.tableView.insertRows(at: [IndexPath(row:strongSelf.events.count-1,section:0)], with: .automatic);
        })
    }
    func configureSignButton(){
        if let _ = FIRAuth.auth()?.currentUser {
            signInButton.title = "Sign Out";
        } else {
            signInButton.title = "Sign In";
        }
    }
    func signInUser(email:String,password:String) {
        FIRAuth.auth()?.signIn(withEmail: email, password: password) {[weak self] (user, error) in
            print(error ?? "no error");
            if error == nil {
                guard let strongSelf = self else {return}
                strongSelf.configureSignButton();
            }
        }
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count;
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath) as! EventCell;
        let eventSnapShot = self.events[indexPath.row];
        let event = Event(event: eventSnapShot.value as! Dictionary<String,AnyObject>);
        cell.eventName?.text = event.name;
        cell.eventLocation?.text = event.location;
        let startDate = Date(timeIntervalSince1970: TimeInterval(event.startDate.doubleValue/1000))
        
        cell.eventStartDate.text = String(describing: dateFormatter.string(from: startDate))
        cell.eventDescription?.text = event.eventDescription;
        
        if let imageURL = event.posterPath {
            if imageURL.hasPrefix("gs://") {
                FIRStorage.storage().reference(forURL: imageURL).data(withMaxSize: INT64_MAX) { (data,error) in
                    if let error = error {
                        print("Error \(error.localizedDescription)")
                        return
                    }
                    let image = UIImage(data: data!);
                    let oldWidth = image!.size.width;
                    let scaleFactor = self.tableView.bounds.size.width/oldWidth;
                    let newHeight = image!.size.height * scaleFactor;
                    let newWidth = oldWidth * scaleFactor;
                    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight));
                    image?.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight));
                    let newImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    cell.eventImage.image = newImage;
                    
                }
            } else if let URL = URL(string:imageURL), let data = try? Data(contentsOf: URL){
                cell.eventImage.image = UIImage(data: data);
            }
        } else {
            cell.eventImage.image = nil;
        }
        
        return cell;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //prepare for segue
        if let addEventVC = segue.destination as? AddEventVC {
            addEventVC.ref = ref;
        }
    }
    

}
