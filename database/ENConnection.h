//
//  ENConnection.h
//  SQLite
//
//  Created by enloyee on 11-11-16.
//  Copyright (c) 2011年 enloyee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ENConnection : NSObject
{
    NSString *_leftTableName;
    NSString *_rightTableName;
}

@property (readonly, retain, nonatomic) NSString *leftTableName;
@property (readonly, retain, nonatomic) NSString *rightTableName;

- (id)initWithLeftTable:(NSString *)leftTableName andRightTable:(NSString *)rightTableName;
- (NSString *)tableCreateSqlStatement;

@end

/*

@interface ENOneConnection : ENConnection
{
    NSInteger _lhs;
}

@property (readonly, assign, nonatomic) NSInteger lhs;

- (id)initWithLeftTable:(NSString *)leftTableName leftRowId:(NSInteger)lhs andRightTableName:(NSString *)rightTableName;

@end

@interface ENOneOneConnection : ENOneConnection
{
    NSInteger _rhs;
}

@property (readonly, assign, nonatomic) NSInteger rhs;

- (id)initWithLeftTable:(NSString *)leftTableName leftRowId:(NSInteger)lhs rightTableName:(NSString *)rightTableName andRightRowId:(NSInteger)rhs;

- (BOOL)loadConnection:(BOOL)useTransactions;

@end

*/

@interface ENOneManyConnection : ENConnection // ENOneConnection
{
    NSInteger _lhs;
    NSMutableArray *_rhses;
    int _currentIndex;
}

@property (readonly, assign, nonatomic) NSInteger lhs;
@property (readonly, assign, nonatomic) NSInteger currentRightHandSide;

- (id)initWithLeftTable:(NSString *)leftTableName
              leftRowId:(NSInteger)lhs
          andRightTable:(NSString *)rightTableName;
- (BOOL)loadConnections:(BOOL)useTransactions;
- (BOOL)storeConnections:(BOOL)useTransactions;
- (BOOL)deleteConnections;
- (void)addRightHandSide:(NSInteger)rhsId;
- (void)removeRightHandSide:(NSInteger)rhsId;
- (void)setConnections:(NSArray *)rhses;
- (BOOL)moveToFirstRightHandSide;
- (BOOL)hasNext;

@end

/*
@interface ENManyManyConnection : ENConnection
{
    NSMutableArray *_connections;
}

- (BOOL)loadConnectionsuseTransactions:(BOOL)useTransactions;
- (BOOL)loadConnectionsWithLeftHandSides:(NSArray *)leftHandSides useTransactions:(BOOL)useTransactions;
- (BOOL)storeConnections:(BOOL)useTransactions;
- (void)addConnection:(NSInteger)lhs rightHandSide:(NSInteger)rhs;
- (BOOL)removeConnection:(NSInteger)lhs rightHandSide:(NSInteger)rhs;
- (int)existConnection:(NSInteger)lhs rightHandSide:(NSInteger)rhs;
- (NSArray *)connectionForLeftHandSide:(NSInteger)lhs;
- (BOOL)removeConnectionsByLeftHandSide:(NSInteger)lhs useTransactions:(BOOL)useTransactions;
- (BOOL)addConnectionsForLeftHandSide:(NSInteger)lhs rightHandSides:(NSArray *)rhses useTransactions:(BOOL)useTransactions;
- (BOOL)resetConnectionsForLeftHandSide:(NSInteger)lhs rightHandSides:(NSArray *)rhses useTransactions:(BOOL)useTransactions;

@end
*/