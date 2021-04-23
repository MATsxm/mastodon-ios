//
//  ThreadMetaView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import UIKit

final class ThreadMetaView: UIView {
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.text = "Date"
        return label
    }()
    
    let reblogButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        button.setTitle("0 reblog", for: .normal)
        button.setTitleColor(Asset.Colors.Button.normal.color, for: .normal)
        button.setTitleColor(Asset.Colors.Button.normal.color.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    let favoriteButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
        button.setTitle("0 favorite", for: .normal)
        button.setTitleColor(Asset.Colors.Button.normal.color, for: .normal)
        button.setTitleColor(Asset.Colors.Button.normal.color.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ThreadMetaView {
    private func _init() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),
        ])
        
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(reblogButton)
        stackView.addArrangedSubview(favoriteButton)
        
        dateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        reblogButton.setContentHuggingPriority(.required - 2, for: .horizontal)
        favoriteButton.setContentHuggingPriority(.required - 1, for: .horizontal)
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ThreadMetaView_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            ThreadMetaView()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif
