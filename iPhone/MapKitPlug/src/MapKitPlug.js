/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2010, Nitobi Software Inc., Brett Rudd, Jesse MacFadyen
 */

function MapKitPlug()
{
	this.options = 
	{
		// Default options
    "firstPinCurrentLocation": false, // is the first pin the user's current location?
    "buttonClose"   :true, // show a close button?
		"buttonCallback": "window.plugins.mapKit.onMapCallback", // callback on annotation click
		"diameter"      :1000, // diameter in meters (0: display map showing ALL pins)
    "offsetTop"     :0, // pixel offset from top
    "offsetBottom"  :0, // pixel offset from bottom
		// ( nitobi HQ, if you have issues, send missles here )
		"lat"           :49.281468, // lat/lon for center of map (ignored when diameter is 0) 
		"lon"           :-123.104446
	};
}

MapKitPlug.Pin = function()
{
//	this.lat = 
//	this.lon = 
//	this.title = 
//  this.subTitle =
//	this.pinColor = 
//	this.index = 
//  this.clickable =
//  this.imageURL =
//	this.selected = false;
	
};

/* This is the way google maps v3 does it */
/* 
 var myLatlng = new google.maps.LatLng(-34.397, 150.644);
 var myOptions = {
 zoom: 8,
 center: myLatlng,
 mapTypeId: google.maps.MapTypeId.ROADMAP | SATELLITE | HYBRID | TERRAIN
 };
 
 var map = new google.maps.Map(document.getElementById("map_canvas"),
 myOptions);
 
 map.setCenter(latlng)
 map.getZoom()
 map.setZoom()
 
 var southWest = new google.maps.LatLng(-31.203405,125.244141);
 var northEast = new google.maps.LatLng(-25.363882,131.044922);
 var bounds = new google.maps.LatLngBounds(southWest,northEast);
 map.fitBounds(bounds);
 
 */

MapKitPlug.prototype.onMapCallback = function(pindex)
{
	alert("You selected pin : " + pindex);
};

MapKitPlug.prototype.showMap = function()
{
	PhoneGap.exec("MapKitView.showMap", {});
};

MapKitPlug.prototype.hideMap = function() 
{
	PhoneGap.exec("MapKitView.hideMap", {});
};

/*
 Available options
 options = {
 buttonCallback:String, string callback function
 height:Number, - pixels
 diameter:Number, - meters
 atBottom:Bool,
 lat:Number,
 lon:Number
 }; 
*/

MapKitPlug.prototype.setMapData = function(pins, options)
{
	for(var v in options)
	{
		if(options.hasOwnProperty(v))
		{
			this.options[v] = options[v];
		}
	}
	
	var pinStr = "[]";
	if(pins)
	{
		pinStr = JSON.stringify(pins);
	}
	
	PhoneGap.exec("MapKitView.setMapData", pinStr, this.options);
};

// Coming Soon!!
//MapKitPlug.prototype.destroyMap = function()
//{
//	PhoneGap.exec("MapKitView.destroyMap", {});
//};

MapKitPlug.install = function()
{
	if(!window.plugins)
	{
		window.plugins = {};
	}
	window.plugins.mapKit = new MapKitPlug();
};
PhoneGap.addConstructor(MapKitPlug.install);