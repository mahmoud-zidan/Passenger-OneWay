//
//  PassengerMap.swift
//  Graduation Project
//
//  Created by Mohamed Eshawy on 2/25/18.
//  Copyright © 2018 MahmoudIsmaeilAtito. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON


class PassengerMap: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    var passenger : Model?
    
    var location : CLLocation?
    let LocationManager = CLLocationManager()
    
    open var tracksUserCourse: Bool = true
    var showsUserLocation: Bool = true
    
    @IBOutlet weak var MapView: GMSMapView!

     var legs : [Legs] = []

    // for loading location from firebase
    var Lat : Any!
    var Lng : Any!
    
    // MARK: for custom marker
    let customMarkerWidth: Int = 50
    let customMarkerHeight: Int = 70
   
    
    let previewDemoData = [(title: "The Polar Junction", img: #imageLiteral(resourceName: "icons8-1st-48")), (title: "The Lunar Petal", img: #imageLiteral(resourceName: "icons8-circled-2-48"))]
    
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
            print("latitude and longitude is nil")
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
    
    // MARK: function to create markers
    func createMarker(titleMarker: String,time:String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, color: UIColor) {
   
        let marker = GMSMarker()
        marker.title = titleMarker
        marker.snippet = "The Time \(time)"
        marker.position = CLLocationCoordinate2DMake(latitude, longitude)
        marker.map = self.MapView
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error to get location : \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("@@@@@@ Did update location @@@@@@")
        location = locations.last
        drawPath()
        self.LocationManager.stopUpdatingLocation()
    }
    
    // MARK: Draw route between markers
    
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
        createMarker(titleMarker: json.array![0]["start_address"].stringValue, time: "\(hours):\(minutes):\(seconds)", latitude: json.array![0]["start_location"]["lat"].doubleValue, longitude: json.array![0]["start_location"]["lng"].doubleValue, color: .red)
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
            createMarker(titleMarker: end_address, time: "\(hours):\(minutes):\(seconds)", latitude: end_location_lat, longitude: end_location_lng, color: .red)
        
            
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

    // MARK: Custom Marker implementation
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let customMarkerView = marker.iconView as? CustomMarkerView else { return false }
        let img = customMarkerView.img!
        let customMarker = CustomMarkerView(frame: CGRect(x: 0, y: 0, width: customMarkerWidth, height: customMarkerHeight), image: img, borderColor: UIColor.white, tag: customMarkerView.tag)
        
        marker.iconView = customMarker
        
        return false
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
        guard let customMarker = marker.iconView as? CustomMarkerView else { return nil }
        let data = previewDemoData[customMarker.tag]
        customWindowView.setData(title: data.title, img: data.img)
        print("@@@ \(previewDemoData[customMarker.tag])")
        return customWindowView
    }
    func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
        guard let customMarkerView = marker.iconView as? CustomMarkerView else { return }
        let img = customMarkerView.img!
        let customMarker = CustomMarkerView(frame: CGRect(x: 0, y: 0, width: customMarkerWidth, height: customMarkerHeight), image: img, borderColor: UIColor.darkGray,tag: customMarkerView.tag)
        marker.iconView = customMarker
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        guard let customMarkerView = marker.iconView as? CustomMarkerView else { return }
        let tag = customMarkerView.tag
    }
    
    
    func setupViews() {
        view.addSubview(MapView)
        MapView.topAnchor.constraint(equalTo: view.topAnchor).isActive=true
        MapView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive=true
        MapView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive=true
        MapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 60).isActive=true
        
        customWindowView=CustomWindowView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 190))
        
      /*  self.view.addSubview(btnMyLocation)
        btnMyLocation.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive=true
        btnMyLocation.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive=true
        btnMyLocation.widthAnchor.constraint(equalToConstant: 50).isActive=true
        btnMyLocation.heightAnchor.constraint(equalTo: btnMyLocation.widthAnchor).isActive=true
       */
    }
    
   /* let btnMyLocation: UIButton = {
        let btn=UIButton()
        btn.backgroundColor = UIColor.white
        btn.setImage(#imageLiteral(resourceName: "globe.png"), for: .normal)
        btn.layer.cornerRadius = 25
        btn.clipsToBounds=true
        btn.tintColor = UIColor.gray
        btn.imageView?.tintColor=UIColor.gray
        btn.addTarget(self, action: #selector(btnMyLocationAction), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints=false
        return btn
    }()*/
    
    var customWindowView: CustomWindowView = {
        let v=CustomWindowView()
        return v
    }()
    // MARK: create custom navigation bar
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
