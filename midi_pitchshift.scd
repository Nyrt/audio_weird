
// pitch shift input - USE HEADPHONES to prevent feedback
MIDIIn.connectAll;


(
SynthDef(\shifter, {
	arg in=1, out=0, ratio=0, grainsize=0.1, pitchdispertion=0, timedispersion=0.004, rate, gate, amp = 0, detune = 0, delay = 0.5, attack=0, decay=0, sustain=1, release=0.01, wet=1, delay_decay = 100;
	var sig, env, pitch;
	pitch = ratio + detune;
	pitch.postln;
	sig = PitchShift.ar(In.ar(in),
		grainsize,
		pitch,
		pitchdispertion,
		timedispersion,
		amp
	);
	env = EnvGen.ar(Env.adsr(attack, decay, sustain,release) , gate, doneAction:2);


	sig = sig + AllpassC.ar(sig, 0.51, delay, 100, wet);

	sig = sig * env;

	Out.ar(out, sig);
}).add;



SynthDef(\mic, {
	arg in = 1, out = 0, wet = 0;
	var sig = SoundIn.ar(in);
	sig = sig + AllpassC.ar(sig, 0.51, 0.5, 10, wet);
	Out.ar(out, sig);
}).add;



SynthDef(\noisegate, {
	arg in = 1, out = 0, thresh, time=2, amp = 1;
	var sig = Compander.ar(In.ar(in), In.ar(in),
		thresh: thresh,
		slopeBelow: 10,
		slopeAbove: 1,
		clampTime: time,
		relaxTime: 0.1
	) * amp;
	Out.ar(out, sig);
}).add;



SynthDef(\stereo, {
	arg in, out=0;
	var sig = In.ar(in);
	Out.ar(out, [sig, sig]);
}).add;



SynthDef(\delay, {
	arg in, out, delay, decay, mix = 1;
	var sig = In.ar(in);
	sig = sig + AllpassC.ar(sig, 5, delay, decay, mix);
	Out.ar(out, sig);
}).add;
);

(
~input = Bus.audio(s, 1);

~fx_1 = Bus.audio(s, 1);

~fx_2 = Bus.audio(s, 1);

~fx_3 = Bus.audio(s, 1);

);
~fx_1.scope();


(
// t = Synth.new(\shiftCtrl, [out:p]);

~preprocessing = Group.new();

~keyboard = Group.after(~preprocessing);

~postprocessing = Group.after(~keyboard);

m = Synth.new(\mic, [in:0, out:~input], ~preprocessing);

~gated = Synth.new(\noisegate, [in: ~input, out:  ~fx_1, thresh: 0.0], ~preprocessing, 'addToTail');

// ~thru = Synth.new(\noisegate, [in: ~input, out:  ~fx_2, thresh: 0.0, amp:0.3], ~keyboard);

~delay = Synth.new(\delay, [in:~fx_2, out:~fx_3], ~postprocessing);

~stereo_out = Synth.new(\stereo, [in:~fx_3], ~postprocessing, 'addToTail');
);


(
MIDIdef.freeAll;
~chanMap = Dictionary.new();

~wet=0;

MIDIdef(\noteOn, {// strike
	arg vel, note, channel;
	var out, synth;
	synth = ~chanMap[channel];
	if (synth != Nil, {synth.set(\gate, 0); ~chanMap.removeAt(channel);});
	~chanMap.put(channel, Synth(\shifter, [in:  ~fx_1, out: ~fx_2, ratio: (note-60).midiratio, gate:1, wet:~wet], ~keyboard));
}, msgType: \noteOn);

MIDIdef(\noteOff, {// lift
	arg vel, note, channel;
	var synth = ~chanMap[channel];
	if(synth != Nil, {
		synth.set(\release, vel.linlin(0,127, 5, 0));
		synth.set(\gate, 0);
	});
}, msgType: \noteOff);

MIDIdef(\touch, {// press
	arg pressure, channel;
	var synth = ~chanMap[channel];
	// pressure.postln;
	if(synth != Nil, {
		synth.get(\note, {arg note;
			synth.set(\amp, pressure.linlin(0,127,0,1));
		});
	});
}, msgType: \touch);

MIDIdef(\bend, {// Glide
	arg bend, channel;
	var synth = ~chanMap[channel];
	bend = (bend - 8192)/170/24;
	if(synth != Nil, {synth.set(\detune, bend)});
}, msgType: \bend);

MIDIdef(\slide, {// Slide
	arg value, cc, channel;
	var synth = ~chanMap[channel];
	if(synth != Nil, {
		synth.get(\note, {arg note;
			// synth.set(\delay_decay, value.linlin(0,127,0.0, 20));
		});
	});
}, 74, msgType: \control);

MIDIdef(\slider1, {// Slider 1
	arg value, cc, channel;

	// value.postln;
	m.set(\wet, value.linlin(0,127,0.0, 1));
}, 107, msgType: \control);

MIDIdef(\slider2, {// Slider 2
	arg value, cc, channel;

	value = value.linlin(0,127,0.0, 0.38);
	value.postln;


	~chanMap.values.collect(_.set(\wet, value));

	~wet = value;

}, 109, msgType: \control);

MIDIdef(\slider3, {// Slider 3
	arg value, cc, channel;
	// value.postln;
	~delay.set(\mix, value.linlin(0,127,0.0, 1));
}, 111, msgType: \control);
);

/*************************** PRESETS ***************************/


// Add delay
~delay.set(\delay,2);~delay.set(\decay,0);

// Add delay with feedback
~delay.set(\delay,0.5);~delay.set(\decay,10);


// no delay
// ~delay.set(\delay,0);~delay.set(\decay,0);

~keyboard.freeAll;