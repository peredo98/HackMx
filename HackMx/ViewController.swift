//
//  ViewController.swift
//  HackMx
//
//  Created by Emiliano Peredo on 4/27/19.
//  Copyright © 2019 Servebeer. All rights reserved.
//


import UIKit
import ARCL
import CoreLocation
import SceneKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var sceneLocationView = SceneLocationView()
    var locationVector: SCNVector3?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneLocationView.run()
        view.addSubview(sceneLocationView)
        
        
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = view.bounds
    }
    
    func ARINIT()  { // Test locations around me. you can also plot these using google place API
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        var location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 19.59643468290748 , longitude: -99.22720396015059), altitude: 2333) // ISKPRO
        let image = UIImage(named: "Pin")!
        var annotationNode = LocationAnnotationNode(location: location, image: image)
        
        annotationNode.annotationNode.name = "Juguete1"
        annotationNode.scaleRelativeToDistance = true
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        let pathNode = SCNPathNode(path: [sceneLocationView.pointOfView!.worldPosition, annotationNode.worldPosition])
        
        sceneLocationView.scene.rootNode.addChildNode(pathNode)
        
    }
    
    // Touch events on nodes
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneLocationView)
            
            let hitResults = sceneLocationView.hitTest(touchLocation, options: [.boundingBoxOnly : true])
            for result in hitResults {
                
                print("HIT:-> Name: \(result.node.description)")
                print("HIT:-> description  \(result.node.name)")
                
                //let line = SCNGeometry.line(from: (sceneLocationView.pointOfView?.position)!, to: result.localCoordinates)
                
               
                let pathNode = SCNPathNode(path: [SCNVector3(0,-1,0), result.worldCoordinates])
                /*let line = SCNGeometry.lineThrough(points: [locationVector!, result.localCoordinates], width: 30, closed: false, color: UIColor.red.cgColor, mitter: false)
                
                let lineNode = SCNNode(geometry: line)
                lineNode.position = SCNVector3Zero*/
            sceneLocationView.scene.rootNode.addChildNode(pathNode)
                
                
                
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: locValue.latitude, longitude: locValue.longitude), altitude: 2240) // Gaur City
        
         locationVector = LocationNode(location: location).position
        ARINIT()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

// MARK: - SceneLocationViewDelegate
@available(iOS 11.0, *)
extension ViewController: SceneLocationViewDelegate {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        print("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        print("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
        print("7845768")
    }
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        print("546456")
    }
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
    }
}

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
    class func lineThrough(points: [SCNVector3], width:Int = 20, closed: Bool = false,  color: CGColor = UIColor.black.cgColor, mitter: Bool = false) -> SCNGeometry {
        
        // Becouse we cannot use geometry shaders in metal, every point on the line has to be changed into 4 verticles
        let vertices: [SCNVector3] = points.flatMap { p in [p, p, p, p] }
        
        // Create Geometry Source object
        let source = SCNGeometrySource(vertices: vertices)
        
        // Create Geometry Element object
        var indices = Array((0..<Int32(vertices.count)))
        if (closed) {
            indices += [0, 1]
        }
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangleStrip)
        
        // Prepare data for vertex shader
        // Format is line width, number of points, should mitter be included, should line create closed loop
        let lineData: [Int32] = [Int32(width), Int32(points.count), Int32(mitter ? 1 : 0), Int32(closed ? 1 : 0)]
        
        let geometry = SCNGeometry(sources: [source], elements: [element])
        geometry.setValue(Data(bytes: lineData, count: MemoryLayout<Int32>.size*lineData.count), forKeyPath: "lineData")
        
        // map verticles into float3
        let floatPoints = vertices.map { float3($0) }
        geometry.setValue(NSData(bytes: floatPoints, length: MemoryLayout<float3>.size * floatPoints.count), forKeyPath: "vertices")
        
        // map color into float
        let colorFloat = color.components!.map { Float($0) }
        geometry.setValue(NSData(bytes: colorFloat, length: MemoryLayout<simd_float1>.size * color.numberOfComponents), forKey: "color")
        
        // Set the shader program
        let program = SCNProgram()
        program.fragmentFunctionName = "thickLinesFragment"
        program.vertexFunctionName = "thickLinesVertex"
        geometry.program = program
        
        return geometry
    }
}

