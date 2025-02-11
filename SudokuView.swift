import UIKit

func fontSizeFor(_ string : NSString, fontName : String, targetSize : CGSize) -> CGFloat {
    let testFontSize : CGFloat = 32
    let font = UIFont(name: fontName, size: testFontSize)
    let attr = [NSAttributedString.Key.font : font!]
    let strSize = string.size(withAttributes: attr)
    return testFontSize*min(targetSize.width/strSize.width, targetSize.height/strSize.height)
}

class SudokuView: UIView {
    
    var selected = (row : -1, column : -1)  // current selected cell in 9x9 puzzle (-1 => none)

    //
    // Allow user to "select" a non-fixed cell in the puzzle's 9x9 grid.
    //
    @IBAction func handleTap(_ sender : UIGestureRecognizer) {
        let tapPoint = sender.location(in: self)
        let gridSize = 0.8*((self.bounds.width < self.bounds.height) ? self.bounds.width : self.bounds.height)
        let gridOrigin = CGPoint(x: (self.bounds.width - gridSize)/2, y: (self.bounds.height - gridSize)/2)
        let d = gridSize/9
        let col = Int((tapPoint.x - gridOrigin.x)/d)
        let row = Int((tapPoint.y - gridOrigin.y)/d)

        if  0 <= col && col < 9 && 0 <= row && row < 9 {              // if inside puzzle bounds
            if (row != selected.row || col != selected.column) {  // and not already selected
                selected.row = row                                // then select cell
                selected.column = col
                setNeedsDisplay()                                 // request redraw ***** PuzzleView
            }
        }
    }
    
    // Draw sudoku board. The current puzzle state is stored in the "sudoku" property
    // stored in the app delegate.
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        let gridSize = 0.8*((self.bounds.width < self.bounds.height) ? self.bounds.width : self.bounds.height)
        let gridOrigin = CGPoint(x: (self.bounds.width - gridSize)/2, y: (self.bounds.height - gridSize)/2)
        let delta = gridSize/3
        let d = delta/3
        
        if selected.row >= 0 && selected.column >= 0 {
            UIColor.lightGray.setFill()
            let x = gridOrigin.x + CGFloat(selected.column)*d
            let y = gridOrigin.y + CGFloat(selected.row)*d
            context?.fill(CGRect(x: x, y: y, width: d, height: d))
        }
        
        // Stroke outer puzzle rectangle
        context?.setLineWidth(6)
        UIColor.black.setStroke()
        context?.stroke(CGRect(x: gridOrigin.x, y: gridOrigin.y, width: gridSize, height: gridSize))
        
        // Stroke major grid lines.
        for i in 0 ..< 3 {
            let x = gridOrigin.x + CGFloat(i)*delta
            context?.move(to: CGPoint(x: x, y: gridOrigin.y))
            context?.addLine(to: CGPoint(x: x, y: gridOrigin.y + gridSize))
            context?.strokePath()
        }
        for i in 0 ..< 3 {
            let y = gridOrigin.y + CGFloat(i)*delta
            context?.move(to: CGPoint(x: gridOrigin.x, y: y))
            context?.addLine(to: CGPoint(x: gridOrigin.x + gridSize, y: y))
            context?.strokePath()
        }

