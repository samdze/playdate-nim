import std/[unittest, strutils, streams], playdate/build/[pdxinfo, nimbledump]

suite "Pdxinfo generation":

    test "Produce a default pdxinfo from a nimble dump":
        let dump = NimbleDump(
            name: "Lorem Ipsum",
            version: "0.0.0",
            nimblePath: "/path/to/nimble",
            author: "Twas Brillig",
            desc: "A thing",
            license: "MIT",
        )

        check($dump.toPdxInfo("1.2.3", "20250216") == """
            name=Lorem Ipsum
            author=Twas Brillig
            description=A thing
            bundleId=com.twasbrillig.loremipsum
            imagePath=launcher
            version=1.2.3
            buildNumber=20250216
            """.dedent())

    test "Read a PDXInfo from a stream":
        let pdx = newStringStream("""
            name=Lorem Ipsum
            author=Twas Brillig
            description=A thing
            bundleId=com.twasbrillig.loremipsum
            imagePath=launcher
            version=1.2.3
            buildNumber=20250216
            launchSoundPath=path/to/launch/sound/file
            contentWarning="Beware the Jabberwock, my son!"
            contentWarning2="The jaws that bite, the claws that catch!"
            """).parsePdx("[stream]")

        check($pdx == """
            name=Lorem Ipsum
            author=Twas Brillig
            description=A thing
            bundleId=com.twasbrillig.loremipsum
            imagePath=launcher
            version=1.2.3
            buildNumber=20250216
            launchSoundPath=path/to/launch/sound/file
            contentWarning=Beware the Jabberwock, my son!
            contentWarning2=The jaws that bite, the claws that catch!
            """.dedent())

    test "Join together multiple pdxinfo objects":
        let pdx1 = PdxInfo(
            name: "Lorem Ipsum",
            description: "A thing",
            imagePath: "launcher",
            version: "1.2.3",
            buildNumber: "20250216",
        )

        let pdx2 = PdxInfo(
            author: "Twas Brillig",
            bundleId: "com.twasbrillig.loremipsum",
            version: "3.4.5",
        )

        check($join(pdx1, pdx2) == """
            name=Lorem Ipsum
            author=Twas Brillig
            description=A thing
            bundleId=com.twasbrillig.loremipsum
            imagePath=launcher
            version=3.4.5
            buildNumber=20250216
            """.dedent())
