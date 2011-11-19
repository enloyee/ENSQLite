//
//  ENDatabase.h
//  ENSQLite
//  ENSQLite is for wrapping the SQLite API with Objective-C object.
//
//  ENDatabase is a singleton object for SQLite database. A ENDatabase can be
//  created by following steps:
//
//  ENDatabase *db = [ENDatabase defaultDatabase];
//    /*
//    db_file_name is an NSString of your own db file, or can be replaced
//    by nil, where the default file @"data.sqlite" will be used.
//     */
//  BOOL ret = [db open];
//  if (ret) {
//     // do your db operations
//    [db close];
//  }
//
//  The database operations can be implemented by follows:
//  1. CREATE TABLE || DELETE
//    ENDatabase *db = [ENDatabase defaultDatabase];
//    BOOL ret = [db open];
//    if (ret)
//    {
//        [db executeNonQuery:@"sql statement"];
//        [db close];
//    }
//  2. SELECT
//    ENDatabase *db = [ENDatabase defaultDatabase];
//    NSMutableArray *array = nil;
//    BOOL ret = [db open];
//    if (ret)
//    {
//        NSString *sql = [NSString stringWithFormat:@"select_statement", some_params, ...];
//        ENDataRow *row = [db executeQuery:sql];
//        if (row != nil)
//        {
//            array = [[NSMutableArray alloc] init];
//            while ([row next])
//            {
//                AnObject *obj = [[AnObject alloc] init];
//                obj.value1 = [row integerForKey:@"column_name1"];
//                obj.value2 = [row stringForColumn:2];
//                [array addObject:obj];
//            }
//            [row close];
//        }
//        [db close];
//    }
//  3. INSERT || UPDATE
//    ENDatabase *db = [ENDatabase defaultDatabase];
//    BOOL ret = [db open];
//    if (ret)
//    {
//        ENDataRow *row = [db compile:@"sql where place holders are like :column1, :column2);"];
//        if (row != nil)
//        {
//            [row setInteger:self.value1 forColumn:1];
//            [row setInteger:self.value2 forKey:@":column2"];
//            ret = [row done];
//            [row close];
//            // self.rowId = [db lastInsertRowId];
//        }
//        [db close];
//    }
//  4. TRANSACTION
//    ENDatabase *db = [ENDatabase defaultDatabase];
//    BOOL ret = [db open];
//    if (ret)
//    {
//        [db beginTransaction];
//        BOOL commit = YES;
//        // do db works, set commit to be NO when something goes wrong.
//        if (commit)
//            [db commit];
//        else
//            [db rollback];
//        [db close];
//    }
//
//  Created by enloyee on 11-11-13.
//  Email: enloyee@hotmail.com
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "/usr/include/sqlite3.h"

@class ENDataRow;

@interface ENDatabase : NSObject
{
    sqlite3 *_database;
    NSInteger _traceCount;
}

@property (retain, nonatomic) NSString *filePath;

+ (ENDatabase *)sharedDatabase;

- (BOOL)open;
- (void)close;

- (ENDataRow *)executeQuery:(NSString *)query;
- (BOOL)executeNonQuery:(NSString *)sql;
- (ENDataRow *)compile:(NSString *)sql;
- (NSInteger)lastInsertRowId;

- (void)beginTransaction;
- (void)commit;
- (void)rollback;

@end
