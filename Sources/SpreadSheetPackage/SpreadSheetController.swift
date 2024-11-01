//
//  SpreadSheetController.swift
//  SpreadSheetLikeView
//
//  Created by Daliborka Randjelovic on 7.10.24..
//

import UIKit
import SwiftUI

open class SpreadSheetController<ViewModel: SpreadSheetDataSourceAndDelegate, Item, RowHeader>: UIViewController, UICollectionViewDelegate, SelectionDelegate where Item: SpreadSheetItem, ViewModel.Item == Item, RowHeader: SpreadSheetItem, ViewModel.RowHeader == RowHeader {
    public typealias DataSource = UICollectionViewDiffableDataSource<RowHeader, Item>
    public let viewModel: ViewModel
    
    private let spreadSheetInfo: SpreadSheetLayoutInfo
    private let elementColorScheme: ElementColorScheme?
    private lazy var supplementaryHorizontalHeaderKind = "columnHeader"
    private static var CellIdentifier: String {
        "SpreadSheetCell"
    }
    private static var HorizontalHeaderIdentifier: String {
        "SpreadSheetHorizontalHeaderIdentifier"
    }
    private static var VerticalHeaderIdentifier: String {
        "SpreadSheetVerticalHeaderIdentifier"
    }
    private var selectedItem: Item?
    private var selectedHeader: RowHeader?
    private(set) lazy var dataSource: DataSource = setupDataSource()
    
