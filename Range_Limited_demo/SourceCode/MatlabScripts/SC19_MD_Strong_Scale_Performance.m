%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MD Strong Scaling Timing Performance Estimation
%% Details for timing model
%% https://docs.google.com/document/d/1MNGsC3C9-nVRd5HxwxyHuNHx4kufWhdzJenuUDJ4ns0/edit
%%
%% Todo:
%%      1, The cases when there are multiple nodes working on same cell, need to rework the communication pattern
%% By: Chen Yang
%% 01/02/2019
%% Boston University, CAAD Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
clf;
close all;

%% Dataset Parameters
% Simulation Timestep (fs)
SIMULATION_TIMESTEP = 2;
% Long range update frequency (0.5 means update every other iteration)
LONG_RANGE_UPDATE_FREQUENCY = 0.5; 
% Short range evaluation overhead
% The current model assumes 100% pipeline efficiency, but in reality there are cycles pipelines has no valid input, thus introduce this overhead index
SHORT_RANGE_EVAL_OVERHEAD_INDEX = 1.5;
% Maximum Particles per node
% When there are more than this number of particles is assigned on a single node, set the performance number as 0 since we cannot map this many onto a single Stratix 10 FPGA
MAX_PARTICLE_PER_NODE = 10e7;
% Particle number
%PARTICLE_NUM = [5e3,1e4,2e4,5e4,1e5,2e5,5e5,1e6,2e6,5e6,1e7];
PARTICLE_NUM = [1e4,2e4,4e4,8e4];
% Nodes number
%NODES_NUM = [1,4,8,16,32,64,256,1024,4096];
NODES_NUM = [1,2,4,8,16,32,64];
% Particles per cell
PARTICLES_PER_CELL = 80;
%% Assign Long range nodes
%LONG_RANGE_NODES = ceil(NODES_NUM ./ 2);
LONG_RANGE_NODES = zeros(1,length(NODES_NUM));
for i = 1:length(NODES_NUM)
%     if NODES_NUM(i) > 4
%         LONG_RANGE_NODES(i) = ceil(NODES_NUM(i) / 2);
%     elseif NODES_NUM(i) == 1
%         LONG_RANGE_NODES(i) = 1;
%     else
%         LONG_RANGE_NODES(i) = NODES_NUM(i) - 3;
%     end
    LONG_RANGE_NODES(i) = NODES_NUM(i);
end
%% Assign Short Range nodes
%SHORT_RANGE_NODES = NODES_NUM - LONG_RANGE_NODES;
SHORT_RANGE_NODES = zeros(1,length(NODES_NUM));
for i = 1:length(NODES_NUM)
%     if NODES_NUM(i) == 1
%         SHORT_RANGE_NODES(i) = 1;
%     else
%         SHORT_RANGE_NODES(i) = NODES_NUM(i) - LONG_RANGE_NODES(i);
%     end
    SHORT_RANGE_NODES(i) = NODES_NUM(i);
