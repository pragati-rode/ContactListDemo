//
//  ViewController.swift
//  ContactListDemo
//
//  Created by Pragati Rode on 05/04/18.
//  Copyright © 2018 Pragati Rode. All rights reserved.
//

import UIKit




class ViewController: UIViewController, EPPickerDelegate {

   // let contactArray = EPContact()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
      
    
    
    }
    @IBAction func ShowButtonTapped(_ sender: Any) {
        let contactPickerScene = EPContactsPicker(delegate: self, multiSelection:true, subtitleCellType: SubtitleCellValue.phoneNumber)
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

    }

    let  alertController = UIAlertController(title: "Alert", message:msg, preferredStyle: UIAlertControllerStyle.alert)
    let alertActionOk = UIAlertAction(title: "OK", style: .default, handler: nil)
    alertController.addAction(alertActionOk)

    self.present(alertController, animated: true)

    }


    
    
   
}

