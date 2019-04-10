/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Scoreboard.v
//
// Function: 
//				Tracking the evaluation status of each cell
//
// Data Organization:
//				
//
// Used by:
//				Summation_Logic.v
//
// Dependency:
//				N/A
//
// Testbench:
//				_tb.v
//
// Timing:
//				TBD
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Scoreboard
#(
	parameter NUM_TOTAL_CELL 				= 125
)
(
	input clk,
	input rst,
	input [251:0] cell_done,
	output [251:0] ready_to_sum
);
 
    reg [28*252-1:0] scoreboard_track;
    genvar i;
    generate
        for(i=0; i < 252; i=i+1) begin:track_entry
            always@(posedge clk)
                begin
                if(rst)
                    scoreboard_track[(i+1)*28-1:i*28] <= {1'b1,27'd0};
                else if (scoreboard_track[i*28] == 1)
                    scoreboard_track[(i+1)*28-1:i*28] <= {1'b1,27'd0};
                else if(cell_done[i] == 1'b1)
                    scoreboard_track[(i+1)*28-1:i*28] <= {scoreboard_track[i*28],scoreboard_track[(i+1)*28-1:i*28+1]};
                else
                    scoreboard_track[(i+1)*28-1:i*28] <= scoreboard_track[(i+1)*28-1:i*28];
                end
        end
    endgenerate
    
    assign ready_to_sum = {scoreboard_track[7028],scoreboard_track[7000],scoreboard_track[6972],scoreboard_track[6944],scoreboard_track[6916],scoreboard_track[6888],scoreboard_track[6860],scoreboard_track[6832],scoreboard_track[6804],scoreboard_track[6776],scoreboard_track[6748],scoreboard_track[6720],scoreboard_track[6692],scoreboard_track[6664],scoreboard_track[6636],scoreboard_track[6608],scoreboard_track[6580],scoreboard_track[6552],scoreboard_track[6524],scoreboard_track[6496],scoreboard_track[6468],scoreboard_track[6440],scoreboard_track[6412],scoreboard_track[6384],scoreboard_track[6356],scoreboard_track[6328],scoreboard_track[6300],scoreboard_track[6272],scoreboard_track[6244],scoreboard_track[6216],scoreboard_track[6188],scoreboard_track[6160],scoreboard_track[6132],scoreboard_track[6104],scoreboard_track[6076],scoreboard_track[6048],scoreboard_track[6020],scoreboard_track[5992],scoreboard_track[5964],scoreboard_track[5936],scoreboard_track[5908],scoreboard_track[5880],scoreboard_track[5852],scoreboard_track[5824],scoreboard_track[5796],scoreboard_track[5768],scoreboard_track[5740],scoreboard_track[5712],scoreboard_track[5684],scoreboard_track[5656],scoreboard_track[5628],scoreboard_track[5600],scoreboard_track[5572],scoreboard_track[5544],scoreboard_track[5516],scoreboard_track[5488],scoreboard_track[5460],scoreboard_track[5432],scoreboard_track[5404],scoreboard_track[5376],scoreboard_track[5348],scoreboard_track[5320],scoreboard_track[5292],scoreboard_track[5264],scoreboard_track[5236],scoreboard_track[5208],scoreboard_track[5180],scoreboard_track[5152],scoreboard_track[5124],scoreboard_track[5096],scoreboard_track[5068],scoreboard_track[5040],scoreboard_track[5012],scoreboard_track[4984],scoreboard_track[4956],scoreboard_track[4928],scoreboard_track[4900],scoreboard_track[4872],scoreboard_track[4844],scoreboard_track[4816],scoreboard_track[4788],scoreboard_track[4760],scoreboard_track[4732],scoreboard_track[4704],scoreboard_track[4676],scoreboard_track[4648],scoreboard_track[4620],scoreboard_track[4592],scoreboard_track[4564],scoreboard_track[4536],scoreboard_track[4508],scoreboard_track[4480],scoreboard_track[4452],scoreboard_track[4424],scoreboard_track[4396],scoreboard_track[4368],scoreboard_track[4340],scoreboard_track[4312],scoreboard_track[4284],scoreboard_track[4256],scoreboard_track[4228],scoreboard_track[4200],scoreboard_track[4172],scoreboard_track[4144],scoreboard_track[4116],scoreboard_track[4088],scoreboard_track[4060],scoreboard_track[4032],scoreboard_track[4004],scoreboard_track[3976],scoreboard_track[3948],scoreboard_track[3920],scoreboard_track[3892],scoreboard_track[3864],scoreboard_track[3836],scoreboard_track[3808],scoreboard_track[3780],scoreboard_track[3752],scoreboard_track[3724],scoreboard_track[3696],scoreboard_track[3668],scoreboard_track[3640],scoreboard_track[3612],scoreboard_track[3584],scoreboard_track[3556],scoreboard_track[3528],scoreboard_track[3500],scoreboard_track[3472],scoreboard_track[3444],scoreboard_track[3416],scoreboard_track[3388],scoreboard_track[3360],scoreboard_track[3332],scoreboard_track[3304],scoreboard_track[3276],scoreboard_track[3248],scoreboard_track[3220],scoreboard_track[3192],scoreboard_track[3164],scoreboard_track[3136],scoreboard_track[3108],scoreboard_track[3080],scoreboard_track[3052],scoreboard_track[3024],scoreboard_track[2996],scoreboard_track[2968],scoreboard_track[2940],scoreboard_track[2912],scoreboard_track[2884],scoreboard_track[2856],scoreboard_track[2828],scoreboard_track[2800],scoreboard_track[2772],scoreboard_track[2744],scoreboard_track[2716],scoreboard_track[2688],scoreboard_track[2660],scoreboard_track[2632],scoreboard_track[2604],scoreboard_track[2576],scoreboard_track[2548],scoreboard_track[2520],scoreboard_track[2492],scoreboard_track[2464],scoreboard_track[2436],scoreboard_track[2408],scoreboard_track[2380],scoreboard_track[2352],scoreboard_track[2324],scoreboard_track[2296],scoreboard_track[2268],scoreboard_track[2240],scoreboard_track[2212],scoreboard_track[2184],scoreboard_track[2156],scoreboard_track[2128],scoreboard_track[2100],scoreboard_track[2072],scoreboard_track[2044],scoreboard_track[2016],scoreboard_track[1988],scoreboard_track[1960],scoreboard_track[1932],scoreboard_track[1904],scoreboard_track[1876],scoreboard_track[1848],scoreboard_track[1820],scoreboard_track[1792],scoreboard_track[1764],scoreboard_track[1736],scoreboard_track[1708],scoreboard_track[1680],scoreboard_track[1652],scoreboard_track[1624],scoreboard_track[1596],scoreboard_track[1568],scoreboard_track[1540],scoreboard_track[1512],scoreboard_track[1484],scoreboard_track[1456],scoreboard_track[1428],scoreboard_track[1400],scoreboard_track[1372],scoreboard_track[1344],scoreboard_track[1316],scoreboard_track[1288],scoreboard_track[1260],scoreboard_track[1232],scoreboard_track[1204],scoreboard_track[1176],scoreboard_track[1148],scoreboard_track[1120],scoreboard_track[1092],scoreboard_track[1064],scoreboard_track[1036],scoreboard_track[1008],scoreboard_track[980],scoreboard_track[952],scoreboard_track[924],scoreboard_track[896],scoreboard_track[868],scoreboard_track[840],scoreboard_track[812],scoreboard_track[784],scoreboard_track[756],scoreboard_track[728],scoreboard_track[700],scoreboard_track[672],scoreboard_track[644],scoreboard_track[616],scoreboard_track[588],scoreboard_track[560],scoreboard_track[532],scoreboard_track[504],scoreboard_track[476],scoreboard_track[448],scoreboard_track[420],scoreboard_track[392],scoreboard_track[364],scoreboard_track[336],scoreboard_track[308],scoreboard_track[280],scoreboard_track[252],scoreboard_track[224],scoreboard_track[196],scoreboard_track[168],scoreboard_track[140],scoreboard_track[112],scoreboard_track[84],scoreboard_track[56],scoreboard_track[28],scoreboard_track[0]};

endmodule
