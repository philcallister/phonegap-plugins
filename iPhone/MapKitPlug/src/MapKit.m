//

//  PhoneGap
//
//

#import "MapKit.h"
#import "PGAnnotation.h"
#import "SBJsonParser.h"
#import "SBJSON.h"
#import "AsyncImageView.h"

@implementation MapKitView

@synthesize buttonCallback;
@synthesize childView;
@synthesize mapView;
@synthesize imageButton;


-(PhoneGapCommand*) initWithWebView:(UIWebView*)theWebView
{
  self = (MapKitView*)[super initWithWebView:theWebView];
  return self;
}

/**
 * Create a native map view
 */
- (void)createView
{
	childView = [[UIView alloc] init];
  mapView = [[MKMapView alloc] init];
  [mapView sizeToFit];
  mapView.delegate = self;
  mapView.multipleTouchEnabled   = YES;
  mapView.autoresizesSubviews    = YES;
  mapView.userInteractionEnabled = YES;
	mapView.showsUserLocation = YES;
	
	imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[childView addSubview:mapView];
	[childView addSubview:imageButton];

	[ [ [ super appViewController ] view ] addSubview:childView];  
}

- (void)destroyMap:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	if (mapView)
	{
		[ mapView removeAnnotations:mapView.annotations];
		[ mapView removeFromSuperview];

		mapView = nil;
	}
	if(imageButton)
	{
		[ imageButton removeFromSuperview];
		[ imageButton removeTarget:self action:@selector(closeButton:) forControlEvents:UIControlEventTouchUpInside];
		imageButton = nil;
		
	}
	if(childView)
	{
		[ childView removeFromSuperview];
		childView = nil;
	}
	[ buttonCallback release ];
}

/**
 * Set annotations and mapview settings
 */
- (void)setMapData:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	// map creation
  if (!mapView) 
	{
		[self createView];
	}
	else 
	{
		[mapView removeAnnotations:mapView.annotations];
	}
  // current location option - a bit of hackery here.  Instead of waiting
  // for the current location to become available, we'll just pass it in as
  // the 1st pin, since we can get it from PhoneGap.  This 1st pin will then
  // be used to calculate the map region.
  // TODO: Don't pass as a pin.  Instead, calculate here. 
  BOOL currentLocation = NO;
  // offset from top
  CGFloat offsetTop = 0.0f;
  // offset from bottom
  CGFloat offsetBottom = 0.0f;
  // close button
  BOOL buttonClose = YES;
  // show all annotations
  BOOL showAllAnnotations = NO;
	
  if ([options objectForKey:@"firstPinCurrentLocation"])
  {
    currentLocation=[[options objectForKey:@"firstPinCurrentLocation"] boolValue];
  }
	if ([options objectForKey:@"buttonCallback"])
	{
		self.buttonCallback=[[options objectForKey:@"buttonCallback"] description];
	}
  if ([options objectForKey:@"buttonClose"])
  {
    buttonClose=[[options objectForKey:@"buttonClose"] boolValue];
  }
  if ([options objectForKey:@"offsetTop"])
  {
    offsetTop=[[options objectForKey:@"offsetTop"] floatValue];
  }
  if ([options objectForKey:@"offsetBottom"])
  {
    offsetBottom=[[options objectForKey:@"offsetBottom"] floatValue];
  }
	CLLocationDistance diameter = [[options objectForKey:@"diameter"] floatValue];
  if (diameter == 0)
  {
    showAllAnnotations = YES;
  }
	
  // add annotations
  PGAnnotation *currentLocationAnnotation = nil;
  NSArray *pins = [[NSArray alloc] init];
	SBJSON *parser=[[SBJSON alloc] init];
	pins = [parser objectWithString:[arguments objectAtIndex:0]];
	for (int y = 0; y < pins.count; y++) 
	{
		NSDictionary *pinData = [pins objectAtIndex:y];
		CLLocationCoordinate2D pinCoord = { [[pinData objectForKey:@"lat"] floatValue] , [[pinData objectForKey:@"lon"] floatValue] };
		NSString *title=[[pinData valueForKey:@"title"] description];
		NSString *subTitle=[[pinData valueForKey:@"subTitle"] description];
		NSString *imageURL=[[pinData valueForKey:@"imageURL"] description];
		NSString *pinColor=[[pinData valueForKey:@"pinColor"] description];
		NSInteger index=[[pinData valueForKey:@"index"] integerValue];
		BOOL selected = [[pinData valueForKey:@"selected"] boolValue];
    BOOL clickable = [[pinData valueForKey:@"clickable"] boolValue];

		PGAnnotation *annotation = [[PGAnnotation alloc] initWithCoordinate:pinCoord index:index title:title subTitle:subTitle imageURL:imageURL];
		annotation.pinColor=pinColor;
		annotation.selected = selected;
    annotation.clickable = clickable;

    if (y == 0 && currentLocation == YES)
    {
      currentLocationAnnotation = annotation;
    }
    else
    {
      [mapView addAnnotation:annotation];
      [annotation release];
    }
	}
	
  // show map close button?
  if (buttonClose)
  {
    CGRect frame = CGRectMake(285.0,12.0 + offsetTop,  29.0, 29.0);
    [ imageButton setImage:[UIImage imageNamed:@"www/map-close-button.png"] forState:UIControlStateNormal];
    [ imageButton setFrame:frame];
    [ imageButton addTarget:self action:@selector(closeButton:) forControlEvents:UIControlEventTouchUpInside];
  }

  // calculate map display
	CGRect webViewBounds = webView.bounds;
  CGFloat height = webViewBounds.size.height - offsetTop - offsetBottom;
	CGRect childBounds = CGRectMake(webViewBounds.origin.x,
                                  webViewBounds.origin.y + offsetTop,
                                  webViewBounds.size.width,
                                  height);
  CGRect mapBounds = CGRectMake(0.0, 0.0, webViewBounds.size.width, height);
	[childView setFrame:childBounds];
	[mapView setFrame:mapBounds];
  
  // show either all annotations OR show a centered lat/lon with diameter
  MKCoordinateRegion region;
  if (showAllAnnotations && [mapView.annotations count] > 0)
  {
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    for(PGAnnotation* annotation in mapView.annotations)
    {
      topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
      topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
      bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
      bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
    }
    // include user's current location in calculation
    if (currentLocation == YES && currentLocationAnnotation != nil)
    {
      topLeftCoord.longitude = fmin(topLeftCoord.longitude, currentLocationAnnotation.coordinate.longitude);
      topLeftCoord.latitude = fmax(topLeftCoord.latitude, currentLocationAnnotation.coordinate.latitude);
      bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, currentLocationAnnotation.coordinate.longitude);
      bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, currentLocationAnnotation.coordinate.latitude);
    }
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.2; // Add a little extra space on the sides
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.2; // Add a little extra space on the sides
    region = [mapView regionThatFits:region];
    
  }
  else 
  {
    CLLocationCoordinate2D centerCoord = { [[options objectForKey:@"lat"] floatValue] , [[options objectForKey:@"lon"] floatValue] };
    region=[ mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord, 
                                                                        diameter*(height / webViewBounds.size.width), 
                                                                        diameter*(height / webViewBounds.size.width))];
  }
  
  // 1st annotation being used for current location.  Remove this annotation
  // now that we've calculated the region with it.
  if (currentLocationAnnotation != nil)
  {
    [currentLocationAnnotation release];
  }  
  [mapView setRegion:region animated:YES];
}

