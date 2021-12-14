//
//  Kin.swift
//  kin-ios-ramp-demo
//
//  Created by Richard Reitzfeld on 5/16/21.
//  Copyright © 2021 Richard Reitzfeld. All rights reserved.
//

import Foundation
import KinBase
import Promises

class Kin {
    
    private enum Constants {

        static let minAPIVersion: Int = 4
    }

    typealias KinBalanceBlock = (KinBalance) -> ()
    typealias KinPaymentBlock = ([KinPayment]) -> ()
        
    // MARK: - Private Properties
    
    private let isProduction: Bool
    private let appIndex: Int
    private let appAddress: String
    private let credentialUser: String
    private let credentialPassword: String
    private let onBalanceChanged: KinBalanceBlock?
    private let onPaymentHappened: KinPaymentBlock?
    private var kinAccountContext: KinAccountContext? = nil {
        didSet {
            setupListeners()
        }
    }
    private var disposeBag = DisposeBag()
    
    private lazy var kinEnvironment: KinEnvironment = {
        if isProduction {
            return KinEnvironment.Agora.mainNet(
                appInfoProvider: self,
                minApiVersion: Constants.minAPIVersion
            )
        } else {
            return KinEnvironment.Agora.testNet(
                appInfoProvider: self,
                enableLogging: true,
                minApiVersion: Constants.minAPIVersion
            )
        }
    }()
    
    // MARK: - Lifecycle
    
    /**
     Initializes a `Kin` object.
     
     - Parameter isProduction: Boolean indicating if  the `KinEnvironment` is in production or test
     - Parameter appIndex: App Index assigned by the Kin Foundation
     - Parameter appAddress: Blockchain address for the app in stellarBase32Encoded format ex: `GAYSJAFQ4WHU6OOGPNF3MULUMXHFBHTKN4M7O466VDGCY4GR5CV4LL6Q`
     - Parameter credentialUser: User id of `AppUserCredentials` sent to your webhook for authentication
     - Parameter credentialPassword: Password of `AppUserCredentials` sent to your webhook for authentication
     - Parameter onBalanceChanged: Callback to notify the app of balance changes
     - Parameter onPaymentHappened: Callback to notify the app of payment changes
    */
    init(isProduction: Bool,
         appIndex: Int,
         appAddress: String,
         credentialUser: String,
         credentialPassword: String,
         onBalanceChanged: KinBalanceBlock?,
         onPaymentHappened: KinPaymentBlock?) {
        self.isProduction = isProduction
        self.appIndex = appIndex
        self.appAddress = appAddress
        self.credentialUser = credentialUser
        self.credentialPassword = credentialPassword
        self.onBalanceChanged = onBalanceChanged
        self.onPaymentHappened = onPaymentHappened
        getContext()
    }
    
    // MARK: - Observation
    
    private func setupListeners() {
        watchBalance()
        watchPayments()
    }
    
    private func watchBalance() {
        guard let context = kinAccountContext else {
            assertionFailure("Should have a KinAccountContext")
            return
        }
        context
            .observeBalance()
            .subscribe({[weak self] balance in
                self?.onBalanceChanged?(balance)
            })
            .disposedBy(disposeBag)
    }
    
    private func watchPayments() {
        guard let context = kinAccountContext else {
            assertionFailure("Should have a KinAccountContext")
            return
        }
        context
            .observePayments()
            .subscribe({[weak self] payments in
                self?.onPaymentHappened?(payments)
            })
            .disposedBy(disposeBag)
    }
    
    // MARK: - Account Info
    
    /**
        Returns the account's public blockchain address
     */
    func address() -> String? {
        return kinAccountContext?.accountPublicKey.stellarID
    }

    /**
        Force the account to refresh in order to retrieve up to date balance information. Completion called on the main thread.
     */
    func checkBalance(completion: @escaping (Result<KinBalance, Error>) -> ()) {
        guard let context = kinAccountContext else {
            DispatchQueue.main.async {
                completion(.failure(KinError.contextNotInitialized))
            }
            return
        }
        context.getAccount(
            forceUpdate: true
        ).then(
            on: .main,
            { account in
                completion(.success(account.balance))
            }
        ).catch(
            on: .main,
            { (error) in
                completion(.failure(error))
            }
        )
    }
    
    // MARK: - Context
    
