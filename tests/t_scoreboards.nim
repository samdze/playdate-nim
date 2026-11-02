import std/[importutils, unittest], playdate/api, playdate/scoreboards {.all.}

proc execScoreboardTests*() =
  # We can't actually invoke the real scoreboard endpoints, so the best we can do is run the
  # nim functions and ensure everything compiles
  suite "Scoreboards API verification":
    test "getPersonalBest":
      playdate.scoreboards.getPersonalBest("some_board") do(
        score: PDResult[PDScore]
      ) -> void:
        case score.kind
        of PDResultSuccess:
          echo $score.result
        of PDResultError:
          echo $score.message
        of PDResultUnavailable:
          echo "PDResultUnavailable"

    test "addScore":
      playdate.scoreboards.addScore("some_board", 123) do(
        score: PDResult[PDScore]
      ) -> void:
        discard

    test "getScoreboards":
      playdate.scoreboards.getScoreboards do(boards: PDResult[PDBoardsList]) -> void:
        discard

    test "getScores":
      playdate.scoreboards.getScores("some_board") do(
        scores: PDResult[PDScoresList]
      ) -> void:
        discard

  privateAccess(CallbackSlots)

  suite "Scoreboards callback slots":
    setup:
      # Earlier requests never get a response in the simulator, so start from empty
      personalBestSlots = default(typeof(personalBestSlots))

    proc request(calls: ptr seq[string], name: string) =
      playdate.scoreboards.getPersonalBest(name) do(score: PDResult[PDScore]) -> void:
        calls[].add(name)

    when scoreboardSlots >= 2:
      test "Responses reach their own callbacks in any order":
        var calls: seq[string]
        request(addr calls, "first")
        request(addr calls, "second")

        personalBestTrampolines[1](nil, nil)
        personalBestTrampolines[0](nil, nil)
        check(calls == @["second", "first"])

      test "A lost response does not misroute later ones":
        var calls: seq[string]
        request(addr calls, "lost")
        request(addr calls, "second")

        personalBestTrampolines[1](nil, nil)
        check(calls == @["second"])

    test "A request fails immediately when all slots are full":
      var calls: seq[string]
      for i in 0 ..< scoreboardSlots:
        request(addr calls, "pending" & $i)

      var overflow: PDResultKind = PDResultSuccess
      playdate.scoreboards.getPersonalBest("overflow") do(
        score: PDResult[PDScore]
      ) -> void:
        overflow = score.kind
      check(overflow == PDResultError)
      check(calls.len == 0)

    test "A late reply still reaches the request that made it":
      var calls: seq[string]
      for i in 0 ..< scoreboardSlots:
        request(addr calls, "pending" & $i)
      playdate.scoreboards.getPersonalBest("overflow") do(
        score: PDResult[PDScore]
      ) -> void:
        discard

      personalBestTrampolines[0](nil, nil)
      check(calls == @["pending0"])

      request(addr calls, "reused")
      personalBestTrampolines[0](nil, nil)
      check(calls == @["pending0", "reused"])

    test "A callback can make a new request that reuses its slot":
      var calls: seq[string]
      playdate.scoreboards.getPersonalBest("outer") do(score: PDResult[PDScore]) -> void:
        calls.add("outer")
        request(addr calls, "inner")

      personalBestTrampolines[0](nil, nil)
      check(personalBestSlots.callbacks[0] != nil)
      personalBestTrampolines[0](nil, nil)
      check(calls == @["outer", "inner"])

    test "A response for an empty slot is ignored":
      personalBestTrampolines[0](nil, nil)
      check(personalBestSlots.callbacks[0] == nil)
