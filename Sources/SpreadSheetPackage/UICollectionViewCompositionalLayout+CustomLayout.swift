//
//  UICollectionViewCompositionalLayout+CustomLayout.swift
//  ezDerm
//
//  Created by Vladimir Jeremic on 10/24/23.
//  Copyright © 2023 EZDERM, LLC. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionViewCompositionalLayout {
    static func equallyDividedLayout(
        itemGeometry: NSCollectionLayoutSection.DinamicWidthItemGeometryParameters,
        headersGeometry: NSCollectionLayoutSection.SectionGeometryParameters? = nil
    ) -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            return .equallyDividedSection(environment: environment, itemGeometry: itemGeometry, headersGeometry: headersGeometry)
        }

        return layout
    }

    static func columnsDividedLayout(
        numberOfColumns: NSCollectionLayoutSection.NumberOfColumns,
        itemGeometry: NSCollectionLayoutSection.ColumnItemGeometryParameters,
        headersGeometry: NSCollectionLayoutSection.SectionGeometryParameters? = nil
    ) -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            return .columnsSection(
                environment: environment,
                numberOfColumns: numberOfColumns,
                itemGeometry: itemGeometry,
                headersGeometry: headersGeometry
            )
        }

        return layout
    }
    
    static func columnsDividedLayout(
        columnWidth: CGFloat,
        numberOfColumns: NSCollectionLayoutSection.NumberOfColumns,
        itemGeometry: NSCollectionLayoutSection.ColumnItemGeometryParameters,
        headersGeometry: NSCollectionLayoutSection.SectionGeometryParameters? = nil
    ) -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            return .columnsSection(
                environment: environment,
                columnWidth: columnWidth,
                numberOfColumns: numberOfColumns,
                itemGeometry: itemGeometry,
                headersGeometry: headersGeometry
            )
        }

        return layout
    }
    
    static func gridLayout(
        numberOfColumns: Int,
        itemGeometry: NSCollectionLayoutSection.ItemGeometryParameters,
        supplementaryHorizontalHeaderKind: String
    ) -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
                .gridSection(
                    numberOfColumns: numberOfColumns,
                    itemGeometry: itemGeometry
                )
        }
        
        if itemGeometry.hasHorizontalHeader {
            let configuration = UICollectionViewCompositionalLayoutConfiguration.horizontalHeadersConfiguration(
                itemGeometry: itemGeometry,
                numberOfColumns: numberOfColumns,
                supplementaryHorizontalHeaderKind: supplementaryHorizontalHeaderKind
            )
            
            layout.configuration = configuration
        }
        return layout
    }
}

extension UICollectionViewCompositionalLayoutConfiguration {
    static func horizontalHeadersConfiguration(
        itemGeometry: NSCollectionLayoutSection.ItemGeometryParameters,
        numberOfColumns: Int,
        supplementaryHorizontalHeaderKind: String
    ) -> UICollectionViewCompositionalLayoutConfiguration {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
    
        // (0,0) position
        if itemGeometry.hasVerticalHeader {
            let columnHeaderLayoutSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemGeometry.verticalHeaderWidth ?? 0),
                heightDimension: .absolute(itemGeometry.height)
            )
            let columnHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: columnHeaderLayoutSize,
                elementKind: supplementaryHorizontalHeaderKind,
                alignment: .topLeading
            )
            columnHeader.pinToVisibleBounds = true
            columnHeader.zIndex = .max
            configuration.boundarySupplementaryItems.append(columnHeader)
        }
        
        for columnIndex in 0..<numberOfColumns {
            let horizontalHeaderLayoutSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemGeometry.widths[columnIndex]),
                heightDimension: .absolute(itemGeometry.height)
            )
               
            let startOffset = itemGeometry.verticalHeaderWidth ?? 0
            let offsetX = itemGeometry.widths[0..<columnIndex].reduce(CGFloat(startOffset), +)
            let horizontalHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: horizontalHeaderLayoutSize,
                elementKind: supplementaryHorizontalHeaderKind,
                alignment: .topLeading,
                absoluteOffset: CGPoint(x: offsetX, y: 0)
            )
            horizontalHeader.pinToVisibleBounds = true
            horizontalHeader.zIndex = .max - numberOfColumns + columnIndex
            configuration.boundarySupplementaryItems.append(horizontalHeader)
        }
        return configuration
    }
}

// Columns Layout
extension NSCollectionLayoutSection {
    
    struct ItemGeometryParameters {
        let height: CGFloat
        let widths: [CGFloat]
        let verticalHeaderWidth: CGFloat?
        let hasHorizontalHeader: Bool
        let itemInsets: NSDirectionalEdgeInsets
        
