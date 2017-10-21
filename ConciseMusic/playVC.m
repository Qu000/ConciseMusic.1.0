//
//  playVC.m
//  ConciseMusic
//
//  Created by qujiahong on 2017/3/15.
//  Copyright © 2017年 qujiahong. All rights reserved.
//

#import "playVC.h"
#define kMusicFile @"庄心妍,萧全 - 爱音乐.mp3"
#define kMusicSinger @"庄心妍,萧全"
#define kMusicTitle @"爱音乐"
@interface playVC ()
@property (nonatomic,strong) AVAudioPlayer *playMusic;//创建播放器
@property (weak,nonatomic) NSTimer *myTimer;//定时器
@property (weak, nonatomic) IBOutlet UIButton *playOrpause;//播放按钮
@property (weak, nonatomic) IBOutlet UISlider *playProgress;//播放进度条
//(上为最基本播放功能)
//（下为界面的优化）
@property (weak, nonatomic) IBOutlet UILabel *musicTitle;
@property (weak, nonatomic) IBOutlet UILabel *musicSinger;
@property (weak, nonatomic) IBOutlet UILabel *musicTime;
@property (weak, nonatomic) IBOutlet UIImageView *myMusicImage;
//歌词部分
@property (weak, nonatomic) IBOutlet UITableView *lyricsTableView;
@property(nonatomic,strong)NSMutableArray *lrcTimeAry;//存储,字典的key 值
@property (strong,nonatomic) NSMutableDictionary *lrcDic;////存储歌词
@property(assign,nonatomic)NSInteger line;
@property(nonatomic,strong)NSArray *dataArr;
@property (weak, nonatomic) IBOutlet UIButton *lyricsOrimage;//切换的按钮
@end

@implementation playVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initPlayProgressSlider];
    [self setUI];
    [self parserLrc];

    self.lyricsTableView.backgroundColor = [UIColor clearColor];//设置cell背景色为透明的一步
    self.lyricsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;//消除每个cell之间的分割线
    self.lyricsTableView.hidden = YES;

   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - 基本的播放功能
-(AVAudioPlayer *)playMusic{
    if (!_playMusic) {//注意，playMusic
        NSString *url = [[NSBundle mainBundle]pathForResource:kMusicFile ofType:nil];//设置路径找到播放文件
        
        
//        NSString * url = [[NSBundle mainBundle]pathForResource:@"/Users/qujiahong/Library/Developer/CoreSimulator/Devices/9B9F04FC-CF28-48AF-BEBE-72EDDE032F76/data/Containers/Data/Application/6CCFA0F0-5F58-47AF-AE07-290D3FEABE83/Documents/music/Raise Hell/wKgDYVdIe5GxnC3YAAsekLwsnCg212.aac" ofType:nil];

        

        NSURL *urlP = [NSURL fileURLWithPath:url];////初始化播放器，注意这里的urlP参数只是本地文件路径，不支持HTTP Url
        NSError *error = nil;//初始化播放器
        _playMusic = [[AVAudioPlayer alloc]initWithContentsOfURL:urlP error:&error];//
        _playMusic.numberOfLoops = 0;
        _playMusic.delegate = self;
        [_playMusic prepareToPlay];//加载音频文件到缓存
        if (error) {
            NSLog(@"初始化播放器过程发生错误，错误信息为：%@",error.localizedDescription);
            return nil;
        }
    }
    return _playMusic;
}
-(void)play{
    if (![self.playMusic isPlaying]) {
        [self.playMusic play];
        self.myTimer.fireDate = [NSDate distantPast];//恢复定时器
    }
}
-(void)pause{
    if ([self.playMusic isPlaying]) {
        [self.playMusic pause];
        self.myTimer.fireDate = [NSDate distantFuture];//暂停定时器
    }
}



- (IBAction)playOnClick:(id)sender {//播放按钮；tag为0认为是暂停状态，1是播放状态
    if (self.playOrpause.tag) {
        self.playOrpause.tag = 0;
        [sender setImage:[UIImage imageNamed:@"play.png"]forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"pause.png"]forState:UIControlStateHighlighted];
        
//        self.myTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateLyrics) userInfo:nil repeats:YES];
        
        [self pause];
    }else{
        self.playOrpause.tag = 1;
        [sender setImage:[UIImage imageNamed:@"pause.png"]forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"play.png"]forState:UIControlStateHighlighted];
        [self play];
    }
}



