//
//  PioneerMapView.swift
//  CityHydrants
//
//  Created by Phil Scarfi on 5/9/19.
//  Copyright © 2019 Pioneer Mobile Applications, LLC. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class PioneerMapView: MKMapView {
    @IBOutlet weak var pitchSlider: UISlider!
    @IBOutlet weak var mapSelector: UISegmentedControl!
    var hideAllGadgets = false
    
    var isAlreadyDrawn = false
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        
        if isAlreadyDrawn || hideAllGadgets {
            return
        }
        //Add pitch slider
        let padding:CGFloat = 5
        let pSlider = UISlider(frame: CGRect(x: rect.origin.x + padding , y: rect.origin.y + padding, width: rect.width - (padding * 2), height: rect.height))
        pSlider.minimumValue = 0
        pSlider.maximumValue = 70
        pSlider.addTarget(self, action: #selector(pitchSliderDidChange(_:)), for: .valueChanged)
        addSubview(pSlider)
        pSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        pSlider.frame = CGRect(x: rect.width - padding - 35 , y: rect.height / 4, width: 20, height: (rect.height / 2))
        pSlider.value = Float(camera.pitch)
        self.pitchSlider = pSlider
        
        //Add Map Selector
        let segmentedControl = UISegmentedControl(items: ["Standard", "Satellite", "Hybrid"])
        segmentedControl.frame = CGRect(x: rect.origin.x + padding , y: rect.origin.y + padding, width: 250, height: 30)
        segmentedControl.center = CGPoint(x: frame.width/2, y: segmentedControl.center.y)
        segmentedControl.selectedSegmentIndex = 2
        segmentedControl.backgroundColor = UIColor(white: 1, alpha: 0.5)
        segmentedControl.addTarget(self, action: #selector(mapSelectorDidChange(_:)), for: .valueChanged)
        //Toggle
        segmentedControl.isHidden = true
        
        addSubview(segmentedControl)
        self.mapSelector = segmentedControl
        
        //Add user tracking button
        let locationButton = MKUserTrackingButton(mapView: self)
        locationButton.tintColor = UIColor.white
        locationButton.frame = CGRect(x: padding * 2, y: frame.height - padding * 2, width: 50, height: 50)
        locationButton.center = CGPoint(x: rect.width - padding * 5, y: rect.height - (padding * 7))
        addSubview(locationButton)
        
        
        //Other Customization
        showsBuildings = true
        showsUserLocation = true
        isAlreadyDrawn = true
    }
    
    @IBAction func pitchSliderDidChange(_ sender: Any) {
        let newPitch = CGFloat((sender as! UISlider).value)
        print("Changing Pitch to: \(newPitch)")
        //        camera.pitch = CGFloat((sender as! UISlider).value)
        camera = MKMapCamera(lookingAtCenter: camera.centerCoordinate, fromDistance: camera.altitude, pitch: newPitch, heading: camera.heading)
    }
    
    @IBAction func mapSelectorDidChange(_ sender: Any) {
        //        pitchSlider.isHidden = false
        if mapSelector.selectedSegmentIndex == 0 {
            mapType = .standard
            //            pitchSlider.isHidden = true
        } else if mapSelector.selectedSegmentIndex == 1 {
            mapType = .satelliteFlyover
        } else {
            mapType = .hybridFlyover
        }
    }
    
    func addAnnotationToLocation(_ location: CLLocation, title: String?, subtitle: String?, image: UIImage?, enlarge: Bool? = false) {
        if let image = image {
            let annotation = ImageAnnotation()
            annotation.title = title
            annotation.subtitle = subtitle
            annotation.coordinate = location.coordinate
            annotation.image = image
            annotation.enlarge = enlarge ?? false
            addAnnotation(annotation)
        } else {
            let annotation = MKPointAnnotation()
            annotation.title = title
            annotation.subtitle = subtitle
            annotation.coordinate = location.coordinate
            addAnnotation(annotation)
        }
        
    }
    
    func removeAllAnnotations() {
        removeAnnotations(self.annotations)
    }
}
