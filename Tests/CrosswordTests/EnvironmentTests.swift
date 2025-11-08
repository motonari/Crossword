import Testing

@testable import Crossword

@Suite struct EnvironmentTests {
    @Test("Simple test case to get a state action.")
    func simpleStateActionTest() async {
        // Current State:
        //   ####
        //   #12#
        //   ####
        //
        // At this state, there is only one possible action: place #2# at (2, 0) down.
        let grid = Grid(width: 4, height: 3)
        let env = Environment(
            grid: grid,
            words: ["#12#", "#2#"])
        var state = State(grid: grid)
        let initialPlacement = Placement(
            word: "#12#",
            start: Location(x: 0, y: 1),
            direction: .across)
        state.add(initialPlacement)

        let actions = env.actions(for: state)
        #expect(actions.count == 1)
    }

    @Test("A slightly complex test case to get state actions.")
    func stateActionTest() async {
        // Current State:
        //   ####
        //   #12#
        //   #  #
        //   ####
        //
        // At this state, there are two possible actions.
        //
        //   ####
        //   #12#
        //   #23#
        //   ####
        //
        //   ####
        //   #12#
        //   # 3#
        //   ####

        let grid = Grid(width: 4, height: 4)
        let env = Environment(
            grid: grid,
            words: ["#12#", "#23#"])
        var state = State(grid: grid)
        let initialPlacement = Placement(
            word: "#12#",
            start: Location(x: 0, y: 1),
            direction: .across)
        state.add(initialPlacement)

        let actions = env.actions(for: state)
        let expectations = [
            Placement(word: "#23#", start: Location(x: 0, y: 2), direction: .across),
            Placement(word: "#23#", start: Location(x: 2, y: 0), direction: .down),
        ]

        #expect(testElementsEquality(actions.sorted(), expectations.sorted()))
    }
}
