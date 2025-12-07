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
                        color: #D6001C;
                        text-shadow: 1px 1px 1px #960014;
                    }

                    h2 {
                        text-align: center;
                        font-size: 20pt;
                        font-weight: normal;
                        margin-bottom: 8pt;
                        color: #3C8D0D;
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

                    .husky {
                        padding: 0px;
                        flex: 0 0;
                        border-right: 0px;
                        z-index: 10;
                    }

                    .rotate180 {
                        transform: rotate(180deg);
                    }

                    .grid {
                        display: grid;
                        grid-template-columns: repeat(%d, 35px);
                        grid-template-rows: repeat(%d, 35px);
                        gap: 1px;
                        background: #C30F16;
                        border-radius: 3px;
                        padding: 2px;
                        user-select: none;
                        justify-content: center;
                        margin-left: -21px;
                        margin-right: -21px;
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
                        background: #C30F16;
                        border-radius: 5px;
                    }

                    .cell .number {
                        position: absolute;
                        top: 2px;
                        left: 6px;
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
                        border-bottom: 3px solid #1E792C;
                        text-transform: uppercase;
                        letter-spacing: 1.5px;
                        padding-bottom: 6pt;
                    }

                    .clue {
                        margin-bottom: 5pt;
                        padding-left: 12pt;
                        border-left: 6px solid #1E792C;
                        font-size: 10pt;
                        line-height: 1.0;
                    }

                    .acknowledgement {
                        margin-top: 20pt;
                        padding: 12pt;
                        border: 1px solid #1E792C;
                        font-size: 10pt;
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
                        <div class="husky">
                          <img id="husky-image" src="data:image/png;base64,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"/>
                          <image id="husky-image-repeat" src=""/>
                          <image id="husky-image-repeat" src=""/>
                          <image id="husky-image-repeat" src=""/>
                          <image id="husky-image-repeat" src=""/>
                          <image id="husky-image-repeat" src=""/>
                        </div>
                        <div class="grid-container">
                            <div class="grid" id="grid"></div>
                        </div>

                        <div class="husky">
                            <image id="husky-image-repeat" src="" class="rotate180"/>
                            <image id="husky-image-repeat" src="" class="rotate180"/>
                            <image id="husky-image-repeat" src="" class="rotate180"/>
                            <image id="husky-image-repeat" src="" class="rotate180"/>
                            <image id="husky-image-repeat" src="" class="rotate180"/>
                            <image id="husky-image-repeat" src="" class="rotate180"/>
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

                    <h2>Answers</h2>
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

                    <div class="acknowledgement">
                    Made by Kyosuke and Moto, his dad. Thoughts or suggestions? Send me an email! <address>Email: <a href="mailto:motonari.ito@gmail.com">motonari.ito@gmail.com</a></address> 
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

                        var src = document.querySelector('#husky-image').src;
                        document.querySelectorAll('#husky-image-repeat').forEach(img => img.src = src);

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
            let clue =
                if word == Word("KYOSUKE") {
                    "Birthday boy's name? 🎉"
                } else {
                    lexicon.clue(for: word) ?? "Your name? 😁"
                }
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
