import UIKit
import AFNetworking
import SafariServices
import SVProgressHUD
import SharediOS

class ViewController: UIViewController, SOSNewsView {
    static var shownIds = [Int32:Bool]()
    @IBOutlet weak var tableView: UITableView!
    var items = [SOSNews]()
    private var refreshControl: UIRefreshControl?
    var noMatchesLabel: UILabel?
    
    var presenter: SOSNewsPresenter!
    
    var loading: Bool {
        get { return self.refreshControl!.isRefreshing }
        set(value) {
            if value {
                
            } else {
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    var refresh: Bool {
        get { return SVProgressHUD.isVisible() }
        set(value) {
            if value {
                SVProgressHUD.show()
            } else {
                SVProgressHUD.dismiss()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = SOSNewsPresenter(
            uiContext: SOSMainQueueDispatcher(),
            view: self,
            newsRepository: NewsRepositoryImpl()
        )
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        self.initTableView()
        
        presenter.onCreate()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView(_:)), name: NSNotification.Name(rawValue: "UpdateTableView"), object: nil)
    }
    
    @objc func refreshData(refControl: Any?) {
        presenter.onRefresh()
    }
    
    @objc func updateTableView(_ not:Notification) {
        let row = not.object as! Int
        let indexPath = IndexPath(row: row, section: 0)
        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
    }
    
    func showList(news: [SOSNews]) {
        items = news
        tableView.reloadData()
    }
    
    func logError(error: SOSStdlibThrowable) {
        print(error.message ?? "Unknown error")
    }
    
    func showError(error: SOSStdlibThrowable) {
        showError(error.message)
    }

    func showError(_ error: String?) {
        let alertController = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: 0, y: UIScreen.main.bounds.size.height-20, width: UIScreen.main.bounds.size.width, height: 20)

        let okAction = UIAlertAction(title: "Ok", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        showNoItem()
        tableView.reloadData()
    }

    func showNoItem() {
        if noMatchesLabel == nil {
            noMatchesLabel = UILabel()
            noMatchesLabel?.textColor = UIColor.lightGray
            noMatchesLabel?.text = "No items available"
            noMatchesLabel?.font = UIFont.systemFont(ofSize: 15)
            noMatchesLabel?.sizeToFit()
        }
        noMatchesLabel?.center = CGPoint(x:UIScreen.main.bounds.size.width/2.0, y:tableView.frame.size.height/2.0)
        tableView.insertSubview(noMatchesLabel!, at: 0)
    }
    
    func hideNoItem() {
        if noMatchesLabel != nil {
            noMatchesLabel?.removeFromSuperview()
        }
    }
    
    func initTableView() {
        tableView.register(UINib(nibName: "KotlinCell", bundle: nil), forCellReuseIdentifier: "KotlinCell")
        tableView.register(UINib(nibName: "KotlinCellShown", bundle: nil), forCellReuseIdentifier: "KotlinCellShown")
        tableView.register(cellType: ArticleCell.self)
        tableView.register(cellType: InfoCell.self)
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(self.refreshData), for: .valueChanged)
        tableView?.addSubview(refreshControl!)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }
}


extension ViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - table view delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if items.count != 0 {
            self.hideNoItem()
        }
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        switch item {
        case let item as SOSArticle:
            let cell: ArticleCell = tableView.dequeueReusableCell(for: indexPath)
            cell.config(item)
            return cell
        case let item as SOSInfo:
            let cell: InfoCell = tableView.dequeueReusableCell(for: indexPath)
            cell.config(item)
            return cell
        default:
            let item = item as! SOSPuzzler
            let CellIdentifier = ViewController.shownIds[item.id] == true ? "KotlinCellShown" : "KotlinCell"
            let cell = self.tableView?.dequeueReusableCell(withIdentifier: CellIdentifier) as! KotlinCell
            cell.config(item)
            cell.selectionStyle = .none
            cell.row = indexPath.row
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        switch item {
        case let item as SOSArticle:
            openUrl(item.url)
        case let item as SOSInfo:
            openUrl(item.url)
        default: break
        }
    }
}

