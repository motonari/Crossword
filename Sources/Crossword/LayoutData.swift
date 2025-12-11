import Algorithms
import Foundation

struct LayoutData {
    let grid: Grid

    var data = Data()
    var offsets = [Int]()
}

// MARK: Insertion
extension LayoutData {
    mutating func insert(_ layout: Layout, maxLayoutCount: Int) {
        let length = Layout.storageSize(for: grid)
        let insertingIndex = offsets.partitioningIndex {
            let subdata = data.subdata(in: $0..<($0 + length))
            let otherLayout = Layout(grid: grid, data: subdata)
            return layout >= otherLayout
        }

        if insertingIndex != offsets.endIndex {
            let offset = offsets[insertingIndex]
            let subdata = data.subdata(in: offset..<(offset + length))
            let existingLayout = Layout(grid: grid, data: subdata)

            if layout == existingLayout {
                // duplication; ignore.
                print("DUP")
                return
            }
        }

        if offsets.count < maxLayoutCount {
            // Simply insert a new layout at the end of `data`.
            let offset = data.count
            data.append(layout.dataRepresentation)
            offsets.insert(offset, at: insertingIndex)
        } else {
            // Remove layout of the lowest score, and then insert.
            let offset = offsets.last!
            data.replaceSubrange(offset..<(offset + length), with: layout.dataRepresentation)
            offsets.insert(offset, at: insertingIndex)
            offsets.removeLast()
        }
    }
}

// MARK: State
extension LayoutData {
    var count: Int {
        offsets.count
    }
}

// MARK: Sequence
extension LayoutData: Sequence {
    struct Iterator: IteratorProtocol {
        let grid: Grid
        let offsets: [Int]
        let data: Data

        var index = 0
        mutating func next() -> Layout? {
            guard index < offsets.count else {
                return nil
            }

            let length = Layout.storageSize(for: grid)
            let offset = offsets[index]
            let subdata = data.subdata(in: offset..<(offset + length))

            index += 1
            return Layout(grid: grid, data: subdata)
        }
    }

    func makeIterator() -> Iterator {
        return Iterator(grid: grid, offsets: offsets, data: data)
    }
}

// MARK: Collection
extension LayoutData: Collection {
    typealias Index = [Int].Index
    var startIndex: Index { offsets.startIndex }
    var endIndex: Index { offsets.endIndex }

    subscript(_ index: Int) -> Layout {
        let length = Layout.storageSize(for: grid)
        let offset = offsets[index]
        let subdata = data.subdata(in: offset..<(offset + length))
        return Layout(grid: grid, data: subdata)
    }

    func index(after i: Index) -> Index {
        precondition(startIndex <= i && i < endIndex, "Index out of bounds")
        return i + 1
    }
}

// MARK: data
extension LayoutData {
    var dataRepresentation: Data {
        var flatData = Data(capacity: data.count)
        let length = Layout.storageSize(for: grid)
        for offset in offsets {
            let subdata = data.subdata(in: offset..<(offset + length))
            flatData.append(subdata)
        }
        return flatData
    }
}
