# Ginie Jobb-PC Edge Starter (renset for æøå-problemer)

$chatgptURL = "https://chat.openai.com/"
$scriptURL  = "https://github.com/JarvisATeam/GinieSystem-Autobackup"

Start-Process "msedge.exe" -ArgumentList "$chatgptURL"
Start-Sleep -Seconds 1
Start-Process "msedge.exe" -ArgumentList "$scriptURL"

Write-Host "✅ Ginie is now launched in Microsoft Edge."
Write-Host "✅ Remember to activate and pin the 'ChatsNow' extension."

