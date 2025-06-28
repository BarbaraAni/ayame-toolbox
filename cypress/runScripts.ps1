# Starte alle Verarbeitungsschritte nacheinander

Write-Host "`nStarte Schritt 1: Metadaten entfernen"
.\1_cleanMetadata.ps1

Write-Host "`nStarte Schritt 2: Verschieben und Aufräumen"
.\2_moveAndCleanup.ps1

Write-Host "`nStarte Schritt 3: Metadaten hinzufügen"
.\3_addMetadata.ps1

Write-Host "`nFertig!" -ForegroundColor Green
pause
