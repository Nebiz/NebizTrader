#Requires AutoHotkey v2.0
#SingleInstance

F12:: {
    ExitApp
}
; Avoid conflicts with other games.
SetTimer CheckClosedPoe, 5000
CheckClosedPoe() {
    If !WinExist("ahk_exe PathOfExileSteam.exe") {
        ExitApp
    }
}

; Hotkey for detecting Ctrl+D
#HotIf WinActive("ahk_exe PathOfExileSteam.exe")
^d:: {
    SendInput "^c"
    Sleep 100
    ProcessClipboardAndOpenURL()
}

; Function to process clipboard content and open the URL
ProcessClipboardAndOpenURL() {
    queryBaseUrl := "https://www.pathofexile.com/trade2/search/poe2/Standard?q="
    exchangeBaseUrl := "https://www.pathofexile.com/trade2/exchange/poe2/Standard?q="
    rareItemQueryPayload    := '{"query":{"type":"--itemType--","stats":[{"type":"and","filters":[]}]}}'
    uniqueItemQueryPayload  := '{"query":{"name":"--itemName--","type":"--itemType--","stats":[{"type":"and","filters":[]}]}}'
    exchangePayload         := '{"query":{"have":["exalted"],"want":["--itemName--"]},"engine":"new"}'
    uncutGemPayload         := '{"query":{"type":"--itemType--","filters":{"type_filters":{"disabled":false,"filters":{"ilvl":{"min":--itemLevelMin--,"max":--itemLevelMax--}}}}}}'
    leveledGemPayload       := '{"query":{"type":"--itemType--","filters":{"misc_filters":{"disabled":false,"filters":{"gem_level":{"min":--itemLevelMin--,"max":--itemLevelMax--}}}}}}'

    ; Split the text by newline
    itemLines := StrSplit(A_Clipboard, "`n", "`r")

    ; Ensure there's at least 4 lines of content
    if (itemLines.Length < 4) {
        return
    }

    ; Getting object data
    delimiter := ": "
    itemClass := ""
    itemRarity := ""
    itemLevel := ""
    for value in itemLines {
        if (InStr(value, "Item Class: ") && !itemClass) {
            itemClass := StrSplit(value, delimiter)[2]
        }
        if (InStr(value, "Rarity: ") && !itemRarity) {
            itemRarity := StrSplit(value, delimiter)[2]
        }
        if (InStr(value, "Level: ") && !itemLevel) {
            itemLevel := StrSplit(value, delimiter)[2]
        }
    }

    ; Handling existing currency not on the trade website.
    if (itemLines[3] = "Chance Shard") {
        return
    }

    payload := ""
    if (itemRarity = "Currency" && itemClass = "") { ; Any Uncut Gems.
        payload := StrReplace(uncutGemPayload, "--itemType--", itemLines[2])
        payload := StrReplace(payload, "--itemLevelMin--", itemLevel)
        payload := StrReplace(payload, "--itemLevelMax--", 100)
    } else if (itemRarity = "Rare") {
        payload := StrReplace(rareItemQueryPayload, "--itemType--", itemLines[4])
    } else if (itemRarity = "Unique") {
        payload := StrReplace(uniqueItemQueryPayload, "--itemName--", itemLines[3])
        payload := StrReplace(payload, "--itemType--", itemLines[4])
    } else if (itemRarity = "Currency" && itemClass = "Stackable Currency") {
        payload := StrReplace(exchangePayload, "--itemName--", MyMap[itemLines[3]])
    } else if (itemClass = "Inscribed Ultimatum" || itemClass = "Djinn Barya" || itemClass = "Trial Coins") {
        payload := StrReplace(uncutGemPayload, "--itemType--", itemLines[3])
        payload := StrReplace(payload, "--itemLevelMin--", itemLevel)
        payload := StrReplace(payload, "--itemLevelMax--", 100)
    } else if (itemRarity = "Gem" && itemClass = "Skill Gems") { ; Skill gems, Spirit gems.
        payload := StrReplace(leveledGemPayload, "--itemType--", itemLines[3])
        payload := StrReplace(payload, "--itemLevelMin--", SubStr(itemLevel, 1, 2))
        payload := StrReplace(payload, "--itemLevelMax--", 21)
    } else if (itemRarity = "Gem" && itemClass = "Support Gems") { ; Support gems.
        payload := StrReplace(rareItemQueryPayload, "--itemType--", itemLines[3])
    } else if (itemClass = "Waystones") {
        payload := StrReplace(rareItemQueryPayload, "--itemType--", "Waystone (Tier " . StrSplit(itemLines[5], delimiter)[2] . ")")
    } else if (itemClass = "Life Flasks" || itemClass = "Mana Flasks") {
        currentItem := StrSplit(itemLines[3], " ")
        for value in currentItem {
            if (value = "Flask") {
                payload := StrReplace(uncutGemPayload, "--itemType--", currentItem[A_Index - 2] . " " . currentItem[A_Index - 1] . " " . currentItem[A_Index])
                break
            }
        }
        payload := StrReplace(payload, "--itemLevelMin--", StrSplit(itemLines[12], delimiter)[2])
        payload := StrReplace(payload, "--itemLevelMax--", 100)
    } else if (itemClass = "Tablet") { ; todo: hard to implement
    } else if (itemRarity = "Gem" && itemClass = "") { ; Cast on Gems.
        payload := StrReplace(leveledGemPayload, "--itemType--", itemLines[2])
        payload := StrReplace(payload, "--itemLevelMin--", SubStr(itemLevel, 1, 2))
        payload := StrReplace(payload, "--itemLevelMax--", 21)
    } else {
    }

    if (!payload) {
        return
    }

    url_1 := itemRarity = "Currency" && (itemClass = "Stackable Currency" || itemClass = "Socketable") ? exchangeBaseUrl : queryBaseUrl
    url_2 := EncodeUrl(url_1 . payload)
    A_Clipboard := url_2 ; debugging
    Run(url_2)
}

