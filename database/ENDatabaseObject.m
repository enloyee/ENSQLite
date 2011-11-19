//
//  ENDatabaseObject.m
//  Jacob's Menu
//
//  Created by enloyee on 11-11-14.
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import "ENDatabaseObject.h"
#import "ENDatabase.h"
#import "ENDataRow.h"

#define kENDataTypeInteger  0
#define kENDataTypeDouble   1
#define kENDataTypeBool     2
#define kENDataTypeString   3
#define kENDataTypeData     4
#define kENDataTypeObject   5
#define kENDataTypeNull     6

#define kENRowIdField       @"row_id"

#define kENDataTypeKey      @"type"
#define kENDataValueKey     @"value"
#define kENDataUpdatedKey   @"updated"

#define kENSelectStatementPattern   @"SELECT %@ FROM %@ WHERE %@ = %d;"
#define kENUpdateStatementPattern   @"UPDATE %@ SET %@ WHERE %@ = %d;"
#define kENInsertStatementPattern   @"INSERT INTO %@ (%@) VALUES (%@);"
#define kENDeleteStatementPattern   @"DELETE FROM %@ WHERE %@ = %d;"
#define kENCreateTableStatementPattern  @"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY, %@);"

@interface ENDatabaseObject()

@property (assign, nonatomic) NSInteger rowId;
@property (retain, nonatomic) NSString *rowIdField;
@property (retain, nonatomic) NSMutableDictionary *properties;

- (BOOL)_load:(NSString *)query useTransactions:(BOOL)useTransactions;
- (void)_init:(ENDataRow *)row;

- (NSUInteger)_type:(NSDictionary *)value;
- (id)_value:(NSDictionary *)value;
- (BOOL)_isUpdated:(NSDictionary *)value;

@end

@implementation ENDatabaseObject

@synthesize rowId = _rowId;
@synthesize rowIdField = _rowIdField;
@synthesize properties = _properties;

+ (NSString *)tableName
{
    return NSStringFromClass([self class]);
}

