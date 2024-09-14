import std/unittest, playdate/api

proc execMidiTests*(runnable: bool) =
    suite "Loading midi files":

        test "Creating sequences from files":
            if runnable:
                var sq = playdate.sound.sequence.newSequence()
                sq.loadMIDIFile("deliberate_concealment.mid")

                sq.setTime(sq.getTime)

                check(sq.getLength == 132961)
                check(sq.getCurrentStep() == 0)

                check(sq.getTempo() == 831.9986572265625)
                sq.setTempo(900.0)
                check(sq.getTempo() == 900.0)

                check(not sq.isPlaying)
                sq.play
                check(sq.isPlaying)
                sq.stop
                check(not sq.isPlaying)


execMidiTests(false)