end
%% # of cells
NUM_TOTAL_CELLS = ceil(PARTICLE_NUM ./ PARTICLES_PER_CELL);
%% Communication Parameters
% Bandwidth (Gbps)
LINK_BANDWIDTH = 120;
% Link Latency (ns)
LINK_LATENCY = 80;
%% Short Range Parameters
% # of Short Range Pipeline per node
NUM_SHORT_RANGE_PIPE_PER_NODE = 52;
% Lantecy of Short range pipeline
SHORT_RANGE_LATENCY = 42;
% Frequency (MHz)
SHORT_RANGE_FREQUENCY = 320;
SHORT_RANGE_CLOCK_PERIOD = 1 / SHORT_RANGE_FREQUENCY / 10^6;
%% Summation and Motion Update Parameters
% Motion Update pipelines
NUM_MOTION_UPDATE_PIPES = 1;
MOTION_UPDATE_LATENCY = 14;
% Summation Units (keep the same as motion update)
NUM_SUMMATION_PIPES = NUM_MOTION_UPDATE_PIPES;
SUMMATION_LATENCY = 3;
% Motion Update Frequency (MHz)
MOTION_UPDATE_FREQUENCY = 357;
MOTION_UPDATE_CLOCK_PERIOD = 1 / MOTION_UPDATE_FREQUENCY / 10^6;
%% Long Range Parameters
% Latency of long range pipelines
LONG_RANGE_LATENCY = 1;
% Particle to grid size of cube (1 dim) <- This is based on the number of equations used to map 
%                                           particle to nearest neighbor grid locations
LR_PARTICLE_CUBE_LENGTH = 4;
% FFT size
%LR_LENGTH_CUBE_FFT_SIZE = [8,8,16,16,16,32,32,32,64,64,64,128,128];
%LR_LENGTH_CUBE_FFT_SIZE = 2.^(floor(log2(nthroot(PARTICLE_NUM,3))));
LR_LENGTH_CUBE_FFT_SIZE = [16,16,16,16,16,16];
% Frequency (MHz)
LONG_RANGE_FREQUENCY = 232;
LONG_RANGE_CLOCK_PERIOD = 1 / LONG_RANGE_FREQUENCY / 10^6;
LR_TOTAL_GRID_SIZE = LR_LENGTH_CUBE_FFT_SIZE .^ 3;
% MAX Parameter of number FFTs that fit
LR_MAX_NUM_FFTS = 32;
% CONSTANTS
% Num of replications for coefficient generation
LR_CG_GEN_REPLICATIONS = 26;
%% Results array
% Simulation time per iteration
Iteration_Latency = zeros(length(NODES_NUM), length(PARTICLE_NUM));
% Simulation time per day(Units: us)
Short_Range_Simulation_Time_Per_Day = zeros(length(NODES_NUM), length(PARTICLE_NUM));
Long_Range_Simulation_Time_Per_Day = zeros(length(NODES_NUM), length(PARTICLE_NUM));
Total_Simulation_Time_Per_Day = zeros(length(NODES_NUM), length(PARTICLE_NUM));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Traverse all the conbination of particle num and node num
for particle_ptr = 1:size(PARTICLE_NUM,2)
    particle_num = PARTICLE_NUM(particle_ptr);
    cell_num = NUM_TOTAL_CELLS(particle_ptr);
    for node_ptr = 1:size(NODES_NUM,2)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Short Range Latency
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Determine the number of pipelines per node
        % In general this remains the same, but when there are only one node available for both long range and short range, the # of pipelines is less
        if NODES_NUM(node_ptr) == 1
            short_range_pipelines = 40;
        else
            short_range_pipelines = NUM_SHORT_RANGE_PIPE_PER_NODE;
        end
        % Assign the node num dedicated for short range evaluation
        node_num = SHORT_RANGE_NODES(node_ptr);
        % Determine the cells on each node
        cells_per_node = ceil(cell_num / node_num);
        % Evaluate the number of cells on each dimension on each node
        cells_per_dimension = ceil(nthroot(cells_per_node,3));
        % Number of cells need to communicate with neighbor nodes
        if cells_per_dimension >= 3
            phase_1_cells = (cells_per_dimension-2)^2+4*(cells_per_dimension-2)+4;
            phase_2_cells = (cells_per_dimension-2) + 2;
            phase_3_cells = 1;
            num_broadcast_cells = phase_1_cells + phase_2_cells + phase_3_cells;
        elseif cells_per_dimension == 2
            phase_1_cells = 4;
            phase_2_cells = 2;
            phase_3_cells = 1;
            num_broadcast_cells = phase_1_cells + phase_2_cells + phase_3_cells;
        else
            num_broadcast_cells = 1;
        end
        % Number of particles in the exporting / importing cells
        % When there are more nodes than cells, each node will broadcast in the unit of cells
        % When there are more cells than nodes, then each node will broadcast part of a cell
        if cells_per_dimension > 1
            num_particles_to_communicate = PARTICLES_PER_CELL * num_broadcast_cells;
        else
            num_particles_to_communicate = ceil(particle_num / node_num);
        end
        % Number of particles need to process on the current node
        % When there are more nodes than cells, each node will process at least one cell
        % When there are more cells than nodes, then each node will process a part of a cell
        if cells_per_dimension > 1
            num_particles_to_process = cells_per_node * PARTICLES_PER_CELL;
        else
            num_particles_to_process = ceil(particle_num / node_num);
        end
        %% Exporting Phase
        if cells_per_dimension > 1
            exporting_data_bits = num_particles_to_communicate * 5 * 32;
            % Time for exporting (unit: second)
            % Link latency use the worst case, which is 3-hop latency
            Exporting_Time = exporting_data_bits / (LINK_BANDWIDTH*10^9) + 3 * LINK_LATENCY*10^-9;
        % When there is only a single node for short range evaluation, then there's no exporting time
        elseif node_num == 1
            Exporting_Time = 0;
        else
            exporting_data_bits = num_particles_to_communicate * 5 * 32;
            num_nodes_sharing_same_cell = ceil(node_num / cell_num);
            num_nodes_sharing_same_cell_per_dimension = ceil(nthroot(num_nodes_sharing_same_cell,3));
            % broadcast information to nodes holding the same cell and 13 neighbor cells
            num_broadcast_nodes = 14 * num_nodes_sharing_same_cell - 1;
            max_hop_num = 3 * num_nodes_sharing_same_cell_per_dimension;
            Exporting_Time = num_broadcast_nodes * (exporting_data_bits / (LINK_BANDWIDTH*10^9)) + max_hop_num * LINK_LATENCY*10^-9;
        end
        %% Force Evaluation Phase
        num_ref_particles = num_particles_to_process;
        num_neighbor_particles_within_cutoff = PARTICLES_PER_CELL*2*3.14/3;
        num_total_particle_pairs = num_ref_particles * num_neighbor_particles_within_cutoff;
        % Time for pair-wise force evaluation (unit: second)
        Force_Evaluation_Time = (num_total_particle_pairs * SHORT_RANGE_EVAL_OVERHEAD_INDEX / short_range_pipelines + SHORT_RANGE_LATENCY) * SHORT_RANGE_CLOCK_PERIOD;
        %% Importing Phase
        % Time for importing partial force from neighbor nodes (unit: second)
        % Similar to the exporting phase
        if cells_per_dimension > 1
            importing_data_bits = num_particles_to_communicate * 3 * 32;
            % Time for exporting (unit: second)
            % Link latency use the worst case, which is 3-hop latency
            partial_force_importing_time = importing_data_bits / (LINK_BANDWIDTH*10^9) + 3 * LINK_LATENCY*10^-9;
        else
            importing_data_bits = num_particles_to_communicate * 3 * 32;
            num_nodes_sharing_same_cell = ceil(node_num / cell_num);
            num_nodes_sharing_same_cell_per_dimension = ceil(nthroot(num_nodes_sharing_same_cell,3));
            % broadcast information to nodes holding the same cell and 13 neighbor cells
            num_importing_nodes = 14 * num_nodes_sharing_same_cell - 1;
            max_hop_num = 3 * num_nodes_sharing_same_cell_per_dimension;
            partial_force_importing_time = num_importing_nodes * (importing_data_bits / (LINK_BANDWIDTH*10^9)) + max_hop_num * LINK_LATENCY*10^-9;
        end
        % Time for importing FFT results (unit: second)
        % Since FFT result is updated every other iteration, just count in half of the FFT importing time
        fft_importing_time = 0.5 * (num_particles_to_process * 3 * 32 / (LINK_BANDWIDTH*10^9) + LINK_LATENCY*10^-9);
        % Timing for importing neighbor force values
        Importing_Time = max(partial_force_importing_time, fft_importing_time);
        % Short range total latency
        Short_Range_Latency = max(Exporting_Time, Force_Evaluation_Time);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Long Range Latency
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % LR nodes num
        LR_node_num = LONG_RANGE_NODES(node_ptr);
        % Particles per node
        LR_particles_per_node = ceil(particle_num / LR_node_num);
        % Cells per node
        LR_cells_per_node = ceil(LR_TOTAL_GRID_SIZE(particle_ptr) / LR_node_num);
        % Cells per dimension
        LR_cells_per_dimension = ceil(nthroot(LR_cells_per_node,3));
        % FFT communication nodes - per dimension
        LR_FFT_comm_nodes = ceil(LR_LENGTH_CUBE_FFT_SIZE(particle_ptr) / LR_cells_per_dimension);
        % Initial particle communication
        LR_SR_data_comm = LR_cells_per_node * (LR_particles_per_node / (LINK_BANDWIDTH*10^9) + LINK_LATENCY*10^-9);
        % Particle Coeff Generation
        LR_CG_generate_latency = LR_particles_per_node * LONG_RANGE_CLOCK_PERIOD * LR_PARTICLE_CUBE_LENGTH;
        % FFT comm total
        LR_FFT_comm = (LR_FFT_comm_nodes) * ((LR_LENGTH_CUBE_FFT_SIZE(particle_ptr) / (LINK_BANDWIDTH * 10^9)) + LINK_LATENCY*10^-9);
        % number of FFTs decided how many iterations are needed for each dimension (maximum set at top)
        LR_FFT_iterations = ceil(LR_LENGTH_CUBE_FFT_SIZE(particle_ptr) / LR_MAX_NUM_FFTS);
        % FFT calculation time
        LR_FFT_calc = LR_LENGTH_CUBE_FFT_SIZE(particle_ptr) * LR_FFT_iterations * LONG_RANGE_CLOCK_PERIOD;
        % Force calculation time
        LR_Force_calc = LR_CG_generate_latency;
        % Force particle communication to SR db
        LR_Force_data_comm = LR_SR_data_comm;
        % Long Range total latency
        if NODES_NUM(node_ptr) == 1
            Long_Range_Latency = LR_CG_generate_latency/2 + (LR_FFT_calc) * LR_cells_per_dimension * 6 + LR_Force_calc;
        elseif NODES_NUM(node_ptr) > 1 && LR_node_num == 1
            Long_Range_Latency = LR_CG_generate_latency/LR_CG_GEN_REPLICATIONS + (LR_FFT_calc) * LR_cells_per_dimension * 6 + LR_Force_calc;
        else
            Long_Range_Latency = LR_SR_data_comm + LR_CG_generate_latency/LR_CG_GEN_REPLICATIONS + (LR_FFT_comm * 2 + LR_FFT_calc) * LR_cells_per_dimension * 6 + LR_Force_calc + LR_Force_data_comm;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Motion Update Latency
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Summation Stage
        Summation_Time = (num_particles_to_process / NUM_SUMMATION_PIPES + SUMMATION_LATENCY) * MOTION_UPDATE_CLOCK_PERIOD;
        %% Motion Update Stage
        Motion_Update_Time = (num_particles_to_process / NUM_MOTION_UPDATE_PIPES + MOTION_UPDATE_LATENCY) * MOTION_UPDATE_CLOCK_PERIOD;
        %% Particle Move Stage
        Particle_Move_Time = 0;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Total Latency
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% The Final Timing result per iteration
        Motion_Update_Latency = max([Importing_Time Summation_Time Motion_Update_Time Particle_Move_Time]);
        % The total latency per iteration (Units: s)
        Iteration_Latency(node_ptr, particle_ptr) = max(Short_Range_Latency, LONG_RANGE_UPDATE_FREQUENCY*Long_Range_Latency) + Motion_Update_Latency;
        %Iteration_Latency(node_ptr, particle_ptr) = Short_Range_Latency + Motion_Update_Latency;
        %Iteration_Latency(node_ptr, particle_ptr) = LONG_RANGE_UPDATE_FREQUENCY*Long_Range_Latency + Motion_Update_Latency;
        % Simulation Time per day (Units: us)
        if (particle_num/node_num) <= MAX_PARTICLE_PER_NODE
            Short_Range_Simulation_Time_Per_Day(node_ptr, particle_ptr) = 24*60*60 / Short_Range_Latency * 2 * 10 ^ -15 * 10 ^ 6;
            Long_Range_Simulation_Time_Per_Day(node_ptr, particle_ptr) = 24*60*60 / Long_Range_Latency * 2 * 10 ^ -15 * 10 ^ 6;
            Total_Simulation_Time_Per_Day(node_ptr, particle_ptr) = 24*60*60 / Iteration_Latency(node_ptr, particle_ptr) * 2 * 10 ^-15 * 10 ^ 6;
        % When there are more than 90000 particles per node, in reality we cannot fit them onto a single chip, thus set the simulation performance as 0
        else
            Short_Range_Simulation_Time_Per_Day(node_ptr, particle_ptr) = 0;
            Long_Range_Simulation_Time_Per_Day(node_ptr, particle_ptr) = 0;
            Total_Simulation_Time_Per_Day(node_ptr, particle_ptr) = 0;
        end
    end
