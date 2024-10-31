//
//  Protocol.swift
//  SpreadSheetLikeView
//
//  Created by Daliborka Randjelovic on 30.10.24..
//

import Foundation
import UIKit

public protocol SpreadSheetCellConfigurator {
    func configure(cell: UICollectionViewCell)
}

public protocol Sortable {
    var isSortable: Bool { get }
}

public protocol SelectionDelegate<Item> {
    associatedtype Item: SpreadSheetItem
    func didSelect(header: Item)
}

public protocol SpreadSheetDataSourceAndDelegate {
    associatedtype Item: SpreadSheetItem
    associatedtype RowHeader: SpreadSheetItem
    func horizontalHeaderItem(for column: Int) -> Item
    func generateData() -> [RowWrapper<Item,  RowHeader>]
    var sortOrder: SortOrder { get }
    var sortByItem: Item? { get }
    var delegate: (any SelectionDelegate<RowHeader>)? { get }
    func sort(by item: Item)
    func select(of item: any SpreadSheetItem)
}
