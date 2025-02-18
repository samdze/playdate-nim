{.push raises: [].}

import utils

type FilePlayerPtr = pointer
type AudioSamplePtr = pointer
type SamplePlayerPtr = pointer
type SoundSourceRaw {.importc: "SoundSource", header: "pd_api.h".} = object
type SoundSourcePtr = ptr SoundSourceRaw
type SoundSequenceRaw {.importc: "SoundSequence", header: "pd_api.h".} = object
type SoundSequencePtr = ptr SoundSequenceRaw

type SequenceFinishedCallback = proc(soundSource: SoundSequencePtr, userdata: pointer) {.cdecl.}
type PDSndCallbackProcRaw {.importc: "sndCallbackProc", header: "pd_api.h".} = proc(soundSource: SoundSourcePtr, userdata: pointer) {.cdecl.}


type PlaydateSoundFileplayer {.importc: "const struct playdate_sound_fileplayer",
                            header: "pd_api.h", bycopy.} = object
    newPlayer {.importc: "newPlayer".}: proc (): FilePlayerPtr {.cdecl, raises: [].}
    freePlayer {.importc: "freePlayer".}: proc (player: FilePlayerPtr) {.cdecl, raises: [].}
    loadIntoPlayer {.importc: "loadIntoPlayer".}: proc (player: FilePlayerPtr;
        path: cstring): cint {.cdecl, raises: [].}
    # setBufferLength* {.importc: "setBufferLength".}: proc (player: ptr FilePlayer;
    #     bufferLen: cfloat) {.cdecl.}
    play {.importc: "play".}: proc (player: FilePlayerPtr; repeat: cint): cint {.cdecl, raises: [].}
    isPlaying {.importc: "isPlaying".}: proc (player: FilePlayerPtr): cint {.cdecl, raises: [].}
    pause {.importc: "pause".}: proc (player: FilePlayerPtr) {.cdecl, raises: [].}
    stop {.importc: "stop".}: proc (player: FilePlayerPtr) {.cdecl, raises: [].}
    setVolume {.importc: "setVolume".}: proc (player: FilePlayerPtr; left: cfloat;
        right: cfloat) {.cdecl, raises: [].}
    getVolume {.importc: "getVolume".}: proc (player: FilePlayerPtr;
        left: ptr cfloat; right: ptr cfloat) {.cdecl, raises: [].}
    getLength {.importc: "getLength".}: proc (player: FilePlayerPtr): cfloat {.cdecl, raises: [].}
    setOffset {.importc: "setOffset".}: proc (player: FilePlayerPtr; offset: cfloat) {.
        cdecl, raises: [].}
    # setRate {.importc: "setRate".}: proc (player: FilePlayerPtr; rate: cfloat) {.cdecl.}
    # setLoopRange* {.importc: "setLoopRange".}: proc (player: ptr FilePlayer;
    #     start: cfloat; `end`: cfloat) {.cdecl.}
    # didUnderrun* {.importc: "didUnderrun".}: proc (player: ptr FilePlayer): cint {.cdecl.}
    setFinishCallback* {.importc: "setFinishCallback".}: proc (
        player: FilePlayerPtr; callback: PDSndCallbackProcRaw, userdata: pointer = nil) {.cdecl, raises: [].}
    # setLoopCallback* {.importc: "setLoopCallback".}: proc (player: ptr FilePlayer;
    #     callback: SndCallbackProc) {.cdecl.}
    getOffset {.importc: "getOffset".}: proc (player: FilePlayerPtr): cfloat {.cdecl, raises: [].}
    # getRate* {.importc: "getRate".}: proc (player: ptr FilePlayer): cfloat {.cdecl.}
    # setStopOnUnderrun* {.importc: "setStopOnUnderrun".}: proc (
    #     player: ptr FilePlayer; flag: cint) {.cdecl.}
    fadeVolume* {.importc: "fadeVolume".}: proc (player: FilePlayerPtr; left: cfloat;
        right: cfloat; len: cint; finishCallback: PDSndCallbackProcRaw, userdata: pointer = nil) {.cdecl, raises:[].}
    # setMP3StreamSource* {.importc: "setMP3StreamSource".}: proc (
    #     player: ptr FilePlayer; dataSource: proc (data: ptr uint8T; bytes: cint;
    #     userdata: pointer): cint {.cdecl.}; userdata: pointer; bufferLen: cfloat) {.
    #     cdecl.}
# type PlaydateSoundFilePlayer* = ptr PlaydateSoundFileplayerRaw

