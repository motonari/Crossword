import Foundation

public struct HTMLSolutionRenderer {
    let fileURL: URL
}

// Initializers
extension HTMLSolutionRenderer {
    public init(to fileURL: URL) {
        self.fileURL = fileURL
    }
}

// SolutionRenderer
extension HTMLSolutionRenderer: SolutionRenderer {

    public func render(solution: Solution) throws {
        let template =
            """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <title>Personalized Crossword</title>
                <style>
                    @page {
                        size: A4;
                        margin: 1in;
                    }

                    body {
                        font-family: 'Comic Sans MS', cursive, sans-serif;
                        color: #34495e;
                        background: white;
                        max-width: 8.5in;
                        margin: 0 auto;
                        padding: 0in;
                    }

                    h1 {
                        text-align: center;
                        font-size: 22pt;
                        font-weight: normal;
                        margin-bottom: 8pt;
                        color: #146B3A;
                        text-shadow: 1px 1px 1px #002C23;
                    }

                    .puzzle-container {
                        display: flex;
                        gap: 10pt;
                        margin-bottom: 2pt;
                        break-inside: avoid;
                        flex-wrap: wrap;
                        justify-content: center;
                    }

                    .grid-container {
                        break-inside: avoid;
                        padding: 0px;
                    }

                    .grid {
                        display: grid;
                        grid-template-columns: repeat(%d, 35px);
                        grid-template-rows: repeat(%d, 35px);
                        gap: 1px;
                        background: #165B33;
                        border-radius: 3px;
                        padding: 2px;
                        user-select: none;
                        justify-content: center;
                    }

                    .cell {
                        width: 35px;
                        height: 35px;
                        background: white;
                        border-radius: 3px;
                        display: flex;
                        flex-direction: column;
                        align-items: flex-start;
                        justify-content: flex-start;
                        font-size: 14pt;
                        font-weight: bold;
                        color: #1e90ff;
                        position: relative;
                    }

                    .cell.black {
                        background: #165B33;
                        border-radius: 5px;
                    }

                    .cell .number {
                        position: absolute;
                        top: 2px;
                        left: 3px;
                        font-size: 9pt;
                        font-weight: bold;
                        color: #0d47a1;
                    }

                    .clues-container {
                        display: flex;
                        flex: 1 1 400px;
                        break-inside: avoid;
                        border-radius: 8px;
                    }

                    .clues-section {
                        margin-bottom: 2pt;
                        flex: 1 1 200px;
                    }

                    .clues-section h3 {
                        font-size: 12pt;
                        font-weight: bold;
                        margin-bottom: 12pt;
                        border-bottom: 3px solid #165B33;
                        text-transform: uppercase;
                        letter-spacing: 1.5px;
                        padding-bottom: 6pt;
                    }

                    .clue {
                        margin-bottom: 5pt;
                        padding-left: 12pt;
                        border-left: 6px solid #90EE90;
                        font-size: 10pt;
                        line-height: 1.0;
                    }

                    @media print {
                        .page-break {
                            break-after: page;
                        }
                    }
                </style>
            </head>
            <body>
                <h1>Birthday Crossword Challenge</h1>
                <div class="puzzle-container">
                    <div class="grid-container">
                        <div class="grid" id="grid"></div>
                    </div>

                    <div class="clues-container">
                        <div class="clues-section">
                        <h3>Across</h3>
                        %@
                        </div>

                        <div class="clues-section">
                        <h3>Down</h3>
                        %@
                        </div>
                    </div>
                </div>

                <div class="page-break"></div>

                <h1>Answers</h1>
                <div class="clues-container">
                    <div class="clues-section">
                        <h3>Across</h3>
                        %@
                    </div>

                    <div class="clues-section">
                        <h3>Down</h3>
                        %@
                    </div>
                </div>

                <script>
                const puzzleLayout = [
                %@
                ];

                    function createGrid() {
                        const grid = document.getElementById('grid');
                        puzzleLayout.forEach(row => {
                            row.forEach(num => {
                                const cell = document.createElement('div');
                                cell.classList.add('cell');
                                if (num === 0) {
                                    cell.classList.add('black');
            		    } else if (num === -1) {
                                    cell.classList.add('white');
                                } else {
                                    const number = document.createElement('span');
                                    number.classList.add('number');
                                    number.textContent = num;
                                    cell.appendChild(number);
                                }
                                grid.appendChild(cell);
                            });
                        });
                    }

                    createGrid();
                </script>
            </body>
            </html>
            """

        let clueIDs = clueIDs(of: solution.crossword)

        let layout = layoutAndClueIDs(
            of: solution.crossword, clueIDs: clueIDs)

        let acrossClues = clues(of: solution, clueIDs: clueIDs, direction: .across)
        let downClues = clues(of: solution, clueIDs: clueIDs, direction: .down)

        let acrossAnswers = answers(of: solution, clueIDs: clueIDs, direction: .across)
        let downAnswers = answers(of: solution, clueIDs: clueIDs, direction: .down)

        let result = String(
            format: template,
            solution.crossword.grid.width,
            solution.crossword.grid.height,
            acrossClues,
            downClues,
            acrossAnswers,
            downAnswers,
            layout)

        try result.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func clueIDs(of crossword: Crossword) -> [Location: Int] {
        let grid = crossword.grid
        var result = [Location: Int]()
        var clueID = 1
        for location in Locations(grid: grid) {
            if crossword.span(at: location, direction: .across) != nil
                || crossword.span(at: location, direction: .down) != nil
            {
                result[location] = clueID
                clueID += 1
            }
        }
        return result
    }

    private func layoutAndClueIDs(of crossword: Crossword, clueIDs: [Location: Int]) -> String {
        let grid = crossword.grid
        let layout = crossword.layout

        var result = ""
        for y in 0..<grid.height {
            var row = [String]()
            for x in 0..<grid.width {
                let location = Location(x, y)
                let color = layout.cell(at: location, in: grid)

                switch color {
                case .white:
                    if let id = clueIDs[location] {
                        row.append(String(id))
                    } else {
                        row.append("-1")
                    }
                case .black:
                    row.append(" 0")
                }
            }
            let rowString = String(format: "[%@],", row.joined(separator: ", "))
            result.append(rowString)
        }
        return result
    }

    private func clues(
        of solution: Solution,
        clueIDs: [Location: Int],
        direction: Direction
    ) -> String {
        let crossword = solution.crossword
        let grid = crossword.grid
        let lexicon = Lexicon()

        var result = ""
        for location in Locations(grid: grid) {
            guard let span = crossword.span(at: location, direction: direction) else {
                continue
            }

            let word = solution.domain(for: span).first!
            let clue = lexicon.clue(for: word) ?? "Your name?"
            let clueID = clueIDs[location]!
            result.append("<div class=\"clue\">\(clueID). \(clue)</div>")
        }
        return result
    }

    private func answers(
        of solution: Solution,
        clueIDs: [Location: Int],
        direction: Direction
    ) -> String {
        let crossword = solution.crossword
        let grid = crossword.grid

        var result = ""
        for location in Locations(grid: grid) {
            guard let span = crossword.span(at: location, direction: direction) else {
                continue
            }

            let word = solution.domain(for: span).first!
            let clueID = clueIDs[location]!
            result.append("<div class=\"clue\">\(clueID). \(word)</div>")
        }
        return result
    }
}
