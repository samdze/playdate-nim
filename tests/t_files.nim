import unittest, playdate/api, std/[streams, strutils]

proc createFile(name: string, body: string = "") =
  var handle = playdate.file.open(name, kFileWrite)
  check(handle.write(cast[seq[byte]](body), body.len.uint) >= 0)

proc execFilesTest*() =
  suite "File loading":
    test "Writing and reading files":
      createFile("test_data.txt", "foo")
      var handle = playdate.file.open("test_data.txt", kFileReadData)
      check(handle.readString() == "foo")

    test "Writing strings to files":
      block:
        playdate.file.open("test_data.txt", kFileWrite).write("file content")
      check(
        playdate.file.open("test_data.txt", kFileReadData).readString() == "file content"
      )

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

    test "Writing and reading through a Stream":
      block:
        let stream = playdate.file.open("stream_data.txt", kFileWrite).toStream()
        stream.writeLine("first line")
        stream.write("second line")
        stream.close()

      let stream = playdate.file.open("stream_data.txt", kFileReadData).toStream()
      check(stream.readLine() == "first line")
      check(stream.readAll() == "second line")
      check(stream.atEnd())
      stream.close()

    test "Seeking within a Stream":
      block:
        let stream = playdate.file.open("stream_seek.txt", kFileWrite).toStream()
        stream.write("0123456789")
        stream.close()

      let stream = playdate.file.open("stream_seek.txt", kFileReadData).toStream()
      stream.setPosition(5)
      check(stream.getPosition() == 5)
      check(stream.readAll() == "56789")
      stream.close()

    test "Explicitly closing a file":
      block:
        let handle = playdate.file.open("closed_file.txt", kFileWrite)
        handle.write("content")
        handle.close()
        handle.close()
      check(
        playdate.file.open("closed_file.txt", kFileReadData).readString() == "content"
      )

    test "Reading an empty file":
      createFile("empty_file.txt")
      check(playdate.file.open("empty_file.txt", kFileReadData).read().len == 0)
      check(playdate.file.open("empty_file.txt", kFileReadData).readString() == "")
      check(playdate.file.open("empty_file.txt", kFileReadData).read(0).length == 0)

    test "Writing a large buffer through a Stream":
      let content = 'x'.repeat(100_000)
      block:
        let stream = playdate.file.open("stream_large.txt", kFileWrite).toStream()
        stream.write(content)
        stream.close()
      check(playdate.file.stat("stream_large.txt").size == content.len.uint)

    test "Checking for the end of an unflushed Stream":
      let stream = playdate.file.open("stream_unflushed.txt", kFileWrite).toStream()
      stream.write("abc")
      check(stream.atEnd())
      stream.setPosition(1)
      check(not stream.atEnd())
      check(stream.getPosition() == 1)
      stream.close()

    test "Reading a bundled file that is shadowed by a data file":
      createFile("bundled_file.txt", "abc")
      let stream = playdate.file.open("bundled_file.txt", kFileRead).toStream()
      var bytesRead = 0
      while not stream.atEnd():
        discard stream.readChar()
        bytesRead += 1
      check(bytesRead == 67)
      stream.close()

    test "Peeking keeps the Stream position when the read fails":
      let stream = playdate.file.open("stream_peek_fail.txt", kFileWrite).toStream()
      stream.write("abc")
      stream.setPosition(1)
      var buffer: array[2, char]
      expect IOError:
        discard stream.peekData(addr buffer, buffer.len)
      check(stream.getPosition() == 1)
      stream.close()
