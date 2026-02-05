
aa = 1;
if aa == 1

    clear all
    clc

    tic

    %Parallel config
    %delete(gcp('nocreate'))
    %parpool(40)

    load conn_matrix_human_80000.mat

    figure()
    imagesc(mat_conn)
    colorbar
    title('Connectivity matrix. Yellow (Inh). Green (Exc)')

    mat_conn = sparse(mat_conn);

    %Neuron parameters
    %Izhikevich firing parameters RS
    a = 0.02;
    b = 0.2;
    c = -65;
    d = 8;
    Erest = - 70; % [mV] resting potential
    Vth = 30; %mV
    Cm = 1; % Specific capacitance = 1 microF/cm2

    %Coefficients
    c2 = 0.04; %mV
    c1 = 5;
    c0 = 140;

    %Simulation conditions
    time_len = 500; % [ms] time duration for plotting
    dt = 0.1; % [ms]    time step
    timevec = 0:dt:time_len;    % time vector with original time step

    %Stimulus is received by 10% of excitatory neurons
    Istim1 = zeros(total_neurons,length(timevec));   % Istim vector
    for nn = 1:total_neurons
        if mod(nn,100)==0
            input_data = load('sparse_synchro_act_1.mat');
        else
            input_data = load(['sparse_synchro_act_' num2str(mod(nn,100)) '.mat']);
        end
        all_long_biphasic_traces = input_data.all_long_biphasic_traces;
        all_long_biphasic_traces = [all_long_biphasic_traces 0];

        %Istim1(nn,:) = all_long_biphasic_traces(1:2:21);
        Istim1(nn,:) = all_long_biphasic_traces(1:2:10001);
        %Istim1(nn,:) = all_long_biphasic_traces(1:2:end);
        %Istim1(nn,:) = all_long_biphasic_traces;
    end
    stim_neuron_id = 1:total_neurons;

    %Add synthetic minis
    %%Acquisition rate 20 KHz. Simulations with time intervals = 0.05 ms
    acq_rate = 20000; %Hz
    delta_t = 1000/acq_rate; %ms

end

gpeak_exc = 0.005;
gpeak_inh = 0.02;

%Generate synaptic conductance (AMPA)
t1 = delta_t:delta_t:200; %ms
tau_rise = 1; %ms
tau_decay = 10; %ms
gsyn_AMPA = biexp(t1,gpeak_exc,tau_rise,tau_decay);
gsyn_AMPA = gsyn_AMPA(1:1000);
Erev_AMPA = 0; %mV

%Generate synaptic conductance (GABAA)
tau_rise = 2; %ms
tau_decay = 20; %ms
gsyn_GABAA = biexp(t1,gpeak_inh,tau_rise,tau_decay); %nS
gsyn_GABAA = gsyn_GABAA(1:1000); %50 ms trace
Erev_GABAA = -80; %mV

is_exc = false(total_neurons,1);
is_exc(xxe) = true;   % mark excitatory neuron indices as true
is_inh = false(total_neurons,1);
is_inh(xxi) = true;   % mark excitatory neuron indices as true

%%
%Asynchronous
tic
mat_freq = [];
cont1 = 0;
for amp_input = 1:10 %1:0.1:10
    amp_input
    cont1 = cont1 + 1;
    %Repetitions
    total_freq = [];
    for rept = 1:1 %100

        %Set initial conditions
        tspks = cell(1,total_neurons);

        %Run simulation
        Vm = Erest*ones(total_neurons,length(timevec));
        u = zeros(total_neurons,length(timevec));
        tspks = zeros(total_neurons,length(timevec));
        Istim = amp_input*Istim1;
        for t = 1:(length(timevec)-1)
            t
            for nn = 1:total_neurons

                if Vm(nn,t) >= Vth-1 & t+999<length(timevec)
                    [rowIdx, colIdx, val] = find(mat_conn(nn,:));
                    if is_exc(nn)
                        conn_nn = colIdx(val == 1);
                        all_conn = length(conn_nn);
                        for pp = 1:all_conn
                            Isyn_AMPA = gsyn_AMPA*(Vm(conn_nn(pp),t)-Erev_AMPA); %pA
                            Istim(conn_nn(pp),t:t+999) = Istim(conn_nn(pp),t:t+999) - Isyn_AMPA;
                        end

                    elseif is_inh(nn)
                        conn_nn = colIdx(val == 2);
                        all_conn = length(conn_nn);
                        for pp = 1:all_conn
                            Isyn_GABAA = gsyn_GABAA*(Vm(conn_nn(pp),t)-Erev_GABAA); %pA
                            Istim(conn_nn(pp),t:t+999) = Istim(conn_nn(pp),t:t+999) - Isyn_GABAA;
                        end

                    end

                else

                    %Izhikevich neuron currents
                    qV =  c2*Vm(nn,t)^2 + c1*Vm(nn,t) + c0 - u(nn,t); %Quadratic
                    Vm(nn,t+1) = Vm(nn,t) + (dt/Cm)*(qV + Istim(nn,t));

                    if is_exc(nn) % excitatory neuron
                        u(nn,t+1) = u(nn,t) + dt*0.02*(0.2*Vm(nn,t) - u(nn,t)); %RS
                    else
                        u(nn,t+1) = u(nn,t) + dt*0.1*(0.2*Vm(nn,t) - u(nn,t)); %FS
                    end


                    if Vm(nn,t+1) >= Vth     % elicite spikes

                        Vm(nn,t+1) = -65;
                        if is_exc(nn)
                            u(nn,t+1) = u(nn,t+1) + 8;
                        else
                            u(nn,t+1) = u(nn,t+1) + 2;
                        end
                        tspks(nn,t) = 1;
                    end

                end

            end

        end

        %Average freq (Hz)
        psth_mat = sum(tspks, 1);
        avg_freq = sum(psth_mat)/(total_neurons*time_len/1000);
        total_freq = [total_freq avg_freq];

    end

    total_freq = mean(total_freq);
    mat_freq(cont1) = total_freq;

