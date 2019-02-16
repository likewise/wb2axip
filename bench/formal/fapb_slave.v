`default_nettype	none
module	fapb_slave(PCLK, PRESETn, PADDR, PSEL, PENABLE, PWRITE, PWDATA, PREADY, PRDATA, PSLVERR);
	input	wire	PCLK, PRESETn;
	input	wire	[AW-1:0]	PADDR;
	input	wire			PSEL;
	input	wire			PENABLE;
	input	wire			PWRITE;
	input	wire	[DW-1:0]	PWDATA;
	input	wire			PREADY;
	input	wire	[DW-1:0]	PRDATA;
	input	wire			PSLVERR;

	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

	always @(posedge i_clk)
	if (!f_past_valid)
		`SLAVE_ASSUME(PRESETn);

	// PSEL
	// PREADY
	// Constant PADDR and PWRITE
	// PWDATA
	always @(posedge i_clk)
	if ((!f_past_valid)||(!$past(PRESETn)))
	begin
		`SLAVE_ASSUME(!PSEL);
		`SLAVE_ASSERT(!PREADY);
	end else if ($past(PSEL))
	begin
		if (!$past(PENABLE) || ($past(PENABLE) && !$past(PREADY)))
		begin
			`SLAVE_ASSUME($stable(PADDR));
			`SLAVE_ASSUME($stable(PWRITE));
			if (PWRITE)
				`SLAVE_ASSUME($stable(PWDATA));
		end
	end else
		`SLAVE_ASSUME(!PENABLE);

	//
	// ENABLE
	always @(posedge i_clk)
	if (f_past_valid && $past(PRESETn))
	begin
		if ($past(PENABLE) && $past(PSEL))
		begin
			if ($past(PREADY))
				`SLAVE_ASSUME(!PENABLE);
			else
				`SLAVE_ASSUME(PENABLE);
		end else if ((!$past(PSEL))&&(PSEL))
			`SLAVE_ASSUME(!PENABLE);
	end

	//
	// PREADY
	//	Can take on any value when PSEL is low
	// always @(posedge i_clk)
	// if !(f_past_valid)&&(!$past(PSEL)))
	//	`SLAVE_ASSERT(!PREADY);

	always @(*)
	if (!PREADY)
		`SLAVE_ASSERT(!SLVERR);
endmodule
