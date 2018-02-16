
// pitch shift input - USE HEADPHONES to prevent feedback


(
SynthDef(\shifter, {
	arg in=1, out=0, ratio, grainsize=0.1, pitchdispertion=0, timedispersion=0.004, rate, gate;
	var sig, env;
	sig = PitchShift.ar(In.ar(in),
		grainsize,
		ratio,
		pitchdispertion,
		timedispersion
	);
	env = EnvGen.ar(Env.adsr(), gate, doneAction:2);
	sig = sig * env;

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

(
~input = Bus.audio(s, 1);

~fx_1 = Bus.audio(s, 1);

~fx_2 = Bus.audio(s, 1);

~fx_3 = Bus.audio(s, 1);

~fx_2.scope();
);

(
// t = Synth.new(\shiftCtrl, [out:p]);

~preprocessing = Group.new();

~keyboard = Group.after(~preprocessing);

~postprocessing = Group.after(~keyboard);

m = Synth.new(\mic, [in:0, out:~input], ~preprocessing);

~gated = Synth.new(\noisegate, [in: ~input, out:  ~fx_1, thresh: 0.0], ~preprocessing, 'addToTail');

~delay = Synth.new(\delay, [in:~fx_2, out:~fx_3, params:~delay_params], ~postprocessing);

~stereo_out = Synth.new(\stereo, [in:~fx_3], ~postprocessing, 'addToTail');
);

(
MIDIdef.freeAll;
~chanMap = Dictionary.new();

MIDIdef(\noteOn, {// strike
	arg vel, note, channel;
	var out, synth;
	synth = ~chanMap[channel];
	if (synth != Nil, {	/*synth.free;*/ ~chanMap.removeAt(channel);});
	~chanMap.put(channel, Synth(\shifter, [in:  ~fx_1, out: ~fx_2, ratio: (note-60).midiratio, gate:1], ~keyboard));
}, msgType: \noteOn);

MIDIdef(\noteOff, {// lift
	arg vel, note, channel;
	var synth = ~chanMap[channel];
	if(synth != Nil, {
		synth.set(\release, vel.linlin(0,127, 2, 0));
		synth.set(\gate, 0);
	});
}, msgType: \noteOff);

MIDIdef(\touch, {// press
	arg pressure, channel;
	var synth = ~chanMap[channel];
	if(synth != Nil, {
		synth.get(\note, {arg note;
			synth.set(\lfofreq, pressure.linexp(0,127,4,note));
		});
	});
}, msgType: \touch);

MIDIdef(\bend, {// Glide
	arg bend, channel;
	var synth = ~chanMap[channel];
	// if(synth != Nil, {synth.set(\detune, bend/10)});
}, msgType: \bend);

MIDIdef(\control, {// Slide
	arg value, cc, channel;
	var synth = ~chanMap[channel];
	if(synth != Nil, {
		synth.get(\note, {arg note;
			synth.set(\lfofreq, value.linexp(0,127,4,note));
		});
	});
}, msgType: \control);
);

/*************************** PRESETS ***************************/
// no delay
~delay.set(\delay,0);~delay.set(\decay,0);

// Add delay
~delay.set(\delay,2);~delay.set(\decay,0);

// Add delay with feedback
~delay.set(\delay,0.5);~delay.set(\decay,10);



