
clear all
clc

%Rows are presynaptic, columns are postsynaptic
%0 are disconnected, 1 is connected by excitatory, 2 by inhibitory

%Number of neurons per layer
%Layers are: L23e, L23i, L4e, L4i, L5e, L5i, L6e, L6i
init_neur = 80000;
L23e = fix(init_neur*0.27);
L23i = fix(init_neur*0.07);
L4e = fix(init_neur*0.286);
L4i = fix(init_neur*0.071);
L5e = fix(init_neur*0.063);
L5i = fix(init_neur*0.014);
L6e = fix(init_neur*0.188);
L6i = fix(init_neur*0.038);
num_neur = [L23e L23i L4e L4i L5e L5i L6e L6i];
total_neurons = sum(num_neur);

perc_conn = [0.1 0.17 0.044 0.082 0.032 0 0.008 0; ...
    0.135 0.137 0.032 0.052 0.075 0 0.004 0; ...
    0.008 0.006 0.05 0.135 0.007 0.0003 0.045 0; ...
    0.069 0.003 0.079 0.16 0.003 0 0.106 0; ...
    0.1 0.062 0.051 0.006 0.083 0.373 0.02 0; ...
    0.055 0.027 0.026 0.002 0.06 0.316 0.009 0; ...
    0.016 0.007 0.021 0.017 0.057 0.02 0.04 0.255; ...
    0.036 0.001 0.003 0.001 0.028 0.008 0.066 0.144];

%Build matrix
all_conn_mat = [];
xxe = [];
xxi = [];
pos = 1;
for i = 1:8 %Rows
    temp_conn_mat = [];
    for j = 1:8 %Columns

        i
        j

        prob_conn = perc_conn(i,j);
        xx = rand(num_neur(i),num_neur(j));
        xx2 = zeros(num_neur(i),num_neur(j));
        xx3 = find(xx<=prob_conn); %Connected neuron

        if rem(i, 2) == 1
            xx2(xx3) = 1;
        else
            xx2(xx3) = 2;
        end

        temp_conn_mat = [temp_conn_mat xx2];

    end

    if rem(i, 2) == 1
        %xxe for excitatory neurons
        xxe = [xxe (pos:pos+num_neur(i)-1)];
    else
        %xxi for inhibitory neurons
        xxi = [xxi (pos:pos+num_neur(i)-1)];
    end

    all_conn_mat = [all_conn_mat; temp_conn_mat];
    pos =  pos + num_neur(i);

end

%Remove self-connection (diagonal 0)
all_conn_mat(1:1+size(all_conn_mat,1):end) = 0;

figure()
imagesc(all_conn_mat)
colorbar
colormap turbo

mat_conn = all_conn_mat;

save('conn_matrix_potjans_diesman_hh.mat','-v7.3','total_neurons','mat_conn','xxe','xxi','num_neur')


