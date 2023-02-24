//
//  FCL.swift
//
//
//  Created by Andrew Wang on 2022/6/24.
//

import Foundation
import FlowSDK
import Cadence
import AuthenticationServices
import GRPC

public let fcl: FCL = FCL()

func log(
    message: String
) {
    guard fcl.config.logging else { return }
    print("🚀 FCL: " + message)
}

public class FCL: NSObject {

    public let config = Config()
    public var delegate: FCLDelegate?

    var flowAPIClient: Client {
        get async throws {
            let task = Task(priority: .utility) {
                Client(network: config.network)
            }
            return await task.value
        }
    }

    private var webAuthSession: ASWebAuthenticationSession?
    private let requestSession = URLSession(configuration: .default)

    public var currentUser: User?

    override init() {
        super.init()
    }

    public func config(
        provider: WalletProvider
    ) {}

    public func login() async throws -> Address {
        try await authanticate(accountProofData: nil)
    }

    public func logout() {
        unauthenticate()
    }

    public func relogin() async throws -> Address {
        logout()
        return try await login()
    }

    // Authn
    public func authanticate(accountProofData: FCLAccountProofData?) async throws -> Address {
        do {
            let walletProvider: WalletProvider
            if let provider = config.selectedWalletProvider {
                walletProvider = provider
            } else {
                if config.walletProviderCandidates.isEmpty == false {
                    walletProvider = try await selectionProvider()
                    fcl.config.selectedWalletProvider = walletProvider
                } else {
                    throw FCLError.walletProviderNotSpecified
                }
            }
            try await walletProvider.authn(accountProofData: accountProofData)
            guard let user = currentUser else {
                throw FCLError.userNotFound
            }
            return user.address
        } catch {
            fcl.config.reset()
            throw error
        }
    }

    public func unauthenticate() {
        currentUser = nil
        config.reset()
    }

    public func reauthenticate(accountProofData: FCLAccountProofData?) async throws -> Address {
        unauthenticate()
        return try await authanticate(accountProofData: accountProofData)
    }

    // User signature
    public func signUserMessage(message: String) async throws -> [FCLCompositeSignature] {
        guard let walletProvider = config.selectedWalletProvider else {
            throw FCLError.walletProviderNotSpecified
        }
        return try await walletProvider.getUserSignature(message)
    }

    // MARK: - Routing

    public func continueForLinks(_ userActivity: NSUserActivity) {
        config.selectedWalletProvider?.continueForLinks(userActivity)
    }

    public func application(open url: URL) {
        config.selectedWalletProvider?.application(open: url)
    }

    // MARK: Internal

    func serviceOfType(type: ServiceType) throws -> Service? {
        guard let currentUser = currentUser else {
            throw FCLError.userNotFound
        }
        return currentUser.services.first(where: { $0.type == type })
    }

    func openWithWebAuthenticationSession(_ service: Service) throws {
        let request = try service.getURLRequest()

        guard let url = request.url else {
            throw FCLError.urlNotFound
        }

        log(message: "About to open ASWebAuthenticationSession with \(url.absoluteString)")

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: nil,
            completionHandler: { [weak self] _, _ in
                self?.webAuthSession?.cancel()
                self?.webAuthSession = nil
            }
        )

        session.presentationContextProvider = self

        webAuthSession = session

