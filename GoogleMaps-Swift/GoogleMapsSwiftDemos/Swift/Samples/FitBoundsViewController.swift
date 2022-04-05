// Copyright 2020 Google LLC. All rights reserved.
//
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License. You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
// ANY KIND, either express or implied. See the License for the specific language governing
// permissions and limitations under the License.

import GoogleMaps
import UIKit

class FitBoundsViewController: UIViewController {

  // MARK: -  Demo Configuration/Options:

  /// Whether the markers are animated
  /// Provides context as to the performance implications of animations
  let animateMarkers: Bool = true

  /// Amount of markers to be displayed
  /// By changing, we can evaluate where the likely performance drop offs appear
  let numberOfMarkers: Int = 30

  // MARK: - Properties

  private let markerImageName = "glow-marker"

  private let anotherSydneyLocation = CLLocationCoordinate2D(
    latitude: -33.8683, longitude: 149.2086)

  let sfBayLatRange: Range<Double> = 37.330584 ..< 37.797048
  let sfBayLongRange: Range<Double> = -122.519890 ..< -121.851070

  // Creates a list of markers, adding the Sydney marker.
  private lazy var markers: [GMSMarker] = [] {
    didSet {
      // Remove Old Values
      oldValue.forEach { marker in
        marker.map = nil
      }
      // Add New Values
      markers.forEach { marker in
        marker.map = mapView
      }
    }
  }

  // MARK: - UI Components

  private lazy var mapView: GMSMapView = {
    let camera = GMSCameraPosition(target: .victoria, zoom: 4)
    return GMSMapView(frame: .zero, camera: camera)
  }()


  override func loadView() {
    mapView.delegate = self
    view = mapView

    // Creates a button that, when pressed, updates the camera to fit the bounds.
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Fit Bounds", style: .plain, target: self, action: #selector(fitBounds))
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    reloadMarkers()

    // Dane - Add FitToBounds to load to focus on the correct region
    fitBounds()

    // Demonstrate reloading markers does not drop dragging interactions
    // Reload Markers every 3 seconds to demonstrate loss of User Interaction
    Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
      self?.reloadMarkers()
    }
  }

  @objc func fitBounds() {
    var bounds = GMSCoordinateBounds()
    for marker in markers {
      bounds = bounds.includingCoordinate(marker.position)
    }
    guard bounds.isValid else { return }
    mapView.moveCamera(GMSCameraUpdate.fit(bounds, withPadding: 50))
  }

  @objc func reloadMarkers() {

    // Demo Option:
    // Change animated true/false to see performance difference between approaches
    markers = makeMarkers(animated: animateMarkers)
  }

  // MARK: - Marker Generator

  func makeMarkers(animated: Bool) -> [GMSMarker] {
    if animated {
      return makeAnimatedMarkers()
    } else {
      return makeStaticMarkers()
    }
  }

  // Creates new collection of basic markers (not attached to map)
  private func makeStaticMarkers() -> [GMSMarker] {
    // Creates 100 Random Coordinates in the SFBay
    let coordinates: [CLLocationCoordinate2D] = (1 ... numberOfMarkers)
      .map { _ in
        let latitude = Double.random(in: sfBayLatRange)
        let longitude = Double.random(in: sfBayLongRange)
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      }

    let markers: [GMSMarker] = coordinates.map { coordinate in
      let marker = GMSMarker(position: coordinate)

      // Only image + title (More performant)
      marker.title = "Foo"
      marker.icon = UIImage(named: markerImageName)
      return marker
    }
    return markers
  }

  // Creates new collection of basic markers (not attached to map)
  private func makeAnimatedMarkers() -> [GMSMarker] {

    // Creates 100 Random Coordinates in the SFBay
    let coordinates: [CLLocationCoordinate2D] = (1 ... numberOfMarkers)
      .map { _ in
        let latitude = Double.random(in: sfBayLatRange)
        let longitude = Double.random(in: sfBayLongRange)
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      }

    let markers: [GMSMarker] = coordinates.map { coordinate in
      let marker = GMSMarker(position: coordinate)

      marker.title = "Foo"

      // Animated Glowing Image
      marker.iconView = UIImageView(image: UIImage(named: "glow-marker"))
      marker.iconView?.contentMode = .center

     let oldBounds = marker.iconView?.bounds ?? .zero // else { return }

      marker.iconView?.bounds = CGRect(
        origin: oldBounds.origin,
        size: CGSize(width: oldBounds.size.width * 2, height: oldBounds.size.height * 2))
      marker.groundAnchor = CGPoint(x: 0.5, y: 0.75)
      marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0.25)
      let glow = UIImageView(image: UIImage(named: "glow-marker"))
      glow.layer.shadowColor = UIColor.blue.cgColor
      glow.layer.shadowOffset = .zero
      glow.layer.shadowRadius = 8
      glow.layer.shadowOpacity = 1.0
      glow.layer.opacity = 0.0
      marker.iconView?.addSubview(glow)
      glow.center = CGPoint(x: oldBounds.size.width, y: oldBounds.size.height)

      // Include animation on view
      UIView.animate(
        withDuration: 1, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat],
        animations: {
          glow.layer.opacity = 1.0
        },
        completion: { _ in
          // If the animation is ever terminated, no need to keep tracking the view for changes.
          marker.tracksViewChanges = false
        })

      return marker
    }
    return markers
  }
}

extension FitBoundsViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
    let marker = GMSMarker(position: coordinate)
    marker.title = "Marker at: \(coordinate.latitude), \(coordinate.longitude)"
    marker.appearAnimation = .pop
    marker.map = mapView
    markers.append(marker)
  }
}
