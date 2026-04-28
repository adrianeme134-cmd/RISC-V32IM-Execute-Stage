`timescale 1ns / 1ps

module division_tb;

  logic clk_i;
  logic rst_ni;
  logic Division_START;
  logic stall_o;
  logic [31:0] dividend;  // numerator
  logic [31:0] divisor;  // denominator
  logic [31:0] remainder;  //result
  logic [31:0] quotient;  // result


  division dut (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .Division_START(Division_START),
      .dividend(dividend),
      .divisor(divisor),
      .remainder(remainder),
      .stall_o(stall_o),
      .quotient(quotient)
  );

  integer file;  // file handler for reading test vectors from file
  integer scan_status;  // number of values successfully read by $fscanf
  logic [31:0] file_dividend;
  logic [31:0] file_divisor;
  logic [31:0] expected_quotient;
  logic [31:0] expected_remainder;
  string header;

  integer total_tests_passed = 0;  // counter for total tests completed
  integer total_tests_failed = 0;  // counter for total tests in file

  always #5
    clk_i = ~clk_i; // start clock with a period of 10 time units (5 time units high, 5 time units low)

  initial begin
    clk_i = 1'b0;  // initialize clock to 0
    rst_ni = 1'b0;  // assert reset (active low)
    Division_START = 1'b0;  // initialize Division_START to 0
    dividend = 32'b0;  // initialize dividend to 0
    divisor = 32'b0;  // initialize divisor to 0


    repeat (2) @(posedge clk_i);  // wait for 2 clock cycles
    rst_ni = 1'b1;  // deassert reset

    @(posedge clk_i);  // wait for one clock cycle after deasserting reset

    file = $fopen("division_vectors.txt", "r");  // open file and read

    if (file == 0) begin  // if file returns 0, error has occured
      $display("could not open file");
      $finish;
    end

    header = $fgets(header, file);  // skip header line

    while ($feof(
        file
    ) == 0) begin  // while not at the end of file (1 means end of file), (0 means there is still data to read)
      scan_status = $fscanf(file, "%h %h %h %h\n", file_dividend,
                            file_divisor, expected_quotient, expected_remainder)
          ;  // read in hex values for dividend, divisor, expected quotient, and expected remainder

      if (scan_status != 4) begin  // scan_status has to read 4 hex numbers else error
        $display("error reading file");
        $finish;
      end

      // Driving DUT inputs with values read from file and start division operation

      dividend = file_dividend;
      divisor = file_divisor;

      // start division operation by asserting Division_START for one clock cycle
      Division_START = 1'b1;

      @(posedge clk_i);
      @(posedge clk_i);

      Division_START = 1'b0;

      @(posedge clk_i);

      // wait until division is done by monitoring stall_o signal from DUT, then check if quotient and remainder match expected values read from file

      wait (stall_o == 1'b0);  // wait until division is done

      //checking logic, check if quotient and remainder match expected values read from file
      if (quotient !== expected_quotient || remainder !== expected_remainder) begin
        $display(
            "Test failed for dividend: %h divisor: %h. Expected quotient: %h, got: %h. Expected remainder: %h, got: %h",
            file_dividend, file_divisor, expected_quotient, quotient, expected_remainder,
            remainder);
        total_tests_failed = total_tests_failed + 1;  // increment failed tests counter
      end else begin
        $display("Test passed for dividend: %h divisor: %h. Quotient: %h. Remainder: %h",
                 file_dividend, file_divisor, quotient, remainder);
        total_tests_passed = total_tests_passed + 1;  // increment passed tests counter
      end

    end

    $display("total tests successfully completed: %d", total_tests_passed);
    $display("total tests failed: %d", total_tests_failed);

    $fclose(file);  // close file after reading all test vectors
    $finish;

  end




endmodule
