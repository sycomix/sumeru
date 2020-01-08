#include <stdio.h>
#include <stdlib.h>
#include <bcm2835.h>
#include <err.h>

void
bcm2835w_spi_setClockDivider(uint32_t divider)
{
  uint16_t div = (uint16_t) (divider & 0xffff);
  bcm2835_spi_setClockDivider(div);
}

void
bcm2835w_vector_append(
		uint8_t *dest, uint8_t *src,
		uint32_t dest_offset, uint32_t len)
{
  uint32_t count;

  for (count = 0; count < len; ++count)
    dest[dest_offset++] = src[count];
}

void
bcm2835w_i2c_setClockDivider(uint32_t divider)
{
  uint16_t div = (uint16_t) (divider & 0xffff);
  bcm2835_i2c_setClockDivider(div);
}
