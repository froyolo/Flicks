//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Ngan, Naomi on 9/14/17.
//  Copyright © 2017 Ngan, Naomi. All rights reserved.
//

import UIKit
import AFNetworking
import CircularSpinner

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
    
    
    @IBOutlet weak var resultsView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies: [[String: Any]] = [[String: Any]]()
    var endpoint: String?
    var queryParams: String! = ""
    let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set datasource and delegate
        tableView.dataSource = self
        tableView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
        
        if (endpoint != nil) {
            
            // Display progress HUD right before the request is made
            CircularSpinner.show("Loading", animated: false, type: CircularSpinnerType.indeterminate, showDismissButton: false, delegate: nil)
        
            // Call movie API
            loadMovieData()
        
            // Initialize a UIRefreshControl for pull-to-refresh functionality
            let refreshControlTable = UIRefreshControl()
            let refreshControlCollection = UIRefreshControl()
        
            // Bind action to UIRefreshControl so something will happen when you pull-to-refresh
            refreshControlTable.addTarget(self, action: #selector(refreshControlActionTable(_:)), for: UIControlEvents.valueChanged)
            refreshControlCollection.addTarget(self, action: #selector(refreshControlActionCollection(_:)), for: UIControlEvents.valueChanged)
        
            // Add refresh control to table and collection views. I.e. Insert the UIRefreshControl as a subview of your table view
            tableView.insertSubview(refreshControlTable, at: 0)
            collectionView.insertSubview(refreshControlCollection, at: 0)
        }
        
        // Add the segmented control to the navigation bar programmatically
        let segmentedControl = UISegmentedControl(items: [ UIImage(named: "list")!, UIImage(named: "grid")!])
        segmentedControl.sizeToFit()
        segmentedControl.selectedSegmentIndex = 0
        
        segmentedControl.addTarget(self, action: #selector(viewTypeChanged(segmentedControl:)), for: .valueChanged)
        let segmentedButton = UIBarButtonItem(customView: segmentedControl)
        navigationItem.rightBarButtonItems = [segmentedButton]
        
        
    }
    
    func viewTypeChanged(segmentedControl: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            collectionView.isHidden = true
            tableView.isHidden = false
            
        case 1:
            collectionView.isHidden = false
            tableView.isHidden = true
        default:
            break
        }
    }
    
    
    func loadMovieData() {
        let url = URL(string:"https://api.themoviedb.org/3/\(endpoint!)?api_key=\(apiKey)&\(queryParams!)")
        let request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            // Make sure the progress HUD is hidden once the network request comes back
            CircularSpinner.hide()
            
            if let error = error {
                // Show network error message
                self.networkErrorView.isHidden = false
                
                print(error)
            } else if let data = data,
                let dictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                // Hide network error message
                self.networkErrorView.isHidden = true
                self.movies = dictionary["results"] as! [[String:Any]]
                if self.movies.count == 0 {
                    self.resultsView.isHidden = false // Show "No Results Found" view
                } else {
                    self.resultsView.isHidden = true
                    self.tableView.reloadData()
                    self.collectionView.reloadData()
                }
                
            }
            
        }
        task.resume()
        
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Reload stuff if search text is cleared out
        if (self.tabBarController?.selectedIndex == 0) {
            endpoint = "movie/now_playing"
        } else {
            endpoint = "movie/top_rated"
        }
        loadMovieData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        endpoint = "search/movie"
        
        queryParams = "&query=" + searchBar.text!
        queryParams = queryParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        loadMovieData()
    }
    
    // Makes a network request to get updated data for the pull-to-refresh feature
    func refreshControlActionTable(_ refreshControl: UIRefreshControl) {
        // Load movie data
        loadMovieData()
        
        // Tell the refreshControl to stop spinning
        refreshControl.endRefreshing()
    }
    
    func refreshControlActionCollection(_ refreshControl: UIRefreshControl) {
        // Load movie data
        loadMovieData()
        
        // Tell the refreshControl to stop spinning
        refreshControl.endRefreshing()
    }
    
    
    func getPosterUrl(movieRow: Int) -> URL? {
        let movie = movies[movieRow]
        if let path = movie["poster_path"] as? String {
            var baseUrl: String!
            baseUrl = "http://image.tmdb.org/t/p/w342"
            
            let posterUrl = URL(string: baseUrl + path)!
            return posterUrl
        } else {
            return nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieGridCell", for: indexPath) as! MovieGridCell
        if let posterUrl = getPosterUrl(movieRow: indexPath.row) {
            let imageRequest = URLRequest(url: posterUrl)
            cell.posterView.setImageWith(imageRequest, placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                                            
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        //print("Image was NOT cached, fade in image")
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.posterView.alpha = 1.0
                        })
                    } else {
                        //print("Image was cached so just update the image")
                        cell.posterView.image = image
                    }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // Load placeholder image
                    cell.posterView.image = UIImage(named: "placeholder")
                }
            )
            
        } else {
            cell.posterView.image = UIImage(named: "placeholder")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.lightGray
        tableView.cellForRow(at: indexPath)?.selectedBackgroundView = backgroundView
        
        // Remove gray selection effect
        tableView.deselectRow(at: indexPath, animated:true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell") as! MovieCell
    
        let movieRow = indexPath.row
        let movie = movies[movieRow]
        let title = movie["title"] as? String
        let synopsis = movie["overview"] as? String
        
        cell.titleLabel.text = title
        cell.synopsisLabel.text = synopsis
        
        if let posterUrl = getPosterUrl(movieRow: indexPath.row) {
            let imageRequest = URLRequest(url: posterUrl)
            cell.posterView.setImageWith(imageRequest, placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                                            
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        //print("Image was NOT cached, fade in image")
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.posterView.alpha = 1.0
                            })
                    } else {
                        //print("Image was cached so just update the image")
                        cell.posterView.image = image
                    }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    cell.posterView.image = UIImage(named: "placeholder")
                }
            )
        } else {
            cell.posterView.image = UIImage(named: "placeholder")
        }
        
        return cell
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get reference to the MovieDetailsViewController
        let detailsViewController = segue.destination as! MovieDetailsViewController
        
        // Get the indexPath of the selected movie
        var indexPath: IndexPath!
        if segue.identifier == "listSegue" {
            indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
        } else if segue.identifier == "gridSegue" {
            indexPath = collectionView.indexPath(for: sender as! UICollectionViewCell)!
        }
        
        // Set the movie property 
        let movie = movies[indexPath.row]
        detailsViewController.movie = movie
    }

}