end

toc

mat_freq_asyn = mat_freq;

figure()
subplot(1,2,1)
plot(mat_freq,'k')

















%%
%Synchronous 2
%Stimulus is received by 10% of excitatory neurons
Istim1 = zeros(total_neurons,length(timevec));   % Istim vector
for nn = 1:total_neurons
    if mod(nn,100)==0
        input_data = load('sparse_synchro_act_1.mat');
    else
        input_data = load(['sparse_synchro_act_' num2str(mod(nn,100)) '.mat']);
    end
    all_long_biphasic_traces = input_data.all_long_biphasic_traces_2;
    all_long_biphasic_traces = [all_long_biphasic_traces 0];

    %Istim1(nn,:) = all_long_biphasic_traces;
    Istim1(nn,:) = all_long_biphasic_traces(1:2:10001);
end

tic
mat_freq = [];
cont1 = 0;
for amp_input = 1:10 %1:0.1:10
    amp_input
    cont1 = cont1 + 1;
    %Repetitions
    total_freq = [];
    for rept = 1:1 %100

        %Set initial conditions
        tspks = cell(1,total_neurons);

        %Run simulation
        Vm = Erest*ones(total_neurons,length(timevec));
        u = zeros(total_neurons,length(timevec));
        tspks = zeros(total_neurons,length(timevec));
        Istim = amp_input*Istim1;
        for t = 1:(length(timevec)-1)
            t
            for nn = 1:total_neurons

                if Vm(nn,t) >= Vth-1 & t+999<length(timevec)
                    [rowIdx, colIdx, val] = find(mat_conn(nn,:));
                    if is_exc(nn)

                        conn_nn = colIdx(val == 1);
                        all_conn = length(conn_nn);
                        for pp = 1:all_conn
                            Isyn_AMPA = gsyn_AMPA*(Vm(conn_nn(pp),t)-Erev_AMPA); %pA
                            Istim(conn_nn(pp),t:t+999) = Istim(conn_nn(pp),t:t+999) - Isyn_AMPA;
                        end

                    elseif is_inh(nn)
                        conn_nn = colIdx(val == 2);
                        all_conn = length(conn_nn);
                        for pp = 1:all_conn
                            Isyn_GABAA = gsyn_GABAA*(Vm(conn_nn(pp),t)-Erev_GABAA); %pA
                            Istim(conn_nn(pp),t:t+999) = Istim(conn_nn(pp),t:t+999) - Isyn_GABAA;
                        end

                    end

                else

                    %Izhikevich neuron currents
                    qV =  c2*Vm(nn,t)^2 + c1*Vm(nn,t) + c0 - u(nn,t); %Quadratic
                    Vm(nn,t+1) = Vm(nn,t) + (dt/Cm)*(qV + Istim(nn,t));

                    if is_exc(nn) % excitatory neuron
                        u(nn,t+1) = u(nn,t) + dt*0.02*(0.2*Vm(nn,t) - u(nn,t)); %RS
                    else
                        u(nn,t+1) = u(nn,t) + dt*0.1*(0.2*Vm(nn,t) - u(nn,t)); %FS
                    end


                    if Vm(nn,t+1) >= Vth     % elicite spikes

                        Vm(nn,t+1) = -65;
                        if is_exc(nn)
                            u(nn,t+1) = u(nn,t+1) + 8;
                        else
                            u(nn,t+1) = u(nn,t+1) + 2;
                        end
                        tspks(nn,t) = 1;
                    end

                end

            end

        end

        %Average freq (Hz)
        psth_mat = sum(tspks, 1);
        avg_freq = sum(psth_mat)/(total_neurons*time_len/1000);
        total_freq = [total_freq avg_freq];

    end

    total_freq = mean(total_freq);
    mat_freq(cont1) = total_freq;

