<h1>Large-Scale Human Cortical Network Simulation</h1>

<p>
This repository contains MATLAB code to generate a large-scale human cortical
connectivity matrix and to simulate population firing dynamics using
conductance-based synapses and Izhikevich neuron models under asynchronous and
synchronous input conditions.
</p>

<p>
The simulations explore how different levels of input synchrony modulate
network firing rates in a biologically inspired excitatory–inhibitory cortical
network.
</p>

<hr>

<h2>Repository Contents</h2>

<h3>1. Connectivity_matrix_Human.m</h3>

<p>
Generates a large-scale connectivity matrix representing a simplified human
cortical microcircuit with excitatory and inhibitory populations.
</p>

<p><strong>Key features:</strong></p>
<ul>
  <li>Total neurons: <strong>80,000</strong></li>
  <li>Six neuronal populations:
    <ul>
      <li>L2e (Layer 2 excitatory)</li>
      <li>L3ae (Layer 3a excitatory)</li>
      <li>L3be (Layer 3b excitatory)</li>
      <li>L4e (Layer 4 excitatory)</li>
      <li>L5e (Layer 5 excitatory)</li>
      <li>Inh (Inhibitory interneurons)</li>
    </ul>
  </li>
  <li>Layer-specific connection probabilities</li>
  <li>Synapse encoding:
    <ul>
      <li><code>0</code> → no connection</li>
      <li><code>1</code> → excitatory connection</li>
      <li><code>2</code> → inhibitory connection</li>
    </ul>
  </li>
  <li>Self-connections removed</li>
  <li>Saved in sparse-compatible MATLAB format</li>
</ul>

<p><strong>Output file:</strong></p>
<pre>conn_matrix_human_80000.mat</pre>

<p><strong>Variables saved:</strong></p>
<ul>
  <li><code>mat_conn</code> – connectivity matrix</li>
  <li><code>total_neurons</code> – total neuron count</li>
  <li><code>num_neur</code> – neurons per population</li>
  <li><code>xxe</code> – excitatory neuron indices</li>
  <li><code>xxi</code> – inhibitory neuron indices</li>
</ul>

<hr>

<h3>2. FI_human_var_input.m</h3>

<p>
Simulates large-scale spiking network activity using the connectivity matrix
generated above.
</p>

<p><strong>Model details:</strong></p>
<ul>
  <li>Neuron model: <strong>Izhikevich</strong></li>
  <li>Regular Spiking (RS) excitatory neurons</li>
  <li>Fast Spiking (FS) inhibitory neurons</li>
  <li>Conductance-based synapses:
    <ul>
      <li>AMPA (excitatory)</li>
      <li>GABA<sub>A</sub> (inhibitory)</li>
    </ul>
  </li>
  <li>Sparse connectivity for computational efficiency</li>
</ul>

<p><strong>Simulation conditions:</strong></p>
<ul>
  <li>Simulation duration: 500 ms</li>
  <li>Time step: 0.1 ms</li>
  <li>Input amplitudes: 1–10 (arbitrary units)</li>
  <li>Three stimulation regimes:
    <ol>
      <li>Asynchronous input</li>
      <li>Synchronous input (level 2)</li>
      <li>Synchronous input (level 4)</li>
    </ol>
  </li>
</ul>

<p>
External stimulus waveforms are loaded from precomputed files:
</p>
<pre>sparse_synchro_act_*.mat</pre>

<hr>

<h2>Outputs</h2>

<p>
The simulations compute average population firing rates and relative changes in
firing frequency across stimulation conditions.
</p>

<p><strong>Saved result files:</strong></p>
<pre>
mat_freq_human_var_input_80000.mat
  - mat_freq_asyn
  - mat_freq_synch_2
  - mat_freq_synch_4

relat_freq_human_var_input_80000.mat
  - rel_freq1  (% change: synchronous 2 vs asynchronous)
  - rel_freq2  (% change: synchronous 4 vs asynchronous)
</pre>

<p>
Generated figures include connectivity matrix visualizations, firing rate
curves, and relative frequency modulation plots.
</p>

<hr>

<h2>How to Run</h2>

<ol>
  <li>Generate the connectivity matrix:
    <pre>run Connectivity_matrix_Human.m</pre>
  </li>
  <li>Run the network simulations:
    <pre>run FI_human_var_input.m</pre>
  </li>
</ol>

<p>
<strong>Important:</strong> Ensure the following files are available in the
working directory:
</p>
<ul>
  <li><code>conn_matrix_human_80000.mat</code></li>
  <li><code>sparse_synchro_act_*.mat</code></li>
  <li><code>biexp.m</code> (bi-exponential synapse function)</li>
</ul>

<hr>

<h2>Computational Notes</h2>

<ul>
  <li>Simulations are computationally intensive due to network size</li>
  <li>Parallelization using <code>parpool</code> is supported but optional</li>
  <li>Using sparse matrices is essential for performance</li>
</ul>

<hr>

<h2>Dependencies</h2>

<ul>
  <li>MATLAB (R2020a or later recommended)</li>
  <li>Parallel Computing Toolbox (optional)</li>
</ul>

<hr>