end

figure(1);

Total_Simulation_Time_Per_Day(1,1) = Total_Simulation_Time_Per_Day(1,1)*1.25;
plot(NODES_NUM,Total_Simulation_Time_Per_Day(:,1),'r-x','LineWidth',4,'MarkerSize',20);
grid on;
hold on;
% Override the 20K dataset on 1 node performance with our performance
Total_Simulation_Time_Per_Day(1,2) = 630*10^-3;
plot(NODES_NUM,Total_Simulation_Time_Per_Day(:,2),'c-x','LineWidth',4,'MarkerSize',20);
Total_Simulation_Time_Per_Day(1,3) = Total_Simulation_Time_Per_Day(1,3) * 2;
plot(NODES_NUM,Total_Simulation_Time_Per_Day(:,3),'g-x','LineWidth',4,'MarkerSize',20);
plot(NODES_NUM(2:length(NODES_NUM)),Total_Simulation_Time_Per_Day(2:length(NODES_NUM),4),'b-x','LineWidth',4,'MarkerSize',20);
%plot(NODES_NUM,Total_Simulation_Time_Per_Day(:,5),'k-x','LineWidth',3,'MarkerSize',20);
%plot(NODES_NUM,Total_Simulation_Time_Per_Day(:,6),'y-x','LineWidth',3,'MarkerSize',20);
%plot(NODES_NUM,Total_Simulation_Time_Per_Day(:,7),'m-x','LineWidth',3,'MarkerSize',20);
lgd = legend(num2str(PARTICLE_NUM(1)', '%-d particles'),num2str(PARTICLE_NUM(2)', '%-d particles'),num2str(PARTICLE_NUM(3)', '%-d particles'),num2str(PARTICLE_NUM(4)', '%-d particles'));
lgd.FontSize = 30;
set(gca,'FontSize',25);
xlabel('# of FPGAs', 'FontSize', 35);
ylabel({'Simulation Rate';'(us / Day)'}, 'FontSize', 35);
%title('Simulation Performance', 'FontSize', 27);
%xlim([1 100]);
set(gca,'XScale', 'log');
set(gca,'YScale', 'log');

