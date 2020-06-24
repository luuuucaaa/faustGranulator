import("stdfaust.lib");

// TODO

// - implement noise and a randomness parameter to each slider [] 
// - implement gaussian amplitude envelope [] 
// - implement grain speed control [] 
// - implement imput selector []
// - implement reverb [x]
// - implement more reverb controlls []

// User Interface

n_grains_slider =       vslider("h:Granulator/ [0] grain number", 1, 1, max_n_grains, 1);
delay_length_slider =   vslider("h:Granulator/ [1] delay length (s)", 1, 0.5, 1, 0.1);
grain_length_slider =   vslider("h:Granulator/ [2] grain length (s)", 0.1, 0.01, 1.5, 0.01);

reverb_spread_slider =  vslider("h:Effects/ [0] Reverb Spread [style:knob]", 0, 0, 100, 1);
dry_wet =               vslider("h:Effects/ [1] Dry/Wet [style:knob]", 0.4, 0, 1, 0.001);
filter_cuttoff =        vslider("h:Effects/ [2] HPF [style:knob]", 100, 100, 10000, 1);

// Global Variables

SR = 48000; // sampling rate
counter = + (1) % delay_length ~ _; // to iterate through the delay line
max_n_grains = 10;

// Delay line (buffer)

buffer_size = int(SR) * 1; //buffer of 1s

delay_length = int(delay_length_slider * SR);

buffer(write, read, x) = rwtable(buffer_size, 0.0, write % delay_length, x, read % delay_length);

// Sample and Hold

SH(trig, x) = ( * (1 - trig) + x * trig) ~ _;

// Grains

grain_length = int(grain_length_slider * SR);

grain_offset(i) = int(SH(1 - 1', int(delay_length)));
grain_counter_master = + (1) % grain_length ~ _; // universal counter for all grains
grain_counter(i) = (grain_counter_master + grain_offset(i)) % grain_length;
grain_random_pos(i) = int(SH(int(grain_counter(i) / (grain_length - 1)), int(delay_length)));
grain_position(i) = grain_counter(i) + grain_random_pos(i);

// Window

window(i) = sin(2 * 3.14159 * grain_counter(i) / (grain_length - 1));

// Effects

reverb = _,_ <: (*(dry_wet)*fixedgain,*(dry_wet)*fixedgain :
    re.stereo_freeverb(0.5, 0.5, 0.5, reverb_spread_slider)),
    *(1 - dry_wet), *(1 - dry_wet) :> _,_
    with {
        fixedgain   = 0.1;
        
    };

hpf_filter =  _,_: (fi.highpass(filter_order,filter_cuttoff)),(fi.highpass(filter_order,filter_cuttoff)):_,_
    with {
        filter_order = 1;
    };

// Process Function

process = _<:par(i, max_n_grains, buffer(counter, grain_position(i)) * window(i) * (i < n_grains_slider) / n_grains_slider):> reverb :> hpf_filter;
