
`timescale 1 ns / 1 ps
`default_nettype none
module xlnxfull_2018_3 #(
	// Users to add parameters here

	// User parameters ends
	// Do not modify the parameters beyond this line

	// Width of ID for for write address, write data, read address and read data
	parameter integer C_S_AXI_ID_WIDTH	= 1,
	// Width of S_AXI data bus
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	// Width of S_AXI address bus
	parameter integer C_S_AXI_ADDR_WIDTH	= 6,
	// Width of optional user defined signal in write address channel
	parameter integer C_S_AXI_AWUSER_WIDTH	= 0,
	// Width of optional user defined signal in read address channel
	parameter integer C_S_AXI_ARUSER_WIDTH	= 0,
	// Width of optional user defined signal in write data channel
	parameter integer C_S_AXI_WUSER_WIDTH	= 0,
	// Width of optional user defined signal in read data channel
	parameter integer C_S_AXI_RUSER_WIDTH	= 0,
	// Width of optional user defined signal in write response channel
	parameter integer C_S_AXI_BUSER_WIDTH	= 0
	) (
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write Address ID
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
		// Write address
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		input wire [7 : 0] S_AXI_AWLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		input wire [2 : 0] S_AXI_AWSIZE,
		// Burst type. The burst type and the size information, 
		// determine how the address for each transfer within the burst is calculated.
		input wire [1 : 0] S_AXI_AWBURST,
		// Lock type. Provides additional information about the
		// atomic characteristics of the transfer.
		input wire  S_AXI_AWLOCK,
		// Memory type. This signal indicates how transactions
		// are required to progress through a system.
		input wire [3 : 0] S_AXI_AWCACHE,
		// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Quality of Service, QoS identifier sent for each
		// write transaction.
		input wire [3 : 0] S_AXI_AWQOS,
		// Region identifier. Permits a single physical interface
		// on a slave to be used for multiple logical interfaces.
		input wire [3 : 0] S_AXI_AWREGION,
		// Optional User-defined signal in the write address channel.
//		input wire [C_S_AXI_AWUSER_WIDTH-1 : 0] S_AXI_AWUSER,
		// Write address valid. This signal indicates that
		// the channel is signaling valid write address and
		// control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that
		// the slave is ready to accept an address and associated
		// control signals.
		output wire  S_AXI_AWREADY,
		// Write Data
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte
		// lanes hold valid data. There is one write strobe
		// bit for each eight bits of the write data bus.
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write last. This signal indicates the last transfer
		// in a write burst.
		input wire  S_AXI_WLAST,
		// Optional User-defined signal in the write data channel.
//		input wire [C_S_AXI_WUSER_WIDTH-1 : 0] S_AXI_WUSER,
		// Write valid. This signal indicates that valid write
		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Response ID tag. This signal is the ID tag of the
		// write response.
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
		// Write response. This signal indicates the status
		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Optional User-defined signal in the write response channel.
//		output wire [C_S_AXI_BUSER_WIDTH-1 : 0] S_AXI_BUSER,
		// Write response valid. This signal indicates that the
		// channel is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address ID. This signal is the identification
		// tag for the read address group of signals.
		input wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
		// Read address. This signal indicates the initial
		// address of a read burst transaction.
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		input wire [7 : 0] S_AXI_ARLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		input wire [2 : 0] S_AXI_ARSIZE,
		// Burst type. The burst type and the size information, 
		// determine how the address for each transfer within the burst is calculated.
		input wire [1 : 0] S_AXI_ARBURST,
		// Lock type. Provides additional information about the
		// atomic characteristics of the transfer.
		input wire  S_AXI_ARLOCK,
		// Memory type. This signal indicates how transactions
		// are required to progress through a system.
		input wire [3 : 0] S_AXI_ARCACHE,
		// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Quality of Service, QoS identifier sent for each
		// read transaction.
		input wire [3 : 0] S_AXI_ARQOS,
		// Region identifier. Permits a single physical interface
		// on a slave to be used for multiple logical interfaces.
//		input wire [3 : 0] S_AXI_ARREGION,
		// Optional User-defined signal in the read address channel.
//		input wire [C_S_AXI_ARUSER_WIDTH-1 : 0] S_AXI_ARUSER,
		// Write address valid. This signal indicates that
		// the channel is signaling valid read address and
		// control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that
		// the slave is ready to accept an address and associated
		// control signals.
		output wire  S_AXI_ARREADY,
		// Read ID tag. This signal is the identification tag
		// for the read data group of signals generated by the slave.
		output wire [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
		// Read Data
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of
		// the read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read last. This signal indicates the last transfer
		// in a read burst.
		output wire  S_AXI_RLAST,
		// Optional User-defined signal in the read address channel.
//		output wire [C_S_AXI_RUSER_WIDTH-1 : 0] S_AXI_RUSER,
		// Read valid. This signal indicates that the channel
		// is signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4FULL signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg 			 	axi_awready;
	reg  				axi_wready;
	reg [1 : 0]		 	axi_bresp;
//	reg [C_S_AXI_BUSER_WIDTH-1 : 0]	axi_buser;
	reg 			 	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg 			 	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 			axi_rresp;
	reg 			 	axi_rlast;
//	reg [C_S_AXI_RUSER_WIDTH-1 : 0] axi_ruser;
	reg  				axi_rvalid;
	// aw_wrap_en determines wrap boundary and enables wrapping
	wire aw_wrap_en;
	// ar_wrap_en determines wrap boundary and enables wrapping
	wire ar_wrap_en;
	// aw_wrap_size is the size of the write transfer, the
	// write address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  aw_wrap_size ; 
	// ar_wrap_size is the size of the read transfer, the
	// read address wraps to a lower address if upper address
	// limit is reached
	wire [31:0]  ar_wrap_size ; 
	// The axi_awv_awr_flag flag marks the presence of write address valid
	reg axi_awv_awr_flag;
	//The axi_arv_arr_flag flag marks the presence of read address valid
	reg axi_arv_arr_flag; 
	// The axi_awlen_cntr internal write address counter to keep track of beats in a burst transaction
	reg [7:0] axi_awlen_cntr;
	//The axi_arlen_cntr internal read address counter to keep track of beats in a burst transaction
	reg [7:0] axi_arlen_cntr;
	reg [1:0] axi_arburst;
	reg [1:0] axi_awburst;
	reg [7:0] axi_arlen;
	reg [7:0] axi_awlen;
	//local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	//ADDR_LSB is used for addressing 32/64 bit registers/memories
	//ADDR_LSB = 2 for 32 bits (n downto 2) 
	//ADDR_LSB = 3 for 42 bits (n downto 3)

	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32)+ 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	localparam integer USER_NUM_MEM = 1;
	//----------------------------------------------
	//-- Signals for user logic memory space example
	//------------------------------------------------
	wire [OPT_MEM_ADDR_BITS:0] mem_address;
//	wire [USER_NUM_MEM-1:0] mem_select;
	reg [C_S_AXI_DATA_WIDTH-1:0] mem_data_out[0 : USER_NUM_MEM-1];

	genvar i;
	genvar j;
	genvar mem_byte_index;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
//	assign S_AXI_BUSER	= axi_buser;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RLAST	= axi_rlast;
//	assign S_AXI_RUSER	= axi_ruser;
	assign S_AXI_RVALID	= axi_rvalid;
	assign S_AXI_BID = S_AXI_AWID;
	assign S_AXI_RID = S_AXI_ARID;
	assign  aw_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_awlen)); 
	assign  ar_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_arlen)); 
	assign  aw_wrap_en = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
	assign  ar_wrap_en = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;

	// Implement axi_awready generation

	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      axi_awv_awr_flag <= 1'b0;
	    end 
	  else
	    begin
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          // slave is ready to accept an address and
	          // associated control signals
	          axi_awready <= 1'b1;
	          axi_awv_awr_flag  <= 1'b1; 
	          // used for generation of bresp() and bvalid
	        end
	      else if (S_AXI_WLAST && axi_wready)          
	      // preparing to accept next address after current write burst tx completion
	        begin
	          axi_awv_awr_flag  <= 1'b0;
	        end
	      else
	        begin
	          axi_awready <= 1'b0;
	        end
	    end
	end
	// Implement axi_awaddr latching

	// This process is used to latch the address when both
	// S_AXI_AWVALID and S_AXI_WVALID are valid.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	      axi_awlen_cntr <= 0;
	      axi_awburst <= 0;
	      axi_awlen <= 0;
	    end 
	  else
	    begin
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag)
	        begin
	          // address latching
	          axi_awaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1:0];  
	           axi_awburst <= S_AXI_AWBURST; 
	           axi_awlen <= S_AXI_AWLEN;
	          // start address of transfer
	          axi_awlen_cntr <= 0;
	        end   
	      else if((axi_awlen_cntr <= axi_awlen) && axi_wready && S_AXI_WVALID)        
	        begin

	          axi_awlen_cntr <= axi_awlen_cntr + 1;

	          case (axi_awburst)
	            2'b00: // fixed burst
	            // The write address for all the beats in the transaction are fixed
	              begin
	                axi_awaddr <= axi_awaddr;          
	                //for awsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The write address for all the beats in the transaction are increments by awsize
	              begin
	                axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //awaddr aligned to 4 byte boundary
	                axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The write address wraps when the address reaches wrap boundary 
	              if (aw_wrap_en)
	                begin
	                  axi_awaddr <= (axi_awaddr - aw_wrap_size); 
	                end
	              else 
	                begin
	                  axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                  axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}}; 
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_awaddr <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //for awsize = 4 bytes (010)
	              end
	          endcase
	        end
	    end
	end
	// Implement axi_wready generation

	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end
	  else
	    begin
	      if (~axi_wready && S_AXI_WVALID && axi_awv_awr_flag)
	        begin
	          // slave can accept the write data
	          axi_wready <= 1'b1;
	        end
	      //else if (~axi_awv_awr_flag)
	      else if (S_AXI_WLAST && axi_wready)
	        begin
	          axi_wready <= 1'b0;
	        end
	    end
	end
	// Implement write response logic generation

	// The write response and response valid signals are asserted by the slave
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
	// This marks the acceptance of address and indicates the status of
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
//	      axi_buser <= 0;
	    end
	  else
	    begin    
	      if (axi_awv_awr_flag && axi_wready && S_AXI_WVALID && ~axi_bvalid && S_AXI_WLAST )
	        begin
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; 
	          // 'OKAY' response 
	        end                   
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid)
	            //check if bready is asserted while bvalid is high)
	            //(there is a possibility that bready is always asserted high)
	            begin
	              axi_bvalid <= 1'b0;
	            end
	        end
	    end
	end
	// Implement axi_arready generation

	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is
	// de-asserted when reset (active low) is asserted.
	// The read address is also latched when S_AXI_ARVALID is
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_arv_arr_flag <= 1'b0;
	    end
	  else
	    begin
	      if (~axi_arready && S_AXI_ARVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag)
	        begin
	          axi_arready <= 1'b1;
	          axi_arv_arr_flag <= 1'b1;
	        end
	      else if (axi_rvalid && S_AXI_RREADY && axi_arlen_cntr == axi_arlen)
	      // preparing to accept next address after current read completion
	        begin
	          axi_arv_arr_flag  <= 1'b0;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end
	end
	// Implement axi_araddr latching

	//This process is used to latch the address when both 
	//S_AXI_ARVALID and S_AXI_RVALID are valid. 
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_araddr <= 0;
	      axi_arlen_cntr <= 0;
	      axi_arburst <= 0;
	      axi_arlen <= 0;
	      axi_rlast <= 1'b0;
