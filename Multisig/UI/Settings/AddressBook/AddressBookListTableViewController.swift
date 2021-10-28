//
//  AddressbookListTableViewController.swift
//  Multisig
//
//  Created by Moaaz on 10/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import MobileCoreServices

class AddressBookListTableViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    private var chainEntries: Chain.ChainEntries = []
    private var menuButton: UIBarButtonItem!
    override var isEmpty: Bool {
        chainEntries.isEmpty
    }

    convenience init() {
        self.init(namedClass: LoadableViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Address Book"

        tableView.delegate = self
        tableView.dataSource = self

        tableView.registerCell(DetailAccountCell.self)
        tableView.registerHeaderFooterView(NetworkIndicatorHeaderView.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        emptyView.setText("There are no address book entries")
        emptyView.setImage(UIImage(named: "ico-no-address-book")!)

        menuButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(showOptionsMenu))
        navigationItem.rightBarButtonItem = menuButton

        for notification in [Notification.Name.selectedSafeChanged, .addressbookChanged] {
            NotificationCenter.default.addObserver(
                self, selector: #selector(reloadData), name: notification, object: nil)
        }

        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.addressbookList)
    }

    @objc private func showOptionsMenu() {
        let alertController = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet)
        let addEnityButton = UIAlertAction(title: "Add new entry", style: .default) { _ in
            self.didTapAddButton()
        }

        alertController.addAction(addEnityButton)

        let importEntryButton = UIAlertAction(title: "Import entries", style: .default) { [unowned self] _ in
            let pricker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeCommaSeparatedText)], in: .import)
            pricker.delegate = self
            pricker.allowsMultipleSelection = false
            self.present(pricker, animated: true, completion: nil)
        }

        alertController.addAction(importEntryButton)

        if let csv = AddressBookEntry.exportToCSV() {
            let exportEntryButton = UIAlertAction(title: "Export entries", style: .default) { [unowned self] _ in
                if let exportedFileURL = FileManagerWrapper.export(text: csv,
                                                                   fileName: "AddressBook",
                                                                   fileExtension: String(kUTTypeCommaSeparatedText)) {
                    let activityViewController : UIActivityViewController = UIActivityViewController(
                        activityItems: [exportedFileURL], applicationActivities: nil)

                    self.present(activityViewController, animated: true, completion: nil)
                }
            }

            alertController.addAction(exportEntryButton)
        }

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelButton)

        self.present(alertController, animated: true)
    }

    private func didTapAddButton() {
        let vc = SelectNetworkViewController()
        vc.screenTitle = "New Entry"
        vc.descriptionText = "Select network on which you want to add entry:"
        vc.completion = { [unowned self] chain  in
            let vc = CreateAddressBookEntryViewController()
            vc.chain = chain
            let ribbon = RibbonViewController(rootViewController: vc)
            ribbon.chain = vc.chain
            vc.completion = { (address, name)  in
                AddressBookEntry.create(address: address.checksummed, name: name, chainInfo: chain)
                NotificationCenter.default.post(name: .addressbookChanged, object: self, userInfo: nil)
                navigationController?.popToRootViewController(animated: true)
                self.reloadData()
                App.shared.snackbar.show(message: "Address book entry added")
            }
            self.show(ribbon, sender: self)
        }

        show(vc, sender: self)
    }
    
    @objc override func reloadData() {
        chainEntries = Chain.chainEntries()
        tableView.reloadData()
        onSuccess()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        chainEntries.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chainEntries[section].entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        let entry = chainEntries[indexPath.section].entries[indexPath.row]

        cell.setAccount(address: entry.addressValue, label: entry.name)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showEdit(entry: chainEntries[indexPath.section].entries[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entry = chainEntries[indexPath.section].entries[indexPath.row]

        var actions = [UIContextualAction]()
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, completion in
            showEdit(entry: chainEntries[indexPath.section].entries[indexPath.row])
            completion(true)
        }
        actions.append(editAction)

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] _, _, completion in
            self.remove(entry)
            completion(true)
        }
        actions.append(deleteAction)

        return UISwipeActionsConfiguration(actions: actions)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(NetworkIndicatorHeaderView.self)
        let chain = chainEntries[section].chain
        view.text = chain.name
        view.dotColor = chain.backgroundColor
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        NetworkIndicatorHeaderView.height
    }

    private func showEdit(entry: AddressBookEntry) {
        let defaultName = entry.name

        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.actionTitle = "Save"
        enterNameVC.descriptionText = "Choose a name for the entry. The name is only stored locally and will not be shared with Gnosis or any third parties."
        enterNameVC.screenTitle = "Enter entry Name"
        enterNameVC.trackingEvent = .addressbookEditEntry
        enterNameVC.placeholder = "Enter name"
        enterNameVC.name = defaultName
        enterNameVC.address = entry.addressValue
        enterNameVC.completion = { [unowned self, unowned entry, unowned notificationCenter] name in
            AddressBookEntry.update(entry.displayAddress, chainId: entry.chain!.id!, name: name)
            notificationCenter.post(name: .addressbookChanged, object: self, userInfo: nil)
            navigationController?.popViewController(animated: true)
            App.shared.snackbar.show(message: "Address book entry updated")
        }
        
        let ribbonVC = RibbonViewController(rootViewController: enterNameVC)

        show(ribbonVC, sender: nil)
    }

    private func remove(_ entry: AddressBookEntry) {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the entry key only removes it from this app.",
            preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
            AddressBookEntry.remove(entry: entry)
            App.shared.snackbar.show(message: "Address book entry removed")
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}

extension AddressBookListTableViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if let csv = FileManagerWrapper.importFile(url: url) {
            let result = AddressBookEntry.importFrom(csv: csv)
            App.shared.snackbar.show(message: "\(result.0) entries imported. \(result.1) entries updated")
        }
    }
}
