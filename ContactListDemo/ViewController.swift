//
//  ViewController.swift
//  ContactListDemo
//
//  Created by Pragati Rode on 05/04/18.
//  Copyright © 2018 Pragati Rode. All rights reserved.
//

import UIKit
import Contacts


var selectedContactsArray = [EPContact]()


class ViewController: UIViewController, EPPickerDelegate {
    
    // let contactArray = EPContact()
    var contactFrom : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        
    }
    @IBAction func ShowButtonTapped(_ sender: Any) {
        let contactPickerScene = EPContactsPicker(delegate: self, multiSelection:true, subtitleCellType: SubtitleCellValue.phoneNumber)
        //        if selectedContactsArray.count > 0{
        //        contactPickerScene.selectedContacts = selectedContactsArray
        //        }
        let navigationController = UINavigationController(rootViewController: contactPickerScene)
        self.present(navigationController, animated: true, completion: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // To avoid the problem
        //search.dismiss(animated: false, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts : [EPContact])
    {
        
        selectedContactsArray = []
        print("The following contacts are selected")
        var msg : String = ""
        for contact in contacts {
            
            print("\(contact.displayName())")
            // print("ContactId ==>\(contact.contactId)")
            print("\(contact.phoneNumbers)")
            
            for phonenumber in contact.phoneNumbers
            {
                msg += "\n \(contact.displayName()) : \(phonenumber.phoneNumber)"
            }
            
            
            let con = CNMutableContact()
            
            con.givenName = contact.firstName//""
            // con.familyName = //"Appleseed"
            con.phoneNumbers.append(CNLabeledValue(
                label: "Mobile", value: CNPhoneNumber(stringValue: contact.phoneNumbers[0].phoneNumber)))
            
            let newcontact: EPContact
            newcontact = EPContact(contact: con)
            print(newcontact)
            
            selectedContactsArray.append(newcontact)
            
        }
        print(selectedContactsArray)
        let  alertController = UIAlertController(title: "Alert", message:msg, preferredStyle: UIAlertControllerStyle.alert)
        let alertActionOk = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertActionOk)
        
        self.present(alertController, animated: true)
        
    }
    
    
    
    @IBAction func buttonTapped(_ sender: Any) {
        if selectedContactsArray.count > 0{
            
            
            let contactPickerScene = EPContactsPicker(delegate: self, multiSelection:true, subtitleCellType: SubtitleCellValue.phoneNumber)
            //contactFrom = "selected"
            contactPickerScene.strFrom = true
            contactPickerScene.selectedContacts = selectedContactsArray
            let navigationController = UINavigationController(rootViewController: contactPickerScene)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    
}

