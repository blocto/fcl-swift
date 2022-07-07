//
//  BloctoSDK.swift
//  Alamofire
//
//  Created by Andrew Wang on 2022/3/10.
//

import UIKit
import AuthenticationServices

func log(enable: Bool, message: String) {
    guard enable else { return }
    print("BloctoSDK: " + message)
}

let responsePath: String = "/blocto"
let responseScheme: String = "blocto"

func customScheme(appId: String) -> String {
    responseScheme + appId
}

public class BloctoSDK {

    public static let shared: BloctoSDK = BloctoSDK()

    private var bloctoAssociatedDomain: String {
        if testnet {
            return "https://staging.blocto.app/"
        } else {
            return "https://blocto.app/"
        }
    }

    private var webBaseURLString: String {
        if testnet {
            return "https://wallet-testnet.blocto.app/"
        } else {
            return "https://wallet.blocto.app/"
        }
    }
    private let requestPath: String = "sdk"

    var requestBloctoBaseURLString: String {
        bloctoAssociatedDomain + requestPath
    }

    var webRequestBloctoBaseURLString: String {
        webBaseURLString + requestPath
    }

    var webCallbackURLScheme: String {
        "blocto"
    }

    var uuidToMethod: [UUID: Method] = [:]

    var appId: String = ""

    private var window: UIWindow = UIWindow()

    var logging: Bool = true

    var testnet: Bool = false

    var urlOpening: URLOpening = UIApplication.shared

    var sessioningType: AuthenticationSessioning.Type = ASWebAuthenticationSession.self

    /// initialize Blocto SDK
    /// - Parameters:
    ///   - appId: Registed id in https://developers.blocto.app/
    ///   - window: PresentationContextProvider of web SDK authentication.
    ///   - logging: Enabling log message, default is true.
    ///   - testnet: Determine which blockchain environment. e.g. testnet (Ethereum testnet, Solana devnet), mainnet (Ethereum mannet, Solana mainnet Beta)
    ///   - urlOpening: Handling url which opened app, default is UIApplication.shared.
    ///   - sessioningType: Type that handles web SDK authentication session, default is ASWebAuthenticationSession.
    @available(iOS 13.0, *)
    public func initialize(
        with appId: String,
        window: UIWindow,
        logging: Bool = true,
        testnet: Bool = false,
        urlOpening: URLOpening = UIApplication.shared,
        sessioningType: AuthenticationSessioning.Type = ASWebAuthenticationSession.self
    ) {
        self.appId = appId
        self.window = window
        self.logging = logging
        self.testnet = testnet
        self.urlOpening = urlOpening
        self.sessioningType = sessioningType
    }

    @available(iOS,
               introduced: 12.0,
               obsoleted: 13.0,
               message: "There is presentationContextProvider in system protocol ASWebAuthenticationSession start from iOS 13. Use initialize with window for webSDK instead.")
    public func initialize(
        with appId: String,
        logging: Bool = true,
        testnet: Bool = false,
        urlOpening: URLOpening = UIApplication.shared,
        sessioningType: AuthenticationSessioning.Type = ASWebAuthenticationSession.self
    ) {
        self.appId = appId
        self.logging = logging
        self.testnet = testnet
        self.urlOpening = urlOpening
        self.sessioningType = sessioningType
    }

    /// Entry of Universal Links
    /// - Parameter userActivity: the same userActivity from UIApplicationDelegate
    public func `continue`(_ userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else {
            log(
                enable: logging,
                message: "webpageURL not found.")
            return
        }
        guard url.path == responsePath else {
            log(
                enable: logging,
                message: "url path should be \(responsePath) rather than \(url.path).")
            return
        }
        log(
            enable: logging,
            message: "App get called by Universal Links: \(url)")
        methodResolve(url: url)
    }

