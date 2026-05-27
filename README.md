# 个人网站（静态）

目录：在 `Life` 下的 **`个人网站`** 文件夹（完整路径示例：`…/AI/Life/个人网站/`）。  
本地双击其中的 `index.html` 或使用 `python3 -m http.server 8080` 预览。

## 功能概览

| 功能 | 说明 |
|------|------|
| **中英文** | 顶栏 **中 / EN** 切换；文案在 `i18n.js` 的 `I18N.zh` / `I18N.en` 中成对维护；选择会写入 `localStorage`（键名 `portfolio-lang`）。 |
| **三套视觉主题** | 顶栏 **主题**按钮循环：**Editorial**（深色暖金 + 细颗粒）、**Swiss**（浅色、红强调、直角）、**Lab**（暗色 + 青强调 + 淡网格）。主题写入 `localStorage`（`portfolio-theme`）。 |
| **案例子页** | 首页三张卡片分别链到 `case-brand.html`、`case-ui.html`、`case-packaging.html`，「查看详情」可正常进入。你可替换为外链（站酷/Behance）或继续扩展子页内容。 |
| **双语文档标题** | 每个 HTML 根节点使用 `data-title-zh` / `data-title-en`，随语言切换 `<title>`。 |

### 文件结构

```
个人网站/
├── index.html
├── case-brand.html
├── case-ui.html
├── case-packaging.html
├── styles.css      ← 主题与版式（可改 CSS 变量）
├── i18n.js         ← 中英文字典
├── site.js         ← 主题循环、年份、初始化语言
└── README.md
```

修改样式：主要改 `styles.css` 顶部各 `html[data-theme="..."]` 下的变量即可。

新增翻译：在 `i18n.js` 的 `zh` / `en` 各加同名 key，在 HTML 对应节点上加 `data-i18n="key"`。

---

## 自定义域名

**可以。** 静态站托管在 **Netlify、GitHub Pages、Cloudflare Pages** 等均可绑定自有域名（在控制台「Domains / Custom domain」按指引添加 DNS 记录，通常一条 **CNAME** 指向平台提供的地址）。

- **GitHub Pages**：用户/组织页或项目页均支持自定义域，官方文档可查最新步骤。  
- **Netlify / Cloudflare**：按向导添加域名并验证所有权即可。

个人站**不需要**为此单独买 Workers。

---

## Cloudflare Workers 是什么？要不要用？免费吗？

- **Workers** 是运行在 Cloudflare 边缘网络上的 **JavaScript/ WASM 小脚本**，可处理 HTTP 请求：例如 **A/B 分流、鉴权、反向代理、轻量 API、改写响应头** 等。  
- **对纯展示型作品集**：通常 **不需要** Workers；**Cloudflare Pages + 自定义域名 +（可选）CDN 缓存** 已足够。  
- **免费档**：Cloudflare 对 Workers / Pages 有免费额度（请求次数、CPU 时间等），具体以官网当前说明为准；超出后按量计费或需升级计划。

**结论**：把站当静态页发布时，**不必**为了上线而去开通 Workers；只有当你需要「在边缘跑一点逻辑」时再考虑。

---

## 部署（与先前相同）

### A. Netlify Drop

压缩整个 `个人网站` 为 ZIP（根目录可见 `index.html`），拖到 <https://app.netlify.com/drop>，在后台绑定域名。

### B. GitHub Pages

仓库根目录包含上述全部文件 → Settings → Pages → branch `main` / root → 绑定域名（可选）。

---

## 占位替换清单

| 位置 | 操作 |
|------|------|
| `<html data-title-zh data-title-en>` 与各页 `<title>` | 与对外姓名一致 |
| `.hero-name`、`.footer-name` | 姓名（一般不随语言切换） |
| `mailto:you@example.com` | 你的邮箱 |
| `resume.pdf` | 放入同目录或改链接名 |
| `i18n.js` 内案例与关于文案 | 改为真实项目描述 |
| 卡片整卡链接 | 已指向三个 `case-*.html`；若某案例只外链，把该卡片的 `href` 改为外链并加 `target="_blank" rel="noopener"` |

---

## 本地预览

```bash
cd /Users/tang/Desktop/Tang-07032022/AI/Life/个人网站
python3 -m http.server 8080
```

浏览器打开：<http://127.0.0.1:8080>

---

## 浏览器说明

主题与卡片使用了较新的 **CSS `color-mix()`**。若需兼容极旧浏览器，可把 `color-mix(...)` 改成固定十六进制色值。
