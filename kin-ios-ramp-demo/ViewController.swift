//
//  ViewController.swift
//  kin-ios-ramp-demo
//
//  Created by Richard Reitzfeld on 5/16/21.
//  Copyright © 2021 Richard Reitzfeld. All rights reserved.
//

import UIKit
import KinBase
import Ramp

class ViewController: UIViewController {
    
    private enum Constants {
        static let exampleAppAddress: String = "GAYSJAFQ4WHU6OOGPNF3MULUMXHFBHTKN4M7O466VDGCY4GR5CV4LL6Q"
        static let exampleAppIndex: Int = 165
        static let credentialUser = "MyUser"
        static let credentialPassword = "MyPass"
        static let exampleSendAddress: String = "GA6CCT5IB4DJBR63BM3BQ7WB3M2UZ6QG6Z5XB64GSIABH6ICIETTAVU2"
    }

    @IBAction func showRamp(_ sender: UIButton) {
       let address = kin?.address()
       var configuration = Configuration()
       configuration.userAddress = address
       configuration.selectedCountryCode = "CA"
       configuration.swapAsset = "SOLANA_KIN"
       let ramp = try! RampViewController(configuration: configuration)
       ramp.delegate = self
       present(ramp, animated: true)
    }

    // MARK: - Private Properties
    
    private let accountLabel: UILabel = {
        let label = UILabel()
        label.text = "Account"
        label.numberOfLines = 0
        label.font = .boldSystemFont(ofSize: 25.0)
        label.textAlignment = .center
        return label
    }()
    
