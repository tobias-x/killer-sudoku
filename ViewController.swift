import UIKit

func random(_ n:Int) -> Int {
    return Int(arc4random_uniform(UInt32(n)))
} // end random()

class DataManager {
    static func saveDataToLocalStorage(_ data: sudokuData) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let saveURL = documentsDirectory.appendingPathComponent("sudoku_save").appendingPathExtension("plist")

        do {
            let saveGame = try PropertyListEncoder().encode(data)
            try saveGame.write(to: saveURL, options: .atomic)
        } catch {
            print("Error saving data to local storage: \(error)")
        }
    }

    static func loadDataFromLocalStorage() -> sudokuData? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let loadURL = documentsDirectory.appendingPathComponent("sudoku_save").appendingPathExtension("plist")

        if let data = try? Data(contentsOf: loadURL) {
            let decoder = PropertyListDecoder()
            do {
                let loadedData = try decoder.decode(sudokuData.self, from: data)
                try? FileManager.default.removeItem(at: loadURL)
                return loadedData
            } catch {
                print("Error decoding saved data: \(error)")
            }
        }

        return nil
    }
}

class ViewController: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var PencilOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PencilOn = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DataManager.saveDataToLocalStorage(appDelegate.sudoku.grid)
    }
    
    @IBAction func pencilOn(_ sender: UIButton) {
        PencilOn = !PencilOn
        sender.isSelected = PencilOn
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var sudokuView: SudokuView!
    
    func refresh() {
        sudokuView.setNeedsDisplay()
    }
    
    @IBAction func NewGame(_ sender: Any) {
        let puzzle = appDelegate.sudoku
        performSegue(withIdentifier: "toPuzzle", sender: sender)
        let array = appDelegate.getPuzzles()
        let plist_tuple = puzzle.plistToPuzzle(plist: array[random(array.count)])
        puzzle.grid.answersPuzzle = plist_tuple.0
        puzzle.grid.cages = plist_tuple.1
        puzzle.clearUserPuzzle()
        puzzle.clearPencilPuzzle()
        DataManager.saveDataToLocalStorage(appDelegate.sudoku.grid)
    }
    
    @IBAction func Continue(_ sender: Any) {
        let puzzle = appDelegate.sudoku
        let load = DataManager.loadDataFromLocalStorage()
        print("\(String(puzzle.inProgress))")
        if puzzle.inProgress {
            performSegue(withIdentifier: "toPuzzle", sender: sender)
        } else if load != nil {
            appDelegate.sudoku.grid = load
            performSegue(withIdentifier: "toPuzzle", sender: sender)
        } else {
        let alert = UIAlertController(title: "Alert", message: "No Game in Progress & No Saved Games", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Default action"), style: .`default`, handler: { _ in
        }))
        self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var PuzzleArea: SudokuView!

    @IBOutlet weak var KeypadArea: UIView!
    
    @IBOutlet weak var KeypadVerticalGrid: UIStackView!
    
    @IBOutlet weak var KeypadNumericalGrid: UIStackView!
    
    @IBOutlet weak var KeypadActionButtonGrid: UIStackView!
    
    
    @IBAction func Keypad(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let puzzle = self.appDelegate.sudoku
        puzzle.gameInProgress(set: true)
        let grid = appDelegate.sudoku.grid
        let row = PuzzleArea.selected.row
        let col = PuzzleArea.selected.column
        if (row != -1 && col != -1) {
            if PencilOn == false {
                if grid?.userPuzzle[row][col] == 0  {
                    appDelegate.sudoku.userGrid(n: sender.tag, row: row, col: col)
                    refresh()
                } else if grid?.answersPuzzle[row][col] == 0 || grid?.userPuzzle[row][col] == sender.tag {
                    appDelegate.sudoku.userGrid(n: 0, row: row, col: col)
                    refresh()
                }
            } else {
                appDelegate.sudoku.pencilGrid(n: sender.tag, row: row, col: col)
                refresh()
            }
        }
        DataManager.saveDataToLocalStorage(appDelegate.sudoku.grid)
    }
    
    @IBAction func clearCell(_ sender: UIButton) {
        let row = PuzzleArea.selected.row
        let col = PuzzleArea.selected.column
        let grid = appDelegate.sudoku.grid
        
        if grid?.userPuzzle[row][col] != 0 {
            appDelegate.sudoku.userGrid(n: 0, row: row, col: col)
        }
        
        for i in 0...9 {
            appDelegate.sudoku.pencilGridBlank(n: i, row: row, col: col)
        }
        refresh()
        DataManager.saveDataToLocalStorage(appDelegate.sudoku.grid)
    }
}

