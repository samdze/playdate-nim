import unittest, playdate/api, playdate/scoreboards {.all.}

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

  suite "Scoreboards callback queue":
    setup:
      # Earlier requests never get a response in the simulator, so start from empty
      privatePersonalBestCallbacks.setLen(0)

    test "Responses are delivered to callbacks in request order":
      var calls: seq[string]
      playdate.scoreboards.getPersonalBest("first") do(
        score: PDResult[PDScore]
      ) -> void:
        calls.add("first")
      playdate.scoreboards.getPersonalBest("second") do(
        score: PDResult[PDScore]
      ) -> void:
        calls.add("second")

      invokePersonalBestCallback(nil, nil)
      invokePersonalBestCallback(nil, nil)
      check(calls == @["first", "second"])

    test "A response with no queued callback is ignored":
      invokePersonalBestCallback(nil, nil)
      check(privatePersonalBestCallbacks.len == 0)
