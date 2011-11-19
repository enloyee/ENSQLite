//
//  ENDatabaseObject.h
//  Jacob's Menu
//
//  Created by enloyee on 11-11-14.
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ENDatabase;

@interface ENDatabaseObject : NSObject

@property (readonly, assign, nonatomic) NSInteger rowId;
@property (readonly, retain, nonatomic) NSString *rowIdField;

+ (NSString *)tableName;

- (BOOL)isSaved;
- (BOOL)load:(NSInteger)rowIdValue;
- (BOOL)load:(NSInteger)rowIdValue useTransactions:(BOOL)useTransactions;
- (BOOL)load:(NSInteger)rowIdValue withRowIdField:(NSString *)rowIdField useTransactions:(BOOL)useTransactions;
- (BOOL)store;
- (BOOL)storeUseTransactions:(BOOL)useTransactions;
- (BOOL)remove;
- (BOOL)removeUseTransactions:(BOOL)useTransactions;

- (NSString *)tableCreatedSqlStatement;

- (void)setInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setDouble:(double)value forKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (void)setString:(NSString *)value forKey:(NSString *)key;
- (void)setData:(NSData *)value forKey:(NSString *)key;
- (void)setNilValueForKey:(NSString *)key;

- (NSInteger)integerForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;
- (BOOL)isNilValueForKEY:(NSString *)key;

- (BOOL)postLoad;
- (BOOL)preInsert;
- (BOOL)postInsert;
- (BOOL)preUpdate;
- (BOOL)postUpdate;
- (BOOL)preDelete;
- (BOOL)postDelete;

@end
