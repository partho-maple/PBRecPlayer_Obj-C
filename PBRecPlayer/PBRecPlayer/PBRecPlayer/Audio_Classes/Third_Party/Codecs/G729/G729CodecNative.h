#pragma once

#include "typedef.h"
#include "basic_op.h"
#include "ld8a.h"

#include "g729a.h"


#define	G729_BIT_STREAM_SIZE	10
#define	PCM_BIT_STREAM_SIZE		80

#ifdef __cplusplus

class G729CodecNative
{
public:
	G729CodecNative(void);
	virtual ~G729CodecNative(void);

	bool Open();
	void Close();
	int Encode(Word16 *pcm, int size, UWord8 *bitstream); //void   g729a_enc_process  (void *encState, Word16 *pcm, UWord8 *bitstream);
	int Decode(UWord8 *bitstream, int size, Word16 *pcm); //void   g729a_dec_process  (void *decState, UWord8 *bitstream, Word16 *pcm, Flag badFrame);

private:
	Word32 encodersize;
	void *_hEncoder;
	/*decoder variable for open*/
	//Word32 decodersize;
	void *_hDecoder;
	bool _bOpened;

	Word16  _speechBuff[PCM_BIT_STREAM_SIZE];	
	UWord8  _g729Buff[PCM_BIT_STREAM_SIZE];
};

#endif
