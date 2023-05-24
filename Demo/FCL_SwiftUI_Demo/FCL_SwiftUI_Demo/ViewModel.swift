//
//  ViewModel.swift
//  FCL_SwiftUI_Demo
//
//  Created by Andrew Wang on 2022/9/6.
//

import Foundation
import SwiftUI
import FCL_SDK
import FlowSDK
import Cadence
import BloctoSDK

class ViewModel: ObservableObject {

    @Published var network: Network = .testnet
    @Published var errorMessage: String?

    @Published var address: Cadence.Address?
    @Published var loginErrorMessage: String?
    @Published var usingAccountProof = false
    @Published var accountProof: AccountProofSignatureData?
    @Published var accountProofValid: Bool?
    @Published var verifyAccountProofErrorMessage: String?

    @Published var signingMessage: String = ""
    @Published var userSignatures: [FCLCompositeSignature] = []
    @Published var signingErrorMessage: String?
    @Published var signatureValid: Bool?
    @Published var verifySigningErrorMessage: String?

    @Published var onChainValue: Decimal?
    @Published var getValueErrorMessage: String?
    @Published var inputValue: String = ""
    @Published var txHash: String?
    @Published var setValueErrorMessage: String?
    @Published var transactionStatus: String?
    @Published var transactionStatusErrorMessage: String?

    private var accountProofAppName = "This is demo app."
    // minimum 32-byte random nonce as a hex string.
    private var nonce = "75f8587e5bd5f9dcc9909d0dae1f0ac5814458b2ae129620502cb936fde7120a"

    var bloctoSDKAppId: String {
        switch network {
        case .mainnet:
            return "0896e44c-20fd-443b-b664-d305b52fe8e8"
        case .testnet:
            return "0896e44c-20fd-443b-b664-d305b52fe8e8"
        case .canarynet,
             .emulator,
             .sandboxnet:
            return ""
        }
    }

    private var bloctoContract: String {
        switch network {
        case .mainnet:
            return "0xdb6b70764af4ff68"
        case .testnet:
            return "0x5b250a8a85b44a67"
        case .canarynet,
             .emulator,
             .sandboxnet:
            return ""
        }
    }

    private var valueDappContract: String {
        switch network {
        case .mainnet:
            return "0x8320311d63f3b336"
        case .testnet:
            return "0x5a8143da8058740c"
        case .canarynet,
             .emulator,
             .sandboxnet:
            return ""
        }
    }

    init() {
        setupFCL()
    }

    func updateNetwork() {
        _ = try? fcl.config
            .put(.network(network))
        setupFCL()
    }

    func authn(usingAccountProof: Bool) {
        address = nil
        accountProof = nil
        loginErrorMessage = nil
        verifyAccountProofErrorMessage = nil

        if usingAccountProof {
            /// 1. Authanticate like FCL
            let accountProofData = FCLAccountProofData(
                appId: accountProofAppName,
                nonce: nonce
            )
            Task { @MainActor in
                do {
                    address = try await fcl.authanticate(accountProofData: accountProofData)
                    accountProof = fcl.currentUser?.accountProof
                } catch {
                    loginErrorMessage = String(describing: error)
                }
            }
        } else {
            /// 2. request account only
            Task { @MainActor in
                do {
                    address = try await fcl.login()
                } catch {
                    loginErrorMessage = String(describing: error)
                }
            }
        }
    }

    func verifyAccountProof() {
        verifyAccountProofErrorMessage = nil
        accountProofValid = nil

        guard let accountProof = fcl.currentUser?.accountProof else {
            verifyAccountProofErrorMessage = "no account proof."
            return
        }

        Task { @MainActor in
            do {
                let valid = try await AppUtilities.verifyAccountProof(
                    appIdentifier: accountProofAppName,
                    accountProofData: accountProof,
                    fclCryptoContract: Address(hexString: bloctoContract)
                )
                accountProofValid = valid
            } catch {
                verifyAccountProofErrorMessage = String(describing: error)
                debugPrint(error)
            }
        }
    }

