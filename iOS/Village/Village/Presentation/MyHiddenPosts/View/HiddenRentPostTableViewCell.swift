//
//  HiddenRentPostTableViewCell.swift
//  Village
//
//  Created by 박동재 on 2023/12/04.
//

import UIKit
import Combine

final class HiddenRentPostTableViewCell: UITableViewCell {
    
    let hideToggleSubject = PassthroughSubject<Bool, Never>()
    
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 16
        
        return imageView
    }()
    
    private let postTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .bold)
        
        return label
    }()
    
    private let postPriceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        
        return label
    }()
    
    private var postMuteButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.titleAlignment = .center
        configuration.baseBackgroundColor = .primary500
        var titleAttribute = AttributedString.init("숨김 해제")
        titleAttribute.font = .systemFont(ofSize: 12.0, weight: .bold)
        configuration.attributedTitle = titleAttribute
        
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(target, action: #selector(muteButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    private let hideOnString: AttributedString = {
        var titleAttribute = AttributedString.init("숨기기")
        titleAttribute.font = .systemFont(ofSize: 12.0, weight: .bold)
        return titleAttribute
    }()
    private let hideOffString: AttributedString = {
        var titleAttribute = AttributedString.init("숨김 해제")
        titleAttribute.font = .systemFont(ofSize: 12.0, weight: .bold)
        return titleAttribute
    }()
    
    @objc private func muteButtonTapped() {
        if postMuteButton.titleLabel?.text == "숨김 해제" {
            postMuteButton.configuration?.baseBackgroundColor = .black
            postMuteButton.configuration?.attributedTitle = hideOnString
            hideToggleSubject.send(false)
        } else {
            postMuteButton.configuration?.baseBackgroundColor = .primary500
            postMuteButton.configuration?.attributedTitle = hideOffString
            hideToggleSubject.send(true)
        }
    }
    
    
    func configureData(post: PostMuteResponseDTO) {
//        postTitleLabel.text = post.title
//        postPriceLabel.text = post.price?.priceText()
//        configureImage(url: post.images.first ?? "")
    }
    
    func configureImage(url: String) {
        Task {
            do {
                let data = try await APIProvider.shared.request(from: url)
                postImageView.image = UIImage(data: data)
            } catch let error {
                dump(error)
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("should not be called")
    }
    
    private func configureUI() {
        contentView.addSubview(postImageView)
        contentView.addSubview(postTitleLabel)
        contentView.addSubview(postMuteButton)
        
        configureConstraints()
    }
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            postImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            postImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            postImageView.widthAnchor.constraint(equalToConstant: 80),
            postImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        NSLayoutConstraint.activate([
            postTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -15),
            postTitleLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 20),
            postTitleLabel.widthAnchor.constraint(equalToConstant: 200)
        ])
        
        NSLayoutConstraint.activate([
            postPriceLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 15),
            postPriceLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 20)
        ])
        
        NSLayoutConstraint.activate([
            postMuteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            postMuteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
}
