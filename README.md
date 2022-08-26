## What is FCL?

The Flow Client Library (FCL) JS is a package used to interact with user wallets and the Flow blockchain. When using FCL for authentication, dapps are able to support all FCL-compatible wallets on Flow and their users without any custom integrations or changes needed to the dapp code.

For more description please refer to [fcl.js](https://github.com/onflow/fcl-js)

---
## Getting Started

### Requirements
-  Swift version >= 5.6
-  iOS version >= 13

## Installation

### CocoaPods

FCL-SDK is available through [CocoaPods](https://cocoapods.org). You can only include specific subspec to install, simply add the following line to your Podfile:

```ruby
pod 'FCL-SDK', '~> 0.1.2'
```

### Swift Package Manager


```swift
.package(url: "https://github.com/portto/fcl-swift", .upToNextMinor(from: "0.1.2"))
```

Here's an example PackageDescription:

```swift
// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "MyPackage",
    products: [
        .library(
            name: "MyPackage",
            targets: ["MyPackage"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/portto/fcl-swift", .upToNextMinor(from: "0.1.2"))
    ],
    targets: [
        .target(
            name: "MyPackage",
            dependencies: [
                .product(name: "FCL_SDK", package: "fcl-swift"),
            ]
        )
    ]
)
```
#### Importing

```swift
import FCL_SDK
```
---
## FCL for Dapps
#### Configuration

Just simply specify `network` and add those instanse conform to protocol `WalletProvider` and put they into config option `supportedWalletProviders` then you are good to go.

```swift
import FCL_SDK

do {
    let bloctoWalletProvider = try BloctoWalletProvider(
        bloctoAppIdentifier: bloctoSDKAppId,
        window: nil,
        testnet: !isProduction
    )
    fcl.config
        .put(.network(.testnet))
        .put(.supportedWalletProviders(
            [
                bloctoWalletProvider,
            ]
        ))
} catch {
    // handle error
}

Task {
    try await fcl.login()
}
```

> **Note**: bloctoSDKAppId can be found in [Blocto Developer Dashboard](https://developers.blocto.app/), for detail instruction please refer to [Blocto Docs](https://docs.blocto.app/blocto-sdk/register-app-id)

#### User Signatures

We can retrive user signatures only after user had logged in, otherwise error will be thrown.

```swift
Task {
    do {
        let signatures = try await fcl.signUserMessage(message: "message you want user to sign.")
    } catch {
        // handle error
    }
}
```

> **Note**: result signatures is array to satisfy custodial wallet usage. Message can be signed by several private key of same wallet address. Those signatures will be valid all together as long as their corresponding key weight sum up over 1000.

#### Blockchain Interactions
- *Query the chain*: Send arbitrary Cadence scripts to the chain and receive back decoded values
```swift
import FCL_SDK

let script = """
import ValueDapp from \(valueDappContract)

pub fun main(): UFix64 {
    return ValueDapp.value
}
"""

Task {
    let argument = try await fcl.query(script: script)
    label.text = argument.value.description
}
```
- *Mutate the chain*: Send arbitrary transactions with specify authorizer to perform state changes on chain. Payload signatures, fee payer and envelope signature should be handled by `WalletProvider`.
```swift
import FCL_SDK

Task { @MainActor in
    guard let userWalletAddress = fcl.currentUser?.address else {
        // handle error
        return
    }

    let scriptString = """
    import ValueDapp from 0x5a8143da8058740c

    transaction(value: UFix64) {
        prepare(authorizer: AuthAccount) {
            ValueDapp.setValue(value)
        }
    }
    """

    let argument = Cadence.Argument(.ufix64(10))

    let txHsh = try await fcl.mutate(
        cadence: scriptString,
        arguments: [argument],
        limit: 100,
        authorizers: [userWalletAddress]
    )
}
```

[Learn more about on-chain interactions >](https://docs.onflow.org/fcl/reference/api/#on-chain-interactions)

#### Prove ownership
To prove ownership of a wallet address there are to approaches.
- Account proof: in the beginning of authentication, there are accountProofData you can provider for user to sign and return generated signatures along with account address. 

`fcl.authanticate` is also called behide `fcl.login()` with accountProofData set to nil.

```swift
let address = try await fcl.authanticate(accountProofData: accountProofData)
```

- [User signature](#User-Signatures): provide specific message for user to sign and generate one or more signatures.

To verify above ownership, there are two utility functions define accordingly in [AppUtilities](https://github.com/portto/fcl-swift/blob/main/Sources/FCL-SDK/AppUtilities/AppUtilities.swift).

#### Utilities
- Get account details from any Flow address
- Get the latest block
- Transaction status polling
- Event polling
- Custom authorization functions

[Learn more about utilities >](https://docs.onflow.org/fcl/reference/api/#pre-built-interactions)


## Next Steps

Learn Flow's smart contract language to build any script or transactions: [Cadence](https://docs.onflow.org/cadence/).

Explore all of Flow [docs and tools](https://docs.onflow.org).


---
## FCL for Wallet Providers
Wallet providers on Flow have the flexibility to build their user interactions and UI through a variety of ways:
- Native app intercommunication via Universal links or custom schemes.
- Back channel communication via HTTP polling with webpage button approving.

FCL is agnostic to the communication channel and be configured to create both custodial and non-custodial wallets. This enables users to interact with wallet providers both native app install or not.

The communication channels involve responding to a set of pre-defined FCL messages to deliver the requested information to the dapp.  Implementing a FCL compatible wallet on Flow is as simple as filling in the responses with the appropriate data when FCL requests them.


### Current Wallet Providers
- [Blocto](https://blocto.portto.io/en/) (fully supported)
- [Dapper Wallet](https://www.meetdapper.com/) (support only authn for now)
- [Ledger](https://ledger.com) (not yet supported)
- [Lilico Wallet](https://lilico.app/) (not yet supported)

### Wallet Discovery
It can be difficult to get users to discover new wallets on a chain.
- Dapps can display and support all FCL compatible wallets who conform to `WalletProvider`.
- Users don't need to sign up for new wallets - they can carry over their existing one to any dapp that uses FCL for authentication and authorization.
- Wallet Discovery will be shown automatically when `login()` is being called only if more then one WalletProvider is specified.
[image]()
```swift
import FCL_SDK

do {
    let bloctoWalletProvider = try BloctoWalletProvider(
        bloctoAppIdentifier: bloctoSDKAppId,
        window: nil,
        testnet: !isProduction
    )
    let dapperWalletProvider = DapperWalletProvider.default
    fcl.config
        .put(.network(.testnet))
        .put(.supportedWalletProviders(
            [
                bloctoWalletProvider,
                dapperWalletProvider,
            ]
        ))
} catch {
    // handle error
}

Task {
    try await fcl.login()
}
```
Every walllet provider can use below property to customize icon, title and description.
```
var providerInfo: ProviderInfo { get }
```

### Building a FCL compatible wallet

- Read the [wallet guide](https://github.com/onflow/fcl-js/blob/master/packages/fcl/src/wallet-provider-spec/draft-v3.md) to understand the implementation details.
- Review the architecture of the [FCL dev wallet](https://github.com/onflow/fcl-dev-wallet) for an overview.
- If building a non-custodial wallet, see the [Account API](https://github.com/onflow/flow-account-api) and the [FLIP](https://github.com/onflow/flow/pull/727) on derivation paths and key generation.

---

## Support

Notice an problem or want to request a feature? [Add an issue](https://github.com/portto/fcl-swift/issues).

Discuss FCL with the community on the [forum](https://forum.onflow.org/c/developer-tools/flow-fcl/22).

Join the Flow community on [Discord](https://discord.gg/k6cZ7QC) to keep up to date and to talk to the team.