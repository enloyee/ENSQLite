//
//  ENConnection.m
//  SQLite
//
//  Created by enloyee on 11-11-16.
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import "ENConnection.h"
#import "ENDatabase.h"
#import "ENDataRow.h"

#define kENLoadOneManyConnectionPattern \
            @"SELECT right_row_id FROM %@_%@_connection WHERE left_row_id = %d;"
#define kENLoadManyManyConnectionPattern \
            @"SELECT left_row_id, right_row_id FROM %@;"
#define kENInsertConnectionPattern \
            @"INSERT INTO %@_%@_connection VALUES (%d, %d);"
#define kENDeleteConnectionsPattern \
            @"DELETE FROM %@_%@_connection WHERE left_row_id = %d;"
#define kENRowIdField       @"row_id"

#define kENLeftRowId(i)     (2*i)
#define kENRightRowId(i)    (2*i+1)

@interface ENConnection()

@property (retain, nonatomic) NSString *leftTableName;
@property (retain, nonatomic) NSString *rightTableName;

@end

@implementation ENConnection

@synthesize leftTableName = _leftTableName;
@synthesize rightTableName = _rightTableName;

- (id)initWithLeftTable:(NSString *)leftTableName andRightTable:(NSString *)rightTableName
{
    if (self = [super init])
    {
        self.leftTableName = leftTableName;
        self.rightTableName = rightTableName;
    }
    return self;
}

- (NSString *)tableCreateSqlStatement
{
    return [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@_connection (left_row_id INTEGER NOT NULL, right_row_id INTEGER NOT NULL);",
            self.leftTableName,
            self.rightTableName];
}

@end

/*
@interface ENOneConnection()

@property (assign, nonatomic) NSInteger lhs;

@end

@implementation ENOneConnection

@synthesize lhs = _lhs;

- (id)initWithLeftTable:(NSString *)leftTableName leftRowId:(NSInteger)lhs andRightTableName:(NSString *)rightTableName
{
    if (self = [super initWithLeftTable:leftTableName andRightTable:rightTableName])
    {
        self.lhs = lhs;
    }
    return self;
}

@end

@interface ENOneOneConnection()

@property (assign, nonatomic) NSInteger rhs;

@end

@implementation ENOneOneConnection

@synthesize rhs = _rhs;

- (id)initWithLeftTable:(NSString *)leftTableName leftRowId:(NSInteger)lhs rightTableName:(NSString *)rightTableName andRightRowId:(NSInteger)rhs
{
    if (self = [super initWithLeftTable:leftTableName leftRowId:lhs andRightTableName:rightTableName])
    {
        self.rhs = rhs;
    }
    return self;
}

@end
*/

@interface ENOneManyConnection()

@property (assign, nonatomic) NSInteger lhs;
@property (retain, nonatomic) NSMutableArray *rhses;
@property (assign, nonatomic) int currentIndex;

@end

@implementation ENOneManyConnection

@synthesize lhs = _lhs;
@synthesize rhses = _rhses;
@synthesize currentIndex = _currentIndex;

- (id)initWithLeftTable:(NSString *)leftTableName
              leftRowId:(NSInteger)lhs
          andRightTable:(NSString *)rightTableName
{
    if (self = [super initWithLeftTable:leftTableName andRightTable:rightTableName])
    {
        self.rhses = [[NSMutableArray alloc] init];
        self.currentIndex = 0;
        self.lhs = lhs;
    }
    return self;
}

- (BOOL)loadConnections:(BOOL)useTransactions
{
    ENDatabase *db = [ENDatabase sharedDatabase];
    BOOL commit = NO;
    if ([db open])
    {
        if (useTransactions)
            [db beginTransaction];
        NSString *sql = [NSString stringWithFormat:kENLoadOneManyConnectionPattern,
                         self.leftTableName, self.rightTableName, self.lhs];
        ENDataRow *row = [db executeQuery:sql];
        if (row != nil)
        {
            while ([row next]) {
                [self addRightHandSide:[row integerForKey:kENRowIdField]];
            }
            [row close];
            commit = YES;
        }
        if (useTransactions)
        {
            if (commit)
                [db commit];
            else
                [db rollback];
        }
        [db close];
    }
    
    return commit;
}

