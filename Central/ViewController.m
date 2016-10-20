//
//  ViewController.m
//  CoreBluetoothCentral
//
//  Created by wubaozeng on 2016/10/19.
//  Copyright © 2016年 wubaozeng. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define kPeripheralName @"This is a demo for bluetooth" //外围设备名称
#define kServiceUUID @"Peripheral Service's UUID" //服务的UUID
#define kCharacteristicUUID @"Peripheral Characteristic's UUID" //特征的UUID

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic,strong)CBCentralManager *centralManager;
@property (nonatomic,strong)NSMutableArray *peripheralArray;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _peripheralArray = [NSMutableArray new];
    
    //初始化后，跳入-(void)centralManagerDidUpdateState:(CBCentralManager *)central
    //如果想重新扫描，重新初始化或者重置delegate target，然后stopScan。
    _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
}


#pragma mark - centralManagerDelegate

/**
 设备状态变更

 @param central 中心设备
 */
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if(central.state == CBManagerStatePoweredOn)
    {
        NSLog(@"设备开启成功，开始扫描设备");
        /*参数
         service UUIDs:根据服务扫描设备，为nil则全部
         CBCentralManagerScanOptionAllowDuplicatesKey:重复扫描
         */
        //建议另起线程处理扫描事务
        //扫描结果跳入-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
        [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    }
    else
    {
        NSLog(@"设备开启失败，或者蓝牙未打开");
    }
    
    
    
}

//RSSI:信号强度
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"发现设备：%@,%@",peripheral.name,advertisementData);
    
    if([advertisementData[CBAdvertisementDataLocalNameKey] isEqualToString:kPeripheralName])
    {
        
        [_centralManager stopScan];
        
        //持有设备
        //如果不持有，设备的delegate将无法被调用
        if(![self.peripheralArray containsObject:peripheral])
        {
            [self.peripheralArray addObject:peripheral];
        }

        //连接设备
        [_centralManager connectPeripheral:peripheral options:nil];
    }

}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //连接成功
    NSLog(@"连接外围设备成功：%@",peripheral.name);
    
    //开始扫描服务
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接外围设备失败：%@",error.localizedDescription);
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    //发现服务
    if(error)
    {
        NSLog(@"发现服务失败：%@",error.localizedDescription);
        return;
    }
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    
    for(CBService *service in peripheral.services)
    {

        NSLog(@"发现服务：%@",service.UUID);
        //扫描特征
        
        if([service.UUID isEqual:serviceUUID])
        {
            [peripheral discoverCharacteristics:nil forService:service];
        }
        
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //发现特征
    if(error)
    {
        NSLog(@"发现特征失败：%@",error.localizedDescription);
        return;
    }
    
    for(CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"发现特征：%@",characteristic.UUID);
        //读取
//        [peripheral readValueForCharacteristic:characteristic];
//        
//        if(characteristic.value)
//        {
//
//            [self writeLog:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
//        }
        
        
        //写入
        
//        if(characteristic.properties & CBCharacteristicPropertyWrite)
//        {
//            NSString *valueStr=@"write a new value";
//            NSData *value=[valueStr dataUsingEncoding:NSUTF8StringEncoding];
//            
//            [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//        }
        
        //订阅
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        
    }
    
    
}

//外围设备更新了数据
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"设备更新了特征");
}



@end
