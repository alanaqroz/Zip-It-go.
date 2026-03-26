//
//  LocationService.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 25/03/26.
//

import MapKit

@Observable
class LocationService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    var busca: String = "" {
        didSet { completer.queryFragment = busca }
    }
    var sugestoes: [MKLocalSearchCompletion] = []

    override init() {
        super.init()
        completer.delegate = self
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.sugestoes = completer.results
    }
}
