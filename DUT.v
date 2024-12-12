
module turbo_encoder
(	input 	clk	   ,
	input	rst	   ,
	input	ack	   ,
	input	mode	   ,
	input	in_MSD_CRC ,

	output	out_TE_data 
);


wire  [1147:0]  MSD_CRC ;
wire  [2:0]	PTAIL_1	;
wire  [2:0]	TAIL_1	;
wire  [1147:0]	PARITY_1;
wire  [2:0]	PTAIL_2	;
wire  [2:0]	TAIL_2	;
wire  [1147:0]	PARITY_2;


read_MSD_input read_MSD_input_i(
               .clk	   	(clk	   	),  // I
               .rst	   	(rst	   	),  // I
               .ack	   	(ack	   	),  // I
               .in_MSD_CRC	(in_MSD_CRC	),  // I
                                                         
               .done	   	(done_rd_MSD 	),  // O
               .MSD_CRC   	(MSD_CRC   	)   // O
);

process_parity1 process_parity1_i(
               .clk		(clk		),  // I
               .rst		(rst		),  // I
               .mode		(mode		),  // I
               .done_rd_MSD	(done_rd_MSD	),  // I
               .MSD_CRC		(MSD_CRC	),  // I
               .ack		(ack		),  // I
               .in_MSD_CRC 	(in_MSD_CRC 	),  // I
                                                        
               .done_p1		(done_p1	),  // O
               .PTAIL_1		(PTAIL_1	),  // O
               .TAIL_1		(TAIL_1		),  // O
               .PARITY_1	(PARITY_1	)   // O
);

process_parity2 process_parity2_i(
               .clk		(clk		),  // I
               .rst		(rst		),  // I
               .mode		(mode		),  // I
               .done_p1		(done_p1	),  // I
               .MSD_CRC		(MSD_CRC	),  // I
               .ack		(ack		),  // I
               .in_MSD_CRC 	(in_MSD_CRC 	),  // I
                                                        
               .done_p2		(done_p2	),  // O
               .PTAIL_2		(PTAIL_2	),  // O
               .TAIL_2		(TAIL_2		),  // O
               .PARITY_2	(PARITY_2	)   // O
);

generate_output generate_output_i(
               .clk		(clk		),  // I
               .rst		(rst		),  // I
                                                 
               .done_rd_MSD	(done_rd_MSD	),  // I
               .MSD_CRC		(MSD_CRC	),  // I
                                                 
               .done_p1		(done_p1	),  // I
               .TAIL_1		(TAIL_1		),  // I
               .PTAIL_1		(PTAIL_1	),  // I
               .PARITY_1	(PARITY_1	),  // I
                                                 
               .done_p2		(done_p2	),  // I
               .TAIL_2		(TAIL_2		),  // I
               .PTAIL_2		(PTAIL_2	),  // I
               .PARITY_2	(PARITY_2	),  // I
                                                 
               .out_TE_data	(out_TE_data	)   // O
);





endmodule

// reading MSD and CRC data from serial input
module read_MSD_input(
	input		clk	   ,
	input		rst	   ,
	input		ack	   ,
	input		in_MSD_CRC ,

	output		done	   ,
	output [1147:0]	MSD_CRC
);


 reg [1147:0] 	MSD_CRC_shift;
 reg [10:0]  	shift_cnt;

 // generating done pulse and bulding MSD_CRC data
 assign MSD_CRC	=  MSD_CRC_shift ;
 assign done	=  (shift_cnt == 1148) ;

 // collecting inputs bit by bit through shift regisers
 always @(posedge clk or posedge rst)
  begin
     if (rst)
	MSD_CRC_shift <= 1148'd0 ;
     else if( ack || (shift_cnt < 1148 ) )
	MSD_CRC_shift <= {MSD_CRC_shift[1146:0],in_MSD_CRC} ;
  end

 // making count of every shift 
 always @(posedge clk or posedge rst)
  begin
     if (rst)
	shift_cnt  <= 11'd0;
     else if ( ack )
	shift_cnt  <= 11'd1;
     else if (shift_cnt != 0 && shift_cnt <= 1148 )
	shift_cnt  <= shift_cnt + 1 ;
  end

endmodule


