//
//  MovieDetailsViewController.swift
//  Flicks
//
//  Created by Ngan, Naomi on 9/14/17.
//  Copyright © 2017 Ngan, Naomi. All rights reserved.
//

import UIKit

class MovieDetailsViewController: UIViewController {

    @IBOutlet weak var posterView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var synopsisLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    
    var movie: [String: Any] = [String: Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let path = movie["poster_path"] as? String {
            let lowResPosterUrl = URL(string: "https://image.tmdb.org/t/p/w45" + path)
            let highResPosterUrl = URL(string: "https://image.tmdb.org/t/p/original" + path)
            
            // Load the low-res image first and switch to high-res when complete
            let imageRequest = URLRequest(url: lowResPosterUrl!)
            posterView.setImageWith(imageRequest, placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                                            
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Detailed image was NOT cached, fade in image")
                        self.posterView.alpha = 0.0
                        self.posterView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            self.posterView.alpha = 1.0
                        })
                    } else {
                        
                        print("Detailed image was cached so just update the image")
                        self.posterView.image = image
                    }
                    print("Low resolution image loaded")
                    
                    // Low-res image loaded.  Now load the high-res picture
                    // Libraries don't guarantee that closures are called from the main thread, so re-dispatch to the main thread
                    DispatchQueue.main.async {
                        self.posterView.setImageWith(highResPosterUrl!)
                        print("High resolution image loaded")
                    }
                    
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    self.posterView.image = UIImage(named: "placeholder")
                }
            )
            
            
        } else {
            posterView.image = UIImage(named: "placeholder")
        }
        
        if let date = movie["release_date"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let releaseDate = dateFormatter.date(from: date)!
            dateFormatter.dateFormat = "MMM dd, YYYY"
            let readableDateString = dateFormatter.string(from: releaseDate)
        
            dateLabel.text = readableDateString
        }
       
        titleLabel.text = movie["title"] as? String
        
        synopsisLabel.text = movie["overview"] as? String
        synopsisLabel.sizeToFit()
        
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
