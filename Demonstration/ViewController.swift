//
//  ViewController.swift
//  Demonstration
//
//  Created by 송민준 on 2022/11/04.
//

import UIKit
import SQLite3

class ViewController: UIViewController {
    @IBOutlet weak var StatusBar: UILabel!
    let dbHelper = DBHelper.shared
    let launchedBefore: Bool = UserDefaults.standard.bool(forKey: "launchedBefore")
    let formatter = DateFormatter()
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        if launchedBefore {
            StatusBar.text? = "Launched Before."
        }
        else{
            StatusBar.text? = "First Launch."
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            //Database Create
            dbHelper.createTable()
            dbHelper.insertData(id: 0, demo_date: formatter.date(from: "2022-11-11 19:35")!, location: "미래관 447호", description: "퇴근 시위 중")
            dbHelper.insertData(id: 1, demo_date: formatter.date(from: "2022-11-12 08:30")!, location: "별내동 신안인스빌", description: "밥 투정 중")
            if let result = dbHelper.readData() {
                print(result)
            }
        }
    }
    
    @IBAction func renewButtonClicked(_ sender: UIButton) {
        
    }
    

}
class DBHelper {
    static let shared = DBHelper()
    var db : OpaquePointer?
    var path = "mySqlite.sqlite"
    init(){
        self.db = createDB()
    }
    deinit{
        sqlite3_close(db)
    }
    func createDB() -> OpaquePointer? {
        do{
            let filePath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathExtension(path)
            if sqlite3_open(filePath.path, &db) == SQLITE_OK{
                print("Successfully create DB :  \(filePath.path)")
                return db
            }
        }
        catch{
            print("Error(CreateDB): \(error.localizedDescription)")
        }
        print("Error(CreateDB): sqlite3_open ")
        return nil
    }
    func createTable(){
        let query = """
        CREATE TABLE IF NOT EXISTS myTable(id INTEGER PRIMARY KEY AUTOINCREMENT, demo_date DATETIME NOT NULL, location TEXT NOT NULL, description TEXT);
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Succesfully Create Table : \(String(describing: self.db))")
            }
            else{
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("sqlite3_step fail while creating table : \(errorMessage)")
            }
        }
        else{
            let errorMessage = String(cString: sqlite3_errmsg(self.db))
            print("sqlite3_prepare fail while creating table: \(errorMessage)")
        }
        sqlite3_finalize(statement) // 메모리 할당 해제
    }
    func insertData(id: Int, demo_date: Date, location: String, description: String){
        let insertQuery = "insert into myTable(id, demo_date, location, description) values (?,?,?,?);"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString = formatter.string(from: demo_date)
            
            let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_int(statement, 1, Int32(id))
            sqlite3_bind_text(statement, 2, dateString, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, location, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, description, -1, SQLITE_TRANSIENT)
        }
        else{
            print("sqlite3_prepare fail: \(String(cString:sqlite3_errmsg(db)))")
        }
        if sqlite3_step(statement) == SQLITE_DONE {
            print("sqlite3_step insertion Success!")
        }
        else{
            print("sqlite3_step insertion fail: \(String(cString:sqlite3_errmsg(db)))")
        }
    }
    func readData() -> [[Any]]? {
        let query: String = "SELECT * FROM myTable"
        var statement: OpaquePointer? = nil
        var result: [[Any]] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if sqlite3_prepare(self.db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var tmpResult: [Any] = []
                let id = sqlite3_column_int(statement, 0)
                let dateString = sqlite3_column_text(statement, 1)
                let demo_date = dateFormatter.date(from: String(cString: dateString!))!
                let location = String(cString:sqlite3_column_text(statement, 2))
                let description = String(cString: sqlite3_column_text(statement, 3))
                tmpResult.append([id, demo_date, location, description])
                result.append(tmpResult)
            }
            return result
        }
        else{
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            print("sqlite3_prepare fail while read data: \(errorMessage)")
            return nil
        }
    }
}
