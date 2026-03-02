#!/bin/bash
set -e

cd "$(dirname "$0")"

DATE=$(date +%F)
TITLE="$1"

if [ -z "$TITLE" ]; then
  TITLE="AI Briefing · $DATE"
fi

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

# 更新 manifest
TMP=$(mktemp)

if [ -f manifest.json ]; then
  jq ".items |= [{\"date\":\"$DATE\",\"slug\":\"$DATE\",\"title\":\"$TITLE\"}] + .items" manifest.json > "$TMP"
else
  echo "{\"items\": [{\"date\":\"$DATE\",\"slug\":\"$DATE\",\"title\":\"$TITLE\"}]}" > "$TMP"
fi

mv "$TMP" manifest.json

git add -A
git commit -m "publish: $DATE"
git push

echo "发布完成："
echo "https://ai-briefing-dz5.pages.dev/briefings/$DATE/briefing.html"
