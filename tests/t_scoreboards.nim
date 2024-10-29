import unittest, playdate/api

proc execScoreboardTests*() =

    # We can't actually invoke the real scoreboard endpoints, so the best we can do is run the
    # nim functions and ensure everything compiles
    suite "Scoreboards API verification":

        test "getPersonalBest":
            playdate.scoreboards.getPersonalBest("some_board") do (score: PDResult[PDScore]) -> void:
                case score.kind
                of PDResultSuccess: echo $score.result
                of PDResultError: echo $score.message
                of PDResultSuccessEmpty: echo "SuccessEmpty"

        test "addScore":
            playdate.scoreboards.addScore("some_board", 123) do (score: PDResult[PDScore]) -> void:
                discard

        test "getScoreboards":
            playdate.scoreboards.getScoreboards() do (boards: PDResult[PDBoardsList]) -> void:
                discard

        test "getScores":
            playdate.scoreboards.getScores("some_board") do (scores: PDResult[PDScoresList]) -> void:
                discard
