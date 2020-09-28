// USER INTERFACE //
grainbufferSizeSlider = hslider("Grain Size", 1000, 1000, 10000, 1); // grain size in samples
delayLengthSlider = hslider("Delay Length", 1000, 1000, 10000, 1); // delay length in samples

// CODE //
SR = 44100; // samplerate in samples per second
N = 10; // numbers of grains

bufferSize = SR; // size of input buffer in samples
bufferCounter = + (1) % bufferSize ~ _; // counter to cycle through the input buffer from 0 to bufferSize
delayLength = delayLengthSlider; // set delay length with delay length slider

grainbufferSize = grainbufferSizeSlider; // size of grainbuffer in samples
grainbufferCounter = + (1) % grainbufferSize ~ _; // counter to cycle through the grains from 0 to grainSize

SH(trigger, signal) = ( * (1 - trigger) + signal * trigger) ~ _; // sample and hold function definiton for grain offset
grainOffset(i) = int(SH(1 - 1', int(delayLength))); // delay length between grains
grainCounter(i) = (grainbufferCounter + grainOffset(i)) % grainbufferSize; // grain-specific grain counter

buffer(writeIndex, readIndex, signal) = rwtable(bufferSize, 0.0, int(writeIndex % delayLength), signal, int(readIndex % delayLength)); // function definition of cycling buffer

window(i) = sin(2 * 3.14159 * grainCounter(i) / (grainbufferSize - 1)); // window function

// PROCESS //
process = _ <: par(i, N, buffer(int(bufferCounter), int(grainCounter(i)), _) * window(i) * (i < N) / N) :> _ <: _, _;