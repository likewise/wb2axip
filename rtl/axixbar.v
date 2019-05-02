////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axixbar.v
//
// Project:	Pipelined Wishbone to AXI converter
//
// Purpose:	Create a full crossbar between NM AXI sources (masters), and NS
//		AXI slaves.  Every master can talk to any slave, provided it
//	isn't already busy.
//
// Performance:	This core has been designed with the goal of being able to push
//		one transaction through the interconnect, from any master to
//	any slave, per clock cycle.  This may perhaps be its most unique
//	feature.  While throughput is good, latency is something else.
//
//	The arbiter requires a clock to switch, then another clock to send data
//	downstream.  This creates a minimum two clock latency up front.  The
//	return path suffers another clock of latency as well, placing the
//	minimum latency at four clocks.  The minimum write latency is at
//	least one clock longer, since the write data must wait for the write
//	address before proceeeding.
//
// Usage:	To use, you must first set NM and NS to the number of masters
//	and the number of slaves you wish to connect to.  You then need to
//	adjust the addresses of the slaves, found SLAVE_ADDR array.  Those
//	bits that are relevant in SLAVE_ADDR to then also be set in SLAVE_MASK.
//	Adjusting the data and address widths go without saying.
//
//	Lower numbered masters are given priority in any "fight".
//
//	Channel grants are given on the condition that 1) they are requested,
//	2) no other channel has a grant, 3) all of the responses have been
//	received from the current channel, and 4) the internal counters are
//	not overflowing.
//
//	The core limits the number of outstanding transactions on any channel to
//	1<<LGMAXBURST-1.
//
//	Channel grants are lost 1) after OPT_LINGER clocks of being idle, or
//	2) when another master requests an idle (but still lingering) channel
//	assignment, or 3) once all the responses have been returned to the
//	current channel, and the current master is requesting another channel.
//
//	A special slave is allocated for the case of no valid address.
//
//	Since the write channel has no address information, the write data
//	channel always be delayed by at least one clock from the write address
//	channel.
//
//	If OPT_LOWPOWER is set, then unused values will be set to zero.
//	This can also be used to help identify relevant values within any
//	trace.
//
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2019, Gisselquist Technology, LLC
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory, run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype none
//
module	axixbar #(
		parameter integer C_S_AXI_DATA_WIDTH = 32,
		parameter integer C_S_AXI_ADDR_WIDTH = 32,
		parameter integer C_S_AXI_ID_WIDTH = 2,
		parameter	NM = 4,
		parameter	NS = 8
		//
	) (
		input	wire	S_AXI_ACLK,
		input	wire	S_AXI_ARESETN,
		//
		input	wire	[NM*C_S_AXI_ID_WIDTH-1:0]	M_AXI_AWID,
		input	wire	[NM*C_S_AXI_ADDR_WIDTH-1:0]	M_AXI_AWADDR,
		input	wire	[NM*8-1:0]			M_AXI_AWLEN,
		input	wire	[NM*3-1:0]			M_AXI_AWSIZE,
		input	wire	[NM*2-1:0]			M_AXI_AWBURST,
		input	wire	[NM-1:0]			M_AXI_AWLOCK,
		input	wire	[NM*4-1:0]			M_AXI_AWCACHE,
		input	wire	[NM*3-1:0]			M_AXI_AWPROT,
		input	wire	[NM*4-1:0]			M_AXI_AWQOS,
		input	wire	[NM-1:0]			M_AXI_AWVALID,
		output	wire	[NM-1:0]			M_AXI_AWREADY,
		//
		input	wire	[NM*C_S_AXI_DATA_WIDTH-1:0]	M_AXI_WDATA,
		input	wire	[NM*C_S_AXI_DATA_WIDTH/8-1:0]	M_AXI_WSTRB,
		input	wire	[NM-1:0]			M_AXI_WLAST,
		input	wire	[NM-1:0]			M_AXI_WVALID,
		output	wire	[NM-1:0]			M_AXI_WREADY,
		//
		output	wire	[NM*C_S_AXI_ID_WIDTH-1:0]	M_AXI_BID,
		output	wire	[NM*2-1:0]			M_AXI_BRESP,
		output	wire	[NM-1:0]			M_AXI_BVALID,
		input	wire	[NM-1:0]			M_AXI_BREADY,
		//
		input	wire	[NM*C_S_AXI_ID_WIDTH-1:0]	M_AXI_ARID,
		input	wire	[NM*C_S_AXI_ADDR_WIDTH-1:0]	M_AXI_ARADDR,
		input	wire	[NM*8-1:0]			M_AXI_ARLEN,
		input	wire	[NM*3-1:0]			M_AXI_ARSIZE,
		input	wire	[NM*2-1:0]			M_AXI_ARBURST,
		input	wire	[NM-1:0]			M_AXI_ARLOCK,
		input	wire	[NM*4-1:0]			M_AXI_ARCACHE,
		input	wire	[NM*3-1:0]			M_AXI_ARPROT,
		input	wire	[NM*4-1:0]			M_AXI_ARQOS,
		input	wire	[NM-1:0]			M_AXI_ARVALID,
		output	wire	[NM-1:0]			M_AXI_ARREADY,
		//
		output	wire	[NM*C_S_AXI_ID_WIDTH-1:0]	M_AXI_RID,
		output	wire	[NM*C_S_AXI_DATA_WIDTH-1:0]	M_AXI_RDATA,
		output	wire	[NM*2-1:0]			M_AXI_RRESP,
		output	wire	[NM-1:0]			M_AXI_RLAST,
		output	wire	[NM-1:0]			M_AXI_RVALID,
		input	wire	[NM-1:0]			M_AXI_RREADY,
		//
		//
		//
		output	wire	[NS*C_S_AXI_ID_WIDTH-1:0]	S_AXI_AWID,
		output	wire	[NS*C_S_AXI_ADDR_WIDTH-1:0]	S_AXI_AWADDR,
		output	wire	[NS*8-1:0]			S_AXI_AWLEN,
		output	wire	[NS*3-1:0]			S_AXI_AWSIZE,
		output	wire	[NS*2-1:0]			S_AXI_AWBURST,
		output	wire	[NS-1:0]			S_AXI_AWLOCK,
		output	wire	[NS*4-1:0]			S_AXI_AWCACHE,
		output	wire	[NS*3-1:0]			S_AXI_AWPROT,
		output	wire	[NS*4-1:0]			S_AXI_AWQOS,
		output	wire	[NS-1:0]			S_AXI_AWVALID,
		input	wire	[NS-1:0]			S_AXI_AWREADY,
		//
		//
		output	wire	[NS*C_S_AXI_DATA_WIDTH-1:0]	S_AXI_WDATA,
		output	wire	[NS*C_S_AXI_DATA_WIDTH/8-1:0]	S_AXI_WSTRB,
		output	wire	[NS-1:0]			S_AXI_WLAST,
		output	wire	[NS-1:0]			S_AXI_WVALID,
		input	wire	[NS-1:0]			S_AXI_WREADY,
		//
		input	wire	[NS*C_S_AXI_ID_WIDTH-1:0]	S_AXI_BID,
		input	wire	[NS*2-1:0]			S_AXI_BRESP,
		input	wire	[NS-1:0]			S_AXI_BVALID,
		output	wire	[NS-1:0]			S_AXI_BREADY,
		//
		output	wire	[NS*C_S_AXI_ID_WIDTH-1:0]	S_AXI_ARID,
		output	wire	[NS*C_S_AXI_ADDR_WIDTH-1:0]	S_AXI_ARADDR,
		output	wire	[NS*8-1:0]			S_AXI_ARLEN,
		output	wire	[NS*3-1:0]			S_AXI_ARSIZE,
		output	wire	[NS*2-1:0]			S_AXI_ARBURST,
		output	wire	[NS-1:0]			S_AXI_ARLOCK,
		output	wire	[NS*4-1:0]			S_AXI_ARCACHE,
		output	wire	[NS*4-1:0]			S_AXI_ARQOS,
		output	wire	[NS*3-1:0]			S_AXI_ARPROT,
		output	wire	[NS-1:0]			S_AXI_ARVALID,
		input	wire	[NS-1:0]			S_AXI_ARREADY,
		//
		//
		input	wire	[NS*C_S_AXI_ID_WIDTH-1:0]	S_AXI_RID,
		input	wire	[NS*C_S_AXI_DATA_WIDTH-1:0]	S_AXI_RDATA,
		input	wire	[NS*2-1:0]			S_AXI_RRESP,
		input	wire	[NS-1:0]			S_AXI_RLAST,
		input	wire	[NS-1:0]			S_AXI_RVALID,
		output	wire	[NS-1:0]			S_AXI_RREADY
	);
	//
	// IW, AW, and DW, are short-hand abbreviations used locally.
	localparam	IW = C_S_AXI_ID_WIDTH;
	localparam	AW = C_S_AXI_ADDR_WIDTH;
	localparam	DW = C_S_AXI_DATA_WIDTH;
	//
	// SLAVE_ADDR is an array of addresses, describing each of the slave
	// channels.  It works tightly with SLAVE_MASK, so that when
	// (ADDR & MASK == ADDR), the channel in question has been requested.
	//
	// It is an internal in the setup of this core to doubly map an address,
	// such that (addr & SLAVE_MASK[k])==SLAVE_ADDR[k] for two separate
	// values of k.
	//
	// Any attempt to access an address that is a hole in this address list
	// will result in a returned xRESP value of INTERCONNECT_ERROR (2'b11)
	parameter	[NS*AW-1:0]	SLAVE_ADDR = {
		3'b111,  {(AW-3){1'b0}},
		3'b110,  {(AW-3){1'b0}},
		3'b101,  {(AW-3){1'b0}},
		3'b100,  {(AW-3){1'b0}},
		3'b011,  {(AW-3){1'b0}},
		3'b010,  {(AW-3){1'b0}},
		4'b0001, {(AW-4){1'b0}},
		4'b0000, {(AW-4){1'b0}} };
	//
	// SLAVE_MASK: is an array, much like SLAVE_ADDR, describing which of
	// the bits in SLAVE_ADDR are relevant.  It is important to maintain
	// for every slave that (~SLAVE_MASK[i] & SLAVE_ADDR[i]) == 0.
	parameter	[NS*AW-1:0]	SLAVE_MASK =
		(NS <= 1) ? { 4'b1111, {(AW-4){1'b0}}}
		: { {(NS-2){ 3'b111, {(AW-3){1'b0}} }},
			{(2){ 4'b1111, {(AW-4){1'b0}}}} };
	//
	// OPT_LOWPOWER: If set, it forces all unused values to zero, preventing
	// them from unnecessarily toggling.  This will raise the logic count
	// of the core.
	parameter [0:0]	OPT_LOWPOWER = 0;
	//
	// OPT_LINGER: Set this to the number of clocks an idle channel shall
	// be left open before being closed.  Once closed, it will take a
	// minimum of two clocks before the channel can be opened and data
	// transmitted through it again.
	parameter	OPT_LINGER = 4;
	//
	// OPT_QOS: If set, the QOS transmission values will be honored when
	// determining who wins arbitration for accessing a given slave
	parameter [0:0]	OPT_QOS = 1;
	//
	// LGMAXBURST: Specifies the log based two of the maximum number of
	// transactions that may be outstanding.  Of necessity, this must me
	// more than 8.
	parameter	LGMAXBURST = 9;
	//
	//
	// Local parameters, derived from those above
	localparam	LGLINGER = (OPT_LINGER>1) ? $clog2(OPT_LINGER+1) : 1;
	//
	localparam	LGNM = (NM>1) ? $clog2(NM) : 1;
	localparam	LGNS = (NS>1) ? $clog2(NS+1) : 1;
	//
	// In order to use indexes, and hence fully balanced mux trees, it helps
	// to make certain that we have a power of two based lookup.  NMFULL
	// is the number of masters in this lookup, with potentially some
	// unused extra ones.  NSFULL is defined similarly.
	localparam	NMFULL = (NM>1) ? (1<<LGNM) : 1;
	localparam	NSFULL = (NS>1) ? (1<<LGNS) : 2;
	//
	localparam [1:0] INTERCONNECT_ERROR = 2'b11;

	genvar	N,M;
	integer	iN, iM;

	reg	[NSFULL-1:0]	wrequest		[0:NM-1];
	reg	[NSFULL-1:0]	rrequest		[0:NM-1];
	reg	[NSFULL-1:0]	wrequested		[0:NM];
	reg	[NSFULL-1:0]	rrequested		[0:NM];
	reg	[NS:0]		wgrant			[0:NM-1];
	reg	[NS:0]		rgrant			[0:NM-1];
	reg	[NM-1:0]	mwgrant;
	reg	[NM-1:0]	mrgrant;
	reg	[NS-1:0]	swgrant;
	reg	[NS-1:0]	srgrant;

	// verilator lint_off UNUSED
	wire	[LGMAXBURST-1:0]	w_mawpending	[0:NM-1];
	wire	[LGMAXBURST-1:0]	w_mwpending	[0:NM-1];
	wire	[LGMAXBURST-1:0]	w_mrpending	[0:NM-1];
	// verilator lint_on  UNUSED
	reg	[NM-1:0]		mwfull;
	reg	[NM-1:0]		mrfull;
	reg	[NM-1:0]		mwnearfull;
	reg	[NM-1:0]		mrnearfull;
	reg	[NM-1:0]		mwempty;
	reg	[NM-1:0]		mrempty;
	//
	reg	[LGNS-1:0]		mwindex	[0:NMFULL-1];
	reg	[LGNS-1:0]		mrindex	[0:NMFULL-1];
	reg	[LGNM-1:0]		swindex	[0:NSFULL-1];
	reg	[LGNM-1:0]		srindex	[0:NSFULL-1];

	(* keep *) reg	[NM-1:0]		wdata_expected;

	// The skid buffers
	reg	[NMFULL-1:0]	r_awvalid, r_wvalid, r_arvalid;

	reg	[C_S_AXI_ID_WIDTH-1:0]		r_awid		[0:NMFULL-1];
	reg	[C_S_AXI_ADDR_WIDTH-1:0]	r_awaddr	[0:NMFULL-1];
	reg	[7:0]				r_awlen		[0:NMFULL-1];
	reg	[2:0]				r_awsize	[0:NMFULL-1];
	reg	[1:0]				r_awburst	[0:NMFULL-1];
	reg	[0:0]				r_awlock	[0:NMFULL-1];
	reg	[3:0]				r_awcache	[0:NMFULL-1];
	reg	[2:0]				r_awprot	[0:NMFULL-1];
	reg	[3:0]				r_awqos		[0:NMFULL-1];
	//
	reg	[C_S_AXI_ID_WIDTH-1:0]		r_wid		[0:NMFULL-1];
	reg	[C_S_AXI_DATA_WIDTH-1:0]	r_wdata		[0:NMFULL-1];
	reg	[C_S_AXI_DATA_WIDTH/8-1:0]	r_wstrb		[0:NMFULL-1];
	reg	[0:0]				r_wlast		[0:NMFULL-1];

	reg	[C_S_AXI_ID_WIDTH-1:0]		r_arid		[0:NMFULL-1];
	reg	[C_S_AXI_ADDR_WIDTH-1:0]	r_araddr	[0:NMFULL-1];
	reg	[8-1:0]				r_arlen		[0:NMFULL-1];
	reg	[3-1:0]				r_arsize	[0:NMFULL-1];
	reg	[2-1:0]				r_arburst	[0:NMFULL-1];
	reg	[NMFULL-1:0]			r_arlock;
	reg	[4-1:0]				r_arcache	[0:NMFULL-1];
	reg	[2:0]				r_arprot	[0:NMFULL-1];
	reg	[3:0]				r_arqos		[0:NMFULL-1];
		//
	//

	// The shadow buffers
	reg	[NMFULL-1:0]	m_awvalid, m_wvalid, m_arvalid;

	reg	[C_S_AXI_ID_WIDTH-1:0]		m_awid		[0:NMFULL-1];
	reg	[C_S_AXI_ADDR_WIDTH-1:0]	m_awaddr	[0:NMFULL-1];
	reg	[7:0]				m_awlen		[0:NMFULL-1];
	reg	[2:0]				m_awsize	[0:NMFULL-1];
	reg	[1:0]				m_awburst	[0:NMFULL-1];
	reg	[0:0]				m_awlock	[0:NMFULL-1];
	reg	[3:0]				m_awcache	[0:NMFULL-1];
	reg	[2:0]				m_awprot	[0:NMFULL-1];
	reg	[3:0]				m_awqos		[0:NMFULL-1];
	//
	//
	reg	[C_S_AXI_ID_WIDTH-1:0]		m_wid		[0:NMFULL-1];
	reg	[C_S_AXI_DATA_WIDTH-1:0]	m_wdata		[0:NMFULL-1];
	reg	[C_S_AXI_DATA_WIDTH/8-1:0]	m_wstrb		[0:NMFULL-1];
	reg	[0:0]				m_wlast		[0:NMFULL-1];

	reg	[C_S_AXI_ID_WIDTH-1:0]		m_arid		[0:NMFULL-1];
	reg	[C_S_AXI_ADDR_WIDTH-1:0]	m_araddr	[0:NMFULL-1];
	reg	[NM*8-1:0]			m_arlen		[0:NMFULL-1];
	reg	[NM*3-1:0]			m_arsize	[0:NMFULL-1];
	reg	[NM*2-1:0]			m_arburst	[0:NMFULL-1];
	reg	[NM-1:0]			m_arlock	[0:NMFULL-1];
	reg	[NM*4-1:0]			m_arcache	[0:NMFULL-1];
	reg	[2:0]				m_arprot	[0:NMFULL-1];
	reg	[3:0]				m_arqos		[0:NMFULL-1];
	//

	reg	[NSFULL-1:0]	s_axi_awvalid;
	reg	[NSFULL-1:0]	s_axi_awready;
	reg	[IW-1:0]	s_axi_awid	[0:NSFULL-1];
	reg	[7:0]		s_axi_awlen	[0:NSFULL-1];

	reg	[NSFULL-1:0]	s_axi_wvalid;
	reg	[NSFULL-1:0]	s_axi_wready;
	reg	[NSFULL-1:0]	s_axi_bvalid;
	reg	[NSFULL-1:0]	s_axi_bready;
	reg	[1:0]		s_axi_bresp	[0:NSFULL-1];
	reg	[IW-1:0]	s_axi_bid	[0:NSFULL-1];

	reg	[NSFULL-1:0]	s_axi_arvalid;
	reg	[7:0]		s_axi_arlen	[0:NSFULL-1];
	reg	[IW-1:0]	s_axi_arid	[0:NSFULL-1];
	// Verilator lint_off UNUSED
	reg	[NSFULL-1:0]	s_axi_arready;
	// Verilator lint_on  UNUSED
	reg	[NSFULL-1:0]	s_axi_rvalid;
	// Verilator lint_off UNUSED
	reg	[NSFULL-1:0]	s_axi_rready;
	// Verilator lint_on  UNUSED

	reg	[DW-1:0]	s_axi_rdata	[0:NSFULL-1];
	reg	[1:0]		s_axi_rresp	[0:NSFULL-1];
	reg	[IW-1:0]	s_axi_rid	[0:NSFULL-1];
	reg	[NSFULL-1:0]	s_axi_rlast;

	reg	[NM-1:0]	slave_awaccepts;
	reg	[NM-1:0]	slave_waccepts;
	reg	[NM-1:0]	slave_raccepts;

	always @(*)
	begin
		s_axi_awvalid = -1;
		s_axi_awready = -1;
		s_axi_wvalid = -1;
		s_axi_wready = -1;
		s_axi_bvalid = 0;
		s_axi_bready = -1;

		s_axi_awvalid[NS-1:0] = S_AXI_AWVALID;
		s_axi_awready[NS-1:0] = S_AXI_AWREADY;
		s_axi_wvalid[NS-1:0]  = S_AXI_WVALID;
		s_axi_wready[NS-1:0]  = S_AXI_WREADY;
		s_axi_bvalid[NS-1:0]  = S_AXI_BVALID;
		s_axi_bready[NS-1:0]  = S_AXI_BREADY;

		for(iM=0; iM<NS; iM=iM+1)
		begin
			s_axi_awid[iM]  = S_AXI_AWID[ iM*IW +: IW];
			s_axi_awlen[iM] = S_AXI_AWLEN[iM* 8 +:  8];

			s_axi_bid[iM]   = S_AXI_BID[iM* IW +:  IW];
			s_axi_bresp[iM] = S_AXI_BRESP[iM* 2 +:  2];

			s_axi_rid[iM]   = S_AXI_RID[  iM*IW +: IW];
			s_axi_rdata[iM] = S_AXI_RDATA[iM*DW +: DW];
			s_axi_rresp[iM] = S_AXI_RRESP[iM* 2 +:  2];
			s_axi_rlast[iM] = S_AXI_RLAST[iM];
		end
		for(iM=NS; iM<NSFULL; iM=iM+1)
		begin
			s_axi_awid[iM]  = 0;
			s_axi_awlen[iM] = 0;

			s_axi_bresp[iM] = INTERCONNECT_ERROR;
			s_axi_bid[iM]   = 0;

			s_axi_rid[iM]   = 0;
			s_axi_rdata[iM] = 0;
			s_axi_rresp[iM] = INTERCONNECT_ERROR;
			s_axi_rlast[iM] = 1;
		end
	end

	generate for(N=0; N<NM; N=N+1)
	begin : DECODE_WRITE_REQUEST
		reg	none_sel;

		always @(*)
		begin
			none_sel = 1'b1;
			for(iM=0; iM<NS; iM=iM+1)
			begin
				if (((m_awaddr[N]^SLAVE_ADDR[iM*AW +:AW])
						& SLAVE_MASK[iM*AW +: AW])==0)
					none_sel = 1'b0;
			end
			if (!m_awvalid[N])
				none_sel = 1'b0;
		end


		always @(*)
		begin
			wrequest[N] = 0;
			for(iM=0; iM<NS; iM=iM+1)
				wrequest[N][iM] = m_awvalid[N]
					&&(((m_awaddr[N]^ SLAVE_ADDR[iM*AW+:AW])
						& SLAVE_MASK[iM*AW +: AW])==0);
			wrequest[N][NS] = m_awvalid[N] && none_sel;
		end

		always @(*)
		begin
			slave_awaccepts[N] = 1'b1;
			if (!mwgrant[N])
				slave_awaccepts[N] = 1'b0;
			if (mwnearfull[N])
				slave_awaccepts[N] = 1'b0;
			if (!wrequest[N][mwindex[N]])
				slave_awaccepts[N] = 1'b0;
			if (mwindex[N] != NS)
			begin
				if ((s_axi_awvalid[mwindex[N]] && !s_axi_awready[mwindex[N]]))
					slave_awaccepts[N] = 1'b0;
				if ((s_axi_wvalid[mwindex[N]] && !s_axi_wready[mwindex[N]]))
					slave_awaccepts[N] = 1'b0;
			end else if (M_AXI_BVALID[N] && !M_AXI_BREADY[N])
			begin
				// Can't accept an write address channel
				// value if the B* channel is stalled, lest
				// we lose the ID of the transaction
				slave_awaccepts[N] = 1'b0;
			end
			// ERRORs are always accepted
			//	back pressure is handled in the write side
		end

		always @(*)
		begin
			slave_waccepts[N] = 1'b1;
			if (!mwgrant[N])
				slave_waccepts[N] = 1'b0;
			// if ((!wdata_expected[N]) && (!slave_awaccepts[N]))
			//	slave_waccepts[N] = 1'b0;
			if (!wdata_expected[N])
				slave_waccepts[N] = 1'b0;
			if ((mwindex[N] != NS)
					&&(s_axi_wvalid[mwindex[N]]
						&& !s_axi_wready[mwindex[N]]))
				slave_waccepts[N] = 1'b0;
			if ((mwindex[N] == NS)
					&&(M_AXI_BVALID[N] && !M_AXI_BREADY[N]))
				slave_waccepts[N] = 1'b0;
		end

		initial	r_awvalid[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			r_awvalid[N] <= 0;
		else if (r_awvalid[N])
		begin
			if (slave_awaccepts[N])
				r_awvalid[N] <= 1'b0;
		end else if (M_AXI_AWVALID[N] && M_AXI_AWREADY[N])
		begin
			if (slave_awaccepts[N])
				r_awvalid[N] <= 1'b0;
			else
				r_awvalid[N] <= 1'b1;
		end


		initial	r_wvalid[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			r_wvalid[N] <= 0;
		else if (r_wvalid[N])
		begin
			if (slave_waccepts[N])
				r_wvalid[N] <= 1'b0;
		end else if (M_AXI_WVALID[N] && M_AXI_WREADY[N])
		begin
			if (slave_waccepts[N])
				r_wvalid[N] <= 1'b0;
			else
				r_wvalid[N] <= 1'b1;
		end


		always @(*)
		if (mwfull[N])
			m_awvalid[N] = 1'b0;
		else if (r_awvalid[N])
			m_awvalid[N] = 1'b1;
		else if (mwnearfull[N])
			m_awvalid[N] = (M_AXI_AWVALID[N] && M_AXI_AWREADY[N]);
		else
			m_awvalid[N] = (M_AXI_AWVALID[N] && M_AXI_AWREADY[N]);

		always @(*)
		if (r_awvalid[N])
		begin
			m_awid[N]    = r_awid[N];
			m_awaddr[N]  = r_awaddr[N];
			m_awlen[N]   = r_awlen[N];
			m_awsize[N]  = r_awsize[N];
			m_awburst[N] = r_awburst[N];
			m_awlock[N]  = r_awlock[N];
			m_awcache[N] = r_awcache[N];
			m_awprot[N]  = r_awprot[N];
			m_awqos[N]   = r_awqos[N];
		end else begin
			m_awid[N]    = M_AXI_AWID[   N*IW+: IW];
			m_awaddr[N]  = M_AXI_AWADDR[ N*AW+: AW];
			m_awlen[N]   = M_AXI_AWLEN[  N* 8 +: 8];
			m_awsize[N]  = M_AXI_AWSIZE[ N* 3 +: 3];
			m_awburst[N] = M_AXI_AWBURST[N* 2 +: 2];
			m_awlock[N]  = M_AXI_AWLOCK[ N];
			m_awcache[N] = M_AXI_AWCACHE[N* 4 +: 2];
			m_awprot[N]  = M_AXI_AWPROT[ N* 3 +: 3];
			m_awqos[N]   = M_AXI_AWQOS[  N* 4 +: 4];
		end

		always @(*)
		begin
			m_wvalid[N] = r_wvalid[N];
			if (M_AXI_WVALID[N] && M_AXI_WREADY[N])
				m_wvalid[N] = 1'b1;
		end

		always @(*)
		if (m_awvalid[N] && m_wvalid[N] && !wdata_expected)
			m_wid[N] = m_awid[N];
		else
			m_wid[N] = r_wid[N];

		always @(*)
		if (r_wvalid[N])
		begin
			m_wdata[N] = r_wdata[N];
			m_wstrb[N] = r_wstrb[N];
			m_wlast[N] = r_wlast[N];
		end else begin
			m_wdata[N] = M_AXI_WDATA[N*DW+:DW];
			m_wstrb[N] = M_AXI_WSTRB[N*DW/8+:DW/8];
			m_wlast[N] = M_AXI_WLAST[N];
		end

	end for (N=NM; N<NMFULL; N=N+1)
	begin : UNUSED_WSKID_BUFFERS

		always @(*)
		begin
			m_awid[N]    = 0;
			m_awaddr[N]  = 0;
			m_awlen[N]   = 0;
			m_awsize[N]  = 0;
			m_awburst[N] = 0;
			m_awlock[N]  = 0;
			m_awcache[N] = 0;
			m_awprot[N]  = 0;
			m_awqos[N]   = 0;
			m_awvalid[N] = 0;
		end
		//
		always @(*)
			m_wdata[N] = 0;
		always @(*)
			m_wstrb[N] = 0;
		always @(*)
			m_wlast[N] = 0;

	end endgenerate

	generate for(N=0; N<NM; N=N+1)
	begin : DECODE_READ_REQUEST
		reg	none_sel;

		always @(*)
		begin
			none_sel = 1'b1;
			for(iM=0; iM<NS; iM=iM+1)
			begin
				if (((m_araddr[N]^SLAVE_ADDR[iM*AW +:AW])
						& SLAVE_MASK[iM*AW +: AW])==0)
					none_sel = 1'b0;
			end
			if (!m_arvalid[N])
				none_sel = 1'b0;
		end


		always @(*)
		begin
			rrequest[N] = 0;
			for(iM=0; iM<NS; iM=iM+1)
				rrequest[N][iM] = m_arvalid[N]
					&&(((m_araddr[N]^ SLAVE_ADDR[iM*AW+:AW])
						& SLAVE_MASK[iM*AW +: AW])==0);
			rrequest[N][NS] = m_arvalid[N] && none_sel;
		end

		always @(*)
		begin
			slave_raccepts[N] = 1'b1;
			if (!mrgrant[N])
				slave_raccepts[N] = 1'b0;
			if (mrnearfull[N])
				slave_raccepts[N] = 1'b0;
			// verilator lint_off  WIDTH
			if (!rrequest[N][mrindex[N]])
				slave_raccepts[N] = 1'b0;
			// verilator lint_on  WIDTH
			if ((mrindex[N] != NS)&&(s_axi_arvalid[mrindex[N]] && !s_axi_arready[mrindex[N]]))
				slave_raccepts[N] = 1'b0;
			if ((mrindex[N] == NS)&&(M_AXI_RVALID[N] && !M_AXI_RREADY[N]))
				slave_raccepts[N] = 1'b0;
		end

		initial	r_arvalid[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			r_arvalid[N] <= 0;
		else if (r_arvalid[N])
		begin
			if (slave_raccepts[N])
				r_arvalid[N] <= 1'b0;
		end else if (M_AXI_ARVALID[N] && M_AXI_ARREADY[N])
		begin
			if (slave_raccepts[N])
				r_arvalid[N] <= 1'b0;
			else
				r_arvalid[N] <= 1'b1;
		end


		always @(*)
		if (mrfull[N])
			m_arvalid[N] = 1'b0;
		else if (mrnearfull[N])
			m_arvalid[N] = M_AXI_ARVALID[N] && !r_arvalid[N];
		else
			m_arvalid[N] = M_AXI_ARVALID[N] || r_arvalid[N];

		always @(*)
		if (r_arvalid[N])
		begin
			m_arid[N]    = r_arid[N];
			m_araddr[N]  = r_araddr[N];
			m_arlen[N]   = r_arlen[N];
			m_arsize[N]  = r_arsize[N];
			m_arburst[N] = r_arburst[N];
			m_arlock[N]  = r_arlock[N];
			m_arcache[N] = r_arcache[N];
			m_arprot[N]  = r_arprot[N];
			m_arqos[N]   = r_arqos[N];
		end else begin
			m_arid[N]    = M_AXI_ARID[   N*IW +: IW];
			m_araddr[N]  = M_AXI_ARADDR[ N*AW +: AW];
			m_arlen[N]   = M_AXI_ARLEN[  N* 8 +:  8];
			m_arsize[N]  = M_AXI_ARSIZE[ N* 3 +:  3];
			m_arburst[N] = M_AXI_ARBURST[N* 2 +:  2];
			m_arlock[N]  = M_AXI_ARLOCK[ N];
			m_arcache[N] = M_AXI_ARCACHE[N* 4 +:  4];
			m_arprot[N]  = M_AXI_ARPROT[ N* 3 +:  3];
			m_arqos[N]   = M_AXI_ARQOS[  N* 4 +:  4];
		end

	end for (N=NM; N<NMFULL; N=N+1)
	begin : UNUSED_RSKID_BUFFERS

		always @(*)
			m_arvalid[N] = 0;
		always @(*)
		begin
			m_arid[N]    = 0;
			m_araddr[N]  = 0;
			m_arlen[N]   = 0;
			m_arsize[N]  = 0;
			m_arburst[N] = 0;
			m_arlock[N]  = 0;
			m_arcache[N] = 0;
			m_arprot[N]  = 0;
			m_arqos[N]   = 0;
		end
	end endgenerate

	always @(*)
	begin : DECONFLICT_WRITE_REQUESTS

		wrequested[NM] = 0;

		for(iM=0; iM<NS; iM=iM+1)
		begin
			wrequested[0][iM] = 0;
			for(iN=1; iN<NM ; iN=iN+1)
			wrequested[iN][iM]
				= (wrequest[iN-1][iM] || wrequested[iN-1][iM]);
			wrequested[NM][iM] = wrequest[NM-1][iM] || wrequested[NM-1][iM];
		end

		for(iM=NS; iM<NSFULL; iM=iM+1)
		begin
			for(iN=0; iN<NM+1; iN=iN+1)
				wrequested[iN][iM] = 0;
		end
	end

	always @(*)
	begin : DECONFLICT_READ_REQUESTS

		rrequested[NM] = 0;

		for(iM=0; iM<NS; iM=iM+1)
		begin
			rrequested[0][iM] = 0;
			for(iN=1; iN<NM ; iN=iN+1)
			rrequested[iN][iM]
				= (rrequest[iN-1][iM] || rrequested[iN-1][iM]);
			rrequested[NM][iM] = rrequest[NM-1][iM] || rrequested[NM-1][iM];
		end

		for(iM=NS; iM<NSFULL; iM=iM+1)
		begin
			for(iN=0; iN<NM ; iN=iN+1)
				rrequested[iN][iM] = 0;
		end
	end

	generate for(M=0; M<NS; M=M+1)
	begin

		always @(*)
		begin
			swgrant[M] = 0;
			for(iN=0; iN<NM; iN=iN+1)
				if (wgrant[iN][M])
					swgrant[M] = 1;
		end

		always @(*)
		begin
			srgrant[M] = 0;
			for(iN=0; iN<NM; iN=iN+1)
				if (rgrant[iN][M])
					srgrant[M] = 1;
		end

	end endgenerate

	generate for(N=0; N<NM; N=N+1)
	begin : ARBITRATE_WRITE_REQUESTS
		reg	stay_on_channel;

		always @(*)
		begin
			stay_on_channel = 0;
			for(iM=0; iM<=NS; iM=iM+1)
			begin
				if (wrequest[N][iM] && wgrant[N][iM])
					stay_on_channel = 1;
			end
		end

		reg	requested_channel_is_available;

		always @(*)
		begin
			requested_channel_is_available = 0;
			for(iM=0; iM<NS; iM=iM+1)
			begin
				if (wrequest[N][iM] && !swgrant[iM]
					&& !wrequested[N][iM])
					requested_channel_is_available = 1;
			end
			if (wrequest[N][NS])
				requested_channel_is_available = 1;
		end

		reg	linger;
		if (OPT_LINGER == 0)
		begin
			always @(*)
				linger = 0;
		end else begin : WRITE_LINGER

			reg [LGLINGER-1:0]	linger_counter;

			initial	linger = 0;
			initial	linger_counter = 0;
			always @(posedge S_AXI_ACLK)
			if (!S_AXI_ARESETN || wgrant[N][NS])
			begin
				linger <= 0;
				linger_counter <= 0;
			end else if (!mwempty[N] || M_AXI_BVALID[N])
			begin
				linger_counter <= OPT_LINGER;
				linger <= 1;
			end else if (linger_counter > 0)
			begin
				linger <= (linger_counter > 1);
				linger_counter <= linger_counter - 1;
			end else
				linger <= 0;

`ifdef	FORMAL
			always @(*)
				assert(linger == (linger_counter != 0));
`endif
		end

		reg	leave_channel;
		always @(*)
		begin
			leave_channel = 0;
			if (!M_AXI_AWVALID[N] && !r_awvalid[N]
				&& (!linger || wrequested[NM][mwindex[N]]))
				// Leave the channel after OPT_LINGER counts
				// of the channel being idle, or when someone
				// else asks for the channel
				leave_channel = 1;
			if (m_awvalid[N] && !wrequest[N][mwindex[N]])
				// Need to leave this channel to connect
				// to any other channel
				leave_channel = 1;

			if (!mwempty[N])
				// Can't leave this channel until we've gotten
				// all of the acknowledgments
				leave_channel = 0;
			if (!mwgrant[N])
				// Can't leave a channel we aren't a part of
				leave_channel = 0;
		end


		initial	wgrant[N]  = 0;
		initial	mwgrant[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
		begin
			wgrant[N]  <= 0;
			mwgrant[N] <= 0;
		end else if (!stay_on_channel && (!mwgrant[N] || mwempty[N]))
		begin
			if (requested_channel_is_available)
			begin
				// Switching channels
				mwgrant[N] <= 1'b1;
				wgrant[N]  <= wrequest[N];
			end else if (M_AXI_AWVALID[N] || r_awvalid[N])
			begin
				// Requested channel isn't yet available
				mwgrant[N] <= 1'b0;
				wgrant[N]  <= 0;
			end else if (leave_channel)
			begin
				mwgrant[N] <= 1'b0;
				wgrant[N]  <= wrequest[N];
			end
		end

		// Now for mwindex
		initial	mwindex[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (!stay_on_channel && (!mwgrant[N] || mwempty[N])
			&& requested_channel_is_available)
		begin

			for(iM=0; iM<=NS; iM=iM+1)
			begin

				if (wrequest[N][iM])
					mwindex[N] <= iM[LGNS-1:0];
			end
		end
	end for (N=NM; N<NMFULL; N=N+1)
	begin

		always @(*)
			mwindex[N] = 0;

	end endgenerate

	generate for(N=0; N<NM; N=N+1)
	begin : ARBITRATE_READ_REQUESTS
		reg	stay_on_channel;

		always @(*)
		begin
			stay_on_channel = 0;
			for(iM=0; iM<=NS; iM=iM+1)
			begin
				if (rrequest[N][iM] && rgrant[N][iM])
					stay_on_channel = 1;
			end
		end

		reg	requested_channel_is_available;

		always @(*)
		begin
			requested_channel_is_available = 0;
			for(iM=0; iM<NS; iM=iM+1)
			begin
				if (rrequest[N][iM] && !srgrant[iM]
					&& !rrequested[N][iM])
					requested_channel_is_available = 1;
			end
			if (rrequest[N][NS])
				requested_channel_is_available = 1;
		end

		reg	linger;
		if (OPT_LINGER == 0)
		begin
			always @(*)
				linger = 0;
		end else begin : READ_LINGER

			reg [LGLINGER-1:0]	linger_counter;

			initial	linger = 0;
			initial	linger_counter = 0;
			always @(posedge S_AXI_ACLK)
			if (!S_AXI_ARESETN || rgrant[N][NS])
			begin
				linger <= 0;
				linger_counter <= 0;
			end else if (!mrempty[N] || M_AXI_RVALID[N])
			begin
				linger_counter <= OPT_LINGER;
				linger <= 1;
			end else if (linger_counter > 0)
			begin
				linger <= (linger_counter > 1);
				linger_counter <= linger_counter - 1;
			end else
				linger <= 0;

`ifdef	FORMAL
			always @(*)
				assert(linger == (linger_counter != 0));
`endif
		end

		reg	leave_channel;
		always @(*)
		begin
			leave_channel = 0;
			if (!M_AXI_ARVALID[N] && !r_arvalid[N]
				&& (!linger || rrequested[NM][mrindex[N]]))
				// Leave the channel after OPT_LINGER counts
				// of the channel being idle, or when someone
				// else asks for the channel
				leave_channel = 1;
			if (m_arvalid[N] && !rrequest[N][mrindex[N]])
				// Need to leave this channel to connect
				// to any other channel
				leave_channel = 1;

			if (!mrempty[N])
				// Can't leave this channel until we've gotten
				// all of the acknowledgments
				leave_channel = 0;
			if (!mrgrant[N])
				// Can't leave a channel we aren't a part of
				leave_channel = 0;
		end


		initial	rgrant[N]  = 0;
		initial	mrgrant[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
		begin
			rgrant[N]  <= 0;
			mrgrant[N] <= 0;
		end else if (!stay_on_channel && (!mrgrant[N] || mrempty[N]))
		begin
			if (requested_channel_is_available)
			begin
				// Switching channels
				mrgrant[N] <= 1'b1;
				rgrant[N] <= rrequest[N];
			end else if (M_AXI_ARVALID[N] || r_arvalid[N])
			begin
				// Requesting another channel, which isn't
				// (yet) available
				mrgrant[N] <= 1'b0;
				rgrant[N]  <= 0;
			end else if (leave_channel)
			begin
				mrgrant[N] <= 1'b0;
				rgrant[N]  <= 0;
			end
		end

		// Now for mrindex
		initial	mrindex[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (!stay_on_channel && (!mrgrant[N] || mrempty[N])
			&& requested_channel_is_available)
		begin
			for(iM=0; iM<=NS; iM=iM+1)
			begin
				if (rrequest[N][iM])
					mrindex[N] <= iM[LGNS-1:0];
			end
		end


	end for (N=NM; N<NMFULL; N=N+1)
	begin

		always @(*)
			mrindex[N] = 0;

	end endgenerate

	generate for (N=0; N<NM; N=N+1)
	begin : INCOMING_SKID_BUFFERS

		initial	r_awid[N]    = 0;
		initial	r_awaddr[N]  = 0;
		initial	r_awlen[N]   = 0;
		initial	r_awsize[N]  = 0;
		initial	r_awburst[N] = 0;
		initial	r_awlock[N]  = 0;
		initial	r_awcache[N] = 0;
		initial	r_awprot[N]  = 0;
		initial	r_awqos[N]   = 0;
		always @(posedge S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			r_awid[N]    <= 0;
			r_awaddr[N]  <= 0;
			r_awlen[N]   <= 0;
			r_awsize[N]  <= 0;
			r_awburst[N] <= 0;
			r_awlock[N]  <= 0;
			r_awcache[N] <= 0;
			r_awprot[N]  <= 0;
			r_awqos[N]   <= 0;
		end else if (M_AXI_AWREADY[N])
		begin
			if (M_AXI_AWVALID[N] || !OPT_LOWPOWER)
			begin
				r_awid[N]    <= M_AXI_AWID[   N*IW +: IW];
				r_awaddr[N]  <= M_AXI_AWADDR[ N*AW +: AW];
				r_awlen[N]   <= M_AXI_AWLEN[  N* 8 +:  8];
				r_awsize[N]  <= M_AXI_AWSIZE[ N* 3 +:  3];
				r_awburst[N] <= M_AXI_AWBURST[N* 2 +:  2];
				r_awlock[N]  <= M_AXI_AWLOCK[ N];
				r_awcache[N] <= M_AXI_AWCACHE[N* 4 +:  4];
				r_awprot[N]  <= M_AXI_AWPROT[ N* 3 +:  3];
				r_awqos[N]   <= M_AXI_AWQOS[  N* 4 +:  4];
			end else // if (OPT_LOWPOWER)
			begin
				r_awid[N]    <= 0;
				r_awaddr[N]  <= 0;
				r_awlen[N]   <= 0;
				r_awsize[N]  <= 0;
				r_awburst[N] <= 0;
				r_awlock[N]  <= 0;
				r_awcache[N] <= 0;
				r_awprot[N]  <= 0;
				r_awqos[N]   <= 0;
			end
		end

		initial	r_wdata[N] = 0;
		initial	r_wstrb[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			r_wdata[N] <= 0;
			r_wstrb[N] <= 0;
			r_wlast[N] <= 0;
		end else if (M_AXI_WREADY[N])
		begin
			if (M_AXI_WVALID[N] || !OPT_LOWPOWER)
			begin
				r_wdata[N] <= M_AXI_WDATA[N*DW   +: DW];
				r_wstrb[N] <= M_AXI_WSTRB[N*DW/8 +: DW/8];
				r_wlast[N] <= M_AXI_WLAST[N];
			end else // if (OPT_LOWPOWER)
			begin
				r_wdata[N] <= 0;
				r_wstrb[N] <= 0;
				r_wlast[N] <= 0;
			end
		end

		//
		//

		initial	r_arid[N]    = 0;
		initial	r_araddr[N]  = 0;
		initial	r_arlen[N]   = 0;
		initial	r_arsize[N]  = 0;
		initial	r_arburst[N] = 0;
		initial	r_arlock[N]  = 0;
		initial	r_arcache[N] = 0;
		initial	r_arprot[N]  = 0;
		initial	r_arqos[N]   = 0;
		always @(posedge S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			r_arid[N]    <= 0;
			r_araddr[N]  <= 0;
			r_arlen[N]   <= 0;
			r_arsize[N]  <= 0;
			r_arburst[N] <= 0;
			r_arlock[N]  <= 0;
			r_arcache[N] <= 0;
			r_arprot[N]  <= 0;
			r_arqos[N]   <= 0;
		end else if (M_AXI_ARREADY[N])
		begin
			if (M_AXI_ARVALID[N] || !OPT_LOWPOWER)
			begin
				r_arid[N]    <= M_AXI_ARID[   N*IW +: IW];
				r_araddr[N]  <= M_AXI_ARADDR[ N*AW +: AW];
				r_arlen[N]   <= M_AXI_ARLEN[  N* 8 +:  8];
				r_arsize[N]  <= M_AXI_ARSIZE[ N* 3 +:  3];
				r_arburst[N] <= M_AXI_ARBURST[N* 2 +:  2];
				r_arlock[N]  <= M_AXI_ARLOCK[ N];
				r_arcache[N] <= M_AXI_ARCACHE[N* 4 +:  4];
				r_arprot[N]  <= M_AXI_ARPROT[ N* 3 +:  3];
				r_arqos[N]   <= M_AXI_ARQOS[  N* 4 +:  4];
			end else // if (OPT_LOWPOWER)
			begin
				r_arid[N]    <= 0;
				r_araddr[N]  <= 0;
				r_arlen[N]   <= 0;
				r_arsize[N]  <= 0;
				r_arburst[N] <= 0;
				r_arlock[N]  <= 0;
				r_arcache[N] <= 0;
				r_arprot[N]  <= 0;
				r_arqos[N]   <= 0;
			end
		end


`ifdef	FORMAL
		always @(*)
		if (r_awvalid[N])
			assert(!M_AXI_AWREADY[N]);

		// always @(*)
		//	assert(!M_AXI_WREADY[N] == r_wvalid[N]);

		always @(*)
			assert(!M_AXI_ARREADY[N] == r_arvalid[N]);
`endif
	end endgenerate

	// Calculate swindex
	generate for (M=0; M<NS; M=M+1)
	begin : SLAVE_WRITE_INDEX

		if (NM <= 1)
		begin

			always @(*)
				swindex[M] = 0;

		end else begin : MULTIPLE_MASTERS

			always @(posedge S_AXI_ACLK)
			if (!swgrant[M])
			begin
				for(iN=0; iN<NM; iN=iN+1)
				begin
					if ((!mwgrant[iN] || mwempty[iN])
						&&(wrequest[iN][M]
						&& !wrequested[iN][M]))
						swindex[M] <= iN[LGNM-1:0];
				end
			end
		end

	end for (M=NS; M<NSFULL; M=M+1)
	begin

		always @(*)
			swindex[M] = 0;

	end endgenerate

	// Calculate srindex
	generate for (M=0; M<NS; M=M+1)
	begin : SLAVE_READ_INDEX

		if (NM <= 1)
		begin

			always @(*)
				srindex[M] = 0;

		end else begin : MULTIPLE_MASTERS

			always @(posedge S_AXI_ACLK)
			if (!srgrant[M])
			begin
				for(iN=0; iN<NM; iN=iN+1)
				begin
					if ((!mrgrant[iN] || mrempty[iN])
						&& (rrequest[iN][M]
						&& !rrequested[iN][M]))
						srindex[M] <= iN[LGNM-1:0];
				end
			end
		end

	end for (M=NS; M<NSFULL; M=M+1)
	begin

		always @(*)
			swindex[M] = 0;

	end endgenerate


	// Assign outputs to the various slaves
	generate for(M=0; M<NS; M=M+1)
	begin : WRITE_SLAVE_OUTPUTS

		reg			axi_awvalid;
		reg	[IW-1:0]	axi_awid;
		reg	[AW-1:0]	axi_awaddr;
		reg	[7:0]		axi_awlen;
		reg	[2:0]		axi_awsize;
		reg	[1:0]		axi_awburst;
		reg			axi_awlock;
		reg	[3:0]		axi_awcache;
		reg	[2:0]		axi_awprot;
		reg	[3:0]		axi_awqos;

		reg			axi_wvalid;
		reg	[DW-1:0]	axi_wdata;
		reg	[DW/8-1:0]	axi_wstrb;
		reg			axi_wlast;
		//
		reg			axi_bready;

		reg	sawstall, swstall, mbstall;
		always @(*)
			sawstall= (S_AXI_AWVALID[M]&& !S_AXI_AWREADY[M]);
		always @(*)
			swstall = (S_AXI_WVALID[M] && !S_AXI_WREADY[M]);
		always @(*)
			mbstall = (M_AXI_BVALID[swindex[M]] && !M_AXI_BREADY[swindex[M]]);

		initial	axi_awvalid = 0;
		always @(posedge  S_AXI_ACLK)
		if (!S_AXI_ARESETN || !swgrant[M])
			axi_awvalid <= 0;
		else if (!sawstall)
		begin
			axi_awvalid <= m_awvalid[swindex[M]]
				&&(slave_awaccepts[swindex[M]]);
		end

		initial	axi_awid    = 0;
		initial	axi_awaddr  = 0;
		initial	axi_awlen   = 0;
		initial	axi_awsize  = 0;
		initial	axi_awburst = 0;
		initial	axi_awlock  = 0;
		initial	axi_awcache = 0;
		initial	axi_awprot  = 0;
		initial	axi_awqos   = 0;
		always @(posedge  S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			axi_awid    <= 0;
			axi_awaddr  <= 0;
			axi_awlen   <= 0;
			axi_awsize  <= 0;
			axi_awburst <= 0;
			axi_awlock  <= 0;
			axi_awcache <= 0;
			axi_awprot  <= 0;
			axi_awqos   <= 0;
		end else if (OPT_LOWPOWER && !swgrant[M])
		begin
			axi_awid    <= 0;
			axi_awaddr  <= 0;
			axi_awlen   <= 0;
			axi_awsize  <= 0;
			axi_awburst <= 0;
			axi_awlock  <= 0;
			axi_awcache <= 0;
			axi_awprot  <= 0;
			axi_awqos   <= 0;
		end else if (!sawstall)
		begin
			if (!OPT_LOWPOWER||(m_awvalid[swindex[M]]&&slave_awaccepts[swindex[M]]))
			begin
				if (NM == 1)
				begin
					axi_awid    <= m_awid[0];
					axi_awaddr  <= m_awaddr[0];
					axi_awlen   <= m_awlen[0];
					axi_awsize  <= m_awsize[0];
					axi_awburst <= m_awburst[0];
					axi_awlock  <= m_awlock[0];
					axi_awcache <= m_awcache[0];
					axi_awprot  <= m_awprot[0];
					axi_awqos   <= m_awqos[0];
				end else begin
					axi_awid    <= m_awid[   swindex[M]];
					axi_awaddr  <= m_awaddr[ swindex[M]];
					axi_awlen   <= m_awlen[  swindex[M]];
					axi_awsize  <= m_awsize[ swindex[M]];
					axi_awburst <= m_awburst[swindex[M]];
					axi_awlock  <= m_awlock[ swindex[M]];
					axi_awcache <= m_awcache[swindex[M]];
					axi_awprot  <= m_awprot[ swindex[M]];
					axi_awqos   <= m_awqos[  swindex[M]];
				end
			end else begin
				axi_awid    <= 0;
				axi_awaddr  <= 0;
				axi_awlen   <= 0;
				axi_awsize  <= 0;
				axi_awburst <= 0;
				axi_awlock  <= 0;
				axi_awcache <= 0;
				axi_awprot  <= 0;
				axi_awqos   <= 0;
			end
		end

		initial	axi_wvalid = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN || !swgrant[M])
			axi_wvalid <= 0;
		else if (!swstall)
		begin
			axi_wvalid <= (m_wvalid[swindex[M]])
					&&(slave_waccepts[swindex[M]]);
		end

		initial axi_wdata  = 0;
		initial axi_wstrb  = 0;
		initial axi_wlast  = 0;
		always @(posedge S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			axi_wdata  <= 0;
			axi_wstrb  <= 0;
			axi_wlast  <= 0;
		end else if (OPT_LOWPOWER && !swgrant[M])
		begin
			axi_wdata  <= 0;
			axi_wstrb  <= 0;
			axi_wlast  <= 0;
		end else if (!swstall)
		begin
			if (!OPT_LOWPOWER || (m_wvalid[swindex[M]]&&slave_waccepts[swindex[M]]))
			begin
				if (NM == 1)
				begin
					axi_wdata <= m_wdata[0];
					axi_wstrb <= m_wstrb[0];
					axi_wlast <= m_wlast[0];
				end else begin
					axi_wdata  <= m_wdata[swindex[M]];
					axi_wstrb  <= m_wstrb[swindex[M]];
					axi_wlast  <= m_wlast[swindex[M]];
				end
			end else begin
				axi_wdata  <= 0;
				axi_wstrb  <= 0;
				axi_wlast  <= 0;
			end
		end

		//
		initial	axi_bready = 1;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN || !swgrant[M])
			axi_bready <= 1;
		else if (!mbstall)
			axi_bready <= 1;
		else if (S_AXI_BVALID[M]) // && mbstall
			axi_bready <= 0;

		//
		assign	S_AXI_AWVALID[M]          = axi_awvalid;
		assign	S_AXI_AWID[   M*IW +: IW] = axi_awid;
		assign	S_AXI_AWADDR[ M*AW +: AW] = axi_awaddr;
		assign	S_AXI_AWLEN[  M* 8 +:  8] = axi_awlen;
		assign	S_AXI_AWSIZE[ M* 3 +:  3] = axi_awsize;
		assign	S_AXI_AWBURST[M* 2 +:  2] = axi_awburst;
		assign	S_AXI_AWLOCK[ M]          = axi_awlock;
		assign	S_AXI_AWCACHE[M* 4 +:  4] = axi_awcache;
		assign	S_AXI_AWPROT[ M* 3 +:  3] = axi_awprot;
		assign	S_AXI_AWQOS[  M* 4 +:  4] = axi_awqos;
		//
		//
		assign	S_AXI_WVALID[M]             = axi_wvalid;
		assign	S_AXI_WDATA[M*DW +: DW]     = axi_wdata;
		assign	S_AXI_WSTRB[M*DW/8 +: DW/8] = axi_wstrb;
		assign	S_AXI_WLAST[M]              = axi_wlast;
		//
		//
		assign	S_AXI_BREADY[M]             = axi_bready;
		//
`ifdef	FORMAL
		if (OPT_LOWPOWER)
		begin
			always @(*)
			if (!axi_awvalid)
			begin
				assert(axi_awaddr == 0);
				assert(axi_awprot == 0);
			end

			always @(*)
			if (!axi_wvalid)
			begin
				assert(axi_wdata == 0);
				assert(axi_wstrb == 0);
			end
		end
`endif
	end endgenerate


	generate for(M=0; M<NS; M=M+1)
	begin : READ_SLAVE_OUTPUTS

		reg					axi_arvalid;
		reg	[C_S_AXI_ID_WIDTH-1:0]		axi_arid;
		reg	[C_S_AXI_ADDR_WIDTH-1:0]	axi_araddr;
		reg	[7:0]				axi_arlen;
		reg	[3:0]				axi_arsize;
		reg	[2:0]				axi_arburst;
		reg					axi_arlock;
		reg	[3:0]				axi_arcache;
		reg	[2:0]				axi_arprot;
		reg	[3:0]				axi_arqos;
		//
		reg					axi_rready;

		reg	arstall, mrstall;
		always @(*)
			arstall= (S_AXI_ARVALID[M]&& !S_AXI_ARREADY[M]);
		always @(*)
			mrstall = (M_AXI_RVALID[srindex[M]]
						&& !M_AXI_RREADY[srindex[M]]);

		initial	axi_arvalid = 0;
		always @(posedge  S_AXI_ACLK)
		if (!S_AXI_ARESETN || !srgrant[M])
			axi_arvalid <= 0;
		else if (!arstall)
		begin
			axi_arvalid <= m_arvalid[srindex[M]] && slave_raccepts[srindex[M]];
		end

		initial	axi_arid    = 0;
		initial	axi_araddr  = 0;
		initial	axi_arlen   = 0;
		initial	axi_arsize  = 0;
		initial	axi_arburst = 0;
		initial	axi_arlock  = 0;
		initial	axi_arcache = 0;
		initial	axi_arprot  = 0;
		initial	axi_arqos   = 0;
		always @(posedge  S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			axi_arid    <= 0;
			axi_araddr  <= 0;
			axi_arlen   <= 0;
			axi_arsize  <= 0;
			axi_arburst <= 0;
			axi_arlock  <= 0;
			axi_arcache <= 0;
			axi_arprot  <= 0;
			axi_arqos   <= 0;
		end else if (OPT_LOWPOWER && !srgrant[M])
		begin
			axi_arid    <= 0;
			axi_araddr  <= 0;
			axi_arlen   <= 0;
			axi_arsize  <= 0;
			axi_arburst <= 0;
			axi_arlock  <= 0;
			axi_arcache <= 0;
			axi_arprot  <= 0;
			axi_arqos   <= 0;
		end else if (!arstall)
		begin
			if (!OPT_LOWPOWER || (m_arvalid[srindex[M]] && slave_raccepts[srindex[M]]))
			begin
				if (NM == 1)
				begin
					axi_arid    <= m_arid[0];
					axi_araddr  <= m_araddr[0];
					axi_arlen   <= m_arlen[0];
					axi_arsize  <= m_arsize[0];
					axi_arburst <= m_arburst[0];
					axi_arlock  <= m_arlock[0];
					axi_arcache <= m_arcache[0];
					axi_arprot  <= m_arprot[0];
					axi_arqos   <= m_arqos[0];
				end else begin
					axi_arid    <= m_arid[   srindex[M]];
					axi_araddr  <= m_araddr[ srindex[M]];
					axi_arlen   <= m_arlen[  srindex[M]];
					axi_arsize  <= m_arsize[ srindex[M]];
					axi_arburst <= m_arburst[srindex[M]];
					axi_arlock  <= m_arlock[ srindex[M]];
					axi_arcache <= m_arcache[srindex[M]];
					axi_arprot  <= m_arprot[ srindex[M]];
					axi_arqos   <= m_arqos[  srindex[M]];
				end
			end else begin
				axi_arid    <= 0;
				axi_araddr  <= 0;
				axi_arlen   <= 0;
				axi_arsize  <= 0;
				axi_arburst <= 0;
				axi_arlock  <= 0;
				axi_arcache <= 0;
				axi_arprot  <= 0;
				axi_arqos   <= 0;
			end
		end

		initial	axi_rready = 1;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN || !srgrant[M])
			axi_rready <= 1;
		else if (!mrstall)
			axi_rready <= 1;
		else if (S_AXI_RVALID[M] && S_AXI_RREADY[M]) // && mrstall
			axi_rready <= 0;

		//
		assign	S_AXI_ARVALID[M]         = axi_arvalid;
		assign	S_AXI_ARID[   M*IW +: IW] = axi_arid;
		assign	S_AXI_ARADDR[ M*AW +: AW] = axi_araddr;
		assign	S_AXI_ARLEN[  M* 8 +:  8] = axi_arlen;
		assign	S_AXI_ARSIZE[ M* 3 +:  3] = axi_arsize;
		assign	S_AXI_ARBURST[M* 2 +:  2] = axi_arburst;
		assign	S_AXI_ARLOCK[ M]          = axi_arlock;
		assign	S_AXI_ARCACHE[M* 4 +:  4] = axi_arcache;
		assign	S_AXI_ARPROT[ M* 3 +:  3] = axi_arprot;
		assign	S_AXI_ARQOS[  M* 4 +:  4] = axi_arqos;
		//
		assign	S_AXI_RREADY[M]          = axi_rready;
		//
`ifdef	FORMAL
		if (OPT_LOWPOWER)
		begin
			always @(*)
			if (!axi_arvalid)
			begin
				assert(axi_araddr == 0);
				assert(axi_arprot == 0);
			end
		end
`endif
	end endgenerate

	reg			r_bvalid	[0:NM-1];
	reg	[1:0]		r_bresp		[0:NM-1];
	reg	[IW-1:0]	r_bid		[0:NM-1];

	// Return values
	generate for (N=0; N<NM; N=N+1)
	begin : WRITE_RETURN_CHANNEL

		reg		axi_awready, axi_wready;
		reg		axi_bvalid;
		reg	[1:0]	axi_bresp;
		reg	[IW-1:0] axi_bid;
		reg		i_axi_bvalid;
		reg	[1:0]	i_axi_bresp;
		reg	[IW-1:0] i_axi_bid;

		always @(*)
		if (mwindex[N] == NS)
			i_axi_bvalid = m_wvalid[N] && slave_waccepts[N] && m_wlast[N];
		else
			i_axi_bvalid = s_axi_bvalid[mwindex[N]];

		always @(*)
		if (mwindex[N] == NS)
			i_axi_bid = m_wid[N];
		else
			i_axi_bid = s_axi_bid[mwindex[N]];
		always @(*)
			i_axi_bresp = s_axi_bresp[mwindex[N]];

		reg	mbstall;
		always @(*)
			mbstall = M_AXI_BVALID[N] && !M_AXI_BREADY[N];

		initial	axi_awready = 1;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			axi_awready <= 1;
		else begin
			if (M_AXI_AWVALID[N] && axi_awready)
			begin
				if (!slave_awaccepts[N])
					axi_awready <= 1'b0;
				// else if (m_awlen[N] > 0)
				//	axi_awready <= 1'b0;
				else if (!M_AXI_WVALID[N] || !M_AXI_WREADY[N]
					|| !M_AXI_WLAST[N])
					axi_awready <= 1'b0;
			end else if (m_wvalid[N] && m_wlast[N]
							&& slave_waccepts[N])
				axi_awready <= 1'b1;
		end

		initial	axi_wready = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			axi_wready <= 0;
		else begin

			if (m_wvalid[N] && !slave_waccepts[N])
				axi_wready <= 0;
			else if (m_wvalid[N] && !m_wlast[N]&& slave_waccepts[N])
				axi_wready <= 1;
			else if (!axi_wready
					&& (!r_wvalid[N] || slave_waccepts[N])
					&& (M_AXI_AWVALID[N] && axi_awready))
				axi_wready <= 1;
			else if (m_wvalid[N] && m_wlast[N] && slave_waccepts[N])
				axi_wready <= 0;
		end

		initial	r_bvalid[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			r_bvalid[N] <= 0;
		else if (mbstall && !r_bvalid[N] && (mwindex[N] != NS))
			r_bvalid[N] <= mwgrant[N] && (mwindex[N]<NS)&&i_axi_bvalid;
		else if (!mbstall)
			r_bvalid[N] <= 1'b0;

		initial	r_bid[N]   = 0;
		initial	r_bresp[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			r_bid[N]   <= 0;
			r_bresp[N] <= 0;
		end else if (OPT_LOWPOWER && (!mwgrant[N] || M_AXI_BREADY[N]))
		begin
			r_bid[N]   <= 0;
			r_bresp[N] <= 0;
		end else if (!r_bvalid[N])
		begin
			if (!OPT_LOWPOWER ||(i_axi_bvalid && (mwindex[N] < NS) && mbstall))
			begin
				if (NS==1)
				begin
					r_bid[N]   <= S_AXI_BID[IW-1:0];
					r_bresp[N] <= S_AXI_BRESP[1:0];
				end else begin
					r_bid[N]   <= i_axi_bid;
					r_bresp[N] <= i_axi_bresp;
				end
			end else begin
				r_bid[N]   <= 0;
				r_bresp[N] <= 0;
			end
		end

		initial	axi_bvalid = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			axi_bvalid <= 0;
		else if (!mbstall)
			axi_bvalid <= mwgrant[N] && (r_bvalid[N] || i_axi_bvalid);

		initial	axi_bid   = 0;
		always @(posedge S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
			axi_bid <= 0;
		else if (OPT_LOWPOWER && !mwgrant[N])
			axi_bid   <= 0;
		else if (!mbstall)
		begin
			if (wgrant[N][NS])
			begin
				if (m_awvalid[N] && slave_awaccepts[N])
					axi_bid <= m_awid[N];
			end else if (r_bvalid[N])
				axi_bid   <= r_bid[N];
			else if (!OPT_LOWPOWER || i_axi_bvalid)
				axi_bid   <= i_axi_bid;
			else
				axi_bid   <= 0;
		end

		initial	axi_bresp = 0;
		always @(posedge S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			axi_bresp <= 0;
		end else if (OPT_LOWPOWER && !mwgrant[N])
		begin
			axi_bresp <= 0;
		end else if (!mbstall)
		begin
			if (r_bvalid[N])
				axi_bresp <= r_bresp[N];
			else if (!OPT_LOWPOWER || i_axi_bvalid)
				axi_bresp <= i_axi_bresp;
			else
				axi_bresp <= 0;

			if (mwindex[N] == NS && (!OPT_LOWPOWER || i_axi_bvalid))
				axi_bresp <= INTERCONNECT_ERROR;
		end

		assign	M_AXI_AWREADY[N]      = axi_awready;
		assign	M_AXI_WREADY[N]       = axi_wready;
		//
		assign	M_AXI_BVALID[N]       = axi_bvalid;
		assign	M_AXI_BID[  N*IW +: IW] = axi_bid;
		assign	M_AXI_BRESP[N* 2 +:  2] = axi_bresp;
`ifdef	FORMAL
		always @(*)
		if (mwgrant[N])
			assert(s_axi_bready[mwindex[N]] == !r_bvalid[N]);
		else
			assert(!r_bvalid[N]);
		always @(*)
		if (OPT_LOWPOWER && !r_bvalid[N])
		begin
			assert(r_bresp[N]  == 0);
			assert(r_bid[N]    == 0);
		end

		always @(*)
		if (OPT_LOWPOWER && !axi_bvalid)
		begin
			assert(axi_bid    == 0);
			assert(axi_bresp  == 0);
		end
`endif
	end endgenerate

	always @(*)
	begin
		s_axi_arvalid = 0;
		s_axi_arready = 0;
		s_axi_rvalid = 0;
		s_axi_rready = 0;
		for(iM=0; iM<NS; iM=iM+1)
		begin
			s_axi_arlen[iM] = S_AXI_ARLEN[iM* 8 +:  8];
			s_axi_arid[iM]  = S_AXI_ARID[ iM*IW +: IW];
		end
		for(iM=NS; iM<NSFULL; iM=iM+1)
		begin
			s_axi_arlen[iM] = 0;
			s_axi_arid[iM]  = 0;
		end

		s_axi_arvalid[NS-1:0] = S_AXI_ARVALID;
		s_axi_arready[NS-1:0] = S_AXI_ARREADY;
		s_axi_rvalid[NS-1:0]  = S_AXI_RVALID;
		s_axi_rready[NS-1:0]  = S_AXI_RREADY;
	end

	reg			r_rvalid	[0:NM-1];
	reg	[1:0]		r_rresp		[0:NM-1];
	reg	[IW-1:0]	r_rid		[0:NM-1];
	reg	[DW-1:0]	r_rdata		[0:NM-1];
	reg	[NM-1:0]	r_rlast;
	// Return values
	generate for (N=0; N<NM; N=N+1)
	begin : READ_RETURN_CHANNEL

		reg			axi_rvalid;
		reg	[1:0]		axi_rresp;
		reg	[DW-1:0]	axi_rdata;
		reg	[IW-1:0]	axi_rid;
		reg			axi_rlast;
		reg			axi_arready;
		// reg	[((NM>1)?($clog2(NM)-1):0):0]		rindex;

		reg	mrstall;
		reg	i_axi_rvalid;
		always @(*)
		if (mrindex[N] == NS)
			i_axi_rvalid = m_arvalid[N] && slave_raccepts[N];
		else
			i_axi_rvalid = s_axi_rvalid[mrindex[N]];

		always @(*)
			mrstall = M_AXI_RVALID[N] && !M_AXI_RREADY[N];



		initial	axi_arready = 1;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			axi_arready <= 1'b1;
		else begin
			if (M_AXI_ARVALID[N] && axi_arready)
			begin
				if (!slave_raccepts[N])
					axi_arready <= 1'b0;
			end else if (!axi_arready && slave_raccepts[N])
				axi_arready <= 1'b1;
		end

		initial	r_rvalid[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			r_rvalid[N] <= 0;
		else if (mrstall && !r_rvalid[N])
			r_rvalid[N] <= mrgrant[N] && (mrindex[N]<NS)&&i_axi_rvalid;
		else if (!mrstall)
			r_rvalid[N] <= 0;

		initial	r_rid[N]   = 0;
		initial	r_rresp[N] = 0;
		initial	r_rdata[N] = 0;
		initial	r_rlast[N] = 0;
		always @(posedge S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			r_rid[N]   <= 0;
			r_rresp[N] <= 0;
			r_rdata[N] <= 0;
			r_rlast[N] <= 0;
		end else if (OPT_LOWPOWER && (!mrgrant[N] || M_AXI_RREADY[N]))
		begin
			r_rid[N]   <= 0;
			r_rresp[N] <= 0;
			r_rdata[N] <= 0;
			r_rlast[N] <= 0;
		end else if (!r_rvalid[N])
		begin
			if (!OPT_LOWPOWER || (i_axi_rvalid && (mrindex[N] < NS)&& mrstall))
			begin
				if (NS == 1)
				begin
					r_rid[N]   <= s_axi_rid[0];
					r_rresp[N] <= s_axi_rresp[0];
					r_rdata[N] <= s_axi_rdata[0];
					r_rlast[N] <= s_axi_rlast[0];
				end else begin
					r_rid[N]   <= s_axi_rid[mrindex[N]];
					r_rresp[N] <= s_axi_rresp[mrindex[N]];
					r_rdata[N] <= s_axi_rdata[mrindex[N]];
					r_rlast[N] <= s_axi_rlast[mrindex[N]];
				end
			end else begin
				r_rid[N]   <= 0;
				r_rresp[N] <= 0;
				r_rdata[N] <= 0;
				r_rlast[N] <= 0;
			end
		end

		initial	axi_rvalid = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			axi_rvalid <= 0;
		else if (!mrstall)
			axi_rvalid <= mrgrant[N] && (r_rvalid[N] || i_axi_rvalid);

		initial	axi_rid  = 0;
		initial	axi_rresp = 0;
		initial	axi_rdata = 0;
		initial	axi_rlast = 0;
		always @(posedge S_AXI_ACLK)
		if (OPT_LOWPOWER && !S_AXI_ARESETN)
		begin
			axi_rid   <= 0;
			axi_rresp <= 0;
			axi_rdata <= 0;
			axi_rlast <= 0;
		end else if (OPT_LOWPOWER && !mrgrant[N])
		begin
			axi_rid   <= 0;
			axi_rresp <= 0;
			axi_rdata <= 0;
			axi_rlast <= 0;
		end else if (!mrstall)
		begin
			if (r_rvalid[N])
			begin
				axi_rid   <= r_rid[N];
				axi_rresp <= r_rresp[N];
				axi_rdata <= r_rdata[N];
				axi_rlast <= r_rlast[N];
			end else if (!OPT_LOWPOWER || i_axi_rvalid)
			begin
				if (NS == 1)
				begin
					axi_rid   <= s_axi_rid[0];
					axi_rresp <= s_axi_rresp[0];
					axi_rdata <= s_axi_rdata[0];
					axi_rlast <= s_axi_rlast[0];
				end else begin
					axi_rid   <= s_axi_rid[mrindex[N]];
					axi_rresp <= s_axi_rresp[mrindex[N]];
					axi_rdata <= s_axi_rdata[mrindex[N]];
					axi_rlast <= s_axi_rlast[mrindex[N]];
				end

				if (mrindex[N] >= NS)
					axi_rresp <= INTERCONNECT_ERROR;
			end else begin
				axi_rid   <= 0;
				axi_rresp <= 0;
				axi_rdata <= 0;
				axi_rlast <= 0;
			end
		end

		assign	M_AXI_ARREADY[N]       = axi_arready && !r_arvalid[N];
		//
		assign	M_AXI_RVALID[N]        = axi_rvalid;
		assign	M_AXI_RID[  N*IW +: IW]= axi_rid;
		assign	M_AXI_RRESP[N* 2 +:  2]= axi_rresp;
		assign	M_AXI_RDATA[N*DW +: DW]= axi_rdata;
		assign	M_AXI_RLAST[N]         = axi_rlast;
`ifdef	FORMAL
		always @(*)
		if (mrgrant[N] && (mrindex[N] < NS))
			assert(s_axi_rready[mrindex[N]] == !r_rvalid[N]);
		else
			assert(!r_rvalid[N]);
		always @(*)
		if (OPT_LOWPOWER && !r_rvalid[N])
		begin
			assert(r_rid[N]   == 0);
			assert(r_rresp[N] == 0);
			assert(r_rdata[N] == 0);
			assert(r_rlast[N] == 0);
		end

		always @(*)
		if (OPT_LOWPOWER && !axi_rvalid)
		begin
			assert(axi_rid   == 0);
			assert(axi_rresp == 0);
			assert(axi_rdata == 0);
			assert(axi_rlast == 0);
		end
`endif
	end endgenerate

	// Count pending transactions
	generate for (N=0; N<NM; N=N+1)
	begin : COUNT_PENDING

		reg	[LGMAXBURST-1:0]	wpending, awpending, rpending,
						missing_wdata;
		//reg				rempty, awempty; // wempty;
		(* keep *) reg	r_wdata_expected;

		initial	awpending    = 0;
		initial	mwempty[N]   = 1;
		initial	mwfull[N]    = 0;
		initial	mwnearfull[N]= 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
		begin
			awpending     <= 0;
			mwempty[N]    <= 1;
			mwfull[N]     <= 0;
			mwnearfull[N] <= 0;
		end else case ({(m_awvalid[N] && slave_awaccepts[N]),
				(M_AXI_BVALID[N] && M_AXI_BREADY[N])})
		2'b01: begin
			awpending     <= awpending - 1;
			mwempty[N]    <= (awpending <= 1);
			mwfull[N]     <= 0;
			mwnearfull[N] <= (&awpending[LGMAXBURST-1:0]);
			end
		2'b10: begin
			awpending <= awpending + 1;
			mwempty[N] <= 0;
			mwfull[N]     <= &awpending[LGMAXBURST-1:1];
			mwnearfull[N] <= (&awpending[LGMAXBURST-1:2])
					&&(awpending[1:0] > 2'b00);
			end
		default: begin end
		endcase

		initial	wpending = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			wpending <= 0;
		else case ({(m_awvalid[N] && slave_awaccepts[N]),
				(m_wvalid[N] && slave_waccepts[N])})
		2'b01: wpending <= wpending - 1;
		2'b10: wpending <= wpending + (m_awlen[N]+1);
		2'b11: wpending <= wpending + (m_awlen[N]);
		default: begin end
		endcase

`ifdef	FORMAL
	always @(*)
	if (m_wvalid[N] && slave_waccepts[N])
		assert(m_wlast[N] == (wpending == 1));
`endif

		always @(*)
			r_wdata_expected = (wpending > 0);


		initial	rpending     = 0;
		initial	mrempty[N]   = 1;
		initial	mrfull[N]    = 0;
		initial	mrnearfull[N]= 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
		begin
			rpending  <= 0;
			mrempty[N]<= 1;
			mrfull[N] <= 0;
			mrnearfull[N] <= 0;
		end else case ({(m_arvalid[N] && slave_raccepts[N]),
				(M_AXI_RVALID[N] && M_AXI_RREADY[N]
					&& M_AXI_RLAST[N])})
		2'b01: begin
			rpending      <= rpending - 1;
			mrempty[N]    <= (rpending == 1);
			mrfull[N]     <= 0;
			mrnearfull[N] <= (&rpending[LGMAXBURST-1:0]);
			end
		2'b10: begin
			rpending      <= rpending + 1;
			mrfull[N]     <= &rpending[LGMAXBURST-1:1];
			mrnearfull[N] <= (&rpending[LGMAXBURST-1:2])
					&&(rpending[1:0] > 2'b00);
			mrempty[N]    <= 0;
			end
		default: begin end
		endcase

		assign	w_mawpending[N] = awpending;
		assign	w_mwpending[N]  = wpending;
		assign	w_mrpending[N]  = rpending;

		always @(*)
			wdata_expected[N] = r_wdata_expected;

	end endgenerate

`ifdef	FORMAL
	localparam	F_LGDEPTH = LGMAXBURST+9;

	//
	//
	//
	//
	wire	[F_LGDEPTH-1:0]	fm_awr_nbursts		[0:NM-1];
	wire	[9-1:0]		fm_wr_pending		[0:NM-1];
	wire	[F_LGDEPTH-1:0]	fm_rd_nbursts		[0:NM-1];
	wire	[F_LGDEPTH-1:0]	fm_rd_outstanding	[0:NM-1];
	//
	wire	[IW-1:0]	fm_wr_checkid		[0:NM-1];
	wire	[NM-1:0]	fm_wr_ckvalid;
	wire	[F_LGDEPTH-1:0]	fm_wrid_nbursts		[0:NM-1];
	wire	[AW-1:0]	fm_wr_addr		[0:NM-1];
	wire	[7:0]		fm_wr_incr		[0:NM-1];
	wire	[1:0]		fm_wr_burst		[0:NM-1];
	wire	[2:0]		fm_wr_size		[0:NM-1];
	wire	[7:0]		fm_wr_len		[0:NM-1];
	//
	wire	[IW-1:0]	fm_rd_checkid		[0:NM-1];
	wire	[NM-1:0]	fm_rd_ckvalid;
	wire	[9-1:0]		fm_rd_cklen		[0:NM-1];
	//
	wire	[AW-1:0]	fm_rd_ckaddr		[0:NM-1];
	wire	[7:0]		fm_rd_ckincr		[0:NM-1];
	wire	[1:0]		fm_rd_ckburst		[0:NM-1];
	wire	[2:0]		fm_rd_cksize		[0:NM-1];
	wire	[7:0]		fm_rd_ckarlen		[0:NM-1];
	//
	wire	[F_LGDEPTH-1:0]	fm_rdid_nbursts	[0:NM-1];
	wire	[F_LGDEPTH-1:0]	fm_rdid_outstanding	[0:NM-1];
	wire	[F_LGDEPTH-1:0]	fm_rdid_ckign_nbursts	[0:NM-1];
	wire	[F_LGDEPTH-1:0]	fm_rdid_ckign_outstanding	[0:NM-1];

	//
	//
	//
	//
	wire	[F_LGDEPTH-1:0]	fs_awr_nbursts		[0:NS-1];
	wire	[9-1:0]		fs_wr_pending		[0:NS-1];
	wire	[F_LGDEPTH-1:0]	fs_rd_nbursts		[0:NS-1];
	wire	[F_LGDEPTH-1:0]	fs_rd_outstanding	[0:NS-1];
	//
	wire	[IW-1:0]	fs_wr_checkid		[0:NS-1];
	wire	[NS-1:0]	fs_wr_ckvalid;
	wire	[F_LGDEPTH-1:0]	fs_wrid_nbursts		[0:NS-1];
	wire	[AW-1:0]	fs_wr_addr		[0:NS-1];
	wire	[7:0]		fs_wr_incr		[0:NS-1];
	wire	[1:0]		fs_wr_burst		[0:NS-1];
	wire	[2:0]		fs_wr_size		[0:NS-1];
	wire	[7:0]		fs_wr_len		[0:NS-1];
	//
	wire	[IW-1:0]	fs_rd_checkid		[0:NS-1];
	wire	[NS-1:0]	fs_rd_ckvalid;
	wire	[9-1:0]		fs_rd_cklen		[0:NS-1];
	//
	wire	[AW-1:0]	fs_rd_ckaddr		[0:NS-1];
	wire	[7:0]		fs_rd_ckincr		[0:NS-1];
	wire	[1:0]		fs_rd_ckburst		[0:NS-1];
	wire	[2:0]		fs_rd_cksize		[0:NS-1];
	wire	[7:0]		fs_rd_ckarlen		[0:NS-1];
	//
	wire	[F_LGDEPTH-1:0]	fs_rdid_nbursts		[0:NS-1];
	wire	[F_LGDEPTH-1:0]	fs_rdid_outstanding	[0:NS-1];
	wire	[F_LGDEPTH-1:0]	fs_rdid_ckign_nbursts	[0:NS-1];
	wire	[F_LGDEPTH-1:0]	fs_rdid_ckign_outstanding	[0:NS-1];

	initial	assert(NS >= 1);
	initial	assert(NM >= 1);

	generate for(N=0; N<NM; N=N+1)
	begin : CHECK_MASTER_GRANTS

		// Write grants
		always @(*)
		for(iM=0; iM<=NS; iM=iM+1)
		begin
			if (wgrant[N][iM])
			begin
				assert((wgrant[N] ^ (1<<iM))==0);
				assert(mwgrant[N]);
				assert(mwindex[N] == iM);
				if (iM < NS)
				begin
					assert(swgrant[iM]);
					assert(swindex[iM] == N);
				end
			end
		end

		always @(*)
		if (mwgrant[N])
			assert(wgrant[N] != 0);

		always @(*)
		if (wrequest[N][NS])
			assert(wrequest[N][NS-1:0] == 0);


		// Read grants
		always @(*)
		for(iM=0; iM<=NS; iM=iM+1)
		begin
			if (rgrant[N][iM])
			begin
				assert((rgrant[N] ^ (1<<iM))==0);
				assert(mrgrant[N]);
				assert(mrindex[N] == iM);
				if (iM < NS)
				begin
					assert(srgrant[iM]);
					assert(srindex[iM] == N);
				end
			end
		end

		always @(*)
		if (mrgrant[N])
			assert(rgrant[N] != 0);

		always @(*)
		if (rrequest[N][NS])
			assert(rrequest[N][NS-1:0] == 0);

	end endgenerate

	reg	[F_LGDEPTH-1:0]	unwr_bursts		[0:NM-1];
	reg	[F_LGDEPTH-1:0]	unwr_data		[0:NM-1];
	reg	[F_LGDEPTH-1:0]	unwrid_bursts		[0:NM-1];

	reg	[F_LGDEPTH-1:0]	unrd_bursts		[0:NM-1];
	reg	[F_LGDEPTH-1:0]	unrd_outstanding	[0:NM-1];
	reg	[F_LGDEPTH-1:0]	unrdid_bursts		[0:NM-1];
	reg	[F_LGDEPTH-1:0]	unrdid_outstanding	[0:NM-1];
	reg	[F_LGDEPTH-1:0]	unrdno_bursts		[0:NM-1];
	reg	[F_LGDEPTH-1:0]	unrdno_outstanding	[0:NM-1];
	//
	reg	[F_LGDEPTH-1:0]	tailrd_bursts		[0:NM-1];
	reg	[F_LGDEPTH-1:0]	tailrd_outstanding	[0:NM-1];
	reg	[F_LGDEPTH-1:0]	tailrdid_bursts		[0:NM-1];
	reg	[F_LGDEPTH-1:0]	tailrdid_outstanding	[0:NM-1];
	reg	[F_LGDEPTH-1:0]	tailrdno_bursts		[0:NM-1];
	reg	[F_LGDEPTH-1:0]	tailrdno_outstanding	[0:NM-1];

	generate for(N=0; N<NM; N=N+1)
	begin : CHECK_MASTERS

		faxi_slave #(
			.C_AXI_ID_WIDTH(IW),
			.C_AXI_DATA_WIDTH(DW),
			.C_AXI_ADDR_WIDTH(AW),
			.F_OPT_ASSUME_RESET(1'b1),
			.F_AXI_MAXSTALL(0),
			.F_AXI_MAXRSTALL(1),
			.F_AXI_MAXDELAY(0),
			.F_OPT_READCHECK(0),
			.F_OPT_NO_RESET(1),
			.F_LGDEPTH(F_LGDEPTH))
		  mstri(.i_clk(S_AXI_ACLK),
			.i_axi_reset_n(S_AXI_ARESETN),
			//
			.i_axi_awid(   M_AXI_AWID[   N*IW +:IW]),
			.i_axi_awaddr( M_AXI_AWADDR[ N*AW +:AW]),
			.i_axi_awlen(  M_AXI_AWLEN[  N* 8 +: 8]),
			.i_axi_awsize( M_AXI_AWSIZE[ N* 3 +: 3]),
			.i_axi_awburst(M_AXI_AWBURST[N* 2 +: 2]),
			.i_axi_awlock( M_AXI_AWLOCK[ N]),
			.i_axi_awcache(M_AXI_AWCACHE[N* 4 +: 4]),
			.i_axi_awprot( M_AXI_AWPROT[ N* 3 +: 3]),
			.i_axi_awqos(  M_AXI_AWQOS[  N* 4 +: 4]),
			.i_axi_awvalid(M_AXI_AWVALID[N]),
			.i_axi_awready(M_AXI_AWREADY[N]),
			//
			.i_axi_wdata( M_AXI_WDATA[ N*DW   +: DW]),
			.i_axi_wstrb( M_AXI_WSTRB[ N*DW/8 +: DW/8]),
			.i_axi_wlast( M_AXI_WLAST[ N]),
			.i_axi_wvalid(M_AXI_WVALID[N]),
			.i_axi_wready(M_AXI_WREADY[N]),
			//
			.i_axi_bid(   M_AXI_BID[   N*IW +:IW]),
			.i_axi_bresp( M_AXI_BRESP[ N*2 +: 2]),
			.i_axi_bvalid(M_AXI_BVALID[N]),
			.i_axi_bready(M_AXI_BREADY[N]),
			//
			.i_axi_arid(   M_AXI_ARID[   N*IW +:IW]),
			.i_axi_arready(M_AXI_ARREADY[N]),
			.i_axi_araddr( M_AXI_ARADDR[ N*AW +:AW]),
			.i_axi_arlen(  M_AXI_ARLEN[  N* 8 +: 8]),
			.i_axi_arsize( M_AXI_ARSIZE[ N* 3 +: 3]),
			.i_axi_arburst(M_AXI_ARBURST[N* 2 +: 2]),
			.i_axi_arlock( M_AXI_ARLOCK[ N]),
			.i_axi_arcache(M_AXI_ARCACHE[N* 4 +: 4]),
			.i_axi_arprot( M_AXI_ARPROT[ N* 3 +: 3]),
			.i_axi_arqos(  M_AXI_ARQOS[  N* 4 +: 4]),
			.i_axi_arvalid(M_AXI_ARVALID[N]),
			//
			//
			.i_axi_rid(   M_AXI_RID[   N*IW +: IW]),
			.i_axi_rdata( M_AXI_RDATA[ N*DW +: DW]),
			.i_axi_rresp( M_AXI_RRESP[ N* 2 +: 2]),
			.i_axi_rlast( M_AXI_RLAST[ N]),
			.i_axi_rvalid(M_AXI_RVALID[N]),
			.i_axi_rready(M_AXI_RREADY[N]),
			//
			.f_axi_awr_nbursts(fm_awr_nbursts[N]),
			.f_axi_wr_pending(fm_wr_pending[N]),
			.f_axi_rd_nbursts(fm_rd_nbursts[N]),
			.f_axi_rd_outstanding(fm_rd_outstanding[N]),
			//
			.f_axi_wr_checkid(fm_wr_checkid[N]),
			.f_axi_wr_ckvalid(fm_wr_ckvalid[N]),
			.f_axi_wrid_nbursts(fm_wrid_nbursts[N]),
			.f_axi_wr_addr( fm_wr_addr[N]),
			.f_axi_wr_incr( fm_wr_incr[N]),
			.f_axi_wr_burst(fm_wr_burst[N]),
			.f_axi_wr_size( fm_wr_size[N]),
			.f_axi_wr_len(  fm_wr_len[N]),
			//
			.f_axi_rd_checkid(fm_rd_checkid[N]),
			.f_axi_rd_ckvalid(fm_rd_ckvalid[N]),
			.f_axi_rd_cklen(fm_rd_cklen[N]),
			.f_axi_rd_ckaddr(fm_rd_ckaddr[N]),
			.f_axi_rd_ckincr(fm_rd_ckincr[N]),
			.f_axi_rd_ckburst(fm_rd_ckburst[N]),
			.f_axi_rd_cksize(fm_rd_cksize[N]),
			.f_axi_rd_ckarlen(fm_rd_ckarlen[N]),
			.f_axi_rdid_nbursts(fm_rdid_nbursts[N]),
			.f_axi_rdid_outstanding(fm_rdid_outstanding[N]),
			.f_axi_rdid_ckign_nbursts(fm_rdid_ckign_nbursts[N]),
			.f_axi_rdid_ckign_outstanding(fm_rdid_ckign_outstanding[N]));

		always @(*)
		begin
			unwr_bursts[N] = 0;
			if (r_awvalid[N])
				unwr_bursts[N] = unwr_bursts[N] + 1;
			if (mwgrant[N] && (mwindex[N]<NS) && s_axi_awvalid[mwindex[N]])
				unwr_bursts[N] = unwr_bursts[N] + 1;
			if (r_bvalid[N])
				unwr_bursts[N] = unwr_bursts[N] + 1;
			if (M_AXI_BVALID[N])
				unwr_bursts[N] = unwr_bursts[N] + 1;
		end

		always @(*)
		begin
			unwr_data[N] = 0;
			if (mwgrant[N] && (mwindex[N]<NS) && s_axi_wvalid[mwindex[N]])
				unwr_data[N] = unwr_data[N] + 1;
			if (!mwgrant[N] || (mwindex[N]==NS)
				|| !s_axi_wvalid[mwindex[N]] || !S_AXI_WLAST[N])
			begin
				if (r_wvalid[N])
					unwr_data[N] = unwr_data[N] + 1;
			end
		end

		always @(*)
		begin
			unwrid_bursts[N] = 0;
			if (r_awvalid[N] && r_awid[N] == fm_wr_checkid[N])
				unwrid_bursts[N] = unwrid_bursts[N] + 1;
			if (mwgrant[N] && (mwindex[N]<NS) && s_axi_awvalid[mwindex[N]]
					&& s_axi_awid[mwindex[N]] == fm_wr_checkid[N])
				unwrid_bursts[N] = unwrid_bursts[N] + 1;
			if (r_bvalid[N] && r_bid[N] == fm_wr_checkid[N])
				unwrid_bursts[N] = unwrid_bursts[N] + 1;
			if (M_AXI_BVALID[N] && M_AXI_BID[N*IW +: IW] == fm_wr_checkid[N])
				unwrid_bursts[N] = unwrid_bursts[N] + 1;
		end

		//
		// Check write counters
		//
		always @(*)
		assert(fm_awr_nbursts[N] == { 1'b0, w_mawpending[N] }
				+ (r_awvalid[N] ? 1:0));

		always @(*)
		if (r_awvalid[N])
			assert(w_mwpending[N] == 0);
		else
			assert(fm_wr_pending[N]+(r_wvalid[N]? 1:0)
				== { 1'b0, w_mwpending[N] });

		always @(*)
		if (S_AXI_ARESETN && wgrant[N][NS])
			assert(fm_awr_nbursts[N]==
				+ ((fm_wr_pending[N]>0) ? 1:0)
				+ ((fm_wr_pending[N]==0)&&(r_wvalid[N]&&r_wlast[N]) ? 1:0)
				+ (M_AXI_BVALID[N] ? 1:0));

/*
		always @(*)
		if (!mwgrant[N])
		begin
			assert(!M_AXI_BVALID[N]);

			assert(fm_awr_nbursts[N]==(M_AXI_AWREADY[N] ? 0:1));
			assert(w_mawpending[N] == 0);
			assert(w_mwpending[N] == 0);
		end
*/
		always @(posedge S_AXI_ACLK)
		if (S_AXI_ARESETN)
		begin
			if ((fm_wr_pending[N] > 0)&&(!$past(M_AXI_WVALID[N]))
				&&(!$past(M_AXI_WVALID[N],2)))
				assume(M_AXI_WVALID[N]);
		end

		////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////

		//
		// Check read counters
		//
		always @(*)
		begin
			unrd_bursts[N] = 0;
			if (r_arvalid[N])
				unrd_bursts[N] = unrd_bursts[N] + 1;
			if (mrgrant[N] && (mrindex[N]<NS) && s_axi_arvalid[mrindex[N]])
				unrd_bursts[N] = unrd_bursts[N] + 1;
			if (r_rvalid[N] && r_rlast[N])
				unrd_bursts[N] = unrd_bursts[N] + 1;
			if (M_AXI_RVALID[N] && M_AXI_RLAST[N])
				unrd_bursts[N] = unrd_bursts[N] + 1;
		end

		always @(*)
		begin
			unrd_outstanding[N] = 0;
			if (r_arvalid[N])
				unrd_outstanding[N] = unrd_outstanding[N] + r_arlen[N]+1;
			if (mrgrant[N] && (mrindex[N]<NS) && s_axi_arvalid[mrindex[N]])
				unrd_outstanding[N] = unrd_outstanding[N] + s_axi_arlen[N]+1;
			if (r_rvalid[N])
				unrd_outstanding[N] = unrd_outstanding[N] + 1;
			if (M_AXI_RVALID[N])
				unrd_outstanding[N] = unrd_outstanding[N] + 1;
		end

		//
		//
		//

		always @(*)
		begin
			unrdid_bursts[N] = 0;
			if (r_arvalid[N]&& (r_arid[N]==fm_rd_checkid[N]))
				unrdid_bursts[N] = unrdid_bursts[N] + 1;
			if (mrgrant[N] && (mrindex[N]<NS) && s_axi_arvalid[mrindex[N]] && s_axi_arid[mrindex[N]] == fm_rd_checkid[N])
				unrdid_bursts[N] = unrdid_bursts[N] + 1;
			if (r_rvalid[N] && (r_rid[N] == fm_rd_checkid[N])
					&& r_rlast[N])
				unrdid_bursts[N] = unrdid_bursts[N] + 1;
			if (M_AXI_RVALID[N] && M_AXI_RLAST[N]
				&&(M_AXI_RID[N*IW+:IW] == fm_rd_checkid[N]))
				unrdid_bursts[N] = unrdid_bursts[N] + 1;
		end

		always @(*)
		begin
			unrdid_outstanding[N] = 0;
			if (r_arvalid[N]&&(r_arid[N]==fm_rd_checkid[N]))
				unrdid_outstanding[N] = r_arlen[N]+1;
			if (mrgrant[N] && (mrindex[N]<NS) && s_axi_arvalid[mrindex[N]] && s_axi_arid[mrindex[N]] == fm_rd_checkid[N])
				unrdid_outstanding[N] = unrdid_outstanding[N]+s_axi_arlen[N]+1;
			if (r_rvalid[N] && (r_rid[N] == fm_rd_checkid[N]))
				unrdid_outstanding[N] = unrdid_outstanding[N] + 1;
			if (M_AXI_RVALID[N]
				&&(M_AXI_RID[N*IW+:IW] == fm_rd_checkid[N]))
				unrdid_outstanding[N] = unrdid_outstanding[N] + 1;
		end


		//
		//

		always @(*)
		begin
			unrdno_bursts[N] = 0;
			if (r_arvalid[N]&& (r_arid[N]!=fm_rd_checkid[N]))
				unrdno_bursts[N] = unrdno_bursts[N] + 1;
			if (mrgrant[N] && (mrindex[N]<NS) && s_axi_arvalid[mrindex[N]] && s_axi_arid[mrindex[N]] != fm_rd_checkid[N])
				unrdno_bursts[N] = unrdno_bursts[N] + 1;
			if (r_rvalid[N] && (r_rid[N] != fm_rd_checkid[N])
					&& r_rlast[N])
				unrdno_bursts[N] = unrdno_bursts[N] + 1;
			if (M_AXI_RVALID[N] && M_AXI_RLAST[N]
				&&(M_AXI_RID[N*IW+:IW] != fm_rd_checkid[N]))
				unrdno_bursts[N] = unrdno_bursts[N] + 1;
		end

		always @(*)
		begin
			unrdno_outstanding[N] = 0;
			if (r_arvalid[N]&&(r_arid[N]!=fm_rd_checkid[N]))
				unrdno_outstanding[N] = r_arlen[N]+1;
			if (mrgrant[N] && (mrindex[N]<NS) && s_axi_arvalid[mrindex[N]] && s_axi_arid[mrindex[N]] != fm_rd_checkid[N])
				unrdno_outstanding[N] = unrdno_outstanding[N]+s_axi_arlen[N]+1;
			if (r_rvalid[N] && (r_rid[N] != fm_rd_checkid[N]))
				unrdno_outstanding[N] = unrdno_outstanding[N] + 1;
			if (M_AXI_RVALID[N]
				&&(M_AXI_RID[N*IW+:IW] != fm_rd_checkid[N]))
				unrdno_outstanding[N] = unrdno_outstanding[N] + 1;
		end

		// Tail bursts
		always @(*)
		begin
			tailrd_bursts[N] = 0;
			if (r_rvalid[N] && r_rlast[N])
				tailrd_bursts[N] = tailrd_bursts[N] + 1;
			if (M_AXI_RVALID[N] && M_AXI_RLAST[N])
				tailrd_bursts[N] = tailrd_bursts[N] + 1;
		end

		always @(*)
		begin
			tailrd_outstanding[N] = 0;
			if (r_rvalid[N])
				tailrd_outstanding[N] = tailrd_outstanding[N] + 1;
			if (M_AXI_RVALID[N])
				tailrd_outstanding[N] = tailrd_outstanding[N] + 1;
		end

		//
		//
		//

		always @(*)
		begin
			tailrdid_bursts[N] = 0;
			if (r_rvalid[N] && (r_rid[N] == fm_rd_checkid[N])
					&& r_rlast[N])
				tailrdid_bursts[N] = tailrdid_bursts[N] + 1;
			if (M_AXI_RVALID[N] && M_AXI_RLAST[N]
				&&(M_AXI_RID[N*IW+:IW] == fm_rd_checkid[N]))
				tailrdid_bursts[N] = tailrdid_bursts[N] + 1;
		end

		always @(*)
		begin
			tailrdid_outstanding[N] = 0;
			if (r_rvalid[N] && (r_rid[N] == fm_rd_checkid[N]))
				tailrdid_outstanding[N] = tailrdid_outstanding[N] + 1;
			if (M_AXI_RVALID[N]
				&&(M_AXI_RID[N*IW+:IW] == fm_rd_checkid[N]))
				tailrdid_outstanding[N] = tailrdid_outstanding[N] + 1;
		end


		//
		//

		always @(*)
		begin
			tailrdno_bursts[N] = 0;
			if (r_rvalid[N] && (r_rid[N] != fm_rd_checkid[N])
					&& r_rlast[N])
				tailrdno_bursts[N] = tailrdno_bursts[N] + 1;
			if (M_AXI_RVALID[N] && M_AXI_RLAST[N]
				&&(M_AXI_RID[N*IW+:IW] != fm_rd_checkid[N]))
				tailrdno_bursts[N] = tailrdno_bursts[N] + 1;
		end

		always @(*)
		begin
			tailrdno_outstanding[N] = 0;
			if (r_rvalid[N] && (r_rid[N] != fm_rd_checkid[N]))
				tailrdno_outstanding[N] = tailrdno_outstanding[N] + 1;
			if (M_AXI_RVALID[N]
				&&(M_AXI_RID[N*IW+:IW] != fm_rd_checkid[N]))
				tailrdno_outstanding[N] = tailrdno_outstanding[N] + 1;
		end


		//
		//

		always @(*)
		if (S_AXI_ARESETN)
		begin
			assert(fm_rd_outstanding[N] >= unrd_outstanding[N]);
			assert((fm_rd_outstanding[N]-fm_rdid_outstanding[N])
				>= unrdno_outstanding[N]);
			assert(fm_rdid_outstanding[N] >= unrdid_outstanding[N]);
		end

		always @(*)
		if (!mrgrant[N] || rgrant[N][NS])
		begin
			assert(fm_rd_outstanding[N] == unrd_outstanding[N]);
			assert(fm_rdid_outstanding[N] == unrdid_outstanding[N]);
			//
			//
			if (fm_rdid_outstanding[N] > 0)
			begin
				if (M_AXI_RVALID[N])
					assert(M_AXI_RID[N*IW+:IW] == fm_rd_checkid[N]);
				if (r_arvalid[N])
					assert(r_arid[N] == fm_rd_checkid[N]);
			end
			assert(w_mrpending[N] == 0);
			assert(fm_rd_nbursts[N] == (r_arvalid[N]? 1:0)
					+((M_AXI_RVALID[N] && M_AXI_RLAST[N])? 1:0));
			assert(fm_rd_outstanding[N] == unrd_outstanding[N]);
			assert(fm_rdid_nbursts[N] == unrdid_bursts[N]);
			assert(fm_rdid_outstanding[N] == unrdid_outstanding[N]);
			//
			assert((fm_rd_nbursts[N]-fm_rdid_nbursts[N]) == unrdno_bursts[N]);
			assert((fm_rd_outstanding[N]-fm_rdid_outstanding[N]) == unrdno_outstanding[N]);
		end

		always @(*)
			assert(fm_rd_nbursts[N] == { 1'b0, w_mrpending[N] }
				+ (r_arvalid[N] ? 1:0));

		always @(*)
		if (S_AXI_ARESETN && rgrant[N][NS])
			assert(fm_rd_outstanding[N]
				== (r_arvalid[N] ? r_arlen[N]+1:0)
				+(M_AXI_RVALID[N] ? 1:0));

		always @(*)
		if (!mrgrant[N])
		begin
			assert(!M_AXI_RVALID[N]);
			assert(fm_rd_outstanding[N]
				== (r_arvalid[N] ? (r_arlen[N]+1):0));
			assert(w_mrpending[N] == 0);
		end

		//
		// Check full/empty flags
		//
		localparam	[LGMAXBURST-1:0] NEAR_THRESHOLD = -2;

		always @(*)
		begin
			assert(mwfull[N] == &w_mawpending[N]);
			assert(mwnearfull[N]==(w_mawpending[N] >= NEAR_THRESHOLD));
			assert(mwempty[N] == (w_mawpending[N] == 0));
		end

		always @(*)
		begin
			assert(mrfull[N] == &w_mrpending[N]);
			assert(mrnearfull[N]==(w_mrpending[N] >= NEAR_THRESHOLD));
			assert(mrempty[N] == (w_mrpending[N] == 0));
		end


	end endgenerate

	generate for(M=0; M<NS; M=M+1)
	begin : CHECK_SLAVES

		faxi_master #(
			.C_AXI_ID_WIDTH(IW),
			.C_AXI_DATA_WIDTH(DW),
			.C_AXI_ADDR_WIDTH(AW),
			.F_OPT_ASSUME_RESET(1'b1),
			.F_AXI_MAXSTALL(1),
			.F_AXI_MAXRSTALL(0),
			.F_AXI_MAXDELAY(2),
			.F_OPT_READCHECK(0),
			.F_OPT_NO_RESET(1),
			.F_LGDEPTH(F_LGDEPTH))
		  slvi(.i_clk(S_AXI_ACLK),
			.i_axi_reset_n(S_AXI_ARESETN),
			//
			.i_axi_awid(   S_AXI_AWID[   M*IW+:IW]),
			.i_axi_awaddr( S_AXI_AWADDR[ M*AW +: AW]),
			.i_axi_awlen(  S_AXI_AWLEN[  M*8 +: 8]),
			.i_axi_awsize( S_AXI_AWSIZE[ M*3 +: 3]),
			.i_axi_awburst(S_AXI_AWBURST[M*2 +: 2]),
			.i_axi_awlock( S_AXI_AWLOCK[ M]),
			.i_axi_awcache(S_AXI_AWCACHE[M*4 +: 4]),
			.i_axi_awprot( S_AXI_AWPROT[ M*3 +: 3]),
			.i_axi_awqos(  S_AXI_AWQOS[  M*4 +: 4]),
			.i_axi_awvalid(S_AXI_AWVALID[M]),
			.i_axi_awready(S_AXI_AWREADY[M]),
			//
			.i_axi_wready(S_AXI_WREADY[M]),
			.i_axi_wdata( S_AXI_WDATA[ M*DW   +: DW]),
			.i_axi_wstrb( S_AXI_WSTRB[ M*DW/8 +: DW/8]),
			.i_axi_wlast( S_AXI_WLAST[ M]),
			.i_axi_wvalid(S_AXI_WVALID[M]),
			//
			.i_axi_bid(   S_AXI_BID[   M*IW +: IW]),
			.i_axi_bresp( S_AXI_BRESP[ M*2 +: 2]),
			.i_axi_bvalid(S_AXI_BVALID[M]),
			.i_axi_bready(S_AXI_BREADY[M]),
			//
			.i_axi_arid(   S_AXI_ARID[   M*IW +:IW]),
			.i_axi_araddr( S_AXI_ARADDR[ M*AW +:AW]),
			.i_axi_arlen(  S_AXI_ARLEN[  M*8  +: 8]),
			.i_axi_arsize( S_AXI_ARSIZE[ M*3  +: 3]),
			.i_axi_arburst(S_AXI_ARBURST[M*2  +: 2]),
			.i_axi_arlock( S_AXI_ARLOCK[ M]),
			.i_axi_arcache(S_AXI_ARCACHE[M* 4 +: 4]),
			.i_axi_arprot( S_AXI_ARPROT[ M* 3 +: 3]),
			.i_axi_arqos(  S_AXI_ARQOS[  M* 4 +: 4]),
			.i_axi_arvalid(S_AXI_ARVALID[M]),
			.i_axi_arready(S_AXI_ARREADY[M]),
			//
			//
			.i_axi_rresp( S_AXI_RRESP[ M*2 +: 2]),
			.i_axi_rvalid(S_AXI_RVALID[M]),
			.i_axi_rdata( S_AXI_RDATA[ M*DW +: DW]),
			.i_axi_rready(S_AXI_RREADY[M]),
			.i_axi_rlast( S_AXI_RLAST[ M]),
			.i_axi_rid(   S_AXI_RID[   M*IW +: IW]),
			//
			.f_axi_awr_nbursts(fs_awr_nbursts[M]),
			.f_axi_wr_pending(fs_wr_pending[M]),
			.f_axi_rd_nbursts(fs_rd_nbursts[M]),
			.f_axi_rd_outstanding(fs_rd_outstanding[M]),
			.f_axi_wr_checkid(fs_wr_checkid[M]),
			.f_axi_wr_ckvalid(fs_wr_ckvalid[M]),
			.f_axi_wrid_nbursts(fs_wrid_nbursts[M]),
			.f_axi_wr_addr(fs_wr_addr[M]),
			.f_axi_wr_incr(fs_wr_incr[M]),
			.f_axi_wr_burst(fs_wr_burst[M]),
			.f_axi_wr_size(fs_wr_size[M]),
			.f_axi_wr_len(fs_wr_len[M]),
			//
			.f_axi_rd_checkid(fs_rd_checkid[M]),
			.f_axi_rd_ckvalid(fs_rd_ckvalid[M]),
			.f_axi_rd_cklen(fs_rd_cklen[M]),
			.f_axi_rd_ckaddr(fs_rd_ckaddr[M]),
			.f_axi_rd_ckincr(fs_rd_ckincr[M]),
			.f_axi_rd_ckburst(fs_rd_ckburst[M]),
			.f_axi_rd_cksize(fs_rd_cksize[M]),
			.f_axi_rd_ckarlen(fs_rd_ckarlen[M]),
			//
			.f_axi_rdid_nbursts(fs_rdid_nbursts[M]),
			.f_axi_rdid_outstanding(fs_rdid_outstanding[M]),
			.f_axi_rdid_ckign_nbursts(fs_rdid_ckign_nbursts[M]),
			.f_axi_rdid_ckign_outstanding(fs_rdid_ckign_outstanding[M]));

		always @(*)
		if (!swgrant[M])
		begin
			assert(fs_awr_nbursts[M] == 0);
			assert(fs_wr_pending[M] == 0);
		end

		always @(*)
		if (!srgrant[M])
			assert(fs_rd_nbursts[M] == 0);

		always @(*)
		if (srgrant[M])
		begin
			assume((fs_rd_checkid[M] == fm_rd_checkid[srindex[M]])
				|| !fs_rd_ckvalid[M]);
		end

		always @(*)
			assert(fs_awr_nbursts[M] < { 1'b1, {(F_LGDEPTH-1){1'b0}}});
		always @(*)
			assert(fs_wr_pending[M] < { 1'b1, {(F_LGDEPTH-1){1'b0}}});
		always @(*)
			assert(fs_rd_outstanding[M] < { 1'b1, {(F_LGDEPTH-1){1'b0}}});

		always @(*)
		if (S_AXI_AWVALID[M])
			assert(((S_AXI_AWADDR[M*AW +: AW]
				^ SLAVE_ADDR[M*AW +: AW])
				& SLAVE_MASK[M*AW +: AW]) == 0);

		always @(*)
		if (S_AXI_ARVALID[M])
			assert(((S_AXI_ARADDR[M*AW +: AW]
				^ SLAVE_ADDR[M*AW +: AW])
				& SLAVE_MASK[M*AW +: AW]) == 0);

	end endgenerate

	generate for(N=0; N<NM; N=N+1)
	begin : CORRELATE_OUTSTANDING
		wire	[AW-1:0]	next_waddr, dbl_next_waddr;
		reg	[LGNS-1:0]	valwslv;
		wire	[7:0]		fs_wr_inc, fs_wr_dblinc;

		always @(*)
		begin
			valwslv = 0;
			if (mwgrant[N] && mwindex[N] < NS)
				valwslv = mwindex[N];
		end

		faxi_addr #(AW) get_next_waddr (fs_wr_addr[valwslv],
				fs_wr_size[valwslv],
				fs_wr_burst[valwslv],
				fs_wr_len[ valwslv],
				fs_wr_inc,
				next_waddr);

		faxi_addr #(AW) get_dblnext_waddr (next_waddr,
				fs_wr_size[valwslv],
				fs_wr_burst[valwslv],
				fs_wr_len[ valwslv],
				fs_wr_dblinc,
				dbl_next_waddr);

		always @(*)
		if (mwgrant[N] && (mwindex[N] < NS))
		begin
			assert(fm_awr_nbursts[N] == fs_awr_nbursts[mwindex[N]]
					+ unwr_bursts[N]);

			assert(fm_wrid_nbursts[N] == fs_wrid_nbursts[mwindex[N]]
					+ unwrid_bursts[N]);

			assert(((fm_awr_nbursts[N]
				- (r_awvalid[N] ? 1:0)
				- (s_axi_awvalid[N] ? 1:0)
				- (r_bvalid[N] ? 1:0)
				- (M_AXI_BVALID[N] ? 1:0)
				- (fs_wr_pending[N] > 0)) > 0)
				||(!s_axi_bvalid[N]));

			assert(((fm_wrid_nbursts[N]
				-((r_awvalid[N]&&r_awid[N]==fm_wr_checkid[N]) ? 1:0)
				-((s_axi_awvalid[mwindex[N]]&&s_axi_awid[mwindex[N]]==fm_wr_checkid[N]) ? 1:0)
				-((r_bvalid[N]&&r_bid[N]==fm_wr_checkid[N])?1:0)
				- (M_AXI_BVALID[N]&&M_AXI_BID[N]==fm_wr_checkid[N] ? 1:0)
				- (fs_wr_ckvalid[mwindex[N]] ? 1:0)) > 0)
				||(!s_axi_bvalid[mwindex[N]]||s_axi_bid[mwindex[N]]==fm_wr_checkid[N]));

/*
			assert(((fm_awr_nbursts[N]-fm_wrid_nbursts[N]
				-((r_awvalid[N]&&r_awid[N]!=fm_wr_checkid[N]) ? 1:0)
				-((s_axi_awvalid[mwindex[N]]&&s_axi_awid[mwindex[N]]!=fm_wr_checkid[N]) ? 1:0)
				-((r_bvalid[N]&&r_bid[N]!=fm_wr_checkid[N])?1:0)
				- (M_AXI_BVALID[N]&&M_AXI_BID[N]!=fm_wr_checkid[N] ? 1:0)
				-((!fs_wr_ckvalid[mwindex[N]]&&fs_wr_pending[mwindex[mwindex[N]]]>0) ? 1:0)) > 0)
				||(!s_axi_bvalid[mwindex[N]]||s_axi_bid[mwindex[N]]!=fm_wr_checkid[mwindex[N]]));
*/

`ifdef	THIS_DIDNT_WORK
			///
			/*
			if (s_axi_bvalid[N])
				assert(fm_awr_nbursts[N] - awr_returning >
					fs_awr_nbursts[N]
					+ (r_awvalid[N] ? 1:0)
					+ (s_axi_awvalid[N] ? 1:0));
			else
			*/
				assert(fm_awr_nbursts[N] - awr_returning >=
					fs_awr_nbursts[N]
					+ (r_awvalid[N] ? 1:0)
					+ (s_axi_awvalid[N] ? 1:0));
			///
			/*
			if (s_axi_bvalid[N] && s_axi_bid[N] == fs_wr_checkid[N])
				assert(fm_wrid_nbursts[N] - wrid_returning >=
				fs_wrid_nbursts[mwindex[N]]
				+ ((r_awvalid[N] && r_awid[N]==fm_wr_checkid[N]) ? 1:0)
				+ ((s_axi_awvalid[N] && s_axi_awid[N]==fm_wr_checkid[N]) ? 1:0));

			else
			*/
				assert(fm_wrid_nbursts[N] - wrid_returning >=
				fs_wrid_nbursts[mwindex[N]]
				+ ((r_awvalid[N] && r_awid[N]==fm_wr_checkid[N]) ? 1:0)
				+ ((s_axi_awvalid[N] && s_axi_awid[N]==fm_wr_checkid[N]) ? 1:0));

			///
			/*
			if (s_axi_bvalid[N] && s_axi_bid[N] != fs_wr_checkid[N])
				assert((fm_awr_nbursts[N]-fm_wrid_nbursts[N])
					- (awr_returning-wrid_returning) >
				(fs_awr_nbursts[mwindex[N]]-fs_wrid_nbursts[mwindex[N]])
				+ ((r_awvalid[N] && r_awid[N]!=fm_wr_checkid[N]) ? 1:0)
				+ ((s_axi_awvalid[N] && s_axi_awid[N]!=fm_wr_checkid[N]) ? 1:0));

			else
			*/
				assert((fm_awr_nbursts[N]-fm_wrid_nbursts[N])
					- (awr_returning-wrid_returning) >=
				(fs_awr_nbursts[N]-fs_wrid_nbursts[N])
				+ ((r_awvalid[N] && r_awid[N]!=fm_wr_checkid[N]) ? 1:0)
				+ ((s_axi_awvalid[N] && s_axi_awid[N]!=fm_wr_checkid[N]) ? 1:0));
`endif
			////
			////


			if (r_awvalid[N] && s_axi_awvalid[mwindex[N]])
			begin
				assert((s_axi_wvalid[N] && S_AXI_WLAST[N])
					|| (r_wvalid[N] && r_wlast[N]));
			end

			if (r_awvalid[N])
				assert((fm_wr_pending[N] == r_awlen[N]+1)
					||((fm_wr_pending[N] == r_awlen[N])
						&& r_wvalid[N]));
			else if (s_axi_awvalid[mwindex[N]])
			begin
				if (fs_wr_pending[N] > 0)
					assert(fs_wr_pending[N] ==unwr_data[N]);
				else
				   assert((fm_wr_pending[N] == s_axi_awlen[N]+1)
					||(fm_wr_pending[N] == s_axi_awlen[N]
					    &&(r_wvalid[N] || s_axi_wvalid[N]))
					||(fm_wr_pending[N] == 0)
					||(fm_wr_pending[N]==s_axi_awlen[N]-1));
			end else begin
				assert(fm_wr_pending[N] + unwr_data[N]
					== fs_wr_pending[mwindex[N]]);

				// .f_axi_wr_addr(fs_wr_addr[M]),
				if (!r_wvalid[N] && !S_AXI_WVALID[mwindex[N]])
					if (fm_wr_pending[N]>0)
					assert(fm_wr_addr[N]==fs_wr_addr[mwindex[N]]);
				else if (S_AXI_WVALID[N] && !r_wvalid[N])
				begin
					if (fm_wr_pending[N]>1)
					assert(fm_wr_addr[N]==next_waddr);
				end else if (S_AXI_WVALID[N] && r_wvalid[N])
				begin
					if (fm_wr_pending[N]>1)
					assert(fm_wr_addr[N]==dbl_next_waddr);
				end
				//
				//
				if (fm_wr_pending[N]>1)
				begin
				assert(fm_wr_incr[N] ==fs_wr_incr[ mwindex[N]]);
				assert(fm_wr_burst[N]==fs_wr_burst[mwindex[N]]);
				assert(fm_wr_size[N] ==fs_wr_size[ mwindex[N]]);
				assert(fm_wr_len[N]  ==fs_wr_len[  mwindex[N]]);
				end

				if (fm_wr_ckvalid[N])
					assert(fs_wr_ckvalid[N]);
				else if (fm_wr_pending[N] > 0)
					assert(!fs_wr_ckvalid[N]);
			end

			if ((r_awvalid[N] || s_axi_awvalid[mwindex[N]])
				&& fm_wr_ckvalid[N])
			begin
				assert((s_axi_awvalid[mwindex[N]]
					    && s_axi_awid[N] == fm_wr_checkid[N])
					||(r_awvalid[N]
					    && r_awid[N] == fm_wr_checkid[N]));
			end

			if (!s_axi_awvalid[mwindex[N]]
				&& (r_awvalid[mwindex[N]]
					&& !wrequest[N][mwindex[N]]))
			begin
				assert((fm_wr_pending[N]== r_awlen[N]
						&&(r_wvalid[N]))
					||(fm_wr_pending[N]== r_awlen[N]+1));
			end

			if (r_wvalid[N] && s_axi_wvalid[mwindex[N]]
						&& !S_AXI_WLAST[N])
			begin
				if (s_axi_awvalid[mwindex[N]])
					assert(fs_wr_pending[N] == 0);
				else
					assert(fs_wr_pending[N] >= 1+(r_wlast[N]? 1:0));
			end
/*
			if (S_AXI_AWVALID[mwindex[N]] || s_axi_awvalid[mwindex[N]])
			begin
				assert(fs_wr_pending[N] == 0);
			end else begin
				assert(fs_wr_pending[mwindex[N]] + unwr_pending[N]
					== fm_wr_pending[N]);
			end

		end else if (!mwgrant[N] || (mwindex[N]==NS))
		begin
			if (!mwgrant[N])
			begin
				assert(fm_awr_nbursts[N] == unwr_bursts[N]);
				// assert(fm_wr_pending[N] == 0);
			end else begin
				assert(fm_awr_nbursts[N] >=
						(r_awvalid[N] ? 1:0)
						+(M_AXI_BVALID[N]  ? 1:0));
			end
*/
		end

		always @(*)
			assert(M_AXI_AWREADY[N] == ((fm_wr_pending[N] == 0)
				&& !r_wvalid[N] && !r_awvalid[N]));

		always @(*)
			assert(M_AXI_WREADY[N] == ((!r_wvalid[N])
				&& (fm_wr_pending[N] > 0)));

		always @(*)
		if (mwgrant[N] && (mwindex[N]==NS))
		begin
			assert(fm_awr_nbursts[N] <= 1);
			if (!r_awvalid[N] && (fm_awr_nbursts[N] > 0))
			begin
				if (fm_wrid_nbursts[N] > 0)
					assert(fm_wr_checkid[N]==M_AXI_BID[IW*N+: IW]);
				else
					assert(fm_wr_checkid[N]!=M_AXI_BID[IW*N+: IW]);
			end else if (r_awvalid[N])
			begin
				if (fm_wrid_nbursts[N] > 0)
					assert(r_awid[N] == fm_wr_checkid[N]);
				else
					assert(r_awid[N] != fm_wr_checkid[N]);
			end
		end

		always @(*)
		if (mwgrant[N] && !wgrant[N][NS])
			assume(fm_wr_checkid[N] == fs_wr_checkid[mwindex[N]]);

		always @(*)
		if (!mwgrant[N])
		begin
			assert(fm_awr_nbursts[N] == (r_awvalid[N] ? 1:0));
			assert(fm_wrid_nbursts[N] == ((r_awvalid[N]&&(r_awid[N] == fm_wr_checkid[N])) ? 1:0));
		end

		////////////////////////////////////////////////////////////////
		//
		// Read counter correlators
		//

		always @(*)
		if (mrgrant[N] && (mrindex[N] < NS))
		begin
			assert(fm_rd_nbursts[N]
				== fs_rd_nbursts[mrindex[N]] + unrd_bursts[N]);

			assert(fm_rd_outstanding[N]
			  == fs_rd_outstanding[mrindex[N]] + unrd_outstanding[N]);
			assert(fm_rdid_nbursts[N] >= unrdid_bursts[N]);
			assert(fm_rdid_outstanding[N] >= unrdid_outstanding[N]);

			assert(fm_rd_nbursts[N]-fm_rdid_nbursts[N] >= unrdno_bursts[N]);
			assert(fm_rd_outstanding[N]-fm_rdid_outstanding[N]
				>= unrdno_outstanding[N]);

			if (fm_rd_checkid[N] == fs_rd_checkid[mrindex[N]])
			begin
				assert(fm_rdid_nbursts[N]
				  ==fs_rdid_nbursts[mrindex[N]]+ unrdid_bursts[N]);

				assert(fm_rdid_outstanding[N]
				  == fs_rdid_outstanding[mrindex[N]]
					+ unrdid_outstanding[N]);

				assert((fm_rd_nbursts[N]-fm_rdid_nbursts[N])
				  == ((fs_rd_nbursts[mrindex[N]]-fs_rdid_nbursts[mrindex[N]]) + unrdno_bursts[N]));
				assert((fm_rd_outstanding[N]-fm_rdid_outstanding[N]) == (fs_rd_outstanding[N]-fs_rdid_outstanding[N])+unrdno_outstanding[N]);
			end else begin
				/*
				assert(fm_rdid_nbursts[N]-unrdid_bursts
				  <= (fs_rd_nbursts[mrindex[N]]
					    - fs_rdid_nbursts[mrindex[N]])
					+ unrdid_bursts);

				assert(fm_rdid_outstanding[N]-unrdid_bursts
				  <= (fs_rd_outstanding[mrindex[N]]
					    - fs_rdid_outstanding[mrindex[N]])
					+ unrdid_outstanding);
				*/

				//
				//
				if (fm_rdid_nbursts[N] == unrdid_bursts[N])
				begin
					// No room for any returns of this
					// ID, all are accounted for within
					// the channel
					assume(!s_axi_rvalid[mrindex[N]]
						||s_axi_rid[mrindex[N]]!=fm_rd_checkid[N]
						||!s_axi_rlast[mrindex[N]]);
				end else if (fm_rdid_nbursts[N]-unrdid_bursts[N] == 1)
				begin
					// Only room for one burst return
					// on this ID, so rlast must be set
					// appropriately
					if (s_axi_rvalid[mrindex[N]]
						&& s_axi_rid[mrindex[N]]==fm_rd_checkid[N])
						assume(s_axi_rlast[mrindex[N]]
						 == ((fm_rdid_outstanding[N]-unrdid_outstanding[N])==1));
				end

				if (fm_rdid_outstanding[N] == unrdid_outstanding[N])
				begin
					// No room for any returns in this
					// channel, all of the expected returns
					// are already in the channel
					assume(!s_axi_rvalid[mrindex[N]]
						||s_axi_rid[mrindex[N]]!=fm_rd_checkid[N]);
				end

				if (fm_rdid_outstanding[N] - unrdid_outstanding[N]
				      == fm_rdid_nbursts[N] - unrdid_bursts[N])
				begin
					// Each burst must have at least one
					// sample
					assume(!s_axi_rvalid[mrindex[N]]
						||s_axi_rid[mrindex[N]]!=fm_rd_checkid[N]
						||s_axi_rlast[mrindex[N]]);
				end

				if ((fm_rd_nbursts[N]-fm_rdid_nbursts[N])
							== unrdno_bursts[N])
				begin
					assume(!s_axi_rvalid[mrindex[N]]
						||s_axi_rid[mrindex[N]]==fm_rd_checkid[N]
						||!s_axi_rlast[mrindex[N]]);
				end else if ((fm_rd_nbursts[N]-fm_rdid_nbursts[N]
						- unrdno_bursts[N])==1)
				begin
					if (s_axi_rvalid[mrindex[N]]
						&& s_axi_rid[mrindex[N]]!=fm_rd_checkid[N])
						assume(s_axi_rlast[mrindex[N]]
						 == ((fm_rd_outstanding[N] - fm_rdid_outstanding[N]-unrdno_outstanding[N])==1));
				end

				if((fm_rd_outstanding[N]-fm_rdid_outstanding[N])
							== unrdno_outstanding[N])
				begin
					assume(!s_axi_rvalid[mrindex[N]]
						||s_axi_rid[mrindex[N]]==fm_rd_checkid[N]);
				end

				if ((fm_rd_outstanding[N]-fm_rdid_outstanding[N]
						- unrdno_outstanding[N])
					== (fm_rd_nbursts[N]-fm_rdid_nbursts[N]
						- unrdno_bursts[N]))
				begin
					assume(!s_axi_rvalid[mrindex[N]]
						||s_axi_rid[mrindex[N]]==fm_rd_checkid[N]
						||s_axi_rlast[N]);
				end
			end
		end


		//
		// Check (or assume) the ckvalid and ckign signals
		//
		/*
		reg	same_check;
		always @(*)
		begin
			same_check = (mrgrant[N] && fs_rd_ckvalid[mrindex[N]]
				&&fm_rd_checkid[N]==fs_rd_checkid[mrindex[N]]);
			if (!fm_rd_ckvalid[M])
				same_check = 0;
			if (fm_rdid_ckign_nbursts[N]
				!= fs_rdid_ckign_nbursts[mrindex[N]])
				+ ((r_rvalid[N] && r_rid[N] == fm_rd_checkid[N]
					& r_rlast[N])?1:0))
				same_check = 0;
		end;
			
		always @(*)
		if (mrgrant[N] && (mrindex[N] < NS) && )
		*/

	end endgenerate

	////////////////////////////////////////////////////////////////////////
	//
	// Double buffer checks
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	generate for(N=0; N<NM; N=N+1)
	begin : DOUBLE_BUFFER_CHECKS

		always @(*)
		if (r_awvalid[N])
			assert(r_awburst[N] != 2'b11);

		reg			r_araligned;
		reg	[AW-1:0]	r_arend;

		always @(*)
		begin
			r_araligned = 1;
			case(r_arsize[N])
			0: r_araligned = 1;
			1: r_araligned = (r_araddr[N][  0] == 0);
			2: r_araligned = (r_araddr[N][((AW>1)? 1:AW-1):0] == 0);
			3: r_araligned = (r_araddr[N][((AW>2)? 2:AW-1):0] == 0);
			4: r_araligned = (r_araddr[N][((AW>3)? 3:AW-1):0] == 0);
			5: r_araligned = (r_araddr[N][((AW>4)? 4:AW-1):0] == 0);
			6: r_araligned = (r_araddr[N][((AW>5)? 5:AW-1):0] == 0);
			7: r_araligned = (r_araddr[N][((AW>6)? 6:AW-1):0] == 0);
			endcase

			r_arend = r_araddr[N] + (r_arlen[N] << r_arsize[N]);
		end

		always @(*)
		if (r_arvalid[N])
		begin
			assert(r_arburst[N] != 2'b11);

			if (r_arburst[N] == 2'b10)
			begin
				assert((r_arlen[N] == 1)
					||(r_arlen[N] == 3)
					||(r_arlen[N] == 7)
					||(r_arlen[N] == 15));
				assert(r_araligned);
					
			end

			if (DW <= 8)
				assert(r_arsize[N] == 0);
			else if (DW <= 16)
				assert(r_arsize[N] <= 1);
			else if (DW <= 32)
				assert(r_arsize[N] <= 2);
			else if (DW <= 64)
				assert(r_arsize[N] <= 3);
			else if (DW <= 128)
				assert(r_arsize[N] <= 4);
			else if (DW <= 256)
				assert(r_arsize[N] <= 5);
			else if (DW <= 512)
				assert(r_arsize[N] <= 6);

			if ((r_arburst[N] == 2'b01)&&(AW>12))
				assert(r_araddr[N][AW-1:12] == r_arend[AW-1:12]);

			if (r_arlock[N])
			begin
				assert(r_arlen[N] < 16);
				assert(r_araligned);
				assert(!r_arcache[N][0]);
			end
		end

/*
		always @(*)
		if (mrgrant[N] && mrindex[N] < NS)
		begin
			if (fs_rd_outstanding[mrindex[N]]+((M_AXI_RVALID[N]&&!M_AXI_RLAST[N])?1:0)
				== fs_rd_nbursts[mrindex[N]]+((M_AXI_RVALID[N]&&M_AXI_RLAST[N])?1:0))
				assume(
					(!r_valid[mrindex[N]]&&(!s_axi_rvalid[mrindex[N]] || s_axi_rlast[mrindex[N]]))
					||(!r_rlast[N]));

			if (fm_rd_outstanding[N] - (M_AXI_RVALID&&!M_AXI_RLAST[N] ? 1:0)
				== fm_rd_nbursts[N]+((M_AXI_RVALID[N]&&M_AXI_RLAST[N])?1:0))
		end
*/
	end endgenerate
	////////////////////////////////////////////////////////////////////////
	//
	// Cover properties
	//
	////////////////////////////////////////////////////////////////////////
	// //
`ifdef	COVER_CHECKS
	// Can every master reach every slave?
	// Can things transition without dropping the request line(s)?
	generate for(N=0; N<NM; N=N+1)
	begin : COVER_CONNECTIVITY_FROM_MASTER
		reg [3:0]	w_returns, r_returns;
		reg		err_wr_return, err_rd_return;
		reg [NS-1:0]	w_every, r_every;
		reg		was_wevery, was_revery, whsreturn, rhsreturn;

		// w_returns is a speed check: Can we return one write
		// acknowledgement per clock cycle?
		initial	w_returns = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			w_returns = 0;
		else begin
			w_returns <= { w_returns[2:0], 1'b0 };
			if (M_AXI_BVALID[N] && M_AXI_BREADY[N] && !wgrant[N][NS])
				w_returns[0] <= 1'b1;
		end

		initial	whsreturn = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			whsreturn <= 0;
		else
			whsreturn <= whsreturn || (&w_returns);

		// w_every is a connectivity test: Can we get a return from
		// every slave?
		initial	w_every = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			w_every <= 0;
		else if (!M_AXI_AWVALID[N])
			w_every <= 0;
		else begin
			if (M_AXI_BVALID[N] && M_AXI_BREADY[N] && !wgrant[N][NS])
				w_every[mwindex[N]] <= 1'b1;
		end

		always @(posedge S_AXI_ACLK)
		if (M_AXI_BVALID[N])
			assert($stable(mwindex[N]));

		initial	was_wevery = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			was_wevery <= 0;
		else
			was_wevery <= was_wevery || (&w_every);

		always @(*)
			cover(!mwgrant[N] && whsreturn);	// @27
		always @(*)
			cover(!mwgrant[N] && was_wevery);	// @27

		// err_wr_return is a test to make certain we can return a
		// bus error on the write channel.
		initial	err_wr_return = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			err_wr_return = 0;
		else if (wgrant[N][NS] && M_AXI_BVALID[N]
				&& (M_AXI_BRESP[2*N+:2]==INTERCONNECT_ERROR))
			err_wr_return = 1;

		always @(*) // @!
			cover(err_wr_return);
		always @(*) // @!
			cover(!mwgrant[N] && err_wr_return);

		always @(*)
		if (M_AXI_BVALID[N])
			assert(mwgrant[N]);

		// r_returns is a speed check: Can we return one read
		// acknowledgment per clock cycle?
		initial	r_returns = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			r_returns = 0;
		else begin
			r_returns <= { r_returns[2:0], 1'b0 };
			if (M_AXI_RVALID[N] && M_AXI_RREADY[N])
				r_returns[0] <= 1'b1;
		end

		initial	rhsreturn = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			rhsreturn <= 0;
		else
			rhsreturn <= rhsreturn || (&r_returns);


		// r_every is a connectivity test: Can we get a read return from
		// every slave?
		initial	r_every = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			r_every = 0;
		else if (!M_AXI_ARVALID[N])
			r_every = 0;
		else begin
			if (M_AXI_RVALID[N] && M_AXI_RREADY[N])
				r_every[mrindex[N]] <= 1'b1;
		end

		// was_revery is a return to idle check following the
		// connectivity test.  Since the connectivity test is cleared
		// if there's ever a drop in the valid line, we need a separate
		// wire to check that this master can return to idle again.
		initial	was_revery = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			was_revery <= 0;
		else
			was_revery <= was_revery || (&r_every);

		always @(posedge S_AXI_ACLK)
		if (M_AXI_RVALID[N])
			assert($stable(mrindex[N]));

		always @(*)
			cover(!mrgrant[N] && rhsreturn);	// @26
		always @(*)
			cover(!mrgrant[N] && was_revery);	// @26

		initial	err_rd_return = 0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			err_rd_return = 0;
		else if (rgrant[N][NS] && M_AXI_RVALID[N]
				&& (M_AXI_RRESP[2*N+:2]==INTERCONNECT_ERROR))
			err_rd_return = 1;

		always @(*)
			cover(M_AXI_ARVALID[N] && rrequest[N][NS]);
		always @(*)
			cover(rgrant[N][NS]);
		always @(*)
			cover(err_rd_return);
		always @(*)
			cover(!mrgrant[N] && err_rd_return); //@!

		always @(*)
		if (M_AXI_BVALID[N] && wgrant[N][NS])
			assert(M_AXI_BRESP[2*N+:2]==INTERCONNECT_ERROR);
		always @(*)
		if (M_AXI_RVALID[N] && rgrant[N][NS])
			assert(M_AXI_RRESP[2*N+:2]==INTERCONNECT_ERROR);
	end endgenerate

	////////////////////////////////////////////////////////////////////////
	//
	// Negation check
	//
	// Pick a particular value.  Assume the value doesn't show up on the
	// input.  Prove it doesn't show up on the output.  This will check for
	// ...
	// 1. Stuck bits on the output channel
	// 2. Cross-talk between channels
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	(* anyconst *)	reg	[LGNM-1:0]	f_const_source;
	(* anyconst *)	reg	[AW-1:0]	f_const_addr;
	(* anyconst *)	reg	[AW-1:0]	f_const_addr_n;
	(* anyconst *)	reg	[IW-1:0]	f_const_id_n;
	(* anyconst *)	reg	[7:0]		f_const_len_n;
	(* anyconst *)	reg	[3:0]		f_const_size_n;
	(* anyconst *)	reg	[1:0]		f_const_burst_n;
	(* anyconst *)	reg	[3:0]		f_const_cache_n;
	(* anyconst *)	reg	[2:0]		f_const_prot_n;
	(* anyconst *)	reg	[3:0]		f_const_qos_n;
	//
	(* anyconst *)	reg	[DW-1:0]	f_const_data_n;
	(* anyconst *)	reg	[DW/8-1:0]	f_const_strb_n;
	(* anyconst *)	reg	[3-1:0]		f_const_prot_n;
	(* anyconst *)	reg	[2-1:0]		f_const_resp_n;
			reg	[LGNS-1:0]	f_const_slave;

	always @(*)
		assume(f_const_source < NM);
	always @(*)
	begin
		f_const_slave = NS;
		for(iM=0; iM<NS; iM=iM+1)
		begin
			if (((f_const_addr ^ SLAVE_ADDR[iM*AW+:AW])
					&SLAVE_MASK[iM*AW+:AW])==0)
				f_const_slave = iM;
		end

		assume(f_const_slave < NS);
	end

	reg	[AW-1:0]	f_awaddr;
	reg	[AW-1:0]	f_araddr;
	always @(*)
		f_awaddr = M_AXI_AWADDR[f_const_source * AW +: AW];
	always @(*)
		f_araddr = M_AXI_ARADDR[f_const_source * AW +: AW];

	// The assumption check: assume our negated values are not found on
	// the inputs
	always @(*)
	begin
		if (M_AXI_AWVALID[f_const_source])
		begin
			assume(f_awaddr != f_const_addr_n);
			if (IW > 1)
			assume(M_AXI_AWID[   f_const_source*IW+:IW] != f_const_id_n);
			assume(M_AXI_AWLEN[  f_const_source* 8+: 8] != f_const_len_n);
			assume(M_AXI_AWSIZE[ f_const_source* 3+: 3] != f_const_size_n);
			assume(M_AXI_AWBURST[f_const_source* 2+: 2] != f_const_burst_n);
			assume(M_AXI_AWCACHE[f_const_source* 4+: 4] != f_const_cache_n);
			assume(M_AXI_AWPROT[ f_const_source* 3+: 3] != f_const_prot_n);
			assume(M_AXI_AWQOS[  f_const_source* 4+: 4] != f_const_qos_n);
		end
		if (m_wvalid)
		begin
			assume(m_wdata[f_const_source] != f_const_data_n);
			assume(m_wstrb[f_const_source] != f_const_strb_n);
		end
		if (M_AXI_ARVALID[f_const_source])
		begin
			assume(f_araddr != f_const_addr_n);
			if (IW > 1)
			assume(M_AXI_ARID[   f_const_source*IW+:IW] != f_const_id_n);
			assume(M_AXI_ARLEN[  f_const_source* 8+: 8] != f_const_len_n);
			assume(M_AXI_ARSIZE[ f_const_source* 3+: 3] != f_const_size_n);
			assume(M_AXI_ARBURST[f_const_source* 2+: 2] != f_const_burst_n);
			assume(M_AXI_ARCACHE[f_const_source* 4+: 4] != f_const_cache_n);
			assume(M_AXI_ARPROT[ f_const_source* 3+: 3] != f_const_prot_n);
			assume(M_AXI_ARQOS[  f_const_source* 4+: 4] != f_const_qos_n);
		end

		if (S_AXI_BVALID[f_const_slave] && wgrant[f_const_source][f_const_slave])
		begin
			assume(s_axi_bresp[f_const_slave] != f_const_resp_n);
			if (IW > 1)
			assume(s_axi_bid[f_const_slave] != f_const_id_n);
		end

		if (S_AXI_RVALID[f_const_slave] && rgrant[f_const_source][f_const_slave])
		begin
			assume(s_axi_rdata[f_const_slave] != f_const_data_n);
			assume(s_axi_rresp[f_const_slave] != f_const_resp_n);
			if (IW > 1)
			assume(s_axi_rid[f_const_slave] != f_const_id_n);
		end
	end

	// Proof check: Prove these values are not found on our outputs
	always @(*)
	begin
		if (r_awvalid[f_const_source])
		begin
			assert(r_awaddr[f_const_source] != f_const_addr_n);
			if (IW > 1)
				assert(r_awid[   f_const_source] != f_const_id_n);
			assert(r_awlen[  f_const_source] != f_const_len_n);
			assert(r_awsize[ f_const_source] != f_const_size_n);
			assert(r_awburst[f_const_source] != f_const_burst_n);
			assert(r_awcache[f_const_source] != f_const_cache_n);
			assert(r_awprot[ f_const_source] != f_const_prot_n);
			assert(r_awqos[  f_const_source] != f_const_qos_n);
		end
		if (S_AXI_AWVALID[f_const_slave] && wgrant[f_const_source][f_const_slave])
		begin
			assert(S_AXI_AWADDR[f_const_slave*AW+:AW] != f_const_addr_n);
			if (IW > 1)
			assert(S_AXI_AWID[   f_const_slave*IW+:IW] != f_const_id_n);
			assert(S_AXI_AWLEN[  f_const_slave* 8+: 8] != f_const_len_n);
			assert(S_AXI_AWSIZE[ f_const_slave* 3+: 3] != f_const_size_n);
			assert(S_AXI_AWBURST[f_const_slave* 2+: 2] != f_const_burst_n);
			assert(S_AXI_AWCACHE[f_const_slave* 4+: 4] != f_const_cache_n);
			assert(S_AXI_AWPROT[ f_const_slave* 3+: 3] != f_const_prot_n);
			assert(S_AXI_AWQOS[  f_const_slave* 4+: 4] != f_const_qos_n);
		end
		if (S_AXI_WVALID[f_const_slave] && wgrant[f_const_source][f_const_slave])
		begin
			assert(S_AXI_WDATA[f_const_slave*DW+:DW] != f_const_data_n);
			assert(S_AXI_WSTRB[f_const_slave*(DW/8)+:(DW/8)] != f_const_strb_n);
		end
		if (r_arvalid[f_const_source])
		begin
			assert(r_araddr[f_const_source] != f_const_addr_n);
			if (IW > 1)
				assert(r_arid[   f_const_source] != f_const_id_n);
			assert(r_arlen[  f_const_source] != f_const_len_n);
			assert(r_arsize[ f_const_source] != f_const_size_n);
			assert(r_arburst[f_const_source] != f_const_burst_n);
			assert(r_arcache[f_const_source] != f_const_cache_n);
			assert(r_arprot[ f_const_source] != f_const_prot_n);
			assert(r_arqos[  f_const_source] != f_const_qos_n);
		end
		if (S_AXI_ARVALID[f_const_slave] && rgrant[f_const_source][f_const_slave])
		begin
			assert(S_AXI_ARADDR[f_const_slave*AW+:AW] != f_const_addr_n);
			assert(S_AXI_ARADDR[f_const_slave*AW+:AW] != f_const_addr_n);
			if (IW>1)
				assert(S_AXI_ARID[   f_const_slave*IW+:IW] != f_const_id_n);
			assert(S_AXI_ARLEN[  f_const_slave* 8+: 8] != f_const_len_n);
			assert(S_AXI_ARSIZE[ f_const_slave* 3+: 3] != f_const_size_n);
			assert(S_AXI_ARBURST[f_const_slave* 2+: 2] != f_const_burst_n);
			assert(S_AXI_ARCACHE[f_const_slave* 4+: 4] != f_const_cache_n);
			assert(S_AXI_ARPROT[ f_const_slave* 3+: 3] != f_const_prot_n);
			assert(S_AXI_ARQOS[  f_const_slave* 4+: 4] != f_const_qos_n);
		end
		//
		if (r_bvalid[f_const_source] && wgrant[f_const_source][f_const_slave])
			assert(r_bresp[f_const_source] != f_const_resp_n);
		if (M_AXI_BVALID[f_const_source] && wgrant[f_const_source][f_const_slave])
			assert(M_AXI_BRESP[f_const_source*2+:2] != f_const_resp_n);
		if (r_rvalid[f_const_source] && rgrant[f_const_source][f_const_slave])
		begin
			assert(r_rresp[f_const_source] != f_const_resp_n);
			assert(r_rdata[f_const_source] != f_const_data_n);
			if (IW>1)
				assert(r_rid[  f_const_source] != f_const_id_n);
		end
		if (M_AXI_RVALID[f_const_source] && rgrant[f_const_source][f_const_slave])
		begin
			assert(M_AXI_RRESP[f_const_source*2+:2]!=f_const_resp_n);
			assert(M_AXI_RDATA[f_const_source*DW+:DW]!=f_const_data_n);
			if (IW>1)
			assert(M_AXI_RID[f_const_source*IW+:IW]!=f_const_id_n);
		end
	end
`endif	// COVER_CHECKS

	////////////////////////////////////////////////////////////////////////
	//
	// (Careless) constraining assumptions
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	generate for(N=0; N<NM; N=N+1)
	begin

		localparam [0:0]	OPT_READS  = 0;
		localparam [0:0]	OPT_WRITES = 1;

		if (!OPT_WRITES)
		begin
			always @(*)
				assume(M_AXI_AWVALID == 0);
			always @(*)
				assert(!wgrant[N][NS]);
			always @(*)
				assert(r_awvalid[N] == 0);
			always @(*)
				assert(mwgrant[N] == 0);
			always @(*)
				assert(fm_awr_nbursts[N] == 0);
		end

		if (!OPT_READS)
		begin
			always @(*)
				assume(M_AXI_ARVALID == 0);
			always @(*)
				assert(r_arvalid[N] == 0);
			always @(*)
				assert(!rgrant[N][NS]);
			always @(*)
				assert(fm_rd_nbursts[N] == 0);
		end


		always@(*)
			assert(OPT_READS | OPT_WRITES);
		always @(*)
			assume(swgrant[NS-1:1] == 0);
		always @(*)
			assume(mwgrant[NM-1:1] == 0);
		always @(*)
			assume(srgrant[NS-1:1] == 0);
		always @(*)
			assume(mrgrant[NM-1:1] == 0);
	//	always @(*)
	//	for(iN=0; iN<NM; iN=iN+1)
	//		assume(fm_rd_nbursts[iN] <= 1);
		always @(*)
		for(iN=0; iN<NM; iN=iN+1)
			assume(!rrequest[iN][NS]);
		always @(*)
		for(iN=0; iN<NM; iN=iN+1)
			assert(!rgrant[iN][NS]);
	end endgenerate

`endif
endmodule
