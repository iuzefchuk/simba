#!/bin/zsh
set -uo pipefail
cd "$(dirname "$0")/.."
failed=0
fail() {
  print -r -- "$1"
  [[ -n "${2:-}" ]] && print -r -- "$2" | sed 's/^/  /'
  failed=1
}

for item in src/*(N); do
  [[ -d $item ]] || { fail "$item: src/ holds only the four layer folders, no files"; continue }
  case ${item:t} in
    assets|domain|infra|fw) ;;
    *) fail "$item: src/ holds only assets, domain, infra and fw" ;;
  esac
done

categories=(aggregate entity value_object service event)
for item in src/domain/*(N); do
  [[ -f $item ]] || { fail "$item: domain holds files only, no folders; the DDD category is the first part of the file name"; continue }
  name=${item:t}
  [[ $name =~ '^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*\.swift$' ]] \
    || { fail "$item: a domain file is named {ddd-category}.{abstraction}.swift, both parts in snake_case"; continue }
  parts=("${(@s:.:)name}")
  category=$parts[1]
  abstraction=$parts[2]
  (( ${categories[(Ie)$category]} )) || fail "$item: the DDD category is ${(j:, :)categories}, not '$category'"
  first=$(grep -oE '^((@[A-Za-z_]+(\([^)]*\))?|public|internal|private|fileprivate|open|final|indirect) +)*(enum|struct|class|actor|protocol) +[A-Z][A-Za-z0-9_]*' "$item" | head -1 | awk '{print $NF}')
  [[ ${(L)first} == ${abstraction//_/} ]] || fail "$item: declares ${first:-nothing} first, so the abstraction in its name is that type in snake_case"
done

boundaries=(system server sdk)
for item in src/infra/*(N); do
  [[ -f $item ]] || { fail "$item: infra holds files only, no folders; the dependency is the first part of the file name"; continue }
  name=${item:t}
  [[ $name =~ '^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*\.swift$' ]] \
    || { fail "$item: an infra file is named {dependency}.{port}.{implementation}.swift, each part in snake_case"; continue }
  parts=("${(@s:.:)name}")
  boundary=$parts[1]
  port=$parts[2]
  implementation=$parts[3]
  (( ${boundaries[(Ie)$boundary]} )) || fail "$item: the dependency is ${(j:, :)boundaries} (browser takes system's place in a web app), not '$boundary'"
  expected=${implementation//_/}${port//_/}
  declared=("${(@f)$(grep -oE '^((@[A-Za-z_]+(\([^)]*\))?|public|internal|private|fileprivate|open|final) +)*(enum|struct|class|actor|protocol) +[A-Z][A-Za-z0-9_]*' "$item" | awk '{print $NF}')}")
  found=0
  for type in $declared; do
    [[ ${(L)type} == $expected ]] && found=1
  done
  (( found )) || fail "$item: must declare a top-level type named {Implementation}{Port}, spelled $expected ignoring case"
done

block_folder() {
  local folder=$1 entry=${2:-}
  for item in $folder/*(N); do
    local name=${item:t}
    if [[ -d $item ]]; then
      [[ $name =~ '^[A-Z][A-Za-z0-9]*$' ]] || { fail "$item: a nested block is a folder named {NestedEntity}, UpperCamelCase"; continue }
      [[ -f $item/$name.swift ]] || fail "$item: a nested block {NestedEntity}/ holds {NestedEntity}.swift"
      for sub in $item/*(N); do
        [[ -f $sub ]] || { fail "$sub: a nested block is one flat level of files"; continue }
        [[ ${sub:t} =~ "^${name}[A-Za-z0-9]*\\.swift$" ]] || fail "$sub: a nested block's files are {NestedEntity}.swift and {NestedEntity}{ChildEntity}.swift"
      done
    else
      [[ $name == $entry ]] && continue
      [[ $name =~ '^[A-Z][A-Za-z0-9]*\.swift$' ]] || fail "$item: a flat block is {Entity}.swift, UpperCamelCase"
    fi
  done
}

for item in src/fw/*(N); do
  if [[ -d $item ]]; then
    case ${item:t} in
      stores|AppIntents|Resources|"Preview Content")
        for sub in $item/*(/N); do fail "$sub: fw/${item:t} is one flat level of files"; done ;;
      blocks) ;;
      *) fail "$item: fw holds stores and blocks beside its *rest*, Apple's layout: AppIntents, Resources and Preview Content" ;;
    esac
  else
    [[ ${item:e} == swift ]] || fail "$item: fw's root holds the app-level Swift files"
  fi
done

for item in src/fw/blocks/*(N); do
  case ${item:t} in
    by-design|by-hierarchy) [[ -d $item ]] || fail "$item: blocks/${item:t} is a folder" ;;
    *) fail "$item: blocks holds by-design and by-hierarchy, nothing else" ;;
  esac
done
block_folder src/fw/blocks/by-design
for item in src/fw/blocks/by-hierarchy/*(N); do
  case ${item:t} in
    per-app|per-route) [[ -d $item ]] || fail "$item: by-hierarchy/${item:t} is a folder" ;;
    *) fail "$item: by-hierarchy holds per-app and per-route, nothing else" ;;
  esac
done

app=src/fw/blocks/by-hierarchy/per-app
if [[ -f $app/App.swift ]]; then
  grep -qE '^((@[A-Za-z_]+(\([^)]*\))?|public|internal|private|fileprivate|final) +)*struct +[A-Z][A-Za-z0-9_]*: *App\b' $app/App.swift \
    || fail "$app/App.swift: the app entry declares the App"
else
  fail "$app/App.swift: the app entry, the App, is per-app/App.swift"
fi
mains=(${(f)"$(grep -rl --include='*.swift' '^@main' src || true)"})
[[ "${(j: :)mains}" == "$app/App.swift" ]] || fail "@main belongs to per-app/App.swift and nothing else, but is in: ${(j:, :)mains}"
block_folder $app App.swift

routes=src/fw/blocks/by-hierarchy/per-route
for route in $routes/*(N); do
  [[ -d $route ]] || { fail "$route: per-route holds one folder per route, no files"; continue }
  [[ ${route:t} =~ '^[a-z][a-z0-9-]*$' ]] || fail "$route: a route folder is named after its route, lowercase"
  prefix=${(j::)${(C)${(s:-:)route:t}}}
  if [[ -f $route/${prefix}Route.swift ]]; then
    grep -qE "^((@[A-Za-z_]+(\([^)]*\))?|public|internal|private|fileprivate|final) +)*class +${prefix}Route *: *NSWindowController\b" $route/${prefix}Route.swift \
      || fail "$route/${prefix}Route.swift: the entry declares ${prefix}Route, the route's NSWindowController"
  else
    fail "$route: the entry is ${prefix}Route.swift, the route's window controller"
  fi
  for file in $route/*(N); do
    case ${file:t} in
      ${prefix}Route.swift|${prefix}View.swift|${prefix}View?*.swift) ;;
      *) fail "$file: a route folder holds ${prefix}Route.swift, the entry, ${prefix}View.swift, the page, and ${prefix}View{Part}.swift, the page's parts" ;;
    esac
  done
  block_folder $route
done

for file in src/fw/**/*.swift(.N); do
  [[ $file == $app/App.swift ]] && continue
  first=$(grep -oE '^((@[A-Za-z_]+(\([^)]*\))?|public|internal|private|fileprivate|open|final|indirect) +)*(enum|struct|class|actor|protocol|extension) +[A-Z][A-Za-z0-9_]*' "$file" | head -1 | awk '{print $NF}')
  [[ "$first" == "${file:t:r}" ]] || fail "$file: declares ${first:-nothing} first, so the file is named after that type"