    /// Entry of custom scheme
    /// - Parameters:
    ///   - app: UIApplication
    ///   - url: custom scheme URL
    ///   - options: options from UIApplicationDelegate
    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]
    ) {
        do {
            try checkConfigration()
            guard url.scheme == customScheme(appId: appId) else {
                log(
                    enable: logging,
                    message: "url scheme should be \(responseScheme) rather than \(String(describing: url.scheme)).")
                return
            }
            log(
                enable: logging,
                message: "App get called by custom scheme: \(url)")
            methodResolve(url: url)
        } catch {
            log(
                enable: logging,
                message: "error: \(error) when opened by \(url)")
        }
    }

    /// Send pre-defined method
    /// - Parameter method: Any method which conform to Method protocol
    public func send(method: Method) {
        do {
            try checkConfigration()
            guard let requestURL = try method.encodeToURL(
                appId: appId,
                baseURLString: requestBloctoBaseURLString) else {
                    method.handleError(error: InternalError.encodeToURLFailed)
                    return
                }
            uuidToMethod[method.id] = method
            urlOpening.open(
                requestURL,
                options: [.universalLinksOnly: true],
                completionHandler: { [weak self] opened in
                    guard let self = self else { return }
                    if opened {
                        log(
                            enable: self.logging,
                            message: "open universal link \(requestURL) successfully.")
                    } else {
                        log(
                            enable: self.logging,
                            message: "can't open universal link \(requestURL).")
                        if #available(iOS 13.0, *) {
                            self.routeToWebSDK(window: self.window, method: method)
                        } else {
                            self.routeToWebSDK(method: method)
                        }
                    }
                })
        } catch {
            method.handleError(error: error)
            routeToWebSDK(window: window, method: method)
        }
    }

    private func checkConfigration() throws {
        guard appId.isEmpty == false else { throw BloctoSDKError.appIdNotSet }
    }

    private func routeToWebSDK(
        window: UIWindow? = nil,
        method: Method
    ) {
        do {
            guard let requestURL = try method.encodeToURL(
                appId: appId,
                baseURLString: webRequestBloctoBaseURLString) else {
                    method.handleError(error: InternalError.encodeToURLFailed)
                    return
                }
            var session: AuthenticationSessioning?

            session = sessioningType.init(
                url: requestURL,
                callbackURLScheme: webCallbackURLScheme,
                completionHandler: { [weak self] callbackURL, error in
                    guard let self = self else { return }
                    if let error = error {
                        log(
                            enable: self.logging,
                            message: error.localizedDescription)
                    } else if let callbackURL = callbackURL {
                        self.methodResolve(expectHost: nil, url: callbackURL)
                    } else {
                        log(
                            enable: self.logging,
                            message: "callback URL not found.")
                    }
                    session = nil
                })

            if #available(iOS 13.0, *) {
                session?.presentationContextProvider = window
            }

            log(
                enable: logging,
                message: "About to route to Web SDK \(requestURL).")
            let startsSuccessfully = session?.start()
            if startsSuccessfully == false {
                method.handleError(error: InternalError.webSDKSessionFailed)
            }
        } catch {
            method.handleError(error: error)
        }
    }

    private func methodResolve(
        expectHost: String? = nil,
        url: URL
    ) {
        if let expectHost = expectHost {
            guard url.host == expectHost else {
                log(
                    enable: logging,
                    message: "\(url.host ?? "host is nil") should be \(expectHost)")
                return
            }
        }
        guard let urlComponents = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false) else {
                log(
                    enable: logging,
                    message: "urlComponents not found.")
                return
            }
        guard let uuid = urlComponents.getRequestId() else {
            log(
                enable: logging,
                message: "\(QueryName.requestId.rawValue) not found.")
            return
        }
        guard let method = uuidToMethod[uuid] else {
            log(
                enable: logging,
                message: "\(QueryName.method.rawValue) not found.")
            return
        }
        method.resolve(components: urlComponents, logging: logging)
    }

}
