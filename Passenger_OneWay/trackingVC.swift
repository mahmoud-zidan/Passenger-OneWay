//
//  homeVC.swift
//  Passenger_OneWay
//
//  Created by Mahmoud Ismaeil Atito on 4/26/18.
//  Copyright © 2018 OneWay. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON
import FirebaseDatabase

class trackingVC : UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    var passenger : Model?
    
    var location : CLLocation?
    let LocationManager = CLLocationManager()
    
    var lat : Any!
    var lng : Any!
    var timer1 = Timer()
    var timer2 = Timer()
    open var tracksUserCourse: Bool = true
    var showsUserLocation: Bool = true
    
    @IBOutlet weak var MapView: GMSMapView!
    let Driver_Marker = GMSMarker()
    
    
    var legs : [Legs] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        print("@@@ 1 @@@")
        NavigationBarItems()
        // Do any additional setup after loading the view.
        /*   guard let passenger = self.passenger else {
         return
         }
         print("@@@passenger_E-Mail : \(passenger.email)")
         */
        LocationManager.delegate = self
        LocationManager.desiredAccuracy = kCLLocationAccuracyBest
        LocationManager.startUpdatingLocation()
        LocationManager.startMonitoringSignificantLocationChanges()
        LocationManager.requestAlwaysAuthorization()
        
        
        let latitude = self.LocationManager.location?.coordinate.latitude
        let longitude = self.LocationManager.location?.coordinate.longitude
        guard (latitude != nil)  && (longitude != nil) else {
            print(" longitude is nil")
            return
        }
        let camera = GMSCameraPosition.camera(withLatitude: latitude!, longitude: longitude!, zoom: 6.0)
        self.MapView.camera = camera
        self.MapView.delegate = self
        print("@@@ 2 @@@")
        self.MapView.isMyLocationEnabled = true
        self.MapView.settings.compassButton = true
        self.MapView.settings.myLocationButton = true
        self.MapView.settings.zoomGestures  = true
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.timer1 = Timer.scheduledTimer(timeInterval: 0.30, target: self, selector: #selector(loadfromFirebase), userInfo: nil, repeats: true)
        self.timer2 = Timer.scheduledTimer(timeInterval: 0.31, target: self, selector: #selector(clearMarker), userInfo: nil, repeats: true)
        loadFirstMoveData()
    }
    
    // Mark: function to create markers
    func createMarker(titleMarker: String,time:String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let marker = GMSMarker()
        marker.title = titleMarker
        marker.snippet = "The Time \(time)"
        marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        marker.map = self.MapView
    }
    
    // MARK: Special marker for driver
    func createDriverMarker(titleMarker: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, color: UIColor) {
        
        //    let imgArray: [UIImage] = [#imageLiteral(resourceName: "icons8-1st-48"), #imageLiteral(resourceName: "icons8-circled-2-48")]
        //        for index in imgArray{
        //      let  custom_marker = CustomMarkerView(frame: CGRect(x: 0, y: 0, width: self.customMarkerWidth, height: self.customMarkerHeight), image: #imageLiteral(resourceName: "icons8-1st-48"), borderColor: .darkGray, tag: 0)
        //
        //  marker.iconView = custom_marke
        
        let MarkerName = UIImage(named: "car.png")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.tintColor = color

        
       imageView.image = MarkerName
        self.Driver_Marker.title = titleMarker
        self.Driver_Marker.iconView = imageView
        self.Driver_Marker.snippet = "The Time \(time)"
        self.Driver_Marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        self.Driver_Marker.map = self.MapView
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error to get location : \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("@@@@@@ Did update location @@@@@@")
        
        self.timer1 = Timer.scheduledTimer(timeInterval: 0.30, target: self, selector: #selector(loadfromFirebase), userInfo: nil, repeats: true)
        self.timer2 = Timer.scheduledTimer(timeInterval: 0.3009, target: self, selector: #selector(clearMarker), userInfo: nil, repeats: true)
        
        location = locations.last
        drawPath()
        self.LocationManager.stopUpdatingLocation()
    }
    
    // MARK: Update Driver Location
    @objc func clearMarker(){
        self.Driver_Marker.map = nil
    }
    func drawPath()
    {
        let url = URL(string :"https://maps.googleapis.com/maps/api/directions/json?origin=29.966663,32.549998&destination= 27.856471,34.279848000000015&waypoints=optimize:true| 30.1197986,31.537000300000045 |30.5964923,32.27145870000004|31.26528929999999,32.301866099999984|27.2578957,33.81160669999997&key=AIzaSyC_jTO0llKSEDmQdtu6_UbDo-jqjqeHiC0".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!)
        Alamofire.request(url!, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                // draw route using Polyline
                for (_,route) in json["routes"]
                {
                    let points = route["overview_polyline"]["points"].stringValue
                    let path = GMSPath(fromEncodedPath: points)
                    let polyline = GMSPolyline(path: path)
                    polyline.strokeWidth = 4
                    polyline.strokeColor = UIColor.red
                    polyline.map = self.MapView
                }
                self.parseJSON(json: json["routes"].array![0]["legs"])
            case .failure(let error):
                print(error)
            }
        }
    }
    func parseJSON(json:JSON) {
        print("start parsing...")
        let date = Date()
        let calendar = Calendar.current
        var hours = calendar.component(.hour, from: date)
        var minutes = calendar.component(.minute, from: date)
        var seconds = calendar.component(.second, from: date)
        createMarker(titleMarker: json.array![0]["start_address"].stringValue, time: "\(hours):\(minutes):\(seconds)", latitude: json.array![0]["start_location"]["lat"].doubleValue, longitude: json.array![0]["start_location"]["lng"].doubleValue)
        legs.removeAll()
        for (_,subJson):(String, JSON) in json {
            let duration : Int = subJson["duration"]["value"].intValue
            let end_address : String = subJson["end_address"].stringValue
            let end_location_lat = subJson["end_location"]["lat"].doubleValue
            let end_location_lng = subJson["end_location"]["lng"].doubleValue
            let start_address : String = subJson["start_address"].stringValue
            let start_location_lat = subJson["start_location"]["lat"].doubleValue
            let start_location_lng = subJson["start_location"]["lng"].doubleValue
            let (h,m,s) = secondsToHoursMinutesSeconds(seconds: duration)
            hours+=h
            minutes+=m
            seconds+=s
            (hours,minutes,seconds)=timeFormatter(hours: hours, minutes: minutes, seconds: seconds)
            createMarker(titleMarker: end_address, time: "\(hours):\(minutes):\(seconds)", latitude: end_location_lat, longitude: end_location_lng)
            let leg = Legs(end_address: end_address, end_location_lat: end_location_lat, end_location_lng: end_location_lng, start_address: start_address, start_location_lat: start_location_lat, start_location_lng: start_location_lng)
            legs.append(leg)
        }
    }
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    func timeFormatter(hours:Int, minutes:Int, seconds:Int) -> (hours:Int, minutes:Int, seconds:Int) {
        var second = seconds
        var minute = minutes
        var hour = hours
        if second>=60{
            second-=60
            minute+=1
        }
        if minute>=60{
            minute-=60
            hour+=1
        }
        if hour>=24{
            hour=0
        }
        return (hour,minute,second)
    }
    
    //MARK: load data when driver start to move
    func loadFirstMoveData(){
        let ref = Database.database().reference(fromURL: "https://oneway-500ad.firebaseio.com/")
        ref.child("Trip").child("Driver_Location").observe(.value , with: {(Driver_snapshot: DataSnapshot) in
            let driver_data = Driver_snapshot.value as? NSDictionary
            self.lat = driver_data!["Latitude"] as? Double
            self.lng = driver_data!["Longitude"] as? Double
            
            print("@@ First Lat \(self.lat)")
            print("@@ First Lng \(self.lng)")
            self.createDriverMarker(titleMarker: "My location\((self.lat as? Double)!)", latitude: (self.lat as? Double)!, longitude: (self.lng as? Double)!, color: .green)
        })
        
    }
    
    // MARK: tracking the driver
    @objc func loadfromFirebase(){
        let ref = Database.database().reference(fromURL: "https://oneway-500ad.firebaseio.com/")
        ref.child("Trip").child("Driver_Location").observe(.value , with: {(Driver_snapshot: DataSnapshot) in
            ref.child("Trip").child("destinations").observe(.value , with: {(Destination_snapshot: DataSnapshot) in
            
            let driver_data = Driver_snapshot.value as? NSDictionary
            let destination_data = Destination_snapshot.value as? NSDictionary
         
            if(driver_data != nil) && (destination_data != nil){
               
                // see if the cuurrent locaion = the destination or not if equal and it is the last point stop updating location and if not the last destination point refresh to the next destination and start updating
                
                self.lat = driver_data!["Latitude"] as? Double
                self.lng = driver_data!["Longitude"] as? Double
                
                print("@@ Lat \(self.lat)")
                print("@@ Lng \(self.lng)")
                self.createDriverMarker(titleMarker: "My location\((self.lat as? Double)!)", latitude: (self.lat as? Double)!, longitude: (self.lng as? Double)!, color: .green)
                
                if (driver_data == destination_data){
                    // make a condition to handle if not the last destination point
                    // display alert or noification to the next assigning marker's passengers
                    print("@@ stop point")
                    self.createDriverMarker(titleMarker: "My location\((self.lat as? Double)!)", latitude: (self.lat as? Double)!, longitude: (self.lng as? Double)!, color: .green)
                    
                }
                else{
                    print("@@ updating location")
                    self.createDriverMarker(titleMarker: "My location\((self.lat as? Double)!)", latitude: (self.lat as? Double)!, longitude: (self.lng as? Double)!, color: .green)
                   
                }
                
                }
            else{
                print("Data is Nil")
            }
            })
        })
    }
    
    private func NavigationBarItems(){
        // logo
        let Imagetitle = UIImageView(image: #imageLiteral(resourceName: "track.png"))
        Imagetitle.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        Imagetitle.contentMode = .scaleAspectFill
        navigationItem.titleView = Imagetitle
        
        let ProfileBtn = UIButton(type: .system)
        ProfileBtn.setImage(#imageLiteral(resourceName: "businessman.png").withRenderingMode(.alwaysOriginal), for: .normal)
        ProfileBtn.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView : ProfileBtn)
        
    }
}
