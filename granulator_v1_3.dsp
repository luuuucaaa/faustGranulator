import("stdfaust.lib");

// TODO

// - implement noise and a randomness parameter to each slider [] 
// - implement randomness to 
// - implement gaussian amplitude envelope [] 
// - implement grain speed control [] 
// - implement imput selector []
// - implement reverb [x]
// - implement more reverb controlls [x]

// User Interface

n_grains_slider      =  vslider("v:[-1]Granulator/h:[0]/v:[1]/[0]grain number", 1, 1, max_n_grains, 1);
delay_length_slider  =  vslider("v:[-1]Granulator/h:[0]/v:[2]/[1]delay length[unit:s]", 1, 0.5, 1, 0.1);
grain_length_slider  =  vslider("v:[-1]Granulator/h:[0]/v:[3]/[2]grain length [unit:s]", 0.1, 0.01, 1.5, 0.01);

rand_delay_slider    =  vslider("v:[-1]Granulator/h:[1]/v:[0]/[0]rand delay[unit:%][style:knob]", 1, 1, 100, 1);
rand_length_slider   =  vslider("v:[-1]Granulator/h:[1]/v:[1]/[0]rand length[unit:%][style:knob]", 0, 0, 100, 1);

reverb_spread_slider =  vslider("v:[0]Effects/h:[0]/v:[0]/[0]Reverb Spread[unit:%][style:knob]", 0, 0, 100, 1);
dry_wet              =  vslider("v:[0]Effects/h:[0]/v:[1]/[1]Dry Wet[style:knob]", 0.4, 0, 1, 0.001);
filter_cuttoff       =  vslider("v:[0]Effects/h:[0]/v:[2]/[2]HPF[unit:Hz][style:knob]", 100, 100, 10000, 1);

// Global Variables

SR = 48000; // sampling rate
counter = + (1) % delay_length ~ _; // to iterate through the delay line (delay length between grains?)
max_n_grains = 20;

// Delay line (buffer)

buffer_size = int(SR) * 1; //buffer of 1s

delay_length = int(delay_length_slider * SR); // scale delay length to seconds

//delay_length = int(delay_length_slider * SR + (no.noise:ba.downSample(20):si.smooth(0.8) * SR * rand_delay_slider/200)); // delay length with randomness

buffer(write, read, x) = rwtable(buffer_size, 0.0, write % delay_length, x, read % delay_length); // input buffer

// Sample and Hold

SH(trig, x) = ( * (1 - trig) + x * trig) ~ _;

// Multi Channel Noise Generator

S(1,F) = F;
S(i,F) = F <: S(i-1,F),_ ;
Divide(n,k) = par(i, n, /(k)) ;
random = +(12345) : *(1103515245) ;
RANDMAX = 2^32 - 1 ;
chain(n) = S(n,random) ~ _;
NoiseN(n) = chain(n) : Divide(n,RANDMAX);

noiser = NoiseN(max_n_grains+1);                  

NoiseChan(n,0) = noiser:>_,par( j, n-1 , !);
NoiseChan(n,i) = noiser:>par( j, i , !) , _, par( j, n-i-1,!);

noise(i) = (NoiseChan(max_n_grains+1,i) + 1) / 2; //get nth channel of multi-channel noiser


// Grains

grain_length = int(grain_length_slider * SR); // scale delay length to samples

// grain_length = int(grain_length_slider * SR + no.noise * SR/2 * (rand_length_slider/100); // grain length with randomness, but not working

grain_offset(i) = int(SH(1 - 1', int(delay_length)));
grain_counter_master = + (1) % grain_length ~ _; // universal counter for all grains
grain_counter(i) = (grain_counter_master + grain_offset(i)) % grain_length;
grain_random_pos(i) = int(SH(int(grain_counter(i) / (grain_length - 1)), int(delay_length)*noise(i)));
grain_position(i) = grain_counter(i) + grain_random_pos(i);

// Window

window(i) = sin(2 * 3.14159 * grain_counter(i) / (grain_length - 1));

// Effects

reverb = _,_ <: (*(dry_wet)*fixedgain,*(dry_wet)*fixedgain : 
    re.stereo_freeverb(0.5, 0.5, 0.5, reverb_spread_slider)),
    *(1 - dry_wet), *(1 - dry_wet) :> _,_
    with {
        fixedgain   = 0.1;
        
    }; // stereo reverb with dry/wet implementation

hpf_filter =  _,_: (fi.highpass(filter_order,filter_cuttoff)),(fi.highpass(filter_order,filter_cuttoff)):_,_
    with {
        filter_order = 1;
    }; //stereo hpf 

// Process Function

process = _<:par(i, max_n_grains, buffer(counter, grain_position(i)) * window(i) * (i < n_grains_slider) / n_grains_slider):> reverb :> hpf_filter;
