//
//  ViewController.m
//  TestGPS
//
//  Created by Lucky Ji on 12-7-26.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "Pin.h"

#define LongtitudeSeg  0.00171661368347031384474
#define DISPLAYGRID     @"DisplayGrid"
@interface ViewController ()

@end

@implementation ViewController
@synthesize lat;
@synthesize llong;

@synthesize allPins;
@synthesize lineView;
@synthesize polyline;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    bShowGridLine = YES;
    m_sqlite = [[CSqlite alloc]init];
    [m_sqlite openSqlite];
    
    if ([CLLocationManager locationServicesEnabled]) { // 检查定位服务是否可用
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter=0.5;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation]; // 开始定位
    }
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    self.mapView.showsUserLocation = YES;//显示ios自带的我的位置显示
    self.allPins = [[NSMutableArray alloc] init];
    self.mapView.delegate = self;
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayCurrentLocation) userInfo:nil repeats:NO];
    
    nTapCount = 0;
    nPoint = 0;
    arrayTapRectangle = [[NSMutableArray alloc] init];
    arrayTapLabel = [[NSMutableArray alloc] init];
    arrayTapPoint = [[NSMutableArray alloc] init];
    arrayPinkRect = [[NSMutableArray alloc] init];
    
    defaults = [NSUserDefaults standardUserDefaults];
    bDisplayGrid = NO;
    
    // add a tap gesture
    
    UILongPressGestureRecognizer* recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onTapMap:)];
    [self.mapView addGestureRecognizer:recognizer];
}