- (BOOL)storeConnections:(BOOL)useTransactions
{
    ENDatabase *db = [ENDatabase sharedDatabase];
    BOOL commit = NO;
    if ([db open])
    {
        if (useTransactions)
            [db beginTransaction];
        for (id r in self.rhses) {
            NSInteger rhs = [(NSNumber *)r integerValue];
            NSString *sql = [NSString stringWithFormat:kENInsertConnectionPattern,
                             self.leftTableName,
                             self.rightTableName,
                             self.lhs,
                             rhs];
            commit = [db executeNonQuery:sql];
            if (!commit)
                break;
        }
        if (useTransactions)
        {
            if (commit)
                [db commit];
            else
                [db rollback];
        }
        [db close];
    }
    
    return commit;
}

- (BOOL)deleteConnections
{
    ENDatabase *db = [ENDatabase sharedDatabase];
    BOOL commit = NO;
    if ([db open])
    {
        NSString *query = [NSString stringWithFormat:kENDeleteConnectionsPattern, self.leftTableName, self.rightTableName, self.lhs];
        commit = [db executeNonQuery:query];
        [db close];
    }
    return commit;
}

- (void)addRightHandSide:(NSInteger)rhsId
{
    [self.rhses addObject:[NSNumber numberWithInteger:rhsId]];
}

- (void)removeRightHandSide:(NSInteger)rhsId
{
    long index = -1;
    for (NSUInteger i = 0; i < [self.rhses count]; i++)
    {
        NSNumber *currId = (NSNumber *)[self.rhses objectAtIndex:i];
        if (rhsId == [currId integerValue])
            index = (long)i;
    }
    if (index != -1)
        [self.rhses removeObjectAtIndex:(NSUInteger)index];
}

- (void)setConnections:(NSArray *)rhses
{
    [self.rhses removeAllObjects];
    for (id r in rhses) {
        [self.rhses addObject:[(NSNumber *)r copy]];
    }
}

- (NSInteger)currentRightHandSide
{
    if (self.currentIndex < 0 ||
        self.currentIndex >= [self.rhses count])
        return 0;
    return [(NSNumber *)[self.rhses objectAtIndex:self.currentIndex] integerValue];
}

- (BOOL)moveToFirstRightHandSide
{
    if ([self.rhses count] == 0)
        return NO;
    self.currentIndex = 0;
    return YES;
}

- (BOOL)hasNext
{
    if ([self.rhses count] == 0)
        return NO;
    if (self.currentIndex == [self.rhses count] - 1)
        return NO;
    return YES;
}

@end

