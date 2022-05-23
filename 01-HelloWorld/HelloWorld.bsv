package HelloWorld;
    String s = "Hello world";

    (* synthesize *)
    module mkHelloModule(Empty);

        Reg#(Bit#(32))cnt <- mkReg(0);
        Reg#(Bit#(32)) target <- mkReg(10);

        rule print_hello_world(cnt < target);
            $display(s);
            cnt <= cnt + 1;
        endrule

        rule stop_hello(cnt == target);
            $finish(0);
        endrule
    endmodule
endpackage
