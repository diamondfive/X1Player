
# X1Player

X1Player是iOS端封装的播放器，支持直播 录播视频的播放,支持常用的播放界面控制，类似于ijkplayer 优点是体积更小,使用快捷。(为了减少SDK体积，SDK之支持arm64 armV7等真机架构)

## 展示效果

![展示效果](https://github.com/diamondfive/X1Player/blob/master/showtime.png?raw=true)


## 功能特性
- [x] 支持直播点播，支持格式包括RTMP、FLV、HLS、MP4等
- [x] 支持横竖屏切换，支持清晰度切换
- [x] 支持小窗播放，支持大小窗切换
- [x] 支持设置封面图，重播图
- [x] 手势操作（调整亮度、声音、进度）
- [x] 支持播放预加载
- [x] 支持屏幕锁屏
- [x] 高可定制性,方便添加自定义图层,控件层界面可自定义
- [x] 支持网络状态监听
- [x] 新增未开始的倒计时页面的简单业务逻辑实践
- [ ] 支持广告(开发中)

## 安装与集成
### 运行环境与配置
- iOS 7+
- Xcode 9+
- 关闭bitcode
具体按以下操作：
在Targets -> Build Settings -> Build Options 下
将Enable Bitcode 设置为NO即可
 
 为了尽可能减小库文件的大小，SDK仅支持 armv7/arm64真机运行环境，不支持模拟器运行，不支持bitcode
 

### 安装
- 通过[CocoaPods](https://cocoapods.org)安装

```objc
pod 'X1Player', '~> 1.1.5'
```

- 手动安装
   - 将工程中X1PlayerSDK文件夹下的所有文件拖入项目
   - 需要导入播放器依赖的系统库
      - libmediaplayer.a
      - OpenAL.framework
      - VideoToolbox.framework
      - GLKit.framework
      - CoreTelephony.framework
      - libz.tbd
      - libbz2.tbd
      - libiconv.tbd
      
## 用例

![结构图](https://github.com/diamondfive/X1Player/blob/develop/结构图.png?raw=true)
### 创建播放器
X1Player主类为X1PlayerView，您需要先创建它并添加到合适的容器View中。

```objective-c
self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH*9/16)];

//设置代理
self.playerView.delegate = self;

[self.view addSubview:self.playerView];

```

### 开始播放

```
 @param url 优先播放清晰度的url url需要存在于视频清晰度字典中
 @param definitionUrlArr 视频清晰度数组
 @param title 视频标题
 @param coverImage 封面图片 也可通过coverImageView/coverImage设置图片
 @param autoplay 是否自动播放
 @param style 控制层风格 参考X1PlayerViewStyle
 
[self.playerView playWithUrl:@"http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4_900.flv" definitionUrlArr:@[model1,model2,model3] playerTitle:@"直播清晰度切换测试" coverImage:self.image autoPlay:YES style:YZMoviePlayerControlsStyleLive];
```

### 横竖屏切换

播放器的isLocked属性标识播放器是否锁屏，调用逻辑如下

```

-(BOOL)shouldAutorotate{
    if (self.playerView.isLocked) {
        return NO;
    }
    return YES;
}
```

 

### 切换视频

在播放中可以随时切换到另一个视频，无需停止当前播放。只需要再次调用上一步的play方法传入新的url


### 小窗播放
小窗播是指在App内，悬浮在主window上的播放器。使用小窗播放非常简单，只需要在适当位置调用下面代码即可：

```
[self.playerView showFloatViewWithFrame:CGRectMake(0, 100, 160, 90) showCloseBtn:YES];
```

### 移除播放器
当不需要播放器时，调用resetPlayer清理播放器内部状态，防止干扰下次播放。

```
[self.playerView viewDestroy];//非常重要
```

## License

X1Player is available under the MIT license. See the LICENSE file for more info.

## 更多

项目封装时间比较仓促,如果使用过程中遇到问题 请issue项目或者email fyz333501@163.com