- (id)init
{
    if (self = [super init])
    {
        self.rowIdField = kENRowIdField;
        self.properties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)_init:(ENDataRow *)row
{
    for (id k in [self.properties allKeys]) {
        NSString *key = (NSString *)k;
        NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
        [dict setValue:[NSNumber numberWithBool:NO] forKey:kENDataUpdatedKey];
        NSNumber *type = (NSNumber *)[dict objectForKey:kENDataTypeKey];
        if ([row isNullForKey:key])
            [dict setValue:[NSNull null] forKey:key];
        else
        {
            switch ([type intValue]) {
                case kENDataTypeInteger:
                    [dict setValue:[NSNumber numberWithInteger:[row integerForKey:key]]
                            forKey:kENDataValueKey];
                    break;
                case kENDataTypeDouble:
                    [dict setValue:[NSNumber numberWithDouble:[row doubleForKey:key]]
                            forKey:kENDataValueKey];
                    break;
                case kENDataTypeBool:
                    [dict setValue:[NSNumber numberWithBool:[row boolForKey:key]]
                            forKey:kENDataValueKey];
                    break;
                case kENDataTypeString:
                    [dict setValue:[row stringForKey:key]
                            forKey:kENDataValueKey];
                    break;
                case kENDataTypeData:
                    [dict setValue:[row dataForKey:key]
                            forKey:kENDataValueKey];
                    break;
                case kENDataTypeNull:
                    [dict setNilValueForKey:kENDataValueKey];
                    break;
                default:
                    break;
            }
        }
    }
}

- (BOOL)_load:(NSString *)query useTransactions:(BOOL)useTransactions
{
    ENDatabase *db = [ENDatabase sharedDatabase];
    BOOL ret = [db open];
    if (ret)
    {
        if (useTransactions)
            [db beginTransaction];
        ENDataRow *row = [db executeQuery:query];
        if (row == nil || ![row next])
        {
            if (useTransactions)
                [db rollback];
            [db close];
            return NO;
        }
        [self _init:row];
        [row close];
        BOOL commit = [self postLoad];
        if (useTransactions)
        {
            if (commit)
                [db commit];
            else
                [db rollback];
        }
        [db close];
        return commit;
    }
    return NO;
}

- (BOOL)isSaved
{
    return self.rowId > 0;
}

- (NSUInteger)_type:(NSDictionary *)value
{
    return (NSUInteger)[(NSNumber *)[value objectForKey:kENDataTypeKey] intValue];
}

- (id)_value:(NSDictionary *)value
{
    return [value objectForKey:kENDataValueKey];
}

- (BOOL)_isUpdated:(NSDictionary *)value;
{
    return [(NSNumber *)[value objectForKey:kENDataUpdatedKey] boolValue];
}

- (BOOL)load:(NSInteger)rowIdValue
{
    return [self load:rowIdValue useTransactions:YES];
}

- (BOOL)load:(NSInteger)rowIdValue useTransactions:(BOOL)useTransactions
{
    return [self load:rowIdValue withRowIdField:nil useTransactions:useTransactions];
}

- (BOOL)load:(NSInteger)rowIdValue withRowIdField:(NSString *)rowIdField useTransactions:(BOOL)useTransactions
{
    NSString *field = nil;
    if (rowIdField == nil || [rowIdField length] == 0)
        field = self.rowIdField;
    else
        field = rowIdField;
    
    if (rowIdField < 0)
        return NO;
    
    self.rowId = rowIdValue;
    
    NSString *query = [NSString stringWithFormat:kENSelectStatementPattern,
                       [[self.properties allKeys] componentsJoinedByString:@", "],
                       NSStringFromClass([self class]),
                       field,
                       rowIdValue];
    
    if ([self _load:query useTransactions:useTransactions])
    {
        return YES;
    }
    self.rowId = 0;
    return NO;
}

- (BOOL)store
{
    return [self storeUseTransactions:YES];
}

- (BOOL)storeUseTransactions:(BOOL)useTransactions
{
    ENDatabase *db = [ENDatabase sharedDatabase];
    if ([db open])
    {
        BOOL update = [self isSaved];
        BOOL commit;
        
        if (useTransactions)
            [db beginTransaction];
        if (update)
            commit = [self preUpdate];
        else
            commit = [self preInsert];
        
        if (!commit)
        {
            if (useTransactions)
                [db rollback];
            [db close];
            return NO;
        }
        
        NSString *sql = nil;
        NSMutableArray *fields = nil;
        
        if (update)
        {
            NSMutableArray *assignments = [[NSMutableArray alloc] init];
            fields = [[NSMutableArray alloc] init];
            
            for (id k in [self.properties allKeys]) {
                NSString *key = (NSString *)k;
                NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
                if (![self _isUpdated:dict])
                    continue;
                
                [assignments addObject:[NSString stringWithFormat:@"%@ = :%@", key, key]];
                [fields addObject:key];
            }
            
            sql = [NSString stringWithFormat:kENUpdateStatementPattern,
                   NSStringFromClass([self class]),
                   [assignments componentsJoinedByString:@", "],
                   self.rowIdField,
                   self.rowId];
        }
        else
        {
            fields = [[NSMutableArray alloc] init];
            NSMutableArray *holders = [[NSMutableArray alloc] init];
            
            for (id k in [self.properties allKeys]) {
                NSString *key = (NSString *)k;
                
                [fields addObject:key];
                [holders addObject:[NSString stringWithFormat:@":%@", key]];
            }
            
            sql = [NSString stringWithFormat:kENInsertStatementPattern,
                   NSStringFromClass([self class]),
                   [fields componentsJoinedByString:@", "],
                   [holders componentsJoinedByString:@", "]];
        }
        
        ENDataRow *row = [db compile:sql];
        if (row != nil)
        {
            for (id k in fields) {
                NSString *key = (NSString *)k;
                NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
                
                switch ([self _type:dict]) {
                    case kENDataTypeInteger:
                        [row setInteger:[(NSNumber *)[self _value:dict] integerValue]
                                 forKey:[NSString stringWithFormat:@":%@", key]];
                        break;
                    case kENDataTypeDouble:
                        [row setDouble:[(NSNumber *)[self _value:dict] doubleValue]
                                forKey:[NSString stringWithFormat:@":%@", key]];
                        break;
                    case kENDataTypeBool:
                        [row setBool:[(NSNumber *)[self _value:dict] boolValue]
                    forKey:[NSString stringWithFormat:@":%@", key]];
                        break;
                    case kENDataTypeString:
                        [row setString:(NSString *)[self _value:dict]
                                forKey:[NSString stringWithFormat:@":%@", key]];
                        break;
                    case kENDataTypeData:
                        [row setData:(NSData *)[self _value:dict]
                              forKey:[NSString stringWithFormat:@":%@", key]];
                        break;
                    case kENDataTypeNull:
                        [row setNullForKey:[NSString stringWithFormat:@":%@", key]];
                        break;
                    default:
                        break;
                }
            }
            commit = [row done];
            [row close];
        }
        else
            commit = NO;
        
        if (commit)
        {
            if (update)
                [self postUpdate];
            else
            {
                self.rowId = [db lastInsertRowId];
                [self postInsert];
            }
        }
        
        if (useTransactions)
        {
            if (commit)
                [db commit];
            else
                [db rollback];
        }
        
        [db close];
        return commit;
    }
    return NO;
}

- (BOOL)remove
{
    return [self removeUseTransactions:YES];
}

- (BOOL)removeUseTransactions:(BOOL)useTransactions
{
    if (![self isSaved])
        return YES;
    
    ENDatabase *db = [ENDatabase sharedDatabase];
    
    if ([db open])
    {
        if (useTransactions)
            [db beginTransaction];
        
        BOOL commit = [self preDelete];
        
        if (commit)
        {
            NSString *sql = [NSString stringWithFormat:kENDeleteStatementPattern,
                             NSStringFromClass([self class]),
                             self.rowIdField,
                             self.rowId];
            
            commit = [db executeNonQuery:sql];
        }
        else
        {
            if (useTransactions)
                [db rollback];
            [db close];
            return NO;
        }
        
        commit = [self postDelete];
        
        if (commit)
            self.rowId = -1;
        
        if (useTransactions)
        {
            if (commit)
                [db commit];
            else
                [db rollback];
        }
        
        [db close];
        
        return commit;
    }
    return NO;
}

- (NSString *)tableCreatedSqlStatement
{
    if (self.rowIdField == nil)
        return nil;
    
    NSAssert(self.rowIdField != nil, @"Error: Row id field string is nil");
    
    NSMutableArray *attributes = [[NSMutableArray alloc] init];
    for (id k in [self.properties allKeys]) {
        NSString *key = (NSString *)k;
        NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
        
        switch ([self _type:dict]) {
            case kENDataTypeInteger:
                [attributes addObject:[NSString stringWithFormat:@"%@ INTEGER", key]];
                break;
            case kENDataTypeDouble:
                [attributes addObject:[NSString stringWithFormat:@"%@ DOUBLE", key]];
                break;
            case kENDataTypeBool:
                [attributes addObject:[NSString stringWithFormat:@"%@ INTEGER", key]];
                break;
            case kENDataTypeString:
                [attributes addObject:[NSString stringWithFormat:@"%@ TEXT", key]];
                break;
            case kENDataTypeData:
                [attributes addObject:[NSString stringWithFormat:@"%@ BLOB", key]];
                break;
            default:
                break;
        }
    }
    return [NSString stringWithFormat:kENCreateTableStatementPattern,
            NSStringFromClass([self class]),
            self.rowIdField,
            [attributes componentsJoinedByString:@", "]];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithInt:kENDataTypeInteger] forKey:kENDataTypeKey];
    [dict setObject:[NSNumber numberWithInteger:value] forKey:kENDataValueKey];
    [dict setObject:[NSNumber numberWithBool:YES] forKey:kENDataUpdatedKey];
    [self.properties setObject:dict forKey:key];
}

