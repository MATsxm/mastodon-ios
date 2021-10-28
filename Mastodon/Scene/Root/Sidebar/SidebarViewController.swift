//
//  SidebarViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-22.
//

import os.log
import UIKit
import Combine
import CoreDataStack

protocol SidebarViewControllerDelegate: AnyObject {
    func sidebarViewController(_ sidebarViewController: SidebarViewController, didSelectTab tab: MainTabBarController.Tab)
}

final class SidebarViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    var viewModel: SidebarViewModel!
    
    weak var delegate: SidebarViewControllerDelegate?

    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.backgroundColor = .clear
            configuration.showsSeparators = false
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            switch sectionIndex {
            case 0:
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(100)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
            default:
                break
            }
            return section
        }
        return layout
    }
    
    let collectionView: UICollectionView = {
        let layout = SidebarViewController.createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.alwaysBounceVertical = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    static func createSecondaryLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.backgroundColor = .clear
            configuration.showsSeparators = false
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return section
        }
        return layout
    }
    
    let secondaryCollectionView: UICollectionView = {
        let layout = SidebarViewController.createSecondaryLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = false
        collectionView.alwaysBounceVertical = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    var secondaryCollectionViewHeightLayoutConstraint: NSLayoutConstraint!
}

extension SidebarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupBackground(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackground(theme: theme)
            }
            .store(in: &disposeBag)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        secondaryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(secondaryCollectionView)
        secondaryCollectionViewHeightLayoutConstraint = secondaryCollectionView.heightAnchor.constraint(equalToConstant: 44).priority(.required - 1)
        NSLayoutConstraint.activate([
            secondaryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            secondaryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: secondaryCollectionView.bottomAnchor),
            secondaryCollectionViewHeightLayoutConstraint,
        ])
        
        collectionView.delegate = self
        secondaryCollectionView.delegate = self
        viewModel.setupDiffableDataSource(
            collectionView: collectionView,
            secondaryCollectionView: secondaryCollectionView
        )
        
        secondaryCollectionView.observe(\.contentSize, options: [.initial, .new]) { [weak self] secondaryCollectionView, _ in
            guard let self = self else { return }
            let height = secondaryCollectionView.contentSize.height
            self.secondaryCollectionViewHeightLayoutConstraint.constant = height
            self.collectionView.contentInset.bottom = height
        }
        .store(in: &observations)
    }
    
    private func setupBackground(theme: Theme) {
        let color: UIColor = theme.sidebarBackgroundColor
        view.backgroundColor = color
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { context in
            self.collectionView.collectionViewLayout.invalidateLayout()
//            // do nothing
        } completion: { [weak self] context in
//            guard let self = self else { return }
        }

    }
    
}

// MARK: - UICollectionViewDelegate
extension SidebarViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case self.collectionView:
            guard let diffableDataSource = viewModel.diffableDataSource else { return }
            guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
            switch item {
            case .tab(let tab):
                delegate?.sidebarViewController(self, didSelectTab: tab)
            case .setting:
                guard let setting = context.settingService.currentSetting.value else { return }
                let settingsViewModel = SettingsViewModel(context: context, setting: setting)
                coordinator.present(scene: .settings(viewModel: settingsViewModel), from: self, transition: .modal(animated: true, completion: nil))
            case .compose:
                assertionFailure()
            }
        case secondaryCollectionView:
            guard let diffableDataSource = viewModel.secondaryDiffableDataSource else { return }
            guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
            switch item {
            case .compose:
                let composeViewModel = ComposeViewModel(context: context, composeKind: .post)
                coordinator.present(scene: .compose(viewModel: composeViewModel), from: self, transition: .modal(animated: true, completion: nil))
            default:
                assertionFailure()
            }
        default:
            assertionFailure()
        }
//        switch item {
//        case .tab(let tab):
//            delegate?.sidebarViewController(self, didSelectTab: tab)
//        case .searchHistory(let viewModel):
//            delegate?.sidebarViewController(self, didSelectSearchHistory: viewModel)
//        case .header:
//            break
//        case .account(let viewModel):
//            assert(Thread.isMainThread)
//            let authentication = context.managedObjectContext.object(with: viewModel.authenticationObjectID) as! MastodonAuthentication
//            context.authenticationService.activeMastodonUser(domain: authentication.domain, userID: authentication.userID)
//                .receive(on: DispatchQueue.main)
//                .sink { [weak self] result in
//                    guard let self = self else { return }
//                    self.coordinator.setup()
//                }
//                .store(in: &disposeBag)
//        case .addAccount:
//            coordinator.present(scene: .welcome, from: self, transition: .modal(animated: true, completion: nil))
//        }
    }
}