type PlaydateSoundSample {.importc: "const struct playdate_sound_sample", header: "pd_api.h".} = object
    newSampleBuffer {.importc: "newSampleBuffer".}: proc (byteCount: cint): AudioSamplePtr {.
        cdecl, raises: [].}
    loadIntoSample {.importc: "loadIntoSample".}: proc (sample: AudioSamplePtr;
        path: cstring): cint {.cdecl, raises: [].}
    load {.importc: "load".}: proc (path: cstring): AudioSamplePtr {.cdecl, raises: [].}
    # newSampleFromData* {.importc: "newSampleFromData".}: proc (data: ptr uint8T;
    #     format: SoundFormat; sampleRate: uint32T; byteCount: cint): ptr AudioSample {.
    #     cdecl.}
    # getData* {.importc: "getData".}: proc (sample: ptr AudioSample;
    #                                    data: ptr ptr uint8T;
    #                                    format: ptr SoundFormat;
    #                                    sampleRate: ptr uint32T;
    #                                    bytelength: ptr uint32T) {.cdecl.}
    freeSample {.importc: "freeSample".}: proc (sample: AudioSamplePtr) {.cdecl, raises: [].}
    getLength {.importc: "getLength".}: proc (sample: AudioSamplePtr): cfloat {.cdecl, raises: [].}
# type PlaydateSoundSample* = ptr PlaydateSoundSampleRaw

type PlaydateSoundSampleplayer {.importc: "const struct playdate_sound_sampleplayer", header: "pd_api.h".} = object
    newPlayer {.importc: "newPlayer".}: proc (): SamplePlayerPtr {.cdecl, raises: [].}
    freePlayer {.importc: "freePlayer".}: proc (player: SamplePlayerPtr) {.cdecl, raises: [].}
    setSample {.importc: "setSample".}: proc (player: SamplePlayerPtr;
        sample: AudioSamplePtr) {.cdecl, raises: [].}
    play {.importc: "play".}: proc (player: SamplePlayerPtr; repeat: cint; rate: cfloat): cint {.
        cdecl, raises: [].}
    isPlaying {.importc: "isPlaying".}: proc (player: SamplePlayerPtr): cint {.cdecl, raises: [].}
    stop {.importc: "stop".}: proc (player: SamplePlayerPtr) {.cdecl, raises: [].}
    setVolume {.importc: "setVolume".}: proc (player: SamplePlayerPtr; left: cfloat;
        right: cfloat) {.cdecl, raises: [].}
    getVolume {.importc: "getVolume".}: proc (player: SamplePlayerPtr;
        left: ptr cfloat; right: ptr cfloat) {.cdecl, raises: [].}
    getLength {.importc: "getLength".}: proc (player: SamplePlayerPtr): cfloat {.cdecl, raises: [].}
    setRate {.importc: "setRate".}: proc (player: SamplePlayerPtr; rate: cfloat) {.cdecl, raises: [].}
    getRate {.importc: "getRate".}: proc (player: SamplePlayerPtr): cfloat {.cdecl, raises: [].}
    setPlayRange* {.importc: "setPlayRange".}: proc (player: SamplePlayerPtr;
        start: cint; `end`: cint) {.cdecl, raises: [].}
    setFinishCallback* {.importc: "setFinishCallback".}: proc (
        player: SamplePlayerPtr; callback: PDSndCallbackProcRaw, userdata: pointer = nil) {.cdecl, raises: [].}
    # setLoopCallback* {.importc: "setLoopCallback".}: proc (player: ptr SamplePlayer;
    #     callback: SndCallbackProc) {.cdecl.}
    getOffset* {.importc: "getOffset".}: proc (player: SamplePlayerPtr): cfloat {.cdecl , raises: [].}
    setOffset {.importc: "setOffset".}: proc (player: SamplePlayerPtr; offset: cfloat) {.
        cdecl, raises: [].}
    setPaused {.importc: "setPaused".}: proc (player: SamplePlayerPtr; flag: cint) {.
        cdecl, raises: [].}
# type PlaydateSoundSampleplayer* = ptr PlaydateSoundSampleplayerRaw

