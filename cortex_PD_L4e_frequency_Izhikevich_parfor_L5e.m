function cortex_PD_L4e_frequency_Izhikevich_parfor_L5e()
% Frequency sweep with independent random seeds per condition.
% Keep the connectivity MAT file in the current MATLAB working directory.
% Each individual stimulation PSC retains a 1 nS peak across all conditions.
% Connectivity is scanned only once; workers reuse compact edge lists.
% Requires Parallel Computing Toolbox.
values = 100:100:2000;
seeds = 1:10;
numWorkers = 20; % Change to match available memory and CPU resources.
saveIndividual = false; % Set true to save individual L5e-only summaries.
outputFolder = 'L4e_frequency_Izhikevich_L5e_results';
if ~exist(outputFolder,'dir'), mkdir(outputFolder); end
pool = gcp('nocreate');
if isempty(pool)
    parpool('local',numWorkers);
elseif pool.NumWorkers ~= numWorkers
    delete(pool);
    parpool('local',numWorkers);
end
nConditions = numel(values);
nSeeds = numel(seeds);
% Build compact connectivity once on the client, before parallel work.
DATA.file = "conn_matrix_potjans_diesman_hh.mat";
DATA.rowBlockSize = 100;
DATA.verifyConnectionCodes = true;
NET = buildCorticalNetwork(DATA);
netConstant = parallel.pool.Constant(NET);
clear NET;
% Worker completion messages are sent to the client command window.
progressQueue = parallel.pool.DataQueue;
afterEach(progressQueue,@(msg)fprintf('%s\n',msg));
allResults = cell(nConditions*nSeeds,1);
parfor job = 1:(nConditions*nSeeds)
    conditionIndex = floor((job-1)/nSeeds)+1;
    seedIndex = mod(job-1,nSeeds)+1;
    seed = seeds(seedIndex);
    synchrony = 1;
    rateHz = values(conditionIndex);
    send(progressQueue,sprintf('START | frequency %.0f Hz | seed %d', rateHz,seed));
    result = runOneCondition(synchrony,rateHz,seed,saveIndividual,outputFolder,'frequency',conditionIndex,netConstant.Value);
    allResults{job} = result;
    send(progressQueue,sprintf('COMPLETED %d/%d | frequency %.0f Hz | seed %d | L5e mean %.4f Hz | %.1f s',job,nConditions*nSeeds,rateHz,seed,result.L5eMeanRate_Hz,result.simulationSeconds));
end
% Matrix: rows = sweep conditions; columns = independent random seeds.
L5eRateMatrix_Hz = reshape(cellfun(@(r)r.L5eMeanRate_Hz,allResults),nSeeds,nConditions)';
meanL5e_Hz = mean(L5eRateMatrix_Hz,2);
sdL5e_Hz = std(L5eRateMatrix_Hz,0,2);
semL5e_Hz = sdL5e_Hz/sqrt(nSeeds);
summary = table(values(:),meanL5e_Hz,sdL5e_Hz,semL5e_Hz, ...
    'VariableNames',{'Condition','MeanL5e_Hz','SDL5e_Hz','SEML5e_Hz'});
writematrix(L5eRateMatrix_Hz,fullfile(outputFolder,'L5e_all_data_points_Hz.csv'));
writetable(summary,fullfile(outputFolder,'L5e_summary.csv'));
save(fullfile(outputFolder,'L5e_results.mat'),'L5eRateMatrix_Hz','meanL5e_Hz', ...
    'sdL5e_Hz','semL5e_Hz','values','seeds','summary');
fig = figure('Color','w','Name','L5e firing frequency');
hold on;
for k=1:nSeeds
    plot(values(:),L5eRateMatrix_Hz(:,k),'o','MarkerSize',5, ...
        'Color',[0.6 0.6 0.6],'MarkerFaceColor',[0.75 0.75 0.75], ...
        'LineStyle','none','HandleVisibility','off');
end
errorbar(values(:),meanL5e_Hz,semL5e_Hz,'-ok','LineWidth',1.6, ...
    'MarkerFaceColor','k','DisplayName','Mean +/- SEM');
