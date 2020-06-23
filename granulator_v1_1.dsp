import("stdfaust.lib");

// TODO

// - implement noise and a randomness parameter to each slider [] 
// - implement gaussian amplitude envelope [] 
// - implement grain speed control [] 
// - implement imput selector []
// - implement reverb [x]
// - implement more reverb controlls []


// interface

n_grains_slider =       vslider("h:Granulator/ [0]grain number", 1, 1, max_n_grains, 1);
delay_length_slider =   vslider("h:Granulator/ [1]delay length (s)", 1, 0.5, 1, 0.1);
grain_length_slider =   vslider("h:Granulator/ [2]grain length (s)", 0.1, 0.01, 1.5, 0.01);

reverb_spread_slider =  vslider("h:Effects/ Reverb Spread[style:knob]", 0, 0, 100, 1);


// global variables
SR = 48000; // sampling rate
counter = + (1) % delay_length ~ _; // to iterate through the delay line

// Delay line (buffer)
buffer_size = int(SR) * 1; //buffer of 1s

delay_length = int(delay_length_slider * SR);

buffer(write, read, x) = rwtable(buffer_size, 0.0, write % delay_length, x, read % delay_length);

// Sample and hold
SH(trig, x) = ( * (1 - trig) + x * trig) ~ _;


// Grains
max_n_grains = 10;
grain_length = int(grain_length_slider * SR);

grain_offset(i) = int(SH(1 - 1', int(delay_length)));
grain_counter_master = + (1) % grain_length ~ _;
grain_counter(i) = (grain_counter_master + grain_offset(i)) % grain_length;
grain_random_pos(i) = int(SH(int(grain_counter(i) / (grain_length - 1)), int(delay_length)));
grain_position(i) = grain_counter(i) + grain_random_pos(i);

// Window
window(i) = sin(2 * 3.14159 * grain_counter(i) / (grain_length - 1));

// Noise Generator

// no.noise

// process function
process = _<:par(i, max_n_grains, buffer(counter, grain_position(i)) * window(i) * (i < n_grains_slider) / n_grains_slider):> _, _: re.stereo_freeverb(0.5, 0.5, 0.5, reverb_spread_slider) : _,_;