EncodeUrl(text) {
    return StrReplace(text, " ", "%20")
}


; Create an associative array (dictionary)
MyMap := Map()
MyMap["Transmutation Shard"] := "transmutation-shard"
MyMap["Regal Shard"] := "regal-shard"
MyMap["Artificer's Shard"] := "artificers-shard"
MyMap["Scroll of Wisdom"] := "wisdom"
MyMap["Orb of Transmutation"] := "transmute"
MyMap["Orb of Augmentation"] := "aug"
MyMap["Orb of Chance"] := "chance"
MyMap["Orb of Alchemy"] := "alch"
MyMap["Chaos Orb"] := "chaos"
MyMap["Vaal Orb"] := "vaal"
MyMap["Regal Orb"] := "regal"
MyMap["Exalted Orb"] := "exalted"
MyMap["Divine Orb"] := "divine"
MyMap["Orb of Annulment"] := "annul"
MyMap["Artificer's Orb"] := "artificers"
MyMap["Mirror of Kalandra"] := "mirror"
MyMap["Armourer's Scrap"] := "scrap"
MyMap["Blacksmith's Whetstone"] := "whetstone"
MyMap["Arcanist Etcher's"] := "etcher"
MyMap["Glassblower's Bauble"] := "bauble"
MyMap["Gemcutter's Prism"] := "gcp"

MyMap["Breach Splinter"] := "breach-splinter"
MyMap["Breachstone"] := "breachstone"
MyMap["Simulacrum Splinter"] := "simulacrum-splinter"
MyMap["Simulacrum"] := "simulacrum"
MyMap["An Audience with the King"] := "an-audience-with-the-king"
MyMap["Cowardly Fate"] := "cowardly-fate"
MyMap["Deadly Fate"] := "deadly-fate"
MyMap["Victorious Fate"] := "victorious-fate"
MyMap["Ancient Crisis Fragment"] := "ancient-crisis-fragment"
MyMap["Faded Crisis Fragment"] := "faded-crisis-fragment"
MyMap["Weathered Crisis Fragment"] := "weathered-crisis-fragment"

MyMap["Desert Rune"] := "desert-rune"
MyMap["Glacial Rune"] := "glacial-rune"
MyMap["Storm Rune"] := "storm-rune"
MyMap["Iron Rune"] := "iron-rune"
MyMap["Body Rune"] := "body-rune"
MyMap["Mind Rune"] := "mind-rune"
MyMap["Rebirth Rune"] := "rebirth-rune"
MyMap["Inspiration Rune"] := "inspiration-rune"
MyMap["Stone Rune"] := "stone-rune"
MyMap["Vision Rune"] := "vision-rune"

MyMap["Essence of the Body"] := "essence-of-the-body"
MyMap["Essence of the Mind"] := "essence-of-the-mind"
MyMap["Essence of Enhancement"] := "essence-of-enhancement"
MyMap["Essence of Torment"] := "essence-of-torment"
MyMap["Essence of Flames"] := "essence-of-flames"
MyMap["Essence of Ice"] := "essence-of-ice"
MyMap["Essence of Electricity"] := "essence-of-electricity"
MyMap["Essence of Ruin"] := "essence-of-ruin"
MyMap["Essence of Battle"] := "essence-of-battle"
MyMap["Essence of Sorcery"] := "essence-of-sorcery"
MyMap["Essence of Haste"] := "essence-of-haste"
MyMap["Essence of the Infinite"] := "essence-of-the-infinite"

MyMap["Greater Essence of Haste"] := "greater-essence-of-haste"
MyMap["Greater Essence of Battle"] := "greater-essence-of-battle"
MyMap["Greater Essence of the Infinite"] := "greater-essence-of-the-infinite"
MyMap["Greater Essence of Sorcery"] := "greater-essence-of-sorcery"
MyMap["Greater Essence of Ruin"] := "greater-essence-of-ruin"
MyMap["Greater Essence of Electricity"] := "greater-essence-of-electricity"
MyMap["Greater Essence of Ice"] := "greater-essence-of-ice"
MyMap["Greater Essence of Flames"] := "greater-essence-of-flames"
MyMap["Greater Essence of Torment"] := "greater-essence-of-torment"
MyMap["Greater Essence of the Mind"] := "greater-essence-of-the-mind"
MyMap["Greater Essence of the Body"] := "greater-essence-of-the-body"
MyMap["Greater Essence of Enhancement"] := "greater-essence-of-enhancement"

