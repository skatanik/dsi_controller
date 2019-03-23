`ifndef PACKET_TYPES_DEFINES
`define PACKET_TYPES_DEFINES
/********************************************************************
            PACKET TYPES DEFINES
********************************************************************/

`define     SP_FRAME_START_CODE         6'h0
`define     SP_FRAME_END_CODE           6'h1
`define     SP_LINE_START_CODE          6'h2
`define     SP_LINE_END_CODE            6'h3

`define     LP_NULL_CODE                6'h10
`define     LP_BLANKING_DATA_CODE       6'h11
`define     LP_EMBD_DATA_CODE           6'h12

`define     LP_YUV420_8_CODE            6'h18
`define     LP_YUV420_10_CODE           6'h19
`define     LP_L_YUV420_8_CODE          6'h1A
`define     LP_YUV420_8_SHPS_CODE       6'h1C   //  Chroma Shifted Pixel Sampling
`define     LP_YUV420_10_SHPS_CODE      6'h1D   //  Chroma Shifted Pixel Sampling
`define     LP_YUV422_8_CODE            6'h1E
`define     LP_YUV422_10_CODE           6'h1F

`define     LP_RGB444_CODE              6'h20
`define     LP_RGB555_CODE              6'h21
`define     LP_RGB565_CODE              6'h22
`define     LP_RGB666_CODE              6'h23
`define     LP_RGB888_CODE              6'h24

`define     LP_RAW6_CODE                6'h28
`define     LP_RAW7_CODE                6'h29
`define     LP_RAW8_CODE                6'h2A
`define     LP_RAW10_CODE               6'h2B
`define     LP_RAW12_CODE               6'h2C
`define     LP_RAW14_CODE               6'h2D

`endif