-(NSTimer *)myTimer{
    if (!_myTimer) {//注意myTimer
        _myTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updatePlayProgressSlider) userInfo:nil repeats:true];//设置时间，每0.5秒钟调用一次绑定方法updateSlider
    }
    /*if ([self.playMusic isPlaying]) {
        [UIView beginAnimations:@"transform" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        self.myMusicImage.transform = CGAffineTransformRotate(self.myMusicImage.transform, 0.02);
        [UIView commitAnimations];//提交动画
    }*/
    return _myTimer;
}
-(void)updatePlayProgressSlider{
    NSTimeInterval totalTime = _playMusic.duration;//获取音频的总时间
    NSTimeInterval currentTime = _playMusic.currentTime;//获取音频的当前时间
    self.playProgress.value = (currentTime/totalTime);//根据时间比设置进度条的进度
    
  
    
    //显示时间Label
    NSTimeInterval currentM = currentTime/60;
    currentTime = (int)currentTime%60;
    NSTimeInterval totalM = totalTime/60;
    totalTime = (int)totalTime%60;//把秒转换为分
    NSString *timeString = [NSString stringWithFormat:@"%02.0f:%02.0f|%02.0f:%02.0f",currentM,currentTime,totalM,totalTime];
    self.musicTime.text = timeString;
    
    //歌词滚不动！！！动动动
    NSString *CtimeLyrics = [NSString stringWithFormat:@"%02.0f:%02.0f",currentM,currentTime];
//       NSLog(@"CtimeLyrics11-->%@",CtimeLyrics);
    if ([self.lrcTimeAry containsObject:CtimeLyrics]) {
//                NSLog(@"CtimeLyrics22-->%@",CtimeLyrics);
        self.line = [self.lrcTimeAry indexOfObject:CtimeLyrics];
//                 NSLog(@"line-->%ld",(long)_line);
        [self.lyricsTableView reloadData];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.line inSection:0];
        [self.lyricsTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }


}


-(void)initPlayProgressSlider{
    self.playProgress.value = 0.0f;
}
- (IBAction)changePlayProgress:(UISlider *)sender {
    CGFloat duration = _playMusic.duration; //获取当前音乐总时间
    _playMusic.currentTime = duration *sender.value; //设置当前的播放进度
}


#pragma mark - 界面优化
- (NSString*)timeStringFromSecond:(NSInteger)second {
    
    return [NSString stringWithFormat:@"%02ld:%02ld",second / 60 ,second % 60];
    
}
-(void)setUI{
    NSString *image = @"1.jpg";
    self.myMusicImage.image = [UIImage imageNamed:image];//设置一张背景图
    self.myMusicImage.layer.cornerRadius = self.myMusicImage.frame.size.width/2;
    self.myMusicImage.clipsToBounds = YES;//将imageView变为圆形

    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.delegate = self;
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI/2, 0, 0, 1.0)];//图片顺时针旋转
    animation.duration = 10;//执行一次的时间
    animation.cumulative = YES;//累计效果，有了它，才可以使图片先旋转180，再旋转360
    animation.repeatCount = INT_MAX;//执行次数
   [_myMusicImage.layer addAnimation:animation forKey:@"animation"];
    
    //-----imageView
    //-----其他Label
    
    self.musicTitle.text = kMusicTitle;
    self.musicSinger.text = kMusicSinger;
}


#pragma mark - 歌词部分
-(void)parserLrc{
  
    self.dataArr = @[@"爱音乐"];
    NSString *path = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"%@",_dataArr[0]] ofType:@"lrc"];
    NSString *contentStr = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    
    self.lrcDic = [NSMutableDictionary dictionaryWithCapacity:0];
    self.lrcTimeAry = [NSMutableArray arrayWithCapacity:0];
    //换行进行分割; 获取每一行的歌词;
    NSArray *linArr = [contentStr componentsSeparatedByString:@"\n"];
    
    for (NSString *string in linArr) {
        if (string.length > 7) {
            NSString *str1 = [string substringWithRange:NSMakeRange(3, 1)];
            NSString *str2 = [string substringWithRange:NSMakeRange(6, 1)];
            if ([str1 isEqualToString:@":"]&&[str2 isEqualToString:@"."]) {
//                 NSLog(@"%@",string);
                //截取歌词和时间;
                NSString *timeStr = [string substringWithRange:NSMakeRange(1, 5)];
                NSString *lrcStr = [string substringFromIndex:10   ];
//                NSLog(@"%@,%@",timeStr,lrcStr);
                //放入集合中;
                [self.lrcTimeAry addObject:timeStr];
                [self.lrcDic setObject:lrcStr forKey:timeStr];
                [self.lyricsTableView reloadData];
            }
        }
    }

}
#pragma mark - 歌词中UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.lrcTimeAry.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"forIndexPath:indexPath];
    NSString *key = self.lrcTimeAry[indexPath.row];
    cell.textLabel.text = self.lrcDic[key];
    //改变 textLabel 的样式;
    if (indexPath.row  == self.line) {
        
        cell.textLabel.font = [UIFont systemFontOfSize:20];
        cell.textLabel.textColor = [UIColor redColor];
    } else {
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.textLabel.textColor = [UIColor blueColor];
    }
    cell.textLabel.textAlignment = NSTextAlignmentCenter;//文本居中
    cell.backgroundColor = [UIColor clearColor];//设置cell为透明的第二步
    return cell;
}
#pragma mark - 歌词与image的切换
- (IBAction)changeButton:(id)sender {//播放按钮；tag为0认为是image，1是歌词
    if (self.lyricsOrimage.tag) {
        self.lyricsOrimage.tag = 0;
        self.myMusicImage.hidden = NO;
        self.lyricsTableView.hidden = YES;
    }else{
        self.lyricsOrimage.tag = 1;
        self.myMusicImage.hidden = YES;
        self.lyricsTableView.hidden = NO;
    }
}


#pragma mark - 播放器代理方法
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"这首歌曲播放完成");
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
