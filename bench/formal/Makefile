################################################################################
##
## Filename:	Makefile
##
## Project:	Pipelined Wishbone to AXI converter
##
## Purpose:	To direct the formal verification of the bus bridge
##		sources.
##
## Targets:	The default target, all, tests all of the components defined
##		within this module.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
##
## Copyright (C) 2017-2019, Gisselquist Technology, LLC
##
## This file is part of the pipelined Wishbone to AXI converter project, a
## project that contains multiple bus bridging designs and formal bus property
## sets.
##
## The bus bridge designs and property sets are free RTL designs: you can
## redistribute them and/or modify any of them under the terms of the GNU
## Lesser General Public License as published by the Free Software Foundation,
## either version 3 of the License, or (at your option) any later version.
##
## The bus bridge designs and property sets are distributed in the hope that
## they will be useful, but WITHOUT ANY WARRANTY; without even the implied
## warranty of MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with these designs.  (It's in the $(ROOT)/doc directory.  Run make
## with no target there if the PDF file isn't present.)  If not, see
## <http://www.gnu.org/licenses/> for a copy.
##
## License:	LGPL, v3, as defined and found on www.gnu.org,
##		http://www.gnu.org/licenses/lgpl.html
##
################################################################################
##
##
CROSSBARS := axilxbar wbxbar axixbar
BRIDGES := wbm2axilite axilrd2wbsp axilwr2wbsp axlite2wbsp wbp2classic wbc2pipeline wbm2axisp # axim2wbsp
# Still worth writing an AXI 2 AXI-lite bridge
AXISLAVES := demofull demoaxi xlnxfull axisafety
TESTS := wbarbiter $(BRDIGES) $(CROSSBARS) $(AXISLAVES)
.PHONY: $(TESTS)
all: $(TESTS)
RTL := ../../rtl
SMTBMC  := yosys-smtbmc
# SOLVER  := -s z3
SOLVER  := -s yices
# SOLVER  := -s boolector
BMCARGS := --presat $(SOLVER)
# BMCARGS := $(SOLVER)
INDARGS := $(SOLVER) -i

DEMOAXI    := demoaxi
WBARB      := wbarbiter
WB2AXI     := wbm2axisp
AXI2WB     := axim2wbsp
WB2LITE    := wbm2axilite
RDLITE     := axilrd2wbsp
WRLITE     := axilwr2wbsp
AXLITE     := axlite2wbsp
XILINXDEMO := xlnxdemo
XILINXFULL := xlnxfull_2018_3
XLNXSTREAM := xlnxstream_2018_3
AXIXBAR    := axixbar
AXILXBAR   := axilxbar
WBXBAR     := wbxbar
WBXBAR4x8  := wbxbar4x8
WBXBAR1x8  := wbxbar1x8
WBXBAR4x1  := wbxbar4x1
WBP2CLASSIC:= wbp2classic
WBC2PIPELIN:= wbc2pipeline
DEMOFULL   := demofull
AXISAFETY  := axisafety
AXIL       := faxil_master.v faxil_slave.v
WB         := fwb_master.v   fwb_slave.v
WBC        := fwbc_master.v  fwbc_slave.v
AXI        := faxi_master.v  faxi_slave.v  faxi_addr.v faxi_valaddr.v faxi_wstrb.v
AXIS       := faxis_master.v faxis_slave.v

.PHONY: $(WBARB) $(WB2AXI) $(RDLITE) $(WRLITE) $(AXLITE) $(WB2LITE) $(DEMOAXI)

$(WBARB): $(WBARB)_prf/PASS $(WBARB)_cvr/PASS
$(WBARB)_prf/PASS: $(RTL)/$(WBARB).v $(WBARB).sby $(WB)
	sby -f $(WBARB).sby
$(WBARB)_cvr/PASS: $(RTL)/$(WBARB).v $(WBARB).sby $(WB)
	sby -f $(WBARB).sby