//	      axi_ruser <= 0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID && ~axi_arv_arr_flag)
	        begin
	          // address latching 
	          axi_araddr <= S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH - 1:0]; 
	          axi_arburst <= S_AXI_ARBURST; 
	          axi_arlen <= S_AXI_ARLEN;     
	          // start address of transfer
	          axi_arlen_cntr <= 0;
	          axi_rlast <= 1'b0;
	        end   
	      else if((axi_arlen_cntr <= axi_arlen) && axi_rvalid && S_AXI_RREADY)        
	        begin
	         
	          axi_arlen_cntr <= axi_arlen_cntr + 1;
	          axi_rlast <= 1'b0;
	        
	          case (axi_arburst)
	            2'b00: // fixed burst
	             // The read address for all the beats in the transaction are fixed
	              begin
	                axi_araddr       <= axi_araddr;        
	                //for arsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The read address for all the beats in the transaction are increments by awsize
	              begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The read address wraps when the address reaches wrap boundary 
	              if (ar_wrap_en) 
	                begin
	                  axi_araddr <= (axi_araddr - ar_wrap_size); 
	                end
	              else 
	                begin
	                axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
	                //araddr aligned to 4 byte boundary
	                axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_araddr <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB]+1;
	                //for arsize = 4 bytes (010)
	              end
	          endcase              
	        end
	      else if((axi_arlen_cntr == axi_arlen) && ~axi_rlast && axi_arv_arr_flag )   
	        begin
	          axi_rlast <= 1'b1;
	        end          
	      else if (S_AXI_RREADY)   
	        begin
	          axi_rlast <= 1'b0;
	        end          
	    end 
	end       
	// Implement axi_arvalid generation

	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arv_arr_flag && ~axi_rvalid)
	        begin
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; 
	          // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          axi_rvalid <= 1'b0;
	        end            
	    end
	end    
	// ------------------------------------------
	// -- Example code to access user logic memory region
	// ------------------------------------------

	generate
	  if (USER_NUM_MEM >= 1)
	    begin
