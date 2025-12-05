//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from Arm Limited or its affiliates.
//
//            (C) COPYRIGHT 2020-2021 Arm Limited or its affiliates.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from Arm Limited or its affiliates.
//
// Release Information : Cortex-M55-r1p1-00rel0
//------------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//     AHB interconnect for Yamin execution_tb
//-----------------------------------------------------------------------------
//
// This block contains an AHB address decoder and AHB multiplexors. It has
// 1 slave ports and 8 master ports.
// Master port 0 is used as the default if no other master port is matched
// by the address decode logic.
//-----------------------------------------------------------------------------

module ahb_interconnect
  #(
    parameter DWIDTH = 32,
    parameter BASE_M1 = 32'h00000000,
    parameter WIDTH_M1 = 0,
    parameter ENABLE_M1 = 1,
    parameter BASE_M2 = 32'h00000000,
    parameter WIDTH_M2 = 0,
    parameter ENABLE_M2 = 0,
    parameter BASE_M3 = 32'h00000000,
    parameter WIDTH_M3 = 0,
    parameter ENABLE_M3 = 0,
    parameter BASE_M4 = 32'h00000000,
    parameter WIDTH_M4 = 0,
    parameter ENABLE_M4 = 0,
    parameter BASE_M5 = 32'h00000000,
    parameter WIDTH_M5 = 0,
    parameter ENABLE_M5 = 0,
    parameter BASE_M6 = 32'h00000000,
    parameter WIDTH_M6 = 0,
    parameter ENABLE_M6 = 0,
    parameter BASE_M7 = 32'h00000000,
    parameter WIDTH_M7 = 0,
    parameter ENABLE_M7 = 0,
    parameter BASE_M8 = 32'h00000000,
    parameter WIDTH_M8 = 0,
    parameter ENABLE_M8 = 0,
    parameter BASE_M9 = 32'h00000000,
    parameter WIDTH_M9 = 0,
    parameter ENABLE_M9 = 0
    //parameter BASE_M10 = 32'h00000000,
    //parameter WIDTH_M10 = 0,
    //parameter ENABLE_M10 = 0
    )
  (// Inputs
   input logic                 HCLK,
   input logic                 HRESETn,
   input logic [31:0]          HADDRS,
   input logic                 HREADYOUTM0,
   input logic [DWIDTH-1:0]    HRDATAM0,
   input logic                 HRESPM0,
   input logic                 HREADYOUTM1,
   input logic [DWIDTH-1:0]    HRDATAM1,
   input logic                 HRESPM1,
   input logic                 HREADYOUTM2,
   input logic [DWIDTH-1:0]    HRDATAM2,
   input logic                 HRESPM2,
   input logic                 HREADYOUTM3,
   input logic [DWIDTH-1:0]    HRDATAM3,
   input logic                 HRESPM3,
   input logic                 HREADYOUTM4,
   input logic [DWIDTH-1:0]    HRDATAM4,
   input logic                 HRESPM4,
   input logic                 HREADYOUTM5,
   input logic [DWIDTH-1:0]    HRDATAM5,
   input logic                 HRESPM5,
   input logic                 HREADYOUTM6,
   input logic [DWIDTH-1:0]    HRDATAM6,
   input logic                 HRESPM6,
   input logic                 HREADYOUTM7,
   input logic [DWIDTH-1:0]    HRDATAM7,
   input logic                 HRESPM7,
   input logic                 HREADYOUTM8,
   input logic [DWIDTH-1:0]    HRDATAM8,
   input logic                 HRESPM8,
   input logic                 HREADYOUTM9,
   input logic [DWIDTH-1:0]    HRDATAM9,
   input logic                 HRESPM9,
   //input logic                 HREADYOUTM10,
   //input logic [DWIDTH-1:0]    HRDATAM10,
   //input logic                 HRESPM10,
   // Outputs
   output logic                HREADYS,
   output logic                HRESPS,
   output logic [DWIDTH-1:0]   HRDATAS,
   output logic                HSELM0,
   output logic                HSELM1,
   output logic                HSELM2,
   output logic                HSELM3,
   output logic                HSELM4,
   output logic                HSELM5,
   output logic                HSELM6,
   output logic                HSELM7,
   output logic                HSELM8,
   output logic                HSELM9
   //output logic                HSELM10
   );

   // Registered HSELs
   logic hsel_m0_r;
   logic hsel_m1_r;
   logic hsel_m2_r;
   logic hsel_m3_r;
   logic hsel_m4_r;
   logic hsel_m5_r;
   logic hsel_m6_r;
   logic hsel_m7_r;
   logic hsel_m8_r;
   logic hsel_m9_r;
   //logic hsel_m10_r;

   //logic hsel_m10;
   logic hsel_m9;
   logic hsel_m8;
   logic hsel_m7;
   logic hsel_m6;
   logic hsel_m5;
   logic hsel_m4;
   logic hsel_m3;
   logic hsel_m2;
   logic hsel_m1;
   logic hsel_m0;

   // HSEL Decoder
   assign hsel_m8 = (ENABLE_M8 != 0) & ~(hsel_m1 | hsel_m2 | hsel_m3 | hsel_m4 | hsel_m5 | hsel_m6 | hsel_m7);

   //assign hsel_m10 = (ENABLE_M10 != 0) & (HADDRS[31:WIDTH_M10] == BASE_M10[31:WIDTH_M10]);
   assign hsel_m9 = (ENABLE_M9 != 0) & (HADDRS[31:WIDTH_M9] == BASE_M9[31:WIDTH_M9]);
   assign hsel_m7 = (ENABLE_M7 != 0) & (HADDRS[31:WIDTH_M7] == BASE_M7[31:WIDTH_M7]);
   assign hsel_m6 = (ENABLE_M6 != 0) & (HADDRS[31:WIDTH_M6] == BASE_M6[31:WIDTH_M6]);
   assign hsel_m5 = (ENABLE_M5 != 0) & (HADDRS[31:WIDTH_M5] == BASE_M5[31:WIDTH_M5]);
   assign hsel_m4 = (ENABLE_M4 != 0) & (HADDRS[31:WIDTH_M4] == BASE_M4[31:WIDTH_M4]);
   assign hsel_m3 = (ENABLE_M3 != 0) & (HADDRS[31:WIDTH_M3] == BASE_M3[31:WIDTH_M3]);
   assign hsel_m2 = (ENABLE_M2 != 0) & (HADDRS[31:WIDTH_M2] == BASE_M2[31:WIDTH_M2]);
   assign hsel_m1 = (ENABLE_M1 != 0) & (HADDRS[31:WIDTH_M1] == BASE_M1[31:WIDTH_M1]);

   // m0 is used as the default port, for example for AHB Default Slave
   assign hsel_m0 = ~(hsel_m1 | hsel_m2 | hsel_m3 | hsel_m4 | hsel_m5 | hsel_m6 | hsel_m7 | hsel_m8 | hsel_m9);

   // Registered HSEL
   always_ff @(posedge HCLK or negedge HRESETn)
     begin
       if (!HRESETn)
         begin
           hsel_m0_r <= 1'b0;
           hsel_m1_r <= 1'b0;
           hsel_m2_r <= 1'b0;
           hsel_m3_r <= 1'b0;
           hsel_m4_r <= 1'b0;
           hsel_m5_r <= 1'b0;
           hsel_m6_r <= 1'b0;
           hsel_m7_r <= 1'b0;
           hsel_m8_r <= 1'b0;
           hsel_m9_r <= 1'b0;
           //hsel_m10_r <= 1'b0;
         end
       else if (HREADYS)
         begin
           hsel_m0_r <= hsel_m0;
           hsel_m1_r <= hsel_m1;
           hsel_m2_r <= hsel_m2;
           hsel_m3_r <= hsel_m3;
           hsel_m4_r <= hsel_m4;
           hsel_m5_r <= hsel_m5;
           hsel_m6_r <= hsel_m6;
           hsel_m7_r <= hsel_m7;
           hsel_m8_r <= hsel_m8;
           hsel_m9_r <= hsel_m9;
           //hsel_m10_r <= hsel_m10;
         end
     end

     assign HRDATAS = ({DWIDTH{hsel_m0_r}} & HRDATAM0) |
                      ({DWIDTH{hsel_m1_r}} & HRDATAM1) |
                      ({DWIDTH{hsel_m2_r}} & HRDATAM2) |
                      ({DWIDTH{hsel_m3_r}} & HRDATAM3) |
                      ({DWIDTH{hsel_m4_r}} & HRDATAM4) |
                      ({DWIDTH{hsel_m5_r}} & HRDATAM5) |
                      ({DWIDTH{hsel_m6_r}} & HRDATAM6) |
                      ({DWIDTH{hsel_m7_r}} & HRDATAM7) |
                      ({DWIDTH{hsel_m8_r}} & HRDATAM8) |
                      ({DWIDTH{hsel_m9_r}} & HRDATAM9); 
             //         ({DWIDTH{hsel_m10_r}} & HRDATAM10);

     assign HRESPS  = (hsel_m0_r & HRESPM0) |
                      (hsel_m1_r & HRESPM1) |
                      (hsel_m2_r & HRESPM2) |
                      (hsel_m3_r & HRESPM3) |
                      (hsel_m4_r & HRESPM4) |
                      (hsel_m5_r & HRESPM5) |
                      (hsel_m6_r & HRESPM6) |
                      (hsel_m7_r & HRESPM7) |
                      (hsel_m8_r & HRESPM8) |
                      (hsel_m9_r & HRESPM9); 
                      //(hsel_m10_r & HRESPM10)


     assign HREADYS = (hsel_m0_r & HREADYOUTM0) |
                      (hsel_m1_r & HREADYOUTM1) |
                      (hsel_m2_r & HREADYOUTM2) |
                      (hsel_m3_r & HREADYOUTM3) |
                      (hsel_m4_r & HREADYOUTM4) |
                      (hsel_m5_r & HREADYOUTM5) |
                      (hsel_m6_r & HREADYOUTM6) |
                      (hsel_m7_r & HREADYOUTM7) |
                      (hsel_m8_r & HREADYOUTM8) |
                      (hsel_m9_r & HREADYOUTM9) |
                      //(hsel_m10_r & HREADYOUTM10) |
                      // Reply READY if no master port (slave device) selected (reset)
                      (~(hsel_m0_r | hsel_m1_r | hsel_m2_r | hsel_m3_r | hsel_m4_r |
                         hsel_m5_r | hsel_m6_r | hsel_m7_r | hsel_m8_r | hsel_m9_r ));

     assign  HSELM0 = hsel_m0;
     assign  HSELM1 = hsel_m1;
     assign  HSELM2 = hsel_m2;
     assign  HSELM3 = hsel_m3;
     assign  HSELM4 = hsel_m4;
     assign  HSELM5 = hsel_m5;
     assign  HSELM6 = hsel_m6;
     assign  HSELM7 = hsel_m7;
     assign  HSELM8 = hsel_m8;
     assign  HSELM9 = hsel_m9;
     //assign  HSELM10 = hsel_m10;

endmodule