        init(
            height: CGFloat,
            widths: [CGFloat],
            verticalHeaderWidth: CGFloat? = nil,
            hasHorizontalHeader: Bool = true,
            itemInsets: NSDirectionalEdgeInsets = .init(
                top: 5,
                leading: 5,
                bottom: 5,
                trailing: 5
            )
        ) {
            self.height = height
            self.widths = widths
            self.verticalHeaderWidth = verticalHeaderWidth
            self.hasHorizontalHeader = hasHorizontalHeader
            self.itemInsets = itemInsets
        }
        
        var hasVerticalHeader: Bool {
            verticalHeaderWidth != nil
        }
    }
    
    struct ColumnItemGeometryParameters {
        let height: CGFloat
        let itemInsets: NSDirectionalEdgeInsets

        init(
            height: CGFloat,
            itemInsets: NSDirectionalEdgeInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
        ) {
            self.height = height
            self.itemInsets = itemInsets
        }
    }

    struct NumberOfColumns {
        let numberForCompact: Int
        let numberForRegular: Int

        init(numberForCompact: Int, numberForRegular: Int) {
            self.numberForCompact = numberForCompact
            self.numberForRegular = numberForRegular
        }

        init(numberOfColumns: Int) {
            numberForCompact = numberOfColumns
            numberForRegular = numberOfColumns
        }
    }

    static func columnsSection(
        environment: NSCollectionLayoutEnvironment,
        numberOfColumns: NSCollectionLayoutSection.NumberOfColumns,
        itemGeometry: NSCollectionLayoutSection.ColumnItemGeometryParameters,
        headersGeometry: NSCollectionLayoutSection.SectionGeometryParameters? = nil
    ) -> NSCollectionLayoutSection {
        let columnsCount = environment.traitCollection.horizontalSizeClass == .compact ? numberOfColumns.numberForCompact : numberOfColumns.numberForRegular
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columnsCount)),
                heightDimension: .fractionalHeight(1.0)
            )
        )
        item.contentInsets = itemGeometry.itemInsets

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemGeometry.height + itemGeometry.itemInsets.top + itemGeometry.itemInsets.bottom)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

        if let headersGeometry {
            let headerFooterSize = NSCollectionLayoutSize(
                widthDimension: headersGeometry.width,
                heightDimension: headersGeometry.height
            )
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerFooterSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: headersGeometry.alignment
            )
            section.boundarySupplementaryItems = [sectionHeader]
        }

        return section
    }
    
    static func columnsSection(
        environment: NSCollectionLayoutEnvironment,
        columnWidth: CGFloat,
        numberOfColumns: NSCollectionLayoutSection.NumberOfColumns,
        itemGeometry: NSCollectionLayoutSection.ColumnItemGeometryParameters,
        headersGeometry: NSCollectionLayoutSection.SectionGeometryParameters? = nil
    ) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .absolute(columnWidth),
                heightDimension: .fractionalHeight(1.0)
            )
        )
        item.contentInsets = itemGeometry.itemInsets

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .absolute(columnWidth * CGFloat(numberOfColumns.numberForRegular)),
                heightDimension: .absolute(itemGeometry.height + itemGeometry.itemInsets.top + itemGeometry.itemInsets.bottom)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

        if let headersGeometry {
            let headerFooterSize = NSCollectionLayoutSize(
                widthDimension: headersGeometry.width,
                heightDimension: headersGeometry.height
            )
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerFooterSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: headersGeometry.alignment
            )
            section.boundarySupplementaryItems = [sectionHeader]
        }

        return section
    }
    
    static func gridSection(
        numberOfColumns: Int,
        itemGeometry: NSCollectionLayoutSection.ItemGeometryParameters
    ) -> NSCollectionLayoutSection {
        var items: [NSCollectionLayoutItem] = []
        for width in itemGeometry.widths {
            items.append(.init(layoutSize: .init(
                widthDimension: .absolute(width),
                heightDimension: .absolute(itemGeometry.height))))
        }
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemGeometry.widths.reduce(0, +) + (itemGeometry.verticalHeaderWidth ?? 0)),
            heightDimension: .absolute(itemGeometry.height)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: items)
        if let verticalHeaderWidth = itemGeometry.verticalHeaderWidth {
            group.contentInsets.leading = CGFloat(verticalHeaderWidth)
        }
        let row = NSCollectionLayoutSection(group: group)
        
        if let verticalHeaderWidth = itemGeometry.verticalHeaderWidth {
            let verticalHeaderLayoutSize = NSCollectionLayoutSize(
                widthDimension: .absolute(verticalHeaderWidth),
                heightDimension: .absolute(itemGeometry.height)
            )
            let verticalHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: verticalHeaderLayoutSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .leading
            )
            
            verticalHeader.pinToVisibleBounds = true
            verticalHeader.zIndex = .max - 100
            row.boundarySupplementaryItems = [verticalHeader]
        }
        return row
    }
}