//	      assign mem_select  = 1;
	      assign mem_address = (axi_arv_arr_flag? axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]:(axi_awv_awr_flag? axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]:0));
	    end
	endgenerate
	     
	// implement Block RAM(s)
	generate 
	  for(i=0; i<= USER_NUM_MEM-1; i=i+1)
	    begin:BRAM_GEN
	      wire mem_rden;
	      wire mem_wren;
	
	      assign mem_wren = axi_wready && S_AXI_WVALID ;
	
	      assign mem_rden = axi_arv_arr_flag ; //& ~axi_rvalid
	     
	      for(mem_byte_index=0; mem_byte_index<= (C_S_AXI_DATA_WIDTH/8-1); mem_byte_index=mem_byte_index+1)
	      begin:BYTE_BRAM_GEN
	        wire [8-1:0] data_in ;
	        wire [8-1:0] data_out;
	        reg  [8-1:0] byte_ram [0 : 15];
//	        integer  j;
	     
	        //assigning 8 bit data
	        assign data_in  = S_AXI_WDATA[(mem_byte_index*8+7) -: 8];
	        assign data_out = byte_ram[mem_address];
	     
	        always @( posedge S_AXI_ACLK )
	        begin
	          if (mem_wren && S_AXI_WSTRB[mem_byte_index])
	            begin
	              byte_ram[mem_address] <= data_in;
	            end   
	        end    
	      
	        always @( posedge S_AXI_ACLK )
	        begin
	          if (mem_rden)
	            begin
	              mem_data_out[i][(mem_byte_index*8+7) -: 8] <= data_out;
	            end   
	        end    
	               
	    end
	  end       
	endgenerate
	//Output register or memory read data

	always @(*) // @( mem_data_out, axi_rvalid)
	begin
	  if (axi_rvalid) 
	    begin
	      // Read address mux
	      axi_rdata = mem_data_out[0];
	    end   
	  else
	    begin
	      axi_rdata = 32'h00000000;
	    end       
	end    