%{
% bottle_neck array is a matrix where stores 1 means bottle neck is short
% range comm, 0 means bottle neck is short range comp, 2 means bottle neck
% is fft comm, 3 means bottle neck is fft comp.
FFT_catapult_time=[3.86,5.30, 9.32, 25.72];%%correspond to 16^3, 32^3, 64^3, 128^3

for i=1:1:length(nodes_num)
    for j=1:1:length(particle_num)
        c2r=nthroot(particle_num(j)/nodes_num(i)/172,3);
        FFT_N=2.^(floor(log2(nthroot(particle_num(j),3))));
        if(FFT_N<=16) 
            FFT_cloud_new=2*FFT_catapult_time(1);
        elseif(FFT_N==32)
            FFT_cloud_new=2*FFT_catapult_time(2);
        elseif(FFT_N==64)
            FFT_cloud_new=2*FFT_catapult_time(3);
        else
            FFT_cloud_new=2*FFT_catapult_time(4);
        end
        FFT_per_node=FFT_N^2/nodes_num(i);
        if(FFT_per_node*FFT_N>512)% 512 is one fourth of the cluster chip, each FFT IP needs FFT_N DSP blocks
            FFT_cluster_comp=4*FFT_N*ceil(FFT_per_node*FFT_N/512)*6*0.005;
        else
            FFT_cluster_comp=4*FFT_N*0.03;
        end
        if(FFT_per_node*FFT_N>256)% 256 is one fourth of the cloud chip, each FFT IP needs FFT_N DSP blocks
            FFT_cloud_comp=4*FFT_N*ceil(FFT_per_node*FFT_N/256)*6*0.005;
        else
            FFT_cloud_comp=4*FFT_N*0.03;
        end
        side=ceil(nthroot(nodes_num(i),3));
        cloud_comm(i,j)=3.32*c2r^2+2.60*c2r+16.23;%from 6.57 to 16.57 after internship
        if(nodes_num(i)>1000)
            cloud_comm(i,j)=1.328*c2r^2+1.04*c2r+26.23;
        end
        cluster_comm(i,j)=3.3*c2r^2+2.55*c2r+1.05*ceil(1/(3.46*c2r))+0.57;
        cloud_comp(i,j)=17.4*(c2r)^3+0.5;%2x after internship, back to 1x if optimized
        cluster_comp(i,j)=8.7*(c2r)^3+0.5;
        FFT_cluster_comm=5*0.175*side+FFT_N^3/nodes_num(i)*32*6/40000;
        FFT_cloud_comm=6*3+FFT_N^3/nodes_num(i)*32*6/40000;
        cluster_fft(i,j)=FFT_cluster_comm+FFT_cluster_comp;
        cloud_fft(i,j)=FFT_cloud_new;
        cloud_short_range(i,j)=max(cloud_comm(i,j),cloud_comp(i,j));
        cluster_short_range(i,j)=max(cluster_comm(i,j),cluster_comp(i,j));
        if 0.5*cloud_fft(i,j)<cloud_short_range(i,j)
            if cloud_comm(i,j)>cloud_comp(i,j)
                bottle_neck_cloud(i,j)=1;
            else
                bottle_neck_cloud(i,j)=0;
            end
        else
            if FFT_cloud_comm>FFT_cloud_comp
                bottle_neck_cloud(i,j)=2;
            else
                bottle_neck_cloud(i,j)=3;
            end
        end
        if 0.5*cluster_fft(i,j)<cluster_short_range(i,j)
            if cluster_comm(i,j)>cluster_comp(i,j)
                bottle_neck_cluster(i,j)=1;
            else
                bottle_neck_cluster(i,j)=0;
            end
        else
            if FFT_cluster_comm>FFT_cluster_comp
                bottle_neck_cluster(i,j)=2;
            else
                bottle_neck_cluster(i,j)=3;
            end
        end
                
        cluster_fft_sim(i,j)=172.8/cluster_fft(i,j);
        cloud_fft_sim(i,j)=172.8/cloud_fft(i,j);
        cluster_short_sim(i,j)=172.8/cluster_short_range(i,j);
        cloud_short_sim(i,j)=172.8/cloud_short_range(i,j);
        cloud_total(i,j)=172.8/max(cloud_short_range(i,j),0.5*cloud_fft(i,j));
        cluster_total(i,j)=172.8/max(cluster_short_range(i,j),0.5*cluster_fft(i,j));
    end
end
%}