end

toc

mat_freq_synch_2 = mat_freq;

hold on
plot(mat_freq,'r')





















%%
%Synchronous 4
%Stimulus is received by 10% of excitatory neurons
Istim1 = zeros(total_neurons,length(timevec));   % Istim vector
for nn = 1:total_neurons
    if mod(nn,100)==0
        input_data = load('sparse_synchro_act_1.mat');
    else
        input_data = load(['sparse_synchro_act_' num2str(mod(nn,100)) '.mat']);
    end
    all_long_biphasic_traces = input_data.all_long_biphasic_traces_4;
    all_long_biphasic_traces = [all_long_biphasic_traces 0];

    %Istim1(nn,:) = all_long_biphasic_traces;
    Istim1(nn,:) = all_long_biphasic_traces(1:2:10001);
end

tic
mat_freq = [];
cont1 = 0;
for amp_input = 1:10 %1:0.1:10
    amp_input
    cont1 = cont1 + 1;
    %Repetitions
    total_freq = [];
    for rept = 1:1 %100

        %Set initial conditions
        tspks = cell(1,total_neurons);

        %Run simulation
        Vm = Erest*ones(total_neurons,length(timevec));
        u = zeros(total_neurons,length(timevec));
        tspks = zeros(total_neurons,length(timevec));
        Istim = amp_input*Istim1;
        for t = 1:(length(timevec)-1)
            t
            for nn = 1:total_neurons

                if Vm(nn,t) >= Vth-1 & t+999<length(timevec)
                    [rowIdx, colIdx, val] = find(mat_conn(nn,:));
                    if is_exc(nn)

                        conn_nn = colIdx(val == 1);
                        all_conn = length(conn_nn);
                        for pp = 1:all_conn
                            Isyn_AMPA = gsyn_AMPA*(Vm(conn_nn(pp),t)-Erev_AMPA); %pA
                            Istim(conn_nn(pp),t:t+999) = Istim(conn_nn(pp),t:t+999) - Isyn_AMPA;
                        end

                    elseif is_inh(nn)
                        conn_nn = colIdx(val == 2);
                        all_conn = length(conn_nn);
                        for pp = 1:all_conn
                            Isyn_GABAA = gsyn_GABAA*(Vm(conn_nn(pp),t)-Erev_GABAA); %pA
                            Istim(conn_nn(pp),t:t+999) = Istim(conn_nn(pp),t:t+999) - Isyn_GABAA;
                        end

                    end

                else

                    %Izhikevich neuron currents
                    qV =  c2*Vm(nn,t)^2 + c1*Vm(nn,t) + c0 - u(nn,t); %Quadratic
                    Vm(nn,t+1) = Vm(nn,t) + (dt/Cm)*(qV + Istim(nn,t));

                    if is_exc(nn) % excitatory neuron
                        u(nn,t+1) = u(nn,t) + dt*0.02*(0.2*Vm(nn,t) - u(nn,t)); %RS
                    else
                        u(nn,t+1) = u(nn,t) + dt*0.1*(0.2*Vm(nn,t) - u(nn,t)); %FS
                    end


                    if Vm(nn,t+1) >= Vth     % elicite spikes

                        Vm(nn,t+1) = -65;
                        if is_exc(nn)
                            u(nn,t+1) = u(nn,t+1) + 8;
                        else
                            u(nn,t+1) = u(nn,t+1) + 2;
                        end
                        tspks(nn,t) = 1;
                    end

                end

            end

        end

        %Average freq (Hz)
        psth_mat = sum(tspks, 1);
        avg_freq = sum(psth_mat)/(total_neurons*time_len/1000);
        total_freq = [total_freq avg_freq];

    end

    total_freq = mean(total_freq);
    mat_freq(cont1) = total_freq;

end

toc

mat_freq_synch_4 = mat_freq;

plot(mat_freq,'b')
xlabel('Input amp')
ylabel('Freq (Hz)')
legend({'Asynchronous' 'Synchronous 2' 'Synchronous 4'})







%%Calculate %relat freq
rel_freq1 = 100*(mat_freq_synch_2-mat_freq_asyn)./mat_freq_asyn;
rel_freq2 = 100*(mat_freq_synch_4-mat_freq_asyn)./mat_freq_asyn;

subplot(1,2,2)
plot(1:1:10,rel_freq1,'k')
hold on
plot(1:1:10,rel_freq2,'r')
xlabel('Input amp')
ylabel('%Relat freq')
legend({'Synch 2' 'Synch 4'})

save mat_freq_human_var_input_80000.mat mat_freq_asyn mat_freq_synch_2 mat_freq_synch_4
save relat_freq_human_var_input_80000.mat rel_freq1 rel_freq2