- (void) onTapMap:(UIGestureRecognizer*)recognizer
{
    if (bDisplayGrid == NO) {
        return;
    }
    
    CGPoint userTouch = [recognizer locationInView:self.mapView];
    CLLocationCoordinate2D mapPoint = [self.mapView convertPoint:userTouch toCoordinateFromView:self.mapView];
    
    int iCount = 0;
    int nDisplayNumber;
    
    float xRectOne, xRectTwo;
    float yRectOne, yRectTwo;
    
    if (mapPoint.longitude > bottomLeftPos.longitude) {
        while (mapPoint.longitude > bottomLeftPos.longitude + LongtitudeSeg * iCount) {
            iCount ++;
        }
        xRectOne = bottomLeftPos.longitude + LongtitudeSeg * (iCount - 1);
        xRectTwo = bottomLeftPos.longitude + LongtitudeSeg * iCount;
    }
    else if(mapPoint.longitude < bottomLeftPos.longitude)
    {
        while (mapPoint.longitude < bottomLeftPos.longitude + LongtitudeSeg * iCount) {
            iCount --;
        }
        
        xRectOne = bottomLeftPos.longitude + LongtitudeSeg * iCount;
        xRectTwo = bottomLeftPos.longitude + LongtitudeSeg * (iCount + 1);
    }
    
    iCount = 0;
    if (mapPoint.latitude > bottomLeftPos.latitude) {
        while (mapPoint.latitude > bottomLeftPos.latitude + LongtitudeSeg * iCount) {
            iCount ++;
        }
        yRectOne = bottomLeftPos.latitude + LongtitudeSeg * (iCount - 1);
        yRectTwo = bottomLeftPos.latitude + LongtitudeSeg * iCount;
    }
    else {
        while (mapPoint.latitude < bottomLeftPos.latitude + LongtitudeSeg * iCount) {
            iCount --;
        }
        yRectOne = bottomLeftPos.latitude + LongtitudeSeg * iCount;
        yRectTwo = bottomLeftPos.latitude + LongtitudeSeg * (iCount + 1);
    }
    
    CLLocationCoordinate2D coordinates[5];
    
    coordinates[0].latitude = yRectTwo;
    coordinates[0].longitude = xRectOne;
    
    coordinates[1].latitude = yRectTwo;
    coordinates[1].longitude = xRectTwo;
    
    coordinates[2].latitude = yRectOne;
    coordinates[2].longitude = xRectTwo;
    
    coordinates[3].latitude = yRectOne;
    coordinates[3].longitude = xRectOne;
    
    coordinates[4].latitude = yRectTwo;
    coordinates[4].longitude = xRectOne;
    
    CLLocation* ptRectCenter = [[CLLocation alloc] initWithLatitude:(yRectOne + yRectTwo) / 2  longitude:(xRectOne + xRectTwo) / 2];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        BOOL bOldTap = NO;
        int nTapId  = -1;
        for (int i = 0; i < nTapCount; i++) {
            CLLocation* ptOld = [arrayTapPoint objectAtIndex:i];
            CLLocationCoordinate2D pointOld = ptOld.coordinate;
            
            if (pointOld.latitude == ptRectCenter.coordinate.latitude && pointOld.longitude == ptRectCenter.coordinate.longitude) {
                bOldTap = YES;
                nTapId = i;
                break;
            }
        }
        
        CGPoint ptOne = [self.mapView convertCoordinate:coordinates[0] toPointToView:self.mapView];
        CGPoint ptTwo = [self.mapView convertCoordinate:coordinates[1] toPointToView:self.mapView];
        CGPoint ptThree = [self.mapView convertCoordinate:coordinates[2] toPointToView:self.mapView];
        
        UIImage* imgPink = [UIImage imageNamed:@"pink.png"];
        UIImageView* imgView = [[UIImageView alloc] initWithImage:imgPink];
        imgView.alpha = 0.6;
        imgView.frame = CGRectMake(ptOne.x, ptOne.y, ptTwo.x - ptOne.x - 1, ptThree.y - ptOne.y - 1);
        
        if (bOldTap == NO) {
            [arrayTapPoint addObject:ptRectCenter];
            nArrayTapCount[nTapCount] = 1;
            nTapCount ++;
            nDisplayNumber = 1;
            [arrayPinkRect addObject:imgView];
        }
        else
        {
            nArrayTapCount[nTapId] ++;
            nDisplayNumber = nArrayTapCount[nTapId];
            UIImageView* oldImageView = [arrayPinkRect objectAtIndex:nTapId];
            [oldImageView removeFromSuperview];
            [arrayPinkRect replaceObjectAtIndex:nTapId withObject:imgView];
        }
        
        [self.view addSubview:imgView];
        
        UILabel* lblNumber = [[UILabel alloc] initWithFrame:CGRectMake(ptOne.x, ptOne.y, ptTwo.x - ptOne.x, ptThree.y - ptOne.y)];
        
        lblNumber.text = [NSString stringWithFormat:@"%d", nDisplayNumber];
        lblNumber.textAlignment = NSTextAlignmentCenter;
        lblNumber.textColor = [UIColor redColor];
        lblNumber.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:20];
        
        if (bOldTap == YES) {
            UILabel* lbl = [arrayTapLabel objectAtIndex:nTapId];
            [lbl removeFromSuperview];
            [arrayTapLabel replaceObjectAtIndex:nTapId withObject:lblNumber];
        }
        else
        {
            [arrayTapLabel addObject:lblNumber];
        }
        [self.view addSubview:lblNumber];
    }
    
    MKPolyline* polyLine = [MKPolyline polylineWithCoordinates:coordinates count:5];
    [self.mapView addOverlay:polyLine];
    
    [arrayTapRectangle addObject:polyLine];
    
    self.polyline = polyLine;
    self.lineView = [[MKPolylineView alloc]initWithPolyline:self.polyline];
    self.lineView.strokeColor = [UIColor blueColor];
    self.lineView.lineWidth = 3;
}