    public init(viewModel: ViewModel, spreadSheetInfo: SpreadSheetLayoutInfo, elementColorScheme: ElementColorScheme? = nil) {
        self.viewModel = viewModel
        self.spreadSheetInfo = spreadSheetInfo
        self.elementColorScheme = elementColorScheme
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: setupLayout(for: self.supplementaryHorizontalHeaderKind))
        collectionView.delegate = self
        return collectionView
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        title = "SpreadSheet"
        setupView()
        setupConstraints()
        registerCollectionViewComponents()
        applySnapshot()
    }
    
    public func applySnapshot(animated: Bool = true, reload: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<RowHeader, Item>()
        let data = viewModel.generateData(spreadSheetInfo.numberOfColumns)
        snapshot.appendSections(data.map({ $0.rowItem }))
        for row in data {
            snapshot.appendItems(row.columns, toSection: row.rowItem)
        }
        if reload {
            dataSource.applySnapshotUsingReloadData(snapshot)
        } else {
            dataSource.apply(snapshot, animatingDifferences: animated)
        }
        selectedItem = nil
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        let previousSelectedItem = selectedItem
        selectedItem = item
        let previousSelectedHeader = selectedHeader
        selectedHeader = nil
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems(Set([selectedItem, previousSelectedItem]).compactMap({$0}))
        snapshot.reloadSections(Set([selectedHeader, previousSelectedHeader]).compactMap({ $0 }))
        dataSource.apply(snapshot)
        viewModel.select(of: item)
    }
    
    public func didSelect(header: RowHeader) {
        let previousSelectedHeader = selectedHeader
        selectedHeader = header
        let previousSelectedItem = selectedItem
        selectedItem = nil
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections(Set([selectedHeader, previousSelectedHeader]).compactMap({ $0 }))
        snapshot.reloadItems(Set([selectedItem, previousSelectedItem]).compactMap({$0}))
        dataSource.apply(snapshot)
        viewModel.select(of: header)
    }
    
    private func setupView() {
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
    }
    private func setupConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.pinToSafeArea(view)
    }
    
    private func registerCollectionViewComponents() {
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.CellIdentifier)
        if spreadSheetInfo.hasHorizontalHeader {
            collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: supplementaryHorizontalHeaderKind, withReuseIdentifier: Self.HorizontalHeaderIdentifier)
        }
        if spreadSheetInfo.hasVerticalHeader {
            collectionView.register(UICollectionViewCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Self.VerticalHeaderIdentifier)
        }
    }
    
    private func setupLayout(for supplementaryHorizontalHeaderKind: String) -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout.gridLayout(
            numberOfColumns: spreadSheetInfo.numberOfColumns,
            itemGeometry: .init(
                height: spreadSheetInfo.rowHeight,
                widths: spreadSheetInfo.columnWidths,
                verticalHeaderWidth: spreadSheetInfo.verticalHeaderWidth,
                hasHorizontalHeader: spreadSheetInfo.hasHorizontalHeader,
                itemInsets: .init(top: 5, leading: 8, bottom: 8, trailing: 5)
            ),
            supplementaryHorizontalHeaderKind: supplementaryHorizontalHeaderKind
        )
    }
    
    private func setupDataSource() -> DataSource {
        let result = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self else { return nil }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.CellIdentifier, for: indexPath)
            itemIdentifier.configure(cell: cell)
            var background = cell.defaultBackgroundConfiguration()
            background.strokeColor = UIColor(named: "TableSeparatorColor")
            background.strokeWidth = 1
            background.backgroundColor = itemIdentifier == selectedItem ? .orange : .white
            cell.backgroundConfiguration = background
            return cell
        }
        
        if spreadSheetInfo.hasVerticalHeader || spreadSheetInfo.hasHorizontalHeader {
            result.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
                guard let self,
                      let cell = cell(elementKind: elementKind, indexPath: indexPath) else {
                    return nil
                }
                switch elementKind {
                case UICollectionView.elementKindSectionHeader:
                    configureVerticalHeader(indexPath: indexPath, cell: cell)
                case self.supplementaryHorizontalHeaderKind:
                    if let cell = cell as? UICollectionViewListCell {
                        configuredHorizontalHeaderWithAccessory(cell: cell, at: indexPath)
                    }
                default:
                    break
                }
                return cell
            }
        }
        return result
    }
    
    private func configureVerticalHeader(indexPath: IndexPath, cell: UICollectionViewCell) {
        let item = verticalItem(indexPath: indexPath)
        item?.configure(cell: cell)
        var backgroundConfiguration = cell.defaultBackgroundConfiguration()
        backgroundConfiguration.strokeColor = UIColor(named: "TableSeparatorColor")
        backgroundConfiguration.strokeWidth = 1
        backgroundConfiguration.backgroundColor = item == selectedHeader ? .orange : elementColorScheme?.headersColor
        cell.backgroundConfiguration = backgroundConfiguration
    }
    
    private func configuredHorizontalHeaderWithAccessory(cell: UICollectionViewCell, at indexPath: IndexPath) {
        if let cell = cell as? UICollectionViewListCell {
            guard let item = self.horizontalItem(indexPath: indexPath) else { return }
            item.configure(cell: cell)
            configureCellAccessories(item: item, for: cell)
            var backgroundConfiguration = cell.defaultBackgroundConfiguration()
            backgroundConfiguration.strokeColor = UIColor(named: "TableSeparatorColor")
            backgroundConfiguration.strokeWidth = 1
            backgroundConfiguration.backgroundColor = elementColorScheme?.headersColor
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }
    
    private func configureCellAccessories(item: Item, for cell: UICollectionViewListCell) {
        if item.isSortable {
            if item == viewModel.sortByItem {
                cell.accessories = [.systemImageAccessory(systemName: imageName(for: viewModel.sortOrder)) { [weak self] _ in
                    guard let self else { return }
                    selectedItem = nil
                    selectedHeader = nil
                    viewModel.sort(by: item)
                    applySnapshot(animated: false, reload: true)
                }]
            } else {
                cell.accessories = [.systemImageAccessory(systemName: "square.fill") { [weak self] _ in
                    guard let self else { return }
                    selectedItem = nil
                    selectedHeader = nil
                    viewModel.sort(by: item)
                    applySnapshot(animated: false, reload: true)
                }]
            }
        } else {
            cell.accessories = []
        }
        
    }
    
    private func imageName(for order: SortOrder) -> String {
        switch order {
        case .forward:
            "arrowtriangle.down.fill"
        case .reverse:
            "arrowtriangle.up.fill"
        }
    }
    
    private func horizontalItem(indexPath: IndexPath) -> Item? {
        if spreadSheetInfo.hasHorizontalHeader {
            return viewModel.horizontalHeaderItem(for: indexPath[0])
        }
        
        return nil
    }
    
    private func verticalItem(indexPath: IndexPath) -> RowHeader? {
        if spreadSheetInfo.hasVerticalHeader {
            return dataSource.sectionIdentifier(for: indexPath.section)
        }
        return nil
    }
    
    private func cell(elementKind: String, indexPath: IndexPath) -> UICollectionViewCell? {
        var identifier: String? = nil
        
        if elementKind == UICollectionView.elementKindSectionHeader, spreadSheetInfo.hasVerticalHeader {
            identifier = Self.VerticalHeaderIdentifier
        } else if elementKind == self.supplementaryHorizontalHeaderKind, spreadSheetInfo.hasHorizontalHeader {
            identifier = Self.HorizontalHeaderIdentifier
        }
        
        if let identifier, let cell = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: indexPath) as? UICollectionViewCell {
            return cell
        } else {
            return nil
        }
    }
}



public extension UICellAccessory {
    static func systemImageAccessory(
        systemName: String,
        for handler: @escaping (UIAction) -> Void
    ) -> UICellAccessory {
        let action = UIAction(image: UIImage(systemName: systemName), handler: handler)
        let button = UIButton(primaryAction: action)
        
        let options = UICellAccessory.CustomViewConfiguration(
            customView: button,
            placement: .trailing(displayed: .always),
            isHidden: false
        )
        
        return .customView(configuration: options)
    }
}
