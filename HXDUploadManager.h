//
//  HXDUploadManager.h
//  upload
//
//  Created by huxuedong on 15/11/2.
//  Copyright © 2015年 huxuedong. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^successBlock)(id responseObject, NSURLResponse *response);
typedef void(^failBlock)(NSError *error);

@interface HXDUploadManager : NSObject

/*
    获取单例对象
*/
+ (instancetype)sharedManager;


/*
    获取文件信息(文件类型/文件名称)
    filePath:文件路径
*/
- (NSURLResponse *)getFileTypeWithFilePath:(NSString *)filePath;


/*
    单文件上传：采用GET请求
    filePath：文件路径
    fileKey：服务器接收文件参数的key值
    fileName：文件在服务器保存的名称，如果这个值为nil，会使用建议的名称suggestedFilename
    返回值：封装好的请求体数据
*/
- (NSData *)getHttpBodyWithFilePath:(NSString *)filePath fileKey:(NSString *)fileKey fileName:(NSString *)fileName;


/*
    单文件上传：采用POST请求
    urlString：上传文件的接口
    filePath：文件路径
    fileKey：服务器接收文件参数的key值
    fileName：文件在服务器保存的名称，如果这个值为nil，会使用建议的名称suggestedFilename
*/
- (void)postUploadFileWithUrlString:(NSString *)urlString FilePath:(NSString *)filePath fileKey:(NSString *)fileKey fileName:(NSString *)fileName;


/*
    单文件上传的封装：采用POST请求
    urlString：上传文件的接口
    filePath：文件路径
    fileKey：服务器接收文件参数的key值
    fileName：文件在服务器保存的名称，如果这个值为nil，会使用建议的名称suggestedFilename
    completionHandler：网络请求完成之后的回调，直接获得系统的Block
    异步的网络上传，在主线程执行Block回调
    内部是对NSUrlSession的封装
*/
- (void)postUploadFileWithUrlString:(NSString *)urlString FilePath:(NSString *)filePath fileKey:(NSString *)fileKey fileName:(NSString *)fileName completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;


/*
    单文件上传的封装：采用POST请求
    urlString：上传文件的接口
    filePath：文件路径
    fileKey：服务器接收文件参数的key值
    fileName：文件在服务器保存的名称，如果这个值为nil，会使用建议的名称suggestedFilename
    success：网络请求成功之后的回调
    fail：网络请求失败的回调
*/
- (void)postUploadFileWithUrlString:(NSString *)urlString FilePath:(NSString *)filePath fileKey:(NSString *)fileKey fileName:(NSString *)fileName successCompletionHandler:(successBlock)success failCompletionHandler:(failBlock)fail;


/*
    多文件和文本信息上传，GET请求
    fileKey：服务器接收文件参数的key值
    fileDict：文件字典，key（文件在服务器中保存的名称），value（文件地址）
    paramatter：文本信息字典，key（服务器接收文本信息的key值），value（文本信息）
    返回值：拼接好的请求体数据
*/
- (NSData *)getHttpBodyWithFileKey:(NSString *)fileKey fileDict:(NSDictionary *)fileDict parameter:(NSDictionary *)parameter;


/*
    多文件和文本信息上传，POST请求
    fileKey：服务器接收文件参数的key值
    fileDict：文件字典，key（文件在服务器中保存的名称），value（文件地址）
    paramatter:文本信息字典，key（服务器接收文本信息的key值），value（文本信息）
*/
- (void)postUploadFileWithUrlString:(NSString *)urlString FileKey:(NSString *)fileKey fileDict:(NSDictionary *)fileDict parameter:(NSDictionary *)parameter;


/*
    多文件上传的封装：采用POST请求
    urlString：上传文件的接口
    filePath：文件路径
    fileKey：服务器接收文件参数的key值
    fileName：文件在服务器保存的名称，如果这个值为nil，会使用建议的名称suggestedFilename
    completionHandler：网络请求完成之后的回调，直接获得系统的Block
    异步的网络上传，在主线程执行Block回调
    内部是对NSUrlSession的封装
*/
- (void)postUploadFileWithUrlString:(NSString *)urlString FileKey:(NSString *)fileKey fileDict:(NSDictionary *)fileDict parameter:(NSDictionary *)parameter completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;


/*
    多文件上传的封装：采用POST请求
    urlString：上传文件的接口
    filePath：文件路径
    fileKey：服务器接收文件参数的key值
    fileName：文件在服务器保存的名称，如果这个值为nil，会使用建议的名称suggestedFilename
    success：网络请求成功之后的回调
    fail：网络请求失败的回调
*/
- (void)postUploadFileWithUrlString:(NSString *)urlString FileKey:(NSString *)fileKey fileDict:(NSDictionary *)fileDict parameter:(NSDictionary *)parameter successCompletionHandler:(successBlock)success failCompletionHandler:(failBlock)fail;

@end