- (void) displayCurrentLocation
{
    nTime = nTime + 3;
    
    if (bDisplayGrid == NO) {
        return;
    }
    
    region = self.mapView.region;
    MKCoordinateSpan span = region.span;
    if (span.longitudeDelta > LongtitudeSeg * 20)
        return;

    CLLocationCoordinate2D mapPoint = currentLocation;
    
    int iCount = 0;
    int nDisplayNumber;
    
    float xRectOne, xRectTwo;
    float yRectOne, yRectTwo;
    
    if (mapPoint.longitude > bottomLeftPos.longitude) {
        while (mapPoint.longitude > bottomLeftPos.longitude + LongtitudeSeg * iCount) {
            iCount ++;
        }
        xRectOne = bottomLeftPos.longitude + LongtitudeSeg * (iCount - 1);
        xRectTwo = bottomLeftPos.longitude + LongtitudeSeg * iCount;
    }
    else if(mapPoint.longitude < bottomLeftPos.longitude)
    {
        while (mapPoint.longitude < bottomLeftPos.longitude + LongtitudeSeg * iCount) {
            iCount --;
        }
        
        xRectOne = bottomLeftPos.longitude + LongtitudeSeg * iCount;
        xRectTwo = bottomLeftPos.longitude + LongtitudeSeg * (iCount + 1);
    }
    
    iCount = 0;
    if (mapPoint.latitude > bottomLeftPos.latitude) {
        while (mapPoint.latitude > bottomLeftPos.latitude + LongtitudeSeg * iCount) {
            iCount ++;
        }
        yRectOne = bottomLeftPos.latitude + LongtitudeSeg * (iCount - 1);
        yRectTwo = bottomLeftPos.latitude + LongtitudeSeg * iCount;
    }
    else {
        while (mapPoint.latitude < bottomLeftPos.latitude + LongtitudeSeg * iCount) {
            iCount --;
        }
        yRectOne = bottomLeftPos.latitude + LongtitudeSeg * iCount;
        yRectTwo = bottomLeftPos.latitude + LongtitudeSeg * (iCount + 1);
    }
    
    CLLocationCoordinate2D coordinates[5];
    
    coordinates[0].latitude = yRectTwo;
    coordinates[0].longitude = xRectOne;
    
    coordinates[1].latitude = yRectTwo;
    coordinates[1].longitude = xRectTwo;
    
    coordinates[2].latitude = yRectOne;
    coordinates[2].longitude = xRectTwo;
    
    coordinates[3].latitude = yRectOne;
    coordinates[3].longitude = xRectOne;
    
    coordinates[4].latitude = yRectTwo;
    coordinates[4].longitude = xRectOne;
    
    CLLocation* ptRectCenter = [[CLLocation alloc] initWithLatitude:(yRectOne + yRectTwo) / 2  longitude:(xRectOne + xRectTwo) / 2];
    BOOL bOldTap = NO;
    int nTapId  = -1;
    for (int i = 0; i < nTapCount; i++) {
        CLLocation* ptOld = [arrayTapPoint objectAtIndex:i];
        CLLocationCoordinate2D pointOld = ptOld.coordinate;
        
        if (pointOld.latitude == ptRectCenter.coordinate.latitude && pointOld.longitude == ptRectCenter.coordinate.longitude) {
            bOldTap = YES;
            nTapId = i;
            break;
        }
    }
    
    CGPoint ptOne = [self.mapView convertCoordinate:coordinates[0] toPointToView:self.mapView];
    CGPoint ptTwo = [self.mapView convertCoordinate:coordinates[1] toPointToView:self.mapView];
    CGPoint ptThree = [self.mapView convertCoordinate:coordinates[2] toPointToView:self.mapView];
    
    UIImage* imgPink = [UIImage imageNamed:@"pink.png"];
    UIImageView* imgView = [[UIImageView alloc] initWithImage:imgPink];
    imgView.alpha = 0.6;
    imgView.frame = CGRectMake(ptOne.x, ptOne.y, ptTwo.x - ptOne.x - 1, ptThree.y - ptOne.y - 1);
    
    if (bOldTap == NO) {
        [arrayTapPoint addObject:ptRectCenter];
        nArrayTapCount[nTapCount] = 1;
        nTapCount ++;
        nDisplayNumber = 1;
        [arrayPinkRect addObject:imgView];
    }
    else
    {
        nArrayTapCount[nTapId] ++;
        nDisplayNumber = nArrayTapCount[nTapId];
        UIImageView* oldImageView = [arrayPinkRect objectAtIndex:nTapId];
        [oldImageView removeFromSuperview];
        [arrayPinkRect replaceObjectAtIndex:nTapId withObject:imgView];
    }
    
    [self.view addSubview:imgView];
    
    UILabel* lblNumber = [[UILabel alloc] initWithFrame:CGRectMake(ptOne.x, ptOne.y, ptTwo.x - ptOne.x, ptThree.y - ptOne.y)];
    
    lblNumber.text = [NSString stringWithFormat:@"%d", nDisplayNumber];
    lblNumber.textAlignment = NSTextAlignmentCenter;
    lblNumber.textColor = [UIColor redColor];
    lblNumber.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:20];
    
    if (bOldTap == YES) {
        UILabel* lbl = [arrayTapLabel objectAtIndex:nTapId];
        [lbl removeFromSuperview];
        [arrayTapLabel replaceObjectAtIndex:nTapId withObject:lblNumber];
    }
    else
    {
        [arrayTapLabel addObject:lblNumber];
    }
    
    [self.view addSubview:lblNumber];

    
    MKPolyline* polyLine = [MKPolyline polylineWithCoordinates:coordinates count:5];
    [self.mapView addOverlay:polyLine];
    
    [arrayTapRectangle addObject:polyLine];
    
    self.polyline = polyLine;
    self.lineView = [[MKPolylineView alloc]initWithPolyline:self.polyline];
    self.lineView.strokeColor = [UIColor blueColor];
    self.lineView.lineWidth = 3;

}

