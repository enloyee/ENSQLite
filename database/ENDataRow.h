//
//  ENDataRow.h
//  ENSQLite
//
//  Created by enloyee on 11-11-13.
//  Email: enloyee@hotmail.com
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "/usr/include/sqlite3.h"

@interface ENDataRow : NSObject
{
    sqlite3_stmt *_statement;
}

- (id)initWithStatement:(sqlite3_stmt *)statement;
- (BOOL)next;
- (BOOL)done;
- (void)close;

- (BOOL)isNullForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;

- (BOOL)isNullForColumn:(int)col;
- (NSInteger)integerForColumn:(int)col;
- (float)floatForColumn:(int)col;
- (double)doubleForColumn:(int)col;
- (BOOL)boolForColumn:(int)col;
- (NSString *)stringForColumn:(int)col;
- (NSData *)dataForColumn:(int)col;

- (void)setNullForKey:(NSString *)key;
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setFloat:(float)value forKey:(NSString *)key;
- (void)setDouble:(double)value forKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (void)setString:(NSString *)value forKey:(NSString *)key;
- (void)setData:(NSData *)value forKey:(NSString *)key;

- (void)setNullForColumn:(int)col;
- (void)setInteger:(NSInteger)value forColumn:(int)col;
- (void)setFloat:(float)value forColumn:(int)col;
- (void)setDouble:(double)value forColumn:(int)col;
- (void)setBool:(BOOL)value forColumn:(int)col;
- (void)setString:(NSString *)value forColumn:(int)col;
- (void)setData:(NSData *)value forColumn:(int)col;

@end