        let startsSuccessfully = session.start()
        if startsSuccessfully == false {
            throw FCLError.authenticateFailed
        }
    }

    func polling(service: Service, data: Data? = nil) async throws -> AuthResponse {
        let request = try service.getURLRequest(body: data)
        guard let type = service.type else {
            throw FCLError.serviceTypeNotFound
        }
        return try await pollingRequest(request, type: type)
    }

    func pollingRequest(_ request: URLRequest, type: ServiceType) async throws -> AuthResponse {
        let authnResponse: AuthResponse = try await requestSession.dataAuthnResponse(for: request)
        switch authnResponse.status {
        case .pending:
            switch type {
            case .authn,
                 .userSignature:
                guard let localView = authnResponse.local,
                      let backChannel = authnResponse.updates else {
                    throw FCLError.serviceError
                }
                let openBrowserTask = Task { @MainActor in
                    try openWithWebAuthenticationSession(localView)
                }
                _ = try await openBrowserTask.result.get()
                try await Task.sleep(seconds: 1)
                return try await polling(service: backChannel)
            case .authz:
                // blocto non custodial respond with updates.
                guard let localView = authnResponse.local,
                      let backChannel = authnResponse.authorizationUpdates ?? authnResponse.updates else {
                    throw FCLError.serviceError
                }
                let openBrowserTask = Task { @MainActor in
                    try openWithWebAuthenticationSession(localView)
                }
                _ = try await openBrowserTask.result.get()
                try await Task.sleep(seconds: 1)
                let backChannelRequest = try backChannel.getURLRequest()
                return try await pollingRequest(backChannelRequest, type: .backChannel)
            case .backChannel:
                if webAuthSession == nil {
                    throw FCLError.userCanceled
                }
                try await Task.sleep(seconds: 1)
                return try await pollingRequest(request, type: type)
            case .localView,
                 .preAuthz,
                 .openId,
                 .accountProof,
                 .authnRefresh:
                throw FCLError.serviceError
            }
        case .approved, .declined:
            Task { @MainActor in
                webAuthSession?.cancel()
                webAuthSession = nil
            }
            return authnResponse
        }
    }

    func buildUser(authn: AuthResponse) throws -> User {
        guard let address: String = authn.data?.address else {
            throw FCLError.authenticateFailed
        }
        return User(
            address: Address(hexString: address),
            accountProof: nil,
            loggedIn: true,
            expiresAt: 0,
            services: authn.data?.services ?? []
        )
    }

    func getKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter(\.isKeyWindow).first
    }

    @MainActor
    private func selectionProvider() async throws -> WalletProvider {
        guard let keyWindow = getKeyWindow() else {
            throw FCLError.walletProviderInitFailed
        }
        return try await withCheckedThrowingContinuation { continuation in
            let selectionViewController = WalletProviderSelectionViewController(providers: fcl.config.walletProviderCandidates)
            selectionViewController.presentationController?.delegate = selectionViewController
            selectionViewController.onSelect = { [weak selectionViewController] provider in
                selectionViewController?.dismiss(animated: true)
                continuation.resume(returning: provider)
            }
            selectionViewController.onCancel = { [weak selectionViewController] in
                selectionViewController?.dismiss(animated: true)
                continuation.resume(throwing: FCLError.userCanceled)
            }
            guard let topViewController = topViewController(from: keyWindow) else {
                continuation.resume(throwing: FCLError.walletProviderInitFailed)
                return
            }
            topViewController.present(selectionViewController, animated: true)
        }
    }

    private func topViewController(from window: UIWindow) -> UIViewController? {
        var topController: UIViewController? = window.rootViewController
        while let presentedViewController = window.rootViewController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }

}

// MARK: ASWebAuthenticationPresentationContextProviding

extension FCL: ASWebAuthenticationPresentationContextProviding {

    public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        delegate?.webAuthenticationContextProvider() ?? ASPresentationAnchor()
    }

}

// MARK: - Transaction Build

extension FCL {

    func send(_ builds: [TransactionBuild]) async throws -> Identifier {
        let ix = prepare(ix: Interaction(), builder: builds)

        let resolvers: [Resolver] = [
            CadenceResolver(),
            AccountsResolver(),
            RefBlockResolver(),
            SequenceNumberResolver(),
            SignatureResolver(),
        ]

        let interaction = try await pipe(ix: ix, resolvers: resolvers)
        return try await sendIX(ix: interaction)
    }

    func send(@FCL.TransactionBuilder builder: () -> [TransactionBuild]) async throws -> Identifier {
        try await send(builder())
    }

    func prepare(ix: Interaction, builder: [TransactionBuild]) -> Interaction {
        var newIX = ix

        builder.forEach { build in
            switch build {
            case let .transaction(script):
                newIX.tag = .transaction
                newIX.message.cadence = script
            case let .arguments(args):
                let fclArgs = args.toFCLArguments() // .compactMap { Flow.Argument(value: $0) }.toFCLArguments()
                newIX.message.arguments = Array(fclArgs.map(\.0))
                newIX.arguments = fclArgs.reduce(into: [:]) { $0[$1.0] = $1.1 }
            case let .computeLimit(gasLimit):
                newIX.message.computeLimit = gasLimit
            }
        }

        newIX = setComputeLimitIfNeeded(ix: newIX, builder: builder)

        newIX.status = .ok

        return newIX
    }

    private func setComputeLimitIfNeeded(ix: Interaction, builder: [TransactionBuild]) -> Interaction {
        var newIX = ix
        let computeLimitCase = builder.first(where: {
            if case .computeLimit = $0 {
                return true
            } else {
                return false
            }
        })

        if computeLimitCase == nil {
            newIX.message.computeLimit = fcl.config.computeLimit
        }
        return newIX
    }

}

public extension FCL {

    enum TransactionBuild {
        case transaction(script: String)
        case arguments([Cadence.Argument])
        case computeLimit(UInt64)

