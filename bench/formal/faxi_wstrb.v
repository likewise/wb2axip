////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	faxi_wstrb.v (Formal properties of an AXI master, write strobe)
//
// Project:	Pipelined Wishbone to AXI converter
//
// Purpose:	This file is an adjunct to the formal properties for AXI.
//		It contains a check of the write strobe signals, which can be
//	used in a lighter check than the entire properties of the AXI bus.
//	It's useful for checking write packets in flight.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2019, Gisselquist Technology, LLC
//
// This file is part of the pipelined Wishbone to AXI converter project, a
// project that contains multiple bus bridging designs and formal bus property
// sets.
//
// The bus bridge designs and property sets are free RTL designs: you can
// redistribute them and/or modify any of them under the terms of the GNU
// Lesser General Public License as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// The bus bridge designs and property sets are distributed in the hope that
// they will be useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with these designs.  (It's in the $(ROOT)/doc directory.  Run make
// with no target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
//
// License:	LGPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/lgpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
//
module faxi_wstrb #(
	parameter C_AXI_DATA_WIDTH	= 128,// Width of the AXI R&W data
	localparam DW			= C_AXI_DATA_WIDTH
	) (
	input	wire	[6:0]		i_addr,
	input	wire	[2:0]		i_size,

	input	wire	[DW/8-1:0]	i_wstrb,	// Write strobes
	output	reg			o_valid
);

	reg	[DW/8-1:0]	strb_mask;
	reg			invalid_stb;

	// Insist the only the appropriate bits be valid
	// For example, if the lower address bit is one, then the
	// strobe LSB cannot be 1, but must be zero.  This is just
	// enforcing the rules of the sub-address which must match
	// the write strobe.  An STRB of 0 is always allowed.
	//
	always @(*)
	begin
		strb_mask = 1;
		case(i_size)
		1: strb_mask =   {(2){1'b1}};
		2: strb_mask =   {(4){1'b1}};
		3: strb_mask =   {(8){1'b1}};
		4: strb_mask =  {(16){1'b1}};
		5: strb_mask =  {(32){1'b1}};
		6: strb_mask =  {(64){1'b1}};
		7: strb_mask = {(128){1'b1}};
		default: strb_mask = 1;
		endcase

		if (DW == 16)
			strb_mask = strb_mask << i_addr[0];
		if (DW == 32)
			strb_mask = strb_mask << i_addr[1:0];
		if (DW == 64)
			strb_mask = strb_mask << i_addr[2:0];
		if (DW == 128)
			strb_mask = strb_mask << i_addr[3:0];
		if (DW == 256)
			strb_mask = strb_mask << i_addr[4:0];
		if (DW == 512)
			strb_mask = strb_mask << i_addr[5:0];
		if (DW == 1024)
			strb_mask = strb_mask << i_addr[6:0];

		invalid_stb = ((i_wstrb & ~strb_mask)!=0);
	end

	always @(*)
		o_valid = !invalid_stb;
endmodule
