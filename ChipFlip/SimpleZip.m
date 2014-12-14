//
//  SimpleZip.m
//  SecretChess
//
//  Created by Secret Chess on 7/23/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "SimpleZip.h"

NSData* compressData(NSData* uncompressedData);
NSData* uncompressGZip(NSData* compressedData);

@interface SimpleZip()
+(BOOL)isSim;
@end

@implementation SimpleZip
+(BOOL)isSim
{
    UIDevice *current = [UIDevice currentDevice];
    NSRange r = [[current model] rangeOfString:@"Simulator"];
    return (r.length > 0);
}

+(NSData*)compress:(NSData*)nsdata 
{
    if ([SimpleZip isSim]) {
        return nsdata;
    }
    return compressData(nsdata);
}
+(NSData*)uncompress:(NSData*)nsdata 
{
    if ([SimpleZip isSim]) {
        return nsdata;
    }
    return uncompressGZip(nsdata);
}

////////////////////////////////////////////////////////
NSData* uncompressGZip(NSData* compressedData) 
{
    if ([compressedData length] == 0) {
        return compressedData;
    }
    
    NSUInteger full_length = [compressedData length];
    NSUInteger half_length = [compressedData length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[compressedData bytes];
    strm.avail_in = (unsigned int)[compressedData length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) {
        return nil;
    }
    
    while (!done) 
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length]) {
            [decompressed increaseLengthBy: half_length];
        }
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (unsigned int)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) {
            done = YES;
        } 
        else if (status != Z_OK) {
            break;
        }
    }
    if (inflateEnd (&strm) != Z_OK) {
        return nil;
    }
    
    // Set real length.
    if (done) 
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    } 
    else {
        return nil;
    }
}

NSData* compressData(NSData* uncompressedData) 
{
    if ([uncompressedData length] == 0) {
        return uncompressedData;
    }
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[uncompressedData bytes];
    strm.avail_in = (unsigned int)[uncompressedData length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    //if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, 
    if (deflateInit2(&strm, Z_BEST_COMPRESSION, 
                     Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) 
    {
        return nil;
    }

    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion

    do {        
        if (strm.total_out >= [compressed length]) {
            [compressed increaseLengthBy: 16384];
        }
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (unsigned int)([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);  
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    return [NSData dataWithData:compressed];
}

@end
