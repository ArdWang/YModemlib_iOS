//
//  DownLoadView.m
//  YModemCs
//
//  Created by rnd on 2018/6/15.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "DownLoadView.h"
#import <QuartzCore/QuartzCore.h>
#import "NoteView.h"
#import "DownLoadBtn.h"

#ifdef __OBJC__
//define this constant if you want to use Masonry without the 'mas_' prefix
#define MAS_SHORTHAND
//define this constant if you want to enable auto-boxing for default syntax
#define MAS_SHORTHAND_GLOBALS
#import "Masonry.h"
#endif

#define SingeleNoteScale 1.2
#define SingeleNoteSize 20
#define DoubleNoteScale 1.25
#define DoubleNoteSize 25
#define Color(r,g,b,a) [UIColor colorWithRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:a]

@interface DownLoadView()
{
    NSString *musicalText;
}

/** UIProgressView */
@property (nonatomic, weak) UIView *musicalProgressView;
/** ZWMusicDownLoadBtn */
@property (nonatomic, weak)  DownLoadBtn *musicDownLoadBtn;
/** musicalSingleNoteView */
@property (nonatomic, weak) NoteView *musicalSingleNoteView;
/** ZWMusicalNoteView */
@property (nonatomic, weak) NoteView *musicalDoubleNoteView;

@end


@implementation DownLoadView
-(instancetype)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self) {
        self.clipsToBounds=YES;
        self.layer.cornerRadius=25;
        self.backgroundColor=Color(29, 28, 37, 1);
        [self setUpChildView];
    }
    return self;
}
-(void)setUpChildView
{
    [self setUpDownLoadBtn];
    
    [self setUpDownLoadProgressView];
    
    [self setUpDownLoadLab];
}


-(void)startDownLoad
{
    if (self.musicalProgress<1) {
        int showMusicalNotesTimes=(arc4random() % 8);
        for (int i=0; i<showMusicalNotesTimes; i++) {
            [self setUpDoubleNoteView];
        }
        self.musicDownLoadLab.font= self.placeholderFont?self.placeholderFont:[UIFont fontWithName:@"Helvetica-Bold" size:12];
        self.musicDownLoadLab.text=[NSString stringWithFormat:@"%@ %d%%",self.placeholderText?self.placeholderText:musicalText,(int)(self.musicalProgress*100)];;
        self.musicDownLoadBtn.userInteractionEnabled=NO;
        
    }else
    {
        self.musicDownLoadLab.font= self.placeholderBtnFont?self.placeholderBtnFont:[UIFont fontWithName:@"Helvetica-Bold" size:15];
        self.musicDownLoadLab.text=self.placeholderBtnText?self.placeholderBtnText:[NSString stringWithFormat:@"升级完成"];
        self.musicDownLoadBtn.userInteractionEnabled=YES;
        [self bringSubviewToFront:self.musicDownLoadBtn];
    }
    
}

-(void)endDownLoad
{
    self.musicalProgress=0.0;
    self.musicDownLoadLab.text=self.musicDownLoadLab.text=[NSString stringWithFormat:@"%@ %d%%",self.placeholderText?self.placeholderText:musicalText,(int)(self.musicalProgress*100)];;
    self.musicDownLoadLab.font= self.placeholderFont?self.placeholderFont:[UIFont fontWithName:@"Helvetica-Bold" size:12];
}

-(void)setUpDownLoadBtn
{
    DownLoadBtn *musicDownLoadBtn =[[DownLoadBtn alloc]initWithFrame:self.bounds];
    musicDownLoadBtn.backgroundColor=[UIColor clearColor];
    [musicDownLoadBtn addTarget:self action:@selector(clickToStartDoSth) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:musicDownLoadBtn];
    self.musicDownLoadBtn=musicDownLoadBtn;
    self.musicDownLoadBtn.userInteractionEnabled=NO;
}
-(void)setUpDownLoadProgressView
{
    UIView * musicalProgressView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.musicalProgress*self.frame.size.width, self.frame.size.height)];
    musicalProgressView.backgroundColor=self.musicalColor?self.musicalColor:Color(236, 93, 78, 1);
    
    [self addSubview:musicalProgressView];
    self.musicalProgressView=musicalProgressView;
    
    
}

