//
//  ContentView.swift
//  FCL_SwiftUI_Demo
//
//  Created by Andrew Wang on 2022/9/6.
//

import SwiftUI
import FlowSDK
import SafariServices

struct ContentView: View {

    @ObservedObject var viewModel = ViewModel()

    @State var showSafari = false

    var body: some View {
        NavigationView {
            Form {
                // Network selection
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }

                Section {
                    VStack {
                        Picker("network", selection: $viewModel.network) {
                            Text("testnet").tag(Network.testnet)
                            Text("mainnet-beta").tag(Network.mainnet)
                        }.onChange(of: viewModel.network) { newValue in
                            debugPrint(newValue)
                            viewModel.updateNetwork()
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                } header: {
                    Label("network", systemImage: "network")
                }

                // Request account
                Section {
                    Toggle("using account proof", isOn: $viewModel.usingAccountProof)

                    Button {
                        viewModel.authn(usingAccountProof: viewModel.usingAccountProof)
                    } label: {
                        Label("Request account", systemImage: "person.crop.circle")
                    }
                    viewModel.loginErrorMessage == nil
                        ? Text(viewModel.address?.hexStringWithPrefix ?? "").foregroundColor(.black)
                        : Text(viewModel.loginErrorMessage ?? "").foregroundColor(.red)

                    // explorer
                    if let address = viewModel.address {
                        if let url = ExplorerURLType.address(address.hexStringWithPrefix).url(network: viewModel.network) {
                            Button {
                                showSafari = true
                            } label: {
                                Label("Look up with flowscan", systemImage: "magnifyingglass")
                            }.sheet(isPresented: $showSafari) {
                                SafariView(url: url)
                            }
                        } else {
                            Text("url not found").foregroundColor(.red)
                        }
                    }

                    if viewModel.usingAccountProof,
                       viewModel.accountProof != nil {
                        HStack(alignment: .center) {
                            Button {
                                viewModel.verifyAccountProof()
                            } label: {
                                Label("Verify account proof", systemImage: "person.fill.checkmark")
                            }

                            if let valid = viewModel.accountProofValid {
                                valid
                                    ? Image(systemName: "checkmark.circle.fill")
                                    .renderingMode(.template)
                                    .foregroundColor(.blue)
                                    : Image(systemName: "xmark.circle.fill")
                                    .renderingMode(.template)
                                    .foregroundColor(.red)
                            }
                        }
                        if let errorMessage = viewModel.verifyAccountProofErrorMessage {
                            Text(errorMessage)
                        }
                    }
                } header: {
                    Label("Account", systemImage: "person.crop.circle.badge.questionmark")
                }

                // Sign message
                Section {
                    ZStack(alignment: .leading) {
                        if viewModel.signingMessage.isEmpty {
                            Text("input any message you want to sign.")
                                .foregroundColor(Color.gray)
                                .font(.system(.body))
                                .padding(.all)
                        }
                        TextEditor(text: $viewModel.signingMessage)
                            .foregroundColor(Color.gray)
                            .font(.system(.body))
                            .frame(height: 35)
                            .cornerRadius(10)
                            .overlay(textFieldBorder)
                            .padding([.top, .bottom], 10)
                    }
                    Button {
                        viewModel.signMessage(message: viewModel.signingMessage)
                    } label: {
                        Label("Sign message", systemImage: "pencil")
                    }
                    viewModel.signingErrorMessage == nil
                        ? Text(viewModel.userSignatures.map(\.signature).joined(separator: "\n\n"))
                        : Text(viewModel.signingErrorMessage ?? "").foregroundColor(.red)
                    if !viewModel.userSignatures.isEmpty {
                        HStack(alignment: .center) {
                            Button {
                                viewModel.verifySignature()
                            } label: {
                                Label("Verify signatures", systemImage: "mail.and.text.magnifyingglass")
                            }
                            if let valid = viewModel.signatureValid {
                                valid
                                    ? Image(systemName: "checkmark.circle.fill")
                                    .renderingMode(.template)
                                    .foregroundColor(.blue)
                                    : Image(systemName: "xmark.circle.fill")
                                    .renderingMode(.template)
                                    .foregroundColor(.red)
                            }
                        }
                        if let errorMessage = viewModel.verifySigningErrorMessage {
                            Text(errorMessage).foregroundColor(.red)
                        }
                    }
                } header: {
                    Label("Signing", systemImage: "pencil.and.outline")
                }

                // Blockchain interactions
                Section {
                    Button {
                        viewModel.getValue()
                    } label: {
                        Label("Get value", systemImage: "book")
                    }

                    viewModel.getValueErrorMessage == nil
                        ? Text(viewModel.onChainValue?.description ?? "")
                        : Text(viewModel.getValueErrorMessage ?? "").foregroundColor(.red)

                    ZStack(alignment: .leading) {
                        if viewModel.inputValue.isEmpty {
                            Text("input any number.")
                                .foregroundColor(Color.gray)
                                .font(.system(.body))
                                .padding(.all)
                        }
                        TextEditor(text: $viewModel.inputValue)
                            .foregroundColor(Color.gray)
                            .font(.system(.body))
                            .frame(height: 35)
                            .cornerRadius(10)
                            .overlay(textFieldBorder)
                            .padding([.top, .bottom], 10)
                            .keyboardType(.decimalPad)
                    }
                    Button {
                        viewModel.setValue(inputValue: viewModel.inputValue)
                    } label: {
                        Label("Send transaction", systemImage: "paperplane")
                    }

                    viewModel.setValueErrorMessage == nil
                        ? Text(viewModel.txHash ?? "")
                        : Text(viewModel.setValueErrorMessage ?? "").foregroundColor(.red)

                    if let txHash = viewModel.txHash {
                        Button {
                            viewModel.lookup(txHash: txHash)
                        } label: {
                            Label("Look up transaction status", systemImage: "hourglass")
                        }

                        viewModel.transactionStatusErrorMessage == nil
                            ? Text(viewModel.transactionStatus ?? "")
                            : Text(viewModel.transactionStatusErrorMessage ?? "").foregroundColor(.red)

                        if let url = ExplorerURLType.txHash(txHash).url(network: viewModel.network) {
                            Button {
                                showSafari = true
                            } label: {
                                Label("Look up with flowscan", systemImage: "magnifyingglass")
                            }.sheet(isPresented: $showSafari) {
                                SafariView(url: url)
                            }
                        } else {
                            Text("url not found").foregroundColor(.red)
                        }
                    }
                } header: {
                    Label("Blockchain interaction", systemImage: "paperplane.circle")
                }
            }
            .navigationTitle("FCL-Swift Demo")
        }
    }

    var textFieldBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.gray, lineWidth: 1)
    }

}

struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
