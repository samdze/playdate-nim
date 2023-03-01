{.push raises: [].}

import std/importutils
import bindings/[sound, api, utils]
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

proc toAudioSamplePtr(this: AudioSampleObj | AudioSample): auto = this.resource

proc `=destroy`(this: var AudioSampleObj) {.wrapApi([PlaydateSoundSample, PlaydateSound], freeSample).}

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

proc load*(this: AudioSample, path: string) {.wrapApi([PlaydateSoundSample, PlaydateSound], loadIntoSample).}

proc getLength*(this: AudioSample): float {.wrapApi([PlaydateSoundSample, PlaydateSound]).}

# AudioSource
type SoundSourceObj {.requiresinit.} = object of RootObj
    resource: pointer
type SoundSource* = ref SoundSourceObj

# FilePlayer
type
    FilePlayerObj = object of SoundSourceObj
    FilePlayer* = ref FilePlayerObj

proc toFilePlayerPtr(this: FilePlayer | FilePlayerObj): auto = this.resource

proc `=destroy`(this: var FilePlayerObj) {.wrapApi([PlaydateSoundFileplayer, PlaydateSound], freePlayer).}

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

proc play*(this: FilePlayer, repeat: int) {.wrapApi([PlaydateSoundFileplayer, PlaydateSound]).}

proc isPlaying*(this: FilePlayer): bool {.wrapApi([PlaydateSoundFileplayer, PlaydateSound]).}

proc pause*(this: FilePlayer) {.wrapApi([PlaydateSoundFileplayer, PlaydateSound]).}

proc stop*(this: FilePlayer) {.wrapApi([PlaydateSoundFileplayer, PlaydateSound]).}

proc volume*(this: FilePlayer): tuple[left: float, right: float] =
    privateAccess(PlaydateSound)
    privateAccess(PlaydateSoundFileplayer)
    var left, right: cfloat
    playdate.sound.fileplayer.getVolume(this.resource, addr left, addr right)
    return (left: left.float, right: right.float)

proc setVolume*(this: FilePlayer; left: float; right: float)
    {.wrapApi([PlaydateSoundFileplayer, PlaydateSound], setVolume).}

proc `volume=`*(this: FilePlayer, volume: float) = setVolume(this, volume, volume)

proc getLength*(this: FilePlayer): float {.wrapApi([PlaydateSoundFileplayer, PlaydateSound]).}

proc offset*(this: FilePlayer): float {.wrapApi([PlaydateSoundFileplayer, PlaydateSound], getOffset).}

proc `offset=`*(this: FilePlayer, offset: float) {.wrapApi([PlaydateSoundFileplayer, PlaydateSound], setOffset).}

# SamplePlayer
type
    SamplePlayerObj = object of SoundSourceObj
        sample: AudioSample
    SamplePlayer* = ref SamplePlayerObj

proc toSamplePlayerPtr(this: SamplePlayer): auto = this.resource

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

proc setVolume*(this: SamplePlayer, left: float, right: float)
    {.wrapApi([PlaydateSoundSampleplayer, PlaydateSound]).}

proc `volume=`*(this: SamplePlayer, volume: float) = setVolume(this, volume, volume)

proc play*(this: SamplePlayer, repeat: int, rate: float) {.wrapApi([PlaydateSoundSampleplayer, PlaydateSound]).}

proc stop*(this: SamplePlayer) {.wrapApi([PlaydateSoundSampleplayer, PlaydateSound]).}

proc isPlaying*(this: SamplePlayer): bool {.wrapApi([PlaydateSoundSampleplayer, PlaydateSound]).}

proc setPaused*(this: SamplePlayer, paused: bool) {.wrapApi([PlaydateSoundSampleplayer, PlaydateSound]).}

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

proc setOutputsActive*(this: ptr PlaydateSound, headphone: bool, speaker: bool) {.wrapApi([PlaydateSound]).}