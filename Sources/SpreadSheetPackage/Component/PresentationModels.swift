//
//  PresentationModels.swift
//  SpreadSheetLikeView
//
//  Created by Daliborka Randjelovic on 30.10.24..
//

import Foundation
import UIKit

public typealias SpreadSheetItem = Hashable & SpreadSheetCellConfigurator & Sortable
public struct RowWrapper<ColumnItem: SpreadSheetItem, RowItem: SpreadSheetItem> {
    let rowItem: RowItem
    let columns: [ColumnItem]
    
    public init(rowItem: RowItem, columns: [ColumnItem]) {
        self.rowItem = rowItem
        self.columns = columns
    }
}

public struct SpreadSheetLayoutInfo {
    let numberOfColumns: Int
    let rowHeight: CGFloat
    let columnWidths: [CGFloat]
    let verticalHeaderWidth: CGFloat?
    let hasHorizontalHeader: Bool
    
    public init(numberOfColumns: Int, rowHeight: CGFloat, columnWidths: [CGFloat], verticalHeaderWidth: CGFloat?, hasHorizontalHeader: Bool) {
        self.numberOfColumns = numberOfColumns
        self.rowHeight = rowHeight
        self.columnWidths = columnWidths
        self.verticalHeaderWidth = verticalHeaderWidth
        self.hasHorizontalHeader = hasHorizontalHeader
    }
    
    var hasVerticalHeader: Bool {
        verticalHeaderWidth != nil
    }
}

public struct ElementColorScheme {
    let headersColor: UIColor?
    
    public init(headersColor: UIColor?) {
        self.headersColor = headersColor
    }
}
