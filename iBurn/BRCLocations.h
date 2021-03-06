//
//  BRCLocations.h
//  iBurn
//
//  Created by David Chiles on 8/4/14.
//  Copyright (c) 2014 Burning Man Earth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BRCLocations : NSObject

/** location of the man in 2015 */
+ (CLLocationCoordinate2D)blackRockCityCenter;

/** Within 5 miles of the man */
+ (CLCircularRegion*) burningManRegion;

@end
