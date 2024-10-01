{.push raises: [].}

import std/[importutils, macros]
import bindings/sound
import bindings/api
import system

# Only export public symbols, then import all
export sound
{.hint[DuplicateModuleImport]: off.}
import bindings/sound {.all.}

# AudioSample
type 
    AudioSampleObj {.requiresinit.} = object
        resource: AudioSamplePtr
    AudioSample* = ref AudioSampleObj

    PDSoundCallbackFunction* = proc(userData: pointer) {.raises: [].}

proc `=destroy`(this: var AudioSampleObj) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSample)
    playdate.sound.sample.freeSample(this.resource)

proc newAudioSample*(this: ptr PlaydateSound, bytes: int32): AudioSample =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSample)
    result = AudioSample(resource: this.sample.newSampleBuffer(bytes))

proc newAudioSample*(this: ptr PlaydateSound, path: string): AudioSample {.raises: [IOError].} =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSample)
    let resource = this.sample.load(path.cstring)
    if resource == nil:
        raise newException(IOError, fmt"file {path} not found: No such file")
    result = AudioSample(resource: resource)

proc load*(this: AudioSample, path: string) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSample)
    discard playdate.sound.sample.loadIntoSample(this.resource, path.cstring)

proc getLength*(this: AudioSample): float32 =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSample)
    return playdate.sound.sample.getLength(this.resource).float32

# AudioSource
type SoundSourceObj {.requiresinit.} = object of RootObj
    resource: pointer
type SoundSource* = ref SoundSourceObj

# FilePlayer
type
    FilePlayerObj = object of SoundSourceObj
        finishCallback: PDFilePlayerCallbackFunction
    FilePlayer* = ref FilePlayerObj

    PDFilePlayerCallbackFunction* = proc(player: FilePlayer) {.raises: [].}

proc `=destroy`(this: var FilePlayerObj) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.freePlayer(this.resource)

proc newFilePlayer*(this: ptr PlaydateSound): FilePlayer =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    result = FilePlayer(resource: this.fileplayer.newPlayer(), finishCallback: nil)

proc newFilePlayer*(this: ptr PlaydateSound, path: string): FilePlayer {.raises: [IOError].} =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    result = FilePlayer(resource: this.fileplayer.newPlayer(), finishCallback: nil)
    if this.fileplayer.loadIntoPlayer(result.resource, path.cstring) == 0:
        raise newException(IOError, fmt"file {path} not found: No such file")

proc load*(this: FilePlayer, path: string) {.raises: [IOError].} =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    if playdate.sound.fileplayer.loadIntoPlayer(this.resource, path.cstring) == 0:
        raise newException(IOError, fmt"file {path} not found: No such file")

proc play*(this: FilePlayer, repeat: int) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    discard playdate.sound.fileplayer.play(this.resource, repeat.cint)

proc isPlaying*(this: FilePlayer): bool =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    return playdate.sound.fileplayer.isPlaying(this.resource) == 1

proc pause*(this: FilePlayer) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.pause(this.resource)

proc stop*(this: FilePlayer) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.stop(this.resource)

proc volume*(this: FilePlayer): tuple[left: float32, right: float32] =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    var left, right: cfloat
    playdate.sound.fileplayer.getVolume(this.resource, addr left, addr right)
    return (left: left.float32, right: right.float32)

proc `volume=`*(this: FilePlayer, volume: float32) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.setVolume(this.resource, volume.cfloat, volume.cfloat)

proc setVolume*(this: FilePlayer, left: float32, right: float32) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.setVolume(this.resource, left.cfloat, right.cfloat)

proc getLength*(this: FilePlayer): float32 =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    return playdate.sound.fileplayer.getLength(this.resource).float32

proc offset*(this: FilePlayer): float32 =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    return playdate.sound.fileplayer.getOffset(this.resource).float32

proc `offset=`*(this: FilePlayer, offset: float32) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.setOffset(this.resource, offset.cfloat)

proc privateFilePlayerFinishCallback(soundSource: SoundSourcePtr, userdata: pointer) {.cdecl, raises: [].} =
    let filePlayer = cast[FilePlayer](userdata)
    if filePlayer.finishCallback != nil:
        filePlayer.finishCallback(filePlayer)

proc setFinishCallback*(this: FilePlayer, callback: PDFilePlayerCallbackFunction) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    this.finishCallback = callback
    if callback == nil:
        playdate.sound.fileplayer.setFinishCallback(this.resource, nil, nil)
    else:
        playdate.sound.fileplayer.setFinishCallback(this.resource, privateFilePlayerFinishCallback, cast[pointer](this))

proc finishCallback*(this: FilePlayer): PDFilePlayerCallbackFunction =
    return this.finishCallback

proc `finishCallback=`*(this: FilePlayer, callback: PDFilePlayerCallbackFunction) =
    this.setFinishCallback(callback)

# SamplePlayer
type
    SamplePlayerObj = object of SoundSourceObj
        sample: AudioSample
        finishCallback: PDSamplePlayerCallbackFunction
    SamplePlayer* = ref SamplePlayerObj

    PDSamplePlayerCallbackFunction* = proc(player: SamplePlayer) {.raises: [].}

proc `=destroy`(this: var SamplePlayerObj) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.freePlayer(this.resource)
    this.sample = nil

proc newSamplePlayer*(this: ptr PlaydateSound): SamplePlayer =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    result = SamplePlayer(resource: this.sampleplayer.newPlayer(), finishCallback: nil)

proc sample*(this: SamplePlayer): AudioSample =
    return this.sample

proc `sample=`*(this: SamplePlayer, sample: AudioSample) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setSample(this.resource, if sample != nil: sample.resource else: nil)
    this.sample = sample

proc newSamplePlayer*(this: ptr PlaydateSound, path: string): SamplePlayer {.raises: [IOError].} =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    result = SamplePlayer(resource: this.sampleplayer.newPlayer(), finishCallback: nil)
    result.`sample=`(this.newAudioSample(path))

proc volume*(this: SamplePlayer): tuple[left: float32, right: float32] =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    var left, right: cfloat
    playdate.sound.sampleplayer.getVolume(this.resource, addr left, addr right)
    return (left: left.float32, right: right.float32)

proc `volume=`*(this: SamplePlayer, volume: float32) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setVolume(this.resource, volume.cfloat, volume.cfloat)

proc setVolume*(this: SamplePlayer, left: float32, right: float32) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setVolume(this.resource, left.cfloat, right.cfloat)

proc `offset=`*(this: SamplePlayer, offset: float32) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setOffset(this.resource, offset.cfloat)

proc offset*(this: SamplePlayer): float32 =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSamplePlayer)
    return playdate.sound.sampleplayer.getOffset(this.resource).float32

proc play*(this: SamplePlayer, repeat: int, rate: float32) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    discard playdate.sound.sampleplayer.play(this.resource, repeat.cint, rate.cfloat)

proc stop*(this: SamplePlayer) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.stop(this.resource)

proc isPlaying*(this: SamplePlayer): bool =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    return playdate.sound.sampleplayer.isPlaying(this.resource) == 1

proc setPaused*(this: SamplePlayer, paused: bool) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setPaused(this.resource, if paused: 1 else: 0)

proc `rate=`*(this: SamplePlayer, rate: float32) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setRate(this.resource, rate.cfloat)

proc rate*(this: SamplePlayer): float32 =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    return playdate.sound.sampleplayer.getRate(this.resource).float32

proc privateSamplePlayerFinishCallback(soundSource: SoundSourcePtr, userdata: pointer) {.cdecl, raises: [].} =
    let samplePlayer = cast[SamplePlayer](userdata)
    if samplePlayer.finishCallback != nil:
        samplePlayer.finishCallback(samplePlayer)

proc setFinishCallback*(this: SamplePlayer, callback: PDSamplePlayerCallbackFunction) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    this.finishCallback = callback
    if callback == nil:
        playdate.sound.sampleplayer.setFinishCallback(this.resource, nil, nil)
    else:
        playdate.sound.sampleplayer.setFinishCallback(this.resource, privateSamplePlayerFinishCallback, cast[pointer](this))

proc finishCallback*(this: SamplePlayer): PDSamplePlayerCallbackFunction =
    return this.finishCallback

proc `finishCallback=`*(this: SamplePlayer, callback: PDSamplePlayerCallbackFunction) =
    this.setFinishCallback(callback)

proc setPlayRange*(this: SamplePlayer, start: int32, `end`: int32) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setPlayRange(this.resource, start.cint, `end`.cint)

# PlaydateSound
var headphoneChanged: proc(headphone: bool, microphone: bool) = nil

proc headphoneChangedCallback(headphone: cint, mic: cint) {.cdecl, raises: [].} =
    if headphoneChanged != nil:
        headphoneChanged(headphone == 1, mic == 1)

proc setHeadphoneChangedCallback*(this: ptr PlaydateSound, changed: proc(headphone: bool, microphone: bool)) =
    privateAccess(PlaydateSound)
    if changed == nil:
        this.getHeadphoneState(nil, nil, nil)
    else:
        this.getHeadphoneState(nil, nil, headphoneChangedCallback)
    headphoneChanged = changed

proc getHeadphoneState*(this: ptr PlaydateSound): tuple[headphone: bool, microphone: bool] =
    privateAccess(PlaydateSound)
    var headphone, mic: cint
    this.getHeadphoneState(addr headphone, addr mic, nil)
    return (headphone: headphone == 1, microphone: mic == 1)

proc setOutputsActive*(this: ptr PlaydateSound, headphone: bool, speaker: bool) =
    privateAccess(PlaydateSound)
    this.setOutputsActive(if headphone: 1 else: 0, if speaker: 1 else: 0)

type
    SoundSequenceObj = object
        resource: SoundSequencePtr

    SoundSequence* = ref SoundSequenceObj

    PDSoundSequenceCallbackFunction* = proc(sequence: SoundSequence) {.raises: [].}

proc `=destroy`*(this: var SoundSequenceObj) =
    privateAccess(PlaydateSoundSequence)
    playdate.sound.sequence.freeSequence(this.resource)

proc newSequence*(this: ptr PlaydateSoundSequence): SoundSequence =
    privateAccess(PlaydateSoundSequence)
    return SoundSequence(resource: this.newSequence())

template checkZero(code: typed) =
    if code == 0:
        raise newException(CatchableError, astToStr(code))

proc loadMIDIFile*(this: var SoundSequence, path: string) {.raises: [CatchableError].} =
    privateAccess(PlaydateSoundSequence)
    checkZero(playdate.sound.sequence.loadMIDIFile(this.resource, path.cstring))

proc getTime*(this: SoundSequence): uint32 =
    privateAccess(PlaydateSoundSequence)
    return playdate.sound.sequence.getTime(this.resource).uint32

proc setTime*(this: SoundSequence, time: uint32) =
    privateAccess(PlaydateSoundSequence)
    playdate.sound.sequence.setTime(this.resource, time)

proc setLoops*(this: SoundSequence, loopstart, loopend, loops: int32) =
    privateAccess(PlaydateSoundSequence)
    playdate.sound.sequence.setLoops(this.resource, loopstart.cint, loopend.cint, loops.cint)

proc allNotesOff*(this: SoundSequence) =
    privateAccess(PlaydateSoundSequence)
    playdate.sound.sequence.allNotesOff(this.resource)

proc isPlaying*(this: SoundSequence): bool =
    privateAccess(PlaydateSoundSequence)
    return playdate.sound.sequence.isPlaying(this.resource) == 1

proc getLength*(this: SoundSequence): uint32 =
    privateAccess(PlaydateSoundSequence)
    return playdate.sound.sequence.getLength(this.resource).uint32

proc play*(this: SoundSequence, finishCallback: SequenceFinishedCallback = nil) =
    privateAccess(PlaydateSoundSequence)
    playdate.sound.sequence.play(this.resource, finishCallback, nil)

proc stop*(this: SoundSequence) =
    privateAccess(PlaydateSoundSequence)
    playdate.sound.sequence.stop(this.resource)

proc getCurrentStep*(this: SoundSequence): int32 =
    privateAccess(PlaydateSoundSequence)
    return playdate.sound.sequence.getCurrentStep(this.resource, nil).int32

proc setCurrentStep*(this: SoundSequence, step, timeOffset, playNotes: int32) =
    privateAccess(PlaydateSoundSequence)
    playdate.sound.sequence.setCurrentStep(this.resource, step.cint, timeOffset.cint, playNotes.cint)

proc getTempo*(this: SoundSequence): float32 =
    privateAccess(PlaydateSoundSequence)
    return playdate.sound.sequence.getTempo(this.resource).float32

proc setTempo*(this: SoundSequence, stepsPerSecond: float32) =
    privateAccess(PlaydateSoundSequence)
    playdate.sound.sequence.setTempo(this.resource, stepsPerSecond)
