#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

DATE=$(date +%F)
TITLE="${1:-AI Briefing · $DATE}"

mkdir -p "briefings/$DATE"

cat > "briefings/$DATE/briefing.html" <<HTML
<!doctype html>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>$TITLE</title>
<body style="font-family:-apple-system,system-ui;padding:24px;line-height:1.6">
<h1>$TITLE</h1>
<p>生成时间：$(date)</p>
<hr/>
<p>（这里将由 OpenClaw 写入内容）</p>
</body>
HTML

TMP=$(mktemp)

# ✅ 兼容两种结构：
# A) {"items":[...]}
# B) [...]
if [ -f manifest.json ]; then
  if jq -e 'type=="object" and has("items") and (.items|type=="array")' manifest.json >/dev/null 2>&1; then
    jq --arg date "$DATE" --arg slug "$DATE" --arg title "$TITLE" \
      '.items = ([{"date":$date,"slug":$slug,"title":$title}] + .items)' \
      manifest.json > "$TMP"
  elif jq -e 'type=="array"' manifest.json >/dev/null 2>&1; then
    jq --arg date "$DATE" --arg slug "$DATE" --arg title "$TITLE" \
      '([{"date":$date,"slug":$slug,"title":$title}] + .)' \
      manifest.json > "$TMP"
  else
    # 格式不对就重建为标准 object 结构
    echo "{\"items\":[{\"date\":\"$DATE\",\"slug\":\"$DATE\",\"title\":\"$TITLE\"}]}" > "$TMP"
  fi
else
  echo "{\"items\":[{\"date\":\"$DATE\",\"slug\":\"$DATE\",\"title\":\"$TITLE\"}]}" > "$TMP"
fi

mv "$TMP" manifest.json

git add -A
git commit -m "publish: $DATE" || echo "no changes to commit"
git push

echo "发布完成："
echo "https://ai-briefing-dz5.pages.dev/briefings/$DATE/briefing.html"