.PHONY: $(WB2AXI)
$(WB2AXI): $(WB2AXI)_prfx8/PASS    $(WB2AXI)_prfx16/PASS
$(WB2AXI): $(WB2AXI)_prfe32/PASS   $(WB2AXI)_prfx32/PASS
$(WB2AXI): $(WB2AXI)_prfx64/PASS   $(WB2AXI)_prfx128/PASS
$(WB2AXI): $(WB2AXI)_prfx256/PASS  $(WB2AXI)_prfx512/PASS
$(WB2AXI): $(WB2AXI)_prfx1024/PASS $(WB2AXI)_cvr/PASS
$(WB2AXI)_prfx8/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby prfx8
$(WB2AXI)_prfx16/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby prfx16
$(WB2AXI)_prfe32/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby prfe32
$(WB2AXI)_prfx32/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby prfx32
$(WB2AXI)_prfx64/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby prfx64
$(WB2AXI)_prfx128/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby prfx128
$(WB2AXI)_prfx256/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby prfx256
$(WB2AXI)_prfx512/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby prfx512
$(WB2AXI)_prfx1024/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby prfx1024
$(WB2AXI)_cvr/PASS: $(RTL)/$(WB2AXI).v $(WB2AXI).sby $(WB) $(AXI)
	sby -f $(WB2AXI).sby cvr

$(RDLITE): $(RDLITE)_prf/PASS $(RDLITE)_cvr/PASS
$(RDLITE)_prf/PASS: $(RDLITE).sby $(RTL)/$(RDLITE).v $(WB) $(AXIL)
	sby -f $(RDLITE).sby prf
$(RDLITE)_cvr/PASS: $(RDLITE).sby $(RTL)/$(RDLITE).v $(WB) $(AXIL)
	sby -f $(RDLITE).sby cvr

$(WRLITE): $(WRLITE)_prf/PASS $(WRLITE)_cvr/PASS
$(WRLITE)_prf/PASS: $(WRLITE).sby $(RTL)/$(WRLITE).v $(WB) $(AXIL)
	sby -f $(WRLITE).sby prf
$(WRLITE)_cvr/PASS: $(WRLITE).sby $(RTL)/$(WRLITE).v $(WB) $(AXIL)
	sby -f $(WRLITE).sby cvr

.PHONY: $(AXLITE)
$(AXLITE): $(AXLITE)_prf/PASS $(AXLITE)_cvr/PASS
AXLITE_DEPS := $(RTL)/$(RDLITE).v $(RTL)/$(WRLITE).v $(AXIL) $(WB)	\
	$(RTL)/$(WBARB).v $(AXLITE).sby $(RTL)/$(AXLITE).v		\
	$(RDLITE)_prf/PASS $(RDLITE)_cvr/PASS				\
	$(WRLITE)_prf/PASS $(WRLITE)_cvr/PASS

$(AXLITE)_prf/PASS: $(AXLITE_DEPS)
	sby -f $(AXLITE).sby prf

$(AXLITE)_cvr/PASS: $(AXLITE_DEPS)
	sby -f $(AXLITE).sby cvr

.PHONY: $(WB2LITE)
$(WB2LITE): $(WB2LITE)_cvr/PASS $(WB2LITE)_prf/PASS
$(WB2LITE)_prf/PASS: $(RTL)/$(WB2LITE).v $(WB) $(AXIL)
$(WB2LITE)_prf/PASS: $(WB2LITE).sby
	sby -f $(WB2LITE).sby prf

$(WB2LITE)_cvr/PASS: $(RTL)/$(WB2LITE).v $(WB) $(AXIL)
$(WB2LITE)_cvr/PASS: $(WB2LITE).sby
	sby -f $(WB2LITE).sby cvr

.PHONY: $(DEMOAXI)
$(DEMOAXI): $(DEMOAXI)_prf/PASS $(DEMOAXI)_cvr/PASS
$(DEMOAXI)_prf/PASS: $(RTL)/$(DEMOAXI).v $(DEMOAXI).sby $(AXIL)
	sby -f $(DEMOAXI).sby prf
