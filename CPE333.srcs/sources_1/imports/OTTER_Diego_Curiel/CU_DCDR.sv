`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Ratner Surf Designs
// Engineer: James Ratner
// 
// Create Date: 01/29/2019 04:56:13 PM
// Design Name: 
// Module Name: CU_Decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies:
//
// 
// Revision:
// Revision 1.00 - File Created (02-01-2020) - from Paul, Joseph, & Celina
//          1.01 - (02-08-2020) - removed unneeded else's; fixed assignments
//          1.02 - (02-25-2020) - made all assignments blocking
//          1.03 - (05-12-2020) - reduced func7 to one bit
//          1.04 - (05-31-2020) - removed misleading code
//          1.05 - (05-01-2023) - reindent and fix formatting
// Additional Comments:
// 
///////////////////////////////////////////////////////////////////////////

module CU_DCDR(
    input br_eq, 
    input br_lt, 
    input br_ltu,
    input [6:0] opcode,   //-  ir[6:0]
    input func7,          //-  ir[30]
    input [2:0] func3,    //-  ir[14:12] 
    input INT_TAKEN,
    output logic [3:0] alu_fun,
    output logic [2:0] pcSource,
    output logic [1:0] alu_srcA,
    output logic [2:0] alu_srcB, 
    output logic [1:0] rf_wr_sel,   
    output logic pcWrite,
    output logic regWrite,
    output logic memWE2,
    output logic memRDEN1,
    output logic memRDEN2
    );
    
    //- datatypes for RISC-V opcode types
    typedef enum logic [6:0] {
        LUI    = 7'b0110111,
        AUIPC  = 7'b0010111,
        JAL    = 7'b1101111,
        JALR   = 7'b1100111,
        BRANCH = 7'b1100011,
        LOAD   = 7'b0000011,
        STORE  = 7'b0100011,
        OP_IMM = 7'b0010011,
        OP_RG3 = 7'b0110011,
        SYS    = 7'b1110011
    } opcode_t;
    opcode_t OPCODE; //- define variable of new opcode type
    
    assign OPCODE = opcode_t'(opcode); //- Cast input enum 

    //- datatype for func3Symbols tied to values
    typedef enum logic [2:0] {
        //BRANCH labels
        BEQ = 3'b000,
        BNE = 3'b001,
        BLT = 3'b100,
        BGE = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
    } func3_t;    
    func3_t FUNC3; //- define variable of new opcode type
    
    assign FUNC3 = func3_t'(func3); //- Cast input enum 
    
    
       
    always_comb begin 
        //- schedule all values to avoid latch
        pcSource = 3'b000;  alu_srcB = 2'b00;    rf_wr_sel = 2'b00; 
        alu_srcA = 1'b0; alu_fun = 4'b0000; pcWrite = 1'b0; regWrite = 1'b0;
        memWE2 = 1'b0;     memRDEN1 = 1'b0;    memRDEN2 = 1'b0;
        
        if (INT_TAKEN == 1'b1)
            pcSource = 3'b100;
        else
    
            case(OPCODE)  
                LUI: begin
                    regWrite = 1'b1;
                    alu_fun = 4'b1001; 
                    alu_srcA = 1'b1; 
                    alu_srcB = 2'b00;
                    rf_wr_sel = 2'b11;
                    pcSource = 2'b00; 
                end
                
                AUIPC: begin
                    regWrite = 1'b1;    //write address to rd  
                    alu_fun = 4'b0000;
                    alu_srcA = 1'b1;
                    alu_srcB = 2'b11;
                    rf_wr_sel = 2'b11;
                end
                
                JAL: begin
                    regWrite = 1'b1;     //cells interLINKed
                    alu_fun = 4'b0000;
                    alu_srcA = 1'b0;
                    alu_srcB = 2'b00;
                    rf_wr_sel = 2'b00;
                    pcSource = 2'b11;
                end
                
                JALR: begin
                    regWrite = 1'b1;      //link up
                    alu_fun = 4'b0000;
                    alu_srcA = 1'b0;
                    alu_srcB = 2'b00;
                    rf_wr_sel = 2'b00;
                    pcSource = 2'b01;
                end
    
    
                LOAD: begin
                    regWrite = 1'b1;       
                    pcWrite = 1'b0;
                    memRDEN2 = 1'b1; 
                    alu_fun = 4'b0000; 
                    alu_srcA = 1'b0; 
                    alu_srcB = 2'b01; 
                    rf_wr_sel = 2'b10; 
                    pcSource = 2'b00;
                end
                
               BRANCH: begin   	
                    regWrite = 1'b0;    //non operate
                    rf_wr_sel = 2'b00;
                    pcSource = 2'b00;
                    case(FUNC3)
                       BEQ: begin
                           if (br_eq == 1'b1)
                               pcSource = 2'b10;
                            end   
                       BNE: begin
                           if (br_eq == 1'b0)
                               pcSource = 2'b10;
                            end 
                       BLT: begin
                           if (br_lt == 1'b1)
                               pcSource = 2'b10;
                            end
                       BGE: begin
                           if (br_lt == 1'b0)
                               pcSource = 2'b10;
                            end
                       BLTU: begin
                           if (br_ltu == 1'b1)
                               pcSource = 2'b10;
                            end
                       BGEU: begin
                           if (br_ltu == 1'b0)
                               pcSource = 2'b10;
                            end
                       default: begin
                            alu_fun = 4'b0000;
                            alu_srcA = 1'b0; 
                            alu_srcB = 2'b01;
                            rf_wr_sel = 2'b11; 
                            pcSource = 2'b00; 
                        end           
                    endcase
                end
             
                STORE: begin;
                    regWrite = 1'b0;       //store, no reg writing happening
                    memWE2 = 1'b1;         //store, YES mem writing
                    alu_fun = 4'b0000;
                    alu_srcA = 1'b0;
                    alu_srcB = 2'b10;
                    pcSource = 2'b00;
                    end
                
                OP_IMM: begin
                    regWrite = 1'b1;
                    alu_fun = 4'b0000;
                    alu_srcA = 1'b0; 
                    alu_srcB = 2'b01;
                    rf_wr_sel = 2'b11; 
                    pcSource = 2'b00;
                    case(FUNC3)
                        3'b000: begin   // instr: ADDI
                            alu_fun = 4'b0000;
                        end
                        
                        3'b010: begin   //SLTI
                            alu_fun = 4'b0010;
                        end
                        
                        3'b011:begin    //SLTIU
                            alu_fun = 4'b0011;
                        end
                        
                        3'b110:begin    //ORI
                            alu_fun = 4'b0110;
                        end
                        
                        3'b100:begin    //XORI
                            alu_fun = 4'b0100;
                        end
                        
                        3'b111:begin    //ANDI
                            alu_fun = 4'b0111;
                        end
                        
                        3'b001:begin    //SLLI
                            alu_fun = 4'b0001;
                        end
                        
                        3'b101:begin  
                            case(func7)
                            1'b0:begin  //SRLI
                                alu_fun = 0101;
                                end
                            1'b1:begin  //SRAI
                                alu_fun = 1101;
                                end
                            endcase
                        end
                        
                        default: begin
                            alu_fun = 4'b0000;
                            alu_srcA = 1'b0; 
                            alu_srcB = 2'b01;
                            rf_wr_sel = 2'b11; 
                            pcSource = 2'b00; 
                        end
                    endcase
                end
                
                OP_RG3: begin
                regWrite = 1'b1;
                alu_fun = 4'b0000;
                alu_srcA = 1'b0;
                alu_srcB = 2'b00;
                rf_wr_sel = 2'b11;
                pcSource = 2'b00;
                    case(FUNC3)
                       3'b000: begin
                       case(func7)
                            1'b0:begin
                                alu_fun = 4'b0000;  // instr: ADD
                            end
                            1'b1:begin
                                alu_fun = 4'b1000;  //SUB
                                end
                        endcase        
                        end
                        
                        3'b001:begin    //SLL
                            alu_fun = 0001;
                            end
                        3'b010: begin   //SLT
                            alu_fun = 4'b0011;
                        end
                        
                        3'b011:begin    //SLTU: how to differentiate from slt?
                            alu_fun = 4'b0010;
                        end
                        
                        3'b110:begin    //OR
                            alu_fun = 4'b0110;
                        end
                        
                        3'b100:begin    //XOR
                            alu_fun = 4'b0100;
                        end
                        
                        3'b111:begin    //AND
                            alu_fun = 4'b0111;
                        end
                        
                        3'b101:begin  
                            case(func7)
                            1'b0:begin  //SRL
                                alu_fun = 0101;
                                end
                            1'b1:begin  //SRA
                                alu_fun = 1101;
                                end
                            endcase
                        end
                        
                        default: begin
                            alu_fun = 4'b0000;
                            alu_srcA = 1'b0;
                            alu_srcB = 2'b00;
                            rf_wr_sel = 2'b11;
                            pcSource = 2'b00;
                        end
                    endcase
                end	
                
                default: begin
                     pcWrite = 1'b0; //will change once hazards enabled
                     pcSource = 2'b00; 
                     alu_srcB = 2'b00; 
                     rf_wr_sel = 2'b00; 
                     alu_srcA = 1'b0; 
                     alu_fun = 4'b0000;
                     regWrite = 1'b0;
                     memWE2 = 1'b0;
                     memRDEN1 = 1'b0;
                     memRDEN2 = 1'b0;
                end
            endcase
        end
    
endmodule