type PlaydateSoundSequence {.importc: "const struct playdate_sound_sequence",
                            header: "pd_api.h", bycopy.} = object
    newSequence {.importc: "newSequence".}: proc (): SoundSequencePtr {.cdecl, raises: [].}
    freeSequence {.importc: "freeSequence".}: proc (player: SoundSequencePtr) {.cdecl, raises: [].}
    loadMIDIFile {.importc: "loadMIDIFile".}: proc(soundSeq: SoundSequencePtr, path: cstring): cint {.cdecl, raises: [].}
    getTime {.importc: "getTime".}: proc(soundSeq: SoundSequencePtr): cuint {.cdecl, raises: [].}
    setTime {.importc: "setTime".}: proc(soundSeq: SoundSequencePtr, time: cuint): void {.cdecl, raises: [].}
    setLoops {.importc: "setLoops".}: proc(soundSeq: SoundSequencePtr, loopstart: cint, loopend: cint, loops: cint): void {.cdecl, raises: [].}
    setTempo {.importc: "setTempo".}: proc(soundSeq: SoundSequencePtr, stepsPerSecond: cfloat): void {.cdecl, raises: [].}
    # getTrackCount {.importc: "getTrackCount".}: proc(soundSeq: SoundSequencePtr): cint {.cdecl, raises: [].}
    # addTrack {.importc: "addTrack".}: proc(soundSeq: SoundSequencePtr): SequenceTrackPtr {.cdecl, raises: [].}
    # getTrackAtIndex {.importc: "getTrackAtIndex".}: proc(soundSeq: SoundSequencePtr, track: cuint): SequenceTrackPtr {.cdecl, raises: [].}
    # setTrackAtIndex {.importc: "setTrackAtIndex".}: proc(soundSeq: SoundSequencePtr, track: SequenceTrackPtr, idx: cuint): void {.cdecl, raises: [].}
    allNotesOff {.importc: "allNotesOff".}: proc(soundSeq: SoundSequencePtr): void {.cdecl, raises: [].}
    isPlaying {.importc: "isPlaying".}: proc(soundSeq: SoundSequencePtr): cint {.cdecl, raises: [].}
    getLength {.importc: "getLength".}: proc(soundSeq: SoundSequencePtr): cuint  {.cdecl, raises: [].}
    play {.importc: "play".}: proc(soundSeq: SoundSequencePtr, finishCallback: SequenceFinishedCallback = nil, userdata: pointer = nil): void {.cdecl, raises: [].}
    stop {.importc: "stop".}: proc(soundSeq: SoundSequencePtr): void {.cdecl, raises: [].}
    getCurrentStep {.importc: "getCurrentStep".}: proc(soundSeq: SoundSequencePtr, timeOffset: ptr cint): cint {.cdecl, raises: [].}
    setCurrentStep {.importc: "setCurrentStep".}: proc(soundSeq: SoundSequencePtr, step: cint, timeOffset: cint, playNotes: cint): void {.cdecl, raises: [].}
    getTempo {.importc: "getTempo".}: proc(soundSeq: SoundSequencePtr): cfloat {.cdecl, raises: [].}

sdktype:
    type PlaydateSound* {.importc: "const struct playdate_sound", header: "pd_api.h".} = object
        # channel* {.importc: "channel".}: ptr PlaydateSoundChannel
        fileplayer {.importc: "fileplayer".}: ptr PlaydateSoundFileplayer
        sample {.importc: "sample".}: ptr PlaydateSoundSample
        sampleplayer {.importc: "sampleplayer".}: ptr PlaydateSoundSampleplayer
        # synth* {.importc: "synth".}: ptr PlaydateSoundSynth
        sequence* {.importc: "sequence".}: ptr PlaydateSoundSequence
        # effect* {.importc: "effect".}: ptr PlaydateSoundEffect
        # lfo* {.importc: "lfo".}: ptr PlaydateSoundLfo
        # envelope* {.importc: "envelope".}: ptr PlaydateSoundEnvelope
        # source* {.importc: "source".}: ptr PlaydateSoundSource
        # controlsignal* {.importc: "controlsignal".}: ptr PlaydateControlSignal
        # track* {.importc: "track".}: ptr PlaydateSoundTrack
        # instrument* {.importc: "instrument".}: ptr PlaydateSoundInstrument
        getCurrentTime* {.importsdk.}: proc (): uint32 {.cdecl, raises: [].}
        # addSource* {.importc: "addSource".}: proc (callback: ptr AudioSourceFunction;
        #     context: pointer; stereo: cint): ptr SoundSource {.cdecl.}
        # getDefaultChannel* {.importc: "getDefaultChannel".}: proc (): ptr SoundChannel {.
        #     cdecl.}
        # addChannel* {.importc: "addChannel".}: proc (channel: ptr SoundChannel) {.cdecl.}
        # removeChannel* {.importc: "removeChannel".}: proc (channel: ptr SoundChannel) {.
        #     cdecl.}
        # setMicCallback* {.importc: "setMicCallback".}: proc (
        #     callback: ptr RecordCallback; context: pointer; forceInternal: cint) {.cdecl.}
        getHeadphoneState {.importc: "getHeadphoneState".}: proc (headphone: ptr cint;
            headsetmic: ptr cint;
            changeCallback: proc (headphone: cint; mic: cint) {.cdecl, raises: [].}) {.cdecl, raises: [].}
        setOutputsActive {.importc: "setOutputsActive".}: proc (headphone: cint;
            speaker: cint) {.cdecl, raises: [].} ##  1.5
        # removeSource* {.importc: "removeSource".}: proc (source: ptr SoundSource) {.cdecl.} ##  1.12
        # signal* {.importc: "signal".}: ptr PlaydateSoundSignal
# type PlaydateSound* = ptr PlaydateSoundRaw