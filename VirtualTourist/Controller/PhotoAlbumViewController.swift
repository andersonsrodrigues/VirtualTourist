//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 02/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    var dataController: DataController!
    var pin: Pin!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!

    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "farmId", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        
        setupFetchedResultsController()
        
        initMap()
        hasImagesToShow(false, "Downloading")
        renderCollectionFlowLayout()
        
        newCollectionButton.target = self
        newCollectionButton.action = #selector(requestFlickrPhotos(sender:))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
        
        setupFetchedResultsController()
        
        if let numOfObjects = fetchedResultsController.sections?[0].numberOfObjects {
            hasImagesToShow(numOfObjects > 0)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    func renderCollectionFlowLayout() {
        let space:CGFloat = 6.0
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        var dimension = (width - (2 * space)) / 2.0
        
        if width > height {
            dimension = (height - (2 * space)) / 2.0
        }

        self.flowLayout.minimumInteritemSpacing = space
        self.flowLayout.minimumLineSpacing = space
        self.flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func hasImagesToShow(_ status: Bool,_ text: String? = "No Images") {
        noImageLabel.text = text
        
        noImageLabel.isHidden = status
        collectionView.isHidden = !status
        newCollectionButton.isEnabled = status
    }
    
    func addImage(p: PhotoData) {
        let photo = Photo(context: self.dataController.viewContext)
        photo.id = p.id
        photo.secret = p.secret
        photo.serverId = p.server
        photo.farmId = Int32(p.farm)
        photo.pin = self.pin
        
        try? self.dataController.viewContext.save()
    }
    
    func deleteImage(at indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        try? dataController.viewContext.save()
    }
    
    func deleteAllImages() {
        if let objects = fetchedResultsController.fetchedObjects {
            for obj in objects {
                dataController.viewContext.delete(obj)
                
                try? dataController.viewContext.save()
            }
        }
    }
    
    @objc func requestFlickrPhotos(sender: UIBarButtonItem) {
        hasImagesToShow(false, "Downloading")
        
        VTClient.getPhotosByLocation(lat: pin.latitude, long: pin.longitude, page: Int(pin.page + 1)) { (photos, error) in
            
            if let error = error {
                self.showAlertFailure(title: "Failed to load photos on this location", message: error.localizedDescription)
                return
            }
            
            self.deleteAllImages()
            
            for photo in photos {
                self.pin.page += 1
                self.addImage(p: photo)
            }
            
            if photos.count > 0 {
                self.hasImagesToShow(true)
            } else {
                self.hasImagesToShow(false)
            }
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCollectionCell", for: indexPath as IndexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.object(at: indexPath)
        
        if let data = photo.image {
            cell.photoImageView?.image = UIImage(data: data)
        } else {
            cell.photoImageView?.image = UIImage(named: "picture")
            
            if let id = photo.id, let secret = photo.secret, let serverId = photo.serverId {
                VTClient.downloadPhotoImage(id: id, secret: secret, serverId: serverId, farmId: Int(photo.farmId)) { (data, error) in
                    guard let data = data else {
                        return
                    }
                    let image = UIImage(data: data)
                    cell.photoImageView?.image = image
                    photo.image = data
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Remove Image", message: "Would like to remove this image?", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Remove", style: .default, handler: { _ in
            self.deleteImage(at: indexPath)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func initMap() {
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let zoom = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: zoom)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        mapView.setRegion(region, animated: false)
        mapView.isUserInteractionEnabled = false
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            collectionView.moveItem(at: indexPath!, to: newIndexPath!)
        default:
            break;
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: collectionView.insertSections(indexSet)
        case .delete: collectionView.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        default:
            break;
        }
    }
    
}
