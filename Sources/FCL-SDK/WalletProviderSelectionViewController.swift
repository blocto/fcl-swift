//
//  WalletProviderSelectionViewController.swift
//  FCL-SDK
//
//  Created by Andrew Wang on 2022/8/24.
//

import Foundation
import UIKit

final class WalletProviderSelectionViewController: UIViewController {

    var onSelect: ((WalletProvider) -> Void)?
    var onCancel: (() -> Void)?

    private let providers: [WalletProvider]

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        view.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20).isActive = true
        stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        stackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select a wallet"
        label.font = .systemFont(ofSize: 24)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(nil, for: .normal)
        button.addTarget(self, action: #selector(self.onCancel(sender:)), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(providers: [WalletProvider]) {
        self.providers = providers
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(cancelButton)
        cancelButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        cancelButton.addSubview(containerView)
        containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 50).isActive = true
        containerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -50).isActive = true

        for (index, provider) in providers.enumerated() {
            let button = createProviderSelectionButton(from: provider.providerInfo, index: index)
            button.addTarget(self, action: #selector(onClicked(sender:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
    }

    private func createProviderSelectionButton(from info: ProviderInfo, index: Int) -> UIButton {
        let iconImage = UIImageView()
        if let iconURL = info.icon {
            let request = URLRequest(url: iconURL)
            URLSession(configuration: .default)
                .dataTask(with: request) { data, _, error in
                    if let error = error {
                        log(message: String(describing: error))
                        return
                    }
                    guard let data = data else {
                        log(message: "Icon image data not found.")
                        return
                    }

                    DispatchQueue.main.async {
                        iconImage.image = UIImage(data: data)
                    }
                }.resume()
        }
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 65).isActive = true
        button.tag = index
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 225 / 255, green: 225 / 255, blue: 225 / 255, alpha: 1).cgColor
        button.clipsToBounds = true
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.text = info.title

        button.addSubview(iconImage)

        let container = UIStackView()
        container.isUserInteractionEnabled = false
        container.axis = .vertical
        container.alignment = .leading
        container.distribution = .equalSpacing
        button.addSubview(container)

        container.addArrangedSubview(titleLabel)

        if let desc = info.desc {
            let descLabel = UILabel()
            descLabel.font = .systemFont(ofSize: 12)
            descLabel.textColor = .gray
            descLabel.text = desc
            container.addArrangedSubview(descLabel)
        }

        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconImage.topAnchor.constraint(equalTo: button.topAnchor, constant: 12).isActive = true
        iconImage.leftAnchor.constraint(equalTo: button.leftAnchor, constant: 12).isActive = true
        iconImage.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12).isActive = true
        iconImage.widthAnchor.constraint(equalTo: iconImage.heightAnchor).isActive = true

        container.translatesAutoresizingMaskIntoConstraints = false
        container.topAnchor.constraint(equalTo: button.topAnchor, constant: 12).isActive = true
        container.leftAnchor.constraint(equalTo: iconImage.rightAnchor, constant: 12).isActive = true
        container.rightAnchor.constraint(equalTo: button.rightAnchor, constant: -12).isActive = true
        container.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12).isActive = true
        return button
    }

    @objc
    private func onClicked(sender: UIButton) {
        cancelButton.isUserInteractionEnabled = false
        let index = sender.tag
        onSelect?(providers[index])
        onSelect = nil
        onCancel = nil
    }

    @objc
    private func onCancel(sender: UIButton) {
        cancelButton.isUserInteractionEnabled = false
        onCancel?()
        onCancel = nil
        onSelect = nil
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension WalletProviderSelectionViewController: UIAdaptivePresentationControllerDelegate {

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }

}