xlabel('Stimulation frequency (Hz)');
ylabel('L5e mean firing frequency (Hz)');
title('Layer 5 excitatory neurons: multiple seeds per condition');
grid on; box on;
legend('Location','best');
exportgraphics(fig,fullfile(outputFolder,'L5e_mean_SEM.png'),'Resolution',200);
savefig(fig,fullfile(outputFolder,'L5e_mean_SEM.fig'));
disp(summary);
end

function out = runOneCondition(synchrony,rateHz,seed,saveIndividual,outputFolder,sweepType,conditionIndex,NET)
rng(seed,'twister');
% ------------------------- Connectivity ---------------------------------
DATA.file = "conn_matrix_potjans_diesman_hh.mat";
DATA.rowBlockSize = 100;       % rows read at once from v7.3 MAT file
DATA.verifyConnectionCodes = true;

% ------------------------- Simulation -----------------------------------
SIM.totalTime_ms = 1000;
SIM.dt_ms = 0.025;
SIM.initialVoltage_mV = -65;
SIM.spikeDetectionThreshold_mV = 30; % Izhikevich spike/reset threshold
SIM.progressUpdates = 20;

% ------------------------- Recurrent cortical synapses ------------------
% One spike causes a conductance transient with the specified PEAK.
REC.excPeak_nS = 0.0765;        % from previous cortical code
REC.excTauRise_ms = 1.0;
REC.excTauDecay_ms = 10.0;
REC.excErev_mV = 0;

REC.inhPeak_nS = 0.2;        % from previous cortical code
REC.inhTauRise_ms = 2.0;
REC.inhTauDecay_ms = 20.0;
REC.inhErev_mV = -80;

REC.excScale = 1.0;
REC.inhScale = 1.0;

% ------------------------- In-vivo-like Poisson background --------------
% Generated online during the simulation. This is much more memory efficient
% than precomputing an N x time stimulus matrix.
BACKGROUND.enabled = true;

% Independent external EPSC/IPSC event rates received by EACH neuron.
% Tune these values to reproduce the statistics of your old precomputed traces.
BACKGROUND.excRate_Hz = 800;
BACKGROUND.inhRate_Hz = 200;

% Peak conductance of ONE external event.
BACKGROUND.excPeak_nS = 0.5;
BACKGROUND.inhPeak_nS = 2;

BACKGROUND.excTauRise_ms = 1.0;
BACKGROUND.excTauDecay_ms = 10.0;
BACKGROUND.excErev_mV = 0;

BACKGROUND.inhTauRise_ms = 2.0;
BACKGROUND.inhTauDecay_ms = 20.0;
BACKGROUND.inhErev_mV = -80;

% Multipliers make input-strength sweeps easy without changing event rates.
BACKGROUND.excScale = 1.0;
BACKGROUND.inhScale = 1.0;

% ------------------------- Layer-4 excitatory stimulation ----------------
% Additional Poisson EPSCs are delivered ONLY to excitatory L4 neurons (L4e).
% All other populations receive only the background input defined above.
STIM.enabled = true;
STIM.rate_Hz = rateHz;
STIM.peak_nS = 1;
STIM.tauRise_ms = 1.0;
STIM.tauDecay_ms = 10.0;
STIM.Erev_mV = 0;
STIM.scale = 1.0;
STIM.synchrony = synchrony;       % 0=independent, 1=identical event times across L4e
assert(STIM.synchrony>=0 && STIM.synchrony<=1);
% Individual PSC peak conductance remains fixed at 1 nS for every condition.

%% ========================================================================
% IZHIKEVICH PARAMETERS: excitatory RS, inhibitory FS
% ========================================================================
IZH.aExc = 0.02; IZH.bExc = 0.2; IZH.cExc = -65; IZH.dExc = 8;
IZH.aInh = 0.1;  IZH.bInh = 0.2; IZH.cInh = -65; IZH.dInh = 2;
IZH.c2 = 0.04; IZH.c1 = 5; IZH.c0 = 140;
IZH.Cm = 1;
IZH.Erest_mV = -70; % Reference only; initial voltage remains -65 mV.
IZH.Vth_mV = 30;
% Synaptic conductances are nS and voltages mV, so currents are pA.
% The canonical Izhikevich equation uses dimensionless current units.
% This explicit conversion is a tunable model calibration, NOT a physical Cm.
IZH.pA_per_current_unit = 100;

