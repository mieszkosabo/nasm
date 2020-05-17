#ifndef PIX_H
#define PIX_H

#include <stdint.h>

uint64_t pix(uint32_t *ppi, uint64_t *pidx, uint64_t max);
void pixtime(uint64_t clock_tick);

#endif