$(DEMOAXI)_cvr/PASS: $(RTL)/$(DEMOAXI).v $(DEMOAXI).sby $(AXIL)
	sby -f $(DEMOAXI).sby cvr

.PHONY: $(XILINXDEMO)
$(XILINXDEMO): $(XILINXDEMO)_prf/PASS $(XILINXDEMO)_cvr/PASS
$(XILINXDEMO)_prf/PASS: $(XILINXDEMO).v $(XILINXDEMO).sby $(AXIL)
	sby -f $(XILINXDEMO).sby prf
$(XILINXDEMO)_cvr/PASS: $(XILINXDEMO).v $(XILINXDEMO).sby $(AXIL)
	sby -f $(XILINXDEMO).sby cvr

.PHONY: $(XILINXFULL) xlnxfull
xlnxfull: $(XILINXFULL)
$(XILINXFULL): $(XILINXFULL)_prf/PASS $(XILINXFULL)_cvr/PASS
$(XILINXFULL)_prf/PASS: $(XILINXFULL).v $(XILINXFULL).sby $(AXI)
	sby -f $(XILINXFULL).sby prf
$(XILINXFULL)_cvr/PASS: $(XILINXFULL).v $(XILINXFULL).sby $(AXI)
	sby -f $(XILINXFULL).sby cvr


.PHONY: $(AXI2WB)
$(AXI2WB)/PASS: $(RTL)/$(AXI2WB).v $(AXI2WB).sby
$(AXI2WB)/PASS: $(WB) $(AXI)
$(AXI2WB)/PASS: f_order.v
$(AXI2WB)/PASS: $(RTL)/aximwr2wbsp.v $(RTL)/aximrd2wbsp.v
$(AXI2WB)/PASS: $(RTL)/wbarbiter.v
	echo "The AXI2WB bridge does not work yet, so I do not expect this one to pass"
	echo sby -f $(AXI2WB).sby

.PHONY: $(AXIXBAR) $(AXIXBAR)_prf $(AXIXBAR)_cvr
$(AXIXBAR): $(AXIXBAR)_prf # $(AXIXBAR)_cvr
$(AXIXBAR)_prf: $(AXIXBAR)_prf4x8_lpg/PASS
$(AXIXBAR)_prf: $(AXIXBAR)_prf4x8_lin/PASS
$(AXIXBAR)_prf: $(AXIXBAR)_prf4x8_lp/PASS
$(AXIXBAR)_prf: $(AXIXBAR)_prf4x8/PASS
$(AXIXBAR)_prf: $(AXIXBAR)_prf1x8_lp/PASS
$(AXIXBAR)_prf: $(AXIXBAR)_prf1x8/PASS
$(AXIXBAR)_prf: $(AXIXBAR)_prf4x1_lp/PASS
$(AXIXBAR)_prf: $(AXIXBAR)_prf4x1/PASS
#
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr3x3_lpg/PASS
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr3x3_lin/PASS
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr3x3_lp/PASS
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr3x3/PASS
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr1x3_lpg/PASS
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr1x3_lin/PASS
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr1x3_lp/PASS
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr1x3/PASS
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr4x1_lp/PASS
$(AXIXBAR)_cvr: $(AXIXBAR)_cvr4x1/PASS

$(AXIXBAR)_prf4x8_lpg/PASS: $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby prf4x8_lpg
$(AXIXBAR)_prf4x8_lin/PASS:    $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby prf4x8_lin
$(AXIXBAR)_prf4x8_lp/PASS: $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby prf4x8_lp
$(AXIXBAR)_prf4x8/PASS:    $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby prf4x8
$(AXIXBAR)_prf1x8_lp/PASS: $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby prf1x8_lp
$(AXIXBAR)_prf1x8/PASS:    $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby prf1x8
$(AXIXBAR)_prf4x1_lp/PASS: $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby prf4x1_lp
$(AXIXBAR)_prf4x1/PASS:    $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby prf4x1

$(AXIXBAR)_cvr3x3_lpg/PASS: $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr3x3_lpg
$(AXIXBAR)_cvr3x3_lin/PASS:    $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr3x3_lin
$(AXIXBAR)_cvr3x3_lp/PASS: $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr3x3_lp
$(AXIXBAR)_cvr3x3/PASS:    $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr3x3
$(AXIXBAR)_cvr1x3_lpg/PASS: $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr1x3_lpg
$(AXIXBAR)_cvr1x3_lin/PASS:    $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr1x3_lin
$(AXIXBAR)_cvr1x3_lp/PASS: $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr1x3_lp
$(AXIXBAR)_cvr1x3/PASS:    $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr1x3
$(AXIXBAR)_cvr4x1_lp/PASS: $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr4x1_lp
$(AXIXBAR)_cvr4x1/PASS:    $(RTL)/$(AXIXBAR).v $(AXIXBAR).sby $(AXI)
	sby -f $(AXIXBAR).sby cvr4x1

.PHONY: $(AXILXBAR) $(AXILXBAR)prf $(AXILXBAR)cvr
$(AXILXBAR): $(AXILXBAR)prf $(AXILXBAR)cvr
$(AXILXBAR)prf: $(AXILXBAR)_prf4x8_lp/PASS
$(AXILXBAR)prf: $(AXILXBAR)_prf1x8_lp/PASS
$(AXILXBAR)prf: $(AXILXBAR)_prf4x1_lp/PASS
$(AXILXBAR)prf: $(AXILXBAR)_prf4x8/PASS
$(AXILXBAR)prf: $(AXILXBAR)_prf1x8/PASS
$(AXILXBAR)prf: $(AXILXBAR)_prf4x1/PASS
$(AXILXBAR)_prf4x8/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby prf4x8
$(AXILXBAR)_prf1x8/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby prf1x8
$(AXILXBAR)_prf4x1/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby prf4x1
$(AXILXBAR)_prf4x8_lp/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby prf4x8_lp
$(AXILXBAR)_prf1x8_lp/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby prf1x8_lp
$(AXILXBAR)_prf4x1_lp/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby prf4x1_lp
$(AXILXBAR)cvr: $(AXILXBAR)_cvr4x8_lp/PASS
$(AXILXBAR)cvr: $(AXILXBAR)_cvr4x8/PASS
$(AXILXBAR)cvr: $(AXILXBAR)_cvr1x3_lp/PASS
$(AXILXBAR)cvr: $(AXILXBAR)_cvr1x3/PASS
$(AXILXBAR)cvr: $(AXILXBAR)_cvr4x1_lp/PASS
$(AXILXBAR)cvr: $(AXILXBAR)_cvr4x1/PASS
$(AXILXBAR)_cvr4x8/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby cvr4x8
$(AXILXBAR)_cvr1x3/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby cvr1x3
$(AXILXBAR)_cvr4x1/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby cvr4x1
$(AXILXBAR)_cvr4x8_lp/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby cvr4x8_lp
$(AXILXBAR)_cvr1x3_lp/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby cvr1x3_lp
$(AXILXBAR)_cvr4x1_lp/PASS: $(AXILXBAR).sby $(RTL)/$(AXILXBAR).v $(AXIL)
	sby -f $(AXILXBAR).sby cvr4x1_lp


.PHONY: $(WBXBAR) $(WBXBAR4x8) $(WBXBAR1x8) $(WBXBAR4x1)
.PHONY: $(WBXBAR)_prf $(WBXBAR)_cvr
.PHONY: $(WBXBAR4x8)_prf $(WBXBAR4x8)_cvr
.PHONY: $(WBXBAR1x8)_prf $(WBXBAR1x8)_cvr
.PHONY: $(WBXBAR4x1)_prf $(WBXBAR4x1)_cvr
$(WBXBAR): $(WBXBAR4x8) $(WBXBAR1x8) $(WBXBAR4x1)
$(WBXBAR)_prf: $(WBXBAR4x8)_prf $(WBXBAR1x8)_prf $(WBXBAR4x1)_prf
$(WBXBAR)_cvr: $(WBXBAR4x8)_cvr $(WBXBAR1x8)_cvr $(WBXBAR4x1)_cvr