- (void)viewDidUnload
{
    [self setLat:nil];
    [self setLlong:nil];
    [self setOffLat:nil];
    [self setOffLog:nil];
    [self setMapView:nil];
    [self setM_locationName:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)drawLineSubroutine {
    
    // remove polyline if one exists
    [self.mapView removeOverlay:self.polyline];
    
    // create an array of coordinates from allPins
    CLLocationCoordinate2D coordinates[self.allPins.count];
    int i = 0;
    for (Pin *currentPin in self.allPins) {
        coordinates[i] = currentPin.coordinate;
        i++;
    }
    
    NSLog(@"%d", self.allPins.count);
    
    // create a polyline with all cooridnates
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:self.allPins.count];
    [self.mapView addOverlay:polyLine];
    self.polyline = polyLine;
    
    // create an MKPolylineView and add it to the map view
    self.lineView = [[MKPolylineView alloc]initWithPolyline:self.polyline];
    self.lineView.strokeColor = [UIColor redColor];
    self.lineView.lineWidth = 5;
    
    // for a laugh: how many polylines are we drawing here?
    self.title = [[NSString alloc]initWithFormat:@"%lu", (unsigned long)self.mapView.overlays.count];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)OpenGPS:(id)sender {
    
}

// 定位成功时调用
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation 
{
    CLLocationCoordinate2D mylocation = newLocation.coordinate;//手机GPS
    currentLocation = newLocation.coordinate;
    
    lat.text = [[NSString alloc]initWithFormat:@"%lf",mylocation.latitude];
    llong.text = [[NSString alloc]initWithFormat:@"%lf",mylocation.longitude];
    
    mylocation = [self zzTransGPS:mylocation];///火星GPS
    
//    MKCoordinateRegion region = self.mapView.region;
    
    [self SetMapPoint:mylocation];
    self.offLat.text = [[NSString alloc]initWithFormat:@"%lf",mylocation.latitude];
    self.offLog.text = [[NSString alloc]initWithFormat:@"%lf",mylocation.longitude];
    
    //显示火星坐标
    if (nTime >= nPoint * 3) {
        Pin *newPin = [[Pin alloc]initWithCoordinate:mylocation];
        [self.mapView addAnnotation:newPin];
        
        nPoint ++;
    }
    
    /////////获取位置信息
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray* placemarks,NSError *error)
    {
        if (placemarks.count > 0)
        {
            CLPlacemark * plmark = [placemarks objectAtIndex:0];
            
            NSString * country = plmark.country;
            NSString * city    = plmark.locality;
            
            
            NSLog(@"%@-%@-%@",country,city,plmark.name);
            self.m_locationName.text =plmark.name;
        }
        
        NSLog(@"%@",placemarks);
        
    }];
    
    //[geocoder release];
    
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    [self.mapView removeOverlays:arrayLine];
    
    for (UIView* view in arrayTapLabel) {
        [view removeFromSuperview];
    }
    
    for (int i = 0; i < [arrayPinkRect count]; i++) {
        UIImageView* imageView = (UIImageView*)[arrayPinkRect objectAtIndex:i];
        [imageView removeFromSuperview];
    }
    
    [arrayTapLabel removeAllObjects];
    [arrayPinkRect removeAllObjects];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    arrayLine = [[NSMutableArray alloc] init];
    
    region = self.mapView.region;
    MKCoordinateSpan span = region.span;
    CLLocationCoordinate2D center = region.center;
    
    if (span.longitudeDelta < LongtitudeSeg * 20 && bShowGridLine == YES) {
        
        CLLocationCoordinate2D posLeftBottom;
        
        posLeftBottom.longitude = center.longitude - span.longitudeDelta / 2;
        posLeftBottom.latitude = center.latitude - span.latitudeDelta / 2;
        
        int nWidthCount = span.longitudeDelta / LongtitudeSeg;
        
        if (bDisplayGrid == NO) {
            bDisplayGrid = YES;
            bottomLeftPos = posLeftBottom;
        }
        else
        {
            int cnWidth = (posLeftBottom.longitude - bottomLeftPos.longitude) / LongtitudeSeg;
            int cnHeight = (posLeftBottom.latitude - bottomLeftPos.latitude) / LongtitudeSeg;
            
            posLeftBottom.longitude = bottomLeftPos.longitude + cnWidth * LongtitudeSeg;
            posLeftBottom.latitude = bottomLeftPos.latitude + cnHeight * LongtitudeSeg;
        }
        
        float fTopLatitude = region.center.latitude + span.latitudeDelta / 2;
        float fBottomLatitude = region.center.latitude - span.latitudeDelta / 2;
        
        int nHeightCount = span.latitudeDelta / LongtitudeSeg;
        
        float fLeftLongtitude = region.center.longitude - span.longitudeDelta / 2;
        float fRightLongtitude = region.center.longitude + span.longitudeDelta / 2;
        
        for (int i = 0; i < nWidthCount + 3; i++) {
            float itemLongtitude = posLeftBottom.longitude + LongtitudeSeg * i;
            
            CLLocationCoordinate2D coordinates[2];
            
            coordinates[0].latitude = fTopLatitude;
            coordinates[0].longitude = itemLongtitude;
            
            coordinates[1].latitude = fBottomLatitude;
            coordinates[1].longitude = itemLongtitude;
            
            MKPolyline* polyLine = [MKPolyline polylineWithCoordinates:coordinates count:2];
            [arrayLine addObject:polyLine];
            [self.mapView addOverlay:polyLine];
            self.polyline = polyLine;
            self.lineView = [[MKPolylineView alloc]initWithPolyline:self.polyline];
            self.lineView.strokeColor = [UIColor redColor];
            self.lineView.lineWidth = 1;
        }
        
        for (int i = 0; i < nHeightCount + 3; i++) {
            float itemLatitude = posLeftBottom.latitude + LongtitudeSeg * i;
            
            CLLocationCoordinate2D coordinates[2];
            coordinates[0].latitude = itemLatitude;
            coordinates[0].longitude = fLeftLongtitude;
            
            coordinates[1].latitude = itemLatitude;
            coordinates[1].longitude = fRightLongtitude;
            
            MKPolyline* polyLine = [MKPolyline polylineWithCoordinates:coordinates count:2];
            [arrayLine addObject:polyLine];
            [self.mapView addOverlay:polyLine];
            self.polyline = polyLine;
            self.lineView = [[MKPolylineView alloc]initWithPolyline:self.polyline];
            self.lineView.strokeColor = [UIColor redColor];
            self.lineView.lineWidth = 1;
        }
        
        for (int i = 0; i < [arrayTapPoint count]; i++) {
            CLLocation *ptLoc = [arrayTapPoint objectAtIndex:i];
            CLLocationCoordinate2D ptCenter = ptLoc.coordinate;
            
            CLLocationCoordinate2D ptRectangle[5];
            
            ptRectangle[0].latitude = ptCenter.latitude + LongtitudeSeg / 2;
            ptRectangle[0].longitude = ptCenter.longitude - LongtitudeSeg / 2;
            
            ptRectangle[1].latitude = ptCenter.latitude + LongtitudeSeg / 2;
            ptRectangle[1].longitude = ptCenter.longitude + LongtitudeSeg / 2;
            
            ptRectangle[2].latitude = ptCenter.latitude - LongtitudeSeg / 2;
            ptRectangle[2].longitude = ptCenter.longitude + LongtitudeSeg / 2;
            
            ptRectangle[3].latitude = ptCenter.latitude - LongtitudeSeg / 2;
            ptRectangle[3].longitude = ptCenter.longitude - LongtitudeSeg / 2;
            
            ptRectangle[4].latitude = ptCenter.latitude + LongtitudeSeg / 2;
            ptRectangle[4].longitude = ptCenter.longitude - LongtitudeSeg / 2;
            
            CGPoint ptOne = [self.mapView convertCoordinate:ptRectangle[0] toPointToView:self.view];
            CGPoint ptTwo = [self.mapView convertCoordinate:ptRectangle[1] toPointToView:self.view];
            CGPoint ptThree = [self.mapView convertCoordinate:ptRectangle[2] toPointToView:self.view];
            
            UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pink.png"]];
            imageView.frame = CGRectMake(ptOne.x, ptOne.y, ptTwo.x - ptOne.x - 1 , ptThree.y - ptOne.y - 1);
            imageView.alpha = 0.6;
            [arrayPinkRect addObject:imageView];
            [self.view addSubview:imageView];
            
            UILabel* lblNumber = [[UILabel alloc] initWithFrame:CGRectMake(ptOne.x, ptOne.y, ptTwo.x - ptOne.x, ptThree.y - ptOne.y)];
            lblNumber.text = [NSString stringWithFormat:@"%d", nArrayTapCount[i]];
            lblNumber.textAlignment = NSTextAlignmentCenter;
            lblNumber.textColor = [UIColor redColor];
            lblNumber.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:20];
            [arrayTapLabel addObject:lblNumber];
            [self.view addSubview:lblNumber];
        }
    }
    else
    {
        nTapCount = 0;
        bDisplayGrid = NO;
        if ([arrayTapRectangle count] != 0) {
            [self.mapView removeOverlays:arrayTapRectangle];
        }
        if ([arrayTapLabel count] != 0) {
            [arrayTapLabel removeAllObjects];
        }
        if ([arrayTapPoint count] != 0) {
            [arrayTapPoint removeAllObjects];
        }
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    
    return self.lineView;
}


