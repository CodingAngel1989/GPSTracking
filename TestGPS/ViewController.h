//
//  ViewController.h
//  TestGPS
//
//  Created by Lucky Ji on 12-7-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "CSqlite.h"
#import <MapKit/MapKit.h>

@interface POI : NSObject <MKAnnotation> {
    
    CLLocationCoordinate2D coordinate;
    NSString *subtitle;
    NSString *title;
}

@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic,retain) NSString *subtitle;
@property (nonatomic,retain) NSString *title;

-(id) initWithCoords:(CLLocationCoordinate2D) coords;

@end

@interface ViewController : UIViewController<MKMapViewDelegate,CLLocationManagerDelegate>
{
    
    CSqlite *m_sqlite;
    
    int nPoint;
    int nTime;
    
    CLLocationManager *locationManager;
    MKCoordinateRegion region;
    NSMutableArray* arrayLine;
    
    NSMutableArray* arrayTapRectangle;
    NSMutableArray* arrayTapPoint;
    NSMutableArray* arrayTapLabel;
    NSMutableArray* arrayPinkRect;
    
    int nTapCount;
    CLLocationCoordinate2D bottomLeftPos;
    CLLocationCoordinate2D pointTap[50];
    CLLocationCoordinate2D currentLocation;
    
    NSUserDefaults* defaults;
    BOOL bDisplayGrid;  // The Screen Size is enough big to display the GridLine
    BOOL bShowGridLine; // User can set this value to display or not GridLine.
    
    int nArrayTapCount[50];

}
- (IBAction)OpenGPS:(id)sender;
- (IBAction)onGridLine:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *lat;
@property (weak, nonatomic) IBOutlet UILabel *llong;
@property (weak, nonatomic) IBOutlet UILabel *offLat;
@property (weak, nonatomic) IBOutlet UILabel *offLog;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;


@property (weak, nonatomic) IBOutlet UILabel *m_locationName;
@property (nonatomic, strong) NSMutableArray* allPins;
@property (nonatomic, strong) MKPolylineView* lineView;
@property (nonatomic, strong) MKPolyline * polyline;

@end