        // Stroke minor grid lines.
        context?.setLineWidth(3)
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                let x = gridOrigin.x + CGFloat(i)*delta + CGFloat(j)*d
                context?.move(to: CGPoint(x: x, y: gridOrigin.y))
                context?.addLine(to: CGPoint(x: x, y: gridOrigin.y + gridSize))
                let y = gridOrigin.y + CGFloat(i)*delta + CGFloat(j)*d
                context?.move(to: CGPoint(x: gridOrigin.x, y: y))
                context?.addLine(to: CGPoint(x: gridOrigin.x + gridSize, y: y))
                context?.strokePath()
            }
        }
        
        //
        // Fetch Sudoku puzzle model object from app delegate.
        //
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let puzzle = appDelegate.sudoku
        
        //
        // Fetch/compute font attribute information.
        //
        let fontName = "Helvetica"
        let boldFontName = "Helvetica-Bold"
        let pencilFontName = "Helvetica-Light"
        
        let fontSize = fontSizeFor("0", fontName: boldFontName, targetSize: CGSize(width: d, height: d))
        
        let boldFont = UIFont(name: boldFontName, size: fontSize)
        let font = UIFont(name: fontName, size: fontSize)
        let pencilFont = UIFont(name: pencilFontName, size: fontSize/6)
        
        let fixedAttributes = [NSAttributedString.Key.font : boldFont!, NSAttributedString.Key.foregroundColor : UIColor.black]
        let userAttributes = [NSAttributedString.Key.font : font!, NSAttributedString.Key.foregroundColor : UIColor.blue]
        let conflictAttributes = [NSAttributedString.Key.font : font!, NSAttributedString.Key.foregroundColor : UIColor.red]
        let pencilAttributes = [NSAttributedString.Key.font : pencilFont!, NSAttributedString.Key.foregroundColor : UIColor.black]
    
        class Block {
            var column: Int
            var row: Int
            var value: Int
            var coordinates: (Int, Int)
            var occupiedBlocks: [(Int, Int)]
            var cageId: Int
            var cumulativeValue: Int
            
            init(column: Int, row: Int, value: Int, cageId: Int) {
                self.column = column
                self.row = row
                self.value = value
                self.coordinates = (row, column)
                self.occupiedBlocks = []
                self.cageId = cageId
                self.cumulativeValue = 0
            }
            
            func getNeighbours() -> [(Int, Int)] {
                var neighbours: [(Int, Int)] = []
                
                for h in [-1, 0, 1] {
                    if (self.column + h) > 8 || (self.column + h) < 0 {
                        continue
                    }
                    
                    for v in [-1, 0, 1] {
                        if (self.row + v) > 8 || (self.row + v) < 0 {
                            continue
                        }
                        
                        if h == 0 && v == 0 {
                            continue
                        }
                        
                        neighbours.append((self.row + v, self.column + h))
                    }
                }
                return neighbours
            }
            
            func draw(context: CGContext, gridOrigin: CGPoint, d: CGFloat) {
//                self.draw_sides(context: context, gridOrigin: gridOrigin, d: d)
                self.draw_corners(context: context, gridOrigin: gridOrigin, d: d)
            }
            
//            func draw_sides(context: CGContext?, gridOrigin: CGPoint, d: CGFloat) {
//                guard let context = context else { return }
//                
//                let center_x = gridOrigin.x + (CGFloat(self.column) + 0.5) * d
//                let center_y = gridOrigin.y + (CGFloat(self.row) + 0.5) * d
//                
//                let dashLength: CGFloat = 2.0  // Adjust this value to control the length of dashes
//                let gapLength: CGFloat = 1.0   // Adjust this value to control the length of gaps
//
//                context.setLineDash(phase: 0, lengths: [dashLength, gapLength])
//                context.setLineWidth(2.0)
//                
//                //left
//                if column - 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row, column - 1) }) {
//                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y - 0.3 * d))
//                    context.addLine(to: CGPoint(x: center_x - 0.4 * d, y: center_y + 0.3 * d))
//                    context.strokePath()
//                }
//                
//                //right
//                if column + 1 > 8 || !occupiedBlocks.contains(where: { $0 == (row, column + 1) }) {
//                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y - 0.3 * d))
//                    context.addLine(to: CGPoint(x: center_x + 0.4 * d, y: center_y + 0.3 * d))
//                    context.strokePath()
//                }
//                
//                //bottom
//                if row - 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row - 1, column) }) {
//                    context.move(to: CGPoint(x: center_x + 0.3 * d, y: center_y - 0.4 * d))
//                    context.addLine(to: CGPoint(x: center_x - 0.3 * d, y: center_y - 0.4 * d))
//                    context.strokePath()
//                }
//                
//                //top
//                if row + 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row + 1, column) }) {
//                    context.move(to: CGPoint(x: center_x + 0.3 * d, y: center_y + 0.4 * d))
//                    context.addLine(to: CGPoint(x: center_x - 0.3 * d, y: center_y + 0.4 * d))
//                    context.strokePath()
//                }
//                
//                context.setLineDash(phase: 0, lengths: [])
//            }
            
            func draw_corners(context: CGContext?, gridOrigin: CGPoint, d: CGFloat) {
                guard let context = context else { return }
                let center_x = gridOrigin.x + (CGFloat(self.column) + 0.5) * d
                let center_y = gridOrigin.y + (CGFloat(self.row) + 0.5) * d
                
                let dashLength: CGFloat = 2.0  // Adjust this value to control the length of dashes
                let gapLength: CGFloat = 1.0   // Adjust this value to control the length of gaps
                
                context.setLineDash(phase: 0, lengths: [dashLength, gapLength])
                context.setLineWidth(2.0)
                
                //top left
                
                var up = !(row - 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row - 1, column) }))
                var left = !(column - 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row, column-1) }))
                var corner = !(column - 1 < 0 || row - 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row-1, column-1) }))
                
                let offset = 0.005
                
                if self.cumulativeValue != 0 {
                    let text = "\(self.cumulativeValue)"
                    let cageFontName = "Helvetica-Light"
                    let fontSize = fontSizeFor("0", fontName: cageFontName, targetSize: CGSize(width: d, height: d))
                    let cageFont = UIFont(name: cageFontName, size: fontSize/5)
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center

                    let attributes: [NSAttributedString.Key: Any] = [
                        NSAttributedString.Key.font: cageFont!,
                        NSAttributedString.Key.foregroundColor: UIColor.black,
                        NSAttributedString.Key.paragraphStyle: paragraphStyle
                    ]
                    
                    let textSize = text.size(withAttributes: attributes)
                    let textRect = CGRect(x: center_x - 0.45*d, y: center_y - 0.45*d, width: textSize.width + 0.04*d, height: textSize.height)

                    // Draw the text
                    text.draw(in: textRect, withAttributes: attributes)
                    
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y - offset * d))
                    context.addLine(to: CGPoint(x: center_x - 0.4 * d, y: center_y - 0.45 * d + textSize.height))
                    context.strokePath()
                    
                    context.move(to: CGPoint(x: center_x - offset * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - 0.45 * d + textSize.width + 0.05*d, y: center_y - 0.4 * d))
                    context.strokePath()
                    
                } else if up && !left && !corner {
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y - offset * d))
                    context.addLine(to: CGPoint(x: center_x - 0.4 * d, y: center_y - 0.5 * d))
                    context.strokePath()
                    
                } else if left && !up {
                    context.move(to: CGPoint(x: center_x - offset * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - 0.5 * d, y: center_y - 0.4 * d))
                    context.strokePath()

                } else if up && left && !corner {
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - 0.5 * d, y: center_y - 0.4 * d))
                    context.strokePath()
                    
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - 0.4 * d, y: center_y - 0.5 * d))
                    context.strokePath()
                    
                } else if up && left && corner {
                    // Nothing
                } else {
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - offset * d, y: center_y - 0.4 * d))
                    context.strokePath()
                    
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - 0.4 * d, y: center_y - offset * d))
                    context.strokePath()
                }
                
                //top right
                
                up = !(row - 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row - 1, column) }))
                var right = !(column + 1 > 8 || !occupiedBlocks.contains(where: { $0 == (row, column+1) }))
                corner = !(column + 1 > 8 || row - 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row-1, column+1) }))
                
                if up && !right {
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y - offset * d))
                    context.addLine(to: CGPoint(x: center_x + 0.4 * d, y: center_y - 0.5 * d))
                    context.strokePath()
                    
                } else if right && !up {
                    context.move(to: CGPoint(x: center_x + offset * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + 0.5 * d, y: center_y - 0.4 * d))
                    context.strokePath()

                } else if up && right && !corner {
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + 0.5 * d, y: center_y - 0.4 * d))
                    context.strokePath()
                    
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + 0.4 * d, y: center_y - 0.5 * d))
                    context.strokePath()
                    
                } else if up && right && corner {
                    // Nothing
                } else {
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + offset * d, y: center_y - 0.4 * d))
                    context.strokePath()
                    
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y - 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + 0.4 * d, y: center_y - offset * d))
                    context.strokePath()
                }
                
                //bottom right
                
                var down = !(row + 1 > 8 || !occupiedBlocks.contains(where: { $0 == (row + 1, column) }))
                right = !(column + 1 > 8 || !occupiedBlocks.contains(where: { $0 == (row, column+1) }))
                corner = !(column + 1 > 8 || row + 1 > 8 || !occupiedBlocks.contains(where: { $0 == (row+1, column+1) }))
                
                if down && !right {
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y + offset * d))
                    context.addLine(to: CGPoint(x: center_x + 0.4 * d, y: center_y + 0.5 * d))
                    context.strokePath()
                    
                } else if right && !down {
                    context.move(to: CGPoint(x: center_x + offset * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + 0.5 * d, y: center_y + 0.4 * d))
                    context.strokePath()

                } else if down && right && !corner {
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + 0.5 * d, y: center_y + 0.4 * d))
                    context.strokePath()
                    
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + 0.4 * d, y: center_y + 0.5 * d))
                    context.strokePath()
                    
                } else if down && right && corner {
                    // Nothing
                } else {
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + offset * d, y: center_y + 0.4 * d))
                    context.strokePath()
                    
                    context.move(to: CGPoint(x: center_x + 0.4 * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x + 0.4 * d, y: center_y + offset * d))
                    context.strokePath()
                }
                
                //bottom left
                
                down = !(row + 1 > 8 || !occupiedBlocks.contains(where: { $0 == (row + 1, column) }))
                left = !(column - 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row, column-1) }))
                corner = !(column - 1 < 0 || row - 1 < 0 || !occupiedBlocks.contains(where: { $0 == (row+1, column-1) }))
                
                if down && !left {
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y + offset * d))
                    context.addLine(to: CGPoint(x: center_x - 0.4 * d, y: center_y + 0.5 * d))
                    context.strokePath()
                    
                } else if left && !down {
                    context.move(to: CGPoint(x: center_x - offset * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - 0.5 * d, y: center_y + 0.4 * d))
                    context.strokePath()

                } else if down && left && !corner {
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - 0.5 * d, y: center_y + 0.4 * d))
                    context.strokePath()
                    
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - 0.4 * d, y: center_y + 0.5 * d))
                    context.strokePath()
                    
                } else if down && left && corner {
                    // Nothing
                } else {
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - offset * d, y: center_y + 0.4 * d))
                    context.strokePath()
                    
                    context.move(to: CGPoint(x: center_x - 0.4 * d, y: center_y + 0.4 * d))
                    context.addLine(to: CGPoint(x: center_x - 0.4 * d, y: center_y + offset * d))
                    context.strokePath()
                }
            }
        }
            
            class Cage {
                var index: Int
                var blocks: [Block]
                var allBlockCoordinates: [(Int, Int)] = []
                
                init(index: Int, blocks: [Block]) {
                    self.index = index
                    self.blocks = blocks
                    
                    for block in blocks{
                        allBlockCoordinates.append(block.coordinates)
                    }
                    
                    self.computeNeighbourBlocks()
                    self.findPrincipalBlock()
                }
                
                var cumulativeValue: Int {
                    var cumsum = 0
                    for block in blocks {
                        cumsum += block.value
                    }
                    return cumsum
                }
                
                func findPrincipalBlock() {
                    let minRow = self.blocks.min(by: { $0.row < $1.row })?.row ?? 0

                    let minRowBlocks = self.blocks.filter { $0.row == minRow }

                    if let minColumnBlock = minRowBlocks.min(by: { $0.column < $1.column }) {
                        minColumnBlock.cumulativeValue = self.cumulativeValue
                    }
                }
                
                func computeNeighbourBlocks() {
                    for block in self.blocks {
                        let neighbouringBlocks = block.getNeighbours()
                        var occupiedBlocks: [(Int, Int)] = []
                        
                        for neighbouringBlock in neighbouringBlocks {
                            if self.allBlockCoordinates.contains(where: { $0 == neighbouringBlock }) {
                                occupiedBlocks.append(neighbouringBlock)
                            }
                        }
                        block.occupiedBlocks = occupiedBlocks
                    }
                }
                
                func draw(context: CGContext, gridOrigin: CGPoint, d: CGFloat) {
                    for block in self.blocks {
                        block.draw(context: context, gridOrigin: gridOrigin, d: d)
                    }
                }
            }
            
            func get_all_cages(puzzle: sudokuClass) -> [Cage] {
                var cages: [Cage] = []
                
                let flattenedCages = puzzle.grid.cages.flatMap { $0 }
                let uniqueValues = Set(flattenedCages)
                for cage_index in uniqueValues {
                    var blocks: [Block] = []
                    for row in 0..<9 {
                        for column in 0..<9 {
                            if puzzle.grid.cages[row][column] == cage_index {
                                let value = puzzle.grid.answersPuzzle[row][column]
                                let block = Block(column: column, row: row, value: value, cageId: cage_index)
                                blocks.append(block)
                            }
                        }
                    }
                    cages.append(Cage(index: cage_index, blocks: blocks))
                }
                
                return cages
            }
            
            let cages = get_all_cages(puzzle: puzzle)
            
            for cage in cages {
                if let unwrappedContext = context {
                    cage.draw(context: unwrappedContext, gridOrigin: gridOrigin, d: d)
                }
            }
            
            //
            // Fill in puzzle numbers.
            //
            for row in 0 ..< 9 {
                for col in 0 ..< 9 {
                    var number : Int
                    if puzzle.userEntry(row: row, column: col) != 0 {
                        number = puzzle.userEntry(row: row, column: col)
                    } else {number=0}
//                    else {
//                        number = puzzle.numberAt(row: row, column: col)
//                    }
                    if (number > 0) {
                        var attributes : [NSAttributedString.Key : NSObject]? = nil
                        if puzzle.numberIsFixedAt(row: row, column: col) {
                            attributes = fixedAttributes
                        } else if puzzle.isConflictingEntryAt(row: row, column: col) {
                            attributes = conflictAttributes
                        } else if puzzle.userEntry(row: row, column: col) != 0 {
                            attributes = userAttributes
                        }
                        let text = "\(number)" as NSString
                        let textSize = text.size(withAttributes: attributes)
                        let x = gridOrigin.x + CGFloat(col)*d + 0.5*(d - textSize.width)
                        let y = gridOrigin.y + CGFloat(row)*d + 0.5*(d - textSize.height)
                        let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)
                        text.draw(in: textRect, withAttributes: attributes)
                    } else if puzzle.anyPencilSetAt(row: row, column: col) {
                        let scaling_factor = 0.6
                        let s = scaling_factor * d/3
                        for n in 1 ... 9 {
                            if puzzle.isSetPencil(n: n, row: row, column: col) {
                                let r = (n - 1) / 3
                                let c = (n - 1) % 3
                                let text : NSString = "\(n)" as NSString
                                let textSize = text.size(withAttributes: pencilAttributes)
                                let x = gridOrigin.x + CGFloat(col)*d + CGFloat(c)*s + (0.5*(1-scaling_factor)*d) + 0.5*(s - textSize.width)
                                let y = gridOrigin.y + CGFloat(row)*d + CGFloat(r)*s + (0.5*(1-scaling_factor)*d) + 0.5*(s - textSize.height)
                                let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)
                                text.draw(in: textRect, withAttributes: pencilAttributes)
                  
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
        
        }
    
    }