$(WBXBAR4x8): $(WBXBAR4x8)_prf $(WBXBAR4x8)_cvr
$(WBXBAR1x8): $(WBXBAR1x8)_prf $(WBXBAR1x8)_cvr
$(WBXBAR4x1): $(WBXBAR4x1)_prf $(WBXBAR4x1)_cvr

$(WBXBAR4x8)_prf: wbxbar_prf4x8_buflp/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_buf/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_lp/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_cheap/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_buflpko/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_bufko/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_lpko/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_cheapko/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_buflpkos/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_bufkos/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_lpkos/PASS
$(WBXBAR4x8)_prf: wbxbar_prf4x8_cheapkos/PASS

wbxbar_prf4x8_buflp/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_buflp
wbxbar_prf4x8_buf/PASS:      $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_buf
wbxbar_prf4x8_lp/PASS:       $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_lp
wbxbar_prf4x8_cheap/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_cheap
#
wbxbar_prf4x8_buflpko/PASS:  $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_buflpko
wbxbar_prf4x8_bufko/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_bufko
wbxbar_prf4x8_lpko/PASS:     $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_lpko
wbxbar_prf4x8_cheapko/PASS:  $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_cheapko
wbxbar_prf4x8_buflpkos/PASS: $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_buflpkos
wbxbar_prf4x8_bufkos/PASS:   $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_bufkos
wbxbar_prf4x8_lpkos/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_lpkos
wbxbar_prf4x8_cheapkos/PASS: $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x8_cheapkos

#
#
$(WBXBAR4x8)_cvr: wbxbar_cvr4x8_buflp/PASS
$(WBXBAR4x8)_cvr: wbxbar_cvr4x8_buf/PASS
$(WBXBAR4x8)_cvr: wbxbar_cvr4x8_lp/PASS
$(WBXBAR4x8)_cvr: wbxbar_cvr4x8_cheap/PASS
#
wbxbar_cvr4x8_buflp/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr4x8_buflp
wbxbar_cvr4x8_buf/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr4x8_buf
wbxbar_cvr4x8_lp/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr4x8_lp
wbxbar_cvr4x8_cheap/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr4x8_cheap
#
#
$(WBXBAR1x8)_prf: wbxbar_prf1x8_buflp/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_buf/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_lp/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_cheap/PASS
#

