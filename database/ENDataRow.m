//
//  ENDataRow.m
//  ENSQLite
//
//  Created by enloyee on 11-11-13.
//  Email: enloyee@hotmail.com
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import "ENDataRow.h"

@interface ENDataRow()
- (int)indexForColumnKey:(NSString *)key;
- (int)indexForBindKey:(NSString *)key;
@end

@implementation ENDataRow

- (int)indexForColumnKey:(NSString *)key
{
    const char *aKey = [key UTF8String];
    for (int i = 0; i < sqlite3_column_count(_statement); i++)
    {
        if (strcmp(aKey, sqlite3_column_name(_statement, i)) == 0)
            return i;
    }
    NSLog(@"Error: Column %@ is not found.", key);
    return -1;
}

- (int)indexForBindKey:(NSString *)key
{
    return sqlite3_bind_parameter_index(_statement, [key UTF8String]);
}

- (id)initWithStatement:(sqlite3_stmt *)statement
{
    if (self = [super init])
    {
        _statement = statement;
    }
    return self;
}

- (BOOL)next
{
    if (sqlite3_step(_statement) == SQLITE_ROW)
        return YES;
    return NO;
}

- (BOOL)done
{
    if (sqlite3_step(_statement) == SQLITE_DONE)
        return YES;
    return NO;
}

- (void)close
{
    sqlite3_finalize(_statement);
}

- (BOOL)isNullForKey:(NSString *)key
{
    int col = [self indexForColumnKey:key];
    if (col == -1)
        return YES;
    return [self isNullForColumn:col];
}

- (NSInteger)integerForKey:(NSString *)key
{
    int col = [self indexForColumnKey:key];
    if (col == -1)
        return INT_MIN;
    return [self integerForColumn:col];
}

- (float)floatForKey:(NSString *)key
{
    int col = [self indexForColumnKey:key];
    if (col == -1)
        return (float)INT_MIN;
    return [self floatForColumn:col];
}

- (double)doubleForKey:(NSString *)key
{
    int col = [self indexForColumnKey:key];
    if (col == -1)
        return (double)INT_MIN;
    return [self doubleForColumn:col];
}

- (BOOL)boolForKey:(NSString *)key
{
    int col = [self indexForColumnKey:key];
    if (col == -1)
        return NO;
    return [self boolForColumn:col];
}

- (NSString *)stringForKey:(NSString *)key
{
    int col = [self indexForColumnKey:key];
    if (col == -1)
        return nil;
    return [self stringForColumn:col];
}

- (NSData *)dataForKey:(NSString *)key
{
    int col = [self indexForColumnKey:key];
    if (col == -1)
        return nil;
    return [self dataForColumn:col];
}

- (BOOL)isNullForColumn:(int)col
{
    if (col == -1)
        return YES;
    return sqlite3_column_type(_statement, col) == SQLITE_NULL;
}

- (NSInteger)integerForColumn:(int)col
{
    return (NSInteger)sqlite3_column_int(_statement, col);
}

- (float)floatForColumn:(int)col
{
    return (float)sqlite3_column_double(_statement, col);
}

- (double)doubleForColumn:(int)col
{
    return sqlite3_column_double(_statement, col);
}

- (BOOL)boolForColumn:(int)col
{
    return sqlite3_column_int(_statement, col) == 1;
}

- (NSString *)stringForColumn:(int)col
{
    const char *str = (const char *)sqlite3_column_text(_statement, col);
    return [NSString stringWithUTF8String:str];
}

- (NSData *)dataForColumn:(int)col
{
    const void *data = sqlite3_column_blob(_statement, col);
    int length = sqlite3_column_bytes(_statement, col);
    return [NSData dataWithBytes:data length:length];
}

- (void)setNullForKey:(NSString *)key
{
    [self setNullForColumn:sqlite3_bind_parameter_index(_statement, [key UTF8String])];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key
{
    int col = [self indexForBindKey:key];
    if (col == 0)
        return;
    [self setInteger:value forColumn:col];
}

- (void)setFloat:(float)value forKey:(NSString *)key
{
    int col = [self indexForBindKey:key];
    if (col == 0)
        return;
    [self setFloat:value forColumn:col];
}

- (void)setDouble:(double)value forKey:(NSString *)key
{
    int col = [self indexForBindKey:key];
    if (col == 0)
        return;
    [self setDouble:value forColumn:col];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key
{
    int col = [self indexForBindKey:key];
    if (col == 0)
        return;
    [self setBool:value forColumn:sqlite3_bind_parameter_index(_statement, [key UTF8String])];
}

- (void)setString:(NSString *)value forKey:(NSString *)key
{
    int col = [self indexForBindKey:key];
    if (col == 0)
        return;
    [self setString:value forColumn:col];
}

- (void)setData:(NSData *)value forKey:(NSString *)key
{
    int col = [self indexForBindKey:key];
    if (col == 0)
        return;
    [self setData:value forColumn:sqlite3_bind_parameter_index(_statement, [key UTF8String])];
}

- (void)setNullForColumn:(int)col
{
    sqlite3_bind_null(_statement, col);
}

- (void)setInteger:(NSInteger)value forColumn:(int)col
{
    sqlite3_bind_int(_statement, col, (int)value);
}

- (void)setFloat:(float)value forColumn:(int)col
{
    sqlite3_bind_double(_statement, col, (double)value);
}

- (void)setDouble:(double)value forColumn:(int)col
{
    sqlite3_bind_double(_statement, col, value);
}

- (void)setBool:(BOOL)value forColumn:(int)col
{
    sqlite3_bind_int(_statement, col, value ? 1 : 0);
}

- (void)setString:(NSString *)value forColumn:(int)col
{
    sqlite3_bind_text(_statement, col, [value UTF8String], [value length], SQLITE_TRANSIENT);
}

- (void)setData:(NSData *)value forColumn:(int)col
{
    sqlite3_bind_blob(_statement, col, [value bytes], [value length], SQLITE_TRANSIENT);
}

@end
