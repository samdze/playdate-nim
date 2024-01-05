{.push raises: [].}

import std/importutils
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

proc getLength*(this: AudioSample): float =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSample)
    return playdate.sound.sample.getLength(this.resource).float

# AudioSource
type SoundSourceObj {.requiresinit.} = object of RootObj
    resource: pointer
type SoundSource* = ref SoundSourceObj

# FilePlayer
type
    FilePlayerObj = object of SoundSourceObj
    FilePlayer* = ref FilePlayerObj

proc `=destroy`(this: var FilePlayerObj) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.freePlayer(this.resource)

proc newFilePlayer*(this: ptr PlaydateSound): FilePlayer =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    result = FilePlayer(resource: this.fileplayer.newPlayer())

proc newFilePlayer*(this: ptr PlaydateSound, path: string): FilePlayer {.raises: [IOError].} =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    result = FilePlayer(resource: this.fileplayer.newPlayer())
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

proc volume*(this: FilePlayer): tuple[left: float, right: float] =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    var left, right: cfloat
    playdate.sound.fileplayer.getVolume(this.resource, addr left, addr right)
    return (left: left.float, right: right.float)

proc `volume=`*(this: FilePlayer, volume: float) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.setVolume(this.resource, volume.cfloat, volume.cfloat)

proc setVolume*(this: FilePlayer, left: float, right: float) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.setVolume(this.resource, left.cfloat, right.cfloat)

proc getLength*(this: FilePlayer): float =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    return playdate.sound.fileplayer.getLength(this.resource).float

proc offset*(this: FilePlayer): float =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    return playdate.sound.fileplayer.getOffset(this.resource).float

proc `offset=`*(this: FilePlayer, offset: float) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    playdate.sound.fileplayer.setOffset(this.resource, offset.cfloat)

# SamplePlayer
type
    SamplePlayerObj = object of SoundSourceObj
        sample: AudioSample
    SamplePlayer* = ref SamplePlayerObj

proc `=destroy`(this: var SamplePlayerObj) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.freePlayer(this.resource)
    this.sample = nil

proc newSamplePlayer*(this: ptr PlaydateSound): SamplePlayer =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    result = SamplePlayer(resource: this.sampleplayer.newPlayer())

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
    result = SamplePlayer(resource: this.sampleplayer.newPlayer())
    result.`sample=`(this.newAudioSample(path))

proc volume*(this: SamplePlayer): tuple[left: float, right: float] =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    var left, right: cfloat
    playdate.sound.sampleplayer.getVolume(this.resource, addr left, addr right)
    return (left: left.float, right: right.float)

proc `volume=`*(this: SamplePlayer, volume: float) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setVolume(this.resource, volume.cfloat, volume.cfloat)

proc setVolume*(this: SamplePlayer, left: float, right: float) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setVolume(this.resource, left.cfloat, right.cfloat)

proc play*(this: SamplePlayer, repeat: int, rate: float) =
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

proc setRate*(this: SamplePlayer, rate: float) =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundSampleplayer)
    playdate.sound.sampleplayer.setRate(this.resource, rate.cfloat)

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