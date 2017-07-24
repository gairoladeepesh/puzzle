//
//  ViewController.swift
//  WAGAWIN
//
//  Created by Deepesh Gairola on 10/07/17.
//  Copyright © 2017 Deepesh Gairola. All rights reserved.
//

import UIKit


// MARK: UIImage extensions for resizing and cropping image

extension UIImage {
    
    func matrix(_ rows: Int, _ columns: Int) -> [UIImage] {
        
        let croppingWidth = (size.width / CGFloat(columns))
        let croppingHeight = (size.height / CGFloat(rows))
        
        var images: [UIImage] = []
        
        var xPos : CGFloat = 0.0
        var yPos : CGFloat = 0.0
        
        guard let cgImage = cgImage else { return [] }
        
        var tagCounter : Int = 0
        
        
        (0..<rows).forEach { row in
            
            xPos = 0.0
            
            (0..<columns).forEach { column in
                
                if let image = cgImage.cropping(to: CGRect(x: xPos, y: yPos, width: croppingWidth, height: croppingHeight)) {
                    let customImg = customImage(cgImage: image, scale: scale, orientation: imageOrientation)
                    customImg.imgTag = tagCounter
                    images.append(customImg)
                    xPos += croppingWidth
                    tagCounter += 1
                }
            }
            yPos += croppingHeight
        }
        return images
    }
    
    
    func resizedImage(cropSize: CGSize) -> UIImage {
        
        let rect = CGRect(x: 0, y: 0, width: cropSize.width, height: cropSize.height)
        UIGraphicsBeginImageContextWithOptions(cropSize, false, self.scale)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

// MARK: Array extension for randomizing

extension Array {
    
    mutating func shuffle () {
        for i in (0..<self.count).reversed() {
            let ix1 = i
            let ix2 = Int(arc4random_uniform(UInt32(i+1)))
            (self[ix1], self[ix2]) = (self[ix2], self[ix1])
        }
    }
}

// MARK: UIColor extensions for converting hex to UIColor

extension UIColor {
    class func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

// MARK: ViewController methods

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var imgViewBanner: UIImageView!
    var tempImage: UIImage!
    let spaceBetweenCells: CGFloat = 0.5
    var countdownDuration = Timer()
    var countDown : Int = 1
    var progressBarImgView = UIImageView()
    var viewProgress = UIView()
    var imageData = Data()
    var lblCounter = UILabel()
    var puzzleCounter : Int = 1
    
    var rows: Int = 3
    var columns: Int = 4
    
    
    @IBOutlet weak var btnClose: UIButton!
    
    @IBOutlet var viewPuzzle: UICollectionView!
    
    var images: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.hexStringToUIColor(hex: "#DCDCDC")
        let bannerURL = URL(string: "https://s3-eu-west-1.amazonaws.com/wagawin-ad-platform/media/testmode/banner-landscape.jpg")
        
        imageData = try! Data(contentsOf: bannerURL!)
        
        if #available(iOS 9.0, *) {
            self.viewPuzzle.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:))))
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configurePuzzle()
    }
    
    // MARK: Puzzle methods

    func configurePuzzle() {
        
        imgViewBanner = UIImageView()
        imgViewBanner.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(imgViewBanner)
        
        lblCounter = UILabel()
        lblCounter.translatesAutoresizingMaskIntoConstraints = false
        lblCounter.font = UIFont.systemFont(ofSize: 80)
        lblCounter.textColor = UIColor.white
        lblCounter.textAlignment = .center
        self.view.addSubview(lblCounter)
        
        addBannerConstraints()
        
        DispatchQueue.main.async {
            self.countDown = 1
            self.tempImage = UIImage(data: self.imageData)!
            self.tempImage = self.tempImage.resizedImage(cropSize: self.view.frame.size)
            self.imgViewBanner.image = self.tempImage
            
            self.perform(#selector(self.startCountDown), with: self, afterDelay: 2)
        }
    }
    
    func addBannerConstraints() {
        
        let views: [String: UIView] = ["imgViewBanner" : imgViewBanner, "lblCounter": lblCounter]
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[imgViewBanner]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[imgViewBanner]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        
        view.addConstraint(NSLayoutConstraint(item: lblCounter, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100))
        view.addConstraint(NSLayoutConstraint(item: lblCounter, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100))
        
        view.addConstraint(NSLayoutConstraint(item: lblCounter, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100))
        
        view.addConstraint(NSLayoutConstraint(item: lblCounter, attribute: .centerX, relatedBy: .equal, toItem: imgViewBanner, attribute: .centerX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: lblCounter, attribute: .centerY, relatedBy: .equal, toItem: imgViewBanner, attribute: .centerY, multiplier: 1, constant: 0))
        
        
    }
    
    @available(iOS 9.0, *)
    func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state)
        {
        case UIGestureRecognizerState.began:
            guard let selectedIndexPath = self.viewPuzzle!.indexPathForItem(at: gesture.location(in: self.viewPuzzle)) else
            {
                break
            }
            viewPuzzle!.beginInteractiveMovementForItem(at: selectedIndexPath)
        case UIGestureRecognizerState.changed:
            viewPuzzle!.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case UIGestureRecognizerState.ended:
            viewPuzzle!.endInteractiveMovement()
        default:
            viewPuzzle!.cancelInteractiveMovement()
        }
    }
    
    
    func startCountDown() {
        countdownDuration = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(animateCountDown), userInfo: nil, repeats: true)
        countdownDuration.fire()
    }
    
    func animateCountDown() {
        // Animate countdown in this step
        
        UIView.animate(withDuration: 1, animations: {
            UIView.transition(with: self.lblCounter, duration: 1, options: [.curveEaseInOut], animations: {
                self.lblCounter.text = "\(self.countDown)"
            }, completion: nil)
        }, completion: { _ in
            
        })
        
        if countDown == 4 {
            // Stop Countdown
            self.lblCounter.removeFromSuperview()
            countdownDuration.invalidate()
            startPuzzle()
        }
        
        countDown += 1
    }
    
    func startPuzzle() {
        // Remove main image
        self.imgViewBanner.removeFromSuperview()
        // Resize main image to fit puzzle view
        self.tempImage = self.tempImage.resizedImage(cropSize: self.viewPuzzle.frame.size)
        // Create a matrix for puzzle
        self.images = self.tempImage.matrix(rows, columns)
        self.images.shuffle()
        self.viewPuzzle.reloadData()
        
        configureProgressBar()
    }
    
    // MARK: Progressbar

    func configureProgressBar() {
        
        progressBarImgView = UIImageView()
        progressBarImgView.translatesAutoresizingMaskIntoConstraints = false
        progressBarImgView.image = UIImage(named: "counter_background.png")
        self.view.addSubview(progressBarImgView)
        addProgressConstraints()
        
        // Layout Subview Immediately
        self.view.layoutIfNeeded()
        
        viewProgress = UIView(frame: CGRect(x: progressBarImgView.frame.origin.x+4, y: progressBarImgView.frame.origin.y+4, width: progressBarImgView.frame.width-8, height: progressBarImgView.frame.height-8))
        
        viewProgress.backgroundColor = UIColor.hexStringToUIColor(hex: "#778FD5")
        
        self.view.addSubview(viewProgress)
        
        
        UIView.animate(withDuration: 21, animations: {
            self.viewProgress.frame = CGRect(x: self.viewProgress.frame.origin.x, y: self.viewProgress.frame.origin.y, width: self.viewProgress.frame.width, height: 0)
        }, completion: { _ in
            
            let alert = UIAlertController(title: "Alert", message: "Time over. Do you want to play again? Press Re-Try to play again.", preferredStyle: .alert)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                //Do Nothing
            }
            alert.addAction(cancelAction)
            
            let retryAction = UIAlertAction(title: "Re-Try", style: .default) { action -> Void in
                self.configurePuzzle()
            }
            
            alert.addAction(retryAction)
            
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    func addProgressConstraints() {
        
        let views: [String: UIView] = ["viewPuzzle": viewPuzzle, "btnClose": btnClose, "progressBarImgView": progressBarImgView, "viewProgress": viewProgress]
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[viewPuzzle]-10-[progressBarImgView]-10-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[btnClose]-2-[progressBarImgView]-10-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
 
        
    }
    
    // MARK: Puzzle collection view delegate methods

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: puzzleCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIdentifier", for: indexPath) as! puzzleCollectionViewCell

        if self.images.count>0 {
            let customImg = self.images[indexPath.row] as! customImage
            cell.puzzleImg.image = customImg
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rows*columns
    }
    
    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let cell: puzzleCollectionViewCell = collectionView.cellForItem(at: destinationIndexPath) as! puzzleCollectionViewCell
        
        let customImg = cell.puzzleImg.image as! customImage
        
        if destinationIndexPath.row == customImg.imgTag {
            
            if puzzleCounter == rows*columns {
                //Player has won//
            }
            puzzleCounter += 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let heightPerItem = self.viewPuzzle.frame.height/3
        let widthPerItem = self.viewPuzzle.frame.width/4
        
        return CGSize(width: widthPerItem-spaceBetweenCells, height: heightPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionStopPuzzle(_ sender: Any) {
        // Can be redirected to desired action //
        
    }
}

