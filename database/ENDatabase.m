//
//  ENDatabase.m
//  ENSQLite
//
//  Created by enloyee on 11-11-13.
//  Email: enloyee@hotmail.com
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import "ENDatabase.h"
#import "ENDataRow.h"

#define kENDataFilePath @"data.sqlite"

@interface ENDatabase()

@property (assign, nonatomic) NSInteger traceCount;

- (id)initWithFilePath:(NSString *)path;

@end

@implementation ENDatabase

@synthesize filePath = _filePath;
@synthesize traceCount = _traceCount;

- (id)init
{
    return nil;
}

- (id)initWithFilePath:(NSString *)path
{
    if (self = [super init])
    {
        self.filePath = path;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        self.filePath = [documentsDirectory stringByAppendingPathComponent:self.filePath];
        self.traceCount = 0;
    }
    return self;
}

+ (ENDatabase *)sharedDatabase
{
    static ENDatabase *_instance = nil;
    @synchronized(self)
    {
        if (_instance == nil)
        {
            _instance = [[ENDatabase alloc] initWithFilePath:kENDataFilePath];
        }
        return _instance;
    }
}

- (ENDataRow *)executeQuery:(NSString *)query
{
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        ENDataRow *row = [[ENDataRow alloc] initWithStatement:statement];
        return row;
    }
    NSLog(@"Error: Sqlite prepare failed");
    return nil;
}

- (BOOL)executeNonQuery:(NSString *)sql
{
    char *errorMsg;
    if (sqlite3_exec(_database, [sql UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK)
    {
        NSLog(@"Error: %s", errorMsg);
        return NO;
    }
    return YES;
}

- (ENDataRow *)compile:(NSString *)sql
{
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(_database, [sql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        return [[ENDataRow alloc] initWithStatement:statement];
    }
    return nil;
}

- (NSInteger)lastInsertRowId
{
    return (NSInteger)sqlite3_last_insert_rowid(_database);
}

- (BOOL)open
{
    NSAssert(self.traceCount >= 0, @"Trace error of database opened.");
    if (self.traceCount == 0 && 
        sqlite3_open([self.filePath UTF8String], &_database) != SQLITE_OK)
        return NO;
    self.traceCount++;
    return YES;
}

- (void)close
{
    NSAssert(self.traceCount >= 0, @"Trace error of database opened.");
    self.traceCount--;
    if (self.traceCount == 0)
        sqlite3_close(_database);
}

- (void)beginTransaction
{
    sqlite3_exec(_database, "BEGIN", 0, 0, 0);
}

- (void)commit
{
    sqlite3_exec(_database, "COMMIT", 0, 0, 0);
}

- (void)rollback
{
    sqlite3_exec(_database, "ROLLBACK", 0, 0, 0);
}

- (void)dealloc
{
    self.filePath = nil;
}

@end
