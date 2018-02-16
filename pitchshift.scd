
// pitch shift input - USE HEADPHONES to prevent feedback


(
SynthDef(\shifter, {
	arg in=1, out=0, ratio, grainsize=0.1, pitchdispertion=0, timedispersion=0.004, rate;
	var sig = PitchShift.ar(In.ar(in),
		grainsize,
		ratio,
		pitchdispertion,
		timedispersion
	);
	Out.ar(out, sig);
}).add;
);

(
SynthDef(\mic, {
	arg in = 1, out = 0;
	Out.ar(out, SoundIn.ar(in));
}).add;
);

(
SynthDef(\noisegate, {
	arg in = 1, out = 0, thresh, time=0.1;
	var sig = Compander.ar(In.ar(in), In.ar(in),
		thresh: thresh,
		slopeBelow: 10,
		slopeAbove: 1,
		clampTime: time,
		relaxTime: 0.1
	);
	Out.ar(out, sig);
}).add;
);

(
SynthDef(\stereo, {
	arg in, out=0;
	var sig = In.ar(in);
	Out.ar(out, [sig, sig]);
}).add;
);

(
SynthDef(\delay, {
	arg in, out, delay, decay;
	var sig = AllpassC.ar(In.ar(in), 5, delay, decay);
	Out.ar(out, sig);
}).add;
);

~input = Bus.audio(s, 1);

~fx_1 = Bus.audio(s, 1);

~fx_2 = Bus.audio(s, 1);

~fx_3 = Bus.audio(s, 1);

// [delay, decay]
~delay_params = Bus.control(s, 2);

~input.scope();

// t = Synth.new(\shiftCtrl, [out:p]);

m = Synth.new(\mic, [in:0, out:~input]);

~gated = Synth.after(m, \noisegate, [in: ~input, out:  ~fx_1, thresh: 0.0]);

~h1 = Synth.after(~gated, \shifter, [in:  ~fx_1, out: ~fx_2, ratio: 0]);

~h2 = Synth.after(~h1, \shifter, [in:  ~fx_1, out: ~fx_2, ratio: 0]);

~delay = Synth.after(~h2, \delay, [in:~fx_2, out:~fx_3, delay:0, decay:0]);

 ~stereo_out = Synth.after(~delay, \stereo, [in:~fx_3]);



/*************************** PRESETS ***************************/
// Octaves

~h1.set(\ratio,-12.midiratio);~h1.set(\ratio,12.midiratio);


//
// // Major chord, no inversion
~h1.set(\ratio,4.midiratio);~h1.set(\ratio,7.midiratio);

// // Minor chord, 1st inversion
~h1.set(\ratio,-5.midiratio);~h1.set(\ratio,3.midiratio);

// no delay
~delay.set(\delay,0);~delay.set(\decay,0);

// Add delay
~delay.set(\delay,2);~delay.set(\decay,0);

// Add delay with feedback
~delay.set(\delay,0.5);~delay.set(\decay,10);

