//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 02/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var selectedPin: Pin!
    
    fileprivate func setupFetchedResultController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        
        setupFetchedResultController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        
        setupFetchedResultController()
        
        setLocationOnMap()
        parseLocations()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    
    // MARK: - Actions
    
    @IBAction func longPressedMapAddPin(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            triggerLongPressAction(gestureRecognizer: sender)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "photoViewSegue" {
            let photoViewController = segue.destination as! PhotoAlbumViewController
            photoViewController.pin = selectedPin
            photoViewController.dataController = dataController
        }
    }
    
    func addPin(coordinate: CLLocationCoordinate2D) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        try? dataController.viewContext.save()
            
        requestFlickrPhotos(by: coordinate, at: pin)
    }

    func deselecteAnnotation() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: selectedPin.latitude, longitude: selectedPin.longitude)
        
        mapView.deselectAnnotation(annotation, animated: true)
    }
    
    func requestFlickrPhotos(by coordinate: CLLocationCoordinate2D, at pin: Pin) {
        VTClient.getPhotosByLocation(lat: coordinate.latitude, long: coordinate.longitude, page: Int(pin.page)) { (photos, error) in
            
            if let error = error {
                self.showAlertFailure(title: "Failed to load photos on this location", message: error.localizedDescription)
                return
            }
            
            for p in photos {
                let photo = Photo(context: self.dataController.viewContext)
                photo.id = p.id
                photo.secret = p.secret
                photo.serverId = p.server
                photo.farmId = Int32(p.farm)
                photo.pin = pin
                
                try? self.dataController.viewContext.save()
            }
        }
    }
}

// MARK: - MKMapViewDelegate

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    // MARK: - Region Functions
    
    func setLocationOnMap() {
        
        let centerLatitude = UserDefaults.standard.double(forKey: "centerLatitude")
        let centerLongitude = UserDefaults.standard.double(forKey: "centerLongitude")
        
        let zoomLatitude = UserDefaults.standard.double(forKey: "zoomLatitude")
        let zoomLongitude = UserDefaults.standard.double(forKey: "zoomLongitude")
        
        let coordinate = CLLocationCoordinate2DMake(centerLatitude, centerLongitude)
        let span = MKCoordinateSpan(latitudeDelta: zoomLatitude, longitudeDelta: zoomLongitude)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        mapView.setRegion(region, animated: false)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let zoomRegion = mapView.region.span
        
        UserDefaults.standard.set(mapView.centerCoordinate.latitude, forKey: "centerLatitude")
        UserDefaults.standard.set(mapView.centerCoordinate.longitude, forKey: "centerLongitude")
        
        UserDefaults.standard.set(zoomRegion.latitudeDelta, forKey: "zoomLatitude")
        UserDefaults.standard.set(zoomRegion.longitudeDelta, forKey: "zoomLongitude")
    }
    
    // MARK: Annotation Functions
    
    func triggerLongPressAction(gestureRecognizer: UITapGestureRecognizer) {
        
        let touchCoordinate = gestureRecognizer.location(in: mapView)
        let position = mapView.convert(touchCoordinate, toCoordinateFrom: mapView)
        
        addPin(coordinate: position)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let objects = fetchedResultsController.fetchedObjects, let coordinate = view.annotation?.coordinate {
            let pinFiltered = objects.first { $0.latitude == coordinate.latitude && $0.longitude == coordinate.longitude }
            
            if pinFiltered != nil {
                selectedPin = pinFiltered
                performSegue(withIdentifier: "photoViewSegue", sender: self)
            } else {
                showAlertFailure(title: "Not found", message: "There's no data that match the pin selected")
            }
        } else {
            showAlertFailure(title: "Not found", message: "We could not find any data")
        }
    }
    
    func parseLocations() {
        var annotations = [MKPointAnnotation]()
        if let data = fetchedResultsController.fetchedObjects {
            for pin in data {
                let lat = CLLocationDegrees(pin.latitude)
                let long = CLLocationDegrees(pin.longitude)
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
            }
            self.mapView.addAnnotations(annotations)
        }
    }
}

extension TravelLocationsMapViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        guard let pin = anObject as? Pin else {
            fatalError("Could not identify the Pin")
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        
        switch type {
        case .insert:
            mapView.addAnnotation(annotation)
            break
        case .delete:
            mapView.removeAnnotation(annotation)
            break
        case .update, .move:
            mapView.removeAnnotation(annotation)
            mapView.addAnnotation(annotation)
            break
        default:
            break
        }
    }
}
