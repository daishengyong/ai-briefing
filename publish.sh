#!/usr/bin/env bash
set -euo pipefail

TITLE="${1:-今日AI简报}"
DATE="$(date +%F)"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$ROOT_DIR"

# 1) 必须先有 content.html（由 OpenClaw 或你生成）
if [ ! -f content.html ]; then
  echo "❌ content.html 不存在：$ROOT_DIR/content.html"
  echo "   请先生成 content.html 再发布。"
  exit 1
fi

# 2) 生成本期页面
OUT_DIR="briefings/$DATE"
mkdir -p "$OUT_DIR"

cat > "$OUT_DIR/briefing.html" <<HTML
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>AI Briefing · $DATE</title>
  <style>
    body{font-family:-apple-system,BlinkMacSystemFont,system-ui,Segoe UI,Roboto,Helvetica,Arial;
         margin:0;padding:18px;background:#0b1220;color:#e5e7eb}
    .wrap{max-width:860px;margin:0 auto}
    .top{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:14px}
    .badge{font-size:12px;padding:6px 10px;border-radius:999px;background:rgba(255,255,255,.08)}
    a{color:#93c5fd}
    .card{background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);
          border-radius:16px;padding:14px;margin:12px 0}
    details{background:rgba(0,0,0,.12);border-radius:12px;padding:10px}
    summary{cursor:pointer;font-weight:600}
    .muted{opacity:.75}
  </style>
</head>
<body>
  <div class="wrap">
    <div class="top">
      <h1 style="margin:0;font-size:22px">AI Briefing · $DATE</h1>
      <div class="badge">Mobile-first · Static</div>
    </div>

    <div class="card muted">
      <div>主题：<b>$TITLE</b></div>
      <div>归档：<a href="/">返回首页</a></div>
    </div>

    <!-- === content injected === -->
    <div class="card">
$(cat content.html)
    </div>

    <div class="muted" style="margin:18px 0 28px">生成时间：$(date "+%F %H:%M")</div>
  </div>
</body>
</html>
HTML

# 3) 更新 manifest.json（无论之前是 array 还是 object，都归一成 object.items）
TMP="$(mktemp)"
if [ -f manifest.json ]; then
  if jq -e 'type=="object" and has("items")' manifest.json >/dev/null 2>&1; then
    jq --arg d "$DATE" --arg t "$TITLE" '
      .items |= ([{"date":$d,"slug":$d,"title":$t}] + .) | .items |= (unique_by(.slug))
    ' manifest.json > "$TMP" || true
  else
    # 如果历史是 array，转成 object.items
    jq --arg d "$DATE" --arg t "$TITLE" '
      {items: ([{"date":$d,"slug":$d,"title":$t}] + .)} | .items |= (unique_by(.slug))
    ' manifest.json > "$TMP" || true
  fi
else
  echo "{\"items\":[{\"date\":\"$DATE\",\"slug\":\"$DATE\",\"title\":\"$TITLE\"}]}" > "$TMP"
fi
mv "$TMP" manifest.json

# 4) 提交发布
git add -A
git commit -m "publish: $DATE" || echo "no changes to commit"
git push

echo "✅ 发布完成："
echo "首页： https://ai-briefing-dz5.pages.dev/"
echo "本期： https://ai-briefing-dz5.pages.dev/briefings/$DATE/briefing.html"
