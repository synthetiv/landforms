Engine_Blips : CroneEngine {

	var group;
	var controlBus;
	var voices;
	classvar def;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	*initClass {

		StartUp.add({

			def = SynthDef.new(\fm_blip, {

				var trigger = \trigger.tr;
				// bend should be proportional to something like:
				// (source_distance · previous_source_distance)
				var frequency = \frequency.kr(220) * \bend.kr(1);
				var modulator_env = Env.perc(\modulator_attack.kr(0.001), \modulator_release.kr(1));
				var carrier_env = Env.perc(\carrier_attack.kr(0.001), \carrier_release.kr(1.2));

				var modulator = SinOsc.ar(
					freq: frequency * \modulator_ratio.kr(2.01),
					phase: LocalIn.ar * \feedback_index.kr(0.3) * 2pi
				) * EnvGen.ar(modulator_env, trigger);

				var carrier = SinOsc.ar(
					freq: frequency * \carrier_ratio.kr(0.25),
					phase: modulator * \modulation_index.kr(0.1) * 2pi
				) * EnvGen.ar(carrier_env, trigger);

				// HF rolloff should increase the farther away and farther behind the
				// listener the sound source is -- something like:
				// 1 / (listener_heading · source_distance)
				var dimmed = OnePole.ar(carrier, \rolloff.kr(0).clip(0, 1) * 0.5);

				// pan should be negative when source is CCW from listener's heading:
				// (listener_heading x source_distance)
				var panned = Pan2.ar(dimmed, \pan.kr(0));

				// feedback send, either from modulator or carrier
				LocalOut.ar(Select.ar(\feedback_source.kr(1), [modulator, carrier]));

				Out.ar(\out.kr(0), panned * \amplitude.kr(0.5).clip(0, 1) * -12.dbamp);
			});

			CroneDefs.add(def);
		});
	}

	alloc {

		group = Group.new(context.server);
		voices = Dictionary.new;

		context.server.sync;

		this.addCommand("add_voice", "i", { |msg|
			var id = msg[1] - 1;
			if(voices[id].isNil, {
				voices.add(id -> Synth.new(\fm_blip, target: group));
				NodeWatcher.register(voices[id]);
				voices[id].onFree({
					voices.removeAt(id);
				});
			});
		});

		this.addCommand("free_voice", "i", { |msg|
			var id = msg[1] - 1;
			if(voices[id].notNil, {
				voices[id].free;
			});
		});

		this.addCommand("blip", "iifffff", { |msg|
			var id = msg[1] - 1;
			// update values
			voices[id].set(
				\trigger, msg[2],
				\frequency, msg[3],
				\bend, msg[4],
				\pan, msg[5],
				\amplitude, msg[6],
				\rolloff, msg[7]
			);
		});

		def.allControlNames.do({ |control|
			var name = control.name;
			if(name != "out", {
				this.addCommand("set_" ++ name, "if", { |msg|
					var id = msg[1] - 1;
					voices[id].set(name.asSymbol, msg[2]);
				});
			});
		});
	}

	free {
		group.free;
	}
}