wbxbar_prf1x8_buflp/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_buflp
wbxbar_prf1x8_buf/PASS:      $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_buf
wbxbar_prf1x8_lp/PASS:       $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_lp
wbxbar_prf1x8_cheap/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_cheap
#
#
$(WBXBAR1x8)_cvr: wbxbar_cvr1x3_buflp/PASS
$(WBXBAR1x8)_cvr: wbxbar_cvr1x3_buf/PASS
$(WBXBAR1x8)_cvr: wbxbar_cvr1x3_lp/PASS
$(WBXBAR1x8)_cvr: wbxbar_cvr1x3_cheap/PASS
#
wbxbar_cvr1x3_buflp/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr1x3_buflp
wbxbar_cvr1x3_buf/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr1x3_buf
wbxbar_cvr1x3_lp/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr1x3_lp
wbxbar_cvr1x3_cheap/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr1x3_cheap
#
#
$(WBXBAR1x8)_prf: wbxbar_prf1x8_buflpko/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_bufko/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_lpko/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_cheapko/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_buflpkos/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_bufkos/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_lpkos/PASS
$(WBXBAR1x8)_prf: wbxbar_prf1x8_cheapkos/PASS
#
wbxbar_prf1x8_buflpko/PASS:  $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_buflpko
wbxbar_prf1x8_bufko/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_bufko
wbxbar_prf1x8_lpko/PASS:     $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_lpko
wbxbar_prf1x8_cheapko/PASS:  $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_cheapko
wbxbar_prf1x8_buflpkos/PASS: $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_buflpkos
wbxbar_prf1x8_bufkos/PASS:   $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_bufkos
wbxbar_prf1x8_lpkos/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_lpkos
wbxbar_prf1x8_cheapkos/PASS: $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf1x8_cheapkos
#
#
$(WBXBAR4x1)_prf: wbxbar_prf4x1_buflp/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_buf/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_lp/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_cheap/PASS
#
wbxbar_prf4x1_buflp/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_buflp
wbxbar_prf4x1_buf/PASS:      $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_buf
wbxbar_prf4x1_lp/PASS:       $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_lp
wbxbar_prf4x1_cheap/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_cheap
#
$(WBXBAR4x1)_prf: wbxbar_prf4x1_buflpko/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_bufko/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_lpko/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_cheapko/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_buflpkos/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_bufkos/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_lpkos/PASS
$(WBXBAR4x1)_prf: wbxbar_prf4x1_cheapkos/PASS
#
wbxbar_prf4x1_buflpko/PASS:  $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_buflpko
wbxbar_prf4x1_bufko/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_bufko
wbxbar_prf4x1_lpko/PASS:     $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_lpko
wbxbar_prf4x1_cheapko/PASS:  $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_cheapko
wbxbar_prf4x1_buflpkos/PASS: $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_buflpkos
wbxbar_prf4x1_bufkos/PASS:   $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_bufkos
wbxbar_prf4x1_lpkos/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_lpkos
wbxbar_prf4x1_cheapkos/PASS: $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby prf4x1_cheapkos
#
$(WBXBAR4x1)_cvr: wbxbar_cvr4x1_buflp/PASS
$(WBXBAR4x1)_cvr: wbxbar_cvr4x1_buf/PASS
$(WBXBAR4x1)_cvr: wbxbar_cvr4x1_lp/PASS
$(WBXBAR4x1)_cvr: wbxbar_cvr4x1_cheap/PASS
#
wbxbar_cvr4x1_buflp/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr4x1_buflp
wbxbar_cvr4x1_buf/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr4x1_buf
wbxbar_cvr4x1_lp/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr4x1_lp
wbxbar_cvr4x1_cheap/PASS:    $(WBXBAR).sby $(RTL)/$(WBXBAR).v $(WB)
	sby -f $(WBXBAR).sby cvr4x1_cheap
#
#

.PHONY: $(WBP2CLASSIC)
$(WBP2CLASSIC): $(WBP2CLASSIC)_prf/PASS $(WBP2CLASSIC)_cvr/PASS
$(WBP2CLASSIC)_prf/PASS: $(RTL)/$(WBP2CLASSIC).v $(WB) $(WBC)
	sby -f $(WBP2CLASSIC).sby prf
$(WBP2CLASSIC)_cvr/PASS: $(RTL)/$(WBP2CLASSIC).v $(WB) $(WBC)
	sby -f $(WBP2CLASSIC).sby cvr

.PHONY: $(WBC2PIPELIN)
$(WBC2PIPELIN): $(WBC2PIPELIN)_prf/PASS $(WBC2PIPELIN)_cvr/PASS
$(WBC2PIPELIN)_prf/PASS: $(RTL)/$(WBC2PIPELIN).v $(WB) $(WBC)
	sby -f $(WBC2PIPELIN).sby prf
$(WBC2PIPELIN)_cvr/PASS: $(RTL)/$(WBC2PIPELIN).v $(WB) $(WBC)
	sby -f $(WBC2PIPELIN).sby cvr