assert(SIM.dt_ms > 0 && SIM.totalTime_ms > 0);
assert(IZH.Cm > 0 && IZH.pA_per_current_unit > 0);
assert(isfile(DATA.file),'Connectivity file not found: %s',DATA.file);

% Reuse connectivity constructed once outside parfor.
N = NET.N;
isExc = NET.isExc;
postEdge = NET.postEdge;
edgeCountByPre = NET.edgeCountByPre;
edgeStart = NET.edgeStart;
edgeStop = NET.edgeStop;
stimIdx = NET.stimIdx;
nStim = NET.nStim;
popStart = NET.popStart;
popStop = NET.popStop;

%% ========================================================================
% PRECOMPUTE SYNAPTIC RECURRENCES
% ========================================================================
% A bi-exponential conductance is implemented as
%   g(t) = A * [exp(-t/tauDecay) - exp(-t/tauRise)]
% Two state vectors are therefore sufficient; no waveform arrays are needed.

REC.excEventIncrement_nS = biexponentialIncrementForPeak( ...
    REC.excPeak_nS*REC.excScale,REC.excTauRise_ms,REC.excTauDecay_ms);
REC.inhEventIncrement_nS = biexponentialIncrementForPeak( ...
    REC.inhPeak_nS*REC.inhScale,REC.inhTauRise_ms,REC.inhTauDecay_ms);
BACKGROUND.excEventIncrement_nS = biexponentialIncrementForPeak( ...
    BACKGROUND.excPeak_nS*BACKGROUND.excScale, ...
    BACKGROUND.excTauRise_ms,BACKGROUND.excTauDecay_ms);
BACKGROUND.inhEventIncrement_nS = biexponentialIncrementForPeak( ...
    BACKGROUND.inhPeak_nS*BACKGROUND.inhScale, ...
    BACKGROUND.inhTauRise_ms,BACKGROUND.inhTauDecay_ms);

STIM.eventIncrement_nS = biexponentialIncrementForPeak( ...
    STIM.peak_nS*STIM.scale,STIM.tauRise_ms,STIM.tauDecay_ms);

recExcRiseDecay = exp(-SIM.dt_ms/REC.excTauRise_ms);
recExcDecayDecay = exp(-SIM.dt_ms/REC.excTauDecay_ms);
recInhRiseDecay = exp(-SIM.dt_ms/REC.inhTauRise_ms);
recInhDecayDecay = exp(-SIM.dt_ms/REC.inhTauDecay_ms);

bgExcRiseDecay = exp(-SIM.dt_ms/BACKGROUND.excTauRise_ms);
bgExcDecayDecay = exp(-SIM.dt_ms/BACKGROUND.excTauDecay_ms);
bgInhRiseDecay = exp(-SIM.dt_ms/BACKGROUND.inhTauRise_ms);
bgInhDecayDecay = exp(-SIM.dt_ms/BACKGROUND.inhTauDecay_ms);

stimRiseDecay = exp(-SIM.dt_ms/STIM.tauRise_ms);
stimDecayDecay = exp(-SIM.dt_ms/STIM.tauDecay_ms);

% For sufficiently small dt, Bernoulli p=rate*dt is the fastest online
% approximation to independent Poisson event trains. Using 1-exp(-lambda*dt)
% gives the exact probability of >=1 event in a bin. If rates become so high
% that multiple events/bin matter, decrease dt or use Poisson counts.
bgExcProbability = 1-exp(-BACKGROUND.excRate_Hz*SIM.dt_ms/1000);
bgInhProbability = 1-exp(-BACKGROUND.inhRate_Hz*SIM.dt_ms/1000);
stimProbability = 1-exp(-STIM.rate_Hz*SIM.dt_ms/1000);
% Split the target Poisson rate into shared and private components.
% Combined event probability stays equal to stimProbability.
stimCommonProbability = 1-exp(-STIM.synchrony*STIM.rate_Hz*SIM.dt_ms/1000);
stimPrivateProbability = 1-exp(-(1-STIM.synchrony)*STIM.rate_Hz*SIM.dt_ms/1000);