// Verification logic starts here:
	initial	axi_awready = 1'b0;
	initial	axi_awv_awr_flag = 1'b0;
	initial	axi_awaddr     = 0;
	initial	axi_awlen_cntr = 0;
	initial	axi_awburst    = 0;
	initial	axi_awlen      = 0;
	initial	axi_wready = 1'b0;
	initial	axi_bvalid = 1'b0;
	initial	axi_bresp  = 1'b0;
//	initial	axi_buser  = 1'b0;
	initial	axi_arready      = 1'b0;
	initial	axi_arv_arr_flag = 1'b0;
	initial	axi_araddr = 0;
	initial	axi_arlen_cntr = 0;
	initial	axi_arburst    = 0;
	initial	axi_arlen      = 0;
	initial	axi_rlast      = 0;
//	initial	axi_ruser      = 0;
	initial	axi_rvalid = 1'b0;
	initial	axi_rresp  = 1'b0;
`ifdef	FORMAL
	localparam	F_LGDEPTH=10;

	wire	[F_LGDEPTH-1:0] f_axi_awr_nbursts,
				f_axi_rd_nbursts,
				f_axi_rd_outstanding;
	wire	[9-1:0]		f_axi_wr_pending;
	wire	[C_S_AXI_ID_WIDTH-1:0]	f_axi_wr_checkid;
	wire				f_axi_wr_ckvalid;
	wire	[F_LGDEPTH-1:0]		f_axi_wrid_nbursts;

	//
	wire	[C_S_AXI_ADDR_WIDTH-1:0] f_axi_wr_addr;
	wire	[7:0]			f_axi_wr_incr;
	wire	[1:0]			f_axi_wr_burst;
	wire	[2:0]			f_axi_wr_size;
	wire	[7:0]			f_axi_wr_len;
	//
	wire	[C_S_AXI_ID_WIDTH-1:0]	f_axi_rd_checkid;
	wire				f_axi_rd_ckvalid;
	wire	[9-1:0]			f_axi_rd_cklen;
	wire	[C_S_AXI_ADDR_WIDTH-1:0] f_axi_rd_ckaddr;
	wire	[7:0]			f_axi_rd_ckincr;
	wire	[1:0]			f_axi_rd_ckburst;
	wire	[2:0]			f_axi_rd_cksize;
	wire	[7:0]			f_axi_rd_ckarlen;
	wire	[F_LGDEPTH-1:0]		f_axi_rdid_nbursts,
					f_axi_rdid_outstanding,
					f_axi_rdid_ckign_nbursts,
					f_axi_rdid_ckign_outstanding;

	faxi_slave	#(
		.F_AXI_MAXSTALL(6),
		.C_AXI_ID_WIDTH(C_S_AXI_ID_WIDTH),
		.C_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
		.OPT_NARROW_BURST(0),
		.OPT_EXCLUSIVE(0),
		.F_LGDEPTH(F_LGDEPTH))
		f_slave(
		.i_clk(S_AXI_ACLK),
		.i_axi_reset_n(S_AXI_ARESETN),
		//
		// Address write channel
		//
		// Write Address ID
		.i_axi_awid(S_AXI_AWID),
		// Write address
		.i_axi_awaddr(S_AXI_AWADDR),
		// Burst length. The burst length gives the exact number of transfers in a burst
		.i_axi_awlen(S_AXI_AWLEN),
		// Burst size. This signal indicates the size of each transfer in the burst
		.i_axi_awsize(S_AXI_AWSIZE),
		// Burst type. The burst type and the size information, 
    		// determine how the address for each transfer within the burst is calculated.
		.i_axi_awburst(S_AXI_AWBURST),
		// Lock type. Provides additional information about the
    		// atomic characteristics of the transfer.
		.i_axi_awlock(S_AXI_AWLOCK),
		// Memory type. This signal indicates how transactions
    		// are required to progress through a system.
		.i_axi_awcache(S_AXI_AWCACHE),
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		.i_axi_awprot(S_AXI_AWPROT),
		// Quality of Service, QoS identifier sent for each
    		// write transaction.
		.i_axi_awqos(S_AXI_AWQOS),
		// Write address valid. This signal indicates that
    		// the channel is signaling valid write address and
    		// control information.
		.i_axi_awvalid(S_AXI_AWVALID),
		// Write address ready. This signal indicates that
    		// the slave is ready to accept an address and associated
    		// control signals.
		.i_axi_awready(S_AXI_AWREADY),
	//
	//
		//
		// Write Data Channel
		//
		// Write Data
		.i_axi_wdata(S_AXI_WDATA),
		// Write strobes. This signal indicates which byte
    		// lanes hold valid data. There is one write strobe
    		// bit for each eight bits of the write data bus.
		.i_axi_wstrb(S_AXI_WSTRB),
		// Write last. This signal indicates the last transfer
    		// in a write burst.
		.i_axi_wlast(S_AXI_WLAST),
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		.i_axi_wvalid(S_AXI_WVALID),
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		.i_axi_wready(S_AXI_WREADY),
	//
	//
		// Response ID tag. This signal is the ID tag of the
    		// write response.
		.i_axi_bid(S_AXI_BID),
		// Write response. This signal indicates the status
    		// of the write transaction.
		.i_axi_bresp(S_AXI_BRESP),
		// Write response valid. This signal indicates that the
    		// channel is signaling a valid write response.
		.i_axi_bvalid(S_AXI_BVALID),
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		.i_axi_bready(S_AXI_BREADY),
	//
	//
		//
		// Read address channel
		//
		// Read address ID. This signal is the identification
		// tag for the read address group of signals.
		.i_axi_arid(S_AXI_ARID),
		// Read address. This signal indicates the initial
    		// address of a read burst transaction.
		.i_axi_araddr(S_AXI_ARADDR),
		// Burst length. The burst length gives the exact number of transfers in a burst
		.i_axi_arlen(S_AXI_ARLEN),
		// Burst size. This signal indicates the size of each transfer in the burst
		.i_axi_arsize(S_AXI_ARSIZE),
		// Burst type. The burst type and the size information, 
    		// determine how the address for each transfer within the burst is calculated.
		.i_axi_arburst(S_AXI_ARBURST),
		// Lock type. Provides additional information about the
    		// atomic characteristics of the transfer.
		.i_axi_arlock(S_AXI_ARLOCK),
		// Memory type. This signal indicates how transactions
    		// are required to progress through a system.
		.i_axi_arcache(S_AXI_ARCACHE),
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		.i_axi_arprot(S_AXI_ARPROT),
		// Quality of Service, QoS identifier sent for each
    		// read transaction.
		.i_axi_arqos(S_AXI_ARQOS),
		// Write address valid. This signal indicates that
    		// the channel is signaling valid read address and
    		// control information.
		.i_axi_arvalid(S_AXI_ARVALID),
		// Read address ready. This signal indicates that
    		// the slave is ready to accept an address and associated
    		// control signals.
		.i_axi_arready(S_AXI_ARREADY),
	//
	//
		//
		// Read data return channel
		//
		// Read ID tag. This signal is the identification tag
		// for the read data group of signals generated by the slave.
		.i_axi_rid(S_AXI_RID),
		// Read Data
		.i_axi_rdata(S_AXI_RDATA),
		// Read response. This signal indicates the status of
    		// the read transfer.
		.i_axi_rresp(S_AXI_RRESP),
		// Read last. This signal indicates the last transfer
    		// in a read burst.
		.i_axi_rlast(S_AXI_RLAST),
		// Read valid. This signal indicates that the channel
    		// is signaling the required read data.
		.i_axi_rvalid(S_AXI_RVALID),
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		.i_axi_rready(S_AXI_RREADY),
		//
		// Formal outputs
		//
		.f_axi_awr_nbursts(f_axi_awr_nbursts),
		.f_axi_wr_pending(f_axi_wr_pending),
		.f_axi_rd_nbursts(f_axi_rd_nbursts),
		.f_axi_rd_outstanding(f_axi_rd_outstanding),
		//
		.f_axi_wr_checkid(f_axi_wr_checkid),
		.f_axi_wr_ckvalid(f_axi_wr_ckvalid),
		.f_axi_wrid_nbursts(f_axi_wrid_nbursts),
		.f_axi_wr_addr(f_axi_wr_addr),
		.f_axi_wr_incr(f_axi_wr_incr),
		.f_axi_wr_burst(f_axi_wr_burst),
		.f_axi_wr_size(f_axi_wr_size),
		.f_axi_wr_len(f_axi_wr_len),
		//
		.f_axi_rd_checkid(f_axi_rd_checkid),
		.f_axi_rd_ckvalid(f_axi_rd_ckvalid),
		.f_axi_rd_cklen(f_axi_rd_cklen),
		.f_axi_rd_ckaddr(f_axi_rd_ckaddr),
		.f_axi_rd_ckincr(f_axi_rd_ckincr),
		.f_axi_rd_ckburst(f_axi_rd_ckburst),
		.f_axi_rd_cksize(f_axi_rd_cksize),
		.f_axi_rd_ckarlen(f_axi_rd_ckarlen),
		.f_axi_rdid_nbursts(f_axi_rdid_nbursts),
		.f_axi_rdid_outstanding(f_axi_rdid_outstanding),
		.f_axi_rdid_ckign_nbursts(f_axi_rdid_ckign_nbursts),
		.f_axi_rdid_ckign_outstanding(f_axi_rdid_ckign_outstanding)
	);

	localparam	[0:0]	F_OPT_WRITE_ONLY = 1'b0;
	generate if (F_OPT_WRITE_ONLY)
	begin
		// Assume we are read only
		always @(*)
			assume(!S_AXI_ARVALID);
		always @(*)
			assert(!S_AXI_RVALID);
		always @(*)
			assert(axi_arv_arr_flag == 0);

		always @(*)
			assert(f_axi_rd_outstanding == 0);
	end endgenerate

	localparam	[0:0]	F_OPT_READ_ONLY = 1'b0;
	generate if (F_OPT_READ_ONLY)
	begin
		// Assume we are read only
		always @(*)
			assume(!i_axi_awvalid);
		always @(*)
			assume(!i_axi_wvalid);
		always @(*)
			assert(!i_axi_bvalid);
		always @(*)
			assert(axi_awv_awr_flag == 0);

		always @(*)
			assert(f_axi_awr_nbursts == 0);

	end endgenerate

	always @(*)
		assert(!F_OPT_READ_ONLY || !F_OPT_WRITE_ONLY);

	////////////////////////////////////////////////////////////////////////
	//
	// Write induction properties
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	always @(*)
		assert((f_axi_wrid_nbursts == 0)
				||(f_axi_wrid_nbursts == f_axi_awr_nbursts));
	always @(*)
		assert(f_axi_awr_nbursts <= 1);

	always @(*)
		assert(axi_awlen_cntr <= axi_awlen+1);

	reg	[8:0]	f_wpending;
	always @(*)
		f_wpending = ({ 1'b0, axi_awlen} + 1 - { 1'b0, axi_awlen_cntr});

	always @(*)
	if (f_axi_wr_pending > 0)
		assert(f_wpending == f_axi_wr_pending);

	always @(*)
	if (f_axi_wr_pending > 0)
		assert(axi_awv_awr_flag);
	else if (!S_AXI_AWREADY)
		assert(!axi_awv_awr_flag);

	always @(*)
	if (f_axi_awr_nbursts > 0)
		assert(axi_awv_awr_flag || S_AXI_BVALID);

	always @(*)
	if ((f_axi_wr_ckvalid)&&(f_axi_wr_pending > 0))
	begin
		assert(axi_awaddr  == f_axi_wr_addr);
		assert(axi_awburst == f_axi_wr_burst);
		assert(axi_awlen   == f_axi_wr_len);
	end

	always @(*)
	if (axi_arv_arr_flag || !axi_awv_awr_flag)
		assert(!S_AXI_WREADY);

	////////////////////////////////////////////////////////////////////////
	//
	// Read induction properties
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	reg	[C_S_AXI_ADDR_WIDTH-1:0]	f_mem_rdaddr;
	wire	[C_S_AXI_ADDR_WIDTH-1:0]	next_rd_addr;
	wire	[7:0]				next_rd_incr;

	always @(*)
		assert((f_axi_rdid_nbursts == 0)
				||(f_axi_rdid_nbursts == f_axi_rd_nbursts));
	always @(*)
		assert((f_axi_rdid_outstanding == 0)
				||(f_axi_rdid_outstanding==f_axi_rd_outstanding));
	always @(*)
		assert(f_axi_rd_nbursts <= 1);
	always @(*)
		assert(f_axi_rdid_ckign_outstanding == 0);
	always @(*)
	if (f_axi_rd_ckvalid)
		assert(f_axi_rd_outstanding == f_axi_rd_cklen);
	always @(*)
	if (S_AXI_ARREADY)
		assert(f_axi_rd_outstanding == 0);
	always @(*)
		assert(axi_arlen_cntr <= axi_arlen+1);
	always @(posedge S_AXI_ACLK)
		f_mem_rdaddr <= axi_araddr;

	faxi_addr #(.AW(C_S_AXI_ADDR_WIDTH))
		get_next_rdaddr(f_mem_rdaddr, 3'b010,
			axi_arburst, axi_arlen,
			next_rd_incr, next_rd_addr);

	always @(posedge S_AXI_ACLK)
		assert(axi_arburst != 2'b11);
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN && f_axi_rd_ckvalid && f_axi_rdid_ckign_nbursts==0)
	begin
		if (!$past(S_AXI_RVALID && S_AXI_RREADY))
			assert(f_mem_rdaddr == axi_araddr);
		else
			assert(next_rd_addr == axi_araddr);
		if (axi_arburst == 0)
			assert(f_mem_rdaddr == axi_araddr);

		if (S_AXI_RVALID)
			assert(f_axi_rd_ckaddr == f_mem_rdaddr);
	end

	always @(*)
	if (f_axi_rd_ckvalid)
	begin
		assert(axi_arlen== f_axi_rd_ckarlen);
		assert(axi_arburst== f_axi_rd_ckburst);
	end
	always @(*)
	if (S_AXI_RVALID && S_AXI_RID == f_axi_rd_checkid)
	begin
		assert(f_axi_rdid_nbursts == f_axi_rd_nbursts);
		assert(f_axi_rdid_outstanding == f_axi_rd_outstanding);
		if (f_axi_rd_ckvalid)
			assert(f_axi_rd_ckaddr == f_mem_rdaddr);
	end

	reg	[8:0]	f_rpending;
	always @(*)
		f_rpending = ({ 1'b0, axi_arlen} + 1 - { 1'b0, axi_arlen_cntr});

	always @(*)
	if (f_axi_rd_outstanding > 0)
		assert(f_rpending == f_axi_rd_outstanding);

	////////////////////////////////////////////////////////////////////////
	//
	// Cover properties
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	reg	f_wr_cvr_valid;
	initial	f_wr_cvr_valid = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		f_wr_cvr_valid <= 0;
	else if (S_AXI_AWVALID && S_AXI_AWREADY && S_AXI_AWLEN > 4)
		f_wr_cvr_valid <= 1;

	always @(*)
	if (!F_OPT_READ_ONLY)
		cover(S_AXI_BVALID && f_wr_cvr_valid);

	reg	f_rd_cvr_valid;
	initial	f_rd_cvr_valid = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		f_rd_cvr_valid <= 0;
	else if (S_AXI_ARVALID && S_AXI_ARREADY && S_AXI_ARLEN > 4)
		f_rd_cvr_valid <= 1;

	always @(*)
	if (!F_OPT_WRITE_ONLY)
		cover(S_AXI_RVALID && S_AXI_RLAST && f_rd_cvr_valid);

	////////////////////////////////////////////////////////////////////////
	//
	// Assumptions necessary to pass a formal check
	//
	////////////////////////////////////////////////////////////////////////
	//
	//
	// BUG #1: The ID inputs, both ARID and AWID, are not registered.
	// 	As a result, if the master changes these values mid burst,
	//	the slave will return the wrong ID values
	always @(*)
		assume((S_AXI_ARID == f_axi_rd_checkid)
			==(f_axi_rdid_nbursts > 0));

	always @(*)
	if (f_axi_wr_pending > 0)
		assume((f_axi_wr_ckvalid) == (S_AXI_AWID == f_axi_wr_checkid));
	always @(*)
	if (f_axi_awr_nbursts > 0)
		assume((f_axi_wrid_nbursts>0) == (S_AXI_AWID == f_axi_wr_checkid));

	//
	// BUG #2: This core using the S_AXI_WLAST signal, without first
	//	checking that S_AXI_WVALID is also true.  Hence, if there's any
	//	time between WVALIDs, the core might act on the last one
	//	without receiving the data
	always @(*)
	if (S_AXI_WLAST)
		assume(S_AXI_WVALID);

	//
	// BUG #3: Like Xilinx's AXI-lite core, this core can't handle back
	//	pressure.  Should S_AXI_BREADY not be accepted before the next
	//	S_AXI_AWVALID & S_AXI_AWREADY, a burst would be dropped
	//
	always @(*)
	if (S_AXI_BVALID)
		assume(S_AXI_BREADY || !S_AXI_AWREADY);

	//
	// BAD PRACTICE: This particular core can't handle both reads and
	//	writes at the same time.  To avoid failing a stall timeout,
	//	we'll insist that no new transactions start while a
	//	transaction on the other side is in process
	always @(*)
	if (axi_arv_arr_flag || f_axi_rd_outstanding)
		assume(!S_AXI_AWVALID && !S_AXI_WVALID);
	always @(*)
	if (axi_awv_awr_flag || f_axi_awr_nbursts)
		assume(!S_AXI_ARVALID && !S_AXI_RVALID);

//
// Comments:
//
//	- ID's are broken.  The ID should be registered and recorded within the
//	    core, allowing the interconnect to change them after the transaction
//	    has been accepted
//
//	- This core does not support narrow burst mode, but rather only
//	    supports an AxSIZE of 2'b10 (32'bit bus).  It cannot handle busses
//	    of other sizes, or transactions from smaller sources.
//
//		This might be considered a "feature"
//
//	- This core can only handle read or write transactions, but never both
//	    at the same time
//
//		This might also be considered a "feature"
//
//	- The wrap logic depends upon a multiply
//
//		A good synthesis tool might simplify this
//
//	- Read transactions take place at one word every other clock at best
//
//		This is just plain crippled.
//
//	- Any back pressure could easily cause the core to lose a transaction,
//	    as the newer transaction's response will overwrite the waiting
//	    response from the previous transaction
//
`endif
// User logic ends
endmodule