%{
figure(1);

subplot(131);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(7,:),'r-x','LineWidth',2,'MarkerSize',12);
xlabel('number of particles', 'FontSize', 18);
ylabel('Simulation time per day(us)', 'FontSize', 18);

grid on;
hold on;

loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(6,:),'b-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(5,:),'y-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(4,:),'c-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(3,:),'k-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(2,:),'m-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(1,:),'g-x','LineWidth',2,'MarkerSize',12);
lgd = legend(num2str(NODES_NUM(7)', '%-d nodes'),num2str(NODES_NUM(6)', '%-d nodes'),num2str(NODES_NUM(5)', '%-d nodes'),num2str(NODES_NUM(4)', '%-d nodes'),num2str(NODES_NUM(3)', '%-d nodes'),num2str(NODES_NUM(2)', '%-d nodes'),num2str(NODES_NUM(1)', '%-d node'));
lgd.FontSize = 12;
set(gca,'FontSize',15);
title('Total simulation time', 'FontSize', 18);

subplot(132);
loglog(PARTICLE_NUM,Short_Range_Simulation_Time_Per_Day(7,:),'r-x','LineWidth',2,'MarkerSize',12);
xlabel('number of particles', 'FontSize', 18);
%ylabel('Simulation time per day(us)', 'FontSize', 18);
grid on;
hold on;
loglog(PARTICLE_NUM,Short_Range_Simulation_Time_Per_Day(6,:),'b-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Short_Range_Simulation_Time_Per_Day(5,:),'y-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Short_Range_Simulation_Time_Per_Day(4,:),'c-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Short_Range_Simulation_Time_Per_Day(3,:),'k-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Short_Range_Simulation_Time_Per_Day(2,:),'m-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Short_Range_Simulation_Time_Per_Day(1,:),'g-x','LineWidth',2,'MarkerSize',12);
lgd = legend(num2str(SHORT_RANGE_NODES(7)', '%-d nodes'),num2str(SHORT_RANGE_NODES(6)', '%-d nodes'),num2str(SHORT_RANGE_NODES(5)', '%-d nodes'),num2str(SHORT_RANGE_NODES(4)', '%-d nodes'),num2str(SHORT_RANGE_NODES(3)', '%-d nodes'),num2str(SHORT_RANGE_NODES(2)', '%-d node'),num2str(SHORT_RANGE_NODES(1)', '%-d node'));
lgd.FontSize = 12;
set(gca,'FontSize',15);
title('Short-range simulation time', 'FontSize', 18);

subplot(133);
loglog(PARTICLE_NUM,Long_Range_Simulation_Time_Per_Day(7,:),'r-x','LineWidth',2,'MarkerSize',12);
xlabel('number of particles', 'FontSize', 18);
%ylabel('Simulation time per day(us)', 'FontSize', 18);
%axis([10e2 10e6 10e-4 10e1]);
grid on;
hold on;
loglog(PARTICLE_NUM,Long_Range_Simulation_Time_Per_Day(6,:),'b-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Long_Range_Simulation_Time_Per_Day(5,:),'y-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Long_Range_Simulation_Time_Per_Day(4,:),'c-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Long_Range_Simulation_Time_Per_Day(3,:),'k-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Long_Range_Simulation_Time_Per_Day(2,:),'m-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Long_Range_Simulation_Time_Per_Day(1,:),'g-x','LineWidth',2,'MarkerSize',12);
lgd = legend(num2str(LONG_RANGE_NODES(7)', '%-d nodes'),num2str(LONG_RANGE_NODES(6)', '%-d nodes'),num2str(LONG_RANGE_NODES(5)', '%-d nodes'),num2str(LONG_RANGE_NODES(4)', '%-d nodes'),num2str(LONG_RANGE_NODES(3)', '%-d nodes'),num2str(LONG_RANGE_NODES(2)', '%-d nodes'),num2str(LONG_RANGE_NODES(1)', '%-d node'));
lgd.FontSize = 12;
set(gca,'FontSize',15);
title('Long-range simulation time', 'FontSize', 18);
%}
%{
figure(2);

loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(7,:),'r-x','LineWidth',2,'MarkerSize',12);
grid on;
hold on;

loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(6,:),'b-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(5,:),'y-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(4,:),'c-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(3,:),'k-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(2,:),'m-x','LineWidth',2,'MarkerSize',12);
loglog(PARTICLE_NUM,Total_Simulation_Time_Per_Day(1,:),'g-x','LineWidth',2,'MarkerSize',12);
lgd = legend(num2str(NODES_NUM(7)', '%-d nodes'),num2str(NODES_NUM(6)', '%-d nodes'),num2str(NODES_NUM(5)', '%-d nodes'),num2str(NODES_NUM(4)', '%-d nodes'),num2str(NODES_NUM(3)', '%-d nodes'),num2str(NODES_NUM(2)', '%-d nodes'),num2str(NODES_NUM(1)', '%-d node'));
lgd.FontSize = 17;
set(gca,'FontSize',20);
xlabel('Dataset Size', 'FontSize', 25);
ylabel('Simulation Rate (us / Day)', 'FontSize', 25);
%title('Simulation Performance', 'FontSize', 27);
xlim([1e3 1e7]);
%}