    private var accountLabelFrame: CGRect {
        accountLabel.sizeToFit()
        let width = view.bounds.width - 50.0
        let height = accountLabel.frame.height
        return CGRect(
            x: view.bounds.width / 2.0 - width / 2.0,
            y: view.safeAreaInsets.top,
            width: width,
            height: height
        )
    }
    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.text = "Account Balance"
        label.font = .systemFont(ofSize: 20.0, weight: .semibold)
        return label
    }()
    
    private var balanceLabelFrame: CGRect {
        balanceLabel.sizeToFit()
        let width = balanceLabel.frame.width
        let height = balanceLabel.frame.height
        return CGRect(
            x: view.bounds.width / 2.0 - width / 2.0,
            y: accountLabelFrame.maxY + 50.0,
            width: width,
            height: height
        )
    }
    
    private var balance: Decimal = 0.0 {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateBalanceLabel()
                self?.updateAccountLabel()
            }
        }
    }
    
    private let addToTestBalanceButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black
        button.setTitleColor(
            .white,
            for: .normal
        )
        button.setTitle(
            "Add To Balance",
            for: .normal
        )
        button.titleLabel?.textAlignment = .center
        button.addTarget(
            self,
            action: #selector(addToTestBalance),
            for: .touchUpInside
        )
        return button
    }()
    
    private var addToTestBalanceButtonFrame: CGRect {
        let width: CGFloat = 200.0
        let height: CGFloat = 50.0
        return CGRect(
            x: view.bounds.width / 2.0 - width / 2.0,
            y: balanceLabelFrame.maxY + 15.0,
            width: width,
            height: height
        )
    }
    
    private let sendKinButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black
        button.setTitleColor(
            .white,
            for: .normal
        )
        button.setTitleColor(
            .gray,
            for: .disabled
        )
        button.setTitle(
            "Send Kin",
            for: .normal
        )
        button.titleLabel?.textAlignment = .center
        button.addTarget(
            self,
            action: #selector(sendKin),
            for: .touchUpInside
        )
        return button
    }()
    
    private var sendKinButtonFrame: CGRect {
        let width: CGFloat = 200.0
        let height: CGFloat = 50.0
        return CGRect(
            x: view.bounds.width / 2.0 - width / 2.0,
            y: addToTestBalanceButtonFrame.maxY + 15.0,
            width: width,
            height: height
        )
    }
    
   private let getRamp: UIButton = {
            let button = UIButton()
            button.backgroundColor = .black
            button.setTitleColor(
                .white,
                for: .normal
            )
            button.setTitleColor(
                .gray,
                for: .disabled
            )
            button.setTitle(
                "Purchase Kin",
                for: .normal
            )
            button.titleLabel?.textAlignment = .center
            button.addTarget(
                self,
                action: #selector(showRamp),
                for: .touchUpInside
            )
            return button
        }()
        
        private var getRampButtonFrame: CGRect {
            let width: CGFloat = 200.0
            let height: CGFloat = 50.0
            return CGRect(
                x: view.bounds.width / 2.0 - width / 2.0,
                y: addToTestBalanceButtonFrame.maxY +  80.0,
                width: width,
                height: height
            )
        }

    private var kin: Kin?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(accountLabel)
        view.addSubview(balanceLabel)
        view.addSubview(addToTestBalanceButton)
        view.addSubview(sendKinButton)
        view.addSubview(getRamp)
        
        setupKin()        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        accountLabel.frame = accountLabelFrame
        balanceLabel.frame = balanceLabelFrame
        addToTestBalanceButton.frame = addToTestBalanceButtonFrame
        addToTestBalanceButton.layer.cornerRadius = addToTestBalanceButtonFrame.height / 2.0
        sendKinButton.frame = sendKinButtonFrame
        sendKinButton.layer.cornerRadius = sendKinButtonFrame.height / 2.0
        getRamp.frame = getRampButtonFrame
        getRamp.layer.cornerRadius = getRampButtonFrame.height / 2.0
    }
    
    func updateBalanceLabel() {
        balanceLabel.text = "Account Balance: \(balance)"

        view.setNeedsLayout()
    }
    
    func updateAccountLabel() {
        let address: String = {
            guard let address = kin?.address() else {
                return "None"
            }
            return address
        }()
        accountLabel.text = "Account: \n \(address)"

        view.setNeedsLayout()
    }

    @objc func addToTestBalance() {
        guard
            let address = kin?.address(),
            let url = URL(string: "https://kin-drops.herokuapp.com/?\(address)")
        else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) {[weak self] (data, response, error) in
            if let error = error {
                self?.show(error: error)
            } else {
                self?.checkKinBalance()
            }
        }

        task.resume()
    }
    
    func setupKin() {
        kin = Kin(
            isProduction: false,
            appIndex: Constants.exampleAppIndex,
            appAddress: Constants.exampleAppAddress,
            credentialUser: Constants.credentialUser,
            credentialPassword: Constants.credentialPassword,
            onBalanceChanged: { [weak self] balance in
                self?.balance = balance.amount
            },
            onPaymentHappened: { [weak self] payment in
                self?.checkKinBalance()
            }
        )
    }
    
    func checkKinBalance() {
        kin?.checkBalance { [weak self] result in
            switch result {
            case .success(let balance):
                self?.balance = balance.amount
            case .failure(let error):
                self?.show(error: error)
            }
        }
    }
    
    @objc func sendKin() {
        let payment1 = Kin.KinPaymentInfo(
            amount: 1.0,
            title: "For burgers"
        )
        
        let payment2 = Kin.KinPaymentInfo(
            amount: 1.0,
            title: "For even more burgers"
        )
        
        kin?.sendKin(
            payments: [payment1, payment2],
            address: Constants.exampleSendAddress,
            paymentType: .spend,
            completion: { [weak self] result in
                switch result {
                case .success(let payment):
                    self?.showSuccess(payment: payment)
                case .failure(let error):
                    self?.show(error: error)
                }
            }
        )
    }
    
    func showSuccess(payment: KinPayment) {
        let alert = UIAlertController(
            title: "Noice!",
            message: "You sent a payment! \n\nFrom: \(payment.sourceAccount.base58)\n\nTo: \(payment.destAccount.base58)\n\n Amount: \(payment.amount)",
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Okay",
                style: .default,
                handler: nil
            )
        )
        present(
            alert,
            animated: true,
            completion: nil
        )
    }
    
    func show(error: Error) {
        let alert = UIAlertController(
            title: "Oops!",
            message: "Looks like something went wrong. Here's a hint: \n\n Error: \(String(describing: error)) \n\n Description: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        

        alert.addAction(
            UIAlertAction(
                title: "Okay",
                style: .default,
                handler: nil
            )
        )
        present(
            alert,
            animated: true,
            completion: nil
        )
    }
}

extension ViewController: RampDelegate {
    func ramp(_ rampViewController: RampViewController, didCreatePurchase purchase: RampPurchase, purchaseViewToken: String, apiUrl: URL) {}
   func rampPurchaseDidFail(_ rampViewController: RampViewController) {}
   func rampDidClose(_ rampViewController: RampViewController) {}
}
