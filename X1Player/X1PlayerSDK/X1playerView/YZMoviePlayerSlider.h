
/*!
 * @File:       YZMoviePlayerSlider
 * @Abstract:   为Slider添加middleTrack，用于实现音乐或视频播放的buffered进度
                支持 UIControlEventValueChanged 事件

 */

#import <UIKit/UIKit.h>

@interface YZMoviePlayerSlider : UIControl
@property (nonatomic, assign) CGFloat value;        /* From 0 to 1 */
@property (nonatomic, assign) CGFloat middleValue;  /* From 0 to 1 */
@property (nonatomic, strong) UISlider* slider; 
@property (nonatomic, strong) UIColor* thumbTintColor;
@property (nonatomic, strong) UIColor* minimumTrackTintColor;
@property (nonatomic, strong) UIColor* middleTrackTintColor;
@property (nonatomic, strong) UIColor* maximumTrackTintColor;

@property (nonatomic, readonly) UIImage* thumbImage;
@property (nonatomic, strong) UIImage* minimumTrackImage;
@property (nonatomic, strong) UIImage* middleTrackImage;
@property (nonatomic, strong) UIImage* maximumTrackImage;

- (void)setThumbImage:(UIImage *)image forState:(UIControlState)state;
@end


