//
//  HomeTableViewController.swift
//  Lolita-public
//
//  Created by Sam on 4/28/15.
//  Copyright (c) 2015 Ding Sai. All rights reserved.
//

import UIKit

class HomeTableViewController: UITableViewController {

    var height:CGFloat?
    var indexNo:NSInteger?
    
    var statusData: FeedsData?
    
    
    private enum magicNumber: Int {
        case changeCover = 3391
        case addTwitter = 3392
    }
    var currentindexPath: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    
    private var imagePicker : UIImagePickerController?
    /// 行高缓存
    lazy var rowHeightCache: NSCache? = {
        return NSCache()
        }()
    
    /// 上拉视图懒加载
    lazy var pullupView:RefreshView = {
        /// 转，不显示箭头
        return RefreshView.refreshView(isLoading: true)
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let rightitem = UIBarButtonItem(image: UIImage(named: "twiPlus"), style: UIBarButtonItemStyle.Plain, target: self, action: "rightButtonPressed:")
        self.navigationItem.rightBarButtonItem = rightitem
        setupPullupView()
        
        loadData()
        
        
    }
    
    /// 设置上拉数据加载视图
    func setupPullupView(){
        tableView.tableFooterView = pullupView
        
        weak var weakSelf = self
        pullupView.addPullupOberserver(tableView){
            println("上啦加载数据啦！！！！")
            
            /// 获取到maxId
            weakSelf?.loadData()
            
        }
    }
    
    deinit {
        println("home视图控制器被释放!!!!!!")
        
        // 主动释放加载刷新视图对tableView的观察
        tableView.removeObserver(pullupView, forKeyPath: "contentOffset")
    }
    
    
    func loadData() {
        
        println("加载数据")
        
        refreshControl?.beginRefreshing()
        
        weak var weakSelf = self
        
        FeedsData.loadFeed("PostFeed") { (data, error) -> () in
            
            weakSelf!.refreshControl?.endRefreshing()
            
            if error != nil{
                println(error)
                SVProgressHUD.showInfoWithStatus("网络繁忙请重试")
            }
            if data != nil{
                
                weakSelf?.statusData = data
                weakSelf?.tableView.reloadData()
                    
                /// 复位刷新视图属性
                weakSelf?.pullupView.isPullupLoading = false
                weakSelf?.pullupView.stopLoading()
                
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showComment"{
            let destinationVC = segue.destinationViewController as! CommentViewController
            let celldata = sender as! Feed
            destinationVC.feedData = celldata
        }else if segue.identifier == "showAdd"{
            let destinationVC = segue.destinationViewController as! AddViewController
            let caseNumber = sender as! Int
            destinationVC.delegate = self
            switch caseNumber{
            case 0:
                destinationVC.currentType = .text
            case 1:
                destinationVC.currentType = .image
            default:
                break
            }
        }
    }
    
    func rightButtonPressed(sender: AnyObject) {
        let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil, otherButtonTitles: "新建文字消息", "新建图文消息", "取消")
        actionSheet.destructiveButtonIndex = 2
        actionSheet.tag = magicNumber.addTwitter.rawValue
        actionSheet.showInView(self.view)
    }
 

}

extension HomeTableViewController:UITableViewDataSource,UITableViewDelegate{
    
    ///  根据indexPath 返回微博数据&可重用标识符
    func cellInfo(indexPath: NSIndexPath) -> (status: Feed, cellId: String) {
        let status = self.statusData!.feedsData[indexPath.row]
        let cellId = HomeFeedsCell.cellIdentifier(status)
        
        //        println("耗时操作 indexPath \(indexPath.row)  " + __FUNCTION__)
        
        return (status, cellId)
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.statusData?.feedsData.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // 提取cell信息
        let info = cellInfo(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(info.cellId, forIndexPath: indexPath) as! HomeFeedsCell
        
        //            dispatch_async(dispatch_get_main_queue(), { () -> Void in
        //
        //            })
        
        if cell.photoDidSelected == nil{
            cell.photoDidSelected = { (status:Feed!,index:Int)-> Void in
                //                println("\(status.text) \(index)")  // $$$$$
                weak var weakSelf = self
                
                
                
                let vc = PhotoBrowserlViewController.photoBrowserViewController()
                
                vc.urls = status.postImageUrls
                vc.selectedIndex = index
                //vc.modalTransitionStyle = UIModalTransitionStyle.PartialCurl

                weakSelf!.presentViewController(vc, animated: true, completion: nil)
                
            }
        }
        cell.indexPath = indexPath
        
        cell.delegate = self
        
        cell.status = info.status
        
        return cell
    }
    
    // 行高的处理
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // 提取cell信息
        let info = cellInfo(indexPath)
        // 判断是否已经缓存了行高
        if let h = rowHeightCache?.objectForKey("\(info.status.id)") as? NSNumber {
            //            println("从缓存返回 \(h)")
            return CGFloat(h.floatValue)
        } else {
            //            println("计算行高 \(__FUNCTION__) \(indexPath)")
            let cell = tableView.dequeueReusableCellWithIdentifier(info.cellId) as! HomeFeedsCell
            let height = cell.cellHeight(info.status)
            
            // 将行高添加到缓存 - swift 中向 NSCache/NSArray/NSDictrionary 中添加数值不需要包装
            rowHeightCache!.setObject(height, forKey: "\(info.status.id)")
            
            return cell.cellHeight(info.status)
        }
    }
    
    // 预估行高，可以提高性能
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 300
    }
    
}



extension HomeTableViewController: UIActionSheetDelegate {
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        switch actionSheet.tag {
        case magicNumber.addTwitter.rawValue:
            // 新建
            switch buttonIndex {
            case 0:
                self.performSegueWithIdentifier("showAdd", sender: buttonIndex)
            case 1:
                self.performSegueWithIdentifier("showAdd", sender: buttonIndex)
            default:
                break
            }
        case magicNumber.changeCover.rawValue:
            //            println("change cover at \(buttonIndex)")
            if buttonIndex == 0 {
                imagePicker = UIImagePickerController()
                imagePicker?.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
                imagePicker?.delegate = self
                presentViewController(imagePicker!, animated: true, completion: nil)
            }
        default:
            break
        }
    }
    func willPresentActionSheet(actionSheet: UIActionSheet) {
        for subView in actionSheet.subviews {
            if subView is UIButton {
                let button = subView as! UIButton
                if button.titleLabel?.text != "取消" {
                    button.setTitleColor(UIColor.LolitaThemeDarkText(), forState: UIControlState.Normal)
                }
            }
        }
    }
}



extension HomeTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
    }
}



extension HomeTableViewController: HomeFeedsCellDelegate{
    
    
    func HomeFeedsCellStar(indexPath: NSIndexPath){
        
        
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)

        
    }

    func HomeFeedsCellComment(indexPath: NSIndexPath){
        let celldata = statusData?.feedsData[indexPath.row]
        println("~~~~~~~~~~~~")
        println(celldata)
        println(indexPath.row)
        println("~~~~~~~~~~~~")
        performSegueWithIdentifier("showComment", sender: celldata)
    }

    func HomeFeedsCellShare(indexPath: NSIndexPath){
        
    }
    
    
}


extension HomeTableViewController: AddCircleDelegate {
    func addCircleDone() {
        loadData()
    }
}
