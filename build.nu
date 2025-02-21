#!/usr/bin/env nu

const newest = 3053

def "main get_comics" [] {
  # let newest = 1000

  mkdir comics

  for i in 1..$newest {
    print --stderr $"Downloading ($i)..."

    let path = $"comics/($i).json"

    if ($path | path exists) {
      continue
    }

    curl $'https://xkcd.com/($i)/info.0.json' out> $path
  }
}

def comics [] {
  1..$newest | filter { $in != 404 } | each { open $"comics/($in).json" }
}

def "main get_explanations" [] {
  let comics = comics

  mkdir explanations

  for comic in $comics {
    print --stderr $"Downloading ($comic.num)..."

    let path = $"explanations/($comic.num).json"

    if ($path | path exists) {
      continue
    }

    # i hate strings
    let url_title = $comic.title |
      str replace --all "<span style=\"color: #0000ED\">House</span>" "House" |
      str replace --all "Killed In Action" "Killed in Action" |
      str replace --all "Alive or Not" "Alive Or Not" |
      str replace --all "Easy or Hard" "Easy Or Hard" |
      str replace --all "Radians are Cursed" "Radians Are Cursed" |
      str replace --all "What to Do" "What To Do" |
      str replace --all "MBMBaM" "mbmbam" |
      str replace --all "LTR" "RTL" |
      str replace --all "�" "%3F" |
      str replace --all "&" "%26" |
      str replace --all "+" "%2B" |
      str replace --all " " "+" |
      str replace --all "\u{2009}" "+" |
      str replace --all "'" "%27" |
      str replace --all "#" "" |
      str replace --all "&eacute;" "%C3%A9" |
      str replace --all "é" "%C3%A9"

    let url = $'https://www.explainxkcd.com/wiki/api.php?action=parse&page=($comic.num):+($url_title)&section=1&prop=text&format=json'
    print $url
    let resp = curl $url | from json

    {
      id: $comic.num
      explanation: $resp.parse.text.*
    } | to json | save $path
  }
}

def explanations [] {
  1..$newest | filter { $in != 404 } | each { open $"explanations/($in).json" }
}

def "main markdown" [] {
  let comics = comics
  let explanations = explanations

  let metadata = {
    # title: [
    #   {type: main text: XKCD}
    #   {type: subtitle, text: "The E-Book"}
    # ]
    title: "XKCD - The E-Book"
  }

  $"---\n($metadata | to yaml)---\n\n" out> out.md

  for comic in $comics {
    let url = $comic.img
    let ext = $url | path parse | get extension
    let path = $"imgs/($comic.num).($ext)"

    $"# #($comic.num): ($comic.title) \(($comic.year)-($comic.month | fill --width 2 --alignment right --character "0")-($comic.day | fill --width 2 --alignment right --character "0")\) {#comic-($comic.num)}\n\n![]\(($path)\){width=100%}\n\n($comic.alt)\n\n[Explain]\(#explain-($comic.num)\)\n\n" out>> out.md
  }

  for explanation in $explanations {
    let text = $explanation.explanation | xq --query 'p' | lines | str join "\n\n"
  
    $"# Explain #($explanation.id) {#explain-($explanation.id)}\n\n[Back to comic]\(#comic-($explanation.id)\)\n\n($text)\n\n" out>> out.md
  }
}

def "main fetch_imgs" [] {
  let comics = comics

  mkdir imgs

  for comic in $comics {
    print --stderr $"Downloading ($comic.num)..."

    let url = $comic.img
    let ext = $url | path parse | get extension
    let path = $"imgs/($comic.num).($ext)"

    if ($path | path exists) {
      continue
    }

    curl $url out> $path
  }
}

def "main pandoc" [] {
  pandoc -o xkcd.epub out.md
}

def main [] {
}
