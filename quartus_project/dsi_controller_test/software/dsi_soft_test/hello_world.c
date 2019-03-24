/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include <stdint.h>
#include "system.h"
#include <io.h>
#include "custom_periph.h"

int main()
{
	// MIPI DSI TX INIT
	// disable packet dropping
	printf("\n[Soft init] TX init\n\n");
	uint32_t settings_word = MIPI_DSI_TX_CTRL_LANES_ENABLE_MASK | MIPI_DSI_TX_CTRL_LANES_NUMBER_MASK_3;

	// enable lanes
	IOWR(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_CTRL_BASE, settings_word);

	while(!(IORD(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_ISR_BASE) & MIPI_DSI_TX_ISR_LANES_READY_MASK))
	{}
	printf("\n[Soft init] Lanes ready!\n\n");

	settings_word |= MIPI_DSI_TX_CTRL_CLK_ENABLE_MASK;

	// enable lck lanes
	IOWR(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_CTRL_BASE, settings_word);

	while(!(IORD(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_ISR_BASE) & MIPI_DSI_TX_ISR_CLK_READY_MASK))
	{}

	printf("\n[Soft init] Clock ready!\n\n");

    settings_word = IORD(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_CTRL_BASE);

    IOWR(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_CMD_BASE, 0x551234);

    settings_word |= MIPI_DSI_TX_CTRL_SEND_CMD_MASK;

    IOWR(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_CTRL_BASE, settings_word);

    while(!(IORD(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_ISR_BASE) & MIPI_DSI_TX_ISR_LANES_UNACTINE_MASK))
    {}

    IOWR(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_ISR_BASE, 0);

    printf("\n[Soft init] CMD sent!\n\n");

	// enable controller
	settings_word |= MIPI_DSI_TX_CTRL_ASSEMBLER_ENABLE_MASK;
    settings_word &= ~MIPI_DSI_TX_CTRL_SEND_CMD_MASK;

	IOWR(DSI_TX_CONTROLLER_0_BASE, MIPI_DSI_TX_CTRL_BASE, settings_word);

	printf("\n[Soft init] Controller enabled!\n\n");

	for(int i = 0; i < 200; i++){}

	IOWR(ALT_VIP_CL_TPG_0_BASE, 0, 0x1);

	printf("\n[Soft init] TPG enabled;\n\n");

  return 0;
}
