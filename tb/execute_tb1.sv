`timescale 1ns / 1ps

module execute_tb1 ();
  logic clk_i;
  logic rst_ni;
  logic [DATA_WIDTH-1:0] op_a_i;  // Register A operand (data) from
  logic  [DATA_WIDTH-1:0]         op_b_i; // Register B operand (data) or sign extended immediate 32'b values
  logic [4:0] ALU_OP;
  logic [DATA_WIDTH-1:0] alu_res_o;  // ALU result from procesing operands
  logic branch_taken_o;  // Control signal for whether branch should be taken
  logic stall_o;  // used for stalling the pipeline when division module enters STALL state


  execute DUT (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .op_a_i(op_a_i),
      .op_b_i(op_b_i),
      .ALU_OP(ALU_OP),
      .alu_res_o(alu_res_o),
      .branch_taken_o(branch_taken_o),
      .stall_o(stall_o)
  );

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, execute_tb1);
  end

  initial begin
    clk_i = 1'b0;  // initialize clock to 0    
    forever #5 clk_i = ~clk_i;
  end

  task automatic Add(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_ADD;  // set ALU operation to addition


    // Wait for addition to complete (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("Add %0d and %0d, got result: %0d", A, B, alu_res_o);

    assert (alu_res_o == A + B)
    else $fatal("Addition result is incorrect. Expected: %0d, Got: %0d", A + B, alu_res_o);

  endtask

  task automatic Sub(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_SUB;  // set ALU operation to subtraction


    // wait for subtraction to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("SUB %0d and %0d, got result: %0d", A, B, alu_res_o);

    assert (alu_res_o == A - B)
    else $fatal("SUB result is incorrect. Expected: %0d, Got: %0d", A - B, alu_res_o);

  endtask

  task automatic SLL(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_SLL;  // set ALU operation to shift left


    // wait for shift left to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("SLL %0d and %0d, got result: %0d", A, B, alu_res_o);

    assert (alu_res_o == A << B)
    else $fatal("SLL result is incorrect. Expected: %0d, Got: %0d", A << B, alu_res_o);

  endtask

  task automatic SLT(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_SLT;  // set ALU operation to set less than


    // wait for set less than to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("SLT %0d and %0d, got result: %0d", $signed(A), $signed(B), $signed(alu_res_o));

    assert ($signed(alu_res_o) == ($signed(A) < $signed(B) ? 1 : 0))
    else
      $fatal(
          "SLT result is incorrect. Expected: %0d, Got: %0d",
          $signed(
              A
          ) < $signed(
              B
          ) ? 1 : 0,
          $signed(
              alu_res_o
          )
      );

  endtask

  task automatic SLTU(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_SLTU;  // set ALU operation to set less than unsigned


    // wait for set less than to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("STLU %0d and %0d, got result: %0d", A, B, alu_res_o);

    assert (alu_res_o == (A < B ? 1 : 0))
    else $fatal("SLTU result is incorrect. Expected: %0d, Got: %0d", A < B ? 1 : 0, alu_res_o);

  endtask

  task automatic XOR(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_XOR;  // set ALU operation to exclusive or


    // wait for set less than to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("XORing %0d and %0d, got result: %0d", A, B, alu_res_o);

    assert (alu_res_o == A ^ B)
    else $fatal("XOR result is incorrect. Expected: %0d, Got: %0d", A ^ B, alu_res_o);

  endtask

  task automatic BEQ(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_BEQ;  // set ALU operation to branch if equal


    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    //@(posedge clk_i);


    $display("BEQ %0d and %0d, got result: %0d", $signed(A), $signed(B), branch_taken_o);

    assert ((branch_taken_o) == ($signed(A) == $signed(B) ? 1 : 0))
    else begin
      $fatal("BEQ result is incorrect. Expected: %0d, Got: %0d", $signed(A) == $signed(B) ? 1 : 0,
             (branch_taken_o));
    end

  endtask

  task automatic BNE(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_BNE;  // set ALU operation to branch if not equal


    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("BNE %0d and %0d, got result: %0d", $signed(A), $signed(B), branch_taken_o);

    assert ((branch_taken_o) == ($signed(A) != $signed(B) ? 1 : 0))
    else begin
      $fatal("BNE result is incorrect. Expected: %0d, Got: %0d", $signed(A) != $signed(B) ? 1 : 0,
             branch_taken_o);
    end

  endtask


  task automatic BLT(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_BLT;  // set ALU operation to branch if less than


    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("BLT %0d and %0d, got result: %0d", $signed(A), $signed(B), branch_taken_o);

    assert (branch_taken_o == ($signed(A) < $signed(B) ? 1 : 0))
    else begin
      $fatal("BLT result is incorrect. Expected: %0d, Got: %0d", $signed(A) < $signed(B) ? 1 : 0,
             branch_taken_o);
    end

  endtask


  task automatic BLTU(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_BLTU;  // set ALU operation to branch if less than unsigned


    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("BLTU %0d and %0d, got result: %0d", A, B, branch_taken_o);

    assert (branch_taken_o == (A < B ? 1 : 0))
    else begin
      $fatal("BLTU result is incorrect. Expected: %0d, Got: %0d", A < B ? 1 : 0, branch_taken_o);
    end

  endtask


  task automatic BGE(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_BGE;  // set ALU operation to branch if greater than or equal


    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("BGE %0d and %0d, got result: %0d", $signed(A), $signed(B), branch_taken_o);

    assert (branch_taken_o == ($signed(A) >= $signed(B) ? 1 : 0))
    else begin
      $fatal("BGE result is incorrect. Expected: %0d, Got: %0d", $signed(A) >= $signed(B) ? 1 : 0,
             branch_taken_o);
    end

  endtask


  task automatic BGEU(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_BGEU;  // set ALU operation to branch if greater than or equal unsigned


    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);


    $display("BGEU %0d and %0d, got result: %0d", A, B, branch_taken_o);

    assert (branch_taken_o == (A >= B ? 1 : 0))
    else begin
      $fatal("BGEU result is incorrect. Expected: %0d, Got: %0d", A >= B ? 1 : 0, branch_taken_o);
    end

  endtask

  logic [63:0] expected_mul;  // 64-bit result of multiplication to compare against lower bits of ALU output

  task automatic MUL(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_MUL;  // set ALU operation to multiplication

    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);

    expected_mul = A * B;  // lower 32 bits of multiplication result to compare against ALU output

    $display("MUL Lower bits %0d and %0d, got result: %0d", A, B, alu_res_o[31:0]);

    assert (alu_res_o[31:0] == expected_mul[31:0])
    else begin
      $fatal("MUL lower bitresult is incorrect. Expected: %0d, Got: %0d", expected_mul[31:0],
             alu_res_o[31:0]);
    end

  endtask

  logic signed [63:0] expected_mulh;  // 64-bit result of multiplication to compare against upper bits of ALU output


  task automatic MULH(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_MULH;  // set ALU operation to multiplication

    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);

    expected_mulh = $signed(A) *
        $signed(B);  // 64-bit result of multiplication to compare against upper bits of ALU output

    $display("MULH Upper bits %0d and %0d, got result: %0d", $signed(A), $signed(B),
             $signed(alu_res_o[31:0]));

    assert ($signed(alu_res_o[31:0]) == $signed(expected_mulh[63:32]))
    else begin
      $fatal("MULH upper bitresult is incorrect. Expected: %0d, Got: %0d",
             $signed(expected_mulh[63:32]), $signed(alu_res_o[31:0]));
    end

  endtask

  logic [63:0] expected_mulhsu;  // 64-bit result of multiplication to compare against upper bits of ALU output


  task automatic MULHSU(
      input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B
  );  // the output of this instruction is neither signed nor unsigned
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_MULHSU;  // set ALU operation to multiplication

    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);

    expected_mulhsu = {{32{A[31]}},A} * {32'b0,B};  // 64-bit result of multiplication to compare against upper bits of ALU output

    $display("MULHSU Upper bits %0d and %0d, got result: %0d", $signed(A), B, alu_res_o[31:0]);

    assert (alu_res_o[31:0] == expected_mulhsu[63:32])
    else begin
      $fatal("MULHSU upper bitresult is incorrect. Expected: %0d, Got: %0d",
             expected_mulhsu[63:32], alu_res_o[31:0]);
    end

  endtask

  logic [63:0] expected_mulhu;

  task automatic MULHU(
      input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B
  );  // the output of this instruction is neither signed nor unsigned
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_MULHU;  // set ALU operation to multiplication

    // wait for output to be reflected in ALU output (2 cycles)
    @(posedge clk_i);

    @(posedge clk_i);

    expected_mulhu = A * B;  // 64-bit result of multiplication to compare against upper bits of ALU output

    $display("MULHU Upper bits %0d and %0d, got result: %0d", A, B, alu_res_o[31:0]);

    assert (alu_res_o[31:0] == expected_mulhu[63:32])
    else begin
      $fatal("MULHU upper bitresult is incorrect. Expected: %0d, Got: %0d", expected_mulhu[63:32],
             alu_res_o[31:0]);
    end

  endtask


  task automatic DIVU(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);

    int stall_cycle_count;
    stall_cycle_count = 0;

    // 1) Make sure previous divide is really finished
    wait (stall_o == 1'b0);

    // 2) Launch new divide
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_DIVU;

    // 3) Prove this divide actually started
    wait (stall_o == 1'b1);

    // 4) Count busy cycles for this divide only
    while (stall_o == 1'b1) begin
      @(posedge clk_i);
    end

    wait (stall_o == 1'b0);

    // 5) Give output mux one cycle to reflect final quotient and remainder after division is done
    @(posedge clk_i);

    $display("DIVU %0d and %0d, got result: %0d after 35 cycles", A, B, alu_res_o);

    assert (alu_res_o == (A / B))
    else begin
      $fatal("DIVU is incorrect. Expected: %0d, Got: %0d", (A / B), alu_res_o);
    end


  endtask


  task automatic DIV(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);

    int stall_cycle_count;
    stall_cycle_count = 0;

    // 1) Make sure previous divide is really finished
    wait (stall_o == 1'b0);

    // 2) Launch new divide
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_DIV;

    // 3) Prove this divide actually started
    wait (stall_o == 1'b1);

    // 4) Count busy cycles for this divide only
    while (stall_o == 1'b1) begin
      @(posedge clk_i);
      stall_cycle_count++;
    end

    // 5) Give output mux one cycle to reflect final quotient and remainder after division is done
    @(posedge clk_i);

    $display("DIV %0d and %0d, got result: %0d after 35 cycles", $signed(A), $signed(B),
             $signed(alu_res_o));

    assert ($signed(alu_res_o) == ($signed(A) / $signed(B)))
    else begin
      $fatal("DIV is incorrect. Expected: %0d, with %0d and %0d Got: %0d", ($signed(A) / $signed(B)
             ), $signed(A), $signed(B), $signed(alu_res_o));
    end

  endtask

  task automatic REMU(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);

    int stall_cycle_count;
    stall_cycle_count = 0;

    // 1) Make sure previous divide is really finished
    wait (stall_o == 1'b0);

    // 2) Launch new divide
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_REMU;

    // 3) Prove this divide actually started
    wait (stall_o == 1'b1);

    // 4) Count busy cycles for this divide only
    while (stall_o == 1'b1) begin
      @(posedge clk_i);
      stall_cycle_count++;
    end

    // 5) Give output mux one cycle to reflect final quotient and remainder after division is done
    @(posedge clk_i);

    $display("REMU %0d and %0d, got result: %0d after 35 cycles", A, B, alu_res_o);

    assert (alu_res_o == (A % B))
    else begin
      $fatal("REMU is incorrect. Expected: %0d, Got: %0d", (A % B), alu_res_o);
    end

  endtask

  task automatic REM(input logic [DATA_WIDTH-1:0] A, input logic [DATA_WIDTH-1:0] B);

    int stall_cycle_count;
    stall_cycle_count = 0;

    // 1) Make sure previous divide is really finished
    wait (stall_o == 1'b0);

    // 2) Launch new divide
    op_a_i = A;
    op_b_i = B;
    ALU_OP = ALU_REMU;

    // 3) Prove this divide actually started
    wait (stall_o == 1'b1);

    // 4) Count busy cycles for this divide only
    while (stall_o == 1'b1) begin
      @(posedge clk_i);
      stall_cycle_count++;
    end

    // 5) Give output mux one cycle to reflect final quotient and remainder after division is done
    @(posedge clk_i);

    $display("REMU %0d and %0d, got result: %0d after 35 cycles", $signed(A), $signed(B),
             $signed(alu_res_o));

    assert ($signed(alu_res_o) == $signed((A) % (B)))
    else begin
      $fatal("REMU is incorrect. Expected: %0d, Got: %0d", $signed(A % B), $signed(alu_res_o));
    end

  endtask

  initial begin
    rst_ni = 1'b0;  // assert reset (active low)
    op_a_i = 32'b0;
    op_b_i = 32'b0;
    ALU_OP = 5'b0;

    repeat (2) @(posedge clk_i);  // wait for 2 clock cycles
    rst_ni = 1'b1;  // deassert reset

    $display("Directed Portion \n");

    $display("-----------------------------------------");

    Add(32'd10, 32'd20);  // Test addition of 10 and 20

    Sub(32'd50, 32'd15);  // Test subtraction of 15 from 50

    SLL(32'd1, 32'd5);  // Test shift left of 1 by 5 positions

    SLT(32'hFFFF_FFFE, 32'hFFFF_FFFF);  // Test set less than for -2 and -1 (should be 1)

    SLT(32'hFFFF_FFFF, 32'hFFFF_FFFE);  // Test set less than for -1 and -2 (should be 0)

    SLTU(32'hFFFF_FFFF, 32'hFFFF_FFFE);  // Test is unsigned, so should be 0

    SLTU(32'hFFFF_FFFE, 32'hFFFF_FFFF);  // Test is unsigned, so should be 1

    XOR(32'd15, 32'd5);  // Test XOR of 15 and 5

    BEQ(32'd100, 32'd100);  // Test branch if equal for equal values (should be taken)

    BGEU(32'hFFFF_FFFF,
         32'hFFFF_FFFE);  // Test branch if greater than or equal unsigned (should be taken)

    MUL(32'd10, 32'd20);  // Test multiplication of 10 and 20 will retur lower XLEN bits of result

    MULH(32'd10, 32'd20);  // Test multiplication of 10 and 20 will return upper XLEN bits of result

    MULH(32'hFFFF_FFFF, 32'd2);  // -1 * 2      => high should be 32'hFFFF_FFFF
    MULH(32'hFFFF_FFFF, 32'hFFFF_FFFF);  // -1 * -1     => high should be 32'h0000_0000
    MULH(32'h8000_0000, 32'd2);  // -2147483648 * 2
    MULH(32'h8000_0000, 32'hFFFF_FFFF);  // minint * -1

    MULHSU(32'hFFFF_FFFF, 32'd2);  // -1 * 2  
    MULHSU(32'hFFFF_FFFF, 32'hFFFF_FFFF);  // -1 * -1

    MULHU(32'hFFFF_FFFF, 32'd2);  // 4294967295 * 2

    DIVU(32'd100, 32'd5);

    DIVU(32'd10, 32'd2);  // Test unsigned division of 10 by 2


    DIV(32'hFFFF_FFFF,
        32'hFFFF_FFFF);  // Test signed division of -1 by 0 (should return 0xFFFF_FFFF)


    DIV(32'hFFFF_FFFF,
        32'hFFFF_FFFF);  // Test signed division of -1 by 0 (should return 0xFFFF_FFFF)

    REMU(32'd100, 32'd7);  // Test unsigned remainder of 100 by 7

    REM(32'hFFFF_FFFF, 32'hFFFF_FFFE);  // Test signed remainder of -1 by -2 (should return 1)




    $display("-----------------------------------------");

    $display("Randomized Portion \n");

    for (integer i = 0; i < 100; i++) begin
      op_a_i = $urandom;
      op_b_i = $urandom;

      Add(op_a_i, op_b_i);
      Sub(op_a_i, op_b_i);
      SLL(op_a_i, op_b_i[4:0]);  // only use lower 5 bits for shift amount
      SLT(op_a_i, op_b_i);
      SLTU(op_a_i, op_b_i);
      XOR(op_a_i, op_b_i);
      BEQ(op_a_i, op_b_i);
      BNE(op_a_i, op_b_i);
      BLT(op_a_i, op_b_i);
      BLTU(op_a_i, op_b_i);
      BGE(op_a_i, op_b_i);
      BGEU(op_a_i, op_b_i);
      MUL(op_a_i, op_b_i);
      MULH(op_a_i, op_b_i);
      MULHSU(op_a_i, op_b_i);
      MULHU(op_a_i, op_b_i);  // 4294967295 * 2
      DIVU(op_a_i, op_b_i);
      DIV(op_a_i, op_b_i);
      REMU(op_a_i, op_b_i);
      REM(op_a_i, op_b_i);



    end


    $finish;

  end




endmodule
