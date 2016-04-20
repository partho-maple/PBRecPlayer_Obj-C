#include "G729CodecNative.h"
#include <stdlib.h>

G729CodecNative::G729CodecNative(void)
{
	_hEncoder = NULL;
	_hDecoder = NULL;
	_bOpened = false;
}


G729CodecNative::~G729CodecNative(void)
{
	Close();
}

bool G729CodecNative::Open()
{
	Flag flag;
	Word32 memSize = g729a_enc_mem_size();
	//_hEncoder = calloc(1, encSize * sizeof(UWord8));
	if( (_hEncoder = calloc(1, memSize * sizeof(UWord8))) == NULL)
		return false;

	//flag = g729a_enc_init(_hEncoder);
	if( (flag = g729a_enc_init(_hEncoder)) == 0)
		return false;

	memSize = g729a_dec_mem_size();
	//_hDecoder = calloc(1, memSize * sizeof(UWord8));
	if ( (_hDecoder = calloc(1, memSize * sizeof(UWord8))) == NULL)
		return false;

	//flag = g729a_dec_init(_hDecoder);
	if( (flag = g729a_dec_init(_hDecoder)) == 0)
		return false;

	_bOpened = true;
	return _bOpened;
}

void G729CodecNative::Close()
{
	if(!_bOpened)
		return;

	g729a_enc_deinit(_hEncoder);
	free(_hEncoder);
	/*decoder closed*/
	g729a_dec_deinit(_hDecoder);
	free(_hDecoder);

	_bOpened = false;
}

int G729CodecNative::Encode(Word16 *pcm, int size, UWord8 *bitstream)
{
	if(!_bOpened)
		return false;

	//int frameSize = L_FRAME;
	int pcmOffset = 0;
	int g729Offset = 0;
	for (; pcmOffset < size;)
	{
		memcpy(_speechBuff, pcm + pcmOffset, PCM_BIT_STREAM_SIZE * 2);
		g729a_enc_process(_hEncoder, _speechBuff, _g729Buff);
		memcpy(bitstream + g729Offset, _g729Buff, G729_BIT_STREAM_SIZE);

		pcmOffset += PCM_BIT_STREAM_SIZE;
		g729Offset += G729_BIT_STREAM_SIZE;
	}

    return g729Offset;
//	return true;
}

int G729CodecNative::Decode(UWord8 *bitstream, int size, Word16 *pcm)
{
	if(!_bOpened)
		return false;

	int pcmOffset = 0;
	int g729Offset = 0;
	for (; g729Offset < size;)
	{
		memcpy(_g729Buff, bitstream + g729Offset, G729_BIT_STREAM_SIZE);
		g729a_dec_process(_hDecoder, _g729Buff, _speechBuff, 0);
		memcpy(pcm + pcmOffset, _speechBuff, PCM_BIT_STREAM_SIZE * 2);

		pcmOffset += PCM_BIT_STREAM_SIZE;
		g729Offset += G729_BIT_STREAM_SIZE;
	}

    return pcmOffset;
//	return true;
}
