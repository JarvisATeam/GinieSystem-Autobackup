$backupPath = "C:\c.ginie\Active"
cd $backupPath

git init
git remote remove origin -ErrorAction SilentlyContinue
git remote add origin https://github.com/JarvisATeam/GinieSystem-Autobackup.git

git add .
$time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "💾 Backup Active folder @ $time"
git branch -M main
git push -f origin main

Write-Host "✅ Active folder pushed to GitHub @ $time"
