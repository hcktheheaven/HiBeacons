//
//  NATAdvertising.swift
//  HiBeacons
//
//  Created by Nick Toumpelis on 2015-07-26.
//  Copyright (c) 2015 Nick Toumpelis.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import CoreLocation
import CoreBluetooth

/// Lists the methods that an advertising delegate should implement to be notified for all advertising operation events.
protocol NATAdvertisingOperationDelegate
{
    /** 
        Triggered when the advertising operation has started successfully.
     */
    func advertisingOperationDidStartSuccessfully()

    /** 
        Triggered when the advertising operation has failed to start.
     */
    func advertisingOperationDidFailToStart()
}

/// NATAdvertisingOperation contains all the process logic required to successfully advertising the presence of a
/// a specific beacon (and region) to nearby devices.
class NATAdvertisingOperation: NATOperation
{

    /// The delegate for an advertising operation.
    var delegate: NATAdvertisingOperationDelegate?

    /// An instance of a CBPeripheralManager, which is used for advertising a beacon to nearby devices.
    var peripheralManager = CBPeripheralManager(delegate: nil, queue: nil, options: nil)

    /**
        Starts the beacon advertising process.
     */
    func startAdvertisingBeacon() {
        NSLog("Turning on advertising...")
        
        if peripheralManager?.state != .PoweredOn {
            NSLog("Peripheral manager is off.")
            if delegate != nil {
                delegate!.advertisingOperationDidFailToStart()
            }
            return
        }

        activatePeripheralManagerNotifications();

        turnOnAdvertising()
    }

    /**
        Turns on advertising (after all the checks have been passed).
     */
    func turnOnAdvertising() {
        let major: CLBeaconMajorValue = CLBeaconMajorValue(arc4random_uniform(5000))
        let minor: CLBeaconMinorValue = CLBeaconMajorValue(arc4random_uniform(5000))
        var region: CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconRegion.proximityUUID, major: major, minor: minor, identifier: beaconRegion.identifier)
        var beaconPeripheralData: NSMutableDictionary = region.peripheralDataWithMeasuredPower(nil)

        peripheralManager?.startAdvertising(beaconPeripheralData as [NSObject : AnyObject])

        NSLog("Turning on advertising for region: \(region).")
    }

    /**
        Stops the monitoring process.
     */
    func stopAdvertisingBeacon() {
        peripheralManager?.stopAdvertising()

        deactivatePeripheralManagerNotifications();

        NSLog("Turned off advertising.")
    }

    /**
        Sets the peripheral manager delegate to self. It is called when an instance is ready to process peripheral
        manager delegate calls.
    */
    func activatePeripheralManagerNotifications() {
        peripheralManager.delegate = self;
    }

    /**
        Sets the peripheral manager delegate to nil. It is called when an instance is ready to stop processing 
        peripheral manager delegate calls.
    */
    func deactivatePeripheralManagerNotifications() {
        peripheralManager.delegate = nil;
    }
}

// MARK: - CBPeripheralManagerDelegate methods
extension NATAdvertisingOperation: CBPeripheralManagerDelegate
{
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!) {
        if error != nil {
            NSLog("Couldn't turn on advertising: \(error)")
            if delegate != nil {
                delegate!.advertisingOperationDidFailToStart()
            }
        }

        if peripheralManager!.isAdvertising {
            NSLog("Turned on advertising.")
            if delegate != nil {
                delegate!.advertisingOperationDidStartSuccessfully()
            }
        }
    }

    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        if peripheralManager?.state == .PoweredOff {
            NSLog("Peripheral manager is off.")
            if delegate != nil {
                delegate!.advertisingOperationDidFailToStart()
            }
        } else if peripheralManager.state == .PoweredOn {
            NSLog("Peripheral manager is on.")
            turnOnAdvertising()
        }
    }
}