        // TODO: support custom proposer and authorizer
        /*
         case proposer(Transaction.ProposalKey)
         case payer([TransactionFeePayer])
         case authorizers([])
          */
    }

    @resultBuilder
    enum TransactionBuilder {
        public static func buildBlock() -> [TransactionBuild] { [] }

        public static func buildArray(_ components: [[TransactionBuild]]) -> [TransactionBuild] {
            components.flatMap { $0 }
        }

        public static func buildBlock(_ components: TransactionBuild...) -> [TransactionBuild] {
            components
        }
    }

}

extension FCL {

    /// Query the Flow Blockchain
    /// - Parameters:
    ///   - script: Cadence Script used to query Flow.
    ///   - arguments: Arguments passed to cadence script.
    /// - Returns: Cadence response Value from Flow Blockchain contract.
    public func query(
        script: String,
        arguments: [Cadence.Argument] = []
    ) async throws -> Cadence.Argument {
        let items = fcl.config.addressReplacements

        let newScript = items.reduce(script) { result, replacement in
            result.replacingOccurrences(of: replacement.placeholder, with: replacement.replacement.hexStringWithPrefix)
        }
        return try await fcl.flowAPIClient
            .executeScriptAtLatestBlock(
                script: Data(newScript.utf8),
                arguments: arguments
            )
    }

    /// As the current user Mutate the Flow Blockchain
    /// - Parameters:
    ///   - cadence: Cadence Transaction used to mutate Flow
    ///   - arguments: Arguments passed to cadence transaction
    ///   - limit: Compute Limit (gas limit) for transaction
    /// - Returns: Transaction id
    public func mutate(
        cadence: String,
        arguments: [Cadence.Argument] = [],
        limit: UInt64 = 1000,
        authorizers: [Cadence.Address]
    ) async throws -> Identifier {
        // not check accessNode.api here cause we already define it in Network's endpoint.
        guard let walletProvider = fcl.config.selectedWalletProvider else {
            throw FCLError.walletProviderNotSpecified
        }

        let items = fcl.config.addressReplacements
        let newCadence = items.reduce(cadence) { result, replacement in
            result.replacingOccurrences(of: replacement.placeholder, with: replacement.replacement.hexStringWithPrefix)
        }

        // TODO: support additional authorizers.
        return try await walletProvider.mutate(
            cadence: newCadence,
            arguments: arguments,
            limit: limit,
            authorizers: authorizers
        )
    }

    func pipe(ix: Interaction, resolvers: [Resolver]) async throws -> Interaction {
        var newInteraction = ix
        for resolver in resolvers {
            newInteraction = try await resolver.resolve(ix: newInteraction)
        }
        return newInteraction
    }

    func sendIX(ix: Interaction) async throws -> Identifier {
        let tx = try await ix.toFlowTransaction()
        return try await fcl.flowAPIClient.sendTransaction(transaction: tx)
    }

}

public extension FCL {

    func getEventsForHeightRange(
        eventType: String,
        startHeight: UInt64,
        endHeight: UInt64,
        options: CallOptions? = nil
    ) async throws -> [BlockEvents] {
        try await flowAPIClient
            .getEventsForHeightRange(eventType: eventType, startHeight: startHeight, endHeight: endHeight, options: options)
    }

    func getEventsForBlockIDs(
        eventType: String,
        blockIds: [Identifier],
        options: CallOptions? = nil
    ) async throws -> [BlockEvents] {
        try await flowAPIClient
            .getEventsForBlockIDs(eventType: eventType, blockIds: blockIds, options: options)
    }

    func getAccount(address: String) async throws -> FlowSDK.Account? {
        try await flowAPIClient
            .getAccountAtLatestBlock(address: Cadence.Address(hexString: address))
    }

    func getBlock(blockId: String) async throws -> FlowSDK.Block? {
        try await flowAPIClient
            .getBlockByID(blockId: Identifier(hexString: blockId))
    }

    func getLastestBlock(sealed: Bool = true) async throws -> FlowSDK.Block? {
        try await flowAPIClient
            .getLatestBlock(isSealed: sealed)
    }

    func getBlockHeader(blockId: String) async throws -> FlowSDK.BlockHeader? {
        try await flowAPIClient
            .getBlockHeaderById(blockId: Identifier(hexString: blockId))
    }

    func getTransactionStatus(transactionId: String) async throws -> FlowSDK.TransactionResult {
        try await flowAPIClient
            .getTransactionResult(id: Identifier(hexString: transactionId))
    }

    func getTransaction(transactionId: String) async throws -> FlowSDK.Transaction? {
        try await flowAPIClient
            .getTransaction(id: Identifier(hexString: transactionId))
    }

}