    private func getContext() {
        kinEnvironment
            .allAccountIds()
            .then { [weak self] ids in
                let accountId = ids.first ?? self?.createAccount()

                guard let id = accountId else {
                    throw KinError.couldNotGetIdForContext
                }
                
                self?.kinAccountContext = self?.getContext(for: id)
        }.catch { error in
            assertionFailure("Error getting context: \(error)")
        }
    }
    
    private func createAccount() -> PublicKey? {
        return try? KinAccountContext
            .Builder(env: kinEnvironment)
            .createNewAccount()
            .build()
            .accountPublicKey
    }
    
    private func getContext(for accountId: PublicKey) -> KinAccountContext {
        return KinAccountContext
            .Builder(env: kinEnvironment)
            .useExistingAccount(accountId)
            .build()
    }
    
    // MARK: - Payments
    
    /**
    Sends Kin to the designated address. Completion called on the main thread.
     - Parameter payments: List of items and costs in a single transaction.
     - Parameter address: Destination address
     - Parameter paymentType:`KinBinaryMemo.TransferType` of Earn, Spend or P2P (for record keeping)
     - Parameter completion: A closure called on success or failure of the send operation
     */
    func sendKin(payments: [KinPaymentInfo],
                 address: String,
                 paymentType: KinBinaryMemo.TransferType,
                 completion: @escaping (Result<KinPayment, Error>) -> ()) {

        guard let invoice = try? buildInvoice(payments: payments) else {
            DispatchQueue.main.async {
                completion(.failure(KinError.couldNotCreateInvoice))
            }
            return
        }
        
        guard let memo = try? buildMemo(invoice: invoice, transferType: paymentType) else {
            DispatchQueue.main.async {
                completion(.failure(KinError.couldNotCreateMemo))
            }
            return
        }
        
        let amount = invoiceTotal(payments: payments)

        guard let publicKey = PublicKey(stellarID: address) else {
            DispatchQueue.main.async {
                completion(.failure(KinError.couldNotParseAddress))
            }
            return
        }
        
        kinAccountContext?.sendKinPayment(
            KinPaymentItem(
                amount: amount,
                destAccount: publicKey,
                invoice: invoice
            ),
            memo: memo
        ).then(
            on: .main,
            { payment in
                completion(.success(payment))
            }
        ).catch(
            on: .main,
            { error in
                completion(.failure(error))
            }
        )
    }

    private func buildInvoice(payments: [KinPaymentInfo]) throws -> Invoice {
        let lineItems = try payments.map { payment in
            return try LineItem(
                title: payment.title,
                amount: Decimal(payment.amount)
            )
        }
        return try Invoice(lineItems: lineItems)
    }
    
    private func invoiceTotal(payments: [KinPaymentInfo]) -> Decimal {
        return payments.map { Decimal($0.amount) }.reduce(0, +)
    }
    
    private func buildMemo(invoice: Invoice,
                           transferType: KinBinaryMemo.TransferType) throws -> KinMemo {
        let invoiceList = try InvoiceList(invoices: [invoice])

        let memo = try KinBinaryMemo(
            typeId: transferType.rawValue,
            appIdx: appInfo.appIdx.value,
            foreignKeyBytes: invoiceList.id.decode()
        )
        return memo.kinMemo
    }
}

// MARK: - AppInfoProvider

extension Kin: AppInfoProvider {
    
    var appInfo: AppInfo {
        return AppInfo(
            appIdx: AppIndex(value: UInt16(appIndex)),
            kinAccount: PublicKey(stellarID: appAddress) ?? .zero,
            name: Bundle.main.appName ?? "kin-ios-ramp-demo",
            appIconData: Bundle.main.appIconData ?? Data()
        )
    }
    
    func getPassthroughAppUserCredentials() -> AppUserCredentials {
        return AppUserCredentials(
            appUserId: credentialUser,
            appUserPasskey: credentialPassword
        )
    }
}

extension Kin {
    
    enum KinError: Error {
        
        case contextNotInitialized
        case couldNotGetIdForContext
        case couldNotCreateInvoice
        case couldNotCreateMemo
        case couldNotParseAddress
    }
    
    struct KinPaymentInfo {
        
        let amount: Double
        let title: String
    }
}

extension Bundle {
    var appIconData: Data? {
        guard let iconsDictionary = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last else { return nil }
        return UIImage(named: lastIcon)?.pngData()
    }
    
    var appName: String? {
        return infoDictionary?["CFBundleName"] as? String
    }
}
