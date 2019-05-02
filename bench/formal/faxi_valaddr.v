////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	faxi_valaddr.v (Formal properties of an AXI master)
//
// Project:	Pipelined Wishbone to AXI converter
//
// Purpose:	
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
module faxi_valaddr #(
	parameter C_AXI_DATA_WIDTH	= 128,// Width of the AXI R&W data
	parameter C_AXI_ADDR_WIDTH	= 28,	// AXI Address width (log wordsize)
	parameter [7:0] OPT_MAXBURST	= 8'hff,// Maximum burst length, minus 1
	parameter [0:0] OPT_EXCLUSIVE	= 1,// Exclusive access allowed
	parameter [0:0] OPT_NARROW_BURST = 1,// Narrow bursts allowed by default
	localparam DW			= C_AXI_DATA_WIDTH,
	localparam AW			= C_AXI_ADDR_WIDTH
	) (
	input	wire	[AW-1:0]	i_addr,	// address
	input	wire	[7:0]		i_len,	// Burst Length
	input	wire	[2:0]		i_size,	// Burst size
	input	wire	[1:0]		i_burst,// Burst type
	input	wire			i_lock,
	input	wire			i_initial,

	output	reg			o_aligned,
	output	reg			o_valid
);

	reg			page_break, wrap_error, invalid_burst,
				overlength_burst, aligned, lock_error;
	reg	[6:0]		addr_lsbs;

	always @(*)
	begin
		addr_lsbs = 0;
		if (AW-1 < 6)
			addr_lsbs[AW-1:0] = i_addr;
		else
			addr_lsbs[6:0] = i_addr;
	end

	always @(*)
	begin
		o_aligned = 1;
		case(i_size)
		0: o_aligned = 1;
		1: o_aligned = (addr_lsbs[    0] == 0);
		2: o_aligned = (addr_lsbs[1 : 0] == 0);
		3: o_aligned = (addr_lsbs[2 : 0] == 0);
		4: o_aligned = (addr_lsbs[3 : 0] == 0);
		5: o_aligned = (addr_lsbs[4 : 0] == 0);
		6: o_aligned = (addr_lsbs[5 : 0] == 0);
		7: o_aligned = (addr_lsbs[6 : 0] == 0);
		endcase
	end

	always @(*)
		overlength_burst = (i_len > OPT_MAXBURST);

	always @(*)
	begin
		if (OPT_NARROW_BURST)
			invalid_burst = ((1<<(i_size+3)) > DW);
		else
			invalid_burst = ((1<<(i_size+3)) != DW);
		if (i_burst == 2'b11)
			invalid_burst = 1;
	end

	always @(*)
	begin
		wrap_error = 0;
		if (i_burst == 2'b10)
		begin
			wrap_error = (i_initial)&&((i_len != 1)&&(i_len != 3)
				&&(i_len != 7)&&(i_len != 15));
			if (!o_aligned)
				wrap_error = 1;
		end
	end


	//
	// The specification specifically prohibits any transaction from
	// crossing a 4kB boundary
	//
	generate if (AW > 12)
	begin
		// We need the generate to make certain the (AW>12) is
		// checked and so as to avoid the synthesis error for
		// referencing addresses that are not valid

		reg	[AW-1:0]	last_addr;

		always @(*)
		begin
			page_break = 0;
			last_addr = i_addr + (i_len<<i_size);
			if ((AW > 12)&&(i_burst == 2'b01))
				page_break = (last_addr[AW-1:12]!=i_addr[AW-1:12]);
		end
	end else begin
		always @(*)
			page_break = 0;
	end endgenerate

	always @(*)
	begin
		lock_error = 0;
		if (i_lock)
		begin
			if (!o_aligned)
				lock_error = 1;
			if (i_len >= 16)
				lock_error = 1;
		end
	end

	always @(*)
	begin
		o_valid = 1;
		if (page_break || wrap_error || invalid_burst)
			o_valid = 0;
		if (overlength_burst)
			o_valid = 0;
		if (!OPT_EXCLUSIVE && i_lock)
			o_valid = 0;
		if (lock_error)
			o_valid = 0;
	end
endmodule
