
clear all
clc

%Rows are presynaptic, columns are postsynaptic
%0 are disconnected, 1 is connected by excitatory, 2 by inhibitory

%Number of neurons per layer
%Layers are: L2e, L3ae, L3be, L4e, L5e, Inh
init_neur = 80000;
L2e = fix(init_neur*(1/6));
L3ae = fix(init_neur*(1/6));
L3be = fix(init_neur*(1/6));
L4e = fix(init_neur*(1/6));
L5e = fix(init_neur*(1/6));
Inh = fix(init_neur*(1/6));
num_neur = [L2e L3ae L3be L4e L5e Inh];
total_neurons = sum(num_neur);

perc_conn = [56/475 9/124 0 0 0 13/75; ...
    3/122 27/206 0 0 0 5/28; ...
    0 0 19/165 0 0 7/23; ...
    0 0 1/18 1/145 1/20 3/10; ...
    0 0 1/7 1/20 8/113 2/22; ...
    3/60 4/27 3/20 4/11 2/22 3/24];

%Build matrix
all_conn_mat = [];
xxe = [];
xxi = [];
pos = 1;
for i = 1:6 %Rows
    temp_conn_mat = [];
    for j = 1:6 %Columns

        i
        j

        prob_conn = perc_conn(i,j);
        xx = rand(num_neur(i),num_neur(j));
        xx2 = zeros(num_neur(i),num_neur(j));
        xx3 = find(xx<=prob_conn); %Connected neuron

        if i == 6
            xx2(xx3) = 2;
        else
            xx2(xx3) = 1;
        end

        temp_conn_mat = [temp_conn_mat xx2];


    end

    if i == 6
        %xxi for inhibitory neurons
        xxi = [xxi (pos:pos+num_neur(i))];
    else
        %xxe for excitatory neurons
        xxe = [xxe (pos:pos+num_neur(i))];
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

save('conn_matrix_human_80000.mat','-v7.3','total_neurons','mat_conn','xxe','xxi','num_neur')


