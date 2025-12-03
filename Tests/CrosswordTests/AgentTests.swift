import Testing

@testable import Crossword

// @Suite struct AgentTests {

//     @Test("At terminal state, the following step should return nil.")
//     func terminalStateReturnsNilActions() {
//         // Current State:
//         //   ###
//         //   #1#
//         //   ###
//         let grid = Grid(width: 3, height: 3)
//         let env = Environment(
//             grid: grid,
//             words: ["#1#"])
//         var state = State(grid: grid)
//         let initialPlacement = Placement(
//             word: "#1#",
//             start: Location(x: 0, y: 1),
//             direction: .across)
//         state = state.adding(initialPlacement)

//         let agent = Agent(greedyEpsilon: 0.9, stepSize: 0.1, decay: 0.9, environment: env)
//         let action = agent.nextAction(for: state)

//         #expect(action == nil)
//     }

//     @Test("Test a state with only one possible action.")
//     func stateWithOnlyOnePosslbeAction() throws {
//         // Current State:
//         //   ####
//         //   #12#
//         //   ####
//         let grid = Grid(width: 4, height: 3)
//         let env = Environment(
//             grid: grid,
//             words: ["#12#", "#2#"])
//         var state = State(grid: grid)
//         let initialPlacement = Placement(
//             word: "#12#",
//             start: Location(x: 0, y: 1),
//             direction: .across)
//         state = state.adding(initialPlacement)

//         let agent = Agent(greedyEpsilon: 0.9, stepSize: 0.1, decay: 0.9, environment: env)
//         let action = try #require(agent.nextAction(for: state))
//         state = state.adding(action)

//         #expect(state.contains("#2#"))
//     }
// }
