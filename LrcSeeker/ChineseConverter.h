//
//  ChineseConverter.h
//  LrcSeeker
//
//  Created by Eru on 15/11/22.
//  Copyright © 2015年 Eru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "opencc.h"

NSString* convertToChineseUsingProfile (NSString* profile, NSString* inputStr);

NSString* convertToSC (NSString* input);

NSString* convertToTC (NSString* input);

NSString* convertToTCTW (NSString* input);

NSString* convertToTCHK (NSString* input);