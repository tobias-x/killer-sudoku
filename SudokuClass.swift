import Foundation
import UIKit

struct sudokuData: Codable {
    var answersPuzzle: [[Int]] = [[Int]] (repeating: [Int] (repeating: 0, count: 9), count: 9) // the answers to the puzzle
    var cages: [[Int]] = [[Int]] (repeating: [Int] (repeating: 0, count: 9), count: 9) // which cages each block belongs to
    var pencilPuzzle: [[[Bool]]] = [[[Bool]]] (repeating: [[Bool]] (repeating: [Bool] (repeating: false, count: 10), count: 9), count: 9)       // penciled values - 3d array of booleans
    var userPuzzle: [[Int]] = [[Int]] (repeating: [Int] (repeating: 0, count: 9), count: 9)           // user entries to puzzle
}

// 4. The Puzzle Model
class sudokuClass {
    var inProgress = false
    var grid: sudokuData! = sudokuData()
    
    // REQUIRED METHOD: Number stored at given row and column, with 0 indicating an empty cell or cell with penciled in values
    func numberAt(row : Int, column : Int) -> Int {
        if grid.answersPuzzle[row][column] != 0 {
            return grid.answersPuzzle[row][column]
        } else {
            return grid.userPuzzle[row][column]
        }
    }
    
    // REQUIRED METHOD: Number was provided as part of the puzzle, and so cannot be changed
    func numberIsFixedAt(row : Int, column : Int) -> Bool {
        if grid.answersPuzzle[row][column] != 0 {
            return true
        } else {
            return false
        }
    } // end numberIsFixedAt
    
    // TODO
    // REQUIRED METHOD: Number conflicts with any other number in the same row, column, or 3 × 3 square?
    func isConflictingEntryAt(row : Int, column: Int) -> Bool  {
        // get n
        var n: Int
        if grid.answersPuzzle[row][column] == 0 {
            n = grid.userPuzzle[row][column]
        } else {
            n = grid.answersPuzzle[row][column]
        }
        
        // if no value exists in entry -- no conflict
        if n == 0 { return false }
        
        // check all columns - if same number as current number (except current location) -- conflict
        for r in 0...8 {
            if r != row && (grid.answersPuzzle[row][column] == n || grid.userPuzzle[row][column] == n) {
                return true;
            }
        }
        
        // check all rows - if same number as current number (except current location) -- conflict
        for c in 0...8 {
            if c != column && (grid.answersPuzzle[row][column] == n || grid.userPuzzle[row][column] == n) {
                return true;
            }
        }
        
        // check all 3x3s
        // row, col = (0,0)-(8,8)
        let threeByThreeRow : Int = row / 3 // forced division
        let threeByThreeCol : Int = column / 3 // forced division
        // 0-2 = 0, 3-5 = 1, 6-8 = 2  ----> 0 + (0*3), 1 + (0*3), 2 + (0*3)
        // check rows and columns in these areas
        let startRow = threeByThreeRow * 3
        let startCol = threeByThreeCol * 3
        let endRow = 2 + (threeByThreeRow * 3)
        let endCol = 2 + (threeByThreeCol * 3)
        for r in startRow...endRow {
            for c in startCol...endCol {
                // if not the original square and contains the value n -- conflict
                if c != column && r != row && (grid.answersPuzzle[row][column] == n || grid.userPuzzle[row][column] == n) {
                    return true
                } // end if
            } // end c
        } // end r
        
        // no conflicts
        return false
    } // end isConflictingEntryAt
    
    // REQUIRED METHOD: Are the any penciled in values at the given cell?
    func anyPencilSetAt(row : Int, column : Int) -> Bool {
        for n in 0...8 {
            if grid.pencilPuzzle[row][column][n] == true {
                return true
            }
        }
        return false
    } // end anyPencilSetAt
        
    // REQUIRED METHOD: Is value n penciled in?
    func isSetPencil(n : Int, row : Int, column : Int) -> Bool {
        return grid.pencilPuzzle[row][column][n]
    }
    
    func plistToPuzzle(plist: String) -> ([[Int]],[[Int]]) {
        let parts = plist.components(separatedBy: "/")

        let part1 = parts[0].map{ String($0) }
        let part2 = parts[1].components(separatedBy: "-")

        func fillPuzzle(from strArray: [String]) -> [[Int]] {
            var result = [[Int]]()
            var currentIndex = 0
            for _ in 0...8 {
                var column = [Int]()
                for _ in 0...8 {
                    column.append(Int(strArray[currentIndex])!)
                    currentIndex += 9
                }
                result.append(column)
                currentIndex = result.count
            }
            return result
        }

        let puzzle1 = fillPuzzle(from: part1)
        let puzzle2 = fillPuzzle(from: part2)

        return (puzzle1, puzzle2)
    }

    // setter
    func userGrid(n: Int, row: Int, col: Int) {
        grid.userPuzzle[row][col] = n
    } // end userGrid
    
    // Is the piece a user piece
    func userEntry(row: Int, column: Int) -> Int {
        return grid.userPuzzle[row][column]
    } // end userEntry
    
    // setter - reverse
    func pencilGrid(n: Int, row: Int, col: Int) {
        grid.pencilPuzzle[row][col][n] = !grid.pencilPuzzle[row][col][n]
    } // end userGrid

    // setter - blank
    func pencilGridBlank(n: Int, row: Int, col: Int) {
        grid.pencilPuzzle[row][col][n] = false
    } // end userGrid
    
    func clearPencilPuzzle() {
        grid.pencilPuzzle = [[[Bool]]] (repeating: [[Bool]] (repeating: [Bool] (repeating: false, count: 10), count: 9), count: 9)
    }
    
    func clearUserPuzzle() {
        grid.userPuzzle = [[Int]] (repeating: [Int] (repeating: 0, count: 9), count: 9)
    }
    
    func clearConflicts() {
        for r in 0...8 {
            for c in 0...8 {
                if isConflictingEntryAt(row: r, column: c) {
                    grid.userPuzzle[r][c] = 0
                }
            }
        }
    }
    
    func gameInProgress(set: Bool) {
        inProgress = set
    }

}

