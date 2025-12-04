import Foundation

struct SolutionRenderer {
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
                    font-size: 14pt;
                    line-height: 1.5;
                    color: #333;
                    background: white;
                    max-width: 8.5in;
                    margin: 0 auto;
                    padding: 1in;
                }

                h1 {
                    text-align: center;
                    font-size: 24pt;
                    font-weight: bold;
                    margin-bottom: 30pt;
                    color: #1e90ff;
                    text-shadow: 1px 1px 2px #a0c4ff;
                }

                .puzzle-container {
                    display: flex;
                    gap: 40pt;
                    margin-bottom: 30pt;
                    break-inside: avoid;
                    flex-wrap: wrap;
                    justify-content: center;
                }

                .grid-container {
                    flex: 1 1 350px;
                    break-inside: avoid;
                    box-shadow: 0 0 15px rgba(30, 144, 255, 0.5);
                    border-radius: 12px;
                    padding: 8px;
                    background: #d0e6ff;
                }

                .grid {
                    display: grid;
                    grid-template-columns: repeat(12, 35px);
                    grid-template-rows: repeat(12, 35px);
                    gap: 1px;
                    background: #1e90ff;
                    border-radius: 10px;
                    padding: 4px;
                    user-select: none;
                    justify-content: center;
                }

                .cell {
                    width: 35px;
                    height: 35px;
                    background: white;
                    border-radius: 5px;
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
                    background: #2c3e50;
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
                    flex: 1 1 300px;
                    break-inside: avoid;
                    background: #f0f8ff;
                    padding: 15px 20px;
                    border-radius: 12px;
                    box-shadow: 0 0 15px rgba(30, 144, 255, 0.3);
                }

                .clues-section {
                    margin-bottom: 25pt;
                }

                .clues-section h3 {
                    font-size: 18pt;
                    font-weight: bold;
                    margin-bottom: 12pt;
                    border-bottom: 3px solid #1e90ff;
                    color: #1e90ff;
                    text-transform: uppercase;
                    letter-spacing: 1.5px;
                    padding-bottom: 6pt;
                }

                .clue {
                    margin-bottom: 10pt;
                    padding-left: 12pt;
                    border-left: 6px solid #74b9ff;
                    font-size: 14pt;
                    color: #34495e;
                    font-family: 'Comic Sans MS', cursive, sans-serif;
                    line-height: 1.3;
                }

                .instructions {
                    margin-top: 30pt;
                    padding: 18pt;
                    border: 2px solid #1e90ff;
                    border-radius: 12px;
                    font-size: 13pt;
                    background: #d0e6ff;
                    color: #2c3e50;
                    font-family: 'Comic Sans MS', cursive, sans-serif;
                    text-align: center;
                    box-shadow: inset 0 0 12px #74b9ff;
                }

                @media print {
                    body {
                        padding: 0.5in;
                    }
                    .grid {
                        grid-template-columns: repeat(15, 22px);
                        grid-template-rows: repeat(15, 22px);
                        padding: 3px;
                    }
                    .cell {
                        width: 22px;
                        height: 22px;
                        font-size: 12pt;
                    }
                    .cell .number {
                        font-size: 8pt;
                    }
                    .clues-section h3 {
                        font-size: 16pt;
                    }
                    .clue {
                        font-size: 12pt;
                    }
                    .instructions {
                        font-size: 12pt;
                        padding: 14pt;
                    }
                }

                @media (max-width: 700px) {
                    .puzzle-container {
                        flex-direction: column;
                        gap: 30pt;
                    }
                    .grid-container, .clues-container {
                        flex: 1 1 100%%;
                    }
                    .grid {
                        justify-self: center;
                    }
                }
            </style>
        </head>
        <body>
            <h1>Crossword Puzzle Challenge!</h1>

            <div class="puzzle-container">
                <div class="grid-container">
                    <div class="grid" id="grid"></div>
                </div>

                <div class="clues-container">
                    <div class="clues-section">
                        <h3>Across</h3>
                        <div class="clue">1. Programming language by Apple (5)</div>
                        <div class="clue">6. Minecraft block for light (4)</div>
                        <div class="clue">8. Swift data structure (5)</div>
                        <div class="clue">11. Game world generator (4)</div>
                        <div class="clue">1. Programming language by Apple (5)</div>
                        <div class="clue">6. Minecraft block for light (4)</div>
                        <div class="clue">8. Swift data structure (5)</div>
                        <div class="clue">11. Game world generator (4)</div>
                        <div class="clue">1. Programming language by Apple (5)</div>
                        <div class="clue">6. Minecraft block for light (4)</div>
                    </div>

                    <div class="clues-section">
                        <h3>Down</h3>
                        <div class="clue">1. Programming language by Apple (5)</div>
                        <div class="clue">6. Minecraft block for light (4)</div>
                        <div class="clue">8. Swift data structure (5)</div>
                        <div class="clue">11. Game world generator (4)</div>
                        <div class="clue">1. Programming language by Apple (5)</div>
                        <div class="clue">6. Minecraft block for light (4)</div>
                        <div class="clue">8. Swift data structure (5)</div>
                        <div class="clue">11. Game world generator (4)</div>
                        <div class="clue">1. Programming language by Apple (5)</div>
                        <div class="clue">6. Minecraft block for light (4)</div>
                    </div>
                </div>
            </div>

            <div class="instructions">
                <strong>How to play:</strong> Use a pencil or crayon to fill each white square with a letter. Colored blocks are black squares where no letters go. Numbers in squares show where clues start. Have fun solving this tech and gaming crossword puzzle!
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
    private func jsonRepresentation(of layout: Layout, in grid: Grid) -> String {
        var result = ""
        for y in 0..<grid.height {
            var row = [String]()
            for x in 0..<grid.width {
                let color = layout.cell(at: Location(x, y), in: grid)
                switch color {
                case .white:
                    row.append("-1")
                case .black:
                    row.append(" 0")
                }
            }
            let rowString = String(format: "[%@],", row.joined(separator: ", "))
            result.append(rowString)
        }
        return result
    }

    func render(solution: DomainMap) -> String {
        let layout = jsonRepresentation(
            of: solution.crossword.layout, in: solution.crossword.grid)

        return String(format: template, layout)
    }
}