/*
@interface ENManyManyConnection()

@property (retain, nonatomic) NSMutableArray *connections;

@end

@implementation ENManyManyConnection

@synthesize connections = _connections;

- (id)initWithLeftTable:(NSString *)leftTableName andRightTable:(NSString *)rightTableName
{
    if (self = [super initWithLeftTable:leftTableName andRightTable:rightTableName])
        self.connections = [[NSMutableArray alloc] init];
    return self;
}

- (BOOL)loadConnectionsuseTransactions:(BOOL)useTransactions
{
    [self.connections removeAllObjects];
    ENDatabase *db = [ENDatabase sharedDatabase];
    BOOL commit = NO;
    if ([db open])
    {
        if (useTransactions)
            [db beginTransaction];
        NSString *tableName = [NSString stringWithFormat:@"%@_%@_connection",
                               self.leftTableName, self.rightTableName];
        NSString *query = [NSString stringWithFormat:kENLoadManyManyConnectionPattern, tableName];
        ENDataRow *row = [db executeQuery:query];
        if (row != nil)
        {
            while ([row next]) {
                [self.connections addObject:[NSNumber numberWithInteger:[row integerForColumn:0]]];
                [self.connections addObject:[NSNumber numberWithInteger:[row integerForColumn:1]]];
            }
            [row close];
            commit = YES;
        }
        if (useTransactions)
        {
            if (commit)
                [db commit];
            else
                [db rollback];
        }
        [db close];
    }
    return commit;
}

- (BOOL)loadConnectionsWithLeftHandSides:(NSArray *)leftHandSides useTransactions:(BOOL)useTransactions
{
    [self.connections removeAllObjects];
    ENDatabase *db = [ENDatabase sharedDatabase];
    BOOL commit = NO;
    if ([db open])
    {
        commit = YES;
        if (useTransactions)
            [db beginTransaction];
        NSString *tableName = [NSString stringWithFormat:@"%@_%@_connection",
                               self.leftTableName, self.rightTableName];
        for (id lk in leftHandSides) {
            NSNumber *lKey = (NSNumber *)lk;
            NSString *term = [tableName stringByAppendingFormat:@" WHERE left_row_id = %@;", lKey];
            NSString *query = [NSString stringWithFormat:kENLoadManyManyConnectionPattern, term];
            ENDataRow *row = [db executeQuery:query];
            if (row != nil)
            {
                while ([row next])
                {
                    [self.connections addObject:lKey];
                    [self.connections addObject:[NSNumber numberWithInteger:[row integerForKey:0]]];
                }
                [row close];
            }
            else
            {
                commit = NO;
                break;
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
    }
    return commit;
}

- (BOOL)storeConnections:(BOOL)useTransactions
{
    return YES;
}

- (void)addConnection:(NSInteger)lhs rightHandSide:(NSInteger)rhs
{
    if ([self existConnection:lhs rightHandSide:rhs] != -1)
        return;
    [self.connections addObject:[NSNumber numberWithInteger:lhs]];
    [self.connections addObject:[NSNumber numberWithInteger:rhs]];
}

- (BOOL)removeConnection:(NSInteger)lhs rightHandSide:(NSInteger)rhs
{
    int lIndex = [self existConnection:lhs rightHandSide:rhs];
    if (lIndex == -1)
        return NO;
    NSRange range = {lIndex, 2};
    [self.connections removeObjectsInRange:range];
    return YES;
}

- (int)existConnection:(NSInteger)lhs rightHandSide:(NSInteger)rhs
{
    for (int i = 0; i < [self.connections count] / 2; i++)
    {
        if ([(NSNumber *)[self.connections objectAtIndex:kENLeftRowId(i)] integerValue] == lhs &&
            [(NSNumber *)[self.connections objectAtIndex:kENRightRowId(i)] integerValue] == rhs)
            return kENLeftRowId(i);
    }
    return -1;
}

- (NSArray *)connectionForLeftHandSide:(NSInteger)lhs
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.connections count] / 2; i++)
    {
        if ([(NSNumber *)[self.connections objectAtIndex:kENLeftRowId(i)] integerValue] == lhs)
            [array addObject:[self.connections objectAtIndex:kENRightRowId(i)]];
    }
    return array;
}

- (BOOL)removeConnectionsByLeftHandSide:(NSInteger)lhs useTransactions:(BOOL)useTransactions
{
    ENDatabase *db = [ENDatabase sharedDatabase];
    BOOL ret = YES;
    if (!useTransactions)
        ret = [db open];
    if (ret)
    {
        NSString *tableName = [NSString stringWithFormat:@"%@_%@_connection", self.leftTableName,
                               self.rightTableName];
        NSString *query = [NSString stringWithFormat:kENDeleteConnectionsPattern, tableName, self.leftTableName, lhs];
        ret = [db executeNonQuery:query];
        if (!useTransactions)
            [db close];
    }
    return ret;
}

- (BOOL)addConnectionsForLeftHandSide:(NSInteger)lhs rightHandSides:(NSArray *)rhses useTransactions:(BOOL)useTransactions
{
    ENDatabase *db = [ENDatabase sharedDatabase];
    BOOL ret = YES;
    BOOL commit = YES;
    if (!useTransactions)
        ret = [db open];
    if (ret)
    {
        if (!useTransactions)
            [db beginTransaction];
        for (id r in rhses) {
            NSInteger rhs = [(NSNumber *)r integerValue];
            NSString *sql = [NSString stringWithFormat:kENInsertConnectionPattern, self.leftTableName, self.rightTableName, lhs, rhs];
            commit = [db executeNonQuery:sql];
        }
        if (!useTransactions)
        {
            if (commit)
                [db commit];
            else
                [db rollback];
            [db close];
        }
    }
    return ret && commit;
}

- (BOOL)resetConnectionsForLeftHandSide:(NSInteger)lhs rightHandSides:(NSArray *)rhses useTransactions:(BOOL)useTransactions
{
    return [self removeConnectionsByLeftHandSide:lhs useTransactions:useTransactions] && [self addConnectionsForLeftHandSide:lhs rightHandSides:rhses useTransactions:useTransactions];
}

@end
*/