// 定位失败时调用
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
}

-(CLLocationCoordinate2D)zzTransGPS:(CLLocationCoordinate2D)yGps
{
    int TenLat=0;
    int TenLog=0;
    TenLat = (int)(yGps.latitude*10);
    TenLog = (int)(yGps.longitude*10);
    NSString *sql = [[NSString alloc]initWithFormat:@"select offLat,offLog from gpsT where lat=%d and log = %d",TenLat,TenLog];
    sqlite3_stmt* stmtL = [m_sqlite NSRunSql:sql];
    int offLat=0;
    int offLog=0;
    while (sqlite3_step(stmtL)==SQLITE_ROW)
    {
        offLat = sqlite3_column_int(stmtL, 0);
        offLog = sqlite3_column_int(stmtL, 1);
    }
    
    yGps.latitude = yGps.latitude+offLat*0.0001;
    yGps.longitude = yGps.longitude + offLog*0.0001;
    return yGps;
}

- (void)addPin:(UIGestureRecognizer *)recognizer {
    
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    // convert touched position to map coordinate
    CGPoint userTouch = [recognizer locationInView:self.mapView];
    CLLocationCoordinate2D mapPoint = [self.mapView convertPoint:userTouch toCoordinateFromView:self.mapView];
    
    // and add it to our view and our array
    Pin *newPin = [[Pin alloc]initWithCoordinate:mapPoint];
    [self.mapView addAnnotation:newPin];
    [self.allPins addObject:newPin];
    
    [self drawLineSubroutine];
    [self drawLineSubroutine];
}

-(void)SetMapPoint:(CLLocationCoordinate2D)myLocation
{

    POI* m_poi = [[POI alloc]initWithCoords:myLocation];
    
    [self.mapView addAnnotation:m_poi];
    
    MKCoordinateRegion theRegion = { {0.0, 0.0 }, { 0.0, 0.0 } };
    theRegion.center=myLocation;
    [self.mapView setZoomEnabled:YES];
    [self.mapView setScrollEnabled:YES];
    theRegion.span.longitudeDelta = 0.01f;
    theRegion.span.latitudeDelta = 0.01f;
    [self.mapView setRegion:theRegion animated:YES];
}

- (IBAction)onGridLine:(id)sender
{
    UIButton* btnGrid = (UIButton*)sender;
    
    if (bShowGridLine == YES) {        
        [btnGrid setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
    else
    {
        bShowGridLine = YES;
        [btnGrid setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
}
@end


@implementation POI

@synthesize coordinate,subtitle,title;

- (id) initWithCoords:(CLLocationCoordinate2D) coords{
    
    self = [super init];
    
    if (self != nil) {
        
        coordinate = coords;
        
    }
    
    return self;
    
}


@end