done

for item in src/assets/*(N); do
  if [[ ! -d "$item" ]]; then
    fail "$item: assets are sorted by file extension, so a file goes in src/assets/{its extension}/"
    continue
  fi
  [[ ${item:e} == xcassets ]] && continue
  ext=${item:t}
  [[ $ext == *.* ]] && { fail "$item: a directory at the assets root is an {extension}/ folder or an .xcassets catalog"; continue }
  for entry in "$item"/*(N); do
    entry_ext=${entry:e}
    if [[ -d $entry && $entry_ext == xcassets ]]; then
      fail "$entry: a catalog is a directory, not a file; it sits at the assets root"
      continue
    fi
    [[ "$entry_ext" == "$ext" ]] || fail "$entry: sits in assets/$ext/ but its file extension is '${entry_ext:-none}'"
  done
done
code=$(find src/assets -type f \( -name '*.swift' -o -name '*.py' -o -name '*.sh' -o -name '*.rb' -o -name '*.js' -o -name '*.m' \) | sort)
[[ -n "$code" ]] && fail "assets holds no logic, but has code:" "$code"
set_kinds=(imageset appiconset colorset symbolset dataset)
for catalog in src/assets/*.xcassets(/N); do
  for item in $catalog/*(N); do
    [[ -d $item ]] || { fail "$item: a catalog's root holds only one folder per set extension, not files (Xcode's metadata-only Contents.json is not needed)"; continue }
    kind=${item:t}
    (( ${set_kinds[(Ie)$kind]} )) || { fail "$item: catalog sets are sorted by extension into ${(j:/:)set_kinds}/, not '$kind'"; continue }
    for dir in $item/*(N); do
      [[ -d $dir && ${dir:t} =~ "^[A-Z][A-Za-z0-9]*\\.$kind\$" ]] \
        || { fail "$dir: $kind/ holds only sets named UpperCamelCase.$kind"; continue }
      for sub in $dir/*(/N); do
        fail "$sub: a set holds files only, nothing nests inside it"
      done
      [[ -f $dir/Contents.json ]] || { fail "$dir: a set needs a Contents.json"; continue }
      listed=("${(@f)$(grep -oE '"filename" *: *"[^"]+"' $dir/Contents.json | sed -E 's/.*: *"([^"]+)"/\1/')}")
      for file in $dir/*(.N); do
        [[ ${file:t} == Contents.json ]] && continue
        [[ ${file:t} =~ '^[0-9]+(@[0-9]x)?\.png$' ]] || fail "$file: a set's files are named {points}.png or {points}@2x.png"
        (( ${listed[(Ie)${file:t}]} )) || fail "$file: not listed in its Contents.json"
      done
      for entry in $listed; do
        [[ -z $entry ]] && continue
        [[ -f $dir/$entry ]] || fail "$dir/Contents.json lists $entry, which does not exist"
      done
    done
  done
done

hits=$(grep -rnE --include='*.swift' '^import ' src/domain | grep -vE 'import +Foundation *$' || true)
[[ -n "$hits" ]] && fail "domain is language-agnostic, so it imports nothing but Foundation:" "$hits"
hits=$(grep -rnE --include='*.swift' '^import +(SwiftUI|AppKit|AppIntents|Observation)\b' src/infra || true)
[[ -n "$hits" ]] && fail "infra is framework-agnostic, so it must not import SwiftUI, AppKit, AppIntents or Observation:" "$hits"
hits=$(grep -rnE --include='*.swift' '^[[:space:]]*#if[[:space:]]' src || true)
[[ -n "$hits" ]] && fail "src is config-agnostic, so nothing in it branches on a compilation condition:" "$hits"

rest=(stores blocks)
apart() {
  local user=$1 declarer=$2
  local -a user_opts=(-rnw --include='*.swift') declarer_opts=(-rhoE --include='*.swift')
  if [[ $user == */\*rest\* ]]; then
    user=${user%/\*rest\*}
    for dir in $rest; do user_opts+=(--exclude-dir=$dir); done
  fi
  if [[ $declarer == */\*rest\* ]]; then
    declarer=${declarer%/\*rest\*}
    for dir in $rest; do declarer_opts+=(--exclude-dir=$dir); done
  fi
  local symbols=("${(@f)$(grep "${declarer_opts[@]}" '^((@[A-Za-z_]+(\([^)]*\))?|public|internal|private|fileprivate|open|final|indirect) +)*(struct|class|enum|actor|protocol) +[A-Z][A-Za-z0-9_]*' "src/$declarer" | awk '{print $NF}' | sort -u)}")
  for symbol in "${symbols[@]}"; do
    [[ -n "$symbol" ]] || continue
    hits=$(grep "${user_opts[@]}" "$symbol" "src/$user" || true)
    [[ -n "$hits" ]] && fail "$1 must not use $symbol, which $2 declares:" "$hits"
  done
}
apart domain infra
apart infra domain
apart domain fw
apart infra fw
apart fw/stores 'fw/*rest*'
apart fw/stores fw/blocks
apart 'fw/*rest*' fw/blocks/by-design
apart 'fw/*rest*' fw/blocks/by-hierarchy/per-app
apart fw/blocks/by-design fw/blocks/by-hierarchy
apart fw/blocks/by-hierarchy/per-app fw/blocks/by-hierarchy/per-route
apart fw/blocks/by-hierarchy/per-route fw/blocks/by-hierarchy/per-app

(( failed == 0 )) && echo "layers ok: domain and infra stand alone; in fw, stores know nothing above them, *rest* knows stores and names its routes, and otherwise only a block knows a block"
exit $failed
