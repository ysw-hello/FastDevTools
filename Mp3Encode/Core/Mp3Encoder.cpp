//
//  Mp3Encoder.cpp
//  MediaDemo
//
//  Created by 闫士伟 on 2018/7/25.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#include "Mp3Encoder.hpp"
#include <iostream>

int Mp3Encoder::processSource(const char *pcmFilePath, const char *mp3FilePath, float sampleRate, int channels, int bitRate) {
    int ret = -1;
    int sampleRate_final = (int)(sampleRate * 1000);
    pcmFile = fopen(pcmFilePath, "rb");
    if (pcmFile) {
        mp3File = fopen(mp3FilePath, "wb");
        if (mp3File) {
            lameClient = lame_init();
            lame_set_in_samplerate(lameClient, sampleRate_final);//单位为Hz
            lame_set_out_samplerate(lameClient, sampleRate_final);//单位为Hz
            lame_set_num_channels(lameClient, channels);
            lame_set_brate(lameClient, bitRate);//单位为kbps
            lame_init_params(lameClient);
            ret = 0;
        }
    }
    return ret;
}

int Mp3Encoder::encode() {
    int ret = -1;
    int bufferSize = 1024 * 256;
    short *buffer = new short[bufferSize / 2];
    short *leftBuffer = new  short[bufferSize / 4];
    short *rightBuffer = new  short[bufferSize / 4];
    unsigned char *mp3_buffer = new unsigned char [bufferSize];
    size_t readBufferSize = 0;
    while ( (readBufferSize = fread(buffer, 2, bufferSize/2, pcmFile)) > 0 ) {
        for (int i = 0; i < readBufferSize; i++) {
            if (i % 2 == 0) {
                leftBuffer[i/2] = buffer[i];
            } else {
                rightBuffer[i/2] =buffer[i];
            }
        }
        size_t wroteSize = lame_encode_buffer(lameClient, (short int *)leftBuffer, (short int *)rightBuffer, (int)(readBufferSize/2), mp3_buffer, bufferSize);
        size_t ret_size = fwrite(mp3_buffer, 1, wroteSize, mp3File);
        if (ret_size) {
            ret = 0;
        }
    }
    
    delete [] buffer;
    delete [] leftBuffer;
    delete [] rightBuffer;
    delete [] mp3_buffer;
    
    return ret;
}

void Mp3Encoder::destory() {
    if (pcmFile) {
        fclose(pcmFile);
    }
    if (mp3File) {
        fclose(mp3File);
        lame_close(lameClient);
    }
}