    func signMessage(message: String) {
        userSignatures = []
        signingErrorMessage = nil

        guard fcl.currentUser?.address.hexStringWithPrefix != nil else {
            signingErrorMessage = "User address not found. Please request account first."
            return
        }

        Task { @MainActor in
            do {
                let signatures = try await fcl.signUserMessage(message: message)
                userSignatures = signatures
            } catch {
                signingErrorMessage = String(describing: error)
            }
        }
    }

    func verifySignature() {
        signatureValid = nil
        verifySigningErrorMessage = nil

        guard userSignatures.isEmpty == false else {
            verifySigningErrorMessage = "signature not found."
            return
        }

        guard signingMessage.isEmpty == false else {
            verifySigningErrorMessage = "message must provided to verify signatures."
            return
        }

        Task { @MainActor in
            do {
                let valid = try await AppUtilities.verifyUserSignatures(
                    message: Data(signingMessage.utf8).bloctoSDK.hexString,
                    signatures: userSignatures,
                    fclCryptoContract: Address(hexString: bloctoContract)
                )
                signatureValid = valid
            } catch {
                verifySigningErrorMessage = String(describing: error)
            }
        }
    }

    func getValue() {
        onChainValue = nil
        getValueErrorMessage = nil

        let script = """
        import ValueDapp from \(valueDappContract)

        pub fun main(): UFix64 {
            return ValueDapp.value
        }
        """

        Task { @MainActor in
            do {
                let argument = try await fcl.query(script: script)
                onChainValue = try argument.value.toSwiftValue()
            } catch {
                getValueErrorMessage = String(describing: error)
            }
        }
    }

    func setValue(inputValue: String) {
        txHash = nil
        setValueErrorMessage = nil

        guard let userWalletAddress = fcl.currentUser?.address else {
            setValueErrorMessage = "User address not found. Please request account first."
            return
        }

        guard inputValue.isEmpty == false,
              let input = Decimal(string: inputValue) else {
            setValueErrorMessage = "Input not found."
            return
        }

        Task { @MainActor in
            do {

                let scriptString = """
                import ValueDapp from VALUE_DAPP_CONTRACT

                transaction(value: UFix64) {
                    prepare(authorizer: AuthAccount) {
                        ValueDapp.setValue(value)
                    }
                }
                """

                let argument = Cadence.Argument(.ufix64(input))

                let txHash = try await fcl.mutate(
                    cadence: scriptString,
                    arguments: [argument],
                    limit: 100,
                    authorizers: [userWalletAddress]
                )
                self.txHash = txHash.hexString
            } catch {
                setValueErrorMessage = String(describing: error)
            }
        }
    }

    func lookup(txHash: String) {
        transactionStatus = nil
        transactionStatusErrorMessage = nil

        Task { @MainActor in
            do {
                let result = try await fcl.getTransactionStatus(transactionId: txHash)
                transactionStatus = "status: \(String(describing: result.status ?? .unknown))\nerror message: \(result.errorMessage ?? "no error")"
            } catch {
                transactionStatusErrorMessage = String(describing: error)
            }
        }
    }

    private func setupFCL() {
        do {
            let bloctoWalletProvider = try BloctoWalletProvider(
                bloctoAppIdentifier: bloctoSDKAppId,
                window: nil,
                network: network
            )
            let dapperWalletProvider = DapperWalletProvider.default
            try fcl.config
                .put(.network(network))
                .put(.supportedWalletProviders(
                    [
                        bloctoWalletProvider,
                        dapperWalletProvider,
                    ]
                ))
                .put(.replace(placeHolder: "VALUE_DAPP_CONTRACT", with: Address(hexString: valueDappContract)))
        } catch {
            errorMessage = String(describing: error)
            debugPrint(error)
        }
    }
}
