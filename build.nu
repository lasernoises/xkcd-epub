#!/usr/bin/env nu

def "main get_comics" [] {
  # let newest = 3053
  let newest = 12

  1..$newest | each {|i|
    # let html = curl $'https://xkcd.com/($i)/'
    # let img = $html | fq --decode html '.. | select(.["@id"]? == "comic").img' | from json
    # let title = $html | fq --raw-output --decode html '.. | select(.["@id"]? == "ctitle").["#text"]'
    let info = curl $'https://xkcd.com/($i)/info.0.json' | from json

    # { id: $i, title: $title, img: $img }
    $info
  } | save --force comics.json
}

def "main get_explanations" [] {
  let comics = open comics.json

  $comics | each {|comic|
    let url = $'https://www.explainxkcd.com/wiki/api.php?action=parse&page=($comic.num):+($comic.safe_title | str replace --all " " "+")&section=1&prop=text&format=json'
    let resp = curl $url | from json

    {
      id: $comic.num
      explanation: $resp.parse.text.*
    }
  } | save --force explanations.json
}

def "main markdown" [] {
  let comics = open comics.json

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

    $"# #($comic.num): ($comic.safe_title) \(($comic.year)-($comic.month | fill --width 2 --alignment right --character "0")-($comic.day | fill --width 2 --alignment right --character "0")\) {#comic-($comic.num)}\n\n![]\(($path)\){width=100%}\n\n($comic.alt)\n\n[Explain]\(#explain-($comic.num)\)\n\n" out>> out.md
  }

  let explanations = open explanations.json

  for explanation in $explanations {
    let text = $explanation.explanation | xq --query 'p' | lines | str join "\n\n"
  
    $"# Explain #($explanation.id) {#explain-($explanation.id)}\n\n[Back to comic]\(#comic-($explanation.id)\)\n\n($text)\n\n" out>> out.md
  }
}

def "main fetch_imgs" [] {
  let comics = open comics.json

  mkdir imgs

  for comic in $comics {
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

def main [] {}
