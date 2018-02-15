(
// pitch shift input - USE HEADPHONES to prevent feedback.


play({
	PitchShift.ar(
		AudioIn.ar([1,2]),	// stereo audio input
		0.1, 			// grain size
		0.5,	// mouse x controls pitch shift ratio
		0, 				// pitch dispersion
		0.004			// time dispersion
	)
}))