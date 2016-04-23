# HingeTest
App for Hinge Coding Test

Currently tested for iOS 9.3 on iPhone 5, 6, 6 Plus, 6s, 6s Plus

CollectionView
* Displays thumbnails of all the images downloaded from the API endpoint above.
* A user can scroll through thumbnails of all the images
* Images are displayed in order received by the server
* Each image should be downloaded asynchronously and in a thread-safe manner
* Clicking on a thumbnail opens GalleryView
* Included Pull to Refresh to delete all images in DataStore and reload all imagess from network

GalleryView
* Displays initial image clicked on then steps through all images with 2 second delay
* Displays image’s position in the list (i.e., “5/16”)
* Includes a button to delete image - only available when Pause animation
* Includes Tap Gesture to Pause animation and activate Delete 