module process_parity1(
	input		clk	,
	input		rst	,
	input		mode	,
	input		done_rd_MSD	,
	input [1147:0]	MSD_CRC	,
	input		ack	,
	input		in_MSD_CRC ,
		
	output		done_p1	,
	output [2:0]	PTAIL_1	,
	output [2:0]	TAIL_1	,
	output [1147:0]	PARITY_1
);

 reg [10:0]	shift_cnt;
 reg [2:0]	parity1_shift_reg;
 reg [1147:0]	parity1_reg;
 reg [2:0]	ptail;
 reg [2:0]	tail ;
 wire		start_shift;
 wire 		in;

 // mode 1:parallel 0: serial
 assign start_shift 	= mode ? ack : done_rd_MSD ;
 assign done_p1		= (shift_cnt == 1151);
 assign PTAIL_1		= ptail;
 assign TAIL_1		= tail ;
 assign PARITY_1	= parity1_reg;
 assign in 		= mode 		    ? in_MSD_CRC 	:
			  done_rd_MSD 	    ? MSD_CRC[0] 	:
			  (shift_cnt < 1148)? MSD_CRC[shift_cnt]: parity1_shift_reg[2] ;
 
 always @(posedge clk or posedge rst)
  begin
     if (rst)
	parity1_shift_reg <= 3'd0;
     else 
	parity1_shift_reg <= {parity1_shift_reg[1],parity1_shift_reg[0],(parity1_shift_reg[2]^parity1_shift_reg[1]^ in) }; 
  end


 always @(posedge clk or posedge rst)
  begin
     if (rst)
	parity1_reg <= 1148'd0;
     else if( shift_cnt < 1148 )
	parity1_reg <= {parity1_reg[1146:0],(parity1_shift_reg[2]^parity1_shift_reg[1]^parity1_shift_reg[0]^in)};
  end

 always @(posedge clk or posedge rst)
  begin
     if (rst) begin
	ptail <= 3'd0;
	tail  <= 3'd0;
      end
     else if( shift_cnt >= 1148 && shift_cnt < 1151 ) begin
	ptail <= {ptail[1:0],(parity1_shift_reg[2]^parity1_shift_reg[1]^parity1_shift_reg[0]^in)};
	tail  <= {tail[1:0],in};
      end
  end


 // making count of every shift 
 always @(posedge clk or posedge rst)
  begin
     if (rst)
	shift_cnt  <= 11'd0;
     else if (start_shift)
	shift_cnt  <= 11'd1;
     else if (shift_cnt != 0 && shift_cnt <= (1148 + 3) )
	shift_cnt  <= shift_cnt + 1 ;
  end

endmodule



module process_parity2(
	input		clk	,
	input		rst	,
	input		mode	,
	input		done_p1	,
	input [1147:0]	MSD_CRC	,
	input		ack	,
	input		in_MSD_CRC ,
		
	output		done_p2	,
	output [2:0]	TAIL_2	,
	output [2:0]	PTAIL_2	,
	output [1147:0]	PARITY_2
);



 reg [10:0]	shift_cnt;
 reg [2:0]	parity2_shift_reg;
 reg [1147:0]	parity2_reg;
 reg [2:0]	ptail;
 reg [2:0]	tail ;
 wire		start_shift;
 wire 		in;
 reg [3:0]	in_shift;
 wire		interleaver_out;
 wire		g1_D;
 wire		g0_D;
 wire		G_D;

 // mode 1:parallel 0: serial
 assign start_shift 	= mode ? ack : done_p1 ;
 assign done_p2		= (shift_cnt == 1151);
 assign PTAIL_2		= ptail;
 assign TAIL_2		= tail ;
 assign PARITY_2	= parity2_reg;
 assign in 		= mode 		    ? !in_MSD_CRC 	:
			  done_p1 	    ? !MSD_CRC[0] 	:
			  (shift_cnt < 1148)? !MSD_CRC[shift_cnt]: parity2_shift_reg[2] ;
 
