#!/bin/bash
bash ~/GinieSystem/Scripts/loop_trip.sh &
bash ~/GinieSystem/Scripts/vault_backup.sh &
open ~/GinieSystem/Workflow/Dashboard/mirror_status.html
open "$HOME/Library/Mobile Documents/com~apple~CloudDocs/GinieSystem/Vault/TrainApp/app/index.html"
