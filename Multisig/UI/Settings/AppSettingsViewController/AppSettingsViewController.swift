//
//  AppSettingsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 10.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

fileprivate protocol SectionItem {}

class AppSettingsViewController: UITableViewController {
    var notificationCenter = NotificationCenter.default
    var app = App.configuration.app
    var legal = App.configuration.legal

    private let tableBackgroundColor: UIColor = .primaryBackground
    private let sectionHeaderHeight: CGFloat = 28
    private var sections = [SectionItems]()

    private typealias SectionItems = (section: Section, items: [SectionItem])

    enum Section {
        case app
        case general
        case advanced

        enum App: SectionItem {
            case importKey(String)
            case importedKey(String, String)
            case passcode(String)
            case appearance(String)
        }

        enum General: SectionItem {
            case terms(String)
            case privacyPolicy(String)
            case licenses(String)
            case getInTouch(String)
            case rateTheApp(String)
            case appVersion(String, String)
            case network(String, String)
        }

        enum Advanced: SectionItem {
            case advanced(String)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = tableBackgroundColor
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
        tableView.separatorStyle = .singleLine

        tableView.registerCell(BasicCell.self)
        tableView.registerCell(ImportedKeyCell.self)
        tableView.registerCell(InfoCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        buildSections()

        notificationCenter.addObserver(
            self, selector: #selector(hidePresentedController), name: .ownerKeyImported, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.settingsApp)
    }

    private func buildSections() {
        let signingKey = App.shared.settings.signingKeyAddress
        sections = [
            (section: .app, items: [
                signingKey != nil ?
                    Section.App.importedKey("Imported owner key", signingKey!) :
                    Section.App.importKey("Import owner key"),
                Section.App.passcode("Passcode"),
                Section.App.appearance("Appearance"),
            ]),
            (section: .general, items: [
                Section.General.terms("Terms of use"),
                Section.General.privacyPolicy("Privacy policy"),
                Section.General.licenses("Licenses"),
                Section.General.getInTouch("Get in touch"),
                Section.General.rateTheApp("Rate the app"),
                Section.General.appVersion("App version", "\(app.marketingVersion) (\(app.buildVersion))"),
                Section.General.network("Network", app.network.rawValue),
            ]),
            (section: .advanced, items: [Section.Advanced.advanced("Advanced")])
        ]
    }

    @objc func hidePresentedController() {
        reload()
    }

    private func reload() {
        buildSections()
        tableView.reloadData()
    }

    // MARK: - Actions

    override func didTapAddressInfoDetails(_ sender: AddressInfoView) {
        removeImportedOwnerKey()
    }

    private func removeImportedOwnerKey() {
        let alertController = UIAlertController(
            title: nil,
            message: "Removing the owner key only removes it from this app. It doesn't delete any Safes from this app or from blockchain. For Safes controlled by this owner key, you will no longer be able to sign transactions in this app",
            preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            PrivateKeyController.removeKey()
            self?.reload()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }

    private func importOwnerKey() {
        let vc = ViewControllerFactory.importOwnerViewController(presenter: self)
        present(vc, animated: true)
    }

    private func openPasscode() {
        let vc = PasscodeSettingsViewController()
        show(vc, sender: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.App.importKey(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.App.importedKey(let name, let signingKey):
            return importedKeyCell(name: name, signingKey: signingKey, indexPath: indexPath)

        case Section.App.passcode(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.App.appearance(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.General.terms(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.General.privacyPolicy(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.General.licenses(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.General.getInTouch(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.General.rateTheApp(let name):
            return basicCell(name: name, indexPath: indexPath)

        case Section.General.appVersion(let name, let version):
            return infoCell(name: name, info: version, indexPath: indexPath)

        case Section.General.network(let name, let network):
            return infoCell(name: name, info: network, indexPath: indexPath)

        case Section.Advanced.advanced(let name):
            return basicCell(name: name, indexPath: indexPath)

        default:
            return UITableViewCell()
        }
    }

    private func basicCell(name: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
        cell.setTitle(name)
        return cell
    }

    private func infoCell(name: String, info: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(InfoCell.self, for: indexPath)
        cell.setTitle(name)
        cell.setInfo(info)
        cell.selectionStyle = .none
        return cell
    }

    private func importedKeyCell(name: String, signingKey: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ImportedKeyCell.self, for: indexPath)
        cell.setAddress(signingKey, label: name)
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.App.importKey(_):
            importOwnerKey()

        case Section.App.passcode:
            openPasscode()

        case Section.App.appearance(_):
            let appearanceViewController = ChangeDisplayModeTableViewController()
            show(appearanceViewController, sender: self)

        case Section.General.terms(_):
            openInSafari(legal.termsURL)

        case Section.General.privacyPolicy(_):
            openInSafari(legal.privacyURL)

        case Section.General.licenses(_):
            openInSafari(legal.licensesURL)

        case Section.General.getInTouch(_):
            let getInTouchVC = GetInTouchView()
            let hostingController = UIHostingController(rootView: getInTouchVC)
            show(hostingController, sender: self)

        case Section.General.rateTheApp(_):
            let url = App.configuration.contact.appStoreReviewURL
            UIApplication.shared.open(url, options: [:], completionHandler: nil)

        case Section.Advanced.advanced(_):
            let advancedVC = AdvancedAppSettings()
            let hostingController = UIHostingController(rootView: advancedVC)
            show(hostingController, sender: self)

        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        return view
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.App.importedKey(_, _):
            return UITableView.automaticDimension

        case Section.General.appVersion(_, _), Section.General.network(_, _):
            return InfoCell.rowHeight

        default:
            return BasicCell.rowHeight
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section].section
        switch section {
        case .general, .advanced:
            return sectionHeaderHeight
        default:
            return 0
        }
    }
}
