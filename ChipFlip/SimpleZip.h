//
//  SimpleZip.h
//  SecretChess
//
//  Created by Secret Chess on 7/23/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "zlib.h"
#import <Foundation/Foundation.h>

@interface SimpleZip : NSObject

+(NSData*)uncompress:(NSData*)nsdata;
+(NSData*)compress:(NSData*)nsdata;
@end