MyMap["Soul Core of Tacati"] := "soul-core-of-tacati"
MyMap["Soul Core of Opiloti"] := "soul-core-of-opiloti"
MyMap["Soul Core of Jiquani"] := "soul-core-of-jiquani"
MyMap["Soul Core of Zalatl"] := "soul-core-of-zalatl"
MyMap["Soul Core of Citaqualotl"] := "soul-core-of-citaqualotl"
MyMap["Soul Core of Puhuarte"] := "soul-core-of-puhuarte"
MyMap["Soul Core of Tzamoto"] := "soul-core-of-tzamoto"
MyMap["Soul Core of Xopec"] := "soul-core-of-xopec"
MyMap["Soul Core of Azcapa"] := "soul-core-of-azcapa"
MyMap["Soul Core of Topotante"] := "soul-core-of-topotante"
MyMap["Soul Core of Quipolatl"] := "soul-core-of-quipolatl"
MyMap["Soul Core of Ticaba"] := "soul-core-of-ticaba"
MyMap["Soul Core of Atmohua"] := "soul-core-of-atmohua"
MyMap["Soul Core of Cholotl"] := "soul-core-of-cholotl"
MyMap["Soul Core of Zantipi"] := "soul-core-of-zantipi"

MyMap["Flesh Catalyst"] := "flesh-catalyst"
MyMap["Neural Catalyst"] := "neural-catalyst"
MyMap["Carapace Catalyst"] := "carapace-catalyst"
MyMap["Uul Netol's Catalyst"] := "uul-netols-catalyst"
MyMap["Xoph's Catalyst"] := "xophs-catalyst"
MyMap["Tul's Catalyst"] := "tuls-catalyst"
MyMap["Esh's Catalyst"] := "eshs-catalyst"
MyMap["Chayula's Catalyst"] := "chayulas-catalyst"
MyMap["Reaver Catalyst"] := "reaver-catalyst"
MyMap["Sibilant Catalyst"] := "sibilant-catalyst"
MyMap["Skittering Catalyst"] := "skittering-catalyst"
MyMap["Adaptive Catalyst"] := "adaptive-catalyst"

MyMap["Exotic Coinage"] := "exotic-coinage"
MyMap["Broken Circle Artifact"] := "broken-circle-artifact"
MyMap["Black Scythe Artifact"] := "black-scythe-artifact"
MyMap["Order Artifact"] := "order-artifact"
MyMap["Sun Artifact"] := "sun-artifact"

MyMap["Omen of Refreshment"] := "omen-of-refreshment"
MyMap["Omen of Resurgence"] := "omen-of-resurgence"
MyMap["Omen of Amelioration"] := "omen-of-amelioration"
MyMap["Omen of Whittling"] := "omen-of-whittling"
MyMap["Omen of Sinistral Erasure"] := "omen-of-sinistral-erasure"
MyMap["Omen of Dextral Erasure"] := "omen-of-dextral-erasure"
MyMap["Omen of Sinistral Alchemy"] := "omen-of-sinistral-alchemy"
MyMap["Omen of Dextral Alchemy"] := "omen-of-dextral-alchemy"
MyMap["Omen of Sinistral Coronation"] := "omen-of-sinistral-coronation"
MyMap["Omen of Dextral Coronation"] := "omen-of-dextral-coronation"
MyMap["Omen of Corruption"] := "omen-of-corruption"
MyMap["Omen of Greater Exaltation"] := "omen-of-greater-exaltation"
MyMap["Omen of Sinistral Exaltation"] := "omen-of-sinistral-exaltation"
MyMap["Omen of Dextral Exaltation"] := "omen-of-dextral-exaltation"
MyMap["Omen of Greater Annulment"] := "omen-of-greater-annulment"
MyMap["Omen of Sinistral Annulment"] := "omen-of-sinistral-annulment"
MyMap["Omen of Dextral Annulment"] := "omen-of-dextral-annulment"

MyMap["Distilled Ire"] := "distilled-ire"
MyMap["Distilled Guilt"] := "distilled-guilt"
MyMap["Distilled Greed"] := "distilled-greed"
MyMap["Distilled Paranoia"] := "distilled-paranoia"
MyMap["Distilled Envy"] := "distilled-envy"
MyMap["Distilled Disgust"] := "distilled-disgust"
MyMap["Distilled Fear"] := "distilled-fear"
MyMap["Distilled Despair"] := "distilled-despair"
MyMap["Distilled Suffering"] := "distilled-suffering"
MyMap["Distilled Isolation"] := "distilled-isolation"