.PHONY: $(DEMOFULL)
$(DEMOFULL): $(DEMOFULL)_prf/PASS     $(DEMOFULL)_prfn/PASS
$(DEMOFULL): $(DEMOFULL)_prf8/PASS    $(DEMOFULL)_prfn8/PASS
$(DEMOFULL): $(DEMOFULL)_prf16/PASS   $(DEMOFULL)_prfn16/PASS
$(DEMOFULL): $(DEMOFULL)_prf64/PASS   $(DEMOFULL)_prfn64/PASS
$(DEMOFULL): $(DEMOFULL)_prf128/PASS  $(DEMOFULL)_prfn128/PASS
$(DEMOFULL): $(DEMOFULL)_prf256/PASS  $(DEMOFULL)_prfn256/PASS
$(DEMOFULL): $(DEMOFULL)_cvr/PASS
$(DEMOFULL)_prf/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prf
$(DEMOFULL)_cvr/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby cvr
$(DEMOFULL)_prfn/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prfn
$(DEMOFULL)_prf8/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prf8
$(DEMOFULL)_prfn8/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prfn8
$(DEMOFULL)_prf16/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prf16
$(DEMOFULL)_prfn16/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prfn16
$(DEMOFULL)_prf64/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prf64
$(DEMOFULL)_prfn64/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prfn64
$(DEMOFULL)_prf128/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prf128
$(DEMOFULL)_prfn128/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prfn128
$(DEMOFULL)_prfn256/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prf256
$(DEMOFULL)_prf256/PASS: $(DEMOFULL).sby $(RTL)/$(DEMOFULL).v $(AXI) $(RTL)/axi_addr.v
	sby -f $(DEMOFULL).sby prfn256

.PHONY: $(AXISAFETY)
$(AXISAFETY): $(AXISAFETY)_prf/PASS   $(AXISAFETY)_prfr/PASS
$(AXISAFETY): $(AXISAFETY)_fault/PASS $(AXISAFETY)_faultr/PASS
$(AXISAFETY): $(AXISAFETY)_cvr/PASS
$(AXISAFETY)_prf/PASS:   $(AXISAFETY).sby $(RTL)/$(AXISAFETY).v $(AXI)
	sby -f $(AXISAFETY).sby prf
$(AXISAFETY)_fault/PASS: $(AXISAFETY).sby $(RTL)/$(AXISAFETY).v $(AXI)
	sby -f $(AXISAFETY).sby fault
$(AXISAFETY)_cvr/PASS:   $(AXISAFETY).sby $(RTL)/$(AXISAFETY).v $(AXI)
	sby -f $(AXISAFETY).sby cvr
$(AXISAFETY)_prfr/PASS:   $(AXISAFETY).sby $(RTL)/$(AXISAFETY).v $(AXI)
	sby -f $(AXISAFETY).sby prfr
$(AXISAFETY)_faultr/PASS:   $(AXISAFETY).sby $(RTL)/$(AXISAFETY).v $(AXI)
	sby -f $(AXISAFETY).sby faultr

.PHONY: clean
clean:
	rm -rf  $(DEMOAXI)_*/
	rm -rf  $(WBARB)_*/
	rm -rf  $(WB2LITE)_*/
	rm -rf  $(RDLITE)_*/
	rm -rf  $(WRLITE)_*/
	rm -rf  $(AXLITE)_*/
	rm -rf  $(XILINXFULL)_*/
	rm -rf  $(AXILXBAR)_*/
	rm -rf  $(WBXBAR)_*/
	rm -rf  $(WBP2CLASSIC)_*/
	rm -rf  $(WBC2PIPELIN)_*/
	rm -rf  $(DEMOFULL)_*/
	rm -rf  $(AXISAFETY)_*/
	@# The three broken cores, to include Xilinx's
	rm -rf  $(WB2AXI)_*/
	rm -rf  $(AXI2WB)_*/
	rm -rf  $(XILINXDEMO)_*/
	rm -rf  $(XLNXSTREAM)_*/
	# rm -f *.check
