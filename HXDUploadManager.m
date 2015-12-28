//
//  HXDUploadManager.m
//  upload
//
//  Created by huxuedong on 15/11/2.
//  Copyright © 2015年 huxuedong. All rights reserved.
//

#import "HXDUploadManager.h"

#define kBoundary @"huxuedong"

@implementation HXDUploadManager

+ (instancetype)sharedManager {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSURLResponse *)getFileTypeWithFilePath:(NSString *)filePath {
    //发送一个file请求，访问本地文件
    NSString *urlString = [NSString stringWithFormat:@"file://%@",filePath];
    NSURL *url = [NSURL URLWithString:urlString];
    //创建请求（本地请求）
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //发送本地请求
    //定义了一块空地址，利用这块空地址，来接收响应头和响应行信息
    NSURLResponse *response = nil;
    //同步方法：返回值就是实体内容
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
    return response;
}

- (NSData *)getHttpBodyWithFilePath:(NSString *)filePath fileKey:(NSString *)fileKey fileName:(NSString *)fileName {
    //请求体内容
    NSMutableData *data = [NSMutableData data];
    //文件的上边界
    NSMutableString *headerStrM = [NSMutableString stringWithFormat:@"--%@\r\n",kBoundary];
    //获得文件类型和建议的文件名称
    NSURLResponse *response = [self getFileTypeWithFilePath:filePath];
    NSString *fileType = response.MIMEType;
    if (!fileName) {
        fileName = response.suggestedFilename;
    }
    [headerStrM appendFormat:@"Content-Disposition: form-data; name=%@; filename=%@\r\n",fileKey,fileName];
    //Content-Type：application/json，告诉服务器上传文件的类型
    [headerStrM appendFormat:@"Content-Type: %@\r\n\r\n",fileType];
    //将上边界拼接到请求体中
    [data appendData:[headerStrM dataUsingEncoding:NSUTF8StringEncoding]];
    //文件内容：直接根据一个文件路径，加载文件的二进制数据
    [data appendData:[NSData dataWithContentsOfFile:filePath]];
    //文件的下边界
    NSMutableString *footerStrM = [NSMutableString stringWithFormat:@"\r\n--%@--\r\n",kBoundary];
    //将下边界拼接到请求体中
    [data appendData:[footerStrM dataUsingEncoding:NSUTF8StringEncoding]];
    return data;
}

- (void)postUploadFileWithUrlString:(NSString *)urlString FilePath:(NSString *)filePath fileKey:(NSString *)fileKey fileName:(NSString *)fileName {
    [self postUploadFileWithUrlString:urlString FilePath:filePath fileKey:fileKey fileName:fileName completionHandler:nil];
}

- (void)postUploadFileWithUrlString:(NSString *)urlString FilePath:(NSString *)filePath fileKey:(NSString *)fileKey fileName:(NSString *)fileName completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //设置请求方法
    request.HTTPMethod = @"POST";
    //对于文件上传，需要设置请求头告诉服务器本次上传的是文件信息
    NSString *type = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",kBoundary];
    [request setValue:type forHTTPHeaderField:@"Content-Type"];
    //设置请求体
    request.HTTPBody = [self getHttpBodyWithFilePath:filePath fileKey:fileKey fileName:fileName];
    //发送网络请求
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //网络完成之后的回调
        dispatch_async(dispatch_get_main_queue(), ^{
            //执行Block
            if (completionHandler) {
                completionHandler(data,response,error);
            }
        });
    }] resume];
}

- (void)postUploadFileWithUrlString:(NSString *)urlString FilePath:(NSString *)filePath fileKey:(NSString *)fileKey fileName:(NSString *)fileName successCompletionHandler:(successBlock)success failCompletionHandler:(failBlock)fail {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //设置请求方法
    request.HTTPMethod = @"POST";
    //对于文件上传，需要设置请求头告诉服务器本次上传的是文件信息
    NSString *type = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",kBoundary];
    [request setValue:type forHTTPHeaderField:@"Content-Type"];
    //设置请求体
    request.HTTPBody = [self getHttpBodyWithFilePath:filePath fileKey:fileKey fileName:fileName];
    //发送网络请求
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //网络完成之后的回调
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && data) {
                //没有网络连接错误，就是成功
                //默认会解析服务器返回的JSON数据
                id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                if (success) {
                    success(obj,response);
                }
            } else {
                if (fail) {
                    fail(error);
                }
            }
        });
    }] resume];
}