-(void)setUpDownLoadLab
{
    musicalText=self.placeholderText?self.placeholderText:@"正在升级中...";
    self.musicDownLoadLab = [[UILabel alloc] init];
    self.musicDownLoadLab.textAlignment=NSTextAlignmentCenter;
    self.musicDownLoadLab.textColor=[UIColor whiteColor];
    self.musicDownLoadLab.font=[UIFont fontWithName:@"Helvetica-Bold" size:12];
    self.musicDownLoadLab.adjustsFontSizeToFitWidth=YES;
    self.musicDownLoadLab.text = musicalText;
    
    self.musicDownLoadLab.text=[NSString stringWithFormat:@"%@   %d%%",self.placeholderText?self.placeholderText:musicalText,(int)(self.musicalProgress*100)];

    [self addSubview:self.musicDownLoadLab];
  
    [self.musicDownLoadLab makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self).offset(30);
        make.right.equalTo(self).offset(-30);
        make.centerY.equalTo(self);
        make.height.equalTo(@20);
    }];
}

-(void)setUpDoubleNoteView
{
    
    CGFloat musicalNoteSize = (arc4random() % 6) + 6;
    //    CGFloat rotationNumber = (arc4random() % 10)/10.0 ;
    //    CGFloat hightNumber = (arc4random() % 20) +20;
    int isSingleNumber=(arc4random() % 2);
    switch (isSingleNumber) {
        case 0:
        {
            NoteView *musicalSingleNoteView=[[NoteView alloc]initWithFrame:CGRectMake(self.frame.size.width, SingeleNoteScale*musicalNoteSize, musicalNoteSize, SingeleNoteScale*musicalNoteSize)];
            musicalSingleNoteView.isSingleOne=YES;
            musicalSingleNoteView.scaleSize=musicalNoteSize/SingeleNoteSize;
            musicalSingleNoteView.backgroundColor=[UIColor clearColor];
            musicalSingleNoteView.musicalColor=self.musicalColor?self.musicalColor:Color(236, 93, 78, 1);
            [self addSubview:musicalSingleNoteView];
            self.musicalSingleNoteView=musicalSingleNoteView;
            [self sendSubviewToBack:self.musicalSingleNoteView];
            
            [self animateInmusicalNoteView:self.musicalSingleNoteView];
            
        }
            break;
            
        case 1:
        {
            NoteView *musicalDoubleNoteView=[[NoteView alloc]initWithFrame:CGRectMake(self.frame.size.width, DoubleNoteScale*musicalNoteSize, musicalNoteSize, DoubleNoteScale*musicalNoteSize)];
            
            
            musicalDoubleNoteView.scaleSize=musicalNoteSize/DoubleNoteSize;
            musicalDoubleNoteView.backgroundColor=[UIColor clearColor];
            musicalDoubleNoteView.musicalColor=self.musicalColor?self.musicalColor:Color(236, 93, 78, 1);
            [self addSubview:musicalDoubleNoteView];
            self.musicalDoubleNoteView=musicalDoubleNoteView;
            
            
            [self sendSubviewToBack:self.musicalDoubleNoteView];
            
            
            [self animateInmusicalNoteView:self.musicalDoubleNoteView];
        }
            break;
    }
    
    
    
}

-(void)showTheMusicalProgress
{
    self.musicalProgressView.frame=CGRectMake(0, 0, self.frame.size.width*self.musicalProgress, self.frame.size.height);
    self.musicDownLoadLab.text=self.musicDownLoadLab.text=[NSString stringWithFormat:@"%@ %d%%",self.placeholderText?self.placeholderText:musicalText,(int)(self.musicalProgress*100)];;
}

