//
//  EPContactsPicker.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 12/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit
import Contacts




public protocol EPPickerDelegate: class {
    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError)
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError)
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact)
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact])
}

public extension EPPickerDelegate {
    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error: NSError) { }
    func epContactPicker(_: EPContactsPicker, didCancel error: NSError) { }
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact) { }
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact]) { }
}

typealias ContactsHandler = (_ contacts : [CNContact] , _ error : NSError?) -> Void

public enum SubtitleCellValue{
    case phoneNumber
    case email
    case birthday
    case organization
}

open class EPContactsPicker: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    // MARK: - Properties
    
    open weak var contactDelegate: EPPickerDelegate?
    var contactsStore: CNContactStore?
    var resultSearchController = UISearchController()
    var orderedContacts = [String: [CNContact]]() //Contacts ordered in dicitonary alphabetically
    var sortedContactKeys = [String]()
    
    var selectedContacts = [EPContact]()
    
    var filteredContacts = [CNContact]()
    
    var subtitleCellValue = SubtitleCellValue.phoneNumber
    var multiSelectEnabled: Bool = false //Default is single selection contact
    var tableView11 = UITableView()
    var contactCount = Int()
    var phoneNumberArray = NSMutableArray()
    var phoneLabelArray = NSMutableArray()
    var alertController = UIAlertController()
    var selectedName = [String]()
    var strFrom : Bool = false
    // MARK: - Lifecycle Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.title = EPGlobalConstants.Strings.contactsTitle
        
        registerContactCell()
        inititlizeBarButtons()
        initializeSearchBar()
        reloadContacts()
        
        
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        //let index = NSIndexPath(row: 2, section: 0)
        //
        //        self.tableView.selectRow(at: index as IndexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
        //      //  self.tableView.delegate?.tableView!(self.tableView, cellForRowAt: index as IndexPath)
        //
        //      //  self.tableView(self.tableView, cellForRowAt: index as IndexPath)
        //        let cell: UITableViewCell = tableView.cellForRow(at: index as IndexPath)!
        //        cell.isSelected = true
        //       // cell.accessoryType = UITableViewCellAccessoryType.none
        //
        // if selectedContacts.count > 0{
        // self.tableView.delegate?.tableView!(self.tableView, didSelectRowAt: index as IndexPath)
        // }
    }
    func initializeSearchBar() {
        self.resultSearchController = ( {
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.delegate = self
            self.tableView.tableHeaderView = controller.searchBar
            return controller
        })()
    }
    
    func inititlizeBarButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(onTouchCancelButton))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        if multiSelectEnabled {
            let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(onTouchDoneButton))
            self.navigationItem.rightBarButtonItem = doneButton
            
        }
    }
    
    fileprivate func registerContactCell() {
        
        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: EPGlobalConstants.Strings.bundleIdentifier, withExtension: "bundle") {
            
            if let bundle = Bundle(url: bundleURL) {
                
                let cellNib = UINib(nibName: EPGlobalConstants.Strings.cellNibIdentifier, bundle: bundle)
                tableView.register(cellNib, forCellReuseIdentifier: "Cell")
            }
            else {
                assertionFailure("Could not load bundle")
            }
        }
        else {
            
            let cellNib = UINib(nibName: EPGlobalConstants.Strings.cellNibIdentifier, bundle: nil)
            tableView.register(cellNib, forCellReuseIdentifier: "Cell")
        }
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Initializers
    
    convenience public init(delegate: EPPickerDelegate?) {
        self.init(delegate: delegate, multiSelection: false)
    }
    
    convenience public init(delegate: EPPickerDelegate?, multiSelection : Bool) {
        self.init(style: .plain)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
    }
    
    convenience public init(delegate: EPPickerDelegate?, multiSelection : Bool, subtitleCellType: SubtitleCellValue) {
        self.init(style: .plain)
        self.multiSelectEnabled = multiSelection
        contactDelegate = delegate
        subtitleCellValue = subtitleCellType
    }
    
    
    // MARK: - Contact Operations
    
    open func reloadContacts() {
        getContacts( {(contacts, error) in
            if (error == nil) {
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
        })
    }
    
    func getContacts(_ completion:  @escaping ContactsHandler) {
        if contactsStore == nil {
            //ContactStore is control for accessing the Contacts
            contactsStore = CNContactStore()
        }
        let error = NSError(domain: "EPContactPickerErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "No Contacts Access"])
        
        switch CNContactStore.authorizationStatus(for: CNEntityType.contacts) {
        case CNAuthorizationStatus.denied, CNAuthorizationStatus.restricted:
            //User has denied the current app to access the contacts.
            
            let productName = Bundle.main.infoDictionary!["CFBundleName"]!
            
            let alert = UIAlertController(title: "Unable to access contacts", message: "\(productName) does not have access to contacts. Kindly enable it in privacy settings ", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {  action in
                completion([], error)
                self.dismiss(animated: true, completion: {
                    self.contactDelegate?.epContactPicker(self, didContactFetchFailed: error)
                })
            })
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            
        case CNAuthorizationStatus.notDetermined:
            //This case means the user is prompted for the first time for allowing contacts
            contactsStore?.requestAccess(for: CNEntityType.contacts, completionHandler: { (granted, error) -> Void in
                //At this point an alert is provided to the user to provide access to contacts. This will get invoked if a user responds to the alert
                if  (!granted ){
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion([], error! as NSError?)
                    })
                }
                else{
                    self.getContacts(completion)
                }
            })
            
        case  CNAuthorizationStatus.authorized:
            //Authorization granted by user for this app.
            var contactsArray = [CNContact]()
            
            let contactFetchRequest = CNContactFetchRequest(keysToFetch: allowedContactKeys())
            
            do {
                try contactsStore?.enumerateContacts(with: contactFetchRequest, usingBlock: { (contact, stop) -> Void in
                    //Ordering contacts based on alphabets in firstname
                    contactsArray.append(contact)
                    var key: String = "#"
                    //If ordering has to be happening via family name change it here.
                    if let firstLetter = contact.givenName[0..<1] , firstLetter.containsAlphabets() {
                        key = firstLetter.uppercased()
                    }
                    var contacts = [CNContact]()
                    
                    if let segregatedContact = self.orderedContacts[key] {
                        contacts = segregatedContact
                    }
                    contacts.append(contact)
                    self.orderedContacts[key] = contacts
                    
                })
                self.sortedContactKeys = Array(self.orderedContacts.keys).sorted(by: <)
                if self.sortedContactKeys.first == "#" {
                    self.sortedContactKeys.removeFirst()
                    self.sortedContactKeys.append("#")
                }
                completion(contactsArray, nil)
            }
                //Catching exception as enumerateContactsWithFetchRequest can throw errors
            catch let error as NSError {
                print(error.localizedDescription)
            }
            
        }
    }
    
    func allowedContactKeys() -> [CNKeyDescriptor]{
        //We have to provide only the keys which we have to access. We should avoid unnecessary keys when fetching the contact. Reducing the keys means faster the access.
        return [CNContactNamePrefixKey as CNKeyDescriptor,
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactBirthdayKey as CNKeyDescriptor,
                CNContactImageDataKey as CNKeyDescriptor,
                CNContactThumbnailImageDataKey as CNKeyDescriptor,
                CNContactImageDataAvailableKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
        ]
    }
    
    // MARK: - Table View DataSource
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == tableView11
        {
            if resultSearchController.isActive { return 1 }
            return 1
        }
        else
        {
            if resultSearchController.isActive { return 1 }
            return sortedContactKeys.count
        }
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == tableView11
        {
            //return 2
            if resultSearchController.isActive { return filteredContacts.count }
            return contactCount
        }
        else
        {
            if resultSearchController.isActive { return filteredContacts.count }
            if let contactsForSection = orderedContacts[sortedContactKeys[section]] {
                return contactsForSection.count
            }
        }
        return 0
    }
    
    // MARK: - Table View Delegates
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tableView11
        {
            let cell : UITableViewCell = tableView11.dequeueReusableCell(withIdentifier: "myCell")!
            
            //           // let cell1 = tableView.cellForRow(at: indexPath) as! EPContactCell
            //            //let selectedContact =  cell1.contact!
            //            for str in selectedContact.phoneNumbers
            //            {
            //            cell.textLabel?.text = str.phoneNumber
            //            }
            var str = phoneLabelArray[indexPath.row] as! String
            
            cell.textLabel?.text = "\(str.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()) : \(phoneNumberArray[indexPath.row] as! String)"
            // cell.detailTextLabel?.text = str
            return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! EPContactCell
            cell.accessoryType = UITableViewCellAccessoryType.none
            //Convert CNContact to EPContact
            let contact: EPContact
            
            if resultSearchController.isActive {
                contact = EPContact(contact: filteredContacts[(indexPath as NSIndexPath).row])
            } else {
                guard let contactsForSection = orderedContacts[sortedContactKeys[(indexPath as NSIndexPath).section]] else {
                    assertionFailure()
                    return UITableViewCell()
                }
                
                contact = EPContact(contact: contactsForSection[(indexPath as NSIndexPath).row])
            }
            if strFrom
            {
                for var i in 0..<contact.phoneNumbers.count{
                    if multiSelectEnabled && selectedContacts.contains(where: {$0.phoneNumbers[0].phoneNumber == contact.phoneNumbers[i].phoneNumber}) && selectedContacts.contains(where:{$0.firstName == contact.displayName()})
                    {
                        cell.accessoryType = UITableViewCellAccessoryType.checkmark
                    }
                }
            }else{
                
                if multiSelectEnabled  && selectedContacts.contains(where: { $0.contactId == contact.contactId }) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                }
            }
            
            cell.updateContactsinUI(contact, indexPath: indexPath, subtitleType: subtitleCellValue)
            return cell
        }
        
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        
        
        if tableView == tableView11
        {
            
            // UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath]
            let cell: UITableViewCell = tableView11.cellForRow(at: indexPath)!
            var selectednumber = cell.textLabel?.text as! String
            // selectednumber = selectednumber?.characters.split{$0 == " : "}.map(String.init)
            
            let selectednumberNew = selectednumber.components(separatedBy: " : ")
            
            //
            let con = CNMutableContact()
            
            con.givenName = selectedName[0]//""
            // con.familyName = //"Appleseed"
            con.phoneNumbers.append(CNLabeledValue(
                label: "Mobile", value: CNPhoneNumber(stringValue: selectednumberNew[1])))
            
            let newcontact: EPContact
            newcontact = EPContact(contact: con)
            print(newcontact)
            
            
            selectedContacts.append(newcontact)
            print("Selected Contacts \(selectedContacts)")
            
            alertController.dismiss(animated: true, completion: nil)
            // }
        }else{
            
            let cell = tableView.cellForRow(at: indexPath) as! EPContactCell
            let selectedContact =  cell.contact!
            if multiSelectEnabled {
                //Keeps track of enable=ing and disabling contacts
                if cell.accessoryType == UITableViewCellAccessoryType.checkmark {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                    
                    
                    
                    outerLoop: for i in 0..<selectedContacts.count
                    {
                        
                        
                        for conta in selectedContact.phoneNumbers{
                            let trimmedStringForPhoneNumber = conta.phoneNumber.replacingOccurrences(of: " ", with: "")
                            
                            for conta1 in  selectedContacts[i].phoneNumbers{
                                
                                let trimmedStringForPhoneNumber1 = conta1.phoneNumber.replacingOccurrences(of: " ", with: "")
                                
                                
                                if trimmedStringForPhoneNumber == trimmedStringForPhoneNumber1
                                {
                                    selectedContacts.remove(at: i)
                                    break outerLoop
                                }
                                //  break
                            }
                        }
                        
                    }
                    selectedContacts = selectedContacts.filter(){
                        
                        return selectedContact.contactId != $0.contactId
                    }
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                    print(selectedContact)
                    //SingleContact = selectedContact
                    contactCount = selectedContact.phoneNumbers.count
                    
                    phoneNumberArray = []
                    selectedName = []
                    phoneLabelArray = []
                    
                    for str in selectedContact.phoneNumbers
                    {
                        
                        phoneNumberArray.add(str.phoneNumber)
                        phoneLabelArray.add(str.phoneLabel)
                    }
                    
                    selectedName.append(selectedContact.displayName())
                    print(selectedName)
                    if resultSearchController.isActive {
                        
                        
                        
                    }
                    else{
                        createAlertController(title:"Select Contact Number", height: Int(self.view.frame.size.height/5))
                    }
                    
                    
                }
            }
            else {
                //Single selection code
                resultSearchController.isActive = false
                self.dismiss(animated: true, completion: {
                    DispatchQueue.main.async {
                        
                        self.contactDelegate?.epContactPicker(self, didSelectContact: selectedContact)
                    }
                })
            }
        }
        
    }
    
    
    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if tableView == tableView11
        {
            return 0
        }
        else
        {
            if resultSearchController.isActive { return 0 }
            tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: UITableViewScrollPosition.top , animated: false)
            return sortedContactKeys.index(of: title)!
        }
    }
    
    override  open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if tableView == tableView11
        {
            return nil
        }
        else
        {
            if resultSearchController.isActive { return nil }
            return sortedContactKeys
        }
    }
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == tableView11
        {
            return nil
        }
        else{
            
            if resultSearchController.isActive { return nil }
            return sortedContactKeys[section]
        }
    }
    
    // MARK: - Button Actions
    
    @objc func onTouchCancelButton() {
        dismiss(animated: true, completion: {
            self.contactDelegate?.epContactPicker(self, didCancel: NSError(domain: "EPContactPickerErrorDomain", code: 2, userInfo: [ NSLocalizedDescriptionKey: "User Canceled Selection"]))
        })
    }
    
    @objc func onTouchDoneButton() {
        dismiss(animated: true, completion: {
            self.contactDelegate?.epContactPicker(self, didSelectMultipleContacts: self.selectedContacts)
        })
    }
    
    // MARK: - Search Actions
    
    open func updateSearchResults(for searchController: UISearchController)
    {
        if let searchText = resultSearchController.searchBar.text , searchController.isActive {
            
            let predicate: NSPredicate
            if searchText.characters.count > 0 {
                predicate = CNContact.predicateForContacts(matchingName: searchText)
            } else {
                predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactsStore!.defaultContainerIdentifier())
            }
            
            let store = CNContactStore()
            do {
                filteredContacts = try store.unifiedContacts(matching: predicate,
                                                             keysToFetch: allowedContactKeys())
                //print("\(filteredContacts.count) count")
                self.contactDelegate?.epContactPicker(self, didSelectMultipleContacts: self.selectedContacts)
                self.tableView.reloadData()
                
            }
            catch {
                print("Error!")
            }
        }
    }
    
    open func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    // MARK: - Custom Function
    func createAlertController(title: String, height: Int)
    {
        if resultSearchController.isActive {
            
            
            
        }
        else{
            let vc = UIViewController()
            vc.preferredContentSize = CGSize(width: 250, height: height)
            
            //        var label = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: height))
            //        label.text = "Hello"
            tableView11 = UITableView(frame: CGRect(x: 0, y: 0, width: 250, height: height))
            tableView11.delegate = self
            tableView11.dataSource = self
            tableView11.register(UITableViewCell.self, forCellReuseIdentifier: "myCell")
            tableView11.backgroundColor = .clear
            vc.view.addSubview(tableView11)
            //   vc.view.addSubview(label)
            
            alertController = UIAlertController(title: title, message: "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.setValue(vc, forKey: "contentViewController")
            
            self.present(alertController, animated: true)
        }
    }
    
}
