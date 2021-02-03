//
//  DownloadTableViewController.swift
//  DaisyNet
//
//  Created by mengqingzheng on 2017/10/14.
//  Copyright © 2017年 MQZHot. All rights reserved.
//

import UIKit
import MediaPlayer
class DownloadTableViewController: UITableViewController {

    let downloadUrls = ["https://hyjj-chatm.oss-cn-beijing.aliyuncs.com/looktm-eye-report/2018%20%E6%AF%8D%E5%A9%B4%20App%20%E8%A1%8C%E4%B8%9A%E5%88%86%E6%9E%90%E6%8A%A5%E5%91%8A.pdf",
                        "http://120.25.226.186:32812/resources/videos/minion_02.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_03.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_04.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_05.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_06.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_07.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_08.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_09.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_10.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_11.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_12.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_13.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_14.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_15.mp4",
                        "http://120.25.226.186:32812/resources/videos/minion_16.mp4"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "DownloadCell", bundle: nil), forCellReuseIdentifier: "downloadCell")
        
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadUrls.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let url = downloadUrls[indexPath.row]
        let status = DaisyNet.downloadStatus(url)
        let progress = DaisyNet.downloadPercent(url)
        let cell = tableView.dequeueReusableCell(withIdentifier: "downloadCell", for: indexPath) as! DownloadCell
        cell.indexPath = indexPath
        cell.updateCell(status, progress: progress)
        cell.download = { [weak self] in
            self?.downloadAction($0)
        }
        cell.delete = { [weak self] in
            self?.deleteAction($0)
        }
        /// 退出界面再进入，获取下载状态
        DaisyNet.downloadProgress(url) {[weak self] in
            print($0)
            self?.update(indexPath)
            }?.response(completion: { [weak self] _ in
                self?.update(indexPath)
            })
        return cell
    }
    // MARK: - 点击事件
    func downloadAction(_ indexPath: IndexPath) {
        
        let url = downloadUrls[indexPath.row]
        let downloadStatus = DaisyNet.downloadStatus(url)
        switch downloadStatus {
        case .complete:     /// 完成
            if let path = DaisyNet.downloadFilePath(url) {
                let mediaVC = MPMoviePlayerViewController(contentURL: path)
                self.present(mediaVC!, animated: true, completion: nil)
            }
        case .downloading:  /// 暂停
            DaisyNet.downloadCancel(url)
        case .suspend:      /// 下载
            /// hud
            DaisyNet.download(url, fileName: "\(indexPath.row)---.mp4").downloadProgress {[weak self] in
                self?.update(indexPath)
                print($0)
                }.response {[weak self] _ in
                    self?.update(indexPath)
            }
        }
    }
    
  
    @IBAction func cancelAll(_ sender: UIBarButtonItem) {
        DaisyNet.downloadCancelAll()
    }
    func update(_ indexPath: IndexPath) {
        let url = downloadUrls[indexPath.row]
        let cell = self.tableView.cellForRow(at: indexPath) as? DownloadCell
        let status = DaisyNet.downloadStatus(url)
        let progress = DaisyNet.downloadPercent(url)
        cell?.updateCell(status, progress: progress)
    }
    
    // MARK: - 删除
    func deleteAction(_ indexPath: IndexPath) {
        let url = downloadUrls[indexPath.row]
        DaisyNet.downloadDelete(url) { [weak self] (result) in
            if result {
                self?.update(indexPath)
            } else {
                print("删除失败")
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    deinit {
        print("dealloc")
    }
}