- (void)setDouble:(double)value forKey:(NSString *)key
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithInt:kENDataTypeDouble] forKey:kENDataTypeKey];
    [dict setObject:[NSNumber numberWithDouble:value] forKey:kENDataValueKey];
    [dict setObject:[NSNumber numberWithBool:YES] forKey:kENDataUpdatedKey];
    [self.properties setObject:dict forKey:key];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithInt:kENDataTypeBool] forKey:kENDataTypeKey];
    [dict setObject:[NSNumber numberWithBool:value] forKey:kENDataValueKey];
    [dict setObject:[NSNumber numberWithBool:YES] forKey:kENDataUpdatedKey];
    [self.properties setObject:dict forKey:key];
}

- (void)setString:(NSString *)value forKey:(NSString *)key
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithInt:kENDataTypeString] forKey:kENDataTypeKey];
    [dict setObject:(value == nil ? [NSNull null] : value) forKey:kENDataValueKey];
    [dict setObject:[NSNumber numberWithBool:YES] forKey:kENDataUpdatedKey];
    [self.properties setObject:dict forKey:key];
}

- (void)setData:(NSData *)value forKey:(NSString *)key
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithInt:kENDataTypeData] forKey:kENDataTypeKey];
    [dict setObject:(value == nil ? [NSNull null] : value) forKey:kENDataValueKey];
    [dict setObject:[NSNumber numberWithBool:YES] forKey:kENDataUpdatedKey];
    [self.properties setObject:dict forKey:key];
}

- (void)setNilValueForKey:(NSString *)key
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithInt:kENDataTypeNull] forKey:kENDataTypeKey];
    [dict setObject:[NSNull null] forKey:kENDataValueKey];
    [dict setObject:[NSNumber numberWithBool:YES] forKey:kENDataUpdatedKey];
    [self.properties setObject:dict forKey:key];
}

- (NSInteger)integerForKey:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
    return [(NSNumber *)[dict objectForKey:kENDataValueKey] integerValue];
}

- (double)doubleForKey:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
    return [(NSNumber *)[dict objectForKey:kENDataValueKey] doubleValue];
}

- (BOOL)boolForKey:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
    return [(NSNumber *)[dict objectForKey:kENDataValueKey] boolValue];
}

- (NSString *)stringForKey:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
    if ([[dict objectForKey:kENDataValueKey] isEqual:[NSNull null]])
        return nil;
    return (NSString *)[dict objectForKey:kENDataValueKey];
}

- (NSData *)dataForKey:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
    if ([[dict objectForKey:kENDataValueKey] isEqual:[NSNull null]])
        return nil;
    return (NSData *)[dict objectForKey:kENDataValueKey];
}

- (BOOL)isNilValueForKEY:(NSString *)key
{
    NSDictionary *dict = (NSDictionary *)[self.properties objectForKey:key];
    return [[dict objectForKey:kENDataValueKey] isEqual:[NSNull null]];
}

- (BOOL)postLoad
{
    return YES;
}

- (BOOL)preInsert
{
    return YES;
}

- (BOOL)postInsert
{
    return YES;
}

- (BOOL)preUpdate
{
    return YES;
}

- (BOOL)postUpdate
{
    return YES;
}

- (BOOL)preDelete
{
    return YES;
}

- (BOOL)postDelete
{
    return YES;
}

@end