extension NSCollectionLayoutSection {
    struct DinamicWidthItemGeometryParameters {
        let maxWidth: CGFloat
        let minWidth: CGFloat
        let height: CGFloat
        let itemInsets: NSDirectionalEdgeInsets

        init(
            maxWidth: CGFloat,
            minWidth: CGFloat = .greatestFiniteMagnitude,
            height: CGFloat,
            itemInsets: NSDirectionalEdgeInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
        ) {
            self.maxWidth = maxWidth
            self.minWidth = minWidth
            self.height = height
            self.itemInsets = itemInsets
        }
    }

    struct SectionGeometryParameters {
        let width: NSCollectionLayoutDimension
        let height: NSCollectionLayoutDimension
        let alignment: NSRectAlignment
    }

    static func equallyDividedSection(
        environment: NSCollectionLayoutEnvironment,
        itemGeometry: DinamicWidthItemGeometryParameters,
        headersGeometry: SectionGeometryParameters? = nil
    ) -> NSCollectionLayoutSection {
        let numberOfItems: CGFloat = environment.estimatedNumberOfCells(maxWidth: itemGeometry.maxWidth, minWidth: itemGeometry.minWidth, inset: itemGeometry.itemInsets.leading)

        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0 / numberOfItems),
                heightDimension: .fractionalHeight(1.0)
            )
        )
        item.contentInsets = itemGeometry.itemInsets

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemGeometry.height + itemGeometry.itemInsets.top + itemGeometry.itemInsets.bottom)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

        if let headersGeometry {
            let headerFooterSize = NSCollectionLayoutSize(
                widthDimension: headersGeometry.width,
                heightDimension: headersGeometry.height
            )
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerFooterSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: headersGeometry.alignment
            )
            section.boundarySupplementaryItems = [sectionHeader]
        }

        return section
    }
}

extension NSCollectionLayoutSection {
    struct FixedSizeItemGeometry {
        let height: NSCollectionLayoutDimension
        let width: NSCollectionLayoutDimension
        let itemInsets: NSDirectionalEdgeInsets
        let edgeSpacing: NSCollectionLayoutEdgeSpacing
    }

    static func fixedSizeItemSection(
        itemGeometry: FixedSizeItemGeometry,
        headersGeometry: SectionGeometryParameters? = nil
    ) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: itemGeometry.width,
                heightDimension: itemGeometry.height
            )
        )
        item.contentInsets = itemGeometry.itemInsets
        item.edgeSpacing = itemGeometry.edgeSpacing

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemGeometry.height.dimension + itemGeometry.itemInsets.top + itemGeometry.itemInsets.bottom)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

        if let headersGeometry {
            let headerFooterSize = NSCollectionLayoutSize(
                widthDimension: headersGeometry.width,
                heightDimension: headersGeometry.height
            )
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerFooterSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: headersGeometry.alignment
            )
            section.boundarySupplementaryItems = [sectionHeader]
        }

        return section
    }
}

// MARK: Load more cell with custom height and width

extension NSCollectionLayoutSection {
    static func loadMoreCellSection(
        environment: NSCollectionLayoutEnvironment,
        size: CGSize,
        sectionInsets: NSDirectionalEdgeInsets
    ) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(size.height)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .absolute(size.width),
                heightDimension: .absolute(size.height)
            ),
            subitems: [item]
        )

        let horizontalInset = (environment.container.contentSize.width - sectionInsets.leading - sectionInsets.trailing - size.width) * 0.5

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(
            top: sectionInsets.top,
            leading: horizontalInset,
            bottom: sectionInsets.bottom,
            trailing: horizontalInset
        )

        return section
    }
}

private extension NSCollectionLayoutEnvironment {
    func estimatedNumberOfCells(maxWidth: CGFloat, minWidth: CGFloat = .greatestFiniteMagnitude, inset: CGFloat) -> CGFloat {
        var potentialWidth = CGFloat.greatestFiniteMagnitude
        var numberOfItems: CGFloat = 0
        while potentialWidth > maxWidth {
            numberOfItems += 1
            potentialWidth = (container.contentSize.width - (inset * numberOfItems + 1)) / numberOfItems
            if potentialWidth < minWidth {
                numberOfItems -= 1
                break
            }
        }

        return numberOfItems
    }
}