// parity 2 is generated from interleaver output
// interleaver implementation
// G(D) = (1 ^ g1(D)) && ( 0 ^ g0(D))//g1(D) && g0(D).... g1(D) || g0(D)...g1(D) ^ g0(D)
// g0(D) = 1+D+(D)^3
// g1(D) = 1+(D)^2+(D)^3

 always @(posedge clk or posedge rst)
  begin
     if (rst)
	in_shift  <= 4'b0;
     else 
	in_shift  <= {in_shift[2:0],in};
  end

 assign g0_D = (in_shift[0] ^ in_shift[1] ^ in_shift[3]);
 assign g1_D = (in_shift[0] ^ in_shift[2] ^ in_shift[3]);
 assign G_D  = ( (1 ^ g1_D) && ( 0 ^ g0_D) );
 assign interleaver_out = G_D;

 always @(posedge clk or posedge rst)
  begin
     if (rst)
	parity2_shift_reg <= 3'd0;
     else if (shift_cnt <= 1151)
	parity2_shift_reg <= {parity2_shift_reg[1],parity2_shift_reg[0],(parity2_shift_reg[2]^parity2_shift_reg[1]^ interleaver_out) }; 
  end


 always @(posedge clk or posedge rst)
  begin
     if (rst)
	parity2_reg <= 1148'd0;
     else if( shift_cnt < 1148 )
	parity2_reg <= {parity2_reg[1146:0],(parity2_shift_reg[2]^parity2_shift_reg[1]^parity2_shift_reg[0]^interleaver_out)};
  end

 always @(posedge clk or posedge rst)
  begin
     if (rst) begin
	ptail <= 3'd0;
	tail  <= 3'd0;
      end
     else if( shift_cnt >= 1148 && shift_cnt < 1151 ) begin
	ptail <= {ptail[1:0],(parity2_shift_reg[2]^parity2_shift_reg[1]^parity2_shift_reg[0]^interleaver_out)};
	tail  <= {tail[1:0],interleaver_out};
      end
  end


 // making count of every shift 
 always @(posedge clk or posedge rst)
  begin
     if (rst)
	shift_cnt  <= 11'd0;
     else if (start_shift)
	shift_cnt  <= 11'd1;
     else if (shift_cnt != 0 && shift_cnt <= (1148 + 3) )
	shift_cnt  <= shift_cnt + 1 ;
  end

endmodule

module generate_output(
	input		clk		,
	input		rst		,

	input		done_rd_MSD	,
	input [1147:0]	MSD_CRC	,

	input		done_p1	,
	input [2:0]	TAIL_1	,
	input [2:0]	PTAIL_1	,
	input [1147:0]	PARITY_1,

	input		done_p2	,
	input [2:0]	TAIL_2	,
	input [2:0]	PTAIL_2	,
	input [1147:0]	PARITY_2,

	output	reg	out_TE_data 
);


reg [3455:0] out_data;
reg [12:0]   shift_cnt;


// aligning the output to send on serial lane
// output data is aligned in the following format
// MSB--------------------------------------------------------------->LSB
// 3455     3452       2304     2301     1153     1150    1147       0
//   | ptail2 | parity2 | ptail1 | parity1 | tail2 | tail1 | MSD_CRC |
//
//  LSB data will be sent to output. 
//  So, the data is stored in reverse compared to paper

 always@ (posedge clk or posedge rst)
  begin
     if (rst)
	out_data <= 3456'd0 ;
     else
      begin
       if(done_rd_MSD)
	  out_data[1147:0]    <= MSD_CRC ;
       if(done_p1) begin
	  out_data[1150:1148] <= TAIL_1 ;
	  out_data[2304:1154] <= {PTAIL_1,PARITY_1} ;
	 end
       if(done_p2) begin
	  out_data[1153:1151] <= TAIL_2 ;
	  out_data[3455:2305] <= {PTAIL_2,PARITY_2} ;
	 end
      end
  end

 // making count of every shift 
 always @(posedge clk or posedge rst)
  begin
     if (rst)
	shift_cnt  <= 13'd0;
     else if (done_p2)
	shift_cnt  <= 13'd1;
     else if (shift_cnt != 0 && shift_cnt <= 3456 )
	shift_cnt  <= shift_cnt + 1 ;
  end

  // generating output data serially from the alogned data
 always@ (posedge clk or posedge rst)
  begin
    if (rst)
	out_TE_data  <= 1'b0;
    else if(done_p2)
	out_TE_data  <= out_data[0];
    else if(shift_cnt != 0 && shift_cnt < 3456 )
	out_TE_data  <= out_data[shift_cnt];
    else
	out_TE_data  <= 1'b0;
  end

endmodule






