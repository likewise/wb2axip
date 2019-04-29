////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	faxi_master.v (Formal properties of an AXI master)
//
// Project:	Pipelined Wishbone to AXI converter
//
// Purpose:	This file contains a set of formal properties which can be
//		used to formally verify that a core truly follows the full
//	AXI4 specification.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017-2019, Gisselquist Technology, LLC
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
module faxi_master #(
	parameter C_AXI_ID_WIDTH	= 3, // The AXI id width used for R&W
                                             // This is an int between 1-16
	parameter C_AXI_DATA_WIDTH	= 128,// Width of the AXI R&W data
	parameter C_AXI_ADDR_WIDTH	= 28,	// AXI Address width (log wordsize)
	parameter [7:0] OPT_MAXBURST	= 8'hff,// Maximum burst length, minus 1
	parameter [0:0] OPT_EXCLUSIVE	= 1,// Exclusive access allowed
	parameter [0:0] OPT_NARROW_BURST = 1,// Narrow bursts allowed by default
	parameter 	F_LGDEPTH	= 10,
	parameter	[(F_LGDEPTH-1):0]	F_AXI_MAXSTALL = 3,
	parameter	[(F_LGDEPTH-1):0]	F_AXI_MAXRSTALL= 3,
	parameter	[(F_LGDEPTH-1):0]	F_AXI_MAXDELAY = 3,
	parameter [0:0]			F_OPT_READCHECK = 0,
	localparam			F_OPT_BURSTS    = (OPT_MAXBURST != 0),
	parameter [0:0]			F_OPT_ASSUME_RESET = 1'b1,
	parameter [0:0]			F_OPT_NO_RESET = 1'b1,
	localparam IW			= C_AXI_ID_WIDTH,
	localparam DW			= C_AXI_DATA_WIDTH,
	localparam AW			= C_AXI_ADDR_WIDTH
	) (
	input	wire			i_clk,	// System clock
	input	wire			i_axi_reset_n,

// AXI write address channel signals
	input	wire			i_axi_awready,//Slave is ready to accept
	input	wire	[C_AXI_ID_WIDTH-1:0]	i_axi_awid,	// Write ID
	input	wire	[AW-1:0]	i_axi_awaddr,	// Write address
	input	wire	[7:0]		i_axi_awlen,	// Write Burst Length
	input	wire	[2:0]		i_axi_awsize,	// Write Burst size
	input	wire	[1:0]		i_axi_awburst,	// Write Burst type
	input	wire	[0:0]		i_axi_awlock,	// Write lock type
	input	wire	[3:0]		i_axi_awcache,	// Write Cache type
	input	wire	[2:0]		i_axi_awprot,	// Write Protection type
	input	wire	[3:0]		i_axi_awqos,	// Write Quality of Svc
	input	wire			i_axi_awvalid,	// Write address valid

// AXI write data channel signals
	input	wire			i_axi_wready,  // Write data ready
	input	wire	[DW-1:0]	i_axi_wdata,	// Write data
	input	wire	[DW/8-1:0]	i_axi_wstrb,	// Write strobes
	input	wire			i_axi_wlast,	// Last write transaction
	input	wire			i_axi_wvalid,	// Write valid

// AXI write response channel signals
	input	wire [C_AXI_ID_WIDTH-1:0] i_axi_bid,	// Response ID
	input	wire	[1:0]		i_axi_bresp,	// Write response
	input	wire			i_axi_bvalid,  // Write reponse valid
	input	wire			i_axi_bready,  // Response ready

// AXI read address channel signals
	input	wire			i_axi_arready,	// Read address ready
	input	wire	[C_AXI_ID_WIDTH-1:0]	i_axi_arid,	// Read ID
	input	wire	[AW-1:0]	i_axi_araddr,	// Read address
	input	wire	[7:0]		i_axi_arlen,	// Read Burst Length
	input	wire	[2:0]		i_axi_arsize,	// Read Burst size
	input	wire	[1:0]		i_axi_arburst,	// Read Burst type
	input	wire	[0:0]		i_axi_arlock,	// Read lock type
	input	wire	[3:0]		i_axi_arcache,	// Read Cache type
	input	wire	[2:0]		i_axi_arprot,	// Read Protection type
	input	wire	[3:0]		i_axi_arqos,	// Read Protection type
	input	wire			i_axi_arvalid,	// Read address valid

// AXI read data channel signals
	input wire [C_AXI_ID_WIDTH-1:0] i_axi_rid,     // Response ID
	input	wire	[1:0]		i_axi_rresp,   // Read response
	input	wire			i_axi_rvalid,  // Read reponse valid
	input	wire	[DW-1:0]	i_axi_rdata,    // Read data
	input	wire			i_axi_rlast,    // Read last
	input	wire			i_axi_rready,  // Read Response ready
	//
	output	reg	[F_LGDEPTH-1:0]		f_axi_awr_nbursts,
	output	reg	[9-1:0]			f_axi_wr_pending,
	output	reg	[F_LGDEPTH-1:0]		f_axi_rd_nbursts,
	output	reg	[F_LGDEPTH-1:0]		f_axi_rd_outstanding,
		// Address writes without write valids
	//
	// WR_COUNT:
	output	reg	[C_AXI_ID_WIDTH-1:0]	f_axi_wr_checkid,
	output	reg				f_axi_wr_ckvalid,
	output	reg	[F_LGDEPTH-1:0]		f_axi_wrid_nbursts,
	output	reg	[AW-1:0]		f_axi_wr_addr,	// Write address
	output	reg	[7:0]			f_axi_wr_incr,
	output	reg	[1:0]			f_axi_wr_burst,
	output	reg	[2:0]			f_axi_wr_size,
	output	reg	[7:0]			f_axi_wr_len,
	//
	// RD_COUNT: increment on read w/o last, cleared on read w/ last
	output reg	[C_AXI_ID_WIDTH-1:0]	f_axi_rd_checkid,
	output reg			    	f_axi_rd_ckvalid,
	output reg	[9-1:0]			f_axi_rd_cklen,
	//
	output	reg	[AW-1:0]		f_axi_rd_ckaddr,// Read address
	output	wire	[7:0]			f_axi_rd_ckincr,
	output	reg	[1:0]			f_axi_rd_ckburst,
	output	reg	[2:0]			f_axi_rd_cksize,
	output	reg	[7:0]			f_axi_rd_ckarlen,

	output	reg	[F_LGDEPTH-1:0]		f_axi_rdid_nbursts,
	output	reg	[F_LGDEPTH-1:0]		f_axi_rdid_outstanding,
	output	reg	[F_LGDEPTH-1:0]		f_axi_rdid_ckign_nbursts,
	output	reg	[F_LGDEPTH-1:0]		f_axi_rdid_ckign_outstanding
);

//*****************************************************************************
// Parameter declarations
//*****************************************************************************

	localparam	F_AXI_MAXWAIT = F_AXI_MAXSTALL;

	// Because of the nature and size of bursts, which can be up to
	// 256 in length (AxLEN), the F_LGDEPTH parameter necessary to capture
	// this *must* be at least 8 bits wide
	always @(*)
		assert(F_LGDEPTH > 8);

	// Only power of two data sizes are supported from 8-bits on up to
	// 1024
	always @(*)
		assert((DW == 8)
			||(DW ==  16)
			||(DW ==  32)
			||(DW ==  64)
			||(DW == 128)
			||(DW == 256)
			||(DW == 512)
			||(DW == 1024));