- (void)closeButton:(id)button
{
	[ self hideMap:NULL withDict:NULL];
	NSString* jsString = [NSString stringWithFormat:@"%@(\"%i\");", self.buttonCallback,-1];
	[webView stringByEvaluatingJavaScriptFromString:jsString];
}

- (void)showMap:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	if (!mapView) 
	{
		[self createView];
	}
	childView.hidden = NO;
	mapView.showsUserLocation = YES;
}


- (void)hideMap:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
  if (!mapView || childView.hidden==YES) 
	{
		return;
	}
	// disable location services, if we no longer need it.
	mapView.showsUserLocation = NO;
	childView.hidden = YES;
}

- (MKAnnotationView *) mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>) annotation
{
	if ([annotation class] != PGAnnotation.class)
  {
    return nil;
  }
	
	PGAnnotation *phAnnotation=(PGAnnotation *) annotation;
	NSString *identifier=[NSString stringWithFormat:@"INDEX[%i]", phAnnotation.index];

	MKPinAnnotationView *annView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:identifier];
	
	if (annView!=nil) return annView;

	annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
	
	annView.animatesDrop=YES;
	annView.canShowCallout = YES;
	if ([phAnnotation.pinColor isEqualToString:@"green"])
		annView.pinColor = MKPinAnnotationColorGreen;
	else if ([phAnnotation.pinColor isEqualToString:@"purple"])
		annView.pinColor = MKPinAnnotationColorPurple;
	else
		annView.pinColor = MKPinAnnotationColorRed;

	AsyncImageView* asyncImage = [[[AsyncImageView alloc] initWithFrame:CGRectMake(0,0, 50, 32)] autorelease];
	asyncImage.tag = 999;
	if (phAnnotation.imageURL)
	{
		NSURL *url = [[NSURL alloc] initWithString:phAnnotation.imageURL];
		[asyncImage loadImageFromURL:url];
		[ url release ];
	} 
	else 
	{
		[asyncImage loadDefaultImage];
	}
	
	annView.leftCalloutAccessoryView = asyncImage;

	if (self.buttonCallback && phAnnotation.clickable)
	{
		UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		myDetailButton.frame = CGRectMake(0, 0, 23, 23);
		myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		myDetailButton.tag=phAnnotation.index;
		annView.rightCalloutAccessoryView = myDetailButton;
		[ myDetailButton addTarget:self action:@selector(checkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	}
	
	if(phAnnotation.selected)
	{
		[self performSelector:@selector(openAnnotation:) withObject:phAnnotation afterDelay:1.0];
	}

	return annView;
}

-(void)openAnnotation:(id <MKAnnotation>) annotation
{
	[ mapView selectAnnotation:annotation animated:YES];  
}

- (void)checkButtonTapped:(id)button 
{
	UIButton *tmpButton = button;
	NSString* jsString = [NSString stringWithFormat:@"%@(\"%i\");", self.buttonCallback, tmpButton.tag];
	[webView stringByEvaluatingJavaScriptFromString:jsString];
}

- (void)dealloc
{
    if (mapView)
	{
		[ mapView removeAnnotations:mapView.annotations];
		[ mapView removeFromSuperview];
        [ mapView release];
	}
	if(imageButton)
	{
		[ imageButton removeFromSuperview];
		[ imageButton release];
	}
	if(childView)
	{
		[ childView removeFromSuperview];
		[ childView release];
	}
	[ buttonCallback release ];
    [super dealloc];
}

@end
