//
//  ViewController.m
//  CoreBluetoothPeripheral
//
//  Created by wubaozeng on 2016/10/19.
//  Copyright © 2016年 wubaozeng. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define kPeripheralName @"This is a demo for bluetooth" //外围设备名称
#define kServiceUUID @"Peripheral Service's UUID" //服务的UUID
#define kCharacteristicUUID @"Peripheral Characteristic's UUID" //特征的UUID

@interface ViewController ()<CBPeripheralManagerDelegate>

@property (nonatomic,strong)CBPeripheralManager *peripheralManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化后会跳入-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
    //根据CBManagerState判断下一步操作
    _peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}



-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if(peripheral.state == CBManagerStatePoweredOn)
    {
        NSLog(@"设备开启成功，开始添加服务和特征");
        
        [self setup];
    }
    else
    {
        NSLog(@"开启失败，或者蓝牙没打开");
    }
}

//初始化服务，特征
-(void)setup
{
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    CBUUID *serviceUUID= [CBUUID UUIDWithString:kServiceUUID];
    
    NSString *valueStr=@"这是特征value";
    NSData *value=[valueStr dataUsingEncoding:NSUTF8StringEncoding];
    
    //创建特征
    /** 参数
     * uuid:特征标识
     * properties:特征的属性，例如：可通知、可写、可读等
     * value:特征值
     * permissions:特征的权限
     */
    
    //可读写特征
    //notice:如果需要write,需持有value,或者为nil
//    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc]initWithType:characteristicUUID properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsWriteable | CBAttributePermissionsReadable];
    
    //通知特征
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc]initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:value permissions:CBAttributePermissionsReadable];
    
    CBMutableService *service = [[CBMutableService alloc]initWithType:serviceUUID primary:YES];
    [service setCharacteristics:@[characteristic]];
    
    
    [_peripheralManager addService:service];
    
    
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if(error)
    {
        NSLog(@"添加服务失败：%@",error.localizedDescription);
        return;
    }
    
    NSLog(@"添加服务成功,并尝试开启广播");
    
    //参数可作为协议一部分，用于判断是否连接此设备
    [_peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey:kPeripheralName}];
    
}

-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if(error)
    {
        NSLog(@"开启广播失败：%@",error.localizedDescription);
        return;
    }
    
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"收到读取请求");
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        [request setValue:data];
        //对请求作出成功响应
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [peripheral respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    NSLog(@"收到写入请求");
    //判断是否有写数据的权限
    CBATTRequest *request = requests[0];

    
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [peripheral respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"收到订阅通知");
}
@end