//*****************************************************************************
// Internal register and wire declarations
//*****************************************************************************


	wire	axi_rd_ack, axi_wr_ack, axi_ard_req, axi_awr_req, axi_wr_req,
		axi_rd_err, axi_wr_err;
	//
	assign	axi_ard_req = (i_axi_arvalid)&&(i_axi_arready);
	assign	axi_awr_req = (i_axi_awvalid)&&(i_axi_awready);
	assign	axi_wr_req  = (i_axi_wvalid )&&(i_axi_wready);
	//
	assign	axi_rd_ack = (i_axi_rvalid)&&(i_axi_rready);
	assign	axi_wr_ack = (i_axi_bvalid)&&(i_axi_bready);
	assign	axi_rd_err = (axi_rd_ack)&&(i_axi_rresp[1]);
	assign	axi_wr_err = (axi_wr_ack)&&(i_axi_bresp[1]);


	reg	f_past_valid;
	reg	[3:0]	f_reset_length;
	reg	[AW-1:0]	r_axi_wr_addr;
	wire	[AW-1:0]	next_wr_addr;
	wire	[7:0]		this_wr_incr;
	reg	[2:0]		this_awsize;
	(* keep *) reg	[DW/8-1:0]	strb_mask;
	reg			wr_aligned, awr_aligned,
				rd_aligned, ard_aligned;
	reg			rd_pending;
	wire	[AW-1:0]	next_rd_addr;
	reg			rd_pending;
	//
	// Let the solver pick some arbitrary ID's to be checked by this
	// checker
	(* anyconst *)	reg	[C_AXI_ID_WIDTH-1:0]	r_axi_wr_checkid;
	(* anyconst *)	reg	[C_AXI_ID_WIDTH-1:0]	r_axi_rd_checkid;

	(* anyseq *)	reg				f_axi_rd_check;

	// Within the slave core, we will *assume* properties from the master,
	// and *assert* properties of signals coming from the slave and
	// returning to the master.  This order will be reversed within the
	// master, and the following two definitions help us do that.
	//
	// Similarly, we will always *assert* local values of our own necessary
	// for checks below.  Those will use the assert() keyword, rather than
	// either of these two macros.
