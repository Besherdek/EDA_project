`timescale	1ns/1ns
module testbench();
  
  logic clk;
  logic rst;
  logic [23:0] mic;
  logic [255:0] out;
  
  time clk_period = 10ns;

  initial begin
  	clk = 0;
  	rst = 0;
  end
  
  initial begin
    repeat(5) begin
      @(posedge clk);
    end
    rst = 1;
    @(posedge clk);
    rst = 0;
    
    // send_inputs();
    // display_outputs();
  end
  
  initial begin

    #(27*clk_period);
    $finish();
  end
  
  always begin
    #(clk_period/2);
    clk = ~clk;
    $display(clk);
  end
  
  
//   task send_inputs();
//     @(posedge clk);
    
    
//   endtask
  
//   task display_output();
//     forever begin
//       @(posedge clk);
//       $display("%d", out);  
//     end
    
//   endtask
  
  lab_top u_lab_top
  (
   	.clk(clk),
    .rst(rst),
    .mic(mic),
    .result(out)
  );
  
endmodule