- (NSData *)getHttpBodyWithFileKey:(NSString *)fileKey fileDict:(NSDictionary *)fileDict parameter:(NSDictionary *)parameter {
    //data请求体
    NSMutableData *data = [NSMutableData data];
    //上传文件的信息在fileDict中
    //遍历文件字典，取出文件，拼接格式
    [fileDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //fileName：文件在服务器中保存的名称
        //filePath：文件路径
        NSString *fileName = key;
        NSString *filePath = obj;
        //得到文件类型
        NSURLResponse *response = [[HXDUploadManager sharedManager] getFileTypeWithFilePath:filePath];
        NSString *fileType = response.MIMEType;
        //上传文件的上边界
        NSMutableString *headerStrM = [NSMutableString stringWithFormat:@"\r\n--%@\r\n",kBoundary];
        [headerStrM appendFormat:@"Content-Disposition: form-data; name=%@; filename=%@\r\n",fileKey,fileName];
        [headerStrM appendFormat:@"Content-Type: %@\r\n\r\n",fileType];
        NSData *headerData = [headerStrM dataUsingEncoding:NSUTF8StringEncoding     ];
        [data appendData:headerData];
        //文件内容
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        [data appendData:fileData];
    }];
    //普通文本信息参数
    //遍历文本信息字典，取出每一条数据做数据拼接
    [parameter enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //textKey：服务器接收文本信息的key值
        //text：文本信息
        NSString *textKey = key;
        NSString *text = obj;
        //非文件信息，字符串信息的上边界
        NSMutableString *strM = [NSMutableString stringWithFormat:@"\r\n--%@\r\n",kBoundary];
        [strM appendFormat:@"Content-Disposition: form-data; name=%@\r\n\r\n",textKey];
        NSData *headerData = [strM dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:headerData];
        //文本信息内容
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:textData];
    }];
    //整个上传文件的下边界
    NSMutableString *footerStrM = [NSMutableString stringWithFormat:@"\r\n--%@--",kBoundary];
    NSData *footerData = [footerStrM dataUsingEncoding:NSUTF8StringEncoding];
    [data appendData:footerData];
    return data;
}

- (void)postUploadFileWithUrlString:(NSString *)urlString FileKey:(NSString *)fileKey fileDict:(NSDictionary *)fileDict parameter:(NSDictionary *)parameter {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //设置请求方法
    request.HTTPMethod = @"POST";
    //对于文件上传，需要设置请求头告诉服务器本次上传的是文件信息
    NSString *type = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",kBoundary];
    [request setValue:type forHTTPHeaderField:@"Content-Type"];
    //设置请求体
    request.HTTPBody = [self getHttpBodyWithFileKey:fileKey fileDict:fileDict parameter:parameter];
    //发送网络请求
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //网络完成之后的回调
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    }] resume];
}

- (void)postUploadFileWithUrlString:(NSString *)urlString FileKey:(NSString *)fileKey fileDict:(NSDictionary *)fileDict parameter:(NSDictionary *)parameter completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //设置请求方法
    request.HTTPMethod = @"POST";
    //对于文件上传，需要设置请求头告诉服务器本次上传的是文件信息
    NSString *type = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",kBoundary];
    [request setValue:type forHTTPHeaderField:@"Content-Type"];
    //设置请求体
    request.HTTPBody = [self getHttpBodyWithFileKey:fileKey fileDict:fileDict parameter:parameter];
    //发送网络请求
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //网络完成之后的回调
        dispatch_async(dispatch_get_main_queue(), ^{
            //执行Block
            if (completionHandler) {
                completionHandler(data,response,error);
            }
        });
    }] resume];
}

- (void)postUploadFileWithUrlString:(NSString *)urlString FileKey:(NSString *)fileKey fileDict:(NSDictionary *)fileDict parameter:(NSDictionary *)parameter successCompletionHandler:(successBlock)success failCompletionHandler:(failBlock)fail {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //设置请求方法
    request.HTTPMethod = @"POST";
    //对于文件上传，需要设置请求头告诉服务器本次上传的是文件信息
    NSString *type = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",kBoundary];
    [request setValue:type forHTTPHeaderField:@"Content-Type"];
    //设置请求体
    request.HTTPBody = [self getHttpBodyWithFileKey:fileKey fileDict:fileDict parameter:parameter];
    //发送网络请求
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //网络完成之后的回调
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && data) {
                //没有网络连接错误，就是成功
                //默认会解析服务器返回的JSON数据
                id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                if (success) {
                    success(obj,response);
                }
            } else {
                if (fail) {
                    fail(error);
                }
            }
        });
    }] resume];
}

@end
