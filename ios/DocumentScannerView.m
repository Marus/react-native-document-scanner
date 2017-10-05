#import "DocumentScannerView.h"
#import "IPDFCameraViewController.h"

@implementation DocumentScannerView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupCameraView];
        [self setEnableBorderDetection:YES];


        [self setOverlayColor: self.overlayColor];
        [self setEnableTorch: self.enableTorch];

        [self setContrast: self.contrast];
        [self setBrightness: self.brightness];
        [self setSaturation: self.saturation];


        [self start];
        [self setDelegate: self];
    }

    return self;
}


- (void) didDetectRectangle:(CIRectangleFeature *)rectangle withType:(IPDFRectangeType)type {
    switch (type) {
        case IPDFRectangeTypeGood:
            self.stableCounter ++;
            break;
        default:
            self.stableCounter = 0;
            break;
    }
    if (self.onRectangleDetect) {
        self.onRectangleDetect(@{@"stableCounter": @(self.stableCounter), @"lastDetectionType": @(type)});
    }

    if (self.stableCounter > self.detectionCountBeforeCapture){
        [self capture];
    }
}

- (void) capture {
    [self captureImageWithCompletionHander:^(UIImage *croppedImage, UIImage *initialImage, CIRectangleFeature *rectangleFeature) {

        if (self.onPictureTaken) {
            NSData *croppedImageData = UIImageJPEGRepresentation(croppedImage, self.quality);

//            if (initialImage.imageOrientation != UIImageOrientationUp) {
//                UIGraphicsBeginImageContextWithOptions(initialImage.size, false, initialImage.scale);
//                [initialImage drawInRect:CGRectMake(0, 0, initialImage.size.width
//                                                    , initialImage.size.height)];
//                initialImage = UIGraphicsGetImageFromCurrentImageContext();
//                UIGraphicsEndImageContext();
//            }
//            NSData *initialImageData = UIImageJPEGRepresentation(initialImage, self.quality);

            /*
             RectangleCoordinates expects a rectanle viewed from portrait,
             while rectangleFeature returns a rectangle viewed from landscape, which explains the nonsense of the mapping below.
             Sorry about that.
             */
            [self stop];
            NSDictionary *rectangleCoordinates = rectangleFeature ? @{
                                     @"topLeft": @{ @"y": @(rectangleFeature.bottomLeft.x + 30), @"x": @(rectangleFeature.bottomLeft.y)},
                                     @"topRight": @{ @"y": @(rectangleFeature.topLeft.x + 30), @"x": @(rectangleFeature.topLeft.y)},
                                     @"bottomLeft": @{ @"y": @(rectangleFeature.bottomRight.x), @"x": @(rectangleFeature.bottomRight.y)},
                                     @"bottomRight": @{ @"y": @(rectangleFeature.topRight.x), @"x": @(rectangleFeature.topRight.y)},
                                     } : [NSNull null];
            self.onPictureTaken(@{
                                  @"croppedImage": [croppedImageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength],
//                                  @"initialImage": [initialImageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength],
                                  @"rectangleCoordinates": rectangleCoordinates });
        }
        else {
            [self stop];
        }
    }];

}


@end
