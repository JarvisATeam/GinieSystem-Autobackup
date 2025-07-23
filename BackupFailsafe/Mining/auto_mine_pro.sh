#!/bin/bash 
LOGFILE="$HOME/GinieSystem/Logs/pro_mode.log" 
echo " Starter kontinuerlig Crypto-mining 
(XMR, Pro Mode) kl. $(date)" | tee -a 
"$LOGFILE" # Starter ekte mining med XMRig 
(erstatt med egen wallet-adresse!) 
~/mining/xmrig --url 
pool.supportxmr.com:3333 \ --user 
DIN_MONERO_WALLET_ADRESSE_HER \ --pass 
GinieProMode \ --donate-level=1 \ 
--threads=2 \ --background \ 
--log-file="$HOME/GinieSystem/Logs/mining.log"
echo " Crypto-mining (XMRig) kjrer n kontinuerlig i bakgrunnen." | tee -a "$LOGFILE"
