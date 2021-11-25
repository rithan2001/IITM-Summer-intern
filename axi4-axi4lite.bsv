
package axi4-axi4lite;
  `include "Logger.bsv"
  import FIFO :: * ;
  import FIFOF :: * ;
  import SpecialFIFOs :: * ;
	import AXI4_Types:: *;
	import AXI4_Lite_Types:: *;
	import AXI4_Fabric:: *;
	import AXI4_Lite_Fabric:: *;
endpackage

interface Ifc_axi4_axi4lite;
interface AXI4_Lite_Slave_IFC#(`PADDR,32,`USERSPACE) slave_axi_lite
interface AXI4_Slave_IFC#(`PADDR,`Reg_width,`USERSPACE) slave_axi;
endinterface

		/*-============================================================================= */

module mkaxitolite(Ifc_axi_axi4lite);
		
	   AXI4_Slave_Xactor_IFC #(`PADDR,`Reg_width,`USERSPACE)s_xactor <- mkAXI4_Slave_Xactor;
	   AXI4_Lite_Slave_Xactor_IFC #(`PADDR,32,`USERSPACE) s_lite_xactor <- mkAXI4_Lite_Slave_Xactor;
     FIFOF#(Bit#(4)) ff_id <-mkSizedFIFOF(2);//To store request address of instruction

		rule check_wr_request_to_memory();
      let info<-pop_o(s_xactor.o_wr_addr);
      let data<-pop_o(s_xactor.o_wr_data);
      let write_addr = info.awaddr>>2; 
		  AXI4_Lite_Wr_Addr#(`paddr, 0) aw = AXI4_Lite_Wr_Addr {awaddr : truncate(write_addr), awuser : 0,
      awsize : 3'b010,awprot:{1'b0, 1'b0, curr_priv[1]}}; 
  	  let w  = AXI4_Lite_Wr_Data {wdata : truncate(req.data), wstrb : '1};
	    s_lite_xactor.i_wr_addr.enq(aw);
		  s_lite_xactor.i_wr_data.enq(w);
      ff_id.enq(info.awid);
      `logLevel( Bridge, 1, $format("BRIDGE:Sending AXI4 response to address",info.awaddr))
      ff_address.enq(info.awaddr);
      //Request scheduling
   endrule
	  
	 rule check_read_request_to_memory();
      let info<-pop_o(s_xactor.o_rd_addr);
      let write_addr = info.araddr>>2; 
		  AXI4_Lite_Rd_Addr#(`paddr, 0) ar = AXI4_Lite_Rd_Addr {araddr : truncate(write_addr), aruser : 0,
      arsize : 3'b010,arprot:{1'b0, 1'b0, curr_priv[1]}}; 
	    s_lite_xactor.i_rd_addr.enq(ar);
      ff_id.enq(info.arid);
      `logLevel( bridge, 1, $format("BRIDGE:Sending AXI4 response to address",info.araddr))
      ff_address.enq(info.araddr);
	  endrule
     
  rule send_read_response_from_memory(); 
      let info<-pop_o(s_xactor.o_rd_data);
		  AXI4__Rd_Data#(`paddr, 0) rd_resp = AXI4_Lite_Rd_Data {rresp : info.rresp, rid : ff_id.first,
      rdata: zeroExtend(info.rd_data),rlast:True,ruser:0}; 
      ff_id.deq();
      s_xactor.i_rd_data.enq(rd_resp);
	endrule

  rule send_write_response_from_memory(); 
      let info<-pop_o(s_xactor.o_wr_resp);
		  AXI4__Wr_Resp#(`paddr, 0) wr = AXI4_Lite_Wr_Resp {wresp : info.wresp, bid : ff_id.first,
      wlast:True, wuser:0}; 
      ff_id.deq();
      s_xactor.i_wr_resp.enq(wr);
	endrule
	  interface slave_axi = s_xactor.axi_side;
	  interface slave_axi_lite = s_lite_xactor.axi_side;
endmodule
