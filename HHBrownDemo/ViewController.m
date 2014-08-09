//
//  ViewController.m
//  HHBrownDemo
//
//  Created by PRAVEEN ARAVAMUDHAN on 8/6/14.
//  Copyright (c) 2014 PRAVEEN ARAVAMUDHAN. All rights reserved.
//

#import "ViewController.h"
#import "ShoeData.h"

@interface ViewController () {
    NSString *access_token;
    NSMutableArray *shoeData_API;
}

@end

@implementation ViewController

- (void) parseShoeData: (NSData*) json {
    NSError *jsonError = nil;
    
    NSArray *jsonShoeArray = (NSArray *)[NSJSONSerialization JSONObjectWithData:json options:0 error:&jsonError];
    
    for (NSDictionary *dic in jsonShoeArray){
        ShoeData *shoeData = [[ShoeData alloc]init];
        shoeData.brand = [dic valueForKey:@"brand"];
        shoeData.imageURL = [dic valueForKey:@"image_link"];
        shoeData.shoeName = [dic valueForKey:@"title"];
        shoeData.product_type = [dic valueForKey:@"product_type"];
        [shoeData_API addObject:shoeData];
    }
    
    [self.tableView reloadData];
}


- (void) extractToken
{
    NSURL *url = [NSURL URLWithString:@"https://www.apitite.net/api/hhbrown/oauth/access_token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary *client_info = [NSMutableDictionary dictionary];
    client_info[@"grant_type"] = @"client_credentials";
    client_info[@"client_id"] = @"53e24df3c49a980200000002";
    client_info[@"client_secret"] = @"LnLhC3B0Kbp3co9RuqDFSdKd";
    
    NSData *body = [NSJSONSerialization dataWithJSONObject:client_info options:0 error:nil];
    NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    NSLog(@"%@", bodyString);
    
    [request setHTTPBody:body];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (!connectionError && httpResponse.statusCode == 200) {
            
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"The json returned is: %@", json);
            if ([json isKindOfClass:[NSDictionary class]]) {
               // completion(nil, json);
                access_token = [json objectForKey:@"access_token_base64"];
                
                NSLog(@"The access token is: %@", access_token);
                
                NSURL *aUrl = [NSURL URLWithString: @"https://www.apitite.net/api/hhbrown/shoesbytype/json?type=Sandals"];
                NSMutableURLRequest *request_shoedata = [NSMutableURLRequest requestWithURL:aUrl
                                                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                   timeoutInterval:30.0];
                
                [request_shoedata addValue:[NSString stringWithFormat:@"Bearer %@", access_token] forHTTPHeaderField:@"Authorization"];
                
                [request_shoedata setHTTPMethod:@"GET"];
                
                
                [NSURLConnection sendAsynchronousRequest:request_shoedata queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response_shoedata, NSData *shoeData, NSError *connectionErrorShoeData) {
                
                    NSHTTPURLResponse *httpResponseShoeData = (NSHTTPURLResponse *)response_shoedata;
                    if (!connectionErrorShoeData && httpResponseShoeData.statusCode == 200) {
                        
                        id json_shoedata = [NSJSONSerialization JSONObjectWithData:shoeData options:0 error:nil];
                        NSLog(@"shoe data is: %@", json_shoedata);
                        [self parseShoeData:shoeData];
                    } else {
                        NSString *responseStringShoeData = [[NSString alloc] initWithData:shoeData encoding:NSUTF8StringEncoding];
                        NSLog(@"Response: %@ Error: %@ StatusCode: %d", responseStringShoeData, connectionErrorShoeData, httpResponseShoeData.statusCode);
                    }
                }];
            }
        } else {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Response: %@ Error: %@ StatusCode: %d", responseString, connectionError, httpResponse.statusCode);
            //completion(connectionError, false);
        }
    }];

}

- (int) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [shoeData_API count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ShoeDetail"];
    ShoeData *shoeData = (ShoeData*)[shoeData_API objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:shoeData.imageURL]]];
    cell.textLabel.text = shoeData.shoeName;
    cell.detailTextLabel.text = shoeData.product_type;

    return cell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    shoeData_API = [[NSMutableArray alloc]initWithCapacity:25];
    [self extractToken];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
