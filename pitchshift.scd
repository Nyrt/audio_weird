
// pitch shift input - USE HEADPHONES to prevent feedback


(
SynthDef(\shifter, {
	arg in=1, out=0, ratio, grainsize=0.1, pitchdispertion=0, timedispersion=0.004, rate;
	var sig = PitchShift.ar(In.ar(in),
		grainsize,
		In.kr(ratio, 1),
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
}
).add;
);


~input = Bus.audio(s, 1);

~fx_1 = Bus.audio(s, 1);

~fx_2 = Bus.audio(s, 1);

~master = Bus.audio(s,1);

~h1_pitch = Bus.control(s, 1);

~h2_pitch = Bus.control(s, 1);

~master.scope();

// t = Synth.new(\shiftCtrl, [out:p]);

m = Synth.new(\mic, [in:1, out:~input]);

~gated = Synth.after(m, \noisegate, [in: ~input, out:  ~fx_1, thresh: 0.1]);

~h1 = Synth.after(~gated, \shifter, [in:  ~fx_1, out: ~fx_2, ratio: ~h1_pitch]);

~h2 = Synth.after(~h1, \shifter, [in:  ~fx_1, out: ~fx_2, ratio: ~h2_pitch]);

 ~stereo_out = Synth.after(~h2, \stereo, [in:~fx_2]);



/*************************** PRESETS ***************************/
// Octaves
~h1_pitch.set(-12.midiratio);~h2_pitch.set(12.midiratio);

// Major chord, no inversion
~h1_pitch.set(4.midiratio);~h2_pitch.set(7.midiratio);

// Minor chord, 1st inversion
~h1_pitch.set(-5.midiratio);~h2_pitch.set(3.midiratio);
