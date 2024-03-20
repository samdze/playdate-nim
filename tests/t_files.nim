import unittest, playdate/api

proc createFile(name: string, body: string = "") =
    var handle = playdate.file.open(name, kFileWrite)
    check(handle.write(cast[seq[byte]](body), body.len.uint) >= 0)

proc execFilesTest*() =
    suite "File loading":
        test "Writing and reading files":
            createFile("test_data.txt", "foo")
            var handle = playdate.file.open("test_data.txt", kFileReadData)
            check(handle.readString() == "foo")

        test "Listing files":
            createFile("list_files.txt")
            check("list_files.txt" in playdate.file.listFiles("/"))

        test "Stating missing file":
            expect IOError:
                discard playdate.file.stat("not_real.txt")

        test "Stating existing file":
            createFile("stat_file.txt", "some content")
            let stat = playdate.file.stat("stat_file.txt")
            check(stat.isdir == 0)
            check(stat.size == 12)

        test "Checking if files exists":
            check(playdate.file.exists("not_a_file.txt") == false)

            createFile("real_file.txt")
            check(playdate.file.exists("real_file.txt"))

        test "Unlinking files":
            createFile("delete_me.txt")
            playdate.file.unlink("delete_me.txt", false)
            check(playdate.file.exists("delete_me.txt") == false)

        test "mkdir":
            playdate.file.mkdir("my_dir")
            check(playdate.file.stat("my_dir").isdir == 1)

        test "Renaming file":
            createFile("original_file.txt")
            playdate.file.rename("original_file.txt", "renamed_file.txt")
            check(playdate.file.exists("renamed_file.txt"))