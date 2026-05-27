# 部署：Cloudflare Pages + GitHub

作品集根目录即本文件夹（根目录须有 `index.html`）。

## 一、推送到 GitHub（首次）

在终端执行（把 `你的GitHub用户名` 换成真实用户名）：

```bash
cd "/Users/tang/Desktop/Tang-07032022/AI/Life/个人网站"

# 若尚未初始化（已在本机执行过可跳过）
git init
git add .
git commit -m "Portfolio site: initial publish"

# 在 github.com 新建空仓库，名称例如 caroline-portfolio，不要勾选 README
git branch -M main
git remote add origin https://github.com/你的GitHub用户名/caroline-portfolio.git
git push -u origin main
```

首次 push 约 **480MB** 图片，可能需要 **10–40 分钟**，请保持网络畅通。

## 二、连接 Cloudflare Pages

1. 打开 <https://dash.cloudflare.com/> 注册 / 登录  
2. 左侧 **Workers & Pages** → **Create** → **Pages** → **Connect to Git**  
3. 授权 **GitHub**，选择仓库 `caroline-portfolio`（或你的仓库名）  
4. 构建设置（静态站，无构建步骤）：

   | 项 | 值 |
   |---|---|
   | Production branch | `main` |
   | Framework preset | **None** |
   | Build command | **留空** |
   | Build output directory | **`/`**（根目录） |

5. **Save and Deploy**，等待 2–10 分钟  
6. 得到地址：`https://caroline-portfolio.pages.dev`（可在 Settings → 自定义子域名）

## 三、以后更新网站

```bash
cd "/Users/tang/Desktop/Tang-07032022/AI/Life/个人网站"
# 改完文件后：
git add .
git commit -m "Update portfolio"
git push
```

Cloudflare 会自动重新部署，约 1–3 分钟生效。

## 四、简历与首页

上线后把 **Pages 的 https 地址** 填进：

- 简历「个人作品集」一行  
- 可选：在 `index.html` 联系区或关于区加链接  

## 五、可选：GitHub Pages（备份访问）

同一仓库可在 GitHub → Settings → Pages → Source: **main** / **/ (root)**，  
会得到 `https://用户名.github.io/仓库名/`。与 Cloudflare 可并存，不必二选一。
