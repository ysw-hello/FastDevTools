//
//  Mp3Encoder.hpp
//  MediaDemo
//
//  Created by 闫士伟 on 2018/7/25.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#ifndef Mp3Encoder_hpp
#define Mp3Encoder_hpp

#import "lame.h"
#include <stdio.h>

class Mp3Encoder {
private:
    FILE *pcmFile;
    FILE *mp3File;
    lame_t lameClient;
    
public:
//    Mp3Encoder ();
//    ~Mp3Encoder ();
    //返回0 表示初始化成功，返回-1表示初始化失败
    int processSource(const char *pcmFilePath, const char *mp3FilePath, float sampleRate, int channels, int bitRate);
    int encode ();
    void destory ();
    
};

#endif /* Mp3Encoder_hpp */
