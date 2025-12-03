// public struct Environment {
//     let grid: Grid
//     let words: [String]

//     public init(grid: Grid, words: [String]) {
//         self.grid = grid
//         self.words = words
//     }

//     func actions(for state: State) -> [Placement] {
//         var actions = [Placement]()
//         for location in AvailableLocations(grid: grid) {
//             let unusedWords = words.filter { !state.contains($0) }
//             for word in unusedWords {
//                 if location.x + word.count <= grid.width {
//                     let across = Placement(word: word, start: location, direction: .across)
//                     if state.canAccept(across) {
//                         actions.append(across)
//                     }
//                 }

//                 if location.y + word.count <= grid.height {
//                     let down = Placement(word: word, start: location, direction: .down)
//                     if state.canAccept(down) {
//                         actions.append(down)
//                     }
//                 }
//             }
//         }
//         return actions
//     }
// }