%% ========================================================================
% INITIAL IZHIKEVICH STATE
% ========================================================================
nSteps = floor(SIM.totalTime_ms/SIM.dt_ms)+1;
V = SIM.initialVoltage_mV*ones(N,1);
a = IZH.aInh*ones(N,1); a(isExc) = IZH.aExc;
b = IZH.bInh*ones(N,1); b(isExc) = IZH.bExc;
c = IZH.cInh*ones(N,1); c(isExc) = IZH.cExc;
d = IZH.dInh*ones(N,1); d(isExc) = IZH.dExc;
u = b.*V;

% Recurrent synaptic bi-exponential states.
recExcRise = zeros(N,1);
recExcDecay = zeros(N,1);
recInhRise = zeros(N,1);
recInhDecay = zeros(N,1);

% External background bi-exponential states.
bgExcRise = zeros(N,1);
bgExcDecay = zeros(N,1);
bgInhRise = zeros(N,1);
bgInhDecay = zeros(N,1);

% Additional external excitatory stimulation states. These vectors are N-long
% so they can be added directly to the total synaptic current, but only L4e
% indices ever receive events.
stimRise = zeros(N,1);
stimDecay = zeros(N,1);

spikeCounts = zeros(N,1,'uint32');

previousSpikes = zeros(0,1,'uint32');
progressEvery = max(1,round((nSteps-1)/max(1,SIM.progressUpdates)));





tSim = tic;

%% ========================================================================
% MAIN SIMULATION LOOP
% ========================================================================
for it=2:nSteps

    % ---- Decay recurrent synaptic states ----
    recExcRise = recExcRise*recExcRiseDecay;
    recExcDecay = recExcDecay*recExcDecayDecay;
    recInhRise = recInhRise*recInhRiseDecay;
    recInhDecay = recInhDecay*recInhDecayDecay;

    % ---- Deliver recurrent synapses from previous-step spikes ----
    if ~isempty(previousSpikes)
        excPostsCell = cell(numel(previousSpikes),1);
        inhPostsCell = cell(numel(previousSpikes),1);
        ne = 0;
        ni = 0;

        for s=1:numel(previousSpikes)
            pre = double(previousSpikes(s));
            if edgeCountByPre(pre)==0
                continue;
            end
            posts = postEdge(edgeStart(pre):edgeStop(pre));
            if isExc(pre)
                ne = ne+1;
                excPostsCell{ne} = posts;
            else
                ni = ni+1;
                inhPostsCell{ni} = posts;
            end
        end

        if ne>0
            posts = double(vertcat(excPostsCell{1:ne}));
            delta = accumarray(posts,REC.excEventIncrement_nS,[N 1],@sum,0);
            recExcRise = recExcRise + delta;
            recExcDecay = recExcDecay + delta;
        end
        if ni>0
            posts = double(vertcat(inhPostsCell{1:ni}));
            delta = accumarray(posts,REC.inhEventIncrement_nS,[N 1],@sum,0);
            recInhRise = recInhRise + delta;
            recInhDecay = recInhDecay + delta;
        end
    end

    % ---- Online Poisson background ----
    % No N x time stimulus is allocated. Only this time bin is generated.
    bgExcRise = bgExcRise*bgExcRiseDecay;
    bgExcDecay = bgExcDecay*bgExcDecayDecay;
    bgInhRise = bgInhRise*bgInhRiseDecay;
    bgInhDecay = bgInhDecay*bgInhDecayDecay;

    if BACKGROUND.enabled
        excEvents = rand(N,1) < bgExcProbability;
        if any(excEvents)
            bgExcRise(excEvents) = bgExcRise(excEvents) + BACKGROUND.excEventIncrement_nS;
            bgExcDecay(excEvents) = bgExcDecay(excEvents) + BACKGROUND.excEventIncrement_nS;
        end

        inhEvents = rand(N,1) < bgInhProbability;
        if any(inhEvents)
            bgInhRise(inhEvents) = bgInhRise(inhEvents) + BACKGROUND.inhEventIncrement_nS;
            bgInhDecay(inhEvents) = bgInhDecay(inhEvents) + BACKGROUND.inhEventIncrement_nS;
        end
    end

    % ---- Additional L4e-only Poisson stimulation ----
    stimRise = stimRise*stimRiseDecay;
    stimDecay = stimDecay*stimDecayDecay;

    if STIM.enabled
        % Shared event is delivered to all L4e neurons; private events are independent.
        commonEvent = rand < stimCommonProbability;
        stimEventsLocal = (rand(nStim,1) < stimPrivateProbability) | commonEvent;
        if any(stimEventsLocal)
            q = stimIdx(stimEventsLocal);
            stimRise(q) = stimRise(q) + STIM.eventIncrement_nS;
            stimDecay(q) = stimDecay(q) + STIM.eventIncrement_nS;
        end
    end

    % ---- Total conductances ----
    gRecExc = recExcDecay-recExcRise;
    gRecInh = recInhDecay-recInhRise;
    gBgExc = bgExcDecay-bgExcRise;
    gBgInh = bgInhDecay-bgInhRise;
    gStim = stimDecay-stimRise;

    % Synaptic currents, positive inward.
    Isyn_pA = ...
        gRecExc.*(REC.excErev_mV-V) + ...
        gRecInh.*(REC.inhErev_mV-V) + ...
        gBgExc.*(BACKGROUND.excErev_mV-V) + ...
        gBgInh.*(BACKGROUND.inhErev_mV-V) + ...
        gStim.*(STIM.Erev_mV-V);

    % ---- Izhikevich RS/FS dynamics (forward Euler) ----
    % Convert pA to Izhikevich current units before adding to qV.
    Iizh = Isyn_pA/IZH.pA_per_current_unit;
    qV = IZH.c2.*V.^2 + IZH.c1.*V + IZH.c0 - u;
    Vnew = V + (SIM.dt_ms/IZH.Cm).*(qV + Iizh);
    unew = u + SIM.dt_ms.*a.*(b.*V-u);

    % A threshold event is one spike; reset voltage and increment recovery.
    spiked = Vnew >= IZH.Vth_mV;
    previousSpikes = uint32(find(spiked));
    Vnew(spiked) = c(spiked);
    unew(spiked) = unew(spiked) + d(spiked);

    if ~isempty(previousSpikes)
        spikeCounts(double(previousSpikes)) = ...
            spikeCounts(double(previousSpikes)) + uint32(1);


    end

    V = Vnew;
    u = unew;

    if mod(it-1,progressEvery)==0 || it==nSteps
        % Suppress per-step progress in parallel workers.
    end
