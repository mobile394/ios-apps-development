//
//  Exposure.swift
//  safesafe
//
//  Created by Rafał Małczyński on 24/05/2020.
//

import Foundation
import RealmSwift

final class Exposure: Object, LocalStorable {
    
    @objc dynamic var id = UUID()
    
    /// Total calculated risk, range is 0-4096
    @objc dynamic var risk: Int = .zero
    
    /// Exposure duration in seconds
    @objc dynamic var duration: Double = .zero
    
    /// Array of durations at certain attenuations
    let attenuationDurations = List<Int>()
    
    /// Signal strength of peer device
    @objc dynamic var attenuationValue: UInt8 = .zero
    
    /// Date of exposure
    @objc dynamic var date: Date = Date()
    
    convenience init(
        risk: Int,
        duration: Double,
        attenuationDurations: [Int],
        attenuationValue: UInt8,
        date: Date
    ) {
        self.init()
        self.risk = risk
        self.duration = duration
        self.attenuationValue = attenuationValue
        self.date = date
        
        self.attenuationDurations.append(objectsIn: attenuationDurations)
    }
    
}