-(void)animateInmusicalNoteView:(UIView *)view{
    
    
    CGFloat totalAnimationDuration =(arc4random() % 2)+2+(arc4random() % 10)/10.0;
    
    //    //Pre-Animation setup
    //    view.transform = CGAffineTransformMakeScale(0, 0);
    //    view.alpha = 0;
    //
    //Bloom
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
        view.transform = CGAffineTransformIdentity;
        view.alpha = 0.9;
    } completion:NULL];
    
    [UIView animateWithDuration:totalAnimationDuration animations:^{
        CGFloat rotationNumber = (arc4random() % 20)/10.0 ;
        view.transform = CGAffineTransformMakeRotation (rotationNumber*M_PI);
    } completion:NULL];
    
    UIBezierPath *heartTravelPath = [UIBezierPath bezierPath];
    
    
    
    if (self.frame.size.width>self.frame.size.height) {
        CGFloat rotationWidthNumber = (arc4random() % 10)+self.frame.size.width/2-5 ;
        CGFloat rotationHighNumber= (arc4random() % (int)self.frame.size.height) ;
        [heartTravelPath moveToPoint:CGPointMake(self.frame.size.width, self.frame.size.height/2)];
        [heartTravelPath addCurveToPoint:CGPointMake(0, self.frame.size.height/2) controlPoint1:CGPointMake(rotationWidthNumber,rotationHighNumber) controlPoint2:CGPointMake(rotationWidthNumber,rotationHighNumber)];
    }else
    {
        CGFloat rotationWidthNumber = (arc4random() % (int)self.frame.size.width) ;
        CGFloat rotationHighNumber=  (arc4random() % 10)+self.frame.size.height/2-5;
        [heartTravelPath moveToPoint:CGPointMake(self.frame.size.width/2, self.frame.size.height)];
        [heartTravelPath addCurveToPoint:CGPointMake(self.frame.size.width/2,0) controlPoint1:CGPointMake(rotationWidthNumber,rotationHighNumber) controlPoint2:CGPointMake(rotationWidthNumber,rotationHighNumber)];
    }
    
    
    
    
    
    CAKeyframeAnimation *keyFrameAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    keyFrameAnimation.path = heartTravelPath.CGPath;
    keyFrameAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    keyFrameAnimation.duration = totalAnimationDuration;
    [view.layer addAnimation:keyFrameAnimation forKey:@"positionOnPath"];
    
    //Alpha & remove from superview
    [UIView animateWithDuration:totalAnimationDuration animations:^{
        view.alpha = 1.0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
    
    
}


-(void)setMusicalProgress:(CGFloat)musicalProgress
{
    _musicalProgress=musicalProgress;
    self.musicalProgressView.frame=CGRectMake(0, 0, self.frame.size.width*_musicalProgress, self.frame.size.height);
    self.musicDownLoadLab.text=[NSString stringWithFormat:@"%@ %d%%",self.placeholderText?self.placeholderText:musicalText,(int)(self.musicalProgress*100)];
}

-(void)setMusicalColor:(UIColor *)musicalColor
{
    _musicalColor=musicalColor;
    self.musicalProgressView.backgroundColor=musicalColor?musicalColor:Color(236, 93, 78, 1);
}

-(void)setTitleColor:(UIColor *)titleColor
{
    _titleColor=titleColor;
    self.musicDownLoadLab.textColor=self.titleColor?self.titleColor:[UIColor whiteColor];
}

-(void)setPlaceholderText:(NSString *)placeholderText
{
    _placeholderText=placeholderText;
    self.musicDownLoadLab.text=[NSString stringWithFormat:@"%@ %d%%",placeholderText?placeholderText:musicalText,(int)(self.musicalProgress*100)];;
}

-(void)setPlaceholderBtnText:(NSString *)placeholderBtnText
{
    _placeholderBtnText=placeholderBtnText;
    
}
-(void)setPlaceholderFont:(UIFont *)placeholderFont
{
    _placeholderFont=placeholderFont;
    self.musicDownLoadLab.font= self.placeholderFont?self.placeholderFont:[UIFont fontWithName:@"Helvetica-Bold" size:12];
}
-(void)clickToStartDoSth
{
    if ([self.delegate respondsToSelector:@selector(ClickToStartTheDownLoadBtnInLoadView:)]) {
        [self.delegate ClickToStartTheDownLoadBtnInLoadView:self];
    }
    NSLog(@"点击");
}
@end

