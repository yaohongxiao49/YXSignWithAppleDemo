//
//  BaseViewController.m
//  YXCollectionTest
//
//  Created by Believer Just on 2019/7/5.
//  Copyright © 2019 August. All rights reserved.
//
// TODO 关于验证的这一步，需要传递授权码给自己的服务端，自己的服务端调用苹果API去校验授权码Generate and validate tokens。如果验证成功，可以根据userIdentifier判断账号是否已存在，若存在，则返回自己账号系统的登录态，若不存在，则创建一个新的账号，并返回对应的登录状态给App

#import "BaseViewController.h"
#import "YXHomePageVC.h"
#import "NormalCollectionViewController.h"
#import <AuthenticationServices/AuthenticationServices.h>

API_AVAILABLE(ios(13.0))
@interface BaseViewController () <UITableViewDataSource, UITableViewDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@property (nonatomic, strong) NSMutableArray *dataSourceArr;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ASAuthorizationAppleIDButton *appleBtn;
@property (nonatomic, copy) NSString *userId;

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _dataSourceArr = [[NSMutableArray alloc] initWithObjects:@"普通collection", @"瀑布流collection", nil];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 64) style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    if (@available(iOS 13.0, *)) {
        _appleBtn = [ASAuthorizationAppleIDButton buttonWithType:ASAuthorizationAppleIDButtonTypeSignIn style:ASAuthorizationAppleIDButtonStyleBlack];
    }
    else {
        // Fallback on earlier versions
    }
    _appleBtn.frame = CGRectMake(0, 0, 100, 40);
    _appleBtn.center= self.view.center;
    [_appleBtn addTarget:self action:@selector(progressAppleBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_appleBtn];
}

#pragma mark - progress
- (void)progressAppleBtn {
    
    if (@available(iOS 13.0, *)) {
        //基于用户的Apple ID授权用户，生成用户授权请求的一种机制
        ASAuthorizationAppleIDProvider *appleIDProvider = [ASAuthorizationAppleIDProvider new];
        if (_userId.length != 0) {
            //快速登录
            [appleIDProvider getCredentialStateForUserID:_userId completion:^(ASAuthorizationAppleIDProviderCredentialState credentialState, NSError * _Nullable error) {
                
            }];
        }
        else {
            //授权请求AppleID
            ASAuthorizationAppleIDRequest *request = appleIDProvider.createRequest;
            [request setRequestedScopes:@[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail]];
            //由ASAuthorizationAppleIDProvider创建的授权请求 管理授权请求的控制器
            ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
            //设置授权控制器通知授权请求的成功与失败的代理
            controller.delegate = self;
            //设置提供 展示上下文的代理，在这个上下文中 系统可以展示授权界面给用户
            controller.presentationContextProvider = self;
            //在控制器初始化期间启动授权流
            [controller performRequests];
        }
    }
    else {
        // Fallback on earlier versions
    }
}

#pragma mark - <UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _dataSourceArr.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellID = @"123cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.text = _dataSourceArr[indexPath.row];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        NormalCollectionViewController *vc = [[NormalCollectionViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        YXHomePageVC *vc = [[YXHomePageVC alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - <ASAuthorizationControllerDelegate>
/** 成功代理方法 */
- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization  API_AVAILABLE(ios(13.0)) {
    
    if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) { //此时为使用Sign With Apple 方式登录
        ASAuthorizationAppleIDCredential *credential = authorization.credential;
        NSString *userID = credential.user;
        _userId = userID;
        NSString *fullName = [NSString stringWithFormat:@"%@", credential.fullName];
        NSData *token = credential.identityToken;
        NSLog(@"userID = %@, fullName = %@, token = %@", userID, fullName, token);
    }
    else if ([authorization.credential isKindOfClass:[ASPasswordCredential class]]) { //Sign in using an existing iCloud Keychain credential.
        //用户登录使用现有的密码凭证
        ASPasswordCredential *passwordCredential = authorization.credential;
        //密码凭证对象的用户标识，用户的唯一标识
        NSString *userID = passwordCredential.user;
        //密码凭证对象的密码
        NSString *password = passwordCredential.password;
        NSLog(@"userID = %@, password = %@", userID, password);
    }
    else {
        NSLog(@"授权信息均不符");
    }
}
/** 失败代理方法 */
- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error  API_AVAILABLE(ios(13.0)) {
    
    NSString *errorMsg = nil;
    switch (error.code) {
        case ASAuthorizationErrorCanceled:
            errorMsg = @"用户取消了授权请求";
            break;
        case ASAuthorizationErrorFailed:
            errorMsg = @"授权请求失败";
            break;
        case ASAuthorizationErrorInvalidResponse:
            errorMsg = @"授权请求响应无效";
            break;
        case ASAuthorizationErrorNotHandled:
            errorMsg = @"未能处理授权请求";
            break;
        case ASAuthorizationErrorUnknown:
            errorMsg = @"授权请求失败未知原因";
            break;
        default:
            break;
    }
    NSLog(@"Handle error：%@", errorMsg);
}
/** 告诉代理应该在哪个window 展示内容给用户 */
- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller  API_AVAILABLE(ios(13.0)) {
    
    return self.view.window;
}

@end