end

simulationSeconds = toc(tSim);


%% ========================================================================
% SUMMARY
% ========================================================================
% Population 5 is L5e. Only its mean firing frequency is returned.
L5eIdx = popStart(5):popStop(5);
L5eMeanRate_Hz = mean(double(spikeCounts(L5eIdx)))/(SIM.totalTime_ms/1000);

out = struct('synchrony',synchrony,'rate_Hz',rateHz,'seed',seed, ...
    'L5eMeanRate_Hz',L5eMeanRate_Hz,'simulationSeconds',simulationSeconds);
if saveIndividual
    filename = fullfile(outputFolder,sprintf('run_%s_%02d_seed_%d.mat',sweepType,conditionIndex,seed));
    save(filename,'out');
end
end

function NET = buildCorticalNetwork(DATA)
%% ========================================================================
% LOAD SMALL NETWORK METADATA ONLY
% ========================================================================
fprintf('Loading cortical network metadata: %s\n',DATA.file);
meta = load(DATA.file,'total_neurons','xxe','xxi','num_neur');

N = double(meta.total_neurons);
xxe = double(meta.xxe(:));
xxi = double(meta.xxi(:));
num_neur = double(meta.num_neur(:)');

assert(sum(num_neur)==N,'sum(num_neur) does not equal total_neurons.');
assert(all(xxe>=1 & xxe<=N) && all(xxi>=1 & xxi<=N));

isExc = false(N,1);
isExc(xxe) = true;
isInh = false(N,1);
isInh(xxi) = true;
assert(~any(isExc & isInh),'A neuron is marked both excitatory and inhibitory.');
assert(all(isExc | isInh),'Some neurons are neither excitatory nor inhibitory.');

populationNames = ["L23e","L23i","L4e","L4i","L5e","L5i","L6e","L6i"];
populationID = zeros(N,1,'uint8');
popStart = cumsum([1 num_neur(1:end-1)]);
popStop = cumsum(num_neur);
for p=1:8
    populationID(popStart(p):popStop(p)) = uint8(p);
end

fprintf('Network: %,d neurons (%d excitatory, %d inhibitory).\n', ...
    N,numel(xxe),numel(xxi));

%% ========================================================================
% CONVERT v7.3 CONNECTIVITY MATRIX TO COMPACT EDGE LISTS
% ========================================================================
% Critical memory optimization: mat_conn is read a few rows at a time.
% We retain only post-neuron indices. Excitatory/inhibitory identity is already
% known from the presynaptic neuron, so the 1/2 matrix values need not remain
% in memory after validation.

fprintf('\nScanning connectivity matrix in blocks of %d rows...\n',DATA.rowBlockSize);
tLoad = tic;
M = matfile(DATA.file,'Writable',false);
info = whos(M,'mat_conn');
assert(~isempty(info),'Variable mat_conn not found in connectivity MAT file.');
assert(isequal(double(info.size),[N N]), ...
    'mat_conn is %d x %d, expected %d x %d.',info.size(1),info.size(2),N,N);

nBlocks = ceil(N/DATA.rowBlockSize);
preCell = cell(nBlocks,1);
postCell = cell(nBlocks,1);

for b=1:nBlocks
    r1 = (b-1)*DATA.rowBlockSize + 1;
    r2 = min(N,b*DATA.rowBlockSize);
    block = M.mat_conn(r1:r2,1:N);
    [rLocal,post,val] = find(block);
    pre = rLocal + r1 - 1;

    if DATA.verifyConnectionCodes && ~isempty(val)
        if any(val~=1 & val~=2)
            error('mat_conn contains a nonzero value other than 1 or 2.');
        end
        expected = ones(size(val));
        expected(isInh(pre)) = 2;
        if any(val~=expected)
            error(['Connection code disagrees with xxe/xxi for at least one ' ...
                   'presynaptic neuron.']);
        end
    end

    preCell{b} = uint32(pre);
    postCell{b} = uint32(post);

    if mod(b,max(1,round(nBlocks/20)))==0 || b==nBlocks
        % Suppress per-block progress in parallel workers.
    end
end

preEdge = vertcat(preCell{:});
postEdge = vertcat(postCell{:});
clear preCell postCell block rLocal post val expected M;

% Sort once by presynaptic neuron. The simulation then accesses only the
% contiguous outgoing edge range of neurons that actually spiked.
[preEdge,order] = sort(preEdge);
postEdge = postEdge(order);
clear order;

edgeCountByPre = accumarray(double(preEdge),1,[N 1],@sum,0);
edgeStart = cumsum([1; edgeCountByPre(1:end-1)]);
edgeStop = edgeStart + edgeCountByPre - 1;

nEdges = numel(postEdge);
fprintf('Loaded %,d directed chemical connections in %.2f s.\n',nEdges,toc(tLoad));
fprintf('Compact edge lists use approximately %.2f MB.\n', ...
    (numel(preEdge)*4 + numel(postEdge)*4)/1024^2);

% preEdge is no longer needed after edgeStart/edgeStop have been built.
clear preEdge;

% L4 excitatory neurons are population 3.
stimIdx = (popStart(3):popStop(3))';
nStim = numel(stimIdx);

NET = struct('N',N,'isExc',isExc,'postEdge',postEdge, ...
    'edgeCountByPre',edgeCountByPre,'edgeStart',edgeStart,'edgeStop',edgeStop, ...
    'stimIdx',stimIdx,'nStim',nStim,'popStart',popStart,'popStop',popStop);
end

function increment = biexponentialIncrementForPeak(peak,tauRise,tauDecay)
    % Return state increment A such that
    % g(t)=A*(exp(-t/tauDecay)-exp(-t/tauRise)) has requested peak.
    assert(tauRise>0 && tauDecay>0 && tauDecay>tauRise, ...
        'Bi-exponential requires tauDecay > tauRise > 0.');
    assert(peak>=0,'Peak conductance must be nonnegative.');
    if peak==0
        increment=0;
        return;
    end
    tPeak = (tauRise*tauDecay/(tauDecay-tauRise))*log(tauDecay/tauRise);
    shapePeak = exp(-tPeak/tauDecay)-exp(-tPeak/tauRise);
    increment = peak/shapePeak;
end