`define	SLAVE_ASSUME	assert
`define	SLAVE_ASSERT	assume

	//
	// Setup
	//
	integer	k;

	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

	always @(*)
	if (!f_past_valid)
		assert(!i_axi_reset_n);

	////////////////////////////////////////////////////////////////////////
	//
	//
	// Reset properties
	//
	// Insist that the reset signal start out asserted (negative), and
	// remain so for 16 clocks.
	//
	////////////////////////////////////////////////////////////////////////
	generate if (F_OPT_ASSUME_RESET)
	begin : ASSUME_INITIAL_RESET
		always @(*)
		if (!f_past_valid)
			assume(!i_axi_reset_n);
	end else begin : ASSERT_INITIAL_RESET
		always @(*)
		if (!f_past_valid)
			assert(!i_axi_reset_n);
	end endgenerate
	//
	//
	// If asserted, the reset must be asserted for a minimum of 16 clocks
	initial	f_reset_length = 0;
	always @(posedge i_clk)
	if (F_OPT_NO_RESET || i_axi_reset_n)
		f_reset_length <= 0;
	else if (!(&f_reset_length))
		f_reset_length <= f_reset_length + 1'b1;

	always @(posedge i_clk)
	if ((f_past_valid)&& !F_OPT_NO_RESET
			&& (!$past(i_axi_reset_n))&&(!$past(&f_reset_length)))
		`SLAVE_ASSUME(!i_axi_reset_n);

	//
	// If the reset is not generated within this particular core, then it
	// can be assumed if F_OPT_ASSUME_RESET is set
	generate if (F_OPT_ASSUME_RESET && !F_OPT_NO_RESET)
	begin : ASSUME_RESET
		always @(posedge i_clk)
		if ((f_past_valid)&&(!$past(i_axi_reset_n))&&(!$past(&f_reset_length)))
			assume(!i_axi_reset_n);

		always @(*)
		if ((f_reset_length > 0)&&(f_reset_length < 4'hf))
			assume(!i_axi_reset_n);

	end else if (!F_OPT_NO_RESET)
	begin : ASSERT_RESET

		always @(posedge i_clk)
		if ((f_past_valid)&&(!$past(i_axi_reset_n))&&(!$past(&f_reset_length)))
			assert(!i_axi_reset_n);

		always @(*)
		if ((f_reset_length > 0)&&(f_reset_length < 4'hf))
			assert(!i_axi_reset_n);

	end endgenerate

	//
	// All of the xVALID signals *MUST* be set low on the clock following
	// a reset.  Not in the spec, but also checked here is that they must
	// also be set low initially.
	always @(posedge i_clk)
	if ((!f_past_valid)||(!$past(i_axi_reset_n)))
	begin
		`SLAVE_ASSUME(!i_axi_arvalid);
		`SLAVE_ASSUME(!i_axi_awvalid);
		`SLAVE_ASSUME(!i_axi_wvalid);
		//
		`SLAVE_ASSERT(!i_axi_bvalid);
		`SLAVE_ASSERT(!i_axi_rvalid);
	end

	////////////////////////////////////////////////////////////////////////
	//
	//
	// Stability properties--what happens if valid and not ready
	//
	//
	////////////////////////////////////////////////////////////////////////

	// Assume any response from the bus will not change prior to that
	// response being accepted
	always @(posedge i_clk)
	if ((f_past_valid)&&($past(i_axi_reset_n)))
	begin
		// Write address channel
		if ((f_past_valid)&&($past(i_axi_awvalid))&&(!$past(i_axi_awready)))
		begin
			`SLAVE_ASSUME(i_axi_awvalid);
			`SLAVE_ASSUME(i_axi_awaddr  == $past(i_axi_awaddr));
			`SLAVE_ASSUME($stable(i_axi_awid));
			`SLAVE_ASSUME($stable(i_axi_awlen));
			`SLAVE_ASSUME($stable(i_axi_awsize));
			`SLAVE_ASSUME($stable(i_axi_awburst));
			`SLAVE_ASSUME($stable(i_axi_awlock));
			`SLAVE_ASSUME($stable(i_axi_awcache));
			`SLAVE_ASSUME($stable(i_axi_awprot));
			`SLAVE_ASSUME($stable(i_axi_awqos));
		end

		// Write data channel
		if ((f_past_valid)&&($past(i_axi_wvalid))&&(!$past(i_axi_wready)))
		begin
			`SLAVE_ASSUME(i_axi_wvalid);
			`SLAVE_ASSUME($stable(i_axi_wstrb));
			`SLAVE_ASSUME($stable(i_axi_wdata));
			`SLAVE_ASSUME($stable(i_axi_wlast));
		end

		// Incoming Read address channel
		if ((f_past_valid)&&($past(i_axi_arvalid))&&(!$past(i_axi_arready)))
		begin
			`SLAVE_ASSUME(i_axi_arvalid);
			`SLAVE_ASSUME($stable(i_axi_arid));
			`SLAVE_ASSUME($stable(i_axi_araddr));
			`SLAVE_ASSUME($stable(i_axi_arlen));
			`SLAVE_ASSUME($stable(i_axi_arsize));
			`SLAVE_ASSUME($stable(i_axi_arburst));
			`SLAVE_ASSUME($stable(i_axi_arlock));
			`SLAVE_ASSUME($stable(i_axi_arcache));
			`SLAVE_ASSUME($stable(i_axi_arprot));
			`SLAVE_ASSUME($stable(i_axi_arqos));
		end

		// Assume any response from the bus will not change prior to
		// that response being accepted
		if ((f_past_valid)&&($past(i_axi_rvalid))&&(!$past(i_axi_rready)))
		begin
			`SLAVE_ASSERT(i_axi_rvalid);
			`SLAVE_ASSERT($stable(i_axi_rid));
			`SLAVE_ASSERT($stable(i_axi_rresp));
			`SLAVE_ASSERT($stable(i_axi_rdata));
			`SLAVE_ASSERT($stable(i_axi_rlast));
		end

		if ((f_past_valid)&&($past(i_axi_bvalid))&&(!$past(i_axi_bready)))
		begin
			`SLAVE_ASSERT(i_axi_bvalid);
			`SLAVE_ASSERT($stable(i_axi_bid));
			`SLAVE_ASSERT($stable(i_axi_bresp));
		end
	end

	////////////////////////////////////////////////////////////////////////
	//
	//
	// Insist upon a maximum delay before a request is accepted
	//
	//
	////////////////////////////////////////////////////////////////////////

	generate if (F_AXI_MAXWAIT > 0)
	begin : CHECK_STALL_COUNT
		//
		// AXI write address channel
		//
		//
		reg	[(F_LGDEPTH-1):0]	f_axi_awstall,
						f_axi_wstall,
						f_axi_arstall;
						// f_axi_bstall,
						// f_axi_rstall;

		initial	f_axi_awstall = 0;
		always @(posedge i_clk)
		if ((!i_axi_reset_n)||(!i_axi_awvalid)||(i_axi_awready)
				||(f_axi_wr_pending > 0))
			f_axi_awstall <= 0;
		else if ((!i_axi_bvalid)||(i_axi_bready))
			f_axi_awstall <= f_axi_awstall + 1'b1;

		always @(*)
			`SLAVE_ASSERT(f_axi_awstall < F_AXI_MAXWAIT);

		//
		// AXI write data channel
		//
		//
		// AXI explicitly allows write bursts with zero strobes.  This
		// is part of how a transaction is aborted (if at all).

		initial	f_axi_wstall = 0;
		always @(posedge i_clk)
		if ((!i_axi_reset_n)||(!i_axi_wvalid)||(i_axi_wready)
				||(f_axi_wr_pending == 0 && i_axi_wvalid))
			f_axi_wstall <= 0;
		else if ((!i_axi_bvalid)||(i_axi_bready))
			f_axi_wstall <= f_axi_wstall + 1'b1;

		always @(*)
			`SLAVE_ASSERT(f_axi_wstall < F_AXI_MAXWAIT);

		//
		// AXI read address channel
		//
		//
		initial	f_axi_arstall = 0;
		always @(posedge i_clk)
		if ((!i_axi_reset_n)||(!i_axi_arvalid)||(i_axi_arready)
				||(i_axi_rvalid)||(f_axi_rd_nbursts > 0))
			f_axi_arstall <= 0;
		else if ((!i_axi_rvalid)||(i_axi_rready))
			f_axi_arstall <= f_axi_arstall + 1'b1;

		always @(*)
			`SLAVE_ASSERT(f_axi_arstall < F_AXI_MAXWAIT);

	end endgenerate

	////////////////////////////////////////////////////////////////////////
	//
	//
	// Insist upon a maximum delay before any response is accepted
	//
	// These are separate from the earlier ones, in case you wish to
	// control them separately.  For example, an interconnect might be
	// forced to let a channel wait indefinitely for access, but it might
	// not be appropriate to require the response to be able to wait
	// indefinitely as well
	//
	////////////////////////////////////////////////////////////////////////

	generate if (F_AXI_MAXRSTALL > 0)
	begin : CHECK_RESPONSE_STALLS
		//
		// AXI write address channel
		//
		//
		reg	[(F_LGDEPTH-1):0]	f_axi_wvstall,
						f_axi_bstall,
						f_axi_rstall;

		// AXI write channel valid
		initial	f_axi_bstall = 0;
		always @(posedge i_clk)
		if ((!i_axi_reset_n)||(i_axi_wvalid)
				||(i_axi_bvalid && !i_axi_bready)
				||(f_axi_wr_pending == 0))
			f_axi_wvstall <= 0;
		else
			f_axi_wvstall <= f_axi_wvstall + 1'b1;

		always @(*)
			`SLAVE_ASSUME(f_axi_wvstall < F_AXI_MAXRSTALL);

		// AXI write response channel
		initial	f_axi_bstall = 0;
		always @(posedge i_clk)
		if ((!i_axi_reset_n)||(!i_axi_bvalid)||(i_axi_bready))
			f_axi_bstall <= 0;
		else
			f_axi_bstall <= f_axi_bstall + 1'b1;

		always @(*)
			`SLAVE_ASSUME(f_axi_bstall < F_AXI_MAXRSTALL);

		// AXI read response channel
		initial	f_axi_rstall = 0;
		always @(posedge i_clk)
		if ((!i_axi_reset_n)||(!i_axi_rvalid)||(i_axi_rready))
			f_axi_rstall <= 0;
		else
			f_axi_rstall <= f_axi_rstall + 1'b1;

		always @(*)
			`SLAVE_ASSUME(f_axi_rstall < F_AXI_MAXRSTALL);

	end endgenerate

	////////////////////////////////////////////////////////////////////////
	//
	//
	// Count outstanding transactions.  With these measures, we count
	// once per any burst.
	//
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	always @(*)
		f_axi_wr_checkid = r_axi_wr_checkid;

	initial	f_axi_wr_pending = 0;
	initial	f_axi_wr_ckvalid = 0;
	always @(posedge i_clk)
	if (!i_axi_reset_n)
	begin
		f_axi_wr_pending <= 0;
		f_axi_wr_ckvalid <= 0;
	end else case({ axi_awr_req, axi_wr_req })
	2'b10: begin
		f_axi_wr_pending <= i_axi_awlen+1;
		f_axi_wr_ckvalid <= (i_axi_awid == f_axi_wr_checkid);
		end
	2'b01: begin
		`SLAVE_ASSUME(f_axi_wr_pending > 0);
		f_axi_wr_pending <= f_axi_wr_pending - 1'b1;
		`SLAVE_ASSUME(!i_axi_wlast || (f_axi_wr_pending == 1));
		if (i_axi_wlast)
			f_axi_wr_ckvalid <= 0;
		end
	2'b11: begin
		f_axi_wr_ckvalid <= (i_axi_awid == f_axi_wr_checkid);
		if (f_axi_wr_pending > 0)
			f_axi_wr_pending <= i_axi_awlen+1;
		else begin
			f_axi_wr_pending <= i_axi_awlen;
			if (i_axi_awlen == 0)
				f_axi_wr_ckvalid <= 0;
		end end
	default: begin end
	endcase

	always @(*)
	if (f_axi_wr_ckvalid)
		assert((f_axi_wrid_nbursts > 0)&&(f_axi_wr_pending > 0));
	//
	// Insist that no WVALID value show up prior to a AWVALID value.  The
	// address *MUST* come first.  Further, while waiting for the write
	// data, NO OTHER WRITE ADDRESS may be permitted.  This is not strictly
	// required by the specification, but it is required in order to make
	// these properties work (currently--I might revisit this later)
	//
	always @(*)
	case({i_axi_awvalid, i_axi_wvalid})
		// If AWVALID is true but not WVALID, then no other write
		// requests shall be pending.  This makes certain that the
		// new address doesn't get mixed up with any prior responses
		// from the slave
	2'b10: `SLAVE_ASSUME(f_axi_wr_pending == 0);
	2'b01: begin
		// On the other hand, if WVALID is true but not AWVALID,
		// then we only need to double check that there's at least
		// one pending value to be returned.  If this is the last value,
		// make certain that it is so marked.
		`SLAVE_ASSUME(f_axi_wr_pending > 0);
		`SLAVE_ASSUME(i_axi_wlast == (f_axi_wr_pending == 1));
		end
	2'b11: begin
		// If both AWVALID and WVALID, then we have two cases to
		// consider.  The first case is that the WVALID applies to the
		// last item of the previous burst.  Otherwise, it could be
		// the data associated with this new burst described by AW*
		if (f_axi_wr_pending > 0)
		begin // Write word applies to the last burst
			`SLAVE_ASSUME(f_axi_wr_pending == 1);
			`SLAVE_ASSUME(i_axi_wlast);
			`SLAVE_ASSERT(!i_axi_awready || i_axi_wready);
		end else begin
			// Must be associated with the new burst
			// In this case, check WLAST against the *incoming*
			// address request
			`SLAVE_ASSUME(i_axi_wlast == (i_axi_awlen == 0));
		end end
	default: begin end
	endcase

	//
	// Count the number of outstanding BVALID's to expect
	//
	initial	f_axi_awr_nbursts = 0;
	always @(posedge i_clk)
	if (!i_axi_reset_n)
		f_axi_awr_nbursts <= 0;
	else case({ (axi_awr_req), (axi_wr_ack) })
	2'b10: f_axi_awr_nbursts <= f_axi_awr_nbursts + 1'b1;
	2'b01: f_axi_awr_nbursts <= f_axi_awr_nbursts - 1'b1;
	default: begin end
	endcase

	//
	// Count the number of outstanding BVALID's to expect associated with
	// our choice of check ID.  That is, we check one channel alone for
	// proper ordering, and this is the count of the channel we have
	// chosen
	//
	initial	f_axi_wrid_nbursts = 0;
	always @(posedge i_clk)
	if (!i_axi_reset_n)
		f_axi_wrid_nbursts <= 0;
	else case({ (axi_awr_req)&&(i_axi_awid==f_axi_wr_checkid),
			(axi_wr_ack)&&(i_axi_bid == f_axi_wr_checkid) })
	2'b10: f_axi_wrid_nbursts <= f_axi_wrid_nbursts + 1'b1;
	2'b01: f_axi_wrid_nbursts <= f_axi_wrid_nbursts - 1'b1;
	default: begin end
	endcase

	//
	// Count the number of reads bursts outstanding.  This defines the
	// number of RDVALID && RLAST's we expect to see before becoming idle
	//
	initial	f_axi_rd_nbursts = 0;
	always @(posedge i_clk)
	if (!i_axi_reset_n)
		f_axi_rd_nbursts <= 0;
	else case({ (axi_ard_req), (axi_rd_ack)&&(i_axi_rlast) })
	2'b01: f_axi_rd_nbursts <= f_axi_rd_nbursts - 1'b1;
	2'b10: f_axi_rd_nbursts <= f_axi_rd_nbursts + 1'b1;
	endcase

	//
	// f_axi_rd_outstanding counts the number of RDVALID's we expect to
	// see before becoming idle.  This must always be greater than or
	// equal to the number of RVALID & RLAST's counted above
	//
	initial	f_axi_rd_outstanding = 0;
	always @(posedge i_clk)
	if (!i_axi_reset_n)
		f_axi_rd_outstanding <= 0;
	else case({ (axi_ard_req), (axi_rd_ack) })
	2'b01: f_axi_rd_outstanding <= f_axi_rd_outstanding - 1'b1;
	2'b10: f_axi_rd_outstanding <= f_axi_rd_outstanding + i_axi_arlen+1;
	2'b11: f_axi_rd_outstanding <= f_axi_rd_outstanding + i_axi_arlen;
	endcase

	//
	// Do not let the number of outstanding requests overflow.  This is
	// a responsibility of the master to never allow 2^F_LGDEPTH-1
	// requests to be outstanding.
	//
	always @(posedge i_clk)
		`SLAVE_ASSERT(f_axi_rd_outstanding  < {(F_LGDEPTH){1'b1}});
	always @(posedge i_clk)
		`SLAVE_ASSERT(f_axi_awr_nbursts < {(F_LGDEPTH){1'b1}});
	always @(posedge i_clk)
		`SLAVE_ASSERT(f_axi_wr_pending <= 256);
	always @(posedge i_clk)
		`SLAVE_ASSERT(f_axi_rd_nbursts  < {(F_LGDEPTH){1'b1}});

	////////////////////////////////////////////////////////////////////////
	//
	// Read Burst counting
	//
	always @(*)
		f_axi_rd_checkid = r_axi_rd_checkid;

	initial	f_axi_rdid_nbursts = 0;
	initial	f_axi_rdid_outstanding = 0;
	always @(posedge i_clk)
	if (!i_axi_reset_n)
	begin
		f_axi_rdid_nbursts <= 0;
		f_axi_rdid_outstanding <= 0;
	end else case({	(i_axi_arvalid&& i_axi_arready&&
				(i_axi_arid == f_axi_rd_checkid)),
			(i_axi_rvalid && i_axi_rready &&
				(i_axi_rid == f_axi_rd_checkid)) })
	2'b01: begin
		if (i_axi_rlast)
			f_axi_rdid_nbursts <= f_axi_rdid_nbursts - 1;
		f_axi_rdid_outstanding <= f_axi_rdid_outstanding - 1;
		end
	2'b10: begin
		f_axi_rdid_nbursts <= f_axi_rdid_nbursts + 1;
		f_axi_rdid_outstanding <= f_axi_rdid_outstanding+i_axi_arlen+ 1;
		end
	2'b11: begin
		if (!i_axi_rlast)
			f_axi_rdid_nbursts <= f_axi_rdid_nbursts + 1;
		f_axi_rdid_outstanding <= f_axi_rdid_outstanding + i_axi_arlen;
		end
	default: begin end
	endcase


	always @(*)
		assert(f_axi_rd_nbursts <= f_axi_rd_outstanding);
	always @(*)
		assert((f_axi_rd_nbursts == 0)==(f_axi_rd_outstanding==0));
	//
	//
	always @(*)
		assert(f_axi_rdid_nbursts <= f_axi_rd_nbursts);
	always @(*)
	if (f_axi_rdid_nbursts == f_axi_rd_nbursts)
		assert(f_axi_rdid_outstanding == f_axi_rd_outstanding);
	always @(*)
		assert(f_axi_rdid_outstanding <= f_axi_rd_outstanding);
	always @(*)
		assert(f_axi_rdid_nbursts <= f_axi_rdid_outstanding);
	always @(*)
		assert(f_axi_rd_nbursts - f_axi_rdid_nbursts
				<= f_axi_rd_outstanding - f_axi_rdid_outstanding);
	always @(*)
		assert((f_axi_rdid_nbursts == 0)==(f_axi_rdid_outstanding==0));
	always @(*)
		assert((f_axi_rdid_nbursts == f_axi_rd_nbursts)
			== (f_axi_rdid_outstanding == f_axi_rd_outstanding));
	// ///////
	always @(*)
	if (f_axi_rd_ckvalid)
	begin
		assert(f_axi_rdid_nbursts >= f_axi_rdid_ckign_nbursts+1);
		if (f_axi_rdid_ckign_nbursts+1 == f_axi_rdid_nbursts)
			assert(f_axi_rdid_outstanding
				== f_axi_rdid_ckign_outstanding+f_axi_rd_cklen);
		assert(f_axi_rdid_outstanding >=
			f_axi_rdid_ckign_outstanding
			+ f_axi_rd_cklen
			+ (f_axi_rdid_nbursts-(f_axi_rdid_ckign_nbursts+1)));
	end

	//
	// AXI read data channel signals
	//
	always @(posedge i_clk)
	if (i_axi_rvalid)
	begin
		`SLAVE_ASSERT(f_axi_rd_outstanding > 0);
		`SLAVE_ASSERT(f_axi_rd_nbursts > 0);
		if (f_axi_rd_checkid == i_axi_rid)
		begin
			`SLAVE_ASSERT(f_axi_rdid_nbursts > 0);
			`SLAVE_ASSERT(f_axi_rdid_outstanding > 0);
		end else begin
			`SLAVE_ASSERT(f_axi_rd_nbursts > f_axi_rdid_nbursts);
			`SLAVE_ASSERT(f_axi_rd_outstanding
					>  f_axi_rdid_outstanding);
		end
	end

	always @(posedge i_clk)
		assume(f_axi_rd_outstanding <= { f_axi_rd_nbursts[F_LGDEPTH-9:0], 8'h0 });
	always @(*)
	if (i_axi_rvalid)
	begin
		if (f_axi_rd_outstanding == f_axi_rd_nbursts)
			`SLAVE_ASSERT(i_axi_rlast);
	
		if (f_axi_rd_nbursts == 1)
			`SLAVE_ASSERT(i_axi_rlast == (f_axi_rd_outstanding==1));
			

		if (f_axi_rd_checkid == i_axi_rid)
		begin
			if (f_axi_rdid_outstanding == f_axi_rdid_nbursts)
				`SLAVE_ASSERT(i_axi_rlast);
			if (f_axi_rdid_nbursts == 1)
				`SLAVE_ASSERT(i_axi_rlast == (f_axi_rdid_outstanding == 1));
		end else // if (f_axi_rd_checkid != i_axi_rid
		begin
			if ((f_axi_rd_outstanding - f_axi_rdid_outstanding)
				 == (f_axi_rd_nbursts - f_axi_rdid_nbursts))
				`SLAVE_ASSERT(i_axi_rlast);
			if (f_axi_rd_nbursts - f_axi_rdid_nbursts == 1)
				`SLAVE_ASSERT(i_axi_rlast == (f_axi_rd_outstanding - f_axi_rdid_outstanding == 1));
		end
	end

	always @(*)
	if (i_axi_rvalid && f_axi_rd_ckvalid && f_axi_rd_checkid == i_axi_rid)
	begin

		if (f_axi_rdid_ckign_nbursts > 0)
		begin
			if (f_axi_rdid_ckign_outstanding == f_axi_rdid_nbursts)
				`SLAVE_ASSERT(i_axi_rlast);
		end else
			`SLAVE_ASSERT(i_axi_rlast == (f_axi_rd_cklen == 1));

	end else if (i_axi_rvalid && f_axi_rd_ckvalid
			&& f_axi_rd_checkid != i_axi_rid)
	begin
		`SLAVE_ASSERT(f_axi_rd_outstanding
			- f_axi_rdid_ckign_outstanding
			- f_axi_rd_cklen
			- (f_axi_rdid_nbursts-f_axi_rdid_ckign_nbursts-1) > 1);
	end

	//
	//



	////////////////////////////////////////////////////////////////////////
	//
	//
	// Insist that all responses are returned in less than a maximum delay
	// In this case, we count responses within a burst, rather than entire
	// bursts.
	//
	//
	// A unique feature to the backpressure mechanism within AXI is that
	// we have to reset our delay counters in the case of any push back,
	// since the response can't move forward if the master isn't (yet)
	// ready for it.
	//
	////////////////////////////////////////////////////////////////////////

	generate if (F_AXI_MAXDELAY > 0)
	begin : CHECK_MAX_DELAY

		reg	[(F_LGDEPTH-1):0]	f_axi_awr_ack_delay,
						f_axi_rd_ack_delay;

		initial	f_axi_awr_ack_delay = 0;
		always @(posedge i_clk)
		if ((!i_axi_reset_n)||(i_axi_bvalid)||(i_axi_wvalid)
					||((f_axi_awr_nbursts == 1)
						&&(f_axi_wr_pending>0))
					||(f_axi_awr_nbursts == 0))
			f_axi_awr_ack_delay <= 0;
		else
			f_axi_awr_ack_delay <= f_axi_awr_ack_delay + 1'b1;

		initial	f_axi_rd_ack_delay = 0;
		always @(posedge i_clk)
		if ((!i_axi_reset_n)||(i_axi_rvalid)||(f_axi_rd_outstanding==0))
			f_axi_rd_ack_delay <= 0;
		else
			f_axi_rd_ack_delay <= f_axi_rd_ack_delay + 1'b1;

		always @(posedge i_clk)
			`SLAVE_ASSERT(f_axi_awr_ack_delay < F_AXI_MAXDELAY);

		always @(*)
			`SLAVE_ASSERT(f_axi_rd_ack_delay < F_AXI_MAXDELAY);

	end endgenerate

	////////////////////////////////////////////////////////////////////////
	//
	//
	// Assume acknowledgements must follow requests
	//
	// The outstanding count is a count of bursts, but the acknowledgements
	// we are looking for are individual.  Hence, there should be no
	// individual acknowledgements coming back if there's no outstanding
	// burst.
	//
	//
	////////////////////////////////////////////////////////////////////////

	//
	// AXI write response channel
	//
	reg	[(F_LGDEPTH-1):0]	f_wr_completed,
					f_wrid_completed;
	always @(*)
	begin
		f_wr_completed = f_axi_awr_nbursts-((f_axi_wr_pending>0) ? 1:0);
		f_wrid_completed = f_axi_wrid_nbursts
				- (f_axi_wr_ckvalid ? 1:0);

		assert(f_axi_wrid_nbursts <= f_axi_awr_nbursts);
		assert(f_wrid_completed <= f_wr_completed);
	end

	always @(*)
	if (i_axi_bvalid)
	begin
		`SLAVE_ASSERT(f_wr_completed > 0);

		if (i_axi_bid == f_axi_wr_checkid)
			`SLAVE_ASSERT(f_wrid_completed > 0);
		else // if (i_axi_bid != f_axi_wr_checkid)
			`SLAVE_ASSERT(f_wr_completed - f_wrid_completed > 0);
	end

	//
	// Cannot have outstanding values if there aren't any outstanding
	// bursts
	always @(posedge i_clk)
		assert(f_axi_wrid_nbursts <= f_axi_awr_nbursts);
	always @(posedge i_clk)
	if (f_axi_awr_nbursts == 0)
		`SLAVE_ASSERT(f_axi_wr_pending == 0);
	always @(posedge i_clk)
	if (f_axi_wr_pending == 0)
		assert(f_axi_wr_ckvalid == 0);

	//
	// Because we can't accept multiple AW* requests prior to the
	// last WVALID && WLAST, the AWREADY signal *MUST* be high while
	// waiting
	//
	always @(posedge i_clk)
	if (f_axi_wr_pending > 1)
		`SLAVE_ASSERT(!i_axi_awready);

	////////////////////////////////////////////////////////////////////////
	//
	// Write address checking
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	always @(posedge i_clk)
	begin
		if (axi_awr_req)
		begin
			f_axi_wr_burst <= i_axi_awburst;
			f_axi_wr_size  <= i_axi_awsize;
			f_axi_wr_len   <= i_axi_awlen;
		end

		if (!OPT_NARROW_BURST)
		begin
			// In this case, all size parameters are fixed.
			// Let's remove them from the solvers logic choices
			// for optimization purposes
			//
			if (DW == 8)
				f_axi_wr_size <= 0;
			else if (DW == 16)
				f_axi_wr_size <= 1;
			else if (DW == 32)
				f_axi_wr_size <= 2;
			else if (DW == 64)
				f_axi_wr_size <= 3;
			else if (DW == 128)
				f_axi_wr_size <= 4;
			else if (DW == 256)
				f_axi_wr_size <= 5;
			else if (DW == 512)
				f_axi_wr_size <= 6;
			else // if (DW == 1024)
				f_axi_wr_size <= 7;
		end
	end

	always @(*)
	begin
		awr_aligned = 1;
		case(i_axi_awsize)
		0: awr_aligned = 1;
		1: awr_aligned = (i_axi_awaddr[  0] == 0);
		2: awr_aligned = (i_axi_awaddr[((AW>1)? 1 : AW-1):0] == 0);
		3: awr_aligned = (i_axi_awaddr[((AW>2)? 2 : AW-1):0] == 0);
		4: awr_aligned = (i_axi_awaddr[((AW>3)? 3 : AW-1):0] == 0);
		5: awr_aligned = (i_axi_awaddr[((AW>4)? 4 : AW-1):0] == 0);
		6: awr_aligned = (i_axi_awaddr[((AW>5)? 5 : AW-1):0] == 0);
		7: awr_aligned = (i_axi_awaddr[((AW>6)? 6 : AW-1):0] == 0);
		endcase
	end

	always @(posedge i_clk)
	if (i_axi_awvalid && i_axi_awburst == 2'b10)
		`SLAVE_ASSUME(awr_aligned);

	always @(*)
		this_awsize = (f_axi_wr_pending>0) ? f_axi_wr_size : i_axi_awsize;
		
	faxi_addr #(.AW(AW)) get_next_waddr(
		(f_axi_wr_pending>1) ? f_axi_wr_addr  : i_axi_awaddr,
		this_awsize,
		(f_axi_wr_pending>1) ? f_axi_wr_burst: i_axi_awburst,
		(f_axi_wr_pending>1) ? f_axi_wr_len  : i_axi_awlen,
		f_axi_wr_incr, next_wr_addr);

	always @(posedge i_clk)
	if (axi_awr_req && ((f_axi_wr_pending > 0)||(!axi_wr_req)))
		r_axi_wr_addr <= i_axi_awaddr;
	else if (axi_awr_req || axi_wr_req) // && first axi_wr_req
		r_axi_wr_addr <= next_wr_addr;

	always @(posedge i_clk)
	if (i_axi_awvalid)
		// A burst type of 2'b11 is reserved, and therefore illegal
		`SLAVE_ASSUME(i_axi_awburst != 2'b11);

	always @(*)
	if (i_axi_awvalid)
		`SLAVE_ASSUME(i_axi_awlen <= OPT_MAXBURST);

	generate if (OPT_NARROW_BURST)
	begin : WR_NARROW_ASSUME

		always @(*)
		if (i_axi_awvalid)
			`SLAVE_ASSUME(DW >= (1<<(i_axi_awsize + 3)));

	end else begin : WR_SZ_ASSUME

		always @(*)
		if (i_axi_awvalid)
			`SLAVE_ASSUME(DW == (1<<(i_axi_awsize + 3)));

	end endgenerate


	//
	// Wrapped bursts can only have lengths of 2, 4, 8, or 16 transfers
	always @(posedge i_clk)
	if (i_axi_awvalid && i_axi_awburst == 2'b10)
	begin
		`SLAVE_ASSUME((i_axi_awlen == 1)
				||(i_axi_awlen == 3)
				||(i_axi_awlen == 7)
				||(i_axi_awlen == 15));
	end

	always @(*)
	if (f_axi_wr_pending > 0)
		f_axi_wr_addr = r_axi_wr_addr;
	else
		f_axi_wr_addr = i_axi_awaddr;

	//
	// The specification specifically prohibits any transaction from
	// crossing a 4kB boundary
	//
	generate if (AW >= 12)
	begin : BOUNDARY_WRAP_WR_INITIAL
		reg	[AW-1:0]	last_addr;
		always @(*)
			last_addr = i_axi_awaddr +(i_axi_awlen << i_axi_awsize);

		always @(*)
		if (i_axi_awvalid && i_axi_awburst == 2'b01)
		begin
			`SLAVE_ASSUME(i_axi_awaddr[AW-1:12] == last_addr[AW-1:12]);
		end
	end endgenerate

	//
	generate begin
		// Insist the only the appropriate bits be valid
		// For example, if the lower address bit is one, then the
		// strobe LSB cannot be 1, but must be zero.  This is just
		// enforcing the rules of the sub-address which must match
		// the write strobe.  An STRB of 0 is always allowed.
		//
		always @(*)
		begin
			strb_mask = 1;
			case(this_awsize)
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
				strb_mask = strb_mask << f_axi_wr_addr[0];
			if (DW == 32)
				strb_mask = strb_mask << f_axi_wr_addr[1:0];
			if (DW == 64)
				strb_mask = strb_mask << f_axi_wr_addr[2:0];
			if (DW == 128)
				strb_mask = strb_mask << f_axi_wr_addr[3:0];
			if (DW == 256)
				strb_mask = strb_mask << f_axi_wr_addr[4:0];
			if (DW == 512)
				strb_mask = strb_mask << f_axi_wr_addr[5:0];
			if (DW == 1024)
				strb_mask = strb_mask << f_axi_wr_addr[6:0];

			if (i_axi_wvalid && (f_axi_wr_pending > 0))
				`SLAVE_ASSUME((i_axi_wstrb & ~strb_mask) == 0);
		end
	end endgenerate

	//
	// Write induction properties
	//
	// These are actual assert()s and not `SLAVE_ASSERT or `SLAVE_ASSUMEs
	// because they are testing the functionality of this core and its local
	// logical registers, not so much the functionality of the core we are
	// testing
	//
	always @(*)
	if (f_axi_wr_pending > 0)
	begin
		assert(f_axi_wr_burst != 2'b11);
		if (f_axi_wr_burst == 2'b10)
		begin
			assert((f_axi_wr_len ==  1)
				||(f_axi_wr_len ==  3)
				||(f_axi_wr_len ==  7)
				||(f_axi_wr_len == 15));
		end
	end

	always @(*)
	if (f_axi_wr_pending > 0)
		assert(f_axi_wr_len <= OPT_MAXBURST);

	always @(*)
	begin
		wr_aligned = 1;
		case(f_axi_wr_size)
		0: wr_aligned = 1;
		1: wr_aligned = (f_axi_wr_addr[  0] == 0);
		2: wr_aligned = (f_axi_wr_addr[((AW>1)? 1 : AW-1):0] == 0);
		3: wr_aligned = (f_axi_wr_addr[((AW>2)? 2 : AW-1):0] == 0);
		4: wr_aligned = (f_axi_wr_addr[((AW>3)? 3 : AW-1):0] == 0);
		5: wr_aligned = (f_axi_wr_addr[((AW>4)? 4 : AW-1):0] == 0);
		6: wr_aligned = (f_axi_wr_addr[((AW>5)? 5 : AW-1):0] == 0);
		7: wr_aligned = (f_axi_wr_addr[((AW>6)? 6 : AW-1):0] == 0);
		endcase
	end

	always @(*)
	if (f_axi_wr_pending > 0 && f_axi_wr_burst == 2'b10)
		assert(wr_aligned);

	//
	// The specification specifically prohibits any transaction from
	// crossing a 4kB boundary
	//
	generate if (AW >= 12)
	begin : BOUNDARY_WRAP_WR_INDUCTION
		reg	[AW-1:0]	last_addr;
		always @(*)
			last_addr = f_axi_wr_addr + ((f_axi_wr_pending-1) << f_axi_wr_size);

		always @(*)
		if ((f_axi_wr_pending > 0)&&(f_axi_wr_burst == 2'b01))
		begin
			assert(f_axi_wr_addr[AW-1:12] == last_addr[AW-1:12]);
		end
	end endgenerate

	generate if (OPT_NARROW_BURST)
	begin : WR_NARROW_ASSERT

		always @(*)
		if (f_axi_wr_pending > 0)
			assert(DW >= (1<<(f_axi_wr_size + 3)));

	end else begin : WR_SZ_ASSERT

		always @(*)
		if (f_axi_wr_pending > 0)
			assert(DW == (1<<(f_axi_wr_size + 3)));

	end endgenerate


	////////////////////////////////////////////////////////////////////////
	//
	// Read address checking
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	wire	check_this_read_burst;
	assign	check_this_read_burst = (i_axi_reset_n
				&& !f_axi_rd_ckvalid && f_axi_rd_check
				&& i_axi_arid == f_axi_rd_checkid
				&& axi_ard_req
				&& F_OPT_READCHECK);
	wire	check_this_return;
	assign	check_this_return = (i_axi_reset_n
				&& f_axi_rd_ckvalid
				&& i_axi_arid == f_axi_rd_checkid
				&& (f_axi_rdid_ckign_nbursts == 0)
				&& i_axi_rvalid);

	always @(*)
	if (!f_axi_rd_ckvalid || f_axi_rdid_ckign_nbursts != 0)
		rd_pending = 0;
	else
		rd_pending = (f_axi_rd_cklen > 0);

	faxi_addr #(.AW(AW)) get_next_raddr(
		f_axi_rd_ckaddr,
		f_axi_rd_cksize,
		f_axi_rd_ckburst,
		f_axi_rd_ckarlen,
		f_axi_rd_ckincr, next_rd_addr);

	always @(*)
	if (i_axi_arvalid)
		`SLAVE_ASSUME(i_axi_arlen <= OPT_MAXBURST);

	always @(posedge i_clk)
	begin
		if (check_this_read_burst)
		begin
			f_axi_rd_ckburst <= i_axi_arburst;
			f_axi_rd_cksize  <= i_axi_arsize;
			f_axi_rd_ckarlen <= i_axi_arlen;
			f_axi_rd_ckaddr  <= i_axi_araddr;
		end else if (check_this_return && axi_rd_ack)
		begin
			f_axi_rd_ckaddr <= next_rd_addr;
		end

		if (!OPT_NARROW_BURST)
		begin
			// In this case, all size parameters are fixed.
			// Let's remove them from the solvers logic choices
			// for optimization purposes
			//
			if (DW == 8)
				f_axi_rd_cksize <= 0;
			else if (DW == 16)
				f_axi_rd_cksize <= 1;
			else if (DW == 32)
				f_axi_rd_cksize <= 2;
			else if (DW == 64)
				f_axi_rd_cksize <= 3;
			else if (DW == 128)
				f_axi_rd_cksize <= 4;
			else if (DW == 256)
				f_axi_rd_cksize <= 5;
			else if (DW == 512)
				f_axi_rd_cksize <= 6;
			else // if (DW == 1024)
				f_axi_rd_cksize <= 7;
		end
	end

	always @(posedge i_clk)
	if (i_axi_arvalid)
		// A burst type of 2'b11 is reserved, and therefore illegal
		`SLAVE_ASSUME(i_axi_arburst != 2'b11);

	always @(posedge i_clk)
	if (i_axi_arvalid)
	begin
		if (DW <= 8)
			`SLAVE_ASSUME(i_axi_arsize == 0);
		else if (DW <= 16)
			`SLAVE_ASSUME(i_axi_arsize <= 1);
		else if (DW <= 32)
			`SLAVE_ASSUME(i_axi_arsize <= 2);
		else if (DW <= 64)
			`SLAVE_ASSUME(i_axi_arsize <= 3);
		else if (DW <= 128)
			`SLAVE_ASSUME(i_axi_arsize <= 4);
		else if (DW <= 256)
			`SLAVE_ASSUME(i_axi_arsize <= 5);
		else if (DW <= 512)
			`SLAVE_ASSUME(i_axi_arsize <= 6);
	end

	//
	// The specification specifically prohibits any transaction from
	// crossing a 4kB boundary
	//
	generate if (AW >= 12)
	begin : BOUNDARY_WRAP_RD_INITIAL
		reg	[AW-1:0]	last_addr;
		always @(*)
			last_addr = i_axi_araddr +(i_axi_arlen << i_axi_arsize);

		always @(*)
		if (i_axi_arvalid && i_axi_arburst == 2'b01)
		begin
			`SLAVE_ASSUME(i_axi_araddr[AW-1:12] == last_addr[AW-1:12]);
		end
	end endgenerate

	always @(*)
	begin
		ard_aligned = 1;
		case(i_axi_arsize)
		0: ard_aligned = 1;
		1: ard_aligned = (i_axi_araddr[  0] == 0);
		2: ard_aligned = (i_axi_araddr[((AW>1)? 1 : AW-1):0] == 0);
		3: ard_aligned = (i_axi_araddr[((AW>2)? 2 : AW-1):0] == 0);
		4: ard_aligned = (i_axi_araddr[((AW>3)? 3 : AW-1):0] == 0);
		5: ard_aligned = (i_axi_araddr[((AW>4)? 4 : AW-1):0] == 0);
		6: ard_aligned = (i_axi_araddr[((AW>5)? 5 : AW-1):0] == 0);
		7: ard_aligned = (i_axi_araddr[((AW>6)? 6 : AW-1):0] == 0);
		endcase
	end

	// Insist on initial alignment for any WRAP transactions
	always @(*)
	if (i_axi_arvalid && i_axi_arburst == 2'b10)
		`SLAVE_ASSUME(ard_aligned);

	// Wrapped bursts can only have lengths of 2, 4, 8, or 16 transfers
	always @(posedge i_clk)
	if (i_axi_arvalid && i_axi_arburst == 2'b10)
	begin
		`SLAVE_ASSUME((i_axi_arlen == 1)
				||(i_axi_arlen == 3)
				||(i_axi_arlen == 7)
				||(i_axi_arlen == 15));
	end

	generate if (OPT_NARROW_BURST)
	begin : RD_NARROW_ASSUME
		always @(*)
		if (i_axi_arvalid)
			`SLAVE_ASSUME(DW >= (1<<(i_axi_arsize+3)));
	end else begin : RD_SZ_ASSUME
		always @(*)
		if (i_axi_arvalid)
			`SLAVE_ASSUME(DW == (1<<(i_axi_arsize+3)));
	end endgenerate


	//
	// Read induction properties
	//
	// These are actual assert()s and not `SLAVE_ASSERT or `SLAVE_ASSUMEs
	// because they are testing the functionality of this core and its local
	// logical registers, not so much the functionality of the core we are
	// testing
	//
	always @(*)
	if (f_axi_rd_ckvalid)
	begin
		assert(f_axi_rd_ckburst != 2'b11);
		if (f_axi_rd_ckburst == 2'b10)
		begin
			assert((f_axi_rd_ckarlen ==  1)
				||(f_axi_rd_ckarlen ==  3)
				||(f_axi_rd_ckarlen ==  7)
				||(f_axi_rd_ckarlen == 15));
		end
	end

	always @(*)
	if ((f_axi_rd_ckvalid > 0) && (OPT_MAXBURST < 8'hff))
		assert(f_axi_rd_cklen <= OPT_MAXBURST+1);

	//
	// The specification specifically prohibits any transaction from
	// crossing a 4kB boundary
	//
	generate if (AW >= 12)
	begin : BOUNDARY_WRAP_RD_INDUCTION
		reg	[AW-1:0]	last_addr;
		always @(*)
			last_addr = f_axi_rd_ckaddr + ((f_axi_rd_cklen-1) << f_axi_rd_cksize);

		always @(*)
		if (f_axi_rd_ckvalid && f_axi_rd_ckburst == 2'b01
				&& (f_axi_rd_cklen > 2))
			assert(f_axi_rd_ckaddr[AW-1:12] == last_addr[AW-1:12]);

	end endgenerate

	generate if (OPT_NARROW_BURST)
	begin : RD_NARROW_ASSERT

		always @(*)
		if (f_axi_rd_ckvalid > 0)
			assert(DW >= (1<<(f_axi_rd_cksize + 3)));
	end else begin : RD_SZ_ASSERT
		always @(*)
		if (f_axi_rd_ckvalid > 0)
			assert(DW == (1<<(f_axi_rd_cksize + 3)));
	end endgenerate


	always @(*)
	if (f_axi_rd_ckvalid)
		assert(f_axi_rd_cklen <= f_axi_rd_ckarlen+1);

	always @(*)
	begin
		rd_aligned = 1;
		case(f_axi_rd_cksize)
		0: rd_aligned = 1;
		1: rd_aligned = (f_axi_rd_ckaddr[  0] == 0);
		2: rd_aligned = (f_axi_rd_ckaddr[((AW>1)? 1 : AW-1):0] == 0);
		3: rd_aligned = (f_axi_rd_ckaddr[((AW>2)? 2 : AW-1):0] == 0);
		4: rd_aligned = (f_axi_rd_ckaddr[((AW>3)? 3 : AW-1):0] == 0);
		5: rd_aligned = (f_axi_rd_ckaddr[((AW>4)? 4 : AW-1):0] == 0);
		6: rd_aligned = (f_axi_rd_ckaddr[((AW>5)? 5 : AW-1):0] == 0);
		7: rd_aligned = (f_axi_rd_ckaddr[((AW>6)? 6 : AW-1):0] == 0);
		endcase
	end

	always @(*)
	if (f_axi_rd_ckvalid && f_axi_rd_cklen <= f_axi_rd_ckarlen
			&& f_axi_rd_ckburst != 2'b00)
		assert(rd_aligned);

	////////////////////////////////////////////////////////////////////////
	//
	// Exclusive properties
	//
	////////////////////////////////////////////////////////////////////////
	generate if (!OPT_EXCLUSIVE)
	begin : EXCLUSIVE_DISALLOWED
		localparam [1:0]	EXOKAY = 2'b01;

		//
		// Without exclusive access support, the master shall not issue
		// exclusive access requests
		always @(*)
		begin
		`SLAVE_ASSUME(!i_axi_awvalid || !i_axi_awlock);
		`SLAVE_ASSUME(!i_axi_arvalid || !i_axi_arlock);
		end

		// Similarly, without exclusive access support, the slave
		// shall not respond with an okay indicating that exclusive
		// access was supported.
		always @(*)
		begin
		`SLAVE_ASSERT(!i_axi_bvalid || i_axi_bresp != EXOKAY);
		`SLAVE_ASSERT(!i_axi_rvalid || i_axi_rresp != EXOKAY);
		end

	end else begin : EXCLUSIVE_ACCESS_CHECKER

		//
		// 1. Exclusive access burst lengths max out at 16
		// 2. Exclusive access bursts must be aligned
		// 3. Write must take place when the read channel is idle (on
		//	this ID)
		// (4. Further read accesses on this ID are not allowed)
		//
		always @(*)
		if (i_axi_awvalid && i_axi_awlock)
		begin
			`SLAVE_ASSUME(i_axi_awlen < 16);
			`SLAVE_ASSUME(awr_aligned);
			`SLAVE_ASSUME(!i_axi_awcache[0]);
			if (f_axi_wr_checkid == f_axi_rd_checkid)
				`SLAVE_ASSUME(f_axi_rdid_nbursts == 0);
			`SLAVE_ASSUME(f_axi_wrid_nbursts == 0);
		end

		always @(*)
		if (i_axi_arvalid && i_axi_arlock)
		begin
			`SLAVE_ASSUME(i_axi_arlen < 16);
			`SLAVE_ASSUME(ard_aligned);
			`SLAVE_ASSUME(!i_axi_arcache[0]);
		end

	end endgenerate

	////////////////////////////////////////////////////////////////////////
	//
	// Xilinx extensions
	//
	////////////////////////////////////////////////////////////////////////

	////////////////////////////////////////////////////////////////////////
	//
	// Option for no bursts, only single transactions
	//
	////////////////////////////////////////////////////////////////////////

	generate if (!F_OPT_BURSTS)
	begin

		always @(posedge i_clk)
		if (i_axi_awvalid)
			`SLAVE_ASSUME(i_axi_awlen == 0);

		always @(posedge i_clk)
		if (i_axi_wvalid)
			`SLAVE_ASSUME(i_axi_wlast);

		always @(posedge i_clk)
		if (i_axi_arvalid)
			`SLAVE_ASSUME(i_axi_arlen == 0);

		always @(*)
		if (i_axi_rvalid)
			`SLAVE_ASSERT(i_axi_rlast);

		always @(*)
			`SLAVE_ASSERT(f_axi_rd_nbursts == f_axi_rd_outstanding);
	end endgenerate


	////////////////////////////////////////////////////////////////////////
	//
	// Packet read checking
	//
	// Pick a read address request, and then track that one transaction
	// through the system
	//
	////////////////////////////////////////////////////////////////////////


	initial	f_axi_rdid_ckign_nbursts = 0;
	initial	f_axi_rdid_ckign_outstanding = 0;
	initial	f_axi_rd_ckvalid = 0;
	initial	f_axi_rd_cklen = 0;
	always @(posedge i_clk)
	if (!i_axi_reset_n)
	begin
		f_axi_rdid_ckign_nbursts <= 0;
		f_axi_rdid_ckign_outstanding <= 0;
		f_axi_rd_ckvalid <= 0;
		f_axi_rd_cklen <= 0;
	end else begin

		if (check_this_read_burst)
		begin
			//
			// Decide to check the length of this burst
			//
			f_axi_rd_ckvalid <= 1'b1;
			f_axi_rdid_ckign_nbursts <= f_axi_rdid_nbursts
			  - ((i_axi_rvalid && i_axi_rready
				&& i_axi_rid == f_axi_rd_checkid
				&& i_axi_rlast) ? 1:0);

			f_axi_rdid_ckign_outstanding <= f_axi_rdid_outstanding
			  - ((i_axi_rvalid && i_axi_rready
				&& i_axi_rid == f_axi_rd_checkid) ? 1:0);

			f_axi_rd_cklen <= i_axi_arlen + 1;
		end else if (check_this_return && i_axi_rready)
		begin
			`SLAVE_ASSERT(i_axi_rlast == (f_axi_rd_cklen == 1));
			f_axi_rd_cklen <= f_axi_rd_cklen - 1;
			if (i_axi_rlast)
				f_axi_rd_ckvalid <= 1'b0;
		end else if (f_axi_rd_ckvalid && i_axi_rvalid && i_axi_rready
					&& i_axi_rid == f_axi_rd_checkid)
		begin
			if (i_axi_rlast)
				f_axi_rdid_ckign_nbursts <= f_axi_rdid_ckign_nbursts-1;
			f_axi_rdid_ckign_outstanding <= f_axi_rdid_ckign_outstanding-1;
			if (f_axi_rdid_ckign_nbursts == f_axi_rdid_ckign_outstanding && !i_axi_rlast)
				`SLAVE_ASSERT(i_axi_rid != f_axi_rd_checkid);
		end
	end

	always @(*)
	if (i_axi_rvalid && f_axi_rd_ckvalid && i_axi_rid == f_axi_rd_checkid)
	begin
		if (f_axi_rdid_ckign_nbursts == 1)
			`SLAVE_ASSERT(i_axi_rlast == (f_axi_rdid_ckign_outstanding==1));
		if ((f_axi_rdid_ckign_nbursts == f_axi_rdid_ckign_outstanding)
			&&(f_axi_rdid_ckign_nbursts > 0))
			`SLAVE_ASSERT(i_axi_rlast);
	end
	
	always @(*)
	if (f_axi_rdid_outstanding == 0)
		assert(f_axi_rdid_nbursts == 0);
	else
		assert(f_axi_rdid_nbursts > 0);
	always @(*)
	if (f_axi_rd_ckvalid)
	begin
		assert(f_axi_rdid_ckign_outstanding <= f_axi_rdid_outstanding);
		assert(f_axi_rdid_ckign_nbursts <= f_axi_rdid_nbursts);
		if (f_axi_rdid_ckign_nbursts == 0)
			assert(f_axi_rdid_ckign_outstanding == 0);
	end
	always @(*)
	if (!f_axi_rd_ckvalid)
	begin
		assert(f_axi_rd_cklen == 0);
		assert(f_axi_rdid_ckign_nbursts == 0);
		assert(f_axi_rdid_ckign_outstanding == 0);
	end else begin
		assert(f_axi_rdid_ckign_nbursts < f_axi_rdid_nbursts);
		assert(f_axi_rdid_ckign_outstanding < f_axi_rdid_outstanding);
	end

	always @(*)
	if (f_axi_rd_ckvalid && (f_axi_rdid_ckign_nbursts == 0)
		&& i_axi_rvalid && (i_axi_rid == f_axi_rd_checkid))
		`SLAVE_ASSERT(i_axi_rlast == (f_axi_rd_cklen == 1));

	always @(*)
	if (f_axi_rd_ckvalid)
		assert(f_axi_rd_cklen > 0);

	always @(*)
	if (f_axi_rd_ckvalid)
		`SLAVE_ASSERT(f_axi_rdid_ckign_nbursts +1 <= f_axi_rdid_nbursts);

	always @(*)
	if (f_axi_rd_ckvalid)
		`SLAVE_ASSERT(f_axi_rdid_ckign_outstanding + f_axi_rd_cklen
				<= f_axi_rdid_outstanding);

	always @(*)
	if ((f_axi_rd_ckvalid)&&(f_axi_rdid_ckign_nbursts +1 == f_axi_rdid_nbursts))
		`SLAVE_ASSERT(f_axi_rdid_ckign_outstanding + f_axi_rd_cklen
				== f_axi_rdid_outstanding);

	always @(*)
	if (!F_OPT_READCHECK)
	begin
		assert(f_axi_rd_cklen == 0);
		assert(f_axi_rdid_ckign_nbursts == 0);
		assert(f_axi_rdid_ckign_outstanding == 0);
	end
`undef	SLAVE_ASSUME
`undef	SLAVE_ASSERT
